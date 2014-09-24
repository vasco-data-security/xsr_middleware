Gem::Specification.new do |s|
  s.name         = 'xsr_middleware'
  s.version      = '1.0.2'
  s.date         = '2014-09-24'
  s.summary      = 'XSR middleware'
  s.description  = "A middleware used to follow a user's path (anonymously) across different services."
  s.authors      = ['Dimitri De Frenne', 'Kjel Delaey']
  s.email        = 'dimitri.defrenne@vasco.com'
  s.files        = Dir["{lib}/**/*.rb"]
  s.require_path = 'lib'
  s.homepage     = 'https://git.vasco.com/dps/xsr_middleware'

  s.add_runtime_dependency "log4r", "1.1.10"

  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
end
