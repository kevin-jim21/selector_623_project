# Resumen

En principio, se desea desarrollar una aplicación para una máquina que tenga la capacidad de estimar la longitud de las barras de aluminio bruto producidas por una empresa siderúrgica y a su vez, poder demarcar las barras que cumplen con los parámetros de longitud adecuados. Para ello se utiliza la tarjeta Dragon 12+, empleando los interruptores, los botones, el teclado matricial, los LEDs, los displays de 7 segmentos y la pantalla LCD para crear una interfaz humano máquina que pueda ser utilizada por un operario de la empresa para cumplir esta tarea.

La solución propuesta consta de tres modos de operación. En primer lugar, el modo Stop consiste en un estado en donde la máquina está encendida pero no se realiza ninguna funcionalidad. El modo Configurar posee la funcionalidad de seleccionar la longitud mínima aceptada para las barras de aluminio utilizando el teclado matricial. Por otra parte, el modo Seleccionar es el que posee la funcionalidad de medir la longitud de las barras de aluminio y marcarlas o deshecharlas de acuerdo a si cumplen o no los parámetros establecidos. 

Esto es posible a partir de dos sensores que emiten un pulso al detectar o dejar de detectar una barra que viaja por una cinta y también, un roceador que se encarga de marcar en su centro longitudinal las barras que cumplen los parámetros establecidos. Cabe destacar que esta máquina cuenta con un rango de velocidad establecido en donde según sus especificaciones, la velocidad a la que viaja la barra por la cinta no puede ser menor a 10 cm/s ni mayor a 50cm/s. En el modo de operación Seleccionar el operario podrá conocer la velocidad a la que viaja la barra, la longitud de la barra y en caso de que la barra no cumpla con los parámetros adecuados, recibirá un parámetro de alerta para que retire la barra manualmente de la cinta.

Implementando la arquitectura de software descrita en las instrucciones fue posible elaborar esta solución y simular el funcionamiento de esta máquina en un ambiente industrial, procurando desarrollar una aplicación eficiente y funcional para dicho contexto. Además, se aplicaron las pruebas necesarias para determinar que las estimaciones realizadas por el Selector 612 concuerdan con lo esperado.

# Diseño de la aplicación
## Memoria de Cálculo

Para desarrollar esta aplicación se emplea una máquina de tiempos manejada por la interrupción output compare, se establece una frecuencia de interrupción de 50 kHz y se utiliza el canal 4. Debido a esto, se cuenta con un tiempo de output compare $T_{OC} = 20\mu s $, un bus clock $Bus_{clk} = 24 MHz$ y además se establece un valor de preescala $PRS = 4$, utilizando la ecuación 1 es posible obtener el valor $TCn$.

$TCn = \frac{Toc \cdot Bus_{clk}}{PRS} = \frac{20\mu s \cdot 24Mhz}{4} = 120$       [1]

A partir de los valores anteriores, es posible configurar los registros del módulo Timer para utilizar la interrupción de output compare según lo solicitado.

Para la Tarea\_Brillo se utiliza el potenciómetro ubicado en PAD7 para modificar el brillo de los LEDs y los displays de 7 segmentos; para ello se utiliza el módulo ATD; programando 4 conversiones en el mismo canal, 2 períodos de reloj para el muestreo, 8 bits sin signo y frecuencia de muestreo de 700 kHz. La ecuación 2 permite obtener el valor del prescalador a configurar en el módulo ATD de acuerdo a la frecuencia de muestreo deseada.

$PRS = \frac{Bus_{Clk}}{2f} - 1 = \frac{24MHz}{2 \cdot 700kHz} - 1 = 16,14$     [2]

Este valor se redondea a 16 y se establece en la configuración de registros del módulo ATD, así como los demás requerimentos mencionados en el párrafo anterior. Para esta tarea también es necesario realizar una progresión lineal que permita transformar la lectura del canal ATD a un valor en la escala de la variable Brillo, para el código del Selector 623. Tomando en cuenta que la letura del PAD7 utiliza 8 bits sin signo, se puede determinar que el valor recibido se encuentra en el rango (0, 255), mientras que la variable brillo debe estar en el rango de valores (0, 100). Dicho esto, es necesario después de obtener el promedio de las 4 lecturas del canal, dividir el resultado por el factor $\frac{255}{100} \approx 3$. En la ecuación 3 es posible visualizar la progresión lineal descrita anteriormente, misma que será ejecutada en el estado 3 de Tarea\_Brillo.

$Brillo = \frac{prom(ARD00-03H)}{3}$        [3]

Por último, la subrutina Calcula emplea una serie de operaciones para determinar los valores de las variables Longitud, Velocidad, DeltaT (recalculado), TimerPant, TimerFinPant y TimerRociador. Para calcular la Velocidad se divide el valor DeltaX\_S entre DeltaT; no obstante, como DeltaT está expresado en décimas de segundo es necesario multiplicar el numerador de la fraccion. La ecuación 4 muestra la operación descrita anteriormente para calcular la velocidad a la que viaja la barra.

$Velocidad = \frac{DeltaX\_S \cdot 10}{DeltaT}$     [4]

Posteriormente, es necesario obtener un nuevo cálculo de DeltaT, que represente el tiempo transcurrido entre la detección del incio de la barra por S2 y la detección del final de la barra por este mismo sensor. Para ello, se toma el valor de 100 (valor incial de TimerCal), se le resta el valor actual de TimerCal para obtener el valor transcurrido desde la detección de S1 y por último, se resta el DeltaT original para descontar el tiempo de duración entre la detección de S1 y la primera detección de S2. Dicha operación es representada en la ecuación 5.

$DeltaT = 100 - TimerCal - Delta T$     [5]

Para el valor Longitud se calcula el producto de DeltaT y Velocidad; pero como el valor de DeltaT está expresado en décimas de segundo, es necesario dividir por 10 para obtener el valor de Longitud en la unidad deseada. El cálculo de Longitud es descrito mediante la ecuación 6.

$Longitud = \frac{Velocidad \cdot DeltaT}{10}$      [6]

El valor de TimerPant describe en décimas de segundo, la duración de la llegada del inicio de la barra al rociador. Para el cálculo de TimerPant, se emplea la operación expresada en la ecuación 7.

$TimerPant = \frac{(10)(DeltaX\_R - Longitud)}{Velocidad}$      [7]

Por otro lado, el valor de TimerFinPant representa la duración en décimas de segundo de la llegada del final de la barra al rociador. Para obtener dicho cálculo, se utiliza la ecuación 8.

$TimerFinPant = \frac{(10)(DeltaX\_R)}{Velocidad}$      [8]

Finalmente, el valor de TimerRociador representa el tiempo en décimas de segundo, que toma el centro longitudinal de la barra para llegar al rociador; este timer determina el momento en que la barra es marcada. Para el cálculo de TimerRociador, se aplicó la ecuación 9.

$TimerRociador = \frac{(10)(DeltaX\_R - \frac{Longitud}{2})}{Velocidad}$      [9]

# Conclusiones y comentarios

Desarrollar un proyecto de este tipo resulta muy provechoso para el estudiante, ya que permite desarrollar sus conocimientos en programación de microcontroladores y a su vez, explorar el uso y funcionamiento de elementos electrónicos como lo son los convertidores analógicos/digitales, los displays de 7 segmentos y las pantallas LCD.
Este proyecto además busca enfrentar el estudiante ante problemas similares a los presentados en la industria; como es el caso del selector 623, que se desarrolla en un contexto empresarial en el cual se necesita una solución eficiente ante un problema de automatización y que a su vez, la aplicación pueda ser muy sencilla de utilizar para un operario.

Por otro lado, la asignación de hardware para este proyecto parece ser la idónea, se emplean la mayoría de elementos de la Dragon 12+ utilizados en tareas anteriores y además, se agregan otros elementos para poder experimentar un poco más con el hardware de la tarjeta. Si se pudiera implementar un cambio en particular con respecto a la aplicación desarrollada, se propondría utilizar aún más el teclado para esta aplicación, ya que los teclados matriciales en los sistemas incrustados suelen ser muchísimo muy relevantes en las aplicaciones donde se coloca.

En cuanto a la arquitectura de software solicitada para este proyecto, se cuenta con un diseño modular bastante ordenado, en donde se emplean bastantes subrutinas de propósitos lo suficientemente generales para ser útiles en otros proyectos desarrollados con el mismo hardware. Esto representa una gran ventaja para el programador, ya que en caso de tomar nuevos proyectos puede ocupar su tiempo mayormente en resolver los problemas que por la naturaleza del proyecto, este le presenta específicamente y de esta forma, ignorar problemas menores, como lo podría ser el desarrollar un algoritmo para leer el teclado matricial, o para pasar de números binarios a los valores de 7 segmentos para los displays.

En cuanto a la naturaleza del problema, a pesar de representar una solución muy interesante, es un poco difícil intentar resolver problemas que involucren cálculos con procesadores de punto fijo. A nivel industria en realidad sería mucho más óptimo utilizar procesadores de punto flotante para obtener resultados de mayor presición; no obstante, es comprensible que el ambiente académico implica bsucar resolver problemas a partir del hardware que se posee.

# Recomendaciones

- En primer lugar, esta no fue una dificultad personal pero resulta muy importante, antes de probar las tareas de los modos de operación principales del Selector 623, probar y asegurarse totalmente del correcto funcionamiento de las tareas que configuran los displays de 7 segmentos, la pantalla LCD, el teclado entre otros. De no ser así, esta aplicación puede resultar muy difícil de depurar.
- Particularmente, para este proyecto fue necesario al cambiar entre los modos de operación principales, colocar en el vector de estado el estado inicial de las tareas que no se estaban utilizando; es decir, al utilizar Configurar se devolvía la tarea Seleccionar al estado 1 y viceversa, ya que de no ser así, la pantalla LCD, los LEDs y los displays de 7 segmentos no reaccionarían correctamente al volver a esta tarea, ya que el diseño de estas máquinas de estado no está realizado para volver siempre al estado inicial.
- Estructurar lo mejor posible el código fuente de la solución del proyecto, ya que en este caso se cuenta con un proyecto bastante grande para un sólo archivo de código; entre mejor estructurado se encuentre el código va a ser más sencillo depurar y modificar ciertas cosas en el código para resolver problemas.