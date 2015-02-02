module Micropublish
  class Server < Sinatra::Base
    register Sinatra::ConfigFile
  
    configure do 
      config_file File.join(File.dirname(__FILE__),'../../config.yml')
      set :views, "#{File.dirname(__FILE__)}/../../views"

      # use a cookie that lasts for 30 days
      use Rack::Session::Cookie, secret: "LJyuMbeLdvwJ2F4tAfWRoo7uwenvxn", expire_after: 2592000
    end
  
    before do
      if logged_in?
        @bookmark_url = "#{settings.root_url}/?micropub_endpoint=#{CGI::escape(session[:micropub_endpoint])}"
        @bookmark_url += "&token=#{CGI::escape(session[:token])}" 
      end
    end
  
    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end
    end

    get '/' do
      # allow for bookmarked login
      if params.key?('micropub_endpoint') && params.key?('token')
        session[:micropub_endpoint] = params[:micropub_endpoint]
        session[:token] = params[:token]
        redirect '/'
      end
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
        client_id: "Micropublish",
        state: session[:state],
        scope: "post",
        redirect_uri: "#{settings.root_url}/auth/callback"
      }
      query = URI.encode_www_form(hash)
      redirect "#{endpoints[:authorization_endpoint]}?#{query}"
    end
  
    get '/auth/callback' do
      puts "params=#{params.inspect}"
      endpoints_and_token = Auth.callback(params[:me], params[:code], session[:state], "#{settings.root_url}/auth/callback")
      logout! if endpoints_and_token.nil?
      # login and token grant was successful so store in session
      session.merge!(endpoints_and_token)
      redirect :new
    end
  
    post '/logout' do
      logout!
    end
  
    get '/new' do
      require_session
      erb :new
    end
  
    post '/create' do
      require_session
      post_url = Micropub.post(session[:micropub_endpoint], params, session[:token])
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

  end
end
