class ModelRequest {
  constructor(path) {
    this.path = path;
  }

  pathWithId(id) {
    return `${this.path}/${id}`;
  }

  get(id) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: this.pathWithId(id),
        type: 'GET',
        dataType: 'json',
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(xhr.responseJSON.errors);
      })
    })
  }

  remove(id) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: this.pathWithId(id),
        type: 'DELETE',
        dataType: 'json',
      })
      .done(function(json) {
        resolve(json);
      }).fail(function(xhr, status, error) {
        reject(xhr.responseJSON.errors);
      })
    })
  }

  index(attrs) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: this.path,
        data: attrs,
        type: 'GET',
        dataType: 'json',
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
      url = this.pathWithId(id)
      type = 'PATCH'
    } else {
      url = this.path
      type = 'POST'
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

export class SpeciesRequest extends ModelRequest {
  constructor() {
    super('/api/species');
  }
}

export class ProjectRequest extends ModelRequest {
  constructor() {
    super('/api/projects');
  }
}

export class SectionRequest extends ModelRequest {
  constructor() {
    super('/api/sections');
  }
}

export class CountingRequest extends ModelRequest {
  constructor() {
    super('/api/countings');
  }
}

export class SampleRequest extends ModelRequest {
  constructor() {
    super('/api/samples');
  }
}

export class OccurrenceRequest extends ModelRequest {
  constructor(projectId) {
    super(`/api/projects/${projectId}/occurrences`);
  }
}
