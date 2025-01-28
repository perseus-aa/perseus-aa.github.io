---
layout: page
title: Coins
permalink: /coins/
---

<ul>
  {% for coin in site.data.coins  %}
  <li><a href="{{coin.artifact}}.html">{{coin.label}}</a></li>
  {% endfor %}
</ul>
