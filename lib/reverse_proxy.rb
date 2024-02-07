require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rack'
  gem 'rack-reverse-proxy'
  gem 'base64'
  gem 'thin'
end

require 'rack'
require 'rack/reverse_proxy'
require 'thin'

class HealthzMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/healthz'
      [204, {}, []]
    else
      @app.call(env)
    end
  end
end

class BasicAuthMiddleware
  def initialize(app, username, password)
    @app, @username, @password = app, username, password
  end

  def call(env)
    if !@username || !@password || authorized?(env)
      @app.call(env)
    else
      [401, { 'Content-Type' => 'text/plain', 'WWW-Authenticate' => 'Basic realm="Reverse Proxy"' }, []]
    end
  end

  private

  def authorized?(env)
    auth = Rack::Auth::Basic::Request.new(env)
    auth.provided? && auth.basic? && auth.credentials == [@username, @password]
  end
end

app = Rack::Builder.new do
  use HealthzMiddleware
  use BasicAuthMiddleware, ENV['PROXY_AUTH_USERNAME'], ENV['PROXY_AUTH_PASSWORD']
  use Rack::ReverseProxy do
    reverse_proxy('/', 'http://localhost:3080')
  end
  run ->(_) { [404, {}, []] }
end

Thin::Server.start('0.0.0.0', 3000, app)
