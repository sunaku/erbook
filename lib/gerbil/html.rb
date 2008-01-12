# This file defines the String#to_html method, which is
# invoked to transform the content of a blog entry into HTML.
#
# It features the Textile formatting system (RedCloth), syntax coloring
# (CodeRay), and smart source code sizing (block versus inline display).
#--
# Copyright 2006 Suraj N. Kurapati
# See the file named LICENSE for details.

require 'cgi'
require 'digest/sha1'

begin
  require 'rubygems'
rescue LoadError
end

require 'coderay'
require 'redcloth'

class String
  # The content of these HTML tags will be preserved while
  # they are being processed by Textile. By doing this, we
  # avoid unwanted Textile transformations, such as quotation
  # marks becoming curly (&#8192;), in source code.
  PROTECTED_TAGS = %w[tt code pre]

  # The content of these HTML tags will
  # be preserved *verbatim* throughout
  # the text-to-HTML conversion process.
  VERBATIM_TAGS = %w[noformat]

  # Transforms this string into HTML.
  def to_html
    text = dup
    protect_tags! text, VERBATIM_TAGS, verbatimStore = {}, true
    protect_tags! text, PROTECTED_TAGS, protectedStore = {}, false

    html = text.thru_redcloth
    restore_tags! html, protectedStore

    # collapse redundant <pre> elements -- a side effect of RedCloth
    html.gsub! %r{(<pre>)\s*<pre>(.*?)</pre>\s*(</pre>)}m, '\1\2\3'

    html = html.thru_coderay
    restore_tags! html, verbatimStore

    # ensure tables have a border (this GREATLY improves
    # readability in text-mode web browsers like Lynx and w3m)
    html.gsub! %r/<table/, '\& border="1"'

    html
  end

  # Returns the result of running this string through RedCloth.
  def thru_redcloth
    text = dup

    # redcloth does not correctly convert -- into &mdash;
    text.gsub! %r{\b--\b}, '&mdash;'

    html = RedCloth.new(text).to_html

    # redcloth adds <span> tags around acronyms
    html.gsub! %r{<span class="caps">([[:upper:][:digit:]]+)</span>}, '\1'

    # redcloth wraps indented text within <pre><code> tags
    html.gsub! %r{(<pre>)\s*<code>(.*?)\s*</code>\s*(</pre>)}m, '\1\2\3'

    # redcloth wraps a single item within paragraph tags, which
    # prevents the item's HTML from being validly injected within
    # other block-level elements, such as headings (h1, h2, etc.)
    html.sub! %r{^<p>(.*)</p>$}m do |match|
      payload = $1

      if payload =~ /<p>/
        match
      else
        payload
      end
    end

    html
  end

  # Adds syntax coloring to <code> elements in the given text.  If the
  # <code> tag has an attribute lang="...", then that is considered the
  # programming language for which appropriate syntax coloring should be
  # applied.  Otherwise, the programming language is assumed to be ruby.
  def thru_coderay
    gsub %r{<(code)(.*?)>(.*?)</\1>}m do
      atts, code = $2, CGI.unescapeHTML($3)

      lang =
        if $2 =~ /lang=('|")(.*?)\1/i
          $2
        else
          :ruby
        end

      tag =
        if code =~ /\n/
          :pre
        else
          :code
        end

      html = CodeRay.scan(code, lang).html(:css => :style)

      %{<#{tag} class="code"#{atts}>#{html}</#{tag}>}
    end
  end

  private

  def protect_tags! aText, aTags, aStore, aVerbatim #:nodoc:
    aTags.each do |tag|
      aText.gsub! %r{(<#{tag}.*?>)(.*?)(</#{tag}>)}m do
        head, body, tail = $1, $2, $3

        # XXX: when we restore protected tags later on, String.gsub! is
        #      removing all single backslashes for some reason... so we
        #      protect against this by doubling all single backslashes first
        body.gsub! %r/\\/, '\&\&'

        original =
          if aVerbatim
            body
          else
            head << CGI.escapeHTML(CGI.unescapeHTML(body)) << tail
          end
        escape = Digest::SHA1.hexdigest(original)

        aStore[escape] = original
        escape
      end
    end
  end

  def restore_tags! aText, aStore #:nodoc:
    until aStore.empty?
      aStore.each_pair do |escape, original|
        if aText.gsub! %r{<p>#{escape}</p>|#{escape}}, original
          aStore.delete escape
        end
      end
    end
  end
end
