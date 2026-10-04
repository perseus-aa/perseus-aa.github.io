---
# create lunr store for search page
# An object's `images` (a comma-separated list of Perseus image ids) is stored with spaces, so that
# each id is a search term; `image_id` is the Perseus image id of an image record (its `id`, which the
# `id` key at the end of each entry overwrites). An image with several parents links to the first one.
# See _data/config-search.csv for the fields indexed.
---
{% if site.data.theme.search-child-objects == true %}
{%- assign items = site.data[site.metadata] | where_exp: 'item','item.objectid' -%}
{% else %}
{%- assign items = site.data[site.metadata] | where_exp: 'item','item.objectid and item.parentid == nil' -%}
{% endif %}
{%- assign fields = site.data.config-search -%}
var store = [ 
{%- for item in items -%} 
{  
{% for f in fields %}{% if item[f.field] %}{{ f.field | jsonify }}: {% if f.field == 'images' %}{{ item[f.field] | replace: ',', ' ' | normalize_whitespace | jsonify }}{% else %}{{ item[f.field] | normalize_whitespace | replace: '""','"' | jsonify }}{% endif %},{% endif %}{% endfor %}
{% unless item.objtype %}{% if item.id %}"image_id": {{ item.id | jsonify }},{% endif %}{% endunless %} 
"id": {% if item.parentid %}{{ item.parentid | split: ',' | first | strip | append: '.html#' | append: item.objectid | jsonify }}{% else %}{{item.objectid | append: '.html' | jsonify }}{% endif %}

}{%- unless forloop.last -%},{%- endunless -%}
{%- endfor -%}
];
