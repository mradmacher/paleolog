import { SectionRequest } from "./requests.js";
import { SampleModalFormView, SectionModalFormView } from "./modal_form_views.js";
import { DomHelpers } from "./dom_helpers.js";
import { UrlBuilder } from "./url_builder.js";

document.addEventListener('DOMContentLoaded', () => {
  const projectId = document.getElementById("project-id").value;
  const projectName = document.getElementById("project-name").value;
  const sectionId = document.getElementById("section-id").value;

  const section = {
    project_id: projectId,
    name: null,
  }

  const new_sample = {
    section_id: sectionId,
    name: null,
    description: null,
    weight: null,
  }

  document.querySelector('.add-section.action').addEventListener('click', () => {
    new SectionModalFormView(section, (section) => window.location.reload()).show();
  })

  new SectionRequest().get(sectionId).then(
    result => {
      let section = result.section

      DomHelpers.setText(section.name, '.section-name')
      DomHelpers.setHref(UrlBuilder.projectOccurrences(projectId, { projectName: projectName, sectionId: section.id }), '.occurrences-link')
      DomHelpers.setHref(UrlBuilder.projectReports(projectId, { projectName: projectName, sectionId: section.id }), '.reports-link')

      let sectionSamplesElement = document.querySelector('.section-samples tbody')
      section.samples.forEach((sample, i) => {
        let template = DomHelpers.getTemplate('section-sample-template')
        DomHelpers.setText(sample.name, '.sample-name', template)
        DomHelpers.setText(sample.description, '.sample-description', template)
        DomHelpers.setText(sample.weight, '.sample-weight', template)

        template.querySelector('.edit-sample.action').addEventListener('click', (event) => {
          new SampleModalFormView(sample, (sample) => window.location.reload()).show()
        })

        sectionSamplesElement.append(template)
      })

      document.querySelector('.edit-section.action').addEventListener('click', (event) => {
        new SectionModalFormView(section, (section) => window.location.reload()).show()
      })
      document.querySelector('.add-sample.action').addEventListener('click', (event) => {
        new SampleModalFormView(new_sample, (sample) => window.location.reload()).show()
      })
    },
    errors => {
      console.log(errors)
    }
  )
});
