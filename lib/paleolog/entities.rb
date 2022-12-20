# frozen_string_literal: true

module Paleolog
  class User
    include Entity

    schema do
      attributes :id,
                 :name,
                 :login,
                 :email,
                 :password,
                 :password_salt,
                 :created_at,
                 :updated_at
    end
  end

  class Project
    include Entity

    schema do
      attributes :id,
                 :name,
                 :created_at,
                 :updated_at

      has_many :countings,
               :sections,
               :research_participations
    end
  end

  class ResearchParticipation
    include Entity

    schema do
      attributes :id,
                 :project_id,
                 :user_id,
                 :manager,
                 :created_at,
                 :updated_at

      belongs_to :project, :user
    end
  end

  class Counting
    include Entity

    schema do
      attributes :id,
                 :name,
                 :group_id,
                 :marker_id,
                 :marker_count,
                 :project_id

      belongs_to :project, :group, :marker
    end
  end

  class Section
    include Entity

    schema do
      attributes :id,
                 :name,
                 :project_id,
                 :created_at,
                 :updated_at

      belongs_to :project
      has_many :samples
    end
  end

  class Sample
    include Entity

    schema do
      attributes :id,
                 :name,
                 :section_id,
                 :created_at,
                 :updated_at,
                 :bottom_depth,
                 :top_depth,
                 :description,
                 :weight,
                 :rank

      belongs_to :section
    end
  end

  class Group
    include Entity

    schema do
      attributes :id, :name
    end
  end

  class Field
    include Entity

    schema do
      attributes :id, :name, :group_id
      has_many :choices
    end
  end

  class Choice
    include Entity

    schema do
      attributes :id, :name, :field_id
      belongs_to :field
    end
  end

  class Feature
    include Entity

    schema do
      attributes :id, :choice_id, :species_id
      belongs_to :choice, :species
    end
  end

  class Image
    include Entity

    schema do
      attributes :id,
                 :species_id,
                 :image_file_name,
                 :image_content_type,
                 :image_file_size,
                 :sample_id,
                 :ef,
                 :created_at,
                 :updated_at

      belongs_to :species, :sample
    end
  end

  class Species
    include Entity

    schema do
      attributes :id,
                 :group_id,
                 :name,
                 :description,
                 :environmental_preferences,
                 :verified,
                 :created_at,
                 :updated_at

      belongs_to :group
      has_many :features, :images
    end
  end

  class Occurrence
    include Entity

    NORMAL = 0
    OUTSIDE_COUNT = 1
    CARVING = 2
    REWORKING = 3
    STATUSES = [NORMAL, OUTSIDE_COUNT, CARVING, REWORKING].freeze

    schema do
      attributes :id,
                 :species_id,
                 :counting_id,
                 :sample_id,
                 :quantity,
                 :rank,
                 :status,
                 :uncertain

      belongs_to :species, :counting, :sample
    end
  end
end
