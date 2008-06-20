desc: An example format.

code: |
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

  class Node
    def name
      # dynamically compute (and store)
      # the name of this node on demand
      @name ||= generate_name
    end
  end

nodes:
  hello:
    index: true
    number: true
    silent: false
    output: |
      <h1><%= @node.type %> #<%= @node.index %>: <%= @node.name.inspect %></h1>
      My name is <%= @node.name.inspect %> and these are my properties:
      <table>
        <tr>
          <th>Property</th>
          <th>Value</th>
        </tr>
        <tr>
          <td>args</td>
          <td><%= @node.args.inspect %></td>
        </tr>
        <tr>
          <td>index</td>
          <td><%= @node.index.inspect %></td>
        </tr>
        <tr>
          <td>number</td>
          <td><%= @node.number.inspect %></td>
        </tr>
        <tr>
          <td>trace</td>
          <td><ul><%= @node.trace.map {|s| "<li>#{s}</li>"} %></ul></td>
        </tr>
        <tr>
          <td>content</td>
          <td><%= @node.content %></td>
        </tr>
      </table>

output: |
  Welcome to the "<%= @spec[:name] %>" format.
  <div style="<%= $style %>"><%= @content %></div>
  That's all folks!
