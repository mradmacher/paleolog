import { DomHelpers } from '/js/dom_helpers.js';

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
          //this.showSearchResult(result);
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
        this.updateSearchParams(attrs);
      }
      this.fetchSearchResult({ ...attrs, ...this.defaultFilter }).then(result => {
        this.onSpeciesSearchedEvent(result)
      })
    });
  }

  updateSearchParams(attrs) {
    if ('URLSearchParams' in window) {
      let searchParams = new URLSearchParams();
      let searchParamsProvided = false;
      for(let attr in attrs) {
        if(attrs[attr]) {
          searchParams.set(attr, attrs[attr]);
          searchParamsProvided = true;
        }
      }
      let newRelativePathQuery = window.location.pathname;
      if(searchParamsProvided) {
        newRelativePathQuery = newRelativePathQuery + '?' + searchParams.toString();
      }
      history.pushState(null, '', newRelativePathQuery);
    }
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
      //$('#search-species-size').text(0);
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
    for(var attr in attrs) {
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
