import { SpeciesSearch } from '/js/species_search.js';
import { DomHelpers } from '/js/dom_helpers.js';

export class OccurrenceSpeciesSelector {
  constructor(selector, scope = document) {
    this.element = scope.querySelector(selector);
  }

  show({ countingGroupId = null }) {
    this.element.classList.add('is-active');

    const cancelListener = (event) => {
      event.target.removeEventListener('click', cancelListener);
      this.element.classList.remove('is-active');
    }

    this.element.querySelector('.button.cancel').addEventListener('click', cancelListener);
    return new Promise((resolve) => {
      new SpeciesSearch({
        selector: '#species-search',
        onSpeciesSearched: (result) => {
          this.showSearchResult(result, (speciesId) => {
            this.element.classList.remove('is-active');
            resolve(speciesId);
          });
        },
        updatePath: false,
        initialFilter: countingGroupId ? { group_id: countingGroupId } : {},
      });
    });
  }

  showSearchResult(result, callback) {
    this.element.querySelector('tbody').innerHTML = '';
    this.element.querySelector('.search-species-size').textContent = result.result.length;
    result.result.forEach(species => {
      let template = DomHelpers.buildFromTemplate('search-species-template');
      DomHelpers.setText(species.name, '.species-name', template);
      DomHelpers.setText(species.group_name, '.species-group-name', template);
      template.querySelector('.select-species-action').addEventListener('click', () => {
        callback(species.id);
      });
      this.element.querySelector('tbody').append(template);
    });
  }
}
