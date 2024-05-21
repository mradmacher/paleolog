import { DomHelpers } from '../dom_helpers.js';
import { UrlParamsUpdater } from '../url_params_updater.js';
import { SpeciesRequest } from '../requests.js';

export class SpeciesSearch {
  constructor({
    selector = null,
    scope = document,
    updatePath = false,
    initialFilter = {},
    defaultFilter = {},
    onSpeciesSearched = (speciesId) => {},
  }) {
    this.element = scope.querySelector(selector);
    this.onSpeciesSearchedEvent= onSpeciesSearched;
    this.updatePath = updatePath;
    this.defaultFilter = defaultFilter;
    this.fetchAvailableSearchFilters().then(filters => {
      this.showAvailableSearchFilters(filters);
      if(Object.keys(initialFilter).length > 0 || Object.keys(defaultFilter).length > 0) {
        new SpeciesRequest().index({ ...initialFilter, ...defaultFilter }).then(result => {
          this.showFilters(initialFilter);
          this.onSpeciesSearchedEvent(result.species);
        })
      };
    });

    this.element.querySelector('[data-js-search-action]').addEventListener('click', (event) => {
      event.preventDefault();
      const attrs = {
        group_id: this.element.querySelector('[data-js-group-id-field]').value,
        name: this.element.querySelector('[data-js-name-field]').value,
        verified: this.element.querySelector('[data-js-verified-field]').checked,
      };
      if(this.updatePath) {
        new UrlParamsUpdater().setParams(attrs);
      }
      new SpeciesRequest().index({ ...attrs, ...this.defaultFilter }).then(result => {
        this.onSpeciesSearchedEvent(result.species)
      })
    });
  }

  fetchAvailableSearchFilters() {
    return new Promise((resolve, reject) => {
      fetch('/species/search-filters').then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    })
  }

  showAvailableSearchFilters(filters) {
    return new Promise((resolve, reject) => {
      let template = DomHelpers.buildFromTemplate('search-group-option-template')
      template.querySelector('[data-js-group-option]').value = '';
      template.querySelector('[data-js-group-option]').textContent = '';
      let selectElement = this.element.querySelector('[data-js-group-id-field]');
      selectElement.append(template);
      filters.groups.forEach((group) => {
        let template = DomHelpers.buildFromTemplate('search-group-option-template')
        template.querySelector('[data-js-group-option]').value = group.id
        template.querySelector('[data-js-group-option]').textContent = group.name
        selectElement.append(template);
      });
    });
  }

  showFilters(attrs) {
    for(let attr in attrs) {
      if(attr == 'verified') {
        this.element.querySelector('[data-js-verified-field]').checked = true;
      } else {
        this.element.querySelector(`[data-js-${attr.replace('_', '-')}-field]`).value = attrs[attr];
      }
    }
  }

  fetchSearchResult(attrs) {
    const searchParams = new URLSearchParams(attrs);

    return new Promise((resolve, reject) => {
      fetch(`/species?${searchParams}`, {
        method: 'GET',
      }).then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    })
  }
}
