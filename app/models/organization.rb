class Organization < ActiveRecord::Base
  include StripWhitespace

  has_paper_trail
  acts_as_taggable

  xss_foliate :sanitize => [:description, :access_notes]
  include DecodeHtmlEntitiesHack

  # Associations
  has_many :events, dependent: :nullify
  def future_events; events.future_with_organization; end
  def past_events; events.past_with_organization; end
  belongs_to :source

  # Triggers
  strip_whitespace! :title, :description, :url, :email, :telephone

  # Validations
  validates_presence_of :title
  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true

  validates :title, :description, :url, :email, :telephone, blacklist: true

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version
  duplicate_squashing_ignores_associations :tags, :base_tags, :taggings

  # Named scopes
  scope :masters,          -> { where(duplicate_of_id: nil).includes(:source, :events, :tags, :taggings) }

  #===[ Finders ]=========================================================

  # Return Hash of Organizations grouped by the +type+, e.g., a 'title'. Each Organization
  # record will include an <tt>events_count</tt> field containing the number of
  # events at the organization, which improves performance for displaying these.
  def self.find_duplicates_by_type(type='na')
    case type
    when 'na', nil, ''
      # The LEFT OUTER JOIN makes sure that organizations without any events are also returned.
      return { [] => \
        self.where('organizations.duplicate_of_id IS NULL').order('LOWER(organizations.title)')
      }
    else
      kind = %w[all any].include?(type) ? type.to_sym : type.split(',').map(&:to_sym)

      return self.find_duplicates_by(kind, 
        :grouped  => true, 
        :where    => 'a.duplicate_of_id IS NULL AND b.duplicate_of_id IS NULL'
      )
    end
  end

  #===[ Search ]==========================================================

  def self.search(query, opts={})
    SearchEngine.search(query, opts)
  end

  #===[ Overrides ]=======================================================

  def url=(value)
    super UrlPrefixer.prefix(value)
  end
end
