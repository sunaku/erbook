desc: A format conceived just for the sake of illustration.

code: |
  # generates a random name
  def generate_name
    letters = ('a'..'z').to_a - %w[ c q w x ] # redundant sounds
    vowels = %w[a e i o u]
    consonants = letters - vowels
    sets = [consonants, vowels]

    length = 3 + rand(5)

    name = ''
    length.times do |i|
      set = sets[i % sets.length]
      name << set[rand(set.length)]
    end

    name
  end

  class Node
    attr_writer :name
    def name
      @name ||= generate_name
    end
  end

nodes:
  hello:
    index: true
    number: true
    silent: false
    output: |
      <h1><%= @node.type %> <%= @node.name.inspect %></h1>
      <table>
        <tr>
          <th>args</th>
          <td><%= @node.args.inspect %></td>
        </tr>
        <tr>
          <th>index</th>
          <td><%= @node.index.inspect %></td>
        </tr>
        <tr>
          <th>number</th>
          <td><%= @node.number.inspect %></td>
        </tr>
        <tr>
          <th>trace</th>
          <td><ul><%= @node.trace.map {|s| "<li>#{s}</li>"} %></ul></td>
        </tr>
        <tr>
          <th>content</th>
          <td><%= @node.content %></td>
        </tr>
      </table>

output: |
  Welcome to the "<%= @spec[:name] %>" format.
  <div style="<%= $style %>"<%= @content %></div>
  That's all folks!