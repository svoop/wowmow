[![Release](https://img.shields.io/github/v/release/svoop/wowmow.svg?style=flat)](https://github.com/svoop/wowmow/releases)
[![Donorbox](https://img.shields.io/badge/donate-on_donorbox-yellow.svg)](https://donorbox.org/bitcetera)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/svoop.svg)](https://github.com/sponsors/svoop)

# 🐛🕳️ wowmow

### Development Reverse Proxy for Render

A minimalistic reverse proxy on [Render](https://render.com) which makes your local development web server reachable from anywhere. This comes in very handy when testing webhooks and such. Think of it as a simple yet private and low-cost alternative to services like [ngrok](https://ngrok.com) or [loca.lt](https://loca.lt).

* [Homepage](https://github.com/svoop/wowmow)
* Author: [Sven Schwyn - Bitcetera](https://bitcetera.com)

Thank you for supporting free and open-source software by sponsoring on [GitHub](https://github.com/sponsors/svoop) or on [Donorbox](https://donorbox.com/bitcetera). Any gesture is appreciated, from a single Euro for a ☕️ cup of coffee to 🍹 early retirement.

## Architecture

The `reverse_proxy.rb` script is a very simple self-contained Rack app which does two things:

* It responds to `/healthz` with status 204 to satisfy the health check by Render.
* It reverse proxies all other requests to port 3080.

This script is designed to be run by a web service instance on Render. All you have to do is forward your local web server port (e.g. the default Rails port 3000) via an SSH tunnel to port 3080 on the web service instance.

Render takes care of SSL, so you can access the reverse proxy on its public (or custom) domain using HTTPS whereas your local web server still serves HTTP.

Please note: The free tier offered by Render does not feature SSH access, so you have to use at least the starter plan for a few bucks per month. You can further cut the cost by suspending the web service when not in use.

⚠️ A reverse proxy is a great place to put spyware. Even though I would never do that, you should not take my word for it: **Don't** use [my canonical repository URL](https://github.com/svoop/wowmow) as the repository your web service instance pulls from, but first [create your own fork](https://github.com/svoop/wowmow/fork) and use its repository URL instead!

## Install

On Render, spin up a new web service instance from [this blueprint](https://raw.githubusercontent.com/svoop/wowmow/main/render.yaml):

1. Create your [own fork](https://github.com/svoop/wowmow/fork).
2. Access the [new blueprint instance page](https://dashboard.render.com/select-repo?type=blueprint).
3. Select the repository which contains your fork.
4. Optionally add a custom domain.
5. Start the web service instance.

This blueprint enables basic auth by default with username `development` and a randomly generated password. You can change them by editing the environment variables `PROXY_AUTH_USERNAME` and `PROXY_AUTH_PASSWORD`. To disable basic auth, just delete both environment variables.

⚠️ The blueprint selects region "Frankfurt" by default in order to assure compliance with GDPR in case you're located in Europe. If that's not the case, you might want to edit the `render.yaml` and [chose a different region](https://docs.render.com/blueprint-spec#region) before you create the instance.

## Usage

To establish the SSH tunnel, connect to your web service instance like so:

```
ssh -N -R 3080:localhost:3000 ssh srv-xxxxxxxxxxxxxxxxxxx0@ssh.xxxxxxxx.render.com
```

This example assumes you have a Rails server on the default `localhost:3000`. If your app is served on a different local port, just replace the `3000` with the corresponding port number.

You have to replace the connection string `srv-...` with the one Render has generated for your particular web service instance. You find it in the "Shell" menu.

Can't connect? You most likely forgot to add your SSH public key on the Account Settings page of your user on Render or the SSH public key is out of date.

### Rake

You might want to create a Rake task to establish the SSH tunnel with a simple command like:

```
rake "proxied_server[srv-xxxxxxxxxxxxxxxxxxx0@ssh.xxxxxxxx.render.com]"
```

For a Rails app and a reverse proxy on `wowmow.onrender.com`, such a task might look something like this:

```ruby
desc "Start a local server proxied via Render"
task :proxied_server, [:ssh] => [:environment] do |_, args|
  system("ssh -fN -MS /tmp/tunnel-ssh.socket -R 3080:localhost:3000 #{args[:ssh]}")
  ENV['HOST'] = 'wowmow.onrender.com'
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

## Gotchas

Say you have a Rails app and you would like to test webhooks calling some routes of your app. Hopefully, the webhook issuer provides proper means to validate the requests. However, in case you simply restrict the IP addresses the webhook is allowed to comes from, you have to keep the following in mind:

Rails gets the client IP from Rack and exposes it as `request.ip`. When using a reverse proxy, this proxy is the client and therefore `request.ip` always returns the IP of the proxy. To get the real remote IP of the client, you have to use `request.remote_ip` instead.

## Trivia

"wowmow" is the [Belter Creole](https://en.wikipedia.org/wiki/Belter_Creole) translation for "wormhole".

## Development

You're welcome to join the [discussion forum](https://github.com/svoop/wowmow/discussions) to ask questions or drop feature ideas, [submit issues](https://github.com/svoop/wowmow/issues) you may encounter or contribute code by [forking this project and submitting pull requests](https://docs.github.com/en/get-started/quickstart/fork-a-repo).
