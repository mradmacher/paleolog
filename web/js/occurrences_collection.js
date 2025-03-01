import { OccurrenceRequest } from './requests.js';
import { DomHelpers } from './dom_helpers.js';
import { MotivatingSlogan } from './motivating_slogan.js';

class SetQuantityDialog {
  constructor(selector, scope = document) {
    this.element = scope.querySelector(selector);
  }

  show(initialQuantity, speciesName, groupName) {
    DomHelpers.setText(speciesName, '.species-name', this.element);
    DomHelpers.setText(groupName, '.group-name', this.element);

    const quantityElement = this.element.querySelector('[name="occurrence-quantity"]');
    quantityElement.value = initialQuantity;
    this.element.classList.add('is-active');

    return new Promise((resolve) => {
      const cancelListener = (event) => {
        event.target.removeEventListener('click', cancelListener);
        this.hide();
      }

      const confirmListener = (event) => {
        if (Number.isInteger(parseInt(quantityElement.value))) {
          event.target.removeEventListener('click', confirmListener);
          this.hide();
          resolve(quantityElement.value);
        } else {
          alert("Please enter a number.");
        }

      }
      this.element.querySelector('.button.cancel').addEventListener('click', cancelListener);
      this.element.querySelector('.button.confirm').addEventListener('click', confirmListener);
    });
  }

  hide() {
    this.element.classList.remove('is-active');
  }
}

export class OccurrencesCollection {
  constructor(projectId, collectionSelector, summarySelector, scope = document) {
    this.projectId = projectId;
    this.summaryElement = scope.querySelector(summarySelector);
    this.collectionElement = scope.querySelector(collectionSelector);
    this.collectionSlotElement = this.collectionElement.querySelector('.occurrences-slot');
    this.setQuantityDialog = new SetQuantityDialog('.modal.set-quantity');
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
      this.collectionSlotElement.innerHTML = '';
      result.occurrences.forEach(occurrence => {
        this.addOccurrence(occurrence);
      })
      this.updateSummary(result.summary);
    });
  }

  addOccurrence(occurrence) {
    this.collectionSlotElement.append(this.buildOccurrenceRow(occurrence));
  }

  updateSummary(summary) {
    DomHelpers.setText(summary.uncountable, '.occurrences-uncountable-sum', this.summaryElement);
    DomHelpers.setText(summary.countable, '.occurrences-countable-sum', this.summaryElement);
    DomHelpers.setText(summary.total, '.occurrences-total-sum', this.summaryElement);
  }

  buildOccurrenceRow(occurrence) {
    const element = DomHelpers.buildFromTemplate('occurrence-template');
    element.querySelector('.occurrence').setAttribute("data-occurrence-id", occurrence.id);

    element.querySelector('.occurrence-group-name').textContent = occurrence.group_name;
    element.querySelector('.occurrence-species-name').textContent = occurrence.species_name;
    element.querySelector('.occurrence-quantity').textContent = occurrence.quantity;
    element.querySelector('.occurrence-status').value = occurrence.status;
    element.querySelector('.occurrence-uncertain').checked = occurrence.uncertain;

    element.querySelector('.increase-quantity').addEventListener('click', () => {
      this.updateOccurrence(occurrence.id, { shift: 1 });
    });

    element.querySelector('.set-quantity').addEventListener('click', () => {
      const currentQuantity = this.occurrenceElementFor(occurrence.id).querySelector('.occurrence-quantity').textContent;
      this.setQuantityDialog.show(currentQuantity, occurrence.species_name, occurrence.group_name).then(value => {
        this.updateOccurrence(occurrence.id, { quantity: value });
      })
    });

    element.querySelector('.update-status').addEventListener('change', (event) => {
      let status = event.target.value;
      this.updateOccurrence(occurrence.id, { status: status });
    });

    element.querySelector('.update-uncertain').addEventListener('change', (event) => {
      var uncertain;
      if (event.target.checked) {
        uncertain = true
      } else {
        uncertain = false
      };
      this.updateOccurrence(occurrence.id, { uncertain: uncertain });
    });

    element.querySelector('.delete-occurrence').addEventListener('click', () => {
      const text = 'Do you confirm removing this occurrence?'
      if (confirm(text) == true) {
        this.removeOccurrence(occurrence.id);
      }
    });

    return element;
  }

  updateOccurrence(occurrenceId, attrs) {
    new OccurrenceRequest(this.projectId).save({ ...attrs, ...{ id: occurrenceId }}).then(result => {
      this.occurrenceElementFor(result.occurrence.id).querySelector('.occurrence-quantity').textContent = result.occurrence.quantity;
      this.updateSummary(result.summary);
      this.displayMotivatingSlogan(result.occurrence, result.summary);
    }).catch(errors => {
      alert('Please refresh the page and try again.')
    })
  }

  displayMotivatingSlogan(occurrence, summary) {
    if (occurrence.status == 0 && summary.countable % 100 == 0) {
      alert(`You've just counted up to ${summary.countable}. ${MotivatingSlogan.randomPhrase()}\n\n${MotivatingSlogan.randomQuote()}`);
    }
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
    return this.collectionElement.querySelector(`.occurrence[data-occurrence-id="${id}"]`);
  }
}
