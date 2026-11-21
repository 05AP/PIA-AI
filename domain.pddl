;; =============================================================================
;; Dominio : distribuidora-limpieza
;; Proyecto: PIA - Inteligencia Artificial - Planificacion automatizada con PDDL
;; Autor   : Alan Emiliano Palomo Plata (2048459)
;;
;; Modela la operacion de surtido y reparto de una distribuidora de insumos de
;; limpieza que opera desde un centro de distribucion (CEDIS):
;;
;;   * Los productos se surten contra pedido: del almacen pasan al anden de
;;     carga solo si existe un cliente que los pidio.
;;   * Los productos peligrosos (cloro, sosa caustica, etc.) solo se pueden
;;     cargar en un camion autorizado para materiales peligrosos y que ya tenga
;;     colocados los rotulos de seguridad.
;;   * Los camiones circulan por una red de rutas definida (no hay traslado
;;     directo entre cualquier par de ubicaciones).
;;   * Un producto solo se puede entregar en el cliente que lo pidio.
;;   * Los bidones vacios (envases retornables) se recogen en los clientes y se
;;     devuelven al CEDIS para su rellenado (logistica inversa).
;;
;; Requisitos: STRIPS + tipos, compatible con los planificadores de
;; editor.planning.domains.
;; =============================================================================

(define (domain distribuidora-limpieza)

  (:requirements :strips :typing)

  (:types
    ubicacion camion producto envase - object
    cedis cliente                    - ubicacion
    producto-general                 - producto
    producto-peligroso               - producto
  )

  (:predicates
    ;; --- Red de transporte ---------------------------------------------------
    (camion-en ?c - camion ?u - ubicacion)        ; posicion actual del camion
    (ruta ?origen - ubicacion ?destino - ubicacion) ; tramo transitable (estatico)

    ;; --- Ciclo de vida del producto -------------------------------------------
    (en-almacen ?p - producto ?cd - cedis)        ; en estanteria del CEDIS
    (en-anden ?p - producto ?cd - cedis)          ; surtido, listo para cargar
    (a-bordo ?p - producto ?c - camion)           ; dentro del camion
    (entregado ?p - producto)                     ; recibido por su cliente

    ;; --- Pedidos ---------------------------------------------------------------
    (destino ?p - producto ?cl - cliente)         ; cliente que pidio el producto (estatico)

    ;; --- Materiales peligrosos ---------------------------------------------------
    (autorizado-mat-peligrosos ?c - camion)       ; permiso del vehiculo (estatico)
    (rotulado ?c - camion)                        ; rotulos de seguridad colocados

    ;; --- Envases retornables -----------------------------------------------------
    (envase-en ?e - envase ?u - ubicacion)        ; bidones vacios en una ubicacion
    (envase-a-bordo ?e - envase ?c - camion)      ; bidones dentro del camion
  )

  ;; ---------------------------------------------------------------------------
  ;; surtir: el almacenista toma un producto de la estanteria y lo deja en el
  ;; anden de carga. Solo se surte lo que tiene un pedido (destino) asociado.
  ;; ---------------------------------------------------------------------------
  (:action surtir
    :parameters (?p - producto ?cl - cliente ?cd - cedis)
    :precondition (and
      (en-almacen ?p ?cd)
      (destino ?p ?cl))
    :effect (and
      (en-anden ?p ?cd)
      (not (en-almacen ?p ?cd))))

  ;; ---------------------------------------------------------------------------
  ;; rotular-camion: se colocan los rotulos de materiales peligrosos en un
  ;; camion autorizado. Se realiza en el CEDIS antes de cargar.
  ;; ---------------------------------------------------------------------------
  (:action rotular-camion
    :parameters (?c - camion ?cd - cedis)
    :precondition (and
      (autorizado-mat-peligrosos ?c)
      (camion-en ?c ?cd))
    :effect (rotulado ?c))

  ;; ---------------------------------------------------------------------------
  ;; cargar-general: sube al camion un producto de manejo general.
  ;; ---------------------------------------------------------------------------
  (:action cargar-general
    :parameters (?p - producto-general ?c - camion ?cd - cedis)
    :precondition (and
      (en-anden ?p ?cd)
      (camion-en ?c ?cd))
    :effect (and
      (a-bordo ?p ?c)
      (not (en-anden ?p ?cd))))

  ;; ---------------------------------------------------------------------------
  ;; cargar-peligroso: sube al camion un producto peligroso. Exige que el
  ;; camion este rotulado (y por lo tanto autorizado).
  ;; ---------------------------------------------------------------------------
  (:action cargar-peligroso
    :parameters (?p - producto-peligroso ?c - camion ?cd - cedis)
    :precondition (and
      (en-anden ?p ?cd)
      (camion-en ?c ?cd)
      (rotulado ?c))
    :effect (and
      (a-bordo ?p ?c)
      (not (en-anden ?p ?cd))))

  ;; ---------------------------------------------------------------------------
  ;; conducir: traslada el camion por un tramo existente de la red de rutas.
  ;; ---------------------------------------------------------------------------
  (:action conducir
    :parameters (?c - camion ?origen - ubicacion ?destino - ubicacion)
    :precondition (and
      (camion-en ?c ?origen)
      (ruta ?origen ?destino))
    :effect (and
      (camion-en ?c ?destino)
      (not (camion-en ?c ?origen))))

  ;; ---------------------------------------------------------------------------
  ;; entregar: el producto se entrega unicamente al cliente que lo pidio.
  ;; ---------------------------------------------------------------------------
  (:action entregar
    :parameters (?p - producto ?c - camion ?cl - cliente)
    :precondition (and
      (a-bordo ?p ?c)
      (camion-en ?c ?cl)
      (destino ?p ?cl))
    :effect (and
      (entregado ?p)
      (not (a-bordo ?p ?c))))

  ;; ---------------------------------------------------------------------------
  ;; recoger-envases: sube al camion los bidones vacios de un cliente.
  ;; ---------------------------------------------------------------------------
  (:action recoger-envases
    :parameters (?e - envase ?c - camion ?cl - cliente)
    :precondition (and
      (envase-en ?e ?cl)
      (camion-en ?c ?cl))
    :effect (and
      (envase-a-bordo ?e ?c)
      (not (envase-en ?e ?cl))))

  ;; ---------------------------------------------------------------------------
  ;; devolver-envases: descarga los bidones vacios en el CEDIS para rellenado.
  ;; ---------------------------------------------------------------------------
  (:action devolver-envases
    :parameters (?e - envase ?c - camion ?cd - cedis)
    :precondition (and
      (envase-a-bordo ?e ?c)
      (camion-en ?c ?cd))
    :effect (and
      (envase-en ?e ?cd)
      (not (envase-a-bordo ?e ?c))))
)
