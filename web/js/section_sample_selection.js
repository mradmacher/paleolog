import { DomHelpers } from './dom_helpers.js';
import { ProjectRequest, SectionRequest } from './requests.js';

export class SectionSampleSelection {
  constructor(selector, scope = document) {
    this.element = scope.querySelector(selector)
  }

  activate(projectId, sectionId, sampleId, onSelection) {
    this.loadSections(projectId, sectionId, sampleId, onSelection);
  }

  loadSamples(sectionId, sampleId, onSelection) {
    new SectionRequest().get(sectionId).then(
      result => {
        let section = result.section

        let sectionSamplesElement = this.element.querySelector('.samples-list .slot')
        sectionSamplesElement.innerHTML = '';
        section.samples.forEach((sample, i) => {
          let template = DomHelpers.buildFromTemplate('section-sample-template')
          DomHelpers.setText(sample.name, '.sample-name', template)
          DomHelpers.setAttr('data-sample-id', sample.id, '.sample', template)

          template.querySelector('.select-sample.action').addEventListener('click', (event) => {
            event.preventDefault();
            this.selectSample(sectionId, sample.id, onSelection);
          })

          sectionSamplesElement.append(template)
        })

        if (sampleId) {
          this.selectSample(sectionId, sampleId, onSelection);
        } else {
          if (section.samples[0]) {
            this.selectSample(sectionId, section.samples[0].id, onSelection);
          }
        }
      },
      errors => {
        console.log(errors)
      }
    )
  }

  loadSections(projectId, sectionId, sampleId, onSelection) {
    new ProjectRequest().sections(projectId).then(
      result => {
        let sectionsElement = this.element.querySelector('.sections-list .slot')
        sectionsElement.innerHTML = '';
        result.sections.forEach((section, i) => {
          let template = DomHelpers.buildFromTemplate('section-template')
          DomHelpers.setText(section.name, '.section-name', template)
          DomHelpers.setAttr('data-section-id', section.id, '.section', template)

          template.querySelector('.select-section.action').addEventListener('click', (event) => {
            event.preventDefault();
            this.selectSection(section.id, null, onSelection);
          })
          sectionsElement.append(template)
        })
        if (sectionId) {
          this.selectSection(sectionId, sampleId, onSelection);
        } else {
          if (result.sections[0]) {
            this.selectSection(result.sections[0].id, null, onSelection);
          }
        }
      }
    )
  }

  selectSection(sectionId, sampleId, onSelection) {
    DomHelpers.unselectAll('.sections-list .section', this.element);
    DomHelpers.selectAll(`.section[data-section-id="${sectionId}"]`, this.element);
    this.loadSamples(sectionId, sampleId, onSelection);
    onSelection({ sectionId });
  }

  selectSample(sectionId, sampleId, onSelection) {
    DomHelpers.unselectAll('.samples-list .sample', this.element);
    DomHelpers.selectAll(`.sample[data-sample-id="${sampleId}"]`, this.element);
    onSelection({ sectionId, sampleId });
  }
}
