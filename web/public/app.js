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
