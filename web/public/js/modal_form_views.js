import { errorMessages } from "./error_messages.js"
import * as requests from "./requests.js"
import { DomHelpers } from "./dom_helpers.js"

export class ModalFormView {
  constructor(model, attrs, requestService, callback) {
    this.model = model
    this.attrs = attrs
    this.requestService = requestService
    this.callback = callback

    this.modal = DomHelpers.buildFromTemplate('form-window-template').children[0];
    document.body.appendChild(this.modal);
    const form = DomHelpers.buildFromTemplate(`${model}-form-template`)
    const modelTitle = model.charAt(0).toUpperCase() + model.slice(1)
    let actionTitle = ''
    if ('id' in attrs) {
      actionTitle = 'Edit'
    } else {
      actionTitle = 'Add'
    }
    DomHelpers.setText(`${actionTitle} ${modelTitle}`, '.header', this.modal)
    this.modal.querySelector('form').append(form)
  }

  clearErrors() {
    DomHelpers.setText('', '.validation-messages .errors', this.modal)
  }

  hideErrors() {
    DomHelpers.hideAll('.validation-messages', this.modal)
    this.clearErrors()
  }

  showErrors(errors) {
    this.clearErrors()
    DomHelpers.showAll('.validation-messages', this.modal)
    var errorsContent = this.modal.querySelector('.validation-messages .errors')
    var that = this
    jQuery.each(errors, function(field, message) {
      errorsContent.append(errorMessages[that.model][field][message])
      errorsContent.append(document.createElement("br"))
    })
  }

  loadFormData(form) {}

  show() {
    this.hideErrors()
    let form = this.modal.querySelector('form')
    form.reset()
    for (const field in this.attrs) {
      let element = form.querySelector(`[name=${field}]`)
      if (element) {
        element.value = this.attrs[field]
      }
    }
    this.loadFormData(form)
    var that = this;
    this.modal.classList.add('is-active');
    this.modal.querySelector('.button.is-cancel').addEventListener('click', () => {
      this.modal.classList.remove('is-active');
    })
    this.modal.querySelector('.button.is-success').addEventListener('click', () => {
      let attrs = {}
      const form = this.modal.querySelector('form')
      for (const field in this.attrs) {
        let element = form.querySelector(`[name=${field}]`)
        if (element) {
          attrs[field] = element.value
        }
      }
      this.requestService.save(attrs).then(
        result => {
          this.callback(result)
          this.modal.classList.remove('is-active');
        },
        errors => {
          this.showErrors(errors)
        }
      )
    });
  }
}

export class ProjectModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('project', attrs, new requests.ProjectRequest, callback)
  }
}

export class SpeciesModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('species', attrs, new requests.SpeciesRequest, callback)
  }

  loadFormData(form) {
    $.ajax({
      url: '/species/search-filters',
      type: "GET",
      dataType: "json",
    })
    .done(function(json) {
      json.groups.forEach(function(group) {
        let option = DomHelpers.buildFromTemplate('species-group-option-template');
        option.value = group.id;
        option.textContent = group.name;
        form.querySelector('#species-group-id').append(option);
      });
    }).fail(function(xhr, status, error) {
      reject(error)
    })
  }
}

export class SectionModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('section', attrs, new requests.SectionRequest, callback)
  }
}

export class CountingModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('counting', attrs, new requests.CountingRequest, callback)
  }
}

export class SampleModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('sample', attrs, new requests.SampleRequest, callback)
  }
}
