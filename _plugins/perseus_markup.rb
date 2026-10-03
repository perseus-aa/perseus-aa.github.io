# frozen_string_literal: true

# Liquid filters for the markup that survives in the metadata text fields.
#
#   {{ page.dimensions | markup }}           markup in any text field -> HTML
#   {{ page.essay_text | essay_markup }}     the catalogue-entry markup in essay_text -> HTML
#   {{ page.see_also | see_also_links }}     <rs type="building">Name</rs> -> a list of links
#
# The source markup is loose: tag names vary in case, attribute values are sometimes unquoted,
# some line tags are never closed, and Greek transliteration contains stray <...> that are not
# tags. So only known tags are converted; any other <...> is shown as text. Open tags are tracked
# so the output is always balanced.
#
# See docs/item_fields.md.

module PerseusMarkup
  LANG_CODES = {
    'greek' => 'grc', 'latin' => 'la', 'la' => 'la', 'etruscan' => 'ett', 'aramaic' => 'arc',
    'lycian' => 'xlc', 'punic' => 'xpu'
  }.freeze

  # tags found in every text field (names compared without regard to case, except L)
  COMMON = %w[p i b hi bibl pbibref obibref plitref olitref rs foreign title quote lb br].freeze

  # tags found only in essay_text: tag => [opening HTML, closing HTML]
  ESSAY_TAGS = {
    'Title' => ['<p class="essay-title">', '</p>'],
    'Head' => ['<strong class="essay-head">', '</strong>'],
    'Entry' => ['<div class="essay-entry">', '</div>'],
    'Header' => ['<p class="essay-header">', '</p>'],
    'Catalog' => ['<span class="essay-catalog">', '</span>'],
    'Inv' => ['<span class="essay-inv">', '</span>'],
    'Shape' => ['<span class="essay-shape">', '</span>'],
    'Plates' => ['<span class="essay-plates">', '</span>'],
    'List' => ['<ul class="essay-list">', '</ul>'],
    'Item' => ['<li>', '</li>'],
    'Heading' => ['<h6 class="essay-heading">', '</h6>'],
    'L' => ['<span class="essay-line d-block">', '</span>'],
    'PBibRef' => ['<span class="bibref">', '</span>'],
    'OBibRef' => ['<span class="bibref">', '</span>'],
    'PLitRef' => ['<span class="bibref">', '</span>'],
    'OLitRef' => ['<span class="bibref">', '</span>'],
    'CITN' => ['<span class="citn">', '</span>'],
    'VaseRef' => ['<span class="objref">', '</span>'],
    'SculptureRef' => ['<span class="objref">', '</span>'],
    'Other.Text' => ['<div class="essay-text">', '</div>'],
    'Essay.Bib' => ['<div class="essay-bib">', '</div>']
  }.freeze

  # block-level parts of an entry that get a small heading
  ESSAY_LABELED = {
    'Collection.Hist' => 'Collection History',
    'Collection' => 'Collection',
    'Dimensions' => 'Dimensions',
    'Condition' => 'Condition',
    'Preservation' => 'Preservation',
    'Dec.Descr' => 'Decoration'
  }.freeze

  # one-line facts about the entry that get an inline label
  ESSAY_META = {
    'Attribution' => 'Attributed to',
    'Essay.Date' => 'Date',
    'Provenience' => 'Provenience',
    'Dec.Summary' => 'Summary',
    'Dimension' => 'Dimension',
    'KEYWORD' => 'Keyword',
    'Entered.By' => 'Entered by'
  }.freeze

  TOKEN = /<[^<>]*>/
  TAG = %r{\A<(/?)([A-Za-z][\w.]*)((?:\s[^<>]*?)?)\s*/?>\z}

  def markup(input)
    PerseusMarkup.convert(input.to_s, essay: false)
  end

  def essay_markup(input)
    text = input.to_s
    return text unless text.include?('<')

    # Footnotes and page breaks are swapped for placeholders, so that the HTML written for them
    # is not treated as unknown tags, and filled in after the conversion.
    #
    # Footnotes sit inside paragraphs in the source; they are numbered and collected at the end.
    # Page breaks of the printed source keep the page as a data attribute and show nothing.
    notes = []
    text = text.gsub(%r{<Milestone([^<>]*?)/?>(</Milestone>)?}) do
      "\u0001MS:#{Regexp.last_match(1)[/n="([^"]*)"/, 1]}\u0001"
    end
    text = text.gsub(%r{<Note(?:\s+n="[^"]*")?\s*>(.*?)</Note>}m) do
      notes << Regexp.last_match(1)
      "\u0001NOTE#{notes.size}\u0001"
    end

    fill = lambda do |html|
      html.gsub(/\u0001NOTE(\d+)\u0001/) do
        n = Regexp.last_match(1)
        %(<sup class="essay-note-ref"><a id="essay-note-ref-#{n}" href="#essay-note-#{n}">#{n}</a></sup>)
      end.gsub(/\u0001MS:(.*?)\u0001/) { %(<span class="essay-milestone" data-page="#{Regexp.last_match(1)}"></span>) }
    end

    html = fill.call(PerseusMarkup.convert(text, essay: true))
    unless notes.empty?
      items = notes.each_with_index.map do |note, i|
        body = fill.call(PerseusMarkup.convert(note.gsub(%r{</?P>}, ''), essay: true))
        %(<li id="essay-note-#{i + 1}">#{body} <a href="#essay-note-ref-#{i + 1}" aria-label="Back to text">&uarr;</a></li>)
      end
      html += %(<ol class="essay-notes small">#{items.join}</ol>)
    end
    html
  end

  def see_also_links(input)
    text = input.to_s
    return text unless text.include?('<rs')

    site = @context.registers[:site]
    index = PerseusMarkup.index(site)
    items = text.scan(%r{<rs type="(\w+)">(.*?)</rs>}m).map do |type, name|
      id = index[PerseusMarkup.normalize(name)]
      label = id ? %(<a href="#{site.baseurl}/items/#{id}.html">#{name}</a>) : name
      %(<li>#{label} <span class="text-body-secondary small">(#{type})</span></li>)
    end
    %(<ul class="see-also list-unstyled">#{items.join}</ul>)
  end

  # Converts known tags to HTML and shows every other <...> as text.
  def self.convert(text, essay:)
    return text unless text.include?('<')

    stack = [] # [tag name, closing HTML]
    # a '<' that does not begin a complete <...> (a damaged tag in the source) is shown as text
    out = text.gsub(/#{TOKEN}|</) do |token|
      next '&lt;' if token == '<'

      m = TAG.match(token)
      handled = m && tag_html(m[1] == '/', m[2], m[3].to_s, essay, stack)
      handled.nil? ? token.gsub('<', '&lt;').gsub('>', '&gt;') : handled
    end
    out += stack.reverse.map(&:last).join
    # a line tag at the start of a quotation or a field would only add an empty line
    out.sub(/\A(<br>)+/, '').gsub(/(<blockquote[^>]*>)(<br>)+/, '\1')
  end

  # HTML for one tag, or nil if the tag is not one we know
  def self.tag_html(closing, tag, attrs, essay, stack)
    name = tag.downcase
    spec = essay ? essay_spec(tag) : nil
    spec ||= common_spec(tag, name, attrs)
    return nil unless spec
    return(closing ? '' : spec) if spec.is_a?(String) # void element such as <br>

    opening, closer = spec
    if closing
      return '' unless (i = stack.rindex { |entry| entry.first == name })

      closers = stack.slice!(i..).reverse.map(&:last)
      closers.join
    else
      stack << [name, closer]
      opening
    end
  end

  def self.essay_spec(tag)
    if (pair = ESSAY_TAGS[tag])
      pair
    elsif (label = ESSAY_LABELED[tag])
      ["<div class=\"essay-#{slug(tag)}\"><h6>#{label}</h6>", '</div>']
    elsif (label = ESSAY_META[tag])
      ["<p class=\"essay-meta essay-#{slug(tag)}\"><span class=\"essay-label\">#{label}:</span> ", '</p>']
    end
  end

  def self.common_spec(tag, name, attrs)
    return '<br>' if %w[lb br].include?(name)
    # a line of an inscription; never closed in the source, so it is a line break
    return '<br>' if tag == 'L'
    return nil unless COMMON.include?(name)

    case name
    when 'p' then ['<p>', '</p>']
    when 'i', 'title' then ['<em>', '</em>']
    when 'b' then ['<strong>', '</strong>']
    when 'hi'
      case attrs[/rend\s*=\s*"?(\w+)/i, 1].to_s.downcase
      when 'ital' then ['<em>', '</em>']
      when 'head', 'bold' then ['<strong>', '</strong>']
      else ['<span>', '</span>']
      end
    when 'bibl', 'pbibref', 'obibref', 'plitref', 'olitref'
      ref = attrs[/\bn\s*=\s*"([^"]*)"/i, 1]
      [%(<span class="bibl"#{ref ? %( data-ref="#{ref}") : ''}>), '</span>']
    when 'rs'
      type = attrs[/type\s*=\s*"?(\w+)/i, 1]
      [%(<span class="objref"#{type ? %( data-type="#{type.downcase}") : ''}>), '</span>']
    when 'foreign'
      lang = attrs[/lang\s*=\s*"?(\w+)/i, 1].to_s
      code = LANG_CODES[lang.downcase]
      extra = code ? %( lang="#{code}") : (lang.empty? ? '' : %( title="#{lang}"))
      [%(<em class="foreign"#{extra}>), '</em>']
    when 'quote'
      ['<blockquote class="quote">', '</blockquote>']
    end
  end

  def self.slug(tag)
    tag.downcase.tr('.', '-')
  end

  def self.normalize(name)
    name.to_s.gsub(/,(?=\S)/, ', ').gsub(/\s+/, ' ').strip.downcase
  end

  # normalized title or name => objectid, for the object records (not their child images)
  def self.index(site)
    @index ||= {}
    @index[site.config['metadata']] ||= begin
      rows = site.data[site.config['metadata']] || []
      rows.each_with_object({}) do |row, h|
        next if row['objtype'].to_s.empty? || row['objectid'].to_s.empty?

        %w[title name].each { |f| h[normalize(row[f])] ||= row['objectid'] unless row[f].to_s.empty? }
      end
    end
  end

  def self.reset
    @index = nil
  end
end

Liquid::Template.register_filter(PerseusMarkup)
Jekyll::Hooks.register :site, :after_reset do |_site|
  PerseusMarkup.reset
end
