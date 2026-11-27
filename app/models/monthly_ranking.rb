# Ranking mensual de los técnicos de una empresa (el corazón del core de UFix).
#
# - Orden: más casos resueltos en el mes; si empatan, mejor calificación promedio de los clientes.
# - Cada técnico muestra el escalón de bono más alto que alcanzó (solo se paga ese, no se acumulan).
# - Un mes cuenta por la fecha en que el caso se resolvió (resuelta_at), no por la de creación.
class MonthlyRanking
  Row = Struct.new(:posicion, :technician, :resueltos, :promedio, :calificados, :tier, :pago, keyword_init: true) do
    def bono = tier ? tier.monto : 0
    def pagado? = pago.present?
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
    filas.select { |fila| fila.tier && !fila.pagado? }
  end

  # Calificación promedio de todos los casos resueltos del período (nil si nadie calificó).
  def promedio_general
    valores = resueltos_del_periodo.where.not(calificacion: nil)
    valores.average(:calificacion)&.round(2)
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
      Row.new(technician: tecnico, resueltos: resueltos,
              promedio: promedios[tecnico.id]&.to_f&.round(2), calificados: calificados.fetch(tecnico.id, 0),
              tier: escalones.find { |escalon| escalon.casos_minimos <= resueltos }, pago: pagos[tecnico.id])
    end

    ordenadas = filas.sort_by { |fila| [ -fila.resueltos, -(fila.promedio || 0), fila.technician.nombre_completo.to_s ] }
    asignar_posiciones(ordenadas)
  end

  # Ranking "de competencia": quien empata en casos y calificación comparte posición.
  def asignar_posiciones(ordenadas)
    anterior = nil
    posicion = 0
    ordenadas.each_with_index do |fila, indice|
      clave = [ fila.resueltos, fila.promedio ]
      posicion = indice + 1 unless clave == anterior
      fila.posicion = posicion
      anterior = clave
    end
  end
end
