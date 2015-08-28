module Micropublish
  class Server < Sinatra::Base
    configure do
      set :views, "#{File.dirname(__FILE__)}/../../views"
      set :public_folder, "#{File.dirname(__FILE__)}/../../public"
      
      # ensure ssl
      use Rack::SSL unless settings.development?

      # use a cookie that lasts for 30 days
      secret = ENV['COOKIE_SECRET'] || Random.new_seed.to_s
      use Rack::Session::Cookie, secret: secret, expire_after: 2_592_000
      
      use Rack::Flash
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
      logout!("Please enter your site's URL.") unless params.key?('me') && !params['me'].empty?
      # prepend http:// if missing
      me = params['me']
      me << "http://" unless params[:me].start_with?('http://') || params[:me].start_with?('https://')
      # find endpoints for 'me'
      endpoints = Auth.find_endpoints(me)
      logout!("No endpoints were found at #{me}. Please check your site is Micropub-compliant.") if endpoints.nil?
      # define random state string
      session[:state] = Auth.generate_state
      hash = {
        me: me,
        client_id: client_id,
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
                                          "#{request.base_url}/auth/callback",
                                          client_id)
      logout!("No endpoints were found at #{params[:me]}. Please check your site is Micropub-compliant.") if endpoints_and_token.nil?
      # login and token grant was successful so store in session
      session.merge!(endpoints_and_token)
      redirect :new
    end

    post '/logout' do
      logout!
    end

    get %r{^/new/?(note|article|bookmark|reply|repost|like)?/?$} do |post_type|
      require_session
      if post_type == 'reply' && params.key?('in_reply_to')
        reply_username = Micropub.reply_username(params['in_reply_to'])
        params['content'] ||= "@#{reply_username} " unless reply_username.nil?
      end
      @post_type = (post_type || 'note').to_sym
      erb :new
    end

    post '/create' do
      require_session
      post_url = Micropub.post(session[:micropub_endpoint], 
                               params,
                               session[:token])
      if post_url.nil?
        redirect :new
      else
        redirect post_url
      end
    end
    
    get '/about' do
      erb :about
    end
    
    get '/twitter-text.js' do
      send_file "#{File.dirname(__FILE__)}/../../vendor/twitter-text/js/twitter-text.js"
    end

    def require_session
      redirect '/' unless logged_in?
    end

    def logout!(message=nil)
      session.clear
      flash[:notice] = message unless message.nil?
      redirect '/'
    end

    def logged_in?
      session.key?(:micropub_endpoint) && session.key?(:token)
    end

    def post_types
      Micropub.post_types
    end

    def syndicate_to
      session[:syndicate_to] ||= Micropub.syndicate_to(
        session[:micropub_endpoint], session[:token])
    end
    
    def client_id
      @client_id ||= request.base_url
    end
  end
end
