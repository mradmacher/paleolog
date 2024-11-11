import { SpeciesRequest } from "./requests.js";
import { SpeciesModalFormView } from "./modal_form_views.js";
import { UrlBuilder } from './url_builder.js';

document.addEventListener('DOMContentLoaded', () => {
  const speciesId = document.getElementById("species-id").value;
  new SpeciesRequest().get(speciesId).then((result) => {
    let species = result.species;

    document.querySelector('.edit-species.action').addEventListener('click', (event) => {
      new SpeciesModalFormView(species, (species) => window.location.reload()).show();
    })
  });
});
