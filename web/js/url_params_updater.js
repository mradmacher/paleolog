export class UrlParamsUpdater {
  constructor(path = window.location.pathname) {
    this.path = path;
  }

  setParams(attrs) {
    let searchParams = new URLSearchParams();
    let searchParamsProvided = false;
    for(let attr in attrs) {
      if(attrs[attr]) {
        searchParams.set(attr, attrs[attr]);
        searchParamsProvided = true;
      }
    }
    let newRelativePathQuery = this.path;
    if(searchParamsProvided) {
      newRelativePathQuery = newRelativePathQuery + '?' + searchParams.toString();
    }
    history.pushState(null, '', newRelativePathQuery);
  }
}
