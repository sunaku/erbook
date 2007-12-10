# Copyright 2007 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'rake/clean'
require 'rake/gempackagetask'

load 'gerbil' # does not have a '.rb' extension, so we cannot use require()

GENERATOR[:id] = GENERATOR[:name].downcase
GENERATOR[:ssh] = "snk@rubyforge.org:/var/www/gforge-projects/#{GENERATOR[:id]}"

# documentation
  desc "Generate documentation."
  task :doc => 'doc/guide.html'

  file 'doc/guide.html' => 'doc/guide.erb' do |t|
    sh "ruby gerbil html #{t.prerequisites} > #{t.name}"
  end

  CLOBBER.include 'doc/guide.html'

# packaging
  spec = Gem::Specification.new do |s|
    s.name        = GENERATOR[:id]
    s.version     = GENERATOR[:version]
    s.summary     = 'Extensible document generator based on eRuby.'
    s.description = s.summary
    s.homepage    = GENERATOR[:website]
    s.files       = FileList['**/*'].exclude('_darcs', File.basename(__FILE__))
    s.executables = GENERATOR[:id]
    s.bindir      = '.' # our executable is not inside 'bin/'

    s.add_dependency 'RedCloth' # needed by the default 'html' format
    s.add_dependency 'coderay'  # needed by the default 'html' format
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
  end

# releasing
  desc 'Build packages for distribution.'
  task :dist => :doc do
    system 'rake package'
  end

# utility
  desc "Show a list of available tasks."
  task :default do
    Rake.application.options.show_task_pattern = //
    Rake.application.display_tasks_and_comments
  end

  desc 'Connect to website FTP.'
  task :ftp do
    sh 'lftp', "sftp://#{GENERATOR[:ssh]}"
  end
