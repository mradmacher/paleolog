#TODO counting and sample should have the same section
 class Sample < ActiveRecord::Base
  NAME_MIN_LENGTH = 1
	NAME_MAX_LENGTH = 32
	NAME_RANGE = NAME_MIN_LENGTH..NAME_MAX_LENGTH

  NAME_SIZE = 10
  BOTTOM_DEPTH_SIZE = 10
  TOP_DEPTH_SIZE = 10
  WEIGHT_SIZE = 10
	DESCRIPTION_ROWS = 12
	DESCRIPTION_COLS = 60

  belongs_to :section
  has_many :images
  has_many :occurrences

  validates :rank, presence: true, uniqueness: { scope: :section_id }
  validates :name, uniqueness: { scope: :section_id }, presence: true, length: { within: NAME_RANGE }
  validates :section_id, :presence => true
  validates :weight, :numericality => { :greater_than => 0 }, allow_nil: true

  scope :viewable_by, lambda { |user| joins(section: { project: :research_participations }).where(research_participations: { user_id: user.id }) }
  scope :manageable_by, lambda { |user| joins(section: { project: :research_participations }).where(research_participations: { user_id: user.id, manager: true }) }
  # order of samples is important
  # samples must be ordered by bottom_depth
  # occurrences must be ordered by specimen's first occurrence
  # samples.sort{ |s1, s2| s1.bottom_depth <=> s2.bottom_depth }.each do |sample|
  scope :ordered, lambda { order(rank: :asc) }

  def manageable_by?( user )
    !self.section.nil? && self.section.manageable_by?(user)
  end

  def viewable_by?( user )
    !self.section.nil? && self.section.viewable_by?(user)
  end

  def full_name
    "#{section.name} : #{name}"
  end

  def can_be_destroyed?
    !self.occurrences.exists?
  end

  before_destroy do
    if can_be_destroyed?
      self.occurrences.destroy_all
    else
      errors[:base] << I18n.t( 'activerecord.errors.models.sample.occurrences.exist' )
      false
    end
  end
end
