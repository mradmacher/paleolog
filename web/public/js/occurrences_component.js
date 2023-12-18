import { OccurrenceRequest } from '/js/requests.js';
import { DomHelpers } from '/js/dom_helpers.js';

export class OccurrencesComponent {
  constructor(projectId, collectionSelector, summarySelector, scope = document) {
    this.projectId = projectId;
    this.summaryElement = scope.querySelector(summarySelector);
    this.collectionElement = scope.querySelector(collectionSelector);
  }

  show() {
    this.collectionElement.classList.remove('is-hidden');
    this.summaryElement.classList.remove('is-hidden');
  }

  hide() {
    this.collectionElement.classList.add('is-hidden');
    this.summaryElement.classList.add('is-hidden');
  }

  loadOccurrences(countingId, sectionId, sampleId) {
    var attrs = {
      counting_id: countingId,
      section_id: sectionId,
      sample_id: sampleId,
    };

    new OccurrenceRequest(this.projectId).index(attrs).then(result => {
      let collectionSlotElement = this.collectionElement.querySelector('.occurrences-slot');
      collectionSlotElement.innerHTML = '';
      result.occurrences.reverse().forEach(occurrence => {
        collectionSlotElement.prepend(this.buildOccurrenceRow(occurrence));
      })
      this.updateSummary(result.summary);
    });
  }

  updateSummary(summary) {
    DomHelpers.setText('.occurrences-uncountable-sum', summary.uncountable, this.summaryElement);
    DomHelpers.setText('.occurrences-countable-sum', summary.countable, this.summaryElement);
    DomHelpers.setText('.occurrences-total-sum', summary.total, this.summaryElement);
  }

  buildOccurrenceRow(occurrence) {
    let element = $($("#occurrence-template").html());
    element.attr("data-occurrence-id", occurrence.id);

    element.find(".occurrence-group-name").text(occurrence.group_name);
    element.find(".occurrence-species-name").text(occurrence.species_name);
    element.find(".occurrence-quantity").text(occurrence.quantity);
    element.find(".occurrence-status").val(occurrence.status);
    element.find(".occurrence-uncertain").prop('checked', occurrence.uncertain);

    element.find(".increase-quantity").click(() => {
      this.updateOccurrence(occurrence.id, { shift: 1 });
    });
    element.find('.set-quantity').click(() => {
      const modal = document.querySelector('.modal.set-quantity');
      DomHelpers.setText('.species-name', occurrence.species_name, modal);
      DomHelpers.setText('.group-name', occurrence.group_name, modal);
      const quantityElement = modal.querySelector('.occurrence-quantity');
      quantityElement.value = element.find(".occurrence-quantity").text();
      modal.classList.add('is-active');
      modal.querySelector('.button.cancel').addEventListener('click', () => {
        modal.classList.remove('is-active');
      })
      modal.querySelector('.button.confirm').addEventListener('click', () => {
        if (Number.isInteger(parseInt(quantityElement.value))) {
          this.updateOccurrence(occurrence.id, { quantity: quantityElement.value });
          modal.classList.remove('is-active');
        } else {
          alert("Please enter a number.");
        }
      })
    });
    element.find(".update-status").change((event) => {
      var status = $(event.target).val();
        this.updateOccurrence(occurrence.id, { status: status });
    });
    element.find(".update-uncertain").change((event) => {
      var uncertain;
      if($(event.target).prop("checked")) {
        uncertain = true
      } else {
        uncertain = false
      };
      this.updateOccurrence(occurrence.id, { uncertain: uncertain });
    });
    element.find('.delete-occurrence').click(() => {
      const text = 'Do you confirm removing this occurrence?'
      if (confirm(text) == true) {
        this.removeOccurrence(occurrence.id);
      }
    });

    return element[0];
  }

  updateOccurrence(occurrenceId, attrs) {
    new OccurrenceRequest(this.projectId).save({ ...attrs, ...{ id: occurrenceId }}).then(result => {
      this.occurrenceElementFor(result.occurrence.id).find(".occurrence-quantity").text(result.occurrence.quantity);
      this.updateSummary(result.summary)
    }).catch(errors => {
      alert('Please refresh the page and try again.')
    })
  }

  removeOccurrence(occurrenceId) {
    new OccurrenceRequest(this.projectId).remove(occurrenceId).then(result => {
      this.occurrenceElementFor(result.occurrence.id).remove();
      this.updateSummary(result.summary)
    }).catch(errors => {
      alert('Please refresh the page and try again.')
    })
  }

  occurrenceElementFor(id) {
    return $(".occurrence[data-occurrence-id='" + id + "']");
  }
}
