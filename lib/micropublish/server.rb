require 'securerandom'
require 'base64'
require 'digest'

module Micropublish
  class Server < Sinatra::Application

    configure do
      helpers Helpers

      use Rack::SSL if settings.production?

      root_path = "#{File.dirname(__FILE__)}/../../"
      set :views, "#{root_path}views"
      set :public_folder, "#{root_path}public"
      set :properties,
        JSON.parse(File.read("#{root_path}config/properties.json"))
      set :readme, File.read("#{root_path}README.md")
      set :changelog, File.read("#{root_path}/changelog.md")
      set :help, File.read("#{public_folder}/help.md")

      set :server, :puma

      # use a cookie that lasts for 30 days
      secret = ENV['COOKIE_SECRET'] || Random.new_seed.to_s
      use Rack::Session::Cookie, secret: secret, expire_after: 2_592_000
    end

    before do
      unless settings.production?
        session[:me] = 'http://localhost:4444/'
        session[:micropub] = 'http://localhost:3333/micropub'
        session[:scope] = 'create update delete undelete'
      end
    end

    get '/' do
      if logged_in?
        @title = "Dashboard"
        @types = post_types
        erb :dashboard
      else
        @title = "Sign in"
        @about = markdown(settings.readme)
        erb :login
      end
    end

    get '/auth' do
      begin
        unless params.key?('me') && !params[:me].empty? &&
            Auth.valid_uri?(params[:me])
          raise "Missing or invalid value for \"me\": \"#{h params[:me]}\"."
        end
        unless params.key?('scope') && (
            params[:scope].include?('create') ||
            params[:scope].include?('post') ||
            params[:scope].include?('draft'))
          raise "You must specify a valid scope, including at least one of " +
            "\"create\", \"post\" or \"draft\"."
        end
        unless endpoints = EndpointsFinder.new(params[:me]).find_links
          raise "Client could not find expected endpoints at \"#{h params[:me]}\"."
        end
      rescue => e
        redirect_flash('/', 'danger', e.message)
      end
      # define random state string
      session[:state] = SecureRandom.alphanumeric(20)
      # store scope - will be needed to limit functionality on dashboard
      session[:scope] = params[:scope].join(' ')
      # store me - we don't want to trust this in callback
      session[:me] = params[:me]
      # code challenge from code verified
      session[:code_verifier] = SecureRandom.alphanumeric(100)
      code_challenge = Auth.generate_code_challenge(session[:code_verifier])
      # redirect to auth endpoint
      query = URI.encode_www_form({
        me: session[:me],
        client_id: request.base_url + "/",
        state: session[:state],
        scope: session[:scope],
        redirect_uri: "#{request.base_url}/auth/callback",
        response_type: "code",
        code_challenge: code_challenge,
        code_challenge_method: "S256"
      })
      redirect "#{endpoints[:authorization_endpoint]}?#{query}"
    end

    get '/auth/callback' do
      unless session.key?(:me) && session.key?(:state) && session.key?(:scope)
        redirect_flash('/', 'info', "Session has timed out. Please try again.")
      end
      unless params.key?(:state) && params[:state] == session[:state]
        session.clear
        redirect_flash('/', 'info', "Callback \"state\" parameter is missing or does not match.")
      end
      auth = Auth.new(
        session[:me],
        params[:code],
        "#{request.base_url}/auth/callback",
        request.base_url + "/",
        session[:code_verifier]
      )
      endpoints_and_token_and_scope_and_me = auth.callback
      # login and token grant was successful so store in session with the scope for the token and the me
      session.merge!(endpoints_and_token_and_scope_and_me)
      redirect_flash('/', 'success', %Q{You are now signed in successfully
          as "#{endpoints_and_token_and_scope_and_me[:me]}".
          Submit content to your site via Micropub using the links
          below. Please
          <a href="/about" class="alert-link">read&nbsp;the&nbsp;docs</a> for
          more information and help.})
    end

    get '/new' do
      redirect '/new/h-entry/note'
    end
    get '/new/h-entry' do
      redirect '/new/h-entry/note'
    end

    get %r{/new/h\-entry/(note|article|bookmark|reply|repost|like|rsvp|checkin|photo|listen)} do
        |subtype|
      require_session
      render_new(subtype)
    end

    post '/new' do
      require_session
      begin
        @post = Post.new([params[:_type]], Post.properties_from_params(params))
        required_properties = post_types[params[:_subtype]]['required']
        @post.validate_properties!(required_properties)
        # articles must be sent as json because content is an object
        format = params[:_subtype] == 'article' ? :json : default_format
        if params.key?('_preview')
          if format == :json
            @content = h @post.to_json(true)
          else
            @content = h format_form_encoded(@post.to_form_encoded)
          end
          if request.xhr?
            @content
          else
            erb :preview
          end
        else
          url = new_request.create(@post)
          redirect_post(url)
        end
      rescue MicropublishError => e
        if request.xhr?
          status 500
          e.message
        else
          set_flash('danger', e.message)
          render_new(params[:_subtype])
        end
      end
    end

    get '/edit' do
      require_session
      redirect "/delete?url=#{params[:url]}" if params.key?('delete')
      redirect "/undelete?url=#{params[:url]}" if params.key?('undelete')
      redirect "/edit-all?url=#{params[:url]}" if params.key?('edit-all')

      subtype = micropub.source_all(params[:url]).entry_type
      if post_types.key?(subtype)
        render_edit(subtype)
      else
        render_edit_all
      end
    end

    get %r{/edit/h\-entry/(note|article|bookmark|reply|repost|like|rsvp|checkin|photo|listen)} do
        |subtype|
      require_session
      render_edit(subtype)
    end

    get '/edit-all' do
      require_session
      render_edit_all
    end

    post '/edit' do
      require_session
      begin
        subtype = params[:_subtype]
        submitted_properties = Post.properties_from_params(params)
        @post = Post.new([params[:_type]], submitted_properties)
        @post.validate_properties!
        original_properties = if params.key?('_all')
            micropub.source_all(params[:_url]).properties
          else
            micropub.source_properties(params[:_url],
              subtype_edit_properties(subtype)).properties
          end
        mp_commands = Micropub.find_commands(params)
        known_properties = post_types.key?(subtype) ?
          settings.properties['known'].select{ |p| (post_types[subtype]['properties'] + %w(syndication published)).any?(p) } :
          settings.properties['known']
        diff = Compare.new(original_properties, submitted_properties,
          known_properties).diff_properties
        if params.key?('_preview')
          hash = {
            action: 'update',
            url: params[:_url]
          }.merge(diff).merge(mp_commands)
          @content = h JSON.pretty_generate(hash)
          if request.xhr?
            @content
          else
            erb :preview
          end
        else
          url = new_request.update(params[:_url], diff, mp_commands)
          redirect_post(url)
        end
      rescue MicropublishError => e
        if request.xhr?
          status 500
          e.message
        else
          set_flash('danger', e.message)
          params.key?('_all') ? render_edit_all : render_edit(params[:_subtype])
        end
      end
    end

    get '/delete' do
      require_session
      require_url
      @title = "Delete post at #{params[:url]}"
      erb :delete
    end

    post '/delete' do
      require_session
      url = new_request.delete(params[:url])
      redirect params[:url]
    end

    get '/undelete' do
      require_session
      require_url
      @title = "Undelete post at #{params[:url]}"
      erb :undelete
    end

    post '/undelete' do
      require_session
      url = new_request.undelete(params[:url])
      redirect params[:url]
    end

    post '/settings' do
      if params.key?('format') && ['json','form'].include?(params[:format])
        session[:format] = params[:format].to_sym
        format_label = params[:format] == 'json' ? 'JSON' : 'form-encoded'
        session[:flash] = {
          type: 'info',
          message: "Format setting updated to \"#{format_label}\". New posts " +
            "will be sent using #{format_label} format."
        }
      end
      redirect '/'
    end

    post '/logout' do
      logout!
    end

    get '/about' do
      @content = markdown(settings.readme)
      # use a better heading for the about page
      @content.sub!('<h1 id="micropublish">Micropublish</h1>',
        '<h1>About</h1>')
      @title = "About"
      erb :static
    end

    get '/changelog' do
      @content = markdown(settings.changelog)
      @title = "Changelog"
      erb :static
    end

    get '/redirect' do
      require_session
      redirect '/' unless params.key?('url')
      @url = params['url']
      # HTTP request to see if post exists yet
      response = HTTParty.get(@url)
      case response.code.to_i
      when 200
        redirect @url
      when 404
        erb :redirect
      else
        redirect_flash('/', 'danger', "There was an error redirecting to your" +
          " new post's URL (#{@url}). Status code #{h(response.code)}."
        )
      end
    end

    helpers do
      def micropub
        require_session
        Micropub.new(session[:micropub], session[:token])
      end

      def set_flash(type, message)
        session[:flash] = { type: type, message: message }
      end

      def redirect_flash(url, type, message)
        set_flash(type, message)
        redirect url
      end

      def syndicate_to(subtype = nil)
        micropub.syndicate_to(subtype) || []
      end

      def channels
        session[:channels] ||= micropub.channels
      end

      def logged_in?
        session.key?(:micropub)
      end

      def require_session
        redirect '/' unless logged_in?
      end

      def require_url
        begin
          micropub.validate_url!(params[:url])
        rescue MicropublishError => e
          redirect_flash('/', 'danger', e.message)
        end
      end

      def logout!
        micropub.cache_clear
        session.clear
        redirect '/'
      end

      def new_request
        require_session
        Request.new(session[:micropub], session[:token],
          session.key?('format') && session[:format] == :json)
      end

      def format_form_encoded(content)
        content.gsub(/&/,"\n&")
      end

      def render_new(subtype)
        @type = 'h-entry'
        @subtype = subtype
        @subtype_label = post_types[subtype]['name']
        @subtype_icon = post_types[subtype]['icon']
        @title = "New #{@subtype_label} (#{@type})"
        @post ||= Post.new(@type, Post.properties_from_params(params))
        @properties = post_types[subtype]['properties']
        @required = post_types[subtype]['required']
        @action_url = '/new'
        @action_label = "Create"
        # insert @username at start of content if replying to a tweet
        if @subtype == 'reply' && params.key?('in-reply-to') &&
            !@post.properties.key?('content')
          @post.properties['content'] =
            [tweet_reply_prefix(params['in-reply-to'])]
        end
        # default to current timestamp if using a published field
        if @properties.include?('published')
          @post.properties['published'] = [Time.now.utc.iso8601]
        end
        erb :form
      end

      def subtype_edit_properties(subtype)
        # for micropub.rocks only return content and category
        return %w(content category) if params.key?('rocks')

        post_types[subtype]['properties'] + %w(syndication published)
      end

      def render_edit(subtype)
        begin
          @post ||= micropub.source_properties(params[:url],
            subtype_edit_properties(subtype))
        rescue MicropubError => e
          redirect_flash('/', 'danger', e.message)
        end
        @subtype = subtype
        @subtype_label = post_types[subtype]['name']
        @subtype_icon = post_types[subtype]['icon']
        @title = "Edit #{@subtype_label} at #{params[:url] || params[:_url]}"
        @type = 'h-entry'
        @properties = subtype_edit_properties(subtype)
        @required = post_types[subtype]['required']
        @edit = true
        @action_url = '/edit'
        @action_label = "Update"
        erb :form
      end

      def render_edit_all
        begin
          @post ||= micropub.source_all(params[:url])
        rescue MicropubError => e
          redirect_flash('/', 'danger', e.message)
        end
        @title = "Edit post at #{params[:url] || params[:_url]}"
        @type = 'h-entry'
        @properties = []
        @required = []
        @edit = true
        @all = true
        @action_url = '/edit'
        @action_label = 'Update'
        erb :form
      end

      def redirect_post(url)
        encoded_url = CGI.escape(url)
        redirect "/redirect?url=#{encoded_url}"
      end
    end

    def config
      micropub.config
    end

    def post_types
      setting_types = settings.properties['types']['h-entry']
      if config.is_a?(Hash) && config.key?('post-types') &&
          config['post-types'].is_a?(Array)
        h_entry = {}
        config['post-types'].each do |type|
          # skip if we don't support type
          next unless setting_types.key?(type['type'])
          default_type = setting_types[type['type']]
          h_entry[type['type']] = {
            'name' => type['name'],
            'icon' => default_type['icon']
          }
          h_entry[type['type']]['properties'] =
            if type.key?('properties') && type['properties'].is_a?(Array)
              type['properties']
            else
              default_type['properties']
            end
          h_entry[type['type']]['required'] =
            if type.key?('required-properties') &&
                type['required-properties'].is_a?(Array)
              type['required-properties']
            else
              default_type['required']
            end
        end
        h_entry
      else
        setting_types
      end
    end

    error do
      @error = env['sinatra.error']
      header = %Q{
        <p><a href="javascript:history.back()">&larr;&nbsp;Back</a></p>
        <h1>Something went wrong</h1><br>
        <div class="alert alert-danger">
          #{@error.message}
        </div>
      }
      @content = header + markdown(settings.help)
      erb :static
    end

  end
end