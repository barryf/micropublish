module Micropublish
  class Server < Sinatra::Base
  
    configure do
      set :views, "#{File.dirname(__FILE__)}/../../views"

      # use a cookie that lasts for 30 days
      use Rack::Session::Cookie, secret: ENV['COOKIE_SECRET'], expire_after: 2592000
    end
  
    before do
      if logged_in?
        @bookmark_url = "#{request.base_url}/?micropub_endpoint=#{CGI::escape(session[:micropub_endpoint])}"
        @bookmark_url += "&token=#{CGI::escape(session[:token])}" 
      end
    end
  
    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end
    end

    get '/' do
      redirect :new if logged_in?
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
        redirect_uri: "#{request.base_url}/auth/callback"
      }
      query = URI.encode_www_form(hash)
      redirect "#{endpoints[:authorization_endpoint]}?#{query}"
    end
  
    get '/auth/callback' do
      puts "params=#{params.inspect}"
      endpoints_and_token = Auth.callback(params[:me], params[:code], session[:state], "#{request.base_url}/auth/callback")
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
      @post_type = post_type || 'note'
      @fields = post_type_fields(post_type)
      @post_types = %w(note article bookmark reply repost like)
      @post_type_icons = %w(comment file-text bookmark reply retweet heart)
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
    
    def post_type_fields(post_type)
      case post_type
      when 'article'
        %i(name content category)
      when 'bookmark'
        %i(bookmark content category)
      when 'reply'
        %i(in_reply_to content category)
      when 'repost'
        %i(repost_of category)
      when 'like'
        %i(like_of category)
      else
        %i(content category)
      end
    end

  end
end
