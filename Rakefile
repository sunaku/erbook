# Copyright 2007 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'rake/clean'
require 'rake/gempackagetask'

require 'version'
Gerbil[:id] = Gerbil[:name].downcase
Gerbil[:ssh] = "snk@rubyforge.org:/var/www/gforge-projects/#{Gerbil[:id]}"

# documentation
  desc "Generate documentation."
  task :doc => 'doc/guide.html'

  file 'doc/guide.html' => 'doc/guide.erb' do |t|
    sh "ruby gerbil html #{t.prerequisites} > #{t.name}"
  end

  CLOBBER.include 'doc/guide.html'

# packaging
  spec = Gem::Specification.new do |s|
    s.name        = Gerbil[:id]
    s.version     = Gerbil[:version]
    s.summary     = 'Extensible document generator based on eRuby.'
    s.description = s.summary
    s.homepage    = Gerbil[:website]
    s.files       = FileList['**/*'].exclude('_darcs')
    s.executables = Gerbil[:id]
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
  task :release => [:clobber, :doc] do
    system 'rake package'
  end

  desc 'Create announcement feed.'
  file 'rss.xml' => 'CHANGES.yaml' do |t|
    require 'gerbil/html'
    require 'yaml'
    require 'time'

    feed = Template.new('feed', <<-EOS.gsub(/^ {6}/, '')).result(binding)
      <?xml version="1.0" encoding="utf-8"?>
      <rss version="2.0">
      <channel>
        <title><%= Gerbil[:name] %></title>
        <link><%= spec.homepage %></link>
        <description><%= spec.summary %></description>
        <lastBuildDate><%= Time.now.rfc822 %></lastBuildDate>
      <% YAML.load_documents(File.open(t.prerequisites[0])) do |item| %>
        <item>
          <title>Version <%= item['version'] %></title>
          <guid><%= item.to_s.digest %></guid>
          <pubDate><%= Time.parse(item['release'].to_s).rfc822 %></pubDate>
          <description><%=h item['message'].to_s.to_html %></description>
        </item>
      <% end %>
      </channel>
      </rss>
    EOS

    File.open(t.name, 'w') {|f| f << feed}
  end
  CLOBBER.include 'rss.xml'

# utility
  desc 'Connect to website FTP.'
  task :ftp do
    sh 'lftp', "sftp://#{Gerbil[:ssh]}"
  end

  desc 'Upload to project website.'
  task :upload => [:doc, 'rss.xml'] do
    sh 'rsync', '-avz', 'doc/', 'rss.xml', Gerbil[:ssh]
  end
