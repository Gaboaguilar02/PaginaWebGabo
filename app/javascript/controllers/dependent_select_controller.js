import { Controller } from "@hotwired/stimulus"

// Dropdown dependiente: al cambiar el <select> "padre" (p. ej. provincia),
// pide al servidor las opciones del <select> "hijo" (p. ej. ciudades).
//
// Uso:
//   <div data-controller="dependent-select"
//        data-dependent-select-url-value="/admin/lookups/cities"
//        data-dependent-select-query-key-value="province_id">
//     <select data-dependent-select-target="parent" data-action="change->dependent-select#change">...</select>
//     <select data-dependent-select-target="child">...</select>
//   </div>
export default class extends Controller {
  static targets = [ "parent", "child" ]
  static values = {
    url: String,
    queryKey: { type: String, default: "parent_id" },
    placeholder: { type: String, default: "Seleccione una ciudad" },
    emptyPlaceholder: { type: String, default: "Primero seleccione una provincia" }
  }

  async change() {
    const parentId = this.parentTarget.value
    this.#reset(parentId ? "Cargando..." : this.emptyPlaceholderValue)

    if (!parentId) {
      this.childTarget.disabled = true
      return
    }

    try {
      const url = `${this.urlValue}?${this.queryKeyValue}=${encodeURIComponent(parentId)}`
      const response = await fetch(url, { headers: { Accept: "application/json" }, credentials: "same-origin" })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const items = await response.json()
      this.#reset(items.length ? this.placeholderValue : "Esta provincia no tiene ciudades")
      items.forEach((item) => this.childTarget.append(new Option(item.nombre, item.id)))
      this.childTarget.disabled = items.length === 0
    } catch (error) {
      console.error("No se pudieron cargar las opciones", error)
      this.#reset("No se pudieron cargar las ciudades")
      this.childTarget.disabled = true
    }
  }

  #reset(placeholder) {
    this.childTarget.replaceChildren(new Option(placeholder, ""))
  }
}
