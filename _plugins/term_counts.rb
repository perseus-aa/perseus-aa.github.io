# frozen_string_literal: true

require 'erb'

# Counts for the home page: the terms in metadata fields, and the object types.
#
#   {{ items | facet_terms: "period", 20 }}     [[term, count], ...] for one field, most frequent first
#   {{ items | type_counts }}                   [[objtype, count, image], ...], most frequent first
#   {{ 1471 | with_delimiter }}                 1,471
#   {{ "Late Classical" | url_param_escape }}    Late%20Classical, for use after the # of a browse link
#   {{ items | term_counts: "period;material", 20 }}   [[term, count, field], ...] sorted by field and term
#
# Terms in a field are separated by semicolons. Terms are matched without regard to case and
# surrounding space, and a term that occurs in different fields is counted per field. The form shown is the most frequent spelling,
# so "Attic Red Figure" is not shown as "attic red figure". Only terms that occur at least `min`
# times are returned.

module PerseusTermCounts
  def facet_terms(items, field, min = 1)
    term_counts(items, field, min).map { |term, count, _field| [term, count] }
                                  .sort_by { |term, count| [-count, term.downcase] }
  end

  # the object types (objects only, not their child images), with a sample image for each
  def type_counts(items)
    types = Hash.new { |h, k| h[k] = { count: 0, image: nil } }
    Array(items).each do |item|
      type = item['objtype'].to_s
      next if type.empty?

      types[type][:count] += 1
      types[type][:image] ||= item['image_small'].to_s unless item['image_small'].to_s.empty?
    end
    types.map { |type, v| [type, v[:count], v[:image]] }.sort_by { |type, count, _| [-count, type] }
  end

  # Collection Builder's templates use this filter, but Jekyll does not define it, so the value was
  # passed through unchanged. This is the same escaping as encodeURIComponent in the browse page.
  def url_param_escape(input)
    ERB::Util.url_encode(input.to_s)
  end

  def with_delimiter(number)
    number.to_i.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
  end

  def term_counts(items, fields, min = 1)
    fields = fields.to_s.split(';').map(&:strip).reject(&:empty?)
    min = min.to_i
    tally = Hash.new { |h, k| h[k] = Hash.new(0) } # [key, field] => { spelling => count }

    Array(items).each do |item|
      fields.each do |field|
        item[field].to_s.split(';').each do |raw|
          term = raw.strip
          next if term.empty?

          tally[[term.downcase, field]][term] += 1
        end
      end
    end

    tally.map do |(_key, field), spellings|
      [spellings.max_by { |spelling, n| [n, spelling] }.first, spellings.values.sum, field]
    end.select { |_term, count, _field| count >= min }
       .sort_by { |term, _count, field| [field, term.downcase] }
  end
end

Liquid::Template.register_filter(PerseusTermCounts)
