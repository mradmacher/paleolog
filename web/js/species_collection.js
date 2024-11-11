import { DomHelpers } from './dom_helpers.js';
import { UrlBuilder } from './url_builder.js';
import { SpeciesModalFormView } from "./modal_form_views.js";

export class SpeciesCollection {
  constructor(selector, scope = document) {
    this.element = scope.querySelector(selector);
  }

  replaceAll(speciesCollection, projectId = null) {
    const slotElement = this.element.querySelector('.species-slot');
    slotElement.innerHTML = '';
    DomHelpers.setText(speciesCollection.length, '.search-species-size', this.element);
    speciesCollection.forEach(species => {
      let template = DomHelpers.buildFromTemplate('search-species-template');
      DomHelpers.setText(species.name, '.species-name', template)
      DomHelpers.setText(species.group_name, '.species-group-name', template)
      DomHelpers.setAttr(
        'href',
        UrlBuilder.species(species.id, { projectId: projectId }),
        '.species-link',
        template
      );
      slotElement.append(template);
    })
  }
}

