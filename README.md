# Development Reverse Proxy for Render

Minimalistic reverse proxy to forward a local development web server via [Render](https://render.com). This comes in very handy in situations where you need your local web server to be reachable by external services such as webhooks. Think of it as a simple yet private and low-cost alternative to services like [ngrok](https://ngrok.com) or [loca.lt](https://loca.lt).

* [Homepage](https://github.com/svoop/development-proxy-render)
* Author: [Sven Schwyn - Bitcetera](https://bitcetera.com)

## Architecture

The `reverse_proxy.rb` script is a very simple self-contained Rack app which does two things:

* It responds to `/healthz` with status 204 to satisfy the health check by Render.
* It reverse proxies all other requests to port 3080.

This script is designed to be run by a web service instance on Render. All you have to do is forward your local web server port (e.g. the default Rails port 3000) via an SSH tunnel to port 3080 on the web service instance (see [usage](#usage) below).

Render takes care of SSL, so you can access the reverse proxy on its public (custom) domain using HTTPS whereas your local web server serves HTTP.

Please note: The free tier offered by Render does not feature SSH access, so you have to use at least the starter plan for a few bucks per month. You can further cut the cost by suspending the web service when not in use.

## Security

A reverse proxy is a great place to put spyware. Even thou I would never do that, you should not take my word for it: **Don't** use [my canonical repository URL](https://github.com/svoop/development-proxy-render) as the repository your web service instance pulls from, but first [create your own fork](https://github.com/svoop/development-proxy-render/fork) and use its repository URL instead!

## Install

The `reverse_proxy.rb` is self-contained, it uses inline Bundler to install and load the few required gems. In other words: `bundle install` is not necessary and collisions with other bundles are not possible.

Therefore, the recommended way to use `reverse_proxy.rb` is to just download and place it somewhere inside an existing project repository which can be used to deploy the project as well as the development proxy:

```
wget https://raw.githubusercontent.com/svoop/development-proxy-render/main/reverse_proxy.rb
```

There's nothing to build and starting the proxy is dead simple:

```
ruby reverse_proxy.rb
```

Alternatively, you can spin up a new web service instance from [this blueprint](https://raw.githubusercontent.com/svoop/development-proxy-render/main/render.yaml):

1. Create your [own fork](https://github.com/svoop/development-proxy-render/fork).
2. Access the [new blueprint instance page](https://dashboard.render.com/select-repo?type=blueprint).
3. Select the repository which contains your fork.
4. Optionally add a custom domain.
5. Start the web service instance.

## Usage

Say, you have Rails app running on the default `localhost:3000`.

To establish the SSH tunnel, connect to your web service instance like so:

```
ssh -N -R 3080:localhost:3000 ssh srv-xxxxxxxxxxxxxxxxxxx0@ssh.xxxxxxxx.render.com
```

Please replace the connection string `srv-...` with the one Render has generated for your particular web service instance. You find it in the "Shell" menu.

Can't connect? You most likely forgot to add your SSH public key on the Account Settings page of your user on Render or the SSH public key is out of date.

### Rake

You might want to create a Rake task to establish the SSH tunnel with a simple command like:

```
rake "proxied_server[srv-xxxxxxxxxxxxxxxxxxx0@ssh.xxxxxxxx.render.com]"
```

For a Rails app and a reverse proxy on `development-proxy.onrender.com`, such a task might look something like this:

```ruby
desc "Start a local server proxied via Render"
task :proxied_server, [:ssh] => [:environment] do |_, args|
  system("ssh -fN -MS /tmp/tunnel-ssh.socket -R 3080:localhost:3000 #{args[:ssh]}")
  ENV['HOST'] = 'development-proxy.onrender.com'
  ENV['PORT'] = '443'
  ENV['PROTOCOL'] = 'https'
  system("rails server --port 3000")
ensure
  `ssh -S /tmp/tunnel-ssh.socket -O exit #{args[:ssh]} >/dev/null`
end
```

These environment variables are just an example and not part of a vanilla Rails app. They should configure your local Rails to use the public host of the reverse proxy e.g. when building URLs. Here's one way to do this in `config/environments/development.rb`:

```ruby
Rails.application.configure do

  config.action_mailer.default_url_options = {
    protocol: ENV['PROTOCOL'] || 'http',
    host: ENV['HOST'] || 'localhost',
    port: ENV['PORT'] || 3000
  }
  Rails.application.routes.default_url_options = config.action_mailer.default_url_options

end
```

## Development

You're welcome to join the [discussion forum](https://github.com/svoop/development-proxy-render/discussions) to ask questions or drop feature ideas, [submit issues](https://github.com/svoop/development-proxy-render/issues) you may encounter or contribute code by [forking this project and submitting pull requests](https://docs.github.com/en/get-started/quickstart/fork-a-repo).
