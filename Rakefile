# Copyright 2007 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'rake/clean'
require 'rake/gempackagetask'

# documentation
  desc "Generate documentation."
  task :doc => 'doc/guide.html'

  file 'doc/guide.html' => 'doc/guide.erb' do |t|
    sh "ruby bin/gerbil html #{t.prerequisites} > #{t.name}"
  end

  CLOBBER.include 'doc/guide.html'

# packaging
  require 'lib/gerbil' # project info

  spec = Gem::Specification.new do |s|
    s.name        = 'gerbil'
    s.version     = Gerbil[:version]
    s.summary     = 'Extensible document generator based on eRuby.'
    s.description = s.summary
    s.homepage    = Gerbil[:website]
    s.files       = FileList['**/*'].exclude('_darcs')
    s.executables = s.name

    s.add_dependency 'RedCloth' # needed by the default 'html' format
    s.add_dependency 'coderay'  # needed by the default 'html' format
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
  end

# releasing
  desc 'Build packages for distribution.'
  task :release => [:clobber, :doc] do
    system 'rake package'
  end

# utility
  desc 'Upload to project website.'
  task :upload => :doc do
    sh 'rsync -av doc/ ~/www/lib/gerbil'
  end
