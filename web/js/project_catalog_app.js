import { SpeciesSearch } from './components/species_search.js';
import { SpeciesCollection } from './species_collection.js';
import { DomHelpers } from './dom_helpers.js';

DomHelpers.onDOMContentLoaded(document, () => {
  const projectId = document.getElementById("project-id").value;
  const speciesFilters = JSON.parse(document.getElementById("species-filters").value);

  const speciesCollection = new SpeciesCollection('.species-collection');

  new SpeciesSearch({
    selector: '[data-js-species-search]',
    onSpeciesSearched: (species) => {
      speciesCollection.replaceAll(species, projectId);
    },
    updatePath: true,
    initialFilter: speciesFilters,
    defaultFilter: { project_id: projectId },
  });
})
