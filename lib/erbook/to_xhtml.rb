# This file defines the String#to_xhtml and String#to_inline_xhtml
# methods, which are invoked to transform plain text into XHTML.
#
# This particular implementation features the Markdown
# formatting system via Maruku, syntax coloring via CodeRay,
# and smart source code sizing (block versus inline display).

require 'cgi'
require 'digest/sha1'

begin
  require 'rubygems'
  gem 'maruku', '~> 0.5'
  gem 'coderay', '>= 0.8'
rescue LoadError
end

require 'coderay'
require 'maruku'

class String
  # The content of these XHTML tags will be preserved while
  # they are being processed by Textile.  By doing this, we
  # avoid unwanted Textile transformations, such as quotation
  # marks becoming curly (&#8192;), in source code.
  PROTECTED_TAGS = {
    :pre  => :block,    # tag => is it a block or inline element?
    :code => :inline,
    :tt   => :inline
  }

  # The content of these XHTML tags will be preserved
  # *verbatim* throughout the text-to-XHTML conversion process.
  VERBATIM_TAGS = {
    :noformat => :block # tag => is it a block or inline element?
  }

  ##
  # Transforms this string into an *inline* XHTML string (one that
  # does not contain any block-level XHTML elements at the root).
  #
  def to_inline_xhtml
    to_xhtml true
  end

  ##
  # Transforms this string into XHTML while ensuring that the
  # result contains one or more block-level elements at the root.
  #
  # [inline]
  #   If true, the resulting XHTML will *not*
  #   contain a block-level element at the root.
  #
  def to_xhtml inline = false
    with_protected_tags(self, VERBATIM_TAGS, true) do |text|
      html = with_protected_tags(text, PROTECTED_TAGS, false) do
        |s| s.thru_maruku inline
      end

      # Markdown's "code spans" should really be "pre spans"
      while html.gsub! %r{(<pre>)<code>(.*?)</code>(</pre>)}m, '\1\2\3'
      end

      # allow user to type <pre> blocks on single lines
      # without affecting the display of their content
      html.gsub! %r{(<pre>)[ \t]*\r?\n|\r?\n[ \t]*(</pre>)}, '\1\2'

      # ensure tables have a border: this *greatly* improves
      # readability in text-based web browsers like w3m and lynx
      html.gsub! %r/<table\b/, '\& border="1"'

      # add syntax coloring
      html.thru_coderay
    end
  end

  ##
  # Returns the result of running this string through Maruku.
  #
  # [inline]
  #   If true, the resulting XHTML will *not*
  #   be wrapped in a XHTML paragraph element.
  #
  def thru_maruku inline = false #:nodoc:
    #
    # XXX: add a newline at the beginning of the text to
    #      prevent Maruku from interpreting the first line
    #      of text as a parameter definition, which is the
    #      case if that first line matches /\S{2}: /
    #
    #      see this bug report for details:
    #      http://rubyforge.org/tracker/?func=detail&atid=10735&aid=25697&group_id=2795
    #
    html = Maruku.new("\n#{self}").to_html
    html.sub! %r{\A<p>(.*)</p>\Z}, '\1' if inline
    html
  end

  ##
  # Adds syntax coloring to <code> elements in this string.
  #
  # Each <code> element is annotated with a class="line"
  # or a class="para" attribute, according to whether it
  # spans a single line or multiple lines of code.
  #
  # In the latter case, the <code> element is replaced with a <pre> element
  # so that its multi-line body appears correctly in text-mode web browsers.
  #
  # If a <code> element has a lang="..." attribute,
  # then that attribute's value is considered to be
  # the programming language for which appropriate
  # syntax coloring should be applied.  Otherwise,
  # the programming language is assumed to be ruby.
  #
  def thru_coderay #:nodoc:
    gsub %r{<(code)(.*?)>(.*?)</\1>}m do
      elem, atts, code = $1, $2, CGI.unescapeHTML($3).sub(/\A\r?\n/, '')
      lang = atts[/\blang=('|")(.*?)\1/i, 2] || :ruby

      body = CodeRay.scan(code, lang).html(:css => :style)

      if code =~ /\n/
        span = :para
        head = "<ins><pre"
        tail = "</pre></ins>"

      else
        span = :line
        head = "<#{elem}"
        tail = "</#{elem}>"
      end

      %{#{head} class="#{span}"#{atts}>#{body}#{tail}}
    end
  end

  private

  ##
  # Protects the given tags in the given input, passes
  # that protected input to the given block, restores the
  # given tags in the result of the block and returns it.
  #
  # [verbatim]
  #   If true, the content of the elments having the given tags will not be
  #   temporarily altered so that process nested elements can be processed.
  #
  def with_protected_tags input, tag_defs, verbatim #:yields: input
    raise ArgumentError unless block_given?

    input = input.dup
    escapes = {}

    # protect the given tags by escaping them
    tag_defs.each_key do |tag|
      input.gsub! %r{(<#{tag}.*?>)(.*?)(</#{tag}>)}m do
        head, body, tail = $1, $2, $3

        # XXX: when we restore protected tags later on, String.gsub! is
        #      removing all single backslashes for some reason... so we
        #      protect against this by doubling all single backslashes first
        body.gsub! %r/\\/, '\&\&'

        original =
          if verbatim
            body
          else
            head << CGI.escapeHTML(CGI.unescapeHTML(body)) << tail
          end

        escaped = calc_digest(original)
        escapes[escaped] = original

        escaped
      end
    end

    # invoke the given block with the protected input
    output = yield input

    # restore the protected tags by unescaping them
    until escapes.empty?
      escapes.each_pair do |esc, orig|
        tag = orig[/<\/(.+?)>\s*\z/, 1].to_sym
        raise ArgumentError, tag unless tag_defs.key? tag

        restore_ok =
          case tag_defs[tag]
          when :inline
            # process inline elements normally
            output.gsub! esc, orig

          when :block
            # pull block-level elements out of paragraph tag added by Maruku
            output.gsub!(/(<p>\s*)?#{Regexp.quote esc}/){ orig + $1.to_s }
          end

        escapes.delete esc if restore_ok
      end
    end

    output
  end

  ##
  # Returns a digest of the given string that
  # will not be altered by String#to_xhtml.
  #
  def calc_digest input
    Digest::SHA1.hexdigest(input.to_s).

    # XXX: surround all digits with alphabets so
    #      Maruku doesn't change them into HTML
    gsub(/\d/, 'z\&z')
  end
end
