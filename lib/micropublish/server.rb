module Micropublish
  class Server < Sinatra::Application

    configure do
      helpers Helpers

      use Rack::SSL if settings.production?

      root_path = "#{File.dirname(__FILE__)}/../../"
      set :public_folder, "#{root_path}public"
      set :properties,
        JSON.parse(File.read("#{root_path}config/properties.json"))
      set :readme, File.read("#{root_path}README.md")

      set :server, :puma

      # use a cookie that lasts for 30 days
      secret = ENV['COOKIE_SECRET'] || Random.new_seed.to_s
      use Rack::Session::Cookie, secret: secret, expire_after: 2_592_000
    end

    #before do
    #  unless settings.production?
    #    session[:me] = 'http://localhost:9394/'
    #    session[:micropub] = 'http://localhost:9394/micropub'
    #    session[:scope] = 'create update delete undelete'
    #  end
    #end

    get '/' do
      if logged_in?
        @title = "Dashboard"
        @types = settings.properties['types']['h-entry']
        erb :dashboard
      else
        @title = "Sign in"
        @about = markdown(settings.readme)
        erb :login
      end
    end

    get '/auth' do
      unless params.key?('me') && !params[:me].empty? &&
          Auth.valid_uri?(params[:me])
        redirect_flash('/', 'danger',
          "Please enter your site's URL. " +
          "It must begin with <code>http://</code> or " +
          "<code>https://</code>.")
      end
      unless params.key?('scope') && (params[:scope] == 'post' ||
          params[:scope] == 'create update delete undelete')
        redirect_flash('/', 'danger',
          "Please select a scope: \"post\" or " +
          "\"create update delete undelete\".")
      end
      unless endpoints = EndpointsFinder.new(params[:me]).find_links
        redirect_flash('/', 'danger', "Could not find any endpoints " +
          "at \"#{params[:me]}\". Does this server support Micropub? " +
          "Please <a href=\"/about#endpoint-discovery\" class=\"alert-" +
          "link\">read&nbsp;the&nbsp;docs</a> for more information.")
      end
      # define random state string
      session[:state] = Random.new_seed.to_s
      # store scope - will be needed to limit functionality on dashboard
      session[:scope] = params[:scope]
      # redirect to auth endpoint
      query = URI.encode_www_form({
        me: params[:me],
        client_id: request.base_url,
        state: session[:state],
        scope: session[:scope],
        redirect_uri: "#{request.base_url}/auth/callback"
      })
      redirect "#{endpoints[:authorization_endpoint]}?#{query}"
    end

    get '/auth/callback' do
      auth = Auth.new(params[:me], params[:code], session[:state],
        "#{request.base_url}/auth/callback", request.base_url)
      begin
        endpoints_and_token = auth.callback
      rescue AuthError => e
        redirect_flash('/', 'danger', e.message)
      end
      # login and token grant was successful so store in session
      session.merge!(endpoints_and_token)
      session[:me] = params[:me]
      redirect_flash('/', 'success', %Q{You are now signed in successfully.
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

    get %r{^/new/h\-entry/(note|article|bookmark|reply|repost|like|rsvp)$} do
        |subtype|
      require_session
      render_new(subtype)
    end

    def render_new(subtype)
      @type = 'h-entry'
      @subtype = subtype
      @subtype_label = subtype == 'rsvp' ? 'RSVP' : subtype
      @title = "New #{@subtype_label} (#{@type})"
      @post ||= Post.new(@type, Post.properties_from_params(params))
      @properties =
        settings.properties['types']['h-entry'][subtype]['properties'] +
        settings.properties['default']
      @required =
        settings.properties['types']['h-entry'][subtype]['required']
      @action_url = '/new'
      @action_label = "Create"
      erb :form
    end

    post '/new' do
      require_session
      begin
        @post = Post.new([params[:_type]], Post.properties_from_params(params))
        required_properties =
          settings.properties['types'][params[:_type]][params[:_subtype]]['required']
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
          redirect url
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
      render_edit
    end

    def render_edit
      begin
        @post ||= micropub.source(params[:url])
      rescue MicropubError => e
        redirect_flash('/', 'danger', e.message)
      end
      @title = "Edit post at #{params[:url] || params[:_url]}"
      @type = 'h-entry'
      @properties = []
      @required = []
      @all = true
      @action_url = '/edit'
      @action_label = 'Update'
      erb :form
    end

    post '/edit' do
      require_session
      begin
        submitted_properties = Post.properties_from_params(params)
        @post = Post.new([params[:_type]], submitted_properties)
        @post.validate_properties!
        original = micropub.source(params[:_url])
        mp_commands = Micropub.find_commands(params)
        diff = Compare.new(original.properties, submitted_properties,
          settings.properties['known']).diff_properties
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
          redirect url
        end
      rescue MicropublishError => e
        if request.xhr?
          status 500
          e.message
        else
          set_flash('danger', e.message)
          render_edit
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
      @title = "About"
      erb :static
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

      def syndicate_to
        begin
          session[:syndicate_to] ||= micropub.syndicate_to || []
        rescue MicropublishError => e
          redirect_flash('/', 'danger', e.message)
        end
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
    end

  end
end