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

  static select(selector, scope = document) {
    scope.querySelector(element).classList.add('is-selected');
  }

  static unselect(element, scope = document) {
    scope.querySelector(element).classList.remove('is-selected');
  }

  static selectAll(selector, scope = document) {
    scope.querySelectorAll(selector).forEach((element) => {
      element.classList.add('is-selected')
    });
  }

  static unselectAll(selector, scope = document) {
    scope.querySelectorAll(selector).forEach((element) => {
      element.classList.remove('is-selected')
    });
  }

  static onDOMContentLoaded(scope, callback) {
    document.addEventListener("DOMContentLoaded", callback);
  }
}
