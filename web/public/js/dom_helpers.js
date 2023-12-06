export class DomHelpers {
  static hideAll(selector, scope = document) {
    scope.querySelectorAll(selector).forEach((elem) => {
      elem.hidden = true;
    })
  }

  static showAll(selector, scope = document) {
    scope.querySelectorAll(selector).forEach((elem) => {
      elem.hidden = false;
    })
  }

  static setHref(selector, href, scope = document) {
    scope.querySelector(selector).setAttribute('href', href);
  }

  static setText(selector, text, scope = document) {
    scope.querySelector(selector).textContent = text;
  }

  static buildFromTemplate(templateId, scope = document) {
    return scope.getElementById(templateId).content.cloneNode(true);
  }

  static getTemplate(templateId, scope = document) {
    return scope.getElementById(templateId).content.cloneNode(true);
  }
}
