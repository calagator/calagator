# Helps Mofo users by providing a strip_html on NilClass, saving developers
# from having to write code like:
#   event.title.strip_html if event.title
#
# And instead writing simpler code like:
#   event.title.strip_html
class NilClass
  def strip_html
    nil
  end
end
