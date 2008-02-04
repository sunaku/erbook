# project information

Gerbil = {
  :name    => 'Gerbil',
  :version => '2.0.0',
  :release => '2008-02-03',
  :website => 'http://gerbil.rubyforge.org',
  :home    => File.expand_path(File.join(File.dirname(__FILE__), '..'))
}
Gerbil[:format_home] = File.join(Gerbil[:home], 'fmt')
Gerbil[:format_files] = Dir[File.join(Gerbil[:format_home], '*.yaml')]

class << Gerbil
  # Returns the name and version.
  def to_s
    self[:name] + ' ' + self[:version]
  end

  # throw an exception instead of returning nil
  alias [] fetch
end
