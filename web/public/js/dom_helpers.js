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

  static setHref(href, selector, scope = document) {
    const element = scope.querySelector(selector);
    if (element) {
      element.setAttribute('href', href);
    }
  }

  static setAttr(attr, value, selector, scope = document) {
    const element = scope.querySelector(selector);
    if (element) {
      element.setAttribute(attr, value);
    }
  }

  static setText(text, selector, scope = document) {
    const element = scope.querySelector(selector);
    if (element) {
      element.textContent = text;
    }
  }

  static setValue(value, selector, scope = document) {
    const element = scope.querySelector(selector);
    if (element) {
      element.value = value;
    }
  }

  static buildFromTemplate(templateId, scope = document) {
    return scope.getElementById(templateId).content.cloneNode(true);
  }

  static getTemplate(templateId, scope = document) {
    return scope.getElementById(templateId).content.cloneNode(true);
  }
}
