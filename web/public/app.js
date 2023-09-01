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
      not_gt: "Weight needs to be greater than 0",
    },
  }
}

class UrlBuilder {
  static superId(id, name) {
    return `${id}-${this.parameterize(name)}`
  }

  static parameterize(name) {
    return name.replace(/\W/g, '-').replace(/\s+/, '-')
  }

  static project(projectId, { projectName = null } = {}) {
    return `/projects/${this.superId(projectId, projectName)}`
  }

  static projectOccurrences(projectId, { projectName = null, sectionId = null, sampleId = null, countingId = null } = {}) {
    let details = []
    if(countingId) {
      details.push(`counting=${countingId}`)
    }
    if(sectionId) {
      details.push(`section=${sectionId}`)
    }
    if(sampleId) {
      details.push(`sample=${sampleId}`)
    }
    let basePath = `${this.project(projectId, { projectName: projectName })}/occurrences`

    if(details.length == 0) {
      return basePath
    } else {
      return `${basePath}?${details.join('&')}`
    }
  }

  static projectReports(projectId, { projectName = null, countingId = null, sectionId = null } = {}) {
    let details = []
    if(countingId) {
      details.push(`counting=${countingId}`)
    }
    if(sectionId) {
      details.push(`section=${sectionId}`)
    }
    let basePath = `${this.project(projectId, { projectName: projectName })}/reports`

    if(details.length == 0) {
      return basePath
    } else {
      return `${basePath}?${details.join('&')}`
    }
  }
}

class DomHelpers {
  static hideAll(selector) {
    document.querySelectorAll(selector).forEach((elem) => {
      elem.hidden = true
    })
  }

  static setHref(selector, href) {
    document.querySelector(selector).setAttribute('href', href)
  }

  static setText(selector, text) {
    document.querySelector(selector).textContent = text
  }
}

class ModelRequest {
  constructor(path) {
    this.path = path;
  }

  get(id) {
    var url = `${this.path}/${id}`;

    return new Promise((resolve, reject) => {
      $.ajax({
        url: url,
        type: 'GET',
        dataType: "json",
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(xhr.responseJSON.errors);
      })
    })
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

class ModalFormView {
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

  show() {
    this.hideErrors()
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
            that.showErrors(errors)
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
