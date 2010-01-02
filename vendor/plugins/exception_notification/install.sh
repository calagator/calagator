# I use this to make life easier when installing and testing from source:
rm -rf super_exception_notifier-*.gem && gem build exception_notification.gemspec && sudo gem uninstall super_exception_notifier && sudo gem install super_exception_notifier-1.7.1.gem --no-ri --no-rdoc
