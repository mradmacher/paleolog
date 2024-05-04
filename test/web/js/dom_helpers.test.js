import test from 'ava';
import { JSDOM } from 'jsdom';
import { DomHelpers } from '../../../web/js/dom_helpers.js';

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
  DomHelpers.setHref(expected, ".i-need-href", document);
  actual = document.querySelector(".i-need-href").getAttribute("href");
  console.log(actual);
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
  DomHelpers.setText(expected, ".i-need-text", document);
  actual = document.querySelector(".i-need-text").textContent;
  t.deepEqual(actual, expected);
});
