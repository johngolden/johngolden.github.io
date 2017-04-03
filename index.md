{% for post in site.posts limit:5 %}
<div>{{ post.content }}</div>
{% endfor %}
