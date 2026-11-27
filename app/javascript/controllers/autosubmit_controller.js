import { Controller } from "@hotwired/stimulus"

// Envía el formulario en cuanto cambia un campo (p. ej. el filtro de mes del panel de la empresa).
//   <form data-controller="autosubmit"><select data-action="change->autosubmit#submit">
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
