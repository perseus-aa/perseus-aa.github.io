# frozen_string_literal: true

# The child rows of an object, for the compound_object layout.
#
#   {% assign children = site.data[site.metadata] | children_of: page.objectid %}
#
# A row is a child of an object when the object's id is one of the comma-separated ids in its
# parentid (a row can have several parents). The rows come back in the order of the metadata.
#
# The layout used to find them by looping over every row of the metadata once for each object
# page: 367 million iterations for the full metadata, about 90% of the build time. Here the rows
# are indexed by parent once per build, and each page does one lookup.

module PerseusChildren
  def children_of(rows, objectid)
    PerseusChildren.index(rows)[objectid.to_s] || []
  end

  def self.index(rows)
    @indexes ||= {}
    @indexes[rows.object_id] ||= begin
      index = Hash.new { |h, k| h[k] = [] }
      Array(rows).each do |row|
        parents = row['parentid'].to_s.split(',')
        parents.uniq.each { |parent| index[parent] << row }
      end
      index.default_proc = nil
      index
    end
  end

  def self.reset
    @indexes = nil
  end
end

Liquid::Template.register_filter(PerseusChildren)
Jekyll::Hooks.register :site, :after_reset do |_site|
  PerseusChildren.reset
end
