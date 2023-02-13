const errorMessages = {
  project: {
    name: {
      taken: "Name is already taken",
      blank: "Name can't be blank"
    }
  }
}

class ProjectRequest {
  create(attrs) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: '/api/projects',
        data: attrs,
        type: "POST",
        dataType: "json",
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(xhr.responseJSON.errors);
      })
    })
  }

  update(id, attrs) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: `/api/projects/${id}`,
        data: attrs,
        type: "PATCH",
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

class SectionRequest {
  create(attrs) {
  }

  update(id, attrs) {
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
      that.element.find('.content').append(errorMessages['project'][field][message]);
    })
  }
}

class EditModalFormView {
  constructor(model, requestService, callback) {
    this.model = model;
    this.element = $(this.elementPath);
    this.requestService = requestService;
    this.callback = callback;
  }

  show() {
    var validationMessageView = new ValidationMessageView(this.model);
    validationMessageView.hide();
    var that = this;
    $(`#${this.model}-form`).trigger('reset');
    $(`#${this.model}-edit-form-window`).modal({
      closable: false,
      onApprove: function() {
        const id = $(`#${that.model}-form #${that.model}-id`).val();
        const attrs = {
          name: $(`#${that.model}-form #${that.model}-name`).val(),
        }
        that.requestService.update(id, attrs).then(
          result => {
            that.callback(result)
          },
          errors => {
            validationMessageView.show(errors)
          }
        )
        return false;
      }
    })
    .modal('show');
  }
}

class AddModalFormView {
  constructor(model, requestService, callback) {
    this.model = model;
    this.element = $(this.elementPath);
    this.requestService = requestService;
    this.callback = callback;
  }

  show() {
    var validationMessageView = new ValidationMessageView(this.model);
    validationMessageView.hide();
    var that = this;
    $(`#${this.model}-form`).trigger('reset');
    $(`#${this.model}-add-form-window`).modal({
      closable: false,
      onApprove: function() {
        const attrs = {
          name: $(`#${that.model}-form #${that.model}-name`).val(),
        }
        that.requestService.create(attrs).then(
          result => {
            that.callback(result)
          },
          errors => {
            validationMessageView.show(errors)
          }
        )
        return false;
      }
    })
    .modal('show');
  }
}
