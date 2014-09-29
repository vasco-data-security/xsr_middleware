# Cross Site Request Middleware

## Description
A middleware used to follow a user's path (anonymously) across different services.

## Installation
- Gemfile:
```ruby
gem 'xsr_middleware', git: "ssh://git@git.vasco.com/dps/xsr_middleware.git"
```
- config/application.rb
```ruby
config.middleware.use XsrMiddleware
```

### When using mdp_rest_client
- config/initializers/rest_client.rb
```ruby
config.request_context = XsrMiddleware::RequestContext.instance
```

## Log4r-integration
XSR Middleware adds a few keys to Log4r for easy logging:
- ```request```: MDP Request ID
- ```tracking```: MDP Tracking ID
- ```operator```: Operator (only usable in MDP and MDP Backoffice)

These can be used in the PatternFormatter of Log4r.
