
globals [dead-trees saved-trees fires-left-in-sim]
breed [ units ]
breed [ trees ]
breed [ fires ]
breed [ fires-out ]

patches-own [ signal ]
units-own [water]

to setupSimulationEnvironment
  clear-all
  ask patches [set signal 0]
  set fires-left-in-sim number-of-fires
  set dead-trees 0
  set saved-trees 0
  start-signal
  create-base
  create-boundary
  setup-trees
  setup-units

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  display-water-units

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  reset-ticks
end

;;; Create the base for refueling/water supplies
;;; Simply ask the specific patch to change color
to create-base
  ask patch 0 0 [set pcolor red]
end

;;; Create a boundary for the world, which the agents treat as an obstacle.
to create-boundary
  ask patches[
  if  abs pxcor = max-pxcor or abs pycor = max-pycor
      [set pcolor blue]
  ]
end


;;; start signaling. The signal is a property of the patch (patch variable)
;;; Its value is proportional to its distance from base (patch 0 0)
to start-signal
  ask patches [set signal distancexy-nowrap 0 0]
end


;;;;;;;;;;;;; Setting up the various "agents" in the environment
;;; setting up trees
to setup-trees
   create-trees tree-num [
      set shape "tree"
      rand-xy-co
      set color green
      ]
end

;;; setting up units
;;; creates the units that detect and extinguish fires
to setup-units
   create-units fire-units-num [
      set shape "fire-unit"
      set color blue
      set water initial-water
      rand-xy-co-near-base
   ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Running the experiment until no more fires are left for simulation and
;;; no more fires are still burning.
;;; Asks the units to execute behaviour and asks fire to spread
to run-experiment
  if fires-left-in-sim <= 0 and not any? fires [stop]
  start-fire-probability
  ask units [without-interruption [execute-behaviour]]
  ask fires [without-interruption [fire-model-behaviour]]

  ;Edited Code
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  tick

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end

;;; starts randonly a fire according to a probability (10%)
;;; This give a model in which fire spots start at different execution times
to start-fire-probability
if not any? trees [set fires-left-in-sim 0 stop]
if fires-left-in-sim > 0
  [
  let p random 100
  if p < 10 and any? trees [
    ask one-of trees [ignite]
    set fires-left-in-sim fires-left-in-sim - 1]
    ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; how fire spreads
;;; Fire burns for a certain period after which thre "tree" on fire dies
;;; the time is indicated by the color of the patch, that fades in each cycle.
;;; After a number of cycles, when its color is near to black, the tree dies.
to fire-model-behaviour
 without-interruption [
 if any? trees-on neighbors [ask one-of trees-on neighbors [ ignite ]]
 set color color - 0.01
 if color < red - 4 [set dead-trees dead-trees + 1  die]
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; starts a fire in a tree location
to ignite
  set breed fires
  set shape "tree"
  set color red
end

;;; fire in a tree location is extinguished.
to extinguish
  set breed fires-out
  set shape "tree"
  set color yellow
end










;;;;;;;;;;;;;;;;;;;;;;;;; THE AGENT ;;;;;;;
;;; Agent has sensors, effectors (actions) and a behaviour (reactive)
;;; This procedure determines the agent's behaviour, encoded as reactive rules.
to execute-behaviour

   ; Prioritises the action to "put-out-fire", when the agent detects a fire
   ; and the amount of water that they carry is not empty.
   if detect-fire and have-water [put-out-fire stop]

   ; If the fire unit used all of the water supplies that they could carry and
   ; the location of the fire unit is at the base station then the action "service-unit" gets executed,
   ; which means that the fire-unit is refilled with water.
   ; If the fire unit needs water but is not at the base station yet, it executes the action "move-towards-base"
   ; which sends signal of the location of the base station and makes the fire unit to move there.
   if need-water [
     ifelse at-base [service-unit stop]
     [move-towards-base stop]
   ]

   ; In the case where the fire unit passes from the base station, and
   ; their water capacity is not full (less than the initial water capacity),
   ; then the "service-unit" action gets executed which refills the water tank
   ; of the fire unit.
   if at-base and water < initial-water [service-unit stop]

   ; If the fire unit detects obstacle in their way while moving then
   ; it will try to avoid it, by turning randomly.
   if detect-obstacle [avoid-obstacle stop]

   ; Updates the water units of each agent, in case they have used water,
   ; or they have refilled their tank.
   display-water-units

   ; Makes the agent to move to a random direction,
   ; first it moves and then it turns randomly.
   if true [move-randomly stop]


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



   ;while [detect-fire and have-water]
    ;  [put-out-fire
     ;  move-randomly]

   ;if need-water [
    ; ifelse at-base
     ;  [service-unit stop]
      ; [move-towards-base stop]
   ;]

;   if at-base and water < initial-water
 ;    [service-unit stop]
  ; display-water-units
   ;move-randomly stop


   ;if true [move-randomly stop]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; If the "show-water-units" is enabled then
; the amount of water that each fire unit carries
; is visible.
to display-water-units
  ask units [ set label "" ]
  if show-water-units? [
    ask units [ set label water ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sensors

;; Detecting obstacles in front of the unit.
;; Obstacles are fire and other units, and the edges of the world (the boundary, patches with blue colour).
;; The agent can move through trees.
to-report detect-obstacle
ifelse any? fires in-cone 2 60 or any? other units in-cone 2 60 or [pcolor] of patch-ahead 1 = blue [report true][report false]
end

;;; detects a fire in the neighborhood of the unit (8 patches areound unit)
to-report detect-fire
  ifelse any? fires-on neighbors
    [report true]
    [report false]
end


;;; reports that the unit is at the base (patch with color red)
to-report at-base
  ifelse [pcolor] of patch-here = red
    [report true]
    [report false]
end

;;; reports that the unit has water
to-report have-water
  ifelse water > 0
    [report true]
    [report false]
end

;;; reports (returns true) that the unit needs water supplies
to-report need-water
  ifelse water = 0
    [set color grey report true]
    [report false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Actions
;;; Puts out a fire in the neighborhood. However since there can be multiple fires
;;; one of the eight possible fires is put out. In each operation it consumes one unit of water.
to put-out-fire
      ask one-of fires-on neighbors [extinguish]
      set water water - 1
      set saved-trees saved-trees + 1
end

;;;; Actions that move the agent around.
;;; Turning randomly to avod an obstacle
to avoid-obstacle
  set heading heading + random 360
end

;; moving towards the base by following the signal. First move and then turn
;; towards the base.
to move-towards-base
  move-ahead
  face min-one-of neighbors [signal]
end

;; moving randomly. First move then turn
to move-randomly
  move-ahead
  turn-randomly
end

;; Moves ahead the agent. Its speed is inversly proportional to the water it is carrying.
to move-ahead
  fd 1 - (water / (initial-water + 5))
end

;;; Turns the unit at a random direction
to turn-randomly
  set heading heading + random 30 - random 30
end

;;; service unit action is used for "recharging" the unit with water.
to service-unit
   set water initial-water
   set color blue
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Utilities
to rand-xy-co
  let x 0
  let y 0
  loop [
    set x random-pxcor
    set y random-pycor
    if not any? turtles-on patch x y and not (abs x < 4 and abs y < 4) and not (abs x = max-pxcor) and not (abs y = max-pycor) [setxy x y stop]
  ]
end

to rand-xy-co-near-base
  let x 0
  let y 0
    loop [
    set x random-pxcor
    set y random-pycor
    if not any? turtles-on patch x y and (abs x < 4 and abs y < 4) [setxy x y stop]
  ]
end


;;; Reporter that counts the number of trees (unaffected) left.
to-report trees-left
  report count trees
end
