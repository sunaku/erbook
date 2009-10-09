desc: An example format.

code: |
  class ERBook::Document::Node
    def name
      # dynamically compute (and store)
      # the name of this node on demand
      @name ||= generate_name
    end

    private

    # Returns a random, yet pronounceable, name.
    def generate_name
      letters = ('a'..'z').to_a - %w[ c q w x ] # redundant sounds
      vowels = %w[a e i o u]
      consonants = letters - vowels
      sets = [consonants, vowels]

      length = 3 + rand(5)

      name = (0...length).map do |i|
        # alternate between consonants and vowels
        set = sets[i % sets.length]

        # choose a random letter from the set
        set[rand(set.length)]
      end.join

      name
    end
  end

nodes:
  hello:
    number: [section, ordinal]
    silent: false
    output: |

      <h3><%= @node.type %> #<%= @node.index %>: <%= @node.name.inspect %></h3>

      My name is <%= @node.name.inspect %> and these are my properties:

      <dl style="<%= $style %>">
        <dt>arguments</dt>
        <dd><code><%= @node.arguments.inspect %></code></dd>

        <dt>section_number</dt>
        <dd><code><%= @node.section_number.inspect %></code></dd>

        <dt>ordinal_number</dt>
        <dd><code><%= @node.ordinal_number.inspect %></code></dd>

        <dt>backtrace</dt>
        <dd><pre><%= @node.backtrace.join("\n") %></pre></dd>

        <dt>content</dt>
        <dd><%= @node.content %></dd>
      </dl>

output: |
  Welcome to the "<%= @format[:name] %>" format.

  <%= @content %>

  That's all folks!
