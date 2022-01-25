# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Reports < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    get '/projects/:project_id/reports' do
      @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
      @section = Paleolog::Repo::Section.new.find_for_project(params[:section].to_i, @project.id) if params[:section]
      if params[:counting]
        @counting = Paleolog::Repo::Counting.new.find_for_project(params[:counting].to_i,
                                                                  @project.id,)
      end
      @groups = Paleolog::Repo::Group.new.all
      @fields = Paleolog::Repo::Field.new.all
      @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.new.all_for_section(@counting, @section) : []
      @species = @occurrences.map(&:species).uniq(&:id)

      using_project_layout { using_reports_layout { display 'reports/index.html' } }
    end

    post '/projects/:project_id/reports' do
      @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
      if params[:section_id]
        @section = Paleolog::Repo::Section.new.find_for_project(params[:section_id].to_i,
                                                                @project.id,)
      end
      if params[:counting_id]
        @counting = Paleolog::Repo::Counting.new.find_for_project(params[:counting_id].to_i,
                                                                  @project.id,)
      end
      @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.new.all_for_section(@counting, @section) : []
      @report = Paleolog::Report.build(params)
      @report.counted_group = @counting.group
      @report.marker = @counting.marker
      @report.marker_quantity = @counting.marker_count
      # def occurrence_density_map(samples, counted_group:, marker:, marker_quantity:)
      @report.generate(@occurrences, @section.samples)
      @chart = Paleolog::Paleorep::ChartView.new(@report)
      using_export_layout { display 'reports/create.html' }
    end

    # def export
    #   @report = Report.build(params[:report])
    # 	@report.generate
    #   respond_to do |format|
    #     format.csv
    #     format.pdf
    #     format.svg
    #     format.html
    #   end
    # end
  end
end
