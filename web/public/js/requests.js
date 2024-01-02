class ModelRequest {
  constructor(path) {
    this.path = path;
  }

  pathWithId(id) {
    return `${this.path}/${id}`;
  }

  get(id) {
    return new Promise((resolve, reject) => {
      fetch(this.pathWithId(id), {
        method: 'GET',
      }).then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    });
  }

  remove(id) {
    return new Promise((resolve, reject) => {
      fetch(this.pathWithId(id), {
        method: 'DELETE',
      }).then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    })
  }

  index(attrs) {
    const searchParams = new URLSearchParams(attrs);

    return new Promise((resolve, reject) => {
      fetch(`${this.path}?${searchParams}`, {
        method: 'GET',
      }).then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    })
  }

  save(attrs) {
    let {id, ...params} = attrs;
    let url;
    let method;
    if (id) {
      url = this.pathWithId(id)
      method = 'PATCH'
    } else {
      url = this.path
      method = 'POST'
    }
    const formData = new FormData();
    for (const key in params) {
      formData.append(key, params[key]);
    }

    return new Promise((resolve, reject) => {
      fetch(url, {
        method: method,
        body: formData,
      }).then(response => {
        response.json().then((json) => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
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

  sections(projectId) {
    return new Promise((resolve, reject) => {
      fetch(`${this.pathWithId(projectId)}/sections`, {
        method: 'GET',
      }).then(response => {
        response.json().then(json => {
          if (response.ok) {
            resolve(json);
          } else {
            reject(json.errors);
          }
        })
      })
    });
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
