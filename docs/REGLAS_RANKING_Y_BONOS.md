# Reglas del ranking mensual y de los bonos (core de UFix)

Este documento define, sin ambigüedad, quién participa en el ranking, cómo se ordena y cuánto dinero se lleva cada técnico.
El código que lo implementa está en `app/models/monthly_ranking.rb`, `bonus_tier.rb` y `bonus_payment.rb`.

## 1. Qué cuenta como caso

Un caso suma al ranking de un mes solo si:

- está en estado **resuelta** (el técnico lo cerró con un informe),
- pertenece a la empresa del técnico, y
- su **fecha de resolución** cae dentro de ese mes (no importa cuándo lo pidió el cliente).

Los casos cancelados, rechazados o en curso no suman.

## 2. Requisitos para participar y cobrar bono

Cada **empresa** configura dos requisitos (por defecto 4,2 y 20):

| Requisito | Valor por defecto | Se mide |
|---|---|---|
| Calificación promedio mínima | **4,2** | Promedio de los casos del mes que el cliente sí calificó |
| Casos resueltos mínimos al mes | **20** | Casos resueltos en el mes (≈ 1 por día hábil) |

- Se exigen **los dos** a la vez (≥, no >): con exactamente 4,2 de nota o 20 casos sí cumple.
- Si nadie calificó sus casos, la nota no se puede verificar y **no participa**.
- Quien no cumple aparece al final del ranking **sin posición ni bono**, con el motivo
  (por ejemplo: «calificación 3,88 menor a 4,20» o «12 de 20 casos requeridos»).

## 3. Cómo se ordena el ranking

Solo entre quienes participan:

1. Más casos resueltos en el mes.
2. Si empatan, mejor calificación promedio.
3. Si empatan en ambos, comparten posición.

La empresa ve tres tablas en su página de ranking:

| Tabla | Quiénes aparecen | Posición |
|---|---|---|
| **Ranking general** | Todos los técnicos, apliquen o no al bono | Posición general (mismo orden, sin exigir requisitos) |
| **Aplican al bono** | Solo quienes cumplen los dos requisitos | Posición del bono, con escalón, dinero y pago |
| **No aplican al bono** | Quienes incumplen uno o ambos requisitos | Sin posición; se muestra cada parámetro frente a lo exigido (por ejemplo «24 / 20 casos ✓» y «3,88 / 4,20 nota ✗») |

Un técnico puede ir primero en el ranking general (por ejemplo, el que más casos resolvió) y no aparecer en el del bono por su calificación.

## 4. Cuánto gana: escalones en porcentaje

La empresa define sus **escalones** (nombre, casos mínimos al mes y **porcentaje del sueldo base** del técnico).
Valores de referencia, pensando en que un técnico resuelve unos 2 a 3 casos por día hábil (45 a 55 al mes):

| Escalón | Casos al mes (mínimo) | Bono (% del sueldo base) | Con sueldo base $500 |
|---|---|---|---|
| Bronce | 30 | 5 % | $25 |
| Plata | 45 | 10 % | $50 |
| Oro | 60 | 15 % | $75 |

Reglas:

- Solo se paga **el escalón más alto alcanzado**; los bonos **no se acumulan**.
- Un escalón con más casos debe pagar un porcentaje **mayor** que los de menos casos (el sistema lo exige).
- **Bono = porcentaje del escalón × sueldo base del técnico.** Cada técnico tiene su sueldo base, que registra la empresa.
  Sin sueldo base registrado no se calcula el dinero ni se puede registrar el pago.

## 5. El pago

- El bono se registra **solo con el mes cerrado**: durante el mes aparece como «proyectado» porque aún pueden entrar casos.
- Hay **un solo pago por técnico y por mes**.
- UFix **no mueve dinero**: solo deja constancia de que la empresa pagó.
- El registro guarda una copia del cálculo (escalón, porcentaje, sueldo base, casos, calificación y monto),
  así que si la empresa cambia después sus reglas, el historial no se altera.

## 6. Ejemplo (datos de demostración de TecniFrío, octubre)

| Técnico | Casos | Nota | ¿Participa? | Escalón | Sueldo base | Bono |
|---|---|---|---|---|---|---|
| Juan Pérez | 52 | 4,63 | Sí (#1) | Plata (10 %) | $500 | **$50** (pagado) |
| Carlos Mena | 34 | 4,38 | Sí (#2) | Bronce (5 %) | $520 | **$26** (pendiente) |
| Lucía Vera | 24 | 3,88 | **No**: nota menor a 4,20 | — | $480 | $0 |

Lucía resolvió 24 casos (más que el mínimo), pero su calificación no llega a 4,2, así que queda fuera del ranking y sin bono.
