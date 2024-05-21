import { SpeciesSearch } from './components/species_search.js';
import { SpeciesCollection } from './species_collection.js';
import { DomHelpers } from './dom_helpers.js';

DomHelpers.onDOMContentLoaded(document, () => {
  const speciesFilters = JSON.parse(document.getElementById("species-filters").value);
  const defaultFilters = { verified: true }

  const speciesCollection = new SpeciesCollection('.species-collection');

  new SpeciesSearch({
    selector: '[data-js-species-search]',
    onSpeciesSearched: (species) => {
      speciesCollection.replaceAll(species);
    },
    updatePath: true,
    initialFilter: { ...defaultFilters, ...speciesFilters },
  });
})
