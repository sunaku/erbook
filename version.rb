# project information

Gerbil = {
  :name    => 'Gerbil',
  :version => '0.0.1',
  :release => '2007-12-13',
  :website => 'http://gerbil.rubyforge.org',
  :home    => File.dirname(__FILE__),
}
Gerbil[:format_home]  = File.join(Gerbil[:home], 'fmt')
Gerbil[:format_files] = Dir[File.join(Gerbil[:format_home], '*.yaml')]
