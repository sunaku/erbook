require 'ember'

module ERBook
  ##
  # An eRuby template which allows access to the underlying result
  # buffer (which contains the result of template evaluation thus
  # far) and provides sandboxing for isolated template rendering.
  #
  # In addition to the standard <% eRuby %> directives, this template supports:
  #
  # * Lines that begin with '%' are treated as normal eRuby directives.
  #
  # * Include directives (<%#include YOUR_PATH #%>) are replaced by the result
  #   of reading and evaluating the YOUR_PATH file in the current context.
  #
  #   * Unless YOUR_PATH is an absolute path, it is treated as being
  #     relative to the file which contains the include directive.
  #
  #   * Errors originating from included files are given a proper
  #     stack trace which shows the chain of inclusion plus any
  #     further trace steps originating from the included file itself.
  #
  # * eRuby directives delimiting Ruby blocks (<% ...  do %>
  #   ...  <% end %>) can be heirarchically unindented by the
  #   crown margin of the opening (<% ...  do %>) delimiter.
  #
  class Template < Ember::Template
    # The result of template evaluation thus far.
    attr_reader :buffer

    ##
    # @param [String] source
    #   Replacement for the ambiguous '(erb)' identifier in stack traces;
    #   so that the user can better determine the source of an error.
    #
    # @param [String] input
    #   A string containing eRuby directives.
    #
    # @param [boolean] unindent
    #   If true, then all content blocks will be unindented hierarchically,
    #   by the leading space of their 'do' and 'end' delimiters.
    #
    # @param safe_level
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
