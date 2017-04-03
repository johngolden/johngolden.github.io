---
title: posts
permalink: posts
---

<h2>posts</h2>

{% for post in site.posts %}
[**{{post.title}}**](http://evandekhayser.com{{post.url}}) {{ post.date | date: "%-d %b %Y" }}
{% endfor %}
