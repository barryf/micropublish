module Micropublish
  class Server < Sinatra::Base
    configure do
      set :views, "#{File.dirname(__FILE__)}/../../views"
      set :public_folder, "#{File.dirname(__FILE__)}/../../public"

      # use a cookie that lasts for 30 days
      secret = ENV['COOKIE_SECRET'] || Random.new_seed.to_s
      use Rack::Session::Cookie, secret: secret, expire_after: 2_592_000
    end

    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end

      def syndication_label(syndication)
        Micropub.syndication_label(syndication)
      end
    end

    get '/' do
      redirect :new if logged_in?
      erb :index
    end

    get '/auth' do
      # define random state string
      session[:state] = Auth.generate_state
      # find endpoints for 'me'
      endpoints = Auth.find_endpoints(params[:me])
      logout! if endpoints.nil?
      hash = {
        me: params[:me],
        client_id: 'Micropublish',
        state: session[:state],
        scope: 'post',
        redirect_uri: "#{request.base_url}/auth/callback"
      }
      query = URI.encode_www_form(hash)
      redirect "#{endpoints[:authorization_endpoint]}?#{query}"
    end

    get '/auth/callback' do
      puts "params=#{params.inspect}"
      endpoints_and_token = Auth.callback(params[:me], params[:code],
                                          session[:state],
                                          "#{request.base_url}/auth/callback")
      logout! if endpoints_and_token.nil?
      # login and token grant was successful so store in session
      session.merge!(endpoints_and_token)
      redirect :new
    end

    post '/logout' do
      logout!
    end

    get %r{^/new/?(note|article|bookmark|reply|repost|like)?/?$} do |post_type|
      require_session
      if post_type == 'reply'
        reply_username = Micropub.reply_username(params['in_reply_to'])
        params['content'] ||= "@#{reply_username} " unless reply_username.nil?
      end
      @post_type = (post_type || 'note').to_sym
      erb :new
    end

    post '/create' do
      require_session
      post_url = Micropub.post(session[:micropub_endpoint], params,
                               session[:token])
      if post_url.nil?
        redirect :new
      else
        redirect post_url
      end
    end

    def require_session
      redirect '/' unless logged_in?
    end

    def logout!
      session.clear
      redirect '/'
    end

    def logged_in?
      session.key?(:micropub_endpoint) && session.key?(:token)
    end

    def post_types
      {
        note:     { label: 'Note', icon: 'comment', fields: %i(content) },
        article:  { label: 'Article', icon: 'file-text',
                    fields: %i(name content) },
        bookmark: { label: 'Bookmark', icon: 'bookmark',
                    fields: %i(bookmark name content) },
        reply:    { label: 'Reply', icon: 'reply',
                    fields: %i(in_reply_to content) },
        repost:   { label: 'Repost', icon: 'retweet', fields: %i(repost_of) },
        like:     { label: 'Like', icon: 'heart', fields: %i(like_of) }
      }
    end

    def syndicate_to
      session[:syndicate_to] ||= Micropub.syndicate_to(
        session[:micropub_endpoint], session[:token])
    end
  end
end
