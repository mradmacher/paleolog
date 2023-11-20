import { errorMessages } from "./error_messages.js"
import * as requests from "./requests.js"

export class ModalFormView {
  constructor(model, attrs, requestService, callback) {
    this.model = model
    this.attrs = attrs
    this.requestService = requestService
    this.callback = callback

    this.modal = $($('#form-window-template').html())
    var form = $($(`#${model}-form-template`).html())
    var modelTitle = model.charAt(0).toUpperCase() + model.slice(1)
    var actionTitle = ''
    if ('id' in attrs) {
      actionTitle = 'Edit'
    } else {
      actionTitle = 'Add'
    }
    this.modal.find('>.header').text(`${actionTitle} ${modelTitle}`)
    this.modal.find('form').append(form)
  }

  clearErrors() {
    this.modal.find('.validation-messages .content').text('')
  }

  hideErrors() {
    this.modal.find('.validation-messages').hide()
    this.clearErrors()
  }

  showErrors(errors) {
    this.clearErrors()
    this.modal.find('.validation-messages').show()
    var errorsContent = this.modal.find('.validation-messages .content')
    var that = this
    jQuery.each(errors, function(field, message) {
      errorsContent.append(errorMessages[that.model][field][message])
      errorsContent.append('<br />')
    })
  }

  loadFormData(form) {}

  show() {
    this.hideErrors()
    var form = this.modal.find('form')
    form.trigger('reset');
    for (const field in this.attrs) {
      form.find(`[name=${field}]`).val(this.attrs[field]);
    }
    this.loadFormData(form)
    var that = this;
    this.modal.modal({
      closable: false,
      onApprove: function() {
        var attrs = {}
        var form = that.modal.find('form')
        for (const field in that.attrs) {
          attrs[field] = form.find(`[name=${field}]`).val()
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
        var option = $($('#species-group-option-template').html());
        option.val(group.id);
        option.text(group.name);
        form.find('#species-group-id').append(option);
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
