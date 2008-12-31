# Project and release information.
module ERBook
  PROJECT = 'erbook'
  VERSION = '5.0.0'
  RELEASE = '2008-11-22'
  WEBSITE = "http://snk.tuxfamily.org/lib/#{PROJECT}"
  SUMMARY = 'Extensible document processor based on eRuby.'
  DISPLAY = PROJECT + ' ' + VERSION

  INSTALL_DIR = File.expand_path File.join(File.dirname(__FILE__), '..')
  FORMATS_DIR = File.join INSTALL_DIR, 'fmt'
  FORMAT_FILES = Dir[File.join(FORMATS_DIR, '*.yaml')]
end

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'erbook/document'
