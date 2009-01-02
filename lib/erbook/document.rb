require 'yaml'
require 'ostruct'
require 'digest/sha1'
require 'erbook/template'

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
    # @param [String] format
    #   Either the short-hand name of a built-in format
    #   or the path to a format specification file.
    #
    # @param [String] input_text
    #   The body of the input document.
    #
    # @param [String] input_file
    #   Name of the file from which the input document originated.
    #
    # @param [Hash] options
    #   Additional method parameters:
    #
    #   [boolean] :unindent =>
    #     If true, all node content is unindented hierarchically.
    #
    def initialize format, input_text, input_file, options = {}
      # process format specification
        @format_file = format.to_s

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

            @template_vars = {
              :@spec  => @format,
              :@roots => @roots = [], # root nodes of all trees
              :@nodes => @nodes = [], # all nodes in the forest
              :@types => @nodes_by_type = Hash.new {|h,k| h[k] = [] },
              :@stack => [],
            }.each_pair {|k,v| template.instance_variable_set(k, v) }

            @node_defs.each_pair do |type, defn|
              # XXX: using a string because define_method()
              #      does not accept a block until Ruby 1.9
              template.instance_eval %{
                def #{type} *node_args, &node_content
                  node = Node.new(
                    :type => #{type.inspect},
                    :args => node_args,
                    :trace => caller,
                    :children => []
                  )
                  @nodes << node
                  @types[node.type] << node

                  # calculate occurrence number for this node
                  if #{defn['number']}
                    @count ||= Hash.new {|h,k| h[k] = []}
                    node.number = (@count[node.type] << node).length
                  end

                  # assign node family
                  if parent = @stack.last
                    parent.children << node
                    node.parent = parent
                    node.depth = parent.depth.next

                    # calculate latex-style index number for this node
                    if #{defn['index']}
                      branches = parent.children.select {|n| n.index}
                      node.index = [parent.index, branches.length.next].join('.')
                    end
                  else
                    @roots << node
                    node.parent = nil
                    node.depth = 0

                    # calculate latex-style index number for this node
                    if #{defn['index']}
                      branches = @roots.select {|n| n.index}
                      node.index = branches.length.next.to_s
                    end
                  end

                  # assign node content
                  if block_given?
                    @stack.push node
                    content = content_from_block(node, &node_content)
                    @stack.pop

                    digest = Document.digest(content)
                    self.buffer << digest
                  else
                    content = nil
                    digest = Document.digest(node.object_id)
                  end

                  node.content = content
                  node.digest = digest

                  digest
                end
              },  __FILE__, Kernel.caller.first[/\d+/].to_i.next
            end

          # evaluate the input & build the document tree
            @processed_document = template.instance_eval { result binding }

            # replace node placeholders with their corresponding output
            expander = lambda do |n, buf|
              # calculate node output
              source = "#{@format_file}:nodes:#{n.type}:output"
              n.output = Template.new(
                source, @node_defs[n.type]['output'].to_s.chomp
              ).render_with(@template_vars.merge(:@node => n))

              # expand all child nodes in this node's output
              n.children.each {|c| expander[c, n.output] }

              # replace this node's placeholder with its output in the buffer
              buf[n.digest] = @node_defs[n.type]['silent'] ? '' : n.output
            end

            @roots.each {|n| expander[n, @processed_document] }

        rescue Exception => e
          # omit erbook internals from the stack trace
          e.backtrace.reject! {|t| t =~ /^#{__FILE__}:\d+/ } unless $DEBUG

          puts input_text # so the user can debug line numbers in the stack trace
          error "Could not process input document #{input_file.inspect}"
        end
    end

    # Returns the output of this document.
    def to_s
      Template.new("#{@format_file}:output", @format['output'].to_s).
      render_with(@template_vars.merge(:@content => @processed_document))
    end

    class Node < OpenStruct
      # deprecated in Ruby 1.8; removed in Ruby 1.9
      undef id if respond_to? :id
      undef type if respond_to? :type

      # Returns the output of this node.
      def to_s
        output
      end
    end

    # Returns a digest of the given string that
    # will not be altered by String#to_xhtml.
    def Document.digest input
      Digest::SHA1.hexdigest(input.to_s).

      # XXX: surround all digits with alphabets so
      #      Maruku doesn't change them into HTML
      gsub(/\d/, 'z\&z')
    end

    private

    # Prints the given message and raises the given error.
    def error message, error = $!
      STDERR.printf "%s:\n\n", message
      raise error
    end
  end
end
