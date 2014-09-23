Gem::Specification.new do |s|
  s.name         = 'xsr_middleware'
  s.version      = '0.0.0'
  s.date         = '2014-09-19'
  s.summary      = 'XSR middleware'
  s.description  = ''
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
