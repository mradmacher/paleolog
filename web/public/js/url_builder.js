export class UrlBuilder {
  static superId(id, name) {
    return `${id}-${this.parameterize(name)}`
  }

  static parameterize(name) {
    return name.replace(/\W/g, '-').replace(/\s+/, '-')
  }

  static project(projectId, { projectName = null } = {}) {
    return `/projects/${this.superId(projectId, projectName)}`
  }

  static species(speciesId, { projectId = null } = {}) {
    const speciesPath = `/species/${speciesId}`;
    if (projectId) {
      return `/projects/${projectId}/${speciesPath}`;
    } else {
      return speciesPath;
    }
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
