# frozen_string_literal: true

module Web
  module ViewHelpers
    def display(view)
      erb view.to_sym
    end

    def using_application_layout(&)
      erb(:'application.html', layout: nil, &)
    end

    def using_species_layout(&)
      erb(:'species_layout.html', layout: :'application.html', &)
    end

    def using_project_species_layout(&)
      erb(:'species_layout.html', layout: nil, &)
    end

    def using_project_layout(&)
      erb(:'project_layout.html', layout: :'application.html', &)
    end

    def using_occurrences_layout(&)
      erb(:'occurrence_layout.html', layout: nil, &)
    end

    def using_reports_layout(&)
      erb(:'report_layout.html', layout: nil, &)
    end

    def using_export_layout(&)
      erb(:'export_layout.html', layout: nil, &)
    end
  end
end
