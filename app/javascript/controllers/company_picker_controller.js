import { Controller } from "@hotwired/stimulus"

// Selector de empresa para la solicitud de servicio: cuando el cliente ya eligió
// electrodoméstico y ciudad, pide al servidor las empresas activas que lo pueden atender.
//
// Uso:
//   <div data-controller="company-picker" data-company-picker-url-value="/cliente/lookups/companies">
//     <select data-company-picker-target="appliance" data-action="change->company-picker#refresh">...</select>
//     <select data-company-picker-target="city"      data-action="change->company-picker#refresh">...</select>
//     <select data-company-picker-target="company">...</select>
//   </div>
export default class extends Controller {
  static targets = [ "appliance", "city", "company" ]
  static values = { url: String }

  // Al cambiar de provincia la ciudad se reinicia, así que la empresa también.
  reset() {
    this.#fill([], "Primero elige electrodoméstico y ciudad")
  }

  async refresh() {
    const applianceId = this.applianceTarget.value
    const cityId = this.cityTarget.value

    if (!applianceId || !cityId) return this.reset()

    this.#fill([], "Cargando...")
    try {
      const query = new URLSearchParams({ appliance_type_id: applianceId, city_id: cityId })
      const response = await fetch(`${this.urlValue}?${query}`, { headers: { Accept: "application/json" }, credentials: "same-origin" })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const empresas = await response.json()
      this.#fill(empresas, empresas.length ? "Elige una empresa" : "No hay empresas disponibles para ese servicio en esa ciudad")
    } catch (error) {
      console.error("No se pudieron cargar las empresas", error)
      this.#fill([], "No se pudieron cargar las empresas")
    }
  }

  #fill(empresas, placeholder) {
    this.companyTarget.replaceChildren(new Option(placeholder, ""))
    empresas.forEach((empresa) => this.companyTarget.append(new Option(empresa.nombre, empresa.id)))
    this.companyTarget.disabled = empresas.length === 0
  }
}
