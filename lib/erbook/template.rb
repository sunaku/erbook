require 'erb'
require 'pathname'

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
  class Template < ERB
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
    def initialize source, input, unindent = false, safe_level = nil
      # expand all "include" directives in the input
      expander = lambda do |src_file, src_text, path_stack, stack_trace|
        src_path = File.expand_path(src_file)
        src_line = 1 # line number of the current include directive in src_file

        chunks = src_text.split(/<%#\s*include\s+(.+?)\s*#%>/)

        path_stack.push src_path
        chunks.each_with_index do |chunk, i|
          # even number: chunk is not an include directive
          if i & 1 == 0
            src_line += chunk.count("\n")

          # odd number: chunk is the target of the include directive
          else
            # resolve correct path of target file
              dst_file = chunk

              unless Pathname.new(dst_file).absolute?
                # target is relative to the file in
                # which the include directive exists
                dst_file = File.join(File.dirname(src_file), dst_file)
              end

              dst_path = File.expand_path(dst_file)

            # include the target file
              if path_stack.include? dst_file
                raise "Cannot include #{dst_file.inspect} at #{src_file.inspect}:#{src_line} because that would cause an infinite loop in the inclusion stack: #{path_stack.inspect}."
              else
                stack_trace.push "#{src_path}:#{src_line}"
                dst_text = eval('File.read dst_file', binding, src_file, src_line)

                # recursively expand any include directives within
                # the expansion of the current include directive
                dst_text = expander[dst_file, dst_text, path_stack, stack_trace]

                # provide more accurate stack trace for
                # errors originating from included files
                line_var = "__erbook_var_#{dst_file.object_id.abs}__"
                dst_text = %{<%
                  #{line_var} = __LINE__ + 2 # content is 2 newlines below
                  begin
                    %>#{dst_text}<%
                  rescue Exception => err
                    bak = err.backtrace

                    top = []
                    found_top = false
                    prev_line = nil

                    bak.each do |step|
                      if step =~ /^#{/#{source}/}:(\\d+)(.*)/
                        line, desc = $1, $2
                        line = line.to_i - #{line_var} + 1

                        if line > 0 and line != prev_line
                          top << "#{dst_path}:\#{line}\#{desc}"
                          found_top = true
                          prev_line = line
                        end
                      elsif !found_top
                        top << step
                      end
                    end

                    if found_top
                      bak.replace top
                      bak.concat #{stack_trace.reverse.inspect}
                    end

                    raise err
                  end
                %>}

                stack_trace.pop
              end

              chunks[i] = dst_text
          end
        end
        path_stack.pop

        chunks.join
      end

      input = expander[source, input, [], []]

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
