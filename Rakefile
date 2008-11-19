require 'rake/clean'

# documentation
  desc "Build the documentation."
  task :doc

  # user manual
    src = 'doc/manual.erb'
    dst = 'doc/index.html'

    task :manual => dst
    task :doc => :manual

    file dst => src do
      sh "ruby bin/erbook -u html #{src} > #{dst}"
    end

    CLOBBER.include dst

  # API reference
    require 'rake/rdoctask'

    Rake::RDocTask.new 'doc/api' do |t|
      t.rdoc_dir = t.name
      t.rdoc_files.exclude('pkg').include('**/*.rb')
    end

    task :doc => 'doc/api'

# packaging
  require 'rake/gempackagetask'
  require 'lib/erbook' # project info

  spec = Gem::Specification.new do |s|
    s.rubyforge_project = 'sunaku'
    s.author, s.email   = File.read('LICENSE').
                          scan(/Copyright \d+ (.*) <(.*?)>/).first

    s.name              = ERBook::PROJECT
    s.version           = ERBook::VERSION
    s.summary           = ERBook::SUMMARY
    s.description       = s.summary
    s.homepage          = ERBook::WEBSITE
    s.files             = FileList['**/*']
    s.executables       = s.name
    s.has_rdoc          = true

    # gems needed by the main program executable
    s.add_dependency 'trollop', '~> 1.10'

    # gems needed by the default 'html' format
    s.add_dependency 'maruku', '~> 0.5'
    s.add_dependency 'coderay', '>= 0.7'
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
  end

  desc 'Build release packages.'
  task :pack => [:clobber, :doc] do
    sh $0, 'package'
  end

# releasing
  desc 'Upload to project website.'
  task :website => :doc do
    sh "rsync -av doc/ ~/www/lib/#{spec.name}"
    sh "rsync -av doc/api/ ~/www/lib/#{spec.name}/api/ --delete"
  end

  desc 'Publish release packages.'
  task :publish => :pack do
    sh 'rubyforge', 'login'

    Dir['pkg/*.[a-z]*'].each do |pkg|
      sh 'rubyforge', 'add_release', '--release_date', ERBook::RELEASE, spec.rubyforge_project, spec.name, spec.version.to_s, pkg
    end
  end
