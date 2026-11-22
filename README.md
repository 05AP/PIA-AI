# PIA-AI

PIA - Inteligencia Artificial - Alan Emiliano Palomo Plata - 2048459

## Planificación automatizada con PDDL: distribuidora de insumos de limpieza

Dominio y problema en PDDL que modelan la operación de surtido y reparto de una
distribuidora de insumos de limpieza con un centro de distribución (CEDIS) en
Apodaca, N.L. El planificador debe decidir cómo surtir los pedidos, preparar la
flota, respetar las reglas de transporte de materiales peligrosos, entregar a
cada cliente lo que pidió y regresar los bidones vacíos al CEDIS.

| Elemento     | Cantidad |
|--------------|----------|
| Tipos        | 8 (con jerarquía) |
| Predicados   | 11 |
| Acciones     | 8 |
| Plan óptimo  | 15 pasos |

## Estructura del repositorio

```
.
├── domain.pddl                  # Dominio: tipos, predicados y acciones
├── problem.pddl                 # Problema: objetos, estado inicial y meta
└── docs/
    └── proceso-de-diseno.md     # Proceso de diseño y diferencias con dominios de inspiración
```

## Escenario del problema

- **CEDIS Apodaca**: tiene en almacén cloro, jabón para manos, desengrasante y
  ácido muriático. El ácido muriático no tiene pedido, así que no se debe mover.
- **Hospital en San Nicolás**: pidió cloro (peligroso) y jabón para manos, y
  tiene bidones vacíos por devolver.
- **Restaurante en Guadalupe**: pidió desengrasante industrial.
- **Flota**: `camion-01` (autorizado para materiales peligrosos, aún sin
  rotular) y `camioneta-02` (no autorizada).
- **Rutas**: CEDIS ↔ Hospital, Hospital ↔ Restaurante, Restaurante ↔ CEDIS.

**Meta:** los tres pedidos entregados y los bidones de vuelta en el CEDIS.

## Cómo ejecutarlo

### editor.planning.domains

1. Abrir <https://editor.planning.domains>.
2. Cargar `domain.pddl` y `problem.pddl` (*File → Load* o pegar el contenido).
3. Presionar **Solve**, seleccionar el dominio y el problema, y ejecutar.

### Local (opcional)

```bash
pip install pyperplan
pyperplan -s bfs domain.pddl problem.pddl   # búsqueda en amplitud: plan óptimo
```

El plan queda en `problem.pddl.soln`.

## Plan encontrado

Plan óptimo de 15 pasos (búsqueda en amplitud):

```
 1. (surtir cloro-hospital hospital-san-nicolas cedis-apodaca)
 2. (surtir jabon-hospital hospital-san-nicolas cedis-apodaca)
 3. (surtir desengrasante-restaurante restaurante-guadalupe cedis-apodaca)
 4. (rotular-camion camion-01 cedis-apodaca)
 5. (cargar-general desengrasante-restaurante camion-01 cedis-apodaca)
 6. (cargar-general jabon-hospital camion-01 cedis-apodaca)
 7. (cargar-peligroso cloro-hospital camion-01 cedis-apodaca)
 8. (conducir camion-01 cedis-apodaca restaurante-guadalupe)
 9. (entregar desengrasante-restaurante camion-01 restaurante-guadalupe)
10. (conducir camion-01 restaurante-guadalupe hospital-san-nicolas)
11. (entregar cloro-hospital camion-01 hospital-san-nicolas)
12. (entregar jabon-hospital camion-01 hospital-san-nicolas)
13. (recoger-envases bidones-hospital camion-01 hospital-san-nicolas)
14. (conducir camion-01 hospital-san-nicolas cedis-apodaca)
15. (devolver-envases bidones-hospital camion-01 cedis-apodaca)
```

### Explicación paso a paso

| # | Acción | Precondiciones que satisface | Contribución a la meta |
|---|--------|------------------------------|------------------------|
| 1 | `surtir` cloro | `en-almacen` cloro en el CEDIS (inicial) y `destino` cloro → hospital (inicial) | Pasa el cloro al andén; habilita el paso 7 |
| 2 | `surtir` jabón | `en-almacen` y `destino` jabón → hospital (inicial) | Pasa el jabón al andén; habilita el paso 6 |
| 3 | `surtir` desengrasante | `en-almacen` y `destino` desengrasante → restaurante (inicial) | Pasa el desengrasante al andén; habilita el paso 5 |
| 4 | `rotular-camion` camion-01 | `autorizado-mat-peligrosos` camion-01 y `camion-en` CEDIS (inicial) | Agrega `rotulado`, requisito para cargar el cloro |
| 5 | `cargar-general` desengrasante | `en-anden` (paso 3) y `camion-en` CEDIS | El desengrasante queda `a-bordo` |
| 6 | `cargar-general` jabón | `en-anden` (paso 2) y `camion-en` CEDIS | El jabón queda `a-bordo` |
| 7 | `cargar-peligroso` cloro | `en-anden` (paso 1), `camion-en` CEDIS y `rotulado` (paso 4) | El cloro queda `a-bordo` |
| 8 | `conducir` CEDIS → restaurante | `camion-en` CEDIS y `ruta` CEDIS → restaurante | El camión llega al restaurante |
| 9 | `entregar` desengrasante | `a-bordo` (paso 5), `camion-en` restaurante (paso 8), `destino` → restaurante | **Meta:** `entregado` desengrasante |
| 10 | `conducir` restaurante → hospital | `camion-en` restaurante y `ruta` restaurante → hospital | El camión llega al hospital |
| 11 | `entregar` cloro | `a-bordo` (paso 7), `camion-en` hospital (paso 10), `destino` → hospital | **Meta:** `entregado` cloro |
| 12 | `entregar` jabón | `a-bordo` (paso 6), `camion-en` hospital, `destino` → hospital | **Meta:** `entregado` jabón |
| 13 | `recoger-envases` bidones | `envase-en` hospital (inicial) y `camion-en` hospital | Los bidones quedan `envase-a-bordo` |
| 14 | `conducir` hospital → CEDIS | `camion-en` hospital y `ruta` hospital → CEDIS | El camión regresa al CEDIS |
| 15 | `devolver-envases` bidones | `envase-a-bordo` (paso 13) y `camion-en` CEDIS (paso 14) | **Meta:** `envase-en` bidones CEDIS |

**Por qué el plan es correcto:**

- `camioneta-02` no puede transportar el cloro. `cargar-peligroso` exige
  `rotulado`, y `rotular-camion` exige `autorizado-mat-peligrosos`, que solo
  tiene `camion-01`.
- El ácido muriático nunca se surte porque no tiene un `destino`.
- El camión debe regresar al CEDIS: la meta de los bidones solo se cumple con
  `devolver-envases`, que exige `camion-en` el CEDIS.

### Planes alternativos

El problema admite más de un plan válido. Hay otros planes óptimos de 15 pasos:
por ejemplo, visitar primero el hospital, o que `camioneta-02` entregue el
desengrasante mientras `camion-01` atiende al hospital.

El planificador de editor.planning.domains no garantiza el plan más corto, sino
uno válido encontrado rápido. En una ejecución devolvió un plan válido de
**20 pasos**:

- Usa `camioneta-02` para el desengrasante y `camion-01` para el cloro, porque
  solo ese vehículo se puede rotular.
- Incluye dos viajes de ida y vuelta sin carga que no aportan a la meta.

## Video

Enlace al video demostrativo: https://drive.google.com/file/d/1Kvq3JVnnK2mTBiYGffl_7sS_Pax1nkS8/view?usp=sharing

## Proceso de diseño

Ver [`docs/proceso-de-diseno.md`](docs/proceso-de-diseno.md).
