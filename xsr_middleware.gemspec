Gem::Specification.new do |s|
  s.name         = 'xsr'
  s.version      = '2.0.0'
  s.date         = '2018-08-13'
  s.summary      = 'XSR middleware'
  s.description  = "A middleware used to follow a user's path (anonymously) across different services."
  s.authors      = ['Maxime Robert-Schreyers', 'Toon Nevelsteen']
  s.email        = 'nevelto1@onespan.com'
  s.files        = Dir["{lib}/**/*.rb"]
  s.require_path = 'lib'
  s.homepage     = 'https://git.onespan.com/dps/xsr_middleware'

  s.add_runtime_dependency "log4r", "1.1.10"

  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
end
