# Workaround for: `rdoc --fmt xml` does not dump information about methods.

require 'rubygems'
gem 'rdoc', '>= 2.4.3', '< 2.5'
require 'rdoc/rdoc'

module RDoc
  class TopLevel
    # Returns an array of all classes recorded thus far.
    def self.all_classes
      @all_classes.values
    end

    # Returns an array of all modules recorded thus far.
    def self.all_modules
      @all_modules.values
    end

    # Returns an array of RDoc::AnyMethod objects
    # representing all methods recorded thus far.
    def self.all_methods
      all_classes_and_modules.map {|c| c.method_list }.flatten
    end

    # Update the return value of the all_classes_and_modules() method
    # to *really* include every class and every module seen thus far.
    def self.refresh_all_classes_and_modules
      visit = lambda do |node|
        if node.is_a? NormalClass or node.is_a? SingleClass
          @all_classes[node.full_name] = node

        elsif node.is_a? NormalModule
          @all_modules[node.full_name] = node
        end

        (node.classes + node.modules).each {|n| visit[n] }
      end

      all_classes_and_modules.each {|n| visit[n] }
    end

    # Returns a RDoc::TopLevel object containing information
    # parsed from the given code string.  This information is
    # also added to the global TopLevel class state, so you can
    # access it via the class methods of the TopLevel class.
    #
    # If the file name (which signifies the origin
    # of the given code) is given, it MUST have a
    # ".c" or ".rb" file extension.  Otherwise,
    # RDoc will ignore the given code string!  :-(
    #
    def self.parse aCodeString, aFileName = __FILE__
      tl = TopLevel.new(aFileName)
      op = DummyOptions.new
      st = Stats.new(0)

      result = Parser.for(tl, aFileName, aCodeString, op, st).scan

      refresh_all_classes_and_modules

      result
    end

    # Returns a RDoc::TopLevel object containing information
    # parsed from the code in the given file.  This information
    # is also added to the global TopLevel class state, so you
    # can access it via the class methods of the TopLevel class.
    #
    # The given file name MUST have a ".c" or ".rb" file
    # extension.  Otherwise, RDoc will ignore the file!  :-(
    #
    def self.parse_file aFileName
      parse File.read(aFileName), aFileName
    end
  end

  class AnyMethod
    # Returns the fully qualified name of this method.
    def full_name
      [parent.full_name, name].join(singleton ? '::' : '#')
    end

    # Returns a complete method declaration with block parameters and all.
    def decl
      a = params.dup
      if b = block_params
        a.sub! %r/\s*\#.*(?=.$)/, '' # remove "# :yields: ..." string
        a << " {|#{b}| ... }"
      end
      full_name << a
    end

    # Returns a HTML version of this method's comment.
    def comment_html
      DummyMarkup.new.markup comment
    end

    # Returns the RDoc::TopLevel object which contains this method.
    def top_level
      n = parent
      while n && n.parent
        n = n.parent
      end
      n
    end
  end

  private

  module DummyMixin #:nodoc:
    def method_missing *args
      # ignore all messages
    end
  end

  class DummyOptions #:nodoc:
    include DummyMixin

    def quiet # supress '...c..m...' output on STDERR
      true
    end
  end

  class DummyMarkup #:nodoc:
    require 'rdoc/generators/html_generator'
    include Generators::MarkUp
    include DummyMixin
  end
end
