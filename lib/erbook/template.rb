require 'ember'

module ERBook
  ##
  # eRuby template that provides access to the underlying result
  # buffer (which contains the result of template evaluation thus
  # far) and provides sandboxing for isolated template rendering.
  #
  class Template < Ember::Template
    # The result of template evaluation thus far.
    attr_reader :buffer

    ##
    # ==== Parameters
    #
    # [source]
    #   Replacement for the ambiguous '(erb)' identifier in stack traces;
    #   so that the user can better determine the source of an error.
    #
    # [input]
    #   A string containing eRuby directives.
    #
    # [unindent]
    #   If true, then all content blocks will be unindented hierarchically,
    #
    # [safe_level]
    #   See safe_level in ERB::new().
    #
    def initialize source, input, unindent = true, safe_level = nil
      super input,
        :result_variable => :@buffer,
        :source_file     => source,
        :unindent        => unindent,
        :shorthand       => true,
        :infer_end       => true

      if $DEBUG
        STDERR.puts IO.popen('cat -n', 'w+') do |io|
          io.write self.program
          io.close_write
          io.read
        end
      end
    end

    ##
    # Renders this template within a fresh object that is populated with
    # the given instance variables, whose names must be prefixed with '@'.
    #
    def render_with inst_vars = {}
      context = Object.new.instance_eval do
        inst_vars.each_pair do |var, val|
          instance_variable_set var, val
        end

        binding
      end

      render(context)
    end

    protected

    ##
    # Returns an array of things that the given block wants to append to the
    # buffer.  If the given block does not want to append to the buffer,
    # then returns the result of invoking the given block inside an array.
    #
    def content_from_block *block_args
      raise ArgumentError, 'block must be given' unless block_given?

      original = @buffer

      begin
        block_content = @buffer = []
        return_value  = yield(*block_args) # this appends content to @buffer
      ensure
        @buffer = original
      end

      if block_content.empty?
        [return_value]
      else
        block_content
      end
    end
  end
end
