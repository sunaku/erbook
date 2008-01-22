# project information

Gerbil = {
  :name    => 'Gerbil',
  :version => '1.1.0',
  :release => '2008-01-22',
  :website => 'http://gerbil.rubyforge.org',
  :home    => File.expand_path(File.join(File.dirname(__FILE__), '..'))
}
Gerbil[:format_home] = File.join(Gerbil[:home], 'fmt')
Gerbil[:format_files] = Dir[File.join(Gerbil[:format_home], '*.yaml')]
