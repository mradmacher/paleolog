import { DomHelpers } from '/js/dom_helpers.js';
import { UrlParamsUpdater } from '/js/url_params_updater.js';
import { SpeciesRequest } from '/js/requests.js';

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

    this.element.querySelector('[type="submit"]').addEventListener('click', (event) => {
      event.preventDefault();
      const attrs = {
        group_id: this.element.querySelector('[name="group_id"]').value,
        name: this.element.querySelector('[name="name"]').value,
        verified: this.element.querySelector('[name="verified"]').checked,
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
      template.querySelector('option').value = '';
      template.querySelector('option').textContent = '';
      let selectElement = this.element.querySelector('[name="group_id"]');
      selectElement.append(template);
      filters.groups.forEach((group) => {
        let template = DomHelpers.buildFromTemplate('search-group-option-template')
        template.querySelector('option').value = group.id
        template.querySelector('option').textContent = group.name
        selectElement.append(template);
      });
    });
  }

  showFilters(attrs) {
    for(let attr in attrs) {
      if(attr == 'verified') {
        this.element.querySelector(`[name="${attr}"]`).checked = true;
      } else {
        this.element.querySelector(`[name="${attr}"]`).value = attrs[attr];
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
