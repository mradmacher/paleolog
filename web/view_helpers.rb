# frozen_string_literal: true

module Web
  module ViewHelpers
    def display(view)
      erb view.to_sym
    end

    def using_application_layout(&block)
      erb :'application.html', layout: nil, &block
    end

    def using_species_layout(&block)
      erb :'species_layout.html', layout: :'application.html', &block
    end

    def using_project_layout(&block)
      erb :'project_layout.html', layout: :'application.html', &block
    end

    def using_occurrences_layout(&block)
      erb :'occurrence_layout.html', layout: nil, &block
    end

    def using_reports_layout(&block)
      erb :'report_layout.html', layout: nil, &block
    end

    def using_export_layout(&block)
      erb :'export_layout.html', layout: nil, &block
    end
  end
end
