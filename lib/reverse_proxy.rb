require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rack'
  gem 'rack-reverse-proxy'
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

app = Rack::Builder.new do
  use HealthzMiddleware
  use Rack::ReverseProxy do
    reverse_proxy '/', 'http://localhost:3080'
  end
  run ->(_) { [404, {}, []] }
end

Thin::Server.start('0.0.0.0', 3000, app)
