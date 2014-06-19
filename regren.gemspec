Gem::Specification.new do |s|
	s.name = 'regren'
	s.version = '0.0.1'
	s.date = '2014-06-28'
	s.summary = 'regren'
	s.homepage = 'https://github.com/adamruzicka/regren'
	s.description = 'A simple gem for batch renaming files'
	s.authors = ['Adam Ruzicka']
	s.email = 'a.ruzicka@outlook.com'
	s.files = Dir['{bin,lib,test}/**/*']
	s.require_paths = ['lib']
	s.executables << 'regren'
	s.license = 'MIT'
	s.add_dependency 'json', '~> 0'
	s.add_development_dependency 'minitest', '~> 0'
end
