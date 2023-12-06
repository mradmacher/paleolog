import { errorMessages } from "./error_messages.js"
import * as requests from "./requests.js"
import { DomHelpers } from "./dom_helpers.js"

export class ModalFormView {
  constructor(model, attrs, requestService, callback) {
    this.model = model
    this.attrs = attrs
    this.requestService = requestService
    this.callback = callback

    this.jqmodal = $($('#form-window-template').html())
    this.modal = this.jqmodal[0]
    const form = DomHelpers.buildFromTemplate(`${model}-form-template`)
    const modelTitle = model.charAt(0).toUpperCase() + model.slice(1)
    let actionTitle = ''
    if ('id' in attrs) {
      actionTitle = 'Edit'
    } else {
      actionTitle = 'Add'
    }
    DomHelpers.setText('.header', `${actionTitle} ${modelTitle}`, this.modal)
    this.modal.querySelector('form').append(form)
  }

  clearErrors() {
    DomHelpers.setText('.validation-messages .content', '', this.modal)
  }

  hideErrors() {
    DomHelpers.hideAll('.validation-messages', this.modal)
    this.clearErrors()
  }

  showErrors(errors) {
    this.clearErrors()
    DomHelpers.showAll('.validation-messages', this.modal)
    var errorsContent = this.modal.querySelector('.validation-messages .content')
    var that = this
    jQuery.each(errors, function(field, message) {
      errorsContent.append(errorMessages[that.model][field][message])
      errorsContent.append('<br />')
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
    this.jqmodal.modal({
      closable: false,
      onApprove: function() {
        var attrs = {}
        var form = that.modal.querySelector('form')
        for (const field in that.attrs) {
          let element = form.querySelector(`[name=${field}]`)
          if (element) {
            attrs[field] = element.value
          }
        }
        that.requestService.save(attrs).then(
          result => {
            that.callback(result)
          },
          errors => {
            that.showErrors(errors)
          }
        )
        return false
      }
    })
    .modal('show')
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
