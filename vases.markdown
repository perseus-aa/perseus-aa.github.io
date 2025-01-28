---
layout: page
title: Vases
permalink: /vases/
---

<ul>
  {% for vase in site.data.vases  %}
  <li><img src="{{vase.thumbnail}}"/><br/>
  <a href="{{vase.id}}.html">{{vase.name}}</a></li>
  {% endfor %}
</ul>
