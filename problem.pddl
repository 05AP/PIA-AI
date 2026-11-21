;; =============================================================================
;; Problema: reparto-monterrey
;; Dominio : distribuidora-limpieza
;; Autor   : Alan Emiliano Palomo Plata (2048459)
;;
;; Escenario: la distribuidora opera un CEDIS en Apodaca y tiene pedidos de dos
;; clientes del area metropolitana de Monterrey:
;;
;;   * Hospital en San Nicolas : cloro (peligroso) y jabon para manos.
;;                               Ademas tiene bidones vacios para devolver.
;;   * Restaurante en Guadalupe: desengrasante industrial.
;;
;; Flota disponible en el CEDIS:
;;   * camion-01    : autorizado para materiales peligrosos (aun sin rotular).
;;   * camioneta-02 : reparto ligero, NO autorizada para materiales peligrosos.
;;
;; En el almacen tambien hay acido muriatico sin pedido; no debe moverse.
;;
;; Meta: entregar los tres pedidos y regresar los bidones vacios al CEDIS.
;; =============================================================================

(define (problem reparto-monterrey)

  (:domain distribuidora-limpieza)

  (:objects
    cedis-apodaca                              - cedis
    hospital-san-nicolas restaurante-guadalupe - cliente

    camion-01 camioneta-02                     - camion

    cloro-hospital acido-muriatico             - producto-peligroso
    jabon-hospital desengrasante-restaurante   - producto-general

    bidones-hospital                           - envase
  )

  (:init
    ;; --- Red de rutas (tramos en ambos sentidos) -------------------------------
    (ruta cedis-apodaca        hospital-san-nicolas)
    (ruta hospital-san-nicolas cedis-apodaca)
    (ruta hospital-san-nicolas restaurante-guadalupe)
    (ruta restaurante-guadalupe hospital-san-nicolas)
    (ruta restaurante-guadalupe cedis-apodaca)
    (ruta cedis-apodaca        restaurante-guadalupe)

    ;; --- Flota -------------------------------------------------------------------
    (camion-en camion-01    cedis-apodaca)
    (camion-en camioneta-02 cedis-apodaca)
    (autorizado-mat-peligrosos camion-01)

    ;; --- Inventario en el CEDIS --------------------------------------------------
    (en-almacen cloro-hospital            cedis-apodaca)
    (en-almacen jabon-hospital            cedis-apodaca)
    (en-almacen desengrasante-restaurante cedis-apodaca)
    (en-almacen acido-muriatico           cedis-apodaca)

    ;; --- Pedidos -----------------------------------------------------------------
    (destino cloro-hospital            hospital-san-nicolas)
    (destino jabon-hospital            hospital-san-nicolas)
    (destino desengrasante-restaurante restaurante-guadalupe)

    ;; --- Envases retornables -----------------------------------------------------
    (envase-en bidones-hospital hospital-san-nicolas)
  )

  (:goal (and
    (entregado cloro-hospital)
    (entregado jabon-hospital)
    (entregado desengrasante-restaurante)
    (envase-en bidones-hospital cedis-apodaca)))
)
