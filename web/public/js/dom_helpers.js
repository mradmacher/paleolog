export class DomHelpers {
  static hideAll(selector, scope = document) {
    scope.querySelectorAll(selector).forEach((elem) => {
      elem.hidden = true
    })
  }

  static setHref(selector, href, scope = document) {
    scope.querySelector(selector).setAttribute('href', href)
  }

  static setText(selector, text, scope = document) {
    scope.querySelector(selector).textContent = text
  }

  static getTemplate(templateId) {
    return document.getElementById(templateId).content.cloneNode(true)
  }
}
