---
title: Migration Example
---
# Introduction

This document will walk you through the implementation of the migration change for adding missing indexes on the <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="11:4:4" line-data="    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id">`taggings`</SwmToken> table.

We will cover:

1. Why we need to add missing indexes.
2. How the migration is structured to handle different <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="4:2:2" line-data="if ActiveRecord.gem_version &gt;= Gem::Version.new(&#39;5.0&#39;)">`ActiveRecord`</SwmToken> versions.
3. The specific indexes added and their importance.

# Purpose

The primary purpose of this migration is to improve database query performance by adding missing indexes to the <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="11:4:4" line-data="    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id">`taggings`</SwmToken> table. Indexes are crucial for speeding up search queries and ensuring efficient data retrieval.

# Key takeaways

## Handling different <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="4:2:2" line-data="if ActiveRecord.gem_version &gt;= Gem::Version.new(&#39;5.0&#39;)">`ActiveRecord`</SwmToken> versions

<SwmSnippet path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" line="1">

---

The migration handles different versions of <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="4:2:2" line-data="if ActiveRecord.gem_version &gt;= Gem::Version.new(&#39;5.0&#39;)">`ActiveRecord`</SwmToken> to ensure compatibility. This is done by conditionally defining the migration class based on the <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="4:2:2" line-data="if ActiveRecord.gem_version &gt;= Gem::Version.new(&#39;5.0&#39;)">`ActiveRecord`</SwmToken> version.

```
# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 6)
if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration; end
end
AddMissingIndexesOnTaggings.class_eval do
  def change
    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id
    add_index :taggings, :taggable_id unless index_exists? :taggings, :taggable_id
    add_index :taggings, :taggable_type unless index_exists? :taggings, :taggable_type
    add_index :taggings, :tagger_id unless index_exists? :taggings, :tagger_id
    add_index :taggings, :context unless index_exists? :taggings, :context
```

---

</SwmSnippet>

## Adding specific indexes

<SwmSnippet path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" line="1">

---

The <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="10:3:3" line-data="  def change">`change`</SwmToken> method in the migration adds several indexes to the <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="11:4:4" line-data="    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id">`taggings`</SwmToken> table. Each <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="11:1:1" line-data="    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id">`add_index`</SwmToken> call is wrapped in a condition to check if the index already exists, preventing duplication.

```
# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 6)
if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddMissingIndexesOnTaggings < ActiveRecord::Migration; end
end
AddMissingIndexesOnTaggings.class_eval do
  def change
    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id
    add_index :taggings, :taggable_id unless index_exists? :taggings, :taggable_id
    add_index :taggings, :taggable_type unless index_exists? :taggings, :taggable_type
    add_index :taggings, :tagger_id unless index_exists? :taggings, :tagger_id
    add_index :taggings, :context unless index_exists? :taggings, :context
```

---

</SwmSnippet>

<SwmSnippet path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" line="16">

---

Additional indexes are added to handle composite keys, which are essential for optimizing queries involving multiple columns.

```

    unless index_exists? :taggings, %i[tagger_id tagger_type]
      add_index :taggings, %i[tagger_id tagger_type]
    end

    unless index_exists? :taggings, %i[taggable_id taggable_type tagger_id context], name: 'taggings_idy'
      add_index :taggings, %i[taggable_id taggable_type tagger_id context], name: 'taggings_idy'
    end
  end
end
```

---

</SwmSnippet>

By adding these indexes, we ensure that the database can efficiently handle queries involving the <SwmToken path="/db/migrate/20200327040656_add_missing_indexes_on_taggings.acts_as_taggable_on_engine.rb" pos="11:4:4" line-data="    add_index :taggings, :tag_id unless index_exists? :taggings, :tag_id">`taggings`</SwmToken> table, improving overall performance.

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
