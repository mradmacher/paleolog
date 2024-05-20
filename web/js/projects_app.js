import { ProjectModalFormView } from './modal_form_views.js'

document.addEventListener('DOMContentLoaded', () => {
  const project = {
    name: null,
  }

  document.querySelector('.add-project.action').addEventListener('click', () => {
    new ProjectModalFormView(project, (project) => window.location.reload()).show();
  });
});
