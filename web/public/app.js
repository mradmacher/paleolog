const errorMessages = {
  project: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    },
  },
  section: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    },
  },
  counting: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    },
  },
  sample: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    },
    weight: {
      non_decimal: "Weight needs to be a decimal number",
    },
  }
}

class ModelRequest {
  constructor(path) {
    this.path = path;
  }

  save(attrs) {
    let {id, ...params} = attrs;
    var url;
    var type;
    if (id) {
      url = `${this.path}/${id}`;
      type = 'PATCH'
    } else {
      url = this.path;
      type = 'POST';
    }

    return new Promise((resolve, reject) => {
      $.ajax({
        url: url,
        data: params,
        type: type,
        dataType: "json",
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(xhr.responseJSON.errors);
      })
    })
  }
}

class ProjectRequest extends ModelRequest {
  constructor() {
    super('/api/projects');
  }
}

class SectionRequest extends ModelRequest {
  constructor() {
    super(`/api/sections`);
  }
}

class CountingRequest extends ModelRequest {
  constructor() {
    super(`/api/countings`);
  }
}

class SampleRequest extends ModelRequest {
  constructor() {
    super(`/api/samples`);
  }
}

class ValidationMessageView {
  constructor(model) {
    this.model = model;
    this.elementPath = `#${model}-form-window .validation-messages`;
    this.element = $(this.elementPath);
  }

  hide() {
    this.element.hide();
    this.clear();
  }

  clear() {
    this.element.find('.content').text('');
  }

  show(errors) {
    var that = this;
    this.clear();
    jQuery.each(errors, function(field, message) {
      that.element.show();
      that.element.find('.content').append(errorMessages[that.model][field][message]);
    })
  }
}

class ModalFormView {
  constructor(model, attrs, requestService, callback) {
    this.model = model
    this.attrs = attrs
    this.requestService = requestService
    this.callback = callback

    this.modal = $($('#form-window-template').html())
    var form = $($(`#${model}-form-template`).html())
    console.log(form)
    var modelTitle = model.charAt(0).toUpperCase() + model.slice(1)
    var actionTitle = ''
    if ('id' in attrs) {
      actionTitle = 'Edit'
    } else {
      actionTitle = 'Add'
    }
    this.modal.find('.header').text(`${actionTitle} ${modelTitle}`)
    this.modal.find('form').append(form)
  }

  show() {
    var validationMessageView = new ValidationMessageView(this.model);
    validationMessageView.hide();
    var form = this.modal.find('form')
    form.trigger('reset');
    for (const field in this.attrs) {
      form.find(`[name=${field}]`).val(this.attrs[field]);
    }
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
            validationMessageView.show(errors)
          }
        )
        return false
      }
    })
    .modal('show')
  }
}

class ProjectModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('project', attrs, new ProjectRequest, callback)
  }
}

class SectionModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('section', attrs, new SectionRequest, callback)
  }
}

class CountingModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('counting', attrs, new CountingRequest, callback)
  }
}

class SampleModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('sample', attrs, new SampleRequest, callback)
  }
}
