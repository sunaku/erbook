require 'rubygems'
require 'inochi'

Inochi.init :ERBook,
  :program => 'erbook',
  :version => '6.0.0',
  :release => '2009-01-19',
  :website => 'http://snk.tuxfamily.org/lib/erbook/',
  :tagline => 'Extensible document processor based on eRuby',
  :require => {
    # gems needed by the default 'xhtml' format
    'maruku'  => '~> 0.5',
    'coderay' => '>= 0.7',
  }

module ERBook
  FORMATS_DIR = File.join(INSTALL, 'fmt')
  FORMAT_FILES = Dir[File.join(FORMATS_DIR, '*.yaml')]
end

require 'erbook/document'
