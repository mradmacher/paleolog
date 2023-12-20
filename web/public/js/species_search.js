import { DomHelpers } from '/js/dom_helpers.js';
import { UrlParamsUpdater } from '/js/url_params_updater.js';

export class SpeciesSearch {
  constructor({
    updatePath = false,
    initialFilter = {},
    defaultFilter = {},
    onSpeciesSearched = null,
  }) {
    if(onSpeciesSearched) {
      this.onSpeciesSearchedEvent= onSpeciesSearched;
    } else {
      this.onSpeciesSearchedEvent = (speciesId) => {
        // do nothing
      };
    };

    this.element = document.querySelector('#species-search');
    this.updatePath = updatePath;
    this.defaultFilter = defaultFilter;
    this.fetchAvailableSearchFilters().then(filters => {
      this.showAvailableSearchFilters(filters);
      if(Object.keys(initialFilter).length > 0 || Object.keys(defaultFilter).length > 0) {
        this.fetchSearchResult({ ...initialFilter, ...defaultFilter }).then(result => {
          this.showFilters(initialFilter);
          this.onSpeciesSearchedEvent(result);
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
      this.fetchSearchResult({ ...attrs, ...this.defaultFilter }).then(result => {
        this.onSpeciesSearchedEvent(result)
      })
    });
  }

  fetchAvailableSearchFilters() {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: '/species/search-filters',
        type: "GET",
        dataType: "json",
      })
      .done((json) => {
        resolve(json);
      }).fail((xhr, status, error) => {
        reject(error)
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
    return new Promise((resolve, reject) => {
      $.ajax({
        url: '/species',
        data: attrs,
        type: "GET",
        dataType: "json",
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(error);
      })
    });
  }
}
