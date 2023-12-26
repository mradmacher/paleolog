import test from 'ava';
import { JSDOM } from 'jsdom';
import { DomHelpers } from '../../../web/public/js/dom_helpers.js';

test('#setHref adds href attribute with given url', t => {
  const html =
    `
      <div>
       <a class="i-need-href"></a>
      </div>
    `
  const document = new JSDOM(html).window.document;
  let actual;

  actual = document.querySelector(".i-need-href").getAttribute("href");
  t.deepEqual(actual, null);

  const expected = "/path/to/resource";
  DomHelpers.setHref(".i-need-href", expected, document);
  actual = document.querySelector(".i-need-href").getAttribute("href");
  t.deepEqual(actual, expected);
});

test('#setText adds text context to element', t => {
  const html =
    `
      <div>
       <p class="i-need-text"></p>
      </div>
    `
  const document = new JSDOM(html).window.document;
  let actual;

  actual = document.querySelector(".i-need-text").textContent;
  t.deepEqual(actual, '');

  const expected = "Here I am";
  DomHelpers.setText(".i-need-text", expected, document);
  actual = document.querySelector(".i-need-text").textContent;
  t.deepEqual(actual, expected);
});
