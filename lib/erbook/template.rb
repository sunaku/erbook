require 'erb'

module ERBook
  # An eRuby template which allows access to the underlying result
  # buffer (which contains the result of template evaluation thus
  # far) and provides sandboxing for isolated template rendering.
  #
  # In addition to the standard <% eRuby %> directives, this template supports:
  #
  # * Lines that begin with '%' are treated as normal eRuby directives.
  #
  # * Special <%#include FILE_TO_INCLUDE #%> directives are replaced by the
  #   result of reading and evaluating the FILE_TO_INCLUDE in the current
  #   context.
  #
  class Template < ERB
    # The result of template evaluation thus far.
    attr_reader :buffer

    # source::      String that replaces the ambiguous '(erb)'
    #               identifier in stack traces, so that the user
    #               can better determine the source of an error.
    #
    # input::       String containing eRuby directives.  This
    #               string will be modified by this method!
    #
    # unindent::    If true, then all content blocks will be
    #               unindented hierarchically, by the leading
    #               space of their 'do' and 'end' delimiters.
    #
    # safe_level::  See safe_level in ERB::new().
    #
    def initialize source, input, unindent = false, safe_level = nil
      # expand all "include" directives in the input
      begin end while input.gsub! %r{<%#\s*include\s+(.+?)\s*#%>} do
        file, line = $1, $`.count("\n").next

        # provide more accurate stack trace for
        # errors originating from included files.
        #
        # NOTE: eRuby does NOT seem to provide line numbers for trace
        #       entries that are deeper than the input document itself
        #
        "<%
          begin
            %>#{File.read file}<%
          rescue Exception => err
            bak = err.backtrace

            # set the input document's originating line number to
            # where this file was included in the input document
            top = bak.find {|t| t =~ /#{/#{source}/}:\\d+$/ }
            top.sub! %r{\\d+$}, '#{line}'

            # add a stack trace entry mentioning this included file
            ins = bak.index top
            bak.insert ins, #{file.inspect}

            raise err
          end
        %>"
      end

      # convert "% at beginning of line" usage into <% normal %> usage
      input.gsub! %r{^([ \t]*)(%[=# \t].*)$}, '\1<\2 %>'
      input.gsub! %r{^([ \t]*)%%}, '\1%'

      # silence the code-only <% ... %> directive, just like PHP does
      input.gsub! %r{^[ \t]*(<%[^%=]((?!<%).)*?[^%]%>)[ \t]*\r?\n}m, '\1'

      # unindent node content hierarchically
      if unindent
        tags = input.scan(/<%(?:.(?!<%))*?%>/m)
        margins = []
        result = []

        buffer = input
        tags.each do |tag|
          chunk, buffer = buffer.split(tag, 2)
          chunk << tag

          # perform unindentation
          result << chunk.gsub(/^#{margins.last}/, '')

          # prepare for next unindentation
          case tag
          when /<%[^%=].*?\bdo\b.*?%>/m
            margins.push buffer[/^[ \t]*(?=\S)/]

          when /<%\s*end\s*%>/m
            margins.pop
          end
        end
        result << buffer

        input = result.join
      end

      # use @buffer to store the result of the ERB template
      super input, safe_level, nil, :@buffer

      self.filename = source
    end

    # Renders this template within a fresh object that is populated with
    # the given instance variables, whose names must be prefixed with '@'.
    def render_with inst_vars = {}
      context = Object.new.instance_eval do
        inst_vars.each_pair do |var, val|
          instance_variable_set var, val
        end

        binding
      end

      result context
    end

    protected

    # Returns the content that the given block wants to append to
    # the buffer.  If the given block does not want to append to the
    # buffer, then returns the result of invoking the given block.
    def content_from_block *block_args
      raise ArgumentError, 'block must be given' unless block_given?

      head = @buffer.length
      body = yield(*block_args) # this appends 'content' to '@buffer'
      tail = @buffer.length

      if tail > head
        @buffer.slice! head..tail
      else
        body
      end.to_s
    end
  end
end