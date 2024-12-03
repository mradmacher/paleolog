# frozen_string_literal: true

module Web
  module PathHelpers
    def super_id(object)
      "#{object.id}-#{parameterize(object.name)}"
    end

    def parameterize(name)
      name.gsub(/[[:punct:]]/, '-').gsub(/[[:space:]]+/, '-')
      # name.gsub('/', '').gsub(/[[:space:]]+/, '-')
    end

    def home_path
      '/'
    end

    def projects_path
      '/projects'
    end

    def project_path(project)
      "/projects/#{super_id(project)}"
    end

    def section_path(project, section)
      "/projects/#{super_id(project)}/sections/#{super_id(section)}"
    end

    def species_path(species)
      if defined?(@project) && @project
        "/projects/#{super_id(@project)}/species/#{super_id(species)}"
      else
        "/species/#{super_id(species)}"
      end
    end

    def project_species_path(project)
      "/projects/#{super_id(project)}/species"
    end

    def counting_section_path(project, counting, section)
      "/projects/#{super_id(project)}/countings/#{super_id(counting)}/sections/#{super_id(section)}"
    end

    def counting_path(project, counting, sample: nil, section: nil)
      details = []
      details << "sample=#{super_id(sample)}" if sample
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/countings/#{super_id(counting)}#{details.empty? ? '' : '?'}#{details.join('&')}"
    end

    def occurrences_path(project, counting: nil, sample: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "sample=#{super_id(sample)}" if sample
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/occurrences#{details.empty? ? '' : '?'}#{details.join('&')}"
    end

    def reports_path(project, counting: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/reports#{details.empty? ? '' : '?'}#{details.join('&')}"
    end
  end
end
