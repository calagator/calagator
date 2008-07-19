`acts_as_solr Rails plugin`
======
This plugin adds full text search capabilities and many other nifty features from Apache's [Solr](http://lucene.apache.org/solr/) to any Rails model.
It was based on the first draft by Erik Hatcher.

Current Release
======
The current stable release is v0.9 and was released on 06-18-2007.

Changes
======
Please refer to the CHANGE_LOG

Installation
======

Requirements
------
* Java Runtime Environment(JRE) 1.5 aka 5.0 [http://www.java.com/en/download/index.jsp](http://www.java.com/en/download/index.jsp)

Basic Usage
======
<pre><code>
# Just include the line below to any of your ActiveRecord models:
  acts_as_solr

# Or if you want, you can specify only the fields that should be indexed:
  acts_as_solr :fields => [:name, :author]

# Then to find instances of your model, just do:
  Model.find_by_solr(query) #query is a string representing your query

# Please see ActsAsSolr::ActsMethods for a complete info

</code></pre>

Authors
======
Erik Hatcher: First draft<br>
Thiago Jackiw: Current developer (tjackiw at gmail dot com)

Release Information
======
Released under the MIT license.

More info
======
[http://acts-as-solr.railsfreaks.com](http://acts-as-solr.railsfreaks.com)