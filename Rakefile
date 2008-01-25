# Copyright 2007 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'

# documentation
  desc "Build the documentation."
  task :doc

  # the user guide
  file 'doc/guide.html' => 'doc/guide.erb' do |t|
    sh "ruby bin/gerbil html #{t.prerequisites} > #{t.name}"
  end
  task :doc => 'doc/guide.html'
  CLOBBER.include 'doc/guide.html'

  # API reference
  Rake::RDocTask.new 'doc/api' do |t|
    t.rdoc_dir = t.name
    t.rdoc_files.exclude('_darcs', 'pkg').include('**/*.rb')
  end
  task :doc => 'doc/api'

# packaging
  require 'lib/gerbil' # project info

  spec = Gem::Specification.new do |s|
    s.name              = Gerbil[:name].downcase
    s.version           = Gerbil[:version]
    s.summary           = 'Extensible document generator based on eRuby.'
    s.description       = s.summary
    s.homepage          = Gerbil[:website]
    s.files             = FileList['**/*'].exclude('_darcs')
    s.executables       = s.name
    s.rubyforge_project = s.name
    s.has_rdoc          = true

    s.add_dependency 'RedCloth' # needed by the default 'html' format
    s.add_dependency 'coderay'  # needed by the default 'html' format
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
  end

# releasing
  desc 'Build release packages.'
  task :dist => [:clobber, :doc] do
    system 'rake package'
  end

# utility
  desc 'Upload to project website.'
  task :upload => :doc do
    sh "rsync -av doc/ ~/www/lib/#{spec.name}"
    sh "rsync -av doc/api/ ~/www/lib/#{spec.name}/api/ --delete"
  end
