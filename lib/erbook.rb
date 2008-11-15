# Project and release information.
module ERBook
  PROJECT = 'erbook'
  VERSION = '4.0.0'
  RELEASE = '2008-11-15'
  WEBSITE = 'http://snk.tuxfamily.org/lib/erbook'
  SUMMARY = 'Extensible document processor based on eRuby.'
  DISPLAY = PROJECT + ' ' + VERSION

  INSTALL_DIR = File.expand_path File.join(File.dirname(__FILE__), '..')
  FORMATS_DIR = File.join INSTALL_DIR, 'fmt'
  FORMAT_FILES = Dir[File.join(FORMATS_DIR, '*.yaml')]
end
