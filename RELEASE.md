# Releasing the Calagator gem

We release Calagator to the RubyGems package repository and we also create releases on Github.


## Update dependencies

We run `bundle update` to update all gems in Gemfile.lock to the newest versions within our Gemfile constraints.

```
bundle update
```

Then we look at `bundle outdated --filter-minor` to see if there are other updates that could be relevant patches and updates that improve security & reliability.

```
bundle outdated --filter-minor
```

Dependabot may have submitted pull requests for these updates, so check there to see if those can be merged now.
If not, update the Gemfile, and then run `bundle install` to install the specific new versions.

```
bundle install 
```

At this point, run all the tests. If something fails, downgrade one by one until you can figure out what caused the issue.
Push these updates to `main` on Github, so the tests also run in the Github CI.

After updating dependencies, look at CHANGES.md, and make sure there are entries for all user and externally facing pull requests that have been merged,
as well as configuration and platform changes. Also add a CHANGES.md entry summarizing dependencies, especially if they fix bugs or address security issues.

## Bump the version

We are using the gem-release gem. The `tag` flag creates a new commit and then tags it.

```
gem bump --version [major|minor|patch] --tag --push 
```

## Create the release

Go to Github and manually create a release for the tag, and paste the CHANGES for that release into the description.

Then make the RubyGems.org release:

```
gem release
```

You can go to our RubyGems page to see that it looks correct. Take the link for this release and share it on twitter!
