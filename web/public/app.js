const errorMessages = {
  project: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    }
  },
  section: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    }
  },
  counting: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    }
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
    this.model = model;
    this.attrs = attrs;
    this.element = $(this.elementPath);
    this.requestService = requestService;
    this.callback = callback;
  }

  show() {
    var validationMessageView = new ValidationMessageView(this.model);
    validationMessageView.hide();
    $(`#${this.model}-form`).trigger('reset');
    for (const field in this.attrs) {
      $(`#${this.model}-form #${this.model}-${field}`).val(this.attrs[field]);
    }
    var that = this;
    $(`#${this.model}-form-window`).modal({
      closable: false,
      onApprove: function() {
        var attrs = {}
        for (const field in that.attrs) {
          attrs[field] = $(`#${that.model}-form #${that.model}-${field}`).val()
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
    super('project', attrs, new ProjectRequest, callback);
  }
}

class SectionModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('section', attrs, new SectionRequest, callback);
  }
}

class CountingModalFormView extends ModalFormView {
  constructor(attrs, callback) {
    super('counting', attrs, new CountingRequest, callback);
  }
}
