document.addEventListener('DOMContentLoaded', () => {
	setFormatAttr = function(formTag, format) {
		formTag.setAttribute("action", formTag.getAttribute("action").replace( /\.\w+/, "" ) + "." + format);
	};

  let	formTag = document.querySelector("form");
  let formatTag = formTag.querySelector('select[name="report[format]"]');
  formatTag.addEventListener('change', (event) => {
    format = event.target.value;
    setFormatAttr(formTag, format);
    formTag.querySelectorAll('.format-properties').forEach((elem) => {
      elem.hidden = true;
    })
    formTag.querySelectorAll(`.${format}-properties`).forEach((elem) => {
      elem.hidden = false;
    })
  });
  formatTag.dispatchEvent(new Event("change"));
});
