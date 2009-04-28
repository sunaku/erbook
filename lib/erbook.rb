require 'rubygems'
gem 'inochi', '~> 1'
require 'inochi'

Inochi.init :ERBook,
  :program => 'erbook',
  :version => '6.1.0',
  :release => '2009-02-14',
  :website => 'http://snk.tuxfamily.org/lib/erbook/',
  :tagline => 'Extensible document processor based on eRuby',
  :require => {
    'maruku'    => '~> 0.5', # for Markdown to XHTML conversion
    'coderay'   => '>= 0.8', # for syntax coloring of source code
    'rainpress' => '~> 1',   # for minifying CSS
  }

module ERBook
  FORMATS_DIR = File.join(INSTALL, 'fmt')
  FORMAT_FILES = Dir[File.join(FORMATS_DIR, '*.yaml')]
end

require 'erbook/document'
