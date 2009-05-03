require 'yaml'
require 'erbook/template'
require 'digest/sha1'

module ERBook
  class Document
    # Data from the format specification file.
    attr_reader :format

    # All root nodes in the document.
    attr_reader :roots

    # All nodes in the document.
    attr_reader :nodes

    # All nodes in the document arranged by node type.
    attr_reader :nodes_by_type

    ##
    # ==== Parameters
    #
    # [format_name]
    #   Either the short-hand name of a built-in format
    #   or the path to a format specification file.
    #
    # [input_text]
    #   The body of the input document.
    #
    # [input_file]
    #   Name of the file from which the input document originated.
    #
    # ==== Options
    #
    # [:unindent]
    #     If true, all node content is unindented hierarchically.
    #
    def initialize format_name, input_text, input_file, options = {}
      # process format specification
      @format_file = format_name.to_s

        File.file? @format_file or
          @format_file = File.join(ERBook::FORMATS_DIR, @format_file + '.yaml')

        begin
          @format = YAML.load_file(@format_file)
          @format[:file] = File.expand_path(@format_file)
          @format[:name] = File.basename(@format_file).sub(/\..*?$/, '')

          if @format.key? 'code'
            eval @format['code'].to_s, TOPLEVEL_BINDING, "#{@format_file}:code"
          end

        rescue Exception
          error "Could not load format specification file #{@format_file.inspect}"
        end

        @node_defs = @format['nodes']

      # process input document
        begin
          # create sandbox for input evaluation
            template = Template.new(input_file, input_text, options[:unindent])
            sandbox = template.sandbox

            @template_vars = {
              :@format        => @format,
              :@roots         => @roots = [], # root nodes of all trees
              :@nodes         => @nodes = [], # all nodes in the forest
              :@nodes_by_type => @nodes_by_type = Hash.new {|h,k| h[k] = [] },
              :@stack         => [], # stack for all nodes
            }.each_pair {|k,v| sandbox.instance_variable_set(k, v) }

            # Handles the method call from a node
            # placeholder in the input document.
            def sandbox.__node_impl__ node_type, *node_args, &node_content
              node = Node.new(
                :type => node_type,
                :defn => @format['nodes'][node_type],
                :args => node_args,
                :children => [],

                # omit erbook internals from the stack trace
                :trace => caller.reject {|t|
                  [$0, ERBook::INSTALL].any? {|f| t.index(f) == 0 }
                }
              )
              @nodes << node
              @nodes_by_type[node.type] << node

              # calculate occurrence number for this node
              if node.defn['number']
                @count ||= Hash.new {|h,k| h[k] = []}
                node.number = (@count[node.type] << node).length
              end

              # assign node family
              if parent = @stack.last
                parent.children << node
                node.parent = parent
                node.depth = parent.depth
                node.depth += 1 if node.defn['depth']

                # calculate latex-style index number for this node
                if node.defn['index']
                  ancestry = @stack.reverse.find {|n| n.defn['index'] }.index
                  branches = node.parent.children.select {|n| n.index }

                  node.index = [ancestry, branches.length + 1].join('.')
                end
              else
                @roots << node
                node.parent = nil
                node.depth = 0

                # calculate latex-style index number for this node
                if node.defn['index']
                  branches = @roots.select {|n| n.index }
                  node.index = (branches.length + 1).to_s
                end
              end

              # assign node content
              if block_given?
                @stack.push node
                node.content = __block_content__(node, &node_content)
                @stack.pop
              end

              @buffer << node

              nil
            end

            @node_defs.each_key do |type|
              # XXX: using a string because define_method()
              #      does not accept a block until Ruby 1.9
              file, line = __FILE__, __LINE__; eval %{
                def sandbox.#{type} *node_args, &node_content
                  __node_impl__ #{type.inspect}, *node_args, &node_content
                end
              }, binding, file, line
            end

          # evaluate the input & build the document tree
            template.render
            @processed_document = template.buffer

          # chain block-level nodes together for local navigation
            block_nodes = @nodes.reject {|n| n.defn['bypass'] ||
                                             n.defn['inline'] }

            require 'enumerator'
            block_nodes.each_cons(2) do |a, b|
              a.next_node = b
              b.prev_node = a
            end

          # calculate output for all nodes
            actual_output_by_node = {}

            visitor = lambda do |n|
              #
              # allow child nodes to calculate their actual
              # output and to set their identifier as Node#output
              #
              # we do this nodes first because this node's
              # content contains the child nodes' output
              #
              n.children.each {|c| visitor.call c }

              # calculate the output for this node
              actual_output = Template.new(
                "#{@format_file}:nodes:#{n.type}:output",
                n.defn['output'].to_s.chomp
              ).render_with(@template_vars.merge(:@node => n))

              # reveal child nodes' actual output in this node's actual output
              n.children.each do |c|
                if c.defn['inline'] && !c.defn['bypass']
                  actual_output[c.output] = actual_output_by_node[c]

                else
                  # pull block-level node out of paragraph tag added by Maruku
                  actual_output.sub! %r/(<p>\s*)?#{Regexp.quote c.output}/ do
                    actual_output_by_node[c] + $1.to_s
                  end
                end
              end

              actual_output_by_node[n] = actual_output

              #
              # allow the parent node to calculate its actual
              # output without interference from the output of
              # this node (Node#to_s is aliased to Node#output)
              #
              # this assumes that having this node's string
              # representation be a consecutive sequence of digits
              # will not interfere with the text-to-whatever
              # transformation defined by the format specification
              #
              n.output = Digest::SHA1.digest(n.object_id.to_s).unpack('I*').join
            end

            @roots.each {|n| visitor.call n }

            # replace the temporary identifier with each node's actual output
            @nodes.each {|n| n.output = actual_output_by_node[n] }

        rescue Exception
          puts input_text # so the user can debug line numbers in stack trace
          error "Could not process input document #{input_file.inspect}"
        end
    end

    ##
    # Returns the output of this document.
    #
    def to_s
      Template.new("#{@format_file}:output", @format['output'].to_s).
      render_with(@template_vars.merge(:@content => @processed_document.join))
    end

    require 'ostruct'
    class Node < OpenStruct
      # deprecated in Ruby 1.8; removed in Ruby 1.9
      undef id if respond_to? :id
      undef type if respond_to? :type

      # Returns the output of this node.
      def to_s
        defn['silent'] ? '' : output
      end
    end

    private

    ##
    # Prints the given message and raises the given error.
    #
    def error message, error = $!
      STDERR.printf "%s:\n\n", message
      raise error
    end
  end
end
