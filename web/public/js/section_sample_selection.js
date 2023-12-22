import { DomHelpers } from '/js/dom_helpers.js';
import { ProjectRequest, SectionRequest } from '/js/requests.js';

export class SectionSampleSelection {
  constructor(selector, scope = document) {
    this.element = scope.querySelector(selector)
  }

  activate(projectId, onSelection) {
    this.loadSections(projectId, onSelection);
  }

  loadSamples(sectionId, onSelection) {
    new SectionRequest().get(sectionId).then(
      result => {
        let section = result.section

        let sectionSamplesElement = this.element.querySelector('.samples-list .slot')
        sectionSamplesElement.innerHTML = '';
        section.samples.forEach((sample, i) => {
          let template = DomHelpers.buildFromTemplate('section-sample-template')
          DomHelpers.setText(sample.name, '.select-sample', template)
          DomHelpers.setAttr('data-sample-id', sample.id, '.select-sample', template)

          template.querySelector('.select-sample.action').addEventListener('click', (event) => {
            event.preventDefault();
            DomHelpers.unselectAll('.samples-list .sample', this.element);
            DomHelpers.select(event.target.parentElement);
            onSelection({ sectionId, sampleId: sample.id });
          })

          sectionSamplesElement.append(template)
        })
      },
      errors => {
        console.log(errors)
      }
    )
  }

  loadSections(projectId, onSelection) {
    new ProjectRequest().sections(projectId).then(
      result => {
        let sectionsElement = this.element.querySelector('.sections-list .slot')
        sectionsElement.innerHTML = '';
        result.sections.forEach((section, i) => {
          let template = DomHelpers.buildFromTemplate('section-template')
          DomHelpers.setText(section.name, '.select-section', template)
          DomHelpers.setAttr('data-section-id', section.id, '.select-section', template)

          template.querySelector('.select-section.action').addEventListener('click', (event) => {
            event.preventDefault();
            DomHelpers.unselectAll('.sections-list .section', this.element);
            DomHelpers.select(event.target.parentElement);
            this.loadSamples(section.id, onSelection);
            onSelection({ sectionId: section.id });
          })
          sectionsElement.append(template)
        })
      }
    )
  }
}
