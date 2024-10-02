---
title: opensearch
---
# Introduction

This document will walk you through the implementation of the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:19:19" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`opensearch`</SwmToken> feature.

The feature allows users to add Calagator's search functionality to their browser's search bar.

We will cover:

1. What the feature is doing.
2. Why the feature is needed.
3. Dependencies involved.
4. Explanation of the code.

# What the feature is doing

The feature generates an <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:19:19" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`opensearch`</SwmToken> description document. This document enables browsers to integrate Calagator's search functionality directly into their search bar.

# Why the feature is needed

This feature is needed to improve user accessibility by allowing them to search Calagator directly from their browser without navigating to the website first.

# Dependencies

The feature relies on:

- Rails URL helpers for generating search URLs.
- XML Builder for constructing the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:19:19" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`opensearch`</SwmToken> description document.

# Explanation of the code

<SwmSnippet path="/app/views/calagator/site/opensearch.xml.builder" line="3">

---

The code is located in <SwmPath>[app/views/calagator/site/opensearch.xml.builder](/app/views/calagator/site/opensearch.xml.builder)</SwmPath>. It constructs an XML document that adheres to the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:19:19" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`opensearch`</SwmToken> specification.

```ruby
xml.instruct!
xml.OpenSearchDescription('xmlns' => 'http://a9.com/-/spec/opensearch/1.1/', 'xmlns:moz' => 'http://www.mozilla.org/2006/browser/search/') do
  xml.ShortName Calagator.title
  xml.Description "Search #{Calagator.title}"
  xml.InputEncoding 'UTF-8'
  # The sub call at the end of this line is because we want to use the rails URL helper, but don't want to urlencode the curly braces.
  xml.Url('type' => 'text/html', 'method' => 'get', 'template' => search_events_url(query: 'searchTerms').sub('searchTerms', '{searchTerms}'))
end
```

---

</SwmSnippet>

- <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="3:0:3" line-data="xml.instruct!">`xml.instruct!`</SwmToken> initializes the XML document.
- <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:0:2" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`xml.OpenSearchDescription`</SwmToken> sets the root element with necessary namespaces.
- <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="5:1:3" line-data="  xml.ShortName Calagator.title">`xml.ShortName`</SwmToken> and <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="6:1:3" line-data="  xml.Description &quot;Search #{Calagator.title}&quot;">`xml.Description`</SwmToken> provide metadata for the search engine.
- <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="7:1:3" line-data="  xml.InputEncoding &#39;UTF-8&#39;">`xml.InputEncoding`</SwmToken> specifies the character encoding.
- <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:1:3" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`xml.Url`</SwmToken> defines the search URL template, using Rails URL helpers to generate the base URL and replacing <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:41:41" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`searchTerms`</SwmToken> with <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:53:55" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`{searchTerms}`</SwmToken> to conform to <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="4:19:19" line-data="xml.OpenSearchDescription(&#39;xmlns&#39; =&gt; &#39;http://a9.com/-/spec/opensearch/1.1/&#39;, &#39;xmlns:moz&#39; =&gt; &#39;http://www.mozilla.org/2006/browser/search/&#39;) do">`opensearch`</SwmToken> syntax.

This setup ensures that browsers can recognize and use Calagator's search functionality.

<SwmSnippet path="/app/views/calagator/site/opensearch.xml.builder" line="9">

---

This code snippet creates a URL using the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:3:3" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`Url`</SwmToken> function from the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:1:1" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`xml`</SwmToken> module. The URL has a type of <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:12:14" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`text/html`</SwmToken>, a method of 'get', and a template that replaces the string <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:41:41" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`searchTerms`</SwmToken> with the value of the <SwmToken path="/app/views/calagator/site/opensearch.xml.builder" pos="9:41:41" line-data="  xml.Url(&#39;type&#39; =&gt; &#39;text/html&#39;, &#39;method&#39; =&gt; &#39;get&#39;, &#39;template&#39; =&gt; search_events_url(query: &#39;searchTerms&#39;).sub(&#39;searchTerms&#39;, &#39;{searchTerms}&#39;))">`searchTerms`</SwmToken> variable.

```ruby
  xml.Url('type' => 'text/html', 'method' => 'get', 'template' => search_events_url(query: 'searchTerms').sub('searchTerms', '{searchTerms}'))
```

---

</SwmSnippet>

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
