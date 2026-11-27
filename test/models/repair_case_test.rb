require "test_helper"

class RepairCaseTest < ActiveSupport::TestCase
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

  def nuevo_caso(**cambios)
    RepairCase.new({
      client: users(:cliente), company: companies(:tecnifrio), appliance_type: appliance_types(:lavadora),
      city: cities(:quito), falla: "La lavadora no centrifuga y hace ruido.", direccion: "Av. Amazonas 123"
    }.merge(cambios))
  end

  test "un caso completo es válido y nace como solicitado" do
    caso = nuevo_caso
    assert caso.valid?, caso.errors.full_messages.to_sentence
    assert_equal "solicitada", caso.status
  end

  test "exige descripción de al menos 10 caracteres y dirección" do
    caso = nuevo_caso(falla: "corta", direccion: "")
    assert_not caso.valid?
    assert caso.errors[:falla].any?
    assert caso.errors[:direccion].any?
  end

  test "solo un usuario con rol cliente puede pedir un servicio" do
    assert_not nuevo_caso(client: users(:tecnico)).valid?
  end

  test "la empresa debe estar activa" do
    caso = nuevo_caso(company: companies(:hogarfix), city: cities(:guayaquil))
    assert_not caso.valid?
    assert_includes caso.errors[:company], "no está activa"
  end

  test "la empresa debe atender en la ciudad del servicio" do
    caso = nuevo_caso(city: cities(:cuenca))
    assert_not caso.valid?
    assert_includes caso.errors[:company], "no atiende en la ciudad seleccionada"
  end

  test "la empresa debe reparar ese electrodoméstico" do
    caso = nuevo_caso(appliance_type: appliance_types(:secadora))
    assert_not caso.valid?
    assert_includes caso.errors[:appliance_type], "no es reparado por la empresa elegida"
  end

  test "el técnico asignado debe pertenecer a la empresa del caso" do
    assert nuevo_caso(technician: users(:tecnico)).valid?
    assert_not nuevo_caso(technician: users(:cliente)).valid?
  end

  test "solo se cancela una solicitud todavía no iniciada" do
    assert repair_cases(:solicitada).cancelar!
    assert_equal "cancelada", repair_cases(:solicitada).reload.status

    assert_not repair_cases(:en_reparacion).cancelar!
    assert_equal "en_reparacion", repair_cases(:en_reparacion).reload.status
  end

  test "la empresa acepta, asigna y rechaza según el estado" do
    caso = repair_cases(:solicitada)
    assert caso.aceptable?
    assert_not caso.asignable?
    assert_not caso.asignar!(users(:tecnico)), "no se asigna antes de aceptar"

    assert caso.aceptar!
    assert_not caso.aceptar!, "no se acepta dos veces"
    assert_not caso.rechazar!("tarde"), "una aceptada ya no se rechaza"

    assert caso.asignar!(users(:tecnico))
    assert_equal "asignada", caso.status
    assert caso.asignar!(users(:tecnico_carlos)), "se puede reasignar"
  end

  test "rechazar exige motivo y lo guarda" do
    caso = repair_cases(:solicitada)
    assert_not caso.rechazar!("   ")
    assert_equal "solicitada", caso.reload.status

    assert caso.rechazar!("No cubrimos esa zona")
    assert_equal "rechazada", caso.status
    assert_equal "No cubrimos esa zona", caso.motivo_rechazo
  end

  test "desde asignada siempre hay un técnico responsable" do
    caso = repair_cases(:en_reparacion)
    caso.technician = nil
    assert_not caso.valid?
  end

  test "el feedback solo existe en casos resueltos" do
    caso = repair_cases(:solicitada)
    caso.calificacion = 4
    assert_not caso.valid?
  end

  test "calificar un caso resuelto guarda el feedback y actualiza la reputación de la empresa" do
    caso = repair_cases(:resuelta_sin_calificar)
    assert caso.puede_calificar?

    assert caso.calificar!(4, "Muy puntual")
    caso.reload
    assert_equal 4, caso.calificacion
    assert_equal "Muy puntual", caso.comentario_feedback
    assert_not_nil caso.feedback_at

    empresa = companies(:tecnifrio).reload
    assert_equal 1, empresa.reviews_count
    assert_equal 4.0, empresa.rating_promedio.to_f
  end

  test "no se puede calificar dos veces ni con una nota fuera de 1 a 5" do
    caso = repair_cases(:resuelta_sin_calificar)
    assert_not caso.calificar!(9, nil)
    assert caso.reload.puede_calificar?

    assert caso.calificar!(5, nil)
    assert_not caso.calificar!(1, "otra vez")
    assert_equal 5, caso.reload.calificacion
  end

  test "admite evidencias en imagen pero rechaza otros archivos" do
    caso = nuevo_caso
    caso.evidencias.attach(io: StringIO.new(PNG), filename: "dano.png", content_type: "image/png")
    assert caso.valid?, caso.errors.full_messages.to_sentence

    caso.evidencias.attach(io: StringIO.new("%PDF-1.4"), filename: "factura.pdf", content_type: "application/pdf")
    assert_not caso.valid?
    assert caso.errors[:evidencias].any?
  end

  test "máximo cuatro evidencias" do
    caso = nuevo_caso
    5.times { |i| caso.evidencias.attach(io: StringIO.new(PNG), filename: "dano#{i}.png", content_type: "image/png") }
    assert_not caso.valid?
  end

  test "no se puede borrar un cliente ni una empresa con casos (integridad referencial)" do
    assert_not users(:cliente).destroy
    assert_not companies(:tecnifrio).destroy
  end
end
