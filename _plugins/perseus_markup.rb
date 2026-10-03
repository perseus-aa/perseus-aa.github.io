# frozen_string_literal: true

# Liquid filters for the markup that survives in a few metadata fields.
#
#   {{ page.essay_text | essay_markup }}     the catalogue-entry markup in essay_text -> HTML
#   {{ page.see_also | see_also_links }}     <rs type="building">Name</rs> -> a list of links
#
# See docs/item_fields.md.

module PerseusMarkup
  # tag => [opening HTML, closing HTML]; tags not listed here become <span class="essay-tag">
  ESSAY_TAGS = {
    'P' => ['<p>', '</p>'],
    'I' => ['<em>', '</em>'],
    'B' => ['<strong>', '</strong>'],
    'Head' => ['<strong class="essay-head">', '</strong>'],
    'Title' => ['<p class="essay-title">', '</p>'],
    'Entry' => ['<div class="essay-entry">', '</div>'],
    'Header' => ['<p class="essay-header">', '</p>'],
    'Catalog' => ['<span class="essay-catalog">', '</span>'],
    'Inv' => ['<span class="essay-inv">', '</span>'],
    'Shape' => ['<span class="essay-shape">', '</span>'],
    'Plates' => ['<span class="essay-plates">', '</span>'],
    'List' => ['<ul class="essay-list">', '</ul>'],
    'Item' => ['<li>', '</li>'],
    'Quote' => ['<blockquote class="essay-quote">', '</blockquote>'],
    'L' => ['<span class="essay-line d-block">', '</span>'],
    'PBibRef' => ['<span class="bibref">', '</span>'],
    'OBibRef' => ['<span class="bibref">', '</span>'],
    'PLitRef' => ['<span class="bibref">', '</span>'],
    'OLitRef' => ['<span class="bibref">', '</span>'],
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

  LANG_CODES = { 'Greek' => 'grc', 'Latin' => 'la', 'Etruscan' => 'ett' }.freeze

  TAG = %r{<(/?)([A-Za-z][\w.]*)([^>]*?)(/?)>}

  def essay_markup(input)
    text = input.to_s
    return text unless text.include?('<')

    notes = []
    # footnotes sit inside paragraphs in the source; number them and collect them at the end
    text = text.gsub(%r{<Note n="([^"]*)">(.*?)</Note>}m) do
      notes << Regexp.last_match(2)
      n = notes.size
      %(<sup class="essay-note-ref"><a id="essay-note-ref-#{n}" href="#essay-note-#{n}">#{n}</a></sup>)
    end
    # page breaks of the printed source: keep the page as a data attribute, show nothing
    text = text.gsub(%r{<Milestone([^>]*?)/?>(</Milestone>)?}) do
      page = Regexp.last_match(1)[/n="([^"]*)"/, 1]
      %(<span class="essay-milestone" data-page="#{page}"></span>)
    end

    html = text.gsub(TAG) { essay_tag(Regexp.last_match(1) == '/', Regexp.last_match(2), Regexp.last_match(3)) }

    unless notes.empty?
      items = notes.each_with_index.map do |note, i|
        body = note.gsub(%r{</?P>}, '').gsub(TAG) { essay_tag(Regexp.last_match(1) == '/', Regexp.last_match(2), Regexp.last_match(3)) }
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

  private

  def essay_tag(closing, tag, attrs)
    if (pair = ESSAY_TAGS[tag])
      return pair[closing ? 1 : 0]
    end
    if (label = ESSAY_LABELED[tag])
      return closing ? '</div>' : %(<div class="essay-#{tag.downcase.tr('.', '-')}"><h6>#{label}</h6>)
    end
    if (label = ESSAY_META[tag])
      return closing ? '</p>' : %(<p class="essay-meta essay-#{tag.downcase.tr('.', '-')}"><span class="essay-label">#{label}:</span> )
    end
    case tag
    when 'foreign'
      return '</em>' if closing

      lang = attrs[/lang="([^"]*)"/, 1]
      code = LANG_CODES[lang]
      %(<em class="essay-foreign"#{code ? %( lang="#{code}") : ''}#{lang && !code ? %( title="#{lang}") : ''}>)
    when 'Heading'
      closing ? '</h6>' : '<h6 class="essay-heading">'
    when 'CITN'
      closing ? '</span>' : '<span class="citn">'
    else
      closing ? '</span>' : %(<span class="essay-#{tag.downcase.tr('.', '-')}">)
    end
  end
end

Liquid::Template.register_filter(PerseusMarkup)
Jekyll::Hooks.register :site, :after_reset do |_site|
  PerseusMarkup.reset
end
