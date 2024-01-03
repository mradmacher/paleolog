import { SpeciesSearch } from '/js/species_search.js';
import { DomHelpers } from '/js/dom_helpers.js';

export class OccurrenceSpeciesDialog {
  constructor({
    selector,
    scope = document,
    countingGroupId = null,
    callback = () => {},
  }) {
    this.element = scope.querySelector(selector);
    this.callback = callback;
    this.speciesSearch = new SpeciesSearch({
      selector: '#species-search',
      onSpeciesSearched: (species) => {
        this.showSearchResult(species);
      },
      updatePath: false,
      initialFilter: countingGroupId ? { group_id: countingGroupId } : {},
    });

    this.element.querySelector('.button.cancel').addEventListener('click', (event) => {
      this.hide();
    });
  }

  show() {
    this.element.classList.add('is-active');
  }

  hide() {
    this.element.classList.remove('is-active');
  }

  clearSearchResult() {
    this.element.querySelector('.species-collection').innerHTML = '';
  }

  showSearchResult(collection, callback) {
    this.clearSearchResult();
    this.element.querySelector('.search-species-size').textContent = collection.length;
    collection.forEach(species => {
      let template = DomHelpers.buildFromTemplate('search-species-template');
      DomHelpers.setText(species.name, '.species-name', template);
      DomHelpers.setText(species.group_name, '.species-group-name', template);
      template.querySelector('.select-species-action').addEventListener('click', () => {
        this.hide();
        this.callback(species.id);
      });
      this.element.querySelector('.species-collection').append(template);
    });
  }
}
