globals[fileIndex fileMatrix numLines enerNums enerProm popNums popProm popPromExt particleNums particleNumsUp particleNumsDown particlePromUp particlePromDown enerOOB popOOB particleOOBUp particleOOBDown currentRql rqlStep truePos falsePos trueNeg falseNeg stableTick attackFoundTick frozenNodes itsHappening]
breed[particles particle] ; Partículas
breed[nodes node] ; Agentes
nodes-own[energy genes life ] ; Variables locales que tienen los agentes, energía y genes
particles-own[pNutri index]; Variables locales que tienen las partículas.
patches-own[numNodes]; Cada patch es un espacoi, sirve para saber cuantos agentes hay encima, esto sirve para dejar solo un agente por espacio.
; El padre para reproducirse le otorga una cierta cantidad de energía al hijo y además pierde una energía por reproducirse
to setup ; Se definen los valores d elas variables
  clear-all
  random-seed new-seed
  set currentRql irql ; current rql = irql, cuyo valor es el de reproducirse al principio.
  set stableTick 1000
  set rqlStep ((rql - irql) / stableTick); rqlStep es cuanto avanza el rql
  set fileIndex 0
  set fileMatrix (matrix fName)
  set enerNums n-values 500 [nodeInitialEnergy]
  set popNums n-values 500 [initialNodes]
  set particleNumsUp n-values 500 [0]
  set particleNumsDown n-values 500 [0]
  set enerProm nodeInitialEnergy
  set popProm initialNodes
  set popPromExt initialNodes
  set particlePromUp 0
  set particlePromDown 0
  set enerOOB n-values 70 [0]
  set popOOB n-values 100 [0]
  set particleOOBUp n-values 100 [0]
  set particleOOBDown n-values 100 [0]
  set truePos 0
  set falsePos 0
  set trueNeg 0
  set falseNeg 0
  set attackFoundTick []
  set frozenNodes []

  set itsHappening false
; Seteamos el color de fondo
  ask patches[set pcolor blue]
  ; Se configuran los nodos iniciales
  create-nodes initialNodes[ ; Crea una cantidad de nodos igual a la cantidad de nodos inicial
    set color green
    set life nodeInitialLife ; Tiempo de vida inicial de los agentes
    set energy nodeInitialEnergy
    set heading 90
    set shape "circle"
    setxy (round random-xcor) (round random-ycor)
    set genes [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32]
    set genes (shuffle genes)
  ]
  reset-ticks
  freeze ; Sirve para guardar la información
end

to go
  if ticks > numLines [ ; numLines corresponde al número de lineas del archivo.
    stop
  ]
  if (count nodes) = 0 [ ;Si mueren todos los nodos llamo a unfreeze para regresar a un estado anterior
    unfreeze
  ]
  if fileIndex < (numLines + 1)[
    random-seed new-seed
    if fileIndex < numLines[
      createParticle fileMatrix fileIndex ; Se crean las partículas  dada la matriz que es el contenido del archivo abierto y el índice en el que está corriendo el programa.
    ]
    ifelse ticks > stableTick [ ; Para controlar el límite de la energía de reproducción
      set currentRql rql
    ]
    [
      set currentRql (currentRql + rqlStep) ; Si no hemos llegado al límite entonces hacemos el seteo correspondiente
    ]
    newNormal ; Se llama a new Normal, definida más abajo, la cual tiene las reglas para analizar si hay un ataque.
    ask patches[ ; Por cada patch se llama a countNodes
      countNodes
    ]
    ask nodes[
      catch-particle; Se llama a catch-particle, función de cada agente para ver si una partícula le otorga o le quita energía
      set energy (energy - metabolism); Los agentes gastan energía para estar vivos, acá se setea la energía actual menos un parámetro definido, la cual se define como metabolismo.
      set life (life - 1); En cada tick los agentes pierden 1 de vida
      nodeDeath; Se verifica si el nodo debe morir o no
      makeNode; Se verifica si el nodo puede reproducirse
      nodeColor; Se setea el nodo a su color correspondiente
      penaltyNeighbors; Se llama a la función que penaliza al agente por vecino similar
    ]
    ask particles[
      particleMove ; Función que hace que las energías se muevan hacia la izquierda
      particleDeath ; Función que verifica si las energías deben morir
    ]
    set fileIndex (fileIndex + 1) ; Avanza una línea en el archivo input.
    tick ; Avanzamos un tick
  ]
end

to makeNode ; El agente puede tener hijos dependiendo su nivel de energía en donde estos hijos aparecerán aleatoreamente en su vecindad.
  let sumNeighbors (sum [numNodes] of neighbors4); Si el agente tiene 4 agentes vecinos entonces no debería poder reproducirse ya que no habría un partch disponible.
  if energy > currentRql [ ; La energía del agente debe ser mayor al parámetro currentRql para poder reproducrise.
    set energy (energy - birthEnergy - procEnergy)
    if sumNeighbors < 4 [
      hatch 1 [
        let rnd1 random 32
        let rnd2 random 32
        let aux1 (item rnd1 genes)
        let aux2 (item rnd2 genes)
          set genes replace-item rnd1 genes aux2
          set genes replace-item rnd2 genes aux1
        set energy birthEnergy
        set life childrenInitialLife
        downhill4 numNodes
      ]
    ]
  ]
end

to nodeDeath; Los agentes mueren si su energía es menor a 0 o si su vida ha terminado.
  if energy < 0 [die]
  if life < 0 [die]
end

to particleDeath ; Las partículas mueren si pNutri es menor a 0 (no usado en este modelo)
  if pNutri < 0 [die]
end

to particleMove ; Las partículas se mueven hacia la izquierda
  fd 1
  if xcor = 0 [die]
end

to nodeColor ; Se definen los colores verde, amarillo y rojo para cada agente dependiendo de la cantidad de energía que este tenga.
  if energy < currentRql [set color green]
  if energy < currentRql / 2 [set color yellow]
  if energy < currentRql / 4 [set color red] ;
end

to newNormal
  if (count nodes) > 0[
    let pos (ticks mod 500)
    let posSmall (ticks mod 100)
    let posEner (ticks mod 70)
    let posPart (ticks mod 100)
    let prom (sum [energy] of nodes) / (count nodes) ; Calcula todos los valores de los gráficos
    ifelse prom < enerProm [ ; Si la energía promedio actual es menor al promedio de las energía promedios (tendencia)
      set enerOOB (replace-item posEner enerOOB 1) ; enerOOB es una matriz que indica cuantas veces la energía promedio se ha salido de los límites de la tendencia. Si se pasó pone un 1 y si no, un 0
    ]
    [
      set enerOOB (replace-item posEner enerOOB 0)
    ]
    let enerOOBCount 0 ; Variable que indica cuantos 1 hay en el arreglo enerOOB. Se cuentan abajo.
    foreach enerOOB [[a] ->
      set enerOOBCount (enerOOBCount + a)
    ]
    set enerNums (replace-item pos enerNums prom); Es un arreglo que contiene los últimos 500 promedios de energía obtenidos
    set enerProm 0
    foreach enerNums [[a] ->
      set enerProm (enerProm + a)
    ]
    set prom (count nodes) ; Se ve la cantidad total de los agentes en los últimos 500 tics para poder obtener la tendencia.
    ifelse prom < popProm [
      set popOOB (replace-item posSmall popOOB 1)
    ]
    [
      set popOOB (replace-item posSmall popOOB 0)
    ]
    let popOOBCount 0
    foreach popOOB [[a] ->
      set popOOBCount (popOOBCount + a)
    ]
    set popNums (replace-item pos popNums prom)
    set popProm 0
    foreach popNums [[a] ->
      set popProm (popProm + a)
    ]; Hasta acá es gráfico de población


    set prom (count particles) ; Cuenta la cantidad de partículas
    ifelse prom > particlePromUp [ ; Dice si en este tic se salió del límite superior  (1 si se salió)
      set particleOOBUp (replace-item posPart particleOOBUp 1)
    ]
    [
      set particleOOBUp (replace-item posPart particleOOBUp 0)
    ]
    let particleOOBCountUp 0
    foreach particleOOBUp [[a] -> ; Cálculo de cuantas veces se salió del límite superior
      set particleOOBCountUp (particleOOBCountUp + a)
    ]
    set particleNumsUp (replace-item pos particleNumsUp prom)
    set particlePromUp 0
    foreach particleNumsUp [[a] ->; Cáulculo de cantidad de partículas en los últimos 500 tics
      set particlePromUp (particlePromUp + a)
    ]
    ; Se repite el procedimiento anterior pero para el límite inferior
    set prom (count particles)
    ifelse prom < particlePromDown [
      set particleOOBDown (replace-item posPart particleOOBDown 1)
    ]
    [
      set particleOOBDown (replace-item posPart particleOOBDown 0)
    ]
    let particleOOBCountDown 0
    foreach particleOOBDown [[a] ->
      set particleOOBCountDown (particleOOBCountDown + a)
    ]
    set particleNumsDown (replace-item pos particleNumsDown prom)
    set particlePromDown 0
    foreach particleNumsDown [[a] ->
      set particlePromDown (particlePromDown + a)
    ]





    if ticks > stableTick [
      ifelse popOOBCount = 100 or enerOOBCount = 70 or count nodes < popPromExt or particleOOBCountUp = 100 or particleOOBCountDown = 100[;Si la cantidad de agentes se pasa del límite durante 100 tics consecutivos o más entonces se sale del límite o
      ;si la energía se salió 70 veces de la tendencia
      ; o si las partículas se salieron hacia arriba o abajo en una cantidad de 100 veces o la cantidad de agentes es mejor al límite inferior extermo (cantidad mínima de agentes hasta ahora) entonces es un ataque
        if itsHappening = false[ ; Si el ataque no se había detectado, se congela la población y se detecta el ataque.
          freeze
          set itsHappening true
          set attackFoundTick lput ticks attackFoundTick ; Es el arreglo que contiene todos los tick en donde se detecto un ataque.
        ]
        ask patches[ ; Setear color naranjo si hay un ataque
          set pcolor orange
        ]
      ]

      [
        if itsHappening = true[ ; Si estamos en el fin del ataque entonces descongelamos la población, seteamos el ataque como falso y dejamos los patches de color azul
          unfreeze
          set itsHappening false
        ]
        ask patches[
          set pcolor blue
        ]
      ]
    ]
    ; Acá obtenemos los promedios para los gráficos y multiplicamos por los parámetros adecuados para que estos valores no sobrepasen los valores actuales.
    set enerProm (enerProm / 500) * 0.95
    set popProm (popProm / 500) * 0.97
    set popPromExt popProm * 0.6
    set particlePromUp (particlePromUp / 500) * 1.20
    set particlePromDown (particlePromDown / 500) * 0.80
  ]
end

to freeze ; Guarda el estado completo de la población
  set frozenNodes []
  ask nodes[
    set frozenNodes lput (list [energy] of self [genes] of self [xcor] of self [ycor] of self) frozenNodes
  ]
  show word "Frozen at " ticks
  let saveName word "imgs/freeze-" ticks
  set saveName word saveName ".png"
  ;export-view saveName
end

to unfreeze ; Reemplaza el estado de la población con la población guardada con freeze
  ask nodes[
    die
  ]
  foreach frozenNodes [ x ->
    create-nodes 1[
      set color green
      set energy item 0 x
      set heading 90
      set shape "circle"
      setxy item 2 x item 3 x
      set genes item 1 x
      set life 80
    ]
  ]
  show word "Unfrozen at " ticks
  let saveName word "imgs/unfreeze-" ticks
  set saveName word saveName ".png"
  ;export-view saveName
end

to countNodes ; Verifica que si hay dos agentes en el mismo espacio entonces se deja uno aleatoriamente
  set numNodes (count nodes-here)
  if numNodes > 1[
    let prey one-of nodes-here
    ask prey[
      die
    ]
  ]
end

to catch-particle ; Función que le indica a un agente si la partícula en su posición le dará energía o le quitará
  let prey  particles-here
  let energyAux energy
  let genesAux genes
  if any? prey [
    let gIndex -1
    ask prey [
      set gIndex index
      set pNutri (pNutri - 1)
      let pIndex (position gIndex genesAux)
      set energyAux (energyAux + (maxNutritionalVal - pIndex * linearNutriLoss)); Función que indica la energía final del agente

      ]
    set energy energyAux
  ]
end

to-report matrix [filename] ; Matriz que contiene los datos del archivo.
  File-open filename
  let results [[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]
  while [not file-at-end?][
    let row n-values 32 [file-read]
    set results (lput row results)
    set numLines (numLines + 1)
  ]
  File-close
  show numLines
  report results
end

to createParticle [ results fIndex] ; Función para crear partícula
  let i 1
  let aux1 (item fIndex results)
  foreach aux1 [a ->
    if a = 1[
      foreach [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24][x ->
      create-particles 1[
        set color red
        set pNutri 100
        set index i
        set shape "dot"
        set heading 270
        setxy max-pxcor (round x)
      ]]
    ]
    set i (i + 1)
  ]
  set i 1
end

to penaltyNeighbors ; Función que penaliza a los vecinos

  let genesAux genes



  ask nodes-on neighbors4 [

    (foreach genes genesAux [ [a b] ->
      if a = b [ set  energy (energy * 0.90 ) ] ; La penalización se hace por cada gen diferente que presente el agente con sus vecinos.
    ]   )

  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
248
65
581
399
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
24
0
24
0
0
1
ticks
30.0

BUTTON
84
48
147
81
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
48
78
81
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
635
10
1208
463
Nodes energy
Time
Energy
0.0
100.0
0.0
0.0
true
true
"" ""
PENS
"Energy" 1.0 0 -14439633 true "" "plot (sum [energy] of nodes) / ((count nodes) + 1)"
"EnergyLowerBound" 1.0 0 -5298144 true "" "plot enerProm"

PLOT
1209
10
1782
463
Population
Time
Population
0.0
100.0
0.0
0.0
true
true
"" ""
PENS
"Population" 1.0 0 -13345367 true "" "plot count nodes"
"LowerBound" 1.0 0 -7858858 true "" "plot popProm"
"ExtLowerBound" 1.0 0 -15575016 true "" "plot popPromExt"

MONITOR
211
438
344
483
Avg node energy
(sum [energy] of nodes) / (count nodes)
3
1
11

MONITOR
347
438
442
483
Population
count nodes
17
1
11

BUTTON
15
90
93
123
go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
449
439
623
499
fName
Dataset/outputDoS6
1
0
String

INPUTBOX
16
127
177
187
rql
210.0
1
0
Number

INPUTBOX
16
432
177
492
nodeInitialEnergy
160.0
1
0
Number

INPUTBOX
16
188
177
248
initialNodes
100.0
1
0
Number

INPUTBOX
16
249
177
309
birthEnergy
122.5
1
0
Number

MONITOR
211
486
344
531
NIL
enerProm
3
1
11

MONITOR
347
486
442
531
NIL
popProm
3
1
11

INPUTBOX
16
371
171
431
irql
100.0
1
0
Number

INPUTBOX
16
310
171
370
procEnergy
47.5
1
0
Number

MONITOR
211
532
281
577
Particles
count particles
17
1
11

INPUTBOX
16
493
177
553
metabolism
0.675
1
0
Number

INPUTBOX
16
554
177
614
maxNutritionalVal
90.0
1
0
Number

INPUTBOX
16
615
177
675
linearNutriLoss
7.15
1
0
Number

MONITOR
636
465
1208
510
attackFoundTick
attackFoundTick
0
1
11

BUTTON
1417
478
1480
511
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1481
478
1554
511
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1555
478
1647
511
go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
636
512
1208
890
Particles
Time
Particles
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Particles" 1.0 0 -13345367 true "" "plot (count particles)"
"LowerBound" 1.0 0 -7858858 true "" "plot particlePromDown"
"UpperBound" 1.0 0 -7858858 true "" "plot particlePromUp"

INPUTBOX
15
680
260
740
nodeInitialLife
100.0
1
0
Number

INPUTBOX
56
751
311
811
childrenInitialLife
0.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

Es una simulación de especies indicadoras artificiales, cuyo proposito es la detección de intrusos en el contexto de redes de computadoras. 

## HOW IT WORKS

El sistema recibe como input un tráfico de datos del cual se hará el análisis correspondiente. Luego de recibir el input correspondiente, se crean dos tipos de entidades. A continuación se dará una definición de cada entidad:

Partículas: 

	De cada paquete perteneciente al tráfico de datos que se desea analizar, se extrae la información necesaria para utilizar en el clasificador, como por ejemplo etiquetas syn o ack, en donde cada una será representada mediante una partícula. 

Agentes: 

	Son aquellos individuos que reaccionaran al tráfico de datos ( partículas).

	Cada agente posee un código genético representado por un arreglo de tamaño 32, en donde cada valor del arreglo se denomina gen, el cual puede tomar un valor en el rango de 1 a 32. 

	Los agentes son generados al comienzo del programa, en donde la distribución de sus genes será al azar y en donde estos no se puedan repetir dentro de un mismo individuo (agente).

	Cada agente en particular tiene una energía correspondiente, la cual varía dependiendo de ciertas reglas que van ocurriendo en cada iteración del programa (tic). 

	Estos agentes pueden vivir o morir de acuerdo a la cantidad de energía que posean, esta energía se verifica en cada Tic.

	Los agentes pueden crear nuevos agentes mediante la reproducción, esta se puede llevar a cabo dependiendo del nivel de energía de los agentes. 

	La energía de los agentes es variable y disminuye tras cada Tic. Si un agente se reproduce también pierde una cantidad de energía, definida previamente. 

	Los agentes se alimentan de las partículas y dependiendo de que tipo de partícula sea, estos agentes pueden ganar o perder energía. 

	Las partículas se mueven siempre hacia la izquierda, lo que permite que puedan interactuar con los agentes, los cuales son creados aleatoriamente al momento de la ejecucuión del programa.
 

Las reglas establecidas para que este sistema funcione son las siguientes: 

Para los agentes:

	Si la energía del agente es mayor a la energía necesaria para reproducirse y además si hay un espacio libre dentro de la vecindad del agente entonces el agente se reproduce. 

	Si la energía del agente es menor a 0 entonces el agente muere.

	En cada Tic los agentes pierden una cantidad m de energía. 

	Si un agente colisiona con una partícula esta le otorga o le quita un valor 			nutricional dada por la ecuación: 
		Valor nutricional= máximo valor nutricional asociado a las partículas- 				(posición de la partícula respecto al genotipo del individuo, es decir, 			la posición en que ese tipo de partícula se encuentra en el arreglo que 			representa al individuo y este valor se multiplica por el valor de la 				energía actual de esa partícula).  

Para las partículas:

	Se crean en el extremo derecho del mundo.

	Se mueven de un espacio a la vez por cada tic hacia la izquierda.

	El valor de la partícula es igual al valor que tiene el input en el instante que 
	la partícula fue creada

	Si la partícula sale del mundo, muere. 

	Si la partícula queda sin energía, muere.

	
Para detectar un ataque se ha creado un clasificador se calcula una tendencia dada una cantidad de iteraciones para:

	Cantidad de agentes.
	Cantidad de partículas.
	Promedio de energía

Estos valores representan una tendencia dada una cantidad de iteraciones, si el valor actual de uno de estos parámetros se sale de los límites establecidos durante un periodo de tiempo (cota mínima y cota máxima para las cantidades de agentes y partículas) entonces se detecta esa instancia como un ataque.
	
Para evitar que todos los agentes mueran se hará en ocasiones una captura del estado actual de los agentes, si todos los agentes mueren entonces se devuelve al último estado guardado. 

Para evitar que los agentes se adapten al ataque entonces se hará una captura del estado de los agentes al momento del ataque, de manera que al terminar el ataque, entonces los agentes volverán a su estado anterior.

	 





## HOW TO USE IT

Para correr el programa dentro de netlogo se debe seleccionar primero debemos escoger los parámetros adecuados o utilizar los parámetros por defecto, los cuales son:

rql: Es el valor final necesario para reproducción, es decir el valor límite.	
initialNodes: Agentes iniciales
birthEnergy: Energía necesaria para reproducirse con la que nacen los hijos.
ProcEnergy: Energía adicional para reproducirse
irql: Energía necesaria para reproducirse inicialmente.
metabolism: Costo de energía por cada tic para cada agente
nodeInitialEnergy: Energía inicial de los agentes
maxNutricionalVAl: Maximo valor de energía que puede dar una partícula
LinearNutriLoss: Es el factor que se multiplica por la posición del agente cuyo valor se 
		utiliza en la ecuación de energía al momento que un agente consume una 				partícula
 



## THINGS TO NOTICE

Se recomienda analizar los gráficos y ver como se comporta tanto la población como la energía en comparación a la tendencia y ver la diferencia en el comportamiento de los agentes (existencia de estos) cuando se presenta un posible ataque. 

## THINGS TO TRY

Se recomienda probar con diferentes parámetros ya que estos aunque son parámetros muy buenos, es muy probable que no sean los óptimos. Además se recomienda probar con diferentes input y diferente tipos de ataque. 

## EXTENDING THE MODEL

Aunque el sistema es un excelente sistema de detección de intrusos, queda abierto a una actualización para convertir el sistema de detección a uno de prevensión. 

## NETLOGO FEATURES

Utilizar desde la versión 6.0.1 en adelante


## CREDITS AND REFERENCES

Sistema desarrollado por Pedro Pinacho docente de la Universidad de Concepción y actualizado por Matías Lermanda, ingeiero civil informático de la Universidad de Concepción 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="SuperTest" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 1</exitCondition>
    <metric>item 1 attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="12000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="75"/>
      <value value="100"/>
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="36500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputProbe2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="75"/>
      <value value="100"/>
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="5.5"/>
      <value value="7"/>
      <value value="9.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SizeTest" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 1</exitCondition>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="4300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="305"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputDoS2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pxcor">
      <value value="7"/>
      <value value="9"/>
      <value value="15"/>
      <value value="19"/>
      <value value="24"/>
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pycor">
      <value value="7"/>
      <value value="9"/>
      <value value="15"/>
      <value value="19"/>
      <value value="24"/>
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SizePopTest" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 1</exitCondition>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="4300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
      <value value="125"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputDoS2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pxcor">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pycor">
      <value value="24"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SuperTest2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 1</exitCondition>
    <metric>item 1 attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="75"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="12000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="75"/>
      <value value="100"/>
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="36500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputProbe2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="75"/>
      <value value="100"/>
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="5.5"/>
      <value value="7"/>
      <value value="9.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pxcor">
      <value value="7"/>
      <value value="9"/>
      <value value="15"/>
      <value value="19"/>
      <value value="24"/>
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-pycor">
      <value value="7"/>
      <value value="9"/>
      <value value="15"/>
      <value value="19"/>
      <value value="24"/>
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="BenchmarkTest" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputNormal1&quot;"/>
      <value value="&quot;outputNormal2&quot;"/>
      <value value="&quot;outputNormal3&quot;"/>
      <value value="&quot;outputDoS1&quot;"/>
      <value value="&quot;outputDoS2&quot;"/>
      <value value="&quot;outputDoS3&quot;"/>
      <value value="&quot;outputDoS4&quot;"/>
      <value value="&quot;outputProbe1&quot;"/>
      <value value="&quot;outputProbe2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="InitialNodesTest-PostSize" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 1</exitCondition>
    <metric>item 1 attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputDoS2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="BenchmarkTestV2" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>truePos</metric>
    <metric>falsePos</metric>
    <metric>trueNeg</metric>
    <metric>falseNeg</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="5500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="32000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputDoS1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NormalRuns" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 0</exitCondition>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputNormal1&quot;"/>
      <value value="&quot;outputNormal2&quot;"/>
      <value value="&quot;outputNormal3&quot;"/>
      <value value="&quot;outputNormal4&quot;"/>
      <value value="&quot;outputNormal5&quot;"/>
      <value value="&quot;outputNormal6&quot;"/>
      <value value="&quot;outputNormal7&quot;"/>
      <value value="&quot;outputNormal8&quot;"/>
      <value value="&quot;outputNormal9&quot;"/>
      <value value="&quot;outputNormal10&quot;"/>
      <value value="&quot;outputNormal11&quot;"/>
      <value value="&quot;outputNormal12&quot;"/>
      <value value="&quot;outputNormal13&quot;"/>
      <value value="&quot;outputNormal14&quot;"/>
      <value value="&quot;outputNormal15&quot;"/>
      <value value="&quot;outputNormal16&quot;"/>
      <value value="&quot;outputNormal17&quot;"/>
      <value value="&quot;outputNormal18&quot;"/>
      <value value="&quot;outputNormal19&quot;"/>
      <value value="&quot;outputNormal20&quot;"/>
      <value value="&quot;outputNormal21&quot;"/>
      <value value="&quot;outputNormal22&quot;"/>
      <value value="&quot;outputNormal23&quot;"/>
      <value value="&quot;outputNormal24&quot;"/>
      <value value="&quot;outputNormal25&quot;"/>
      <value value="&quot;outputNormal26&quot;"/>
      <value value="&quot;outputNormal27&quot;"/>
      <value value="&quot;outputNormal28&quot;"/>
      <value value="&quot;outputNormal29&quot;"/>
      <value value="&quot;outputNormal30&quot;"/>
      <value value="&quot;outputNormal31&quot;"/>
      <value value="&quot;outputNormal32&quot;"/>
      <value value="&quot;outputNormal33&quot;"/>
      <value value="&quot;outputNormal34&quot;"/>
      <value value="&quot;outputNormal35&quot;"/>
      <value value="&quot;outputNormal36&quot;"/>
      <value value="&quot;outputNormal37&quot;"/>
      <value value="&quot;outputNormal38&quot;"/>
      <value value="&quot;outputNormal39&quot;"/>
      <value value="&quot;outputNormal40&quot;"/>
      <value value="&quot;outputNormal41&quot;"/>
      <value value="&quot;outputNormal42&quot;"/>
      <value value="&quot;outputNormal43&quot;"/>
      <value value="&quot;outputNormal44&quot;"/>
      <value value="&quot;outputNormal45&quot;"/>
      <value value="&quot;outputNormal46&quot;"/>
      <value value="&quot;outputNormal47&quot;"/>
      <value value="&quot;outputNormal48&quot;"/>
      <value value="&quot;outputNormal49&quot;"/>
      <value value="&quot;outputNormal50&quot;"/>
      <value value="&quot;outputNormal51&quot;"/>
      <value value="&quot;outputNormal52&quot;"/>
      <value value="&quot;outputNormal53&quot;"/>
      <value value="&quot;outputNormal54&quot;"/>
      <value value="&quot;outputNormal55&quot;"/>
      <value value="&quot;outputNormal56&quot;"/>
      <value value="&quot;outputNormal57&quot;"/>
      <value value="&quot;outputNormal58&quot;"/>
      <value value="&quot;outputNormal59&quot;"/>
      <value value="&quot;outputNormal60&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="AtkRunsNotBase" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 0</exitCondition>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputDoS1&quot;"/>
      <value value="&quot;outputDoS2&quot;"/>
      <value value="&quot;outputDoS3&quot;"/>
      <value value="&quot;outputDoS4&quot;"/>
      <value value="&quot;outputDoS5&quot;"/>
      <value value="&quot;outputDoS6&quot;"/>
      <value value="&quot;outputDoS7&quot;"/>
      <value value="&quot;outputDoS8&quot;"/>
      <value value="&quot;outputDoS9&quot;"/>
      <value value="&quot;outputDoS10&quot;"/>
      <value value="&quot;outputProbe1&quot;"/>
      <value value="&quot;outputProbe2&quot;"/>
      <value value="&quot;outputProbe3&quot;"/>
      <value value="&quot;outputProbe4&quot;"/>
      <value value="&quot;outputProbe5&quot;"/>
      <value value="&quot;outputProbe6&quot;"/>
      <value value="&quot;outputProbe7&quot;"/>
      <value value="&quot;outputProbe8&quot;"/>
      <value value="&quot;outputProbe9&quot;"/>
      <value value="&quot;outputProbe10&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="AtkRunsNotBaseMITM" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>length attackFoundTick &gt; 0</exitCondition>
    <metric>attackFoundTick</metric>
    <enumeratedValueSet variable="rql">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialNodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackStart">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birthEnergy">
      <value value="122.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attackEnd">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="procEnergy">
      <value value="47.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fName">
      <value value="&quot;outputMITM1&quot;"/>
      <value value="&quot;outputMITM2&quot;"/>
      <value value="&quot;outputMITM3&quot;"/>
      <value value="&quot;outputMITM4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolism">
      <value value="0.675"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="linearNutriLoss">
      <value value="7.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="irql">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nodeInitialEnergy">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxNutritionalVal">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
