import { ProjectModalFormView, CountingModalFormView, SectionModalFormView } from './modal_form_views.js'

document.addEventListener('DOMContentLoaded', () => {
  const projectId = document.getElementById("project-id").value;
  const projectName = document.getElementById("project-name").value;

  const section = {
    project_id: projectId,
    name: null,
  }

  const counting = {
    project_id: projectId,
    name: null,
  }

  const project = {
    id: projectId,
    name: projectName,
  }

  document.querySelector('.edit-project.action').addEventListener('click', () => {
    new ProjectModalFormView(project, (project) => window.location.reload()).show();
  });

  document.querySelector('.add-counting.action').addEventListener('click', () => {
    new CountingModalFormView(counting, (counting) => window.location.reload()).show();
  })

  document.querySelector('.add-section.action').addEventListener('click', () => {
    new SectionModalFormView(section, (section) => window.location.reload()).show();
  })
});
