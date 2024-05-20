import { OccurrenceSpeciesDialog } from './occurrence_species_dialog.js';
import { OccurrencesCollection } from './occurrences_collection.js';
import { SpeciesModalFormView, CountingModalFormView } from "./modal_form_views.js";
import { SectionSampleSelection } from './section_sample_selection.js';
import { OccurrenceRequest, SectionRequest, CountingRequest } from "./requests.js";
import { DomHelpers } from "./dom_helpers.js";
import { UrlBuilder } from "./url_builder.js";
import { UrlParamsUpdater } from './url_params_updater.js';

document.addEventListener('DOMContentLoaded', () => {
  const projectId = document.getElementById("project-id").value;
  const projectName = document.getElementById("project-name").value;
  const countingId = document.getElementById("counting-id").value;

  let selectedSectionId = document.getElementById("selected-section-id").value;
  let selectedSampleId = document.getElementById("selected-sample-id").value;
  let countingGroupId = document.getElementById("counting-group-id").value;

  const counting = {
    project_id: projectId,
    name: null,
  }

  document.querySelector('.add-counting.action').addEventListener('click', () => {
    new CountingModalFormView(counting, (counting) => window.location.reload()).show();
  })

  new CountingRequest().get(countingId).then(
    result => {
      let counting = result.counting
      DomHelpers.setHref(UrlBuilder.projectOccurrences(projectId, { projectName: projectName, countingId: counting.id }), '.occurrences-link')
      DomHelpers.setHref(UrlBuilder.projectReports(projectId, { projectName: projectName, countingId: counting.id }), '.reports-link')
      DomHelpers.setText(counting.name, '.counting-name')
      if(counting.marker_count) {
        DomHelpers.setText(counting.marker_count, '.marker-count')
      } else {
        DomHelpers.hideAll('.marker-count-wrapper')
      }
      if(counting.group_name) {
        DomHelpers.setText(counting.group_name, '.group-name')
      } else {
        DomHelpers.hideAll('.group-name-wrapper')
      }
      if(counting.marker_name) {
        DomHelpers.setText(counting.marker_name, '.marker-name')
        DomHelpers.setText(counting.marker_group_name, '.marker-group-name')
      } else {
        DomHelpers.hideAll('.marker-name-wrapper')
      }
      document.querySelector('.edit-counting.action').addEventListener('click', () => {
        new CountingModalFormView(counting, (counting) => window.location.reload()).show()
      });
    },
    errors => {
      console.log(errors)
    }
  )

  const occurrencesCollection = new OccurrencesCollection(
    projectId,
    '#occurrences-collection',
    '#occurrences-summary'
  );
  const occurrenceSpeciesDialog = new OccurrenceSpeciesDialog({
   selector: '.modal.add-occurrence',
   countingGroupId: countingGroupId,
   callback: (speciesId) => {
     addOccurrence(speciesId, countingId, selectedSampleId);
   }
  });

  const addOccurrence = function(speciesId, countingId, sampleId) {
    const attrs = {
      species_id: speciesId,
      counting_id: countingId,
      sample_id: sampleId,
    };
    new OccurrenceRequest(projectId).save(attrs).then(
      result => {
        occurrencesCollection.addOccurrence(result.occurrence);
      },
      errors => {
        alert(errors);
        window.location.reload();
      }
    )
  }

  document.querySelector('.button.add-occurrence').addEventListener('click', () => {
    occurrenceSpeciesDialog.show();
  });

  // Selecting section and sample
  new SectionSampleSelection('.section-sample-selection').activate(
    projectId, selectedSectionId, selectedSampleId, (selected) => {

    selectedSectionId = selected.sectionId;
    selectedSampleId = selected.sampleId;
    new UrlParamsUpdater().setParams({
      section: selectedSectionId,
      sample: selectedSampleId,
    });

    if (selectedSectionId && selectedSampleId) {
      occurrencesCollection.show();
      occurrencesCollection.loadOccurrences(countingId, selectedSectionId, selectedSampleId)
    } else {
      occurrencesCollection.hide();
    }
  })

  const species = {
    name: null,
    group_id: null,
    //description: null,
    //environmental_preferences: null,
    //verified: false,
  }

  document.querySelector('.add-species.action').addEventListener('click', () => {
    new SpeciesModalFormView(species, (result) => {
      addOccurrence(result.species.id, countingId, selectedSampleId);
    }).show();
  });
});
