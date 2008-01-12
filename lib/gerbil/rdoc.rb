# Workaround for: `rdoc --fmt xml` does not dump information about methods.
#--
# Copyright 2007 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'rdoc/rdoc'

module RDoc
  module DummyMixin
    def method_missing *args
      # ignore all messages
    end
  end

  class DummyOptions
    include DummyMixin

    def quiet # supress '...c..m...' output on STDERR
      true
    end
  end

  class DummyMarkup
    require 'rdoc/generators/html_generator'
    include Generators::MarkUp
    include DummyMixin
  end

  # Returns an RDoc parse tree for the given code.  If the file name (which
  # signifies the origin of the given code) is given, it MUST have a ".rb"
  # file extension.  Otherwise, RDoc will give you an empty parse tree!  :-(
  def self.gen_parse_tree aCode, aFileName = __FILE__
    root = TopLevel.new(aFileName)
    parser = ParserFactory.parser_for(root, aFileName, aCode, DummyOptions.new, Stats.new)
    info = parser.scan

    info.requires.map do |r|
      f = r.name
      f << '.rb' unless File.exist? f
      gen_parse_tree f if File.exist? f
    end.flatten.compact << info
  end

  # Returns an array of hashes describing all methods present in the
  # given parse trees (which are produced by RDoc::gen_parse_trees).
  def self.gen_method_infos *aParseTrees
    meths = aParseTrees.map do |i|
      i.method_list + i.classes.map { |c| c.method_list }
    end.flatten.uniq

    meths.map do |m|
      # determine full path to method (Module::Class::...::method)
      hier = []
      root = m.parent
      while root && root.parent
        hier.unshift root
        root = root.parent
      end

      if hier.empty?
        path = m.name
      else
        path = hier.map {|n| n.name}.join('::')
        path = [path, m.name].join(m.singleton ? '::' : '#')
      end

      # determine argument string for method
      args = m.params
      if m.block_params
        args.sub! %r/\#.*(?=.$)/, ''
        args << " { |#{m.block_params}| ... }"
      end

      {
        :file => root.file_absolute_name,
        :name => path,
        :args => args,
        :decl => path + args,
        :docs => m.comment,
        :docs_html => DummyMarkup.new.markup(m.comment),

        # nodes in the parse tree
        :node => m,
        :root => root,
        # for top level methods, info.parent == root
        # for class methods, info.singleton == true
      }
    end
  end
end
