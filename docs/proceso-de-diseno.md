# Proceso de diseño del dominio `distribuidora-limpieza`

## 1. Escenario y objetivo

Elegí modelar una distribuidora de insumos de limpieza porque es una operación
real con reglas concretas que un planificador debe respetar:

- Solo se surte lo que un cliente pidió.
- Los químicos peligrosos (cloro, sosa cáustica, ácido muriático) no pueden
  viajar en cualquier vehículo: el transporte de materiales peligrosos exige un
  vehículo autorizado y rotulado con los carteles de seguridad.
- Los camiones se mueven por rutas concretas de la zona metropolitana.
- Los clientes institucionales (hospitales, restaurantes) compran producto a
  granel en bidones retornables, que la distribuidora recoge vacíos para
  rellenarlos.

El objetivo era un dominio donde el plan no fuera una simple secuencia de
"cargar, mover, descargar": el planificador tiene que preparar recursos,
respetar el orden entre etapas y planear el regreso.

## 2. Inspiración

- **Air Cargo** (Russell & Norvig, visto en clase): predicados `At`, `In`, y
  acciones `Load`, `Unload`, `Fly`.
- **Logistics** (IPC): paquetes, camiones dentro de ciudades y aviones entre
  ciudades.

Tomé de ellos la idea base de un vehículo que transporta objetos entre
ubicaciones. Todo lo demás lo diseñé a partir de cómo opera una distribuidora.

## 3. Del esquema inicial al esquema final

### Iteración 1: punto de partida

Empecé con el esquema más simple posible, parecido a Air Cargo:

```
cargar(producto, camion, lugar)     conducir(camion, origen, destino)
descargar(producto, camion, lugar)
```

Al escribir un problema de prueba encontré tres problemas que no reflejaban la
realidad:

1. `descargar` permitía dejar un producto **en cualquier lugar**. Un pedido
   descargado en el cliente equivocado no es una entrega.
2. `conducir` permitía ir **de cualquier ubicación a cualquier otra**, sin
   considerar la red de calles.
3. El producto aparecía "listo para cargar". En un CEDIS real primero se
   **surte** (se toma de la estantería y se lleva al andén).

### Iteración 2: entregas con destino y red de rutas

- Reemplacé `descargar` por **`entregar`**. Exige el predicado estático
  `destino ?p ?cl` y produce `entregado ?p`. La meta deja de ser "el producto
  está en X" y pasa a ser "el pedido fue entregado". Además, un producto
  entregado ya no puede volver a cargarse: sale del problema.
- Agregué el predicado estático **`ruta ?origen ?destino`** como precondición de
  `conducir`. Las rutas son dirigidas, por eso en el problema se declaran ambos
  sentidos.

### Iteración 3: ciclo de vida del producto en el CEDIS

Dividí la posición del producto en etapas: `en-almacen` → `en-anden` →
`a-bordo` → `entregado`. Para eso agregué la acción **`surtir`**.

La primera versión de `surtir` solo pedía `en-almacen`. La cambié para que
también exija `destino ?p ?cl` (un parámetro adicional `?cl`), y así modelar el
**surtido contra pedido**. Para comprobarlo, el problema incluye ácido
muriático en almacén sin pedido: el planificador nunca lo mueve.

### Iteración 4: materiales peligrosos

Fue la decisión de diseño más importante. Consideré dos alternativas:

| Alternativa | Problema |
|-------------|----------|
| Una sola acción `cargar` con un predicado estático `puede-transportar ?c ?p` | Hay que listar en el estado inicial todos los pares camión-producto, y no modela el paso operativo de preparar el vehículo |
| **Subtipos de producto + dos acciones de carga + acción de preparación** | Es la opción elegida |

Diseño final:

- Tipos `producto-general` y `producto-peligroso`, ambos subtipos de `producto`.
  `surtir` y `entregar` siguen aceptando cualquier producto, pero la carga se
  distingue por tipo.
- `autorizado-mat-peligrosos ?c` es **estático**: es un permiso del vehículo y
  ninguna acción lo cambia.
- `rotulado ?c` es **dinámico**: colocar los carteles es un paso que se realiza
  en el CEDIS (`rotular-camion`) y que exige la autorización.
- `cargar-peligroso` exige `rotulado`. `cargar-general` no.

Separé la carga en dos acciones porque el dominio usa solo `:strips` y
`:typing`. Sin precondiciones negativas ni efectos condicionales, la forma
limpia de expresar "este tipo de producto tiene un requisito extra" es una
acción por tipo. Mantener esos requisitos garantiza que el dominio funcione con
todos los planificadores de editor.planning.domains.

### Iteración 5: envases retornables (logística inversa)

Los bidones vacíos los modelé como un **tipo propio `envase`**, no como un
`producto`. Así:

- No se pueden surtir ni "entregar".
- Tienen su propio par de acciones, `recoger-envases` (en un cliente) y
  `devolver-envases` (en un CEDIS).
- Usan predicados propios (`envase-en`, `envase-a-bordo`), porque su flujo es
  el inverso al del producto: del cliente hacia el CEDIS.

Esta meta obliga al planificador a planear el **viaje de regreso**, lo cual hace
el plan menos trivial.

### Ideas descartadas

- **Incompatibilidad química** (cloro y ácido muriático no deben viajar juntos):
  requiere precondiciones negativas o modelar compartimentos. La descarté para
  mantener la compatibilidad STRIPS.
- **Capacidad del camión**: requiere fluentes numéricos (`:numeric-fluents`),
  que no todos los planificadores soportan.
- **Cadena de frío**: la consideré en una primera versión con otro giro
  (alimentos), pero no aplica a insumos de limpieza. Su lugar lo tomó la
  restricción de materiales peligrosos.

## 4. Predicados finales y su justificación

| Predicado | Tipo | Por qué existe |
|-----------|------|----------------|
| `camion-en ?c ?u` | Dinámico | Posición del camión; precondición de casi todas las acciones |
| `ruta ?o ?d` | Estático | Red de calles; limita a dónde se puede conducir |
| `en-almacen ?p ?cd` | Dinámico | Producto en estantería, aún no surtido |
| `en-anden ?p ?cd` | Dinámico | Producto surtido y listo para cargar |
| `a-bordo ?p ?c` | Dinámico | Producto dentro de un camión |
| `entregado ?p` | Dinámico | Pedido cumplido; es lo que pide la meta |
| `destino ?p ?cl` | Estático | Pedido: qué cliente pidió cada producto |
| `autorizado-mat-peligrosos ?c` | Estático | Permiso del vehículo |
| `rotulado ?c` | Dinámico | Vehículo preparado para cargar peligrosos |
| `envase-en ?e ?u` | Dinámico | Ubicación de los bidones vacíos |
| `envase-a-bordo ?e ?c` | Dinámico | Bidones dentro del camión |

## 5. Acciones finales

| Acción | Precondiciones | Agrega | Elimina |
|--------|----------------|--------|---------|
| `surtir ?p ?cl ?cd` | `en-almacen ?p ?cd`, `destino ?p ?cl` | `en-anden ?p ?cd` | `en-almacen ?p ?cd` |
| `rotular-camion ?c ?cd` | `autorizado-mat-peligrosos ?c`, `camion-en ?c ?cd` | `rotulado ?c` | — |
| `cargar-general ?p ?c ?cd` | `en-anden ?p ?cd`, `camion-en ?c ?cd` | `a-bordo ?p ?c` | `en-anden ?p ?cd` |
| `cargar-peligroso ?p ?c ?cd` | `en-anden ?p ?cd`, `camion-en ?c ?cd`, `rotulado ?c` | `a-bordo ?p ?c` | `en-anden ?p ?cd` |
| `conducir ?c ?o ?d` | `camion-en ?c ?o`, `ruta ?o ?d` | `camion-en ?c ?d` | `camion-en ?c ?o` |
| `entregar ?p ?c ?cl` | `a-bordo ?p ?c`, `camion-en ?c ?cl`, `destino ?p ?cl` | `entregado ?p` | `a-bordo ?p ?c` |
| `recoger-envases ?e ?c ?cl` | `envase-en ?e ?cl`, `camion-en ?c ?cl` | `envase-a-bordo ?e ?c` | `envase-en ?e ?cl` |
| `devolver-envases ?e ?c ?cd` | `envase-a-bordo ?e ?c`, `camion-en ?c ?cd` | `envase-en ?e ?cd` | `envase-a-bordo ?e ?c` |

`rotular-camion` no elimina nada a propósito: una vez colocados, los rótulos
permanecen durante toda la operación del problema.

## 6. Diferencias con los dominios de inspiración

| Aspecto | Air Cargo / Logistics | `distribuidora-limpieza` |
|---------|-----------------------|--------------------------|
| Estado del objeto | Solo su ubicación (`At` / `In`) | Ciclo de vida: almacén → andén → a bordo → entregado |
| Descarga | En cualquier ubicación | Solo en el cliente que lo pidió (`destino`) |
| Meta | Objeto en una ubicación | Pedido `entregado` (estado, no lugar) |
| Movimiento | Cualquier par de aeropuertos / ciudades | Red de rutas explícita (`ruta`) |
| Tipos de carga | Toda la carga es igual | Subtipos con requisitos distintos (general / peligroso) |
| Preparación de recursos | No existe | `rotular-camion`, condicionado a un permiso estático |
| Vehículos | Todos equivalentes | Flota heterogénea: no todos pueden llevar todo |
| Flujo | Solo de ida | Logística inversa con envases retornables |
| Selección de objetos | Todo se mueve | Surtido contra pedido: el inventario sin pedido no se toca |

## 7. Validación

- Dominio y problema verificados con dos parsers distintos: `pyperplan` y la
  biblioteca `unified-planning`.
- Plan óptimo de 15 pasos, encontrado con búsqueda en amplitud y validado como
  `VALID` por el validador de planes secuenciales de `unified-planning`.
- Pruebas de las restricciones:
  - Sin `autorizado-mat-peligrosos` para `camion-01`, el problema **no tiene
    solución** (ningún vehículo puede llevar el cloro).
  - Sin rutas de regreso al CEDIS, el problema **no tiene solución** (los
    bidones no pueden volver).
