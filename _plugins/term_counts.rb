# frozen_string_literal: true

# Counts the terms in one or more metadata fields, for the Subjects and Locations clouds.
#
#   {{ items | term_counts: "period;material", 20 }}
#
# returns [[term, count, field], ...] sorted by field and term. Terms in a field are separated by
# semicolons. Terms are matched without regard to case and surrounding space, and a term that
# occurs in different fields is counted per field. The form shown is the most frequent spelling,
# so "Attic Red Figure" is not shown as "attic red figure". Only terms that occur at least `min`
# times are returned.

module PerseusTermCounts
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
