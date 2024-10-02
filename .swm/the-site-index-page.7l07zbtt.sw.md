---
title: The site index page
---
# Introduction

This document will walk you through the implementation of the site index page feature.

The feature enhances the user experience by providing a structured and informative homepage.

We will cover:

1. Purpose of the feature.
2. Key takeaways from the implementation.
3. Dependencies involved.

# Purpose

The site index page is designed to provide users with quick access to essential information about the site, popular tags, and upcoming events.

# Key takeaways

## Caching the site index

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="1">

---

We use caching to improve performance by storing the rendered content of the site index page. This reduces the load on the server by serving cached content for repeated requests.

```
<% cache(Calagator::CacheObserver.daily_key_for("site_index", request)) do %>
<a href="#" id="homepage_sidebar_toggle" class="expander_toggle">Hi there. Learn about this site and how to use it...</a>
<div id="homepage_sidebar">
  <div id="project_description">
    <%= render :partial => "description" %>
    <%= render :partial => "sidebar_menu" %>
  </div>
```

---

</SwmSnippet>

## Displaying popular tags

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="8">

---

We conditionally display a tag cloud if there are any tags present. This helps users quickly find popular topics.

```

  <% if @overview.tags.present? %>
    <div id="tagcloud">
      <h2>Popular tags</h2>
      <% tag_cloud @overview.tags, %w(tagcloud_level_0 tagcloud_level_1 tagcloud_level_2 tagcloud_level_3 tagcloud_level_4) do |tag, css_class| %>
        <%= link_to tag.name, search_events_path(tag: tag.name), class: css_class %>
        <span class="spacer">&middot;</span>
      <% end %>
    </div>
  <% end %>
</div>
```

---

</SwmSnippet>

## Showing upcoming events

<SwmSnippet path="/app/views/calagator/site/index.html.erb" line="19">

---

We provide a section that lists events happening today, tomorrow, and in the next two weeks. This keeps users informed about current and future events.

```

<div id="whats_happening">
  <h1>What's happening?</h1>
  <h3><%= link_to("View All &raquo;".html_safe, events_path(:anchor => "event-#{@overview.more.id}")) if @overview.more %></h3>
  <div class='coming_events' id='today'>
    <h3>Today</h3>
      <%= render 'calagator/events/list', :events => @overview.today, :dates => false %>
  </div>
  <div class='coming_events' id='tomorrow'>
    <h3>Tomorrow</h3>
    <%= render 'calagator/events/list', :events => @overview.tomorrow, :dates => false %>
  </div>
  <div id='next_two_weeks'>
    <h3>Next two weeks</h3>
    <%= render 'calagator/events/list', :events => @overview.later %>
  </div>
  <div>
    <h3><%= link_to("View future events &raquo;".html_safe, events_path(:anchor => "event-#{@overview.more.id}")) if @overview.more %></h3>
  </div>
</div>
<% end %>
```

---

</SwmSnippet>

# Dependencies

This feature relies on the following dependencies:

- <SwmToken path="/app/views/calagator/site/index.html.erb" pos="1:4:6" line-data="&lt;% cache(Calagator::CacheObserver.daily_key_for(&quot;site_index&quot;, request)) do %&gt;">`Calagator::CacheObserver`</SwmToken> for caching.
- Partial templates `_description` and `_sidebar_menu` for rendering the sidebar content.
- Partial template <SwmToken path="/app/views/calagator/site/index.html.erb" pos="25:6:10" line-data="      &lt;%= render &#39;calagator/events/list&#39;, :events =&gt; @overview.today, :dates =&gt; false %&gt;">`calagator/events/list`</SwmToken> for rendering the list of events.

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
