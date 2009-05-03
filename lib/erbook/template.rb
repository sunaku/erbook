require 'ember'

module ERBook
  ##
  # eRuby template that provides access to the underlying result
  # buffer (which contains the result of template evaluation thus
  # far) and provides sandboxing for isolated template rendering.
  #
  class Template < Ember::Template
    attr_reader :sandbox

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

      @sandbox = Sandbox.new

      if $DEBUG
        IO.popen('cat -n', 'w+') do |io|
          io.write self.program
          io.close_write
          STDERR.puts io.read
        end
      end
    end

    ##
    # Returns the output of evaluating this template inside the given context.
    #
    # If no context is given, then the sandbox of this template is used.
    #
    def render
      super @sandbox.instance_eval('binding')
    end

    ##
    # Returns the result of template evaluation thus far.
    #
    def buffer
      @sandbox.instance_variable_get(:@buffer)
    end

    ##
    # Renders this template within a fresh sandbox that is populated with
    # the given instance variables, whose names must be prefixed with '@'.
    #
    def render_with inst_vars = {}
      old_sandbox = @sandbox

      begin
        @sandbox = Sandbox.new

        inst_vars.each_pair do |var, val|
          @sandbox.instance_variable_set var, val
        end

        render

      ensure
        @sandbox = old_sandbox
      end
    end

    ##
    # Environment for template evaluation.
    #
    class Sandbox
      ##
      # Returns an array of things that the given
      # block wants to append to the buffer.  If
      # the given block does not want to append
      # to the buffer, then returns the result of
      # invoking the given block inside an array.
      #
      def __block_content__ *block_args
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
end
