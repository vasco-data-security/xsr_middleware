# Cross Service Request Middleware

## Description
A middleware used to follow a user's path (anonymously) across different services.

## Installation

### Installing the gem
```
# Gemfile

source "http://rubygems.org"

gem 'xsr', git: "ssh://git@git.vasco.com/dps/xsr_middleware.git"
```

### Adding the Middleware
You can add the Xsr middleware to the middleware stack using any of the following methods:

* ```config.middleware.use Xsr::Middleware```: Adds the Xsr middleware at the bottom of the middleware stack.
* ```config.middleware.insert_before existing_middleware, Xsr::Middleware```: Adds the Xsr middleware before the specified existing middleware in the middleware stack.
* ```config.middleware.insert_after existing_middleware, Xsr::Middleware```: Adds the Xsr middleware after the specified existing middleware in the middleware stack.

```ruby
# config/application.rb

config.middleware.use Xsr::Middleware
```

### When using mdp_rest_client
Add the Xsr middleware to the middleware stack as described in the _Adding the Middleware_ section and configure the rest client.

```ruby
# config/initializers/rest_client.rb

config.request_context = Xsr::RequestContext.instance
```

It will set the ```X-Mdp-Request-Id``` and ```X-Mpd-Tracking-Id``` headers automatically.

### When using HTTPClient
When using HTTPClient, or using the `curl` command you'll need to pass the headers by yourself so that the application you are communicating with can use the values from the existing headers instead of generating new IDs upon each request. As a result the response headers will contain the same values too.

```ruby
# lib/foo.rb

require 'httpclient'
require 'httpclient/include_client'

class Foo
  extend HTTPClient::IncludeClient

  include_http_client

  def self.bar
    res = self.http_client.post( uri,
                                { api_key: '' },
                                { 'X-Mdp-Request-Id' => Xsr::RequestContext.mdp_request_id,
                                  'X-Mdp-Tracking-Id' => Xsr::RequestContext.tracking_idli } )

    p res.header['X-Mdp-Request-Id']
    p res.header['X-Mdp-Tracking-Id']
  end
end

```

## Log4r-integration
XSR Middleware adds a few keys to Log4r for easy logging:
- ```request```: MDP Request ID
- ```tracking```: MDP Tracking ID
- ```operator```: Operator (only usable in MDP and MDP Backoffice)

These can be used in the PatternFormatter of Log4r.

```yaml
# config/settings/production.yml

log_to: log4r_config
log4r_config:
  loggers:
    - name: production
      outputters:
        - syslog

  outputters:
    - type: SyslogOutputter
      name: syslog
      level: INFO
      ident: _app_production_name_of_the_service
      facility: LOG_USER
      formatter:
        pattern: '%5l [%p:%X{request}:%X{tracking}:%X{operator}] %m'
        type: PatternFormatter
```