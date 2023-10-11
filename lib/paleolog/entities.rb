# frozen_string_literal: true

require 'entitainer'

module Paleolog
  class User
    include Entitainer

    schema do
      attributes :name,
                 :login,
                 :email,
                 :password,
                 :password_salt,
                 :created_at,
                 :updated_at
    end
  end

  class Project
    include Entitainer

    schema do
      attributes :name,
                 :created_at,
                 :updated_at

      has_many :countings,
               :sections,
               :researchers
    end
  end

  class Researcher
    include Entitainer

    schema do
      attributes :manager,
                 :created_at,
                 :updated_at

      belongs_to :project, :user
    end
  end

  class Counting
    include Entitainer

    schema do
      attributes :name,
                 :marker_count

      belongs_to :project, :group, :marker
    end
  end

  class Section
    include Entitainer

    schema do
      attributes :name,
                 :created_at,
                 :updated_at

      belongs_to :project
      has_many :samples
    end
  end

  class Sample
    include Entitainer

    schema do
      attributes :name,
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
    include Entitainer

    schema do
      attributes :name
    end
  end

  class Field
    include Entitainer

    schema do
      attributes :name, :group_id
      has_many :choices
    end
  end

  class Choice
    include Entitainer

    schema do
      attributes :name
      belongs_to :field
    end
  end

  class Feature
    include Entitainer

    schema do
      attributes :id
      belongs_to :choice, :species
    end
  end

  class Image
    include Entitainer

    schema do
      attributes :image_file_name,
                 :image_content_type,
                 :image_file_size,
                 :ef,
                 :created_at,
                 :updated_at

      belongs_to :species, :sample
    end
  end

  class Species
    include Entitainer

    schema do
      attributes :name,
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
    include Entitainer

    NORMAL = 0
    OUTSIDE_COUNT = 1
    CARVING = 2
    REWORKING = 3
    STATUSES = [NORMAL, OUTSIDE_COUNT, CARVING, REWORKING].freeze

    schema do
      attributes :quantity,
                 :rank,
                 :status,
                 :uncertain

      belongs_to :species, :counting, :sample
    end
  end
end
