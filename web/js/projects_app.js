import { ProjectModalFormView } from './modal_form_views.js'
import { ProjectRequest } from "./requests.js";
import { DomHelpers } from "./dom_helpers.js";
import { UrlBuilder } from "./url_builder.js";

document.addEventListener('DOMContentLoaded', () => {
  const project = {
    name: null,
  }

  document.querySelector('.add-project.action').addEventListener('click', () => {
    new ProjectModalFormView(project, (project) => window.location.reload()).show();
  });

  new ProjectRequest().index().then(
    result => {
      let projectsElement = document.querySelector('.projects tbody')
      let projects = result.projects;
      DomHelpers.setText(projects.length, '.projects-size');
      projects.forEach((project, i) => {
        let template = DomHelpers.getTemplate('project-template');
        DomHelpers.setText(project.name, '.project-name', template);
        DomHelpers.setHref(UrlBuilder.project(project.id, { projectName: project.name }), '.project-link', template);
        DomHelpers.setText(new Date(Date.parse(project.created_at)).toDateString(), '.project-date', template);
        projectsElement.append(template);
      });
    },
    errors => {
      console.log(errors)
    }
  )
});
