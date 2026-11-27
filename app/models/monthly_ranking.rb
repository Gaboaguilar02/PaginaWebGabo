# Ranking mensual de los técnicos de una empresa (el corazón del core de UFix).
#
# Reglas (cada empresa fija los dos requisitos; por defecto nota 4,2 y 20 casos):
# 1. PARTICIPA y puede cobrar bono solo el técnico que, en el mes, tiene
#    - calificación promedio >= company.min_calificacion (sobre los casos que sí fueron calificados), y
#    - casos resueltos >= company.min_casos_participar.
# 2. Entre quienes participan: más casos resueltos primero; si empatan, mejor calificación; si empatan en ambos, comparten posición.
# 3. Quien no cumple aparece al final, sin posición ni bono, con el motivo.
# 4. Cada participante cobra solo el escalón más alto que alcanzó: porcentaje de su sueldo base (los bonos no se acumulan).
# 5. Un caso cuenta en el mes en que se resolvió (resuelta_at), no en el que se pidió.
class MonthlyRanking
  Row = Struct.new(:posicion, :technician, :resueltos, :promedio, :calificados, :tier, :pago, :motivos, keyword_init: true) do
    def participa? = motivos.empty?
    def sueldo_base = technician.sueldo_base
    def tiene_sueldo? = sueldo_base.present?

    # Dinero del bono del mes: solo si participa, alcanzó un escalón y la empresa registró su sueldo base.
    def bono = participa? && tier ? tier.monto_para(sueldo_base) : 0
    def con_bono? = bono.positive?
    def pagado? = pago.present?

    # Participa y alcanzó un escalón, pero la empresa todavía no registró su sueldo base: no se puede calcular el bono.
    def falta_sueldo? = participa? && tier.present? && !tiene_sueldo?
  end

  attr_reader :company, :periodo

  def initialize(company, periodo = Date.current)
    @company = company
    @periodo = periodo.to_date.beginning_of_month
  end

  def cerrado?
    periodo < Date.current.beginning_of_month
  end

  def rango
    periodo.in_time_zone.beginning_of_day..periodo.end_of_month.in_time_zone.end_of_day
  end

  def filas
    @filas ||= construir
  end

  def participantes
    filas.select(&:participa?)
  end

  def no_participantes
    filas.reject(&:participa?)
  end

  def fila_de(technician)
    filas.find { |fila| fila.technician.id == technician.id }
  end

  def total_resueltos
    filas.sum(&:resueltos)
  end

  # Bonos que la empresa debe (o deberá) pagar este período según los escalones alcanzados.
  def total_bonos
    filas.sum(&:bono)
  end

  def total_pagado
    filas.select(&:pagado?).sum { |fila| fila.pago.monto }
  end

  def pendientes_de_pago
    filas.select { |fila| fila.con_bono? && !fila.pagado? }
  end

  # Calificación promedio de todos los casos calificados del período (nil si nadie calificó).
  def promedio_general
    resueltos_del_periodo.where.not(calificacion: nil).average(:calificacion)&.round(2)
  end

  # Texto de los motivos por los que alguien no participa (ver Row#motivos).
  def self.motivos_para(resueltos:, promedio:, company:)
    motivos = []
    if promedio.nil?
      motivos << "sin calificaciones de clientes"
    elsif promedio < company.min_calificacion
      motivos << "calificación #{format('%.2f', promedio).tr('.', ',')} menor a #{format('%.2f', company.min_calificacion).tr('.', ',')}"
    end
    motivos << "#{resueltos} de #{company.min_casos_participar} casos requeridos" if resueltos < company.min_casos_participar
    motivos
  end

  private

  def resueltos_del_periodo
    company.repair_cases.resueltos.where(resuelta_at: rango)
  end

  def construir
    conteos = resueltos_del_periodo.group(:technician_id).count
    promedios = resueltos_del_periodo.where.not(calificacion: nil).group(:technician_id).average(:calificacion)
    calificados = resueltos_del_periodo.where.not(calificacion: nil).group(:technician_id).count
    pagos = company.bonus_payments.where(periodo: periodo).index_by(&:technician_id)
    escalones = company.bonus_tiers.de_mayor_a_menor.to_a

    ids_con_casos = conteos.keys.compact
    tecnicos = company.users.where(role: "tecnico").where(activo: true).or(company.users.where(id: ids_con_casos)).to_a

    filas = tecnicos.map do |tecnico|
      resueltos = conteos.fetch(tecnico.id, 0)
      promedio = promedios[tecnico.id]&.to_f&.round(2)
      motivos = self.class.motivos_para(resueltos: resueltos, promedio: promedio, company: company)
      Row.new(technician: tecnico, resueltos: resueltos, promedio: promedio, calificados: calificados.fetch(tecnico.id, 0),
              motivos: motivos, pago: pagos[tecnico.id],
              tier: motivos.empty? ? escalones.find { |escalon| escalon.casos_minimos <= resueltos } : nil)
    end

    ordenar_y_posicionar(filas)
  end

  # Participantes primero (con posición); después los que no cumplen requisitos, sin posición.
  def ordenar_y_posicionar(filas)
    por_mejor = ->(fila) { [ -fila.resueltos, -(fila.promedio || 0), fila.technician.nombre_completo.to_s ] }
    participantes, fuera = filas.partition(&:participa?)

    anterior = nil
    posicion = 0
    ordenados = participantes.sort_by(&por_mejor)
    ordenados.each_with_index do |fila, indice|
      clave = [ fila.resueltos, fila.promedio ]
      posicion = indice + 1 unless clave == anterior
      fila.posicion = posicion
      anterior = clave
    end

    ordenados + fuera.sort_by(&por_mejor)
  end
end
