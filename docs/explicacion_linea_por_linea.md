# Explicación detallada de `Papeleria.asm`

Este documento acompaña al programa [Papeleria.asm](../src/Papeleria.asm) y explica su funcionamiento a partir del código que realmente ejecuta. Sigue el orden del archivo fuente y utiliza sus números de línea (el archivo tiene 1417 líneas). Las líneas en blanco y los comentarios organizan o documentan el código, pero no generan instrucciones ejecutables.

La explicación cubre qué hace cada instrucción o grupo inmediato de instrucciones, por qué se eligió ese mecanismo, cómo se atienden los requisitos y qué límites conserva la solución. No pretende atribuirle funciones que no están implementadas.

## 1. Objetivo y recorrido general

El programa es una aplicación de consola de 32 bits escrita en MASM y apoyada en Irvine32. Mantiene un catálogo en memoria, permite registrar y buscar productos, recibir mercancía, vender, calcular un resumen y guardar/cargar el catálogo en un archivo de texto delimitado.

El flujo general es:

1. `principal` intenta cargar el catálogo.
2. Presenta el menú y despacha cada opción a un procedimiento.
3. Las entradas se capturan como cadenas; los procedimientos propios las validan y convierten.
4. Solo después de validar se modifica el arreglo de productos.
5. Las operaciones que cambian productos marcan `cambiosSinGuardar`.
6. Al salir, si hay cambios pendientes, se pregunta si deben guardarse.

La estructura de procedimientos separa la entrada/salida de consola, la validación, los cálculos, las operaciones de inventario y la persistencia. Esto ayuda a mantener la lógica comprensible pese a que el lenguaje no ofrece las abstracciones de un lenguaje de alto nivel.

## 2. Convenciones de ensamblador que aparecen en el archivo

- `EAX`, `EBX`, `ECX`, `EDX`, `ESI` y `EDI` son registros de 32 bits. Se usan para valores, contadores y direcciones.
- `AL` y `DL` son los 8 bits menos significativos de `EAX` y `EDX`; son útiles para caracteres y dígitos.
- `mov destino, origen` copia un valor; no convierte su tipo ni valida su contenido.
- `cmp A, B` actualiza las banderas como si restara `A-B`, pero no guarda el resultado. Las instrucciones `je`, `jne`, `jb`, `ja`, `jae`, `jns` y otras consultan esas banderas para decidir el salto.
- `add` y `sub` hacen aritmética de 32 bits y actualizan banderas. `jc` y `jnz` permiten detectar algunos desbordamientos.
- `mul` multiplica sin signo `EAX` por su operando y devuelve el producto de 64 bits en `EDX:EAX`. `div` divide el valor de `EDX:EAX`; el cociente queda en `EAX` y el residuo en `EDX`.
- `OFFSET` obtiene la dirección de una variable; `ADDR` permite pasar una dirección a `INVOKE`; `lea` calcula la dirección de un campo. `[registro + desplazamiento]` accede a memoria.
- Las cadenas de Irvine32 terminan con byte cero. `ReadString` recibe la dirección en `EDX`, el máximo en `ECX` y deja la longitud leída en `EAX`. `WriteString` imprime la cadena cuya dirección está en `EDX`.
- `PROC USES ...` hace que MASM preserve los registros listados; `LOCAL` reserva variables temporales en la pila; `INVOKE` prepara llamadas con argumentos conforme a la convención del proyecto. Así se evita administrar manualmente la pila con `PUSH`/`POP`.
- En un dato `BYTE`, cada carácter ocupa un byte. `DWORD` ocupa cuatro bytes y `QWORD` ocho. `DUP(0)` reserva y pone a cero un conjunto de bytes; `?` reserva espacio sin inicializarlo.

## 3. Encabezado, constantes y estructura (líneas 1–21)

- **Líneas 1–6:** comentarios de encabezado. Identifican el proyecto, curso y propósito; no cambian el estado del programa.
- **Línea 8 — `INCLUDE Irvine32.inc`:** importa declaraciones de Irvine32, incluidas las rutinas de consola y archivos usadas más adelante. La biblioteca evita tener que implementar desde cero esas operaciones de sistema.
- **Línea 10 — `MAX_PRODUCTOS = 10`:** límite del arreglo. Se usa tanto para reservar espacio como para rechazar registros adicionales.
- **Línea 11 — `LONGITUD_MAX_NOMBRE = 25`:** máximo de caracteres admitido para nombre.
- **Línea 12 — `LONGITUD_MAX_CODIGO = 8`:** tamaño del campo del código en memoria, incluyendo espacio para el terminador cero. El código visible tiene siete caracteres (`ABC-123`).
- **Línea 13 — `TAMANO_BUFFER_ARCHIVO = 4096`:** capacidad fija para leer un catálogo. El lector conserva un byte para terminar la cadena y rechaza una lectura que alcanza el límite, porque podría estar truncada.
- **Línea 14 — `EXISTENCIA_MAXIMA = 100`:** tope de stock por producto; se valida tanto al recibir mercancía como al cargar/registrar.
- **Línea 16 — `Producto STRUCT`:** inicia una estructura para que un producto tenga campos contiguos con offsets conocidos por MASM.
- **Línea 17 — `Codigo BYTE ...`:** reserva ocho bytes para el código y su terminador.
- **Línea 18 — `Nombre BYTE ...`:** reserva 26 bytes: 25 caracteres más el cero final.
- **Línea 19 — `PrecioCentavos DWORD ?`:** representa el precio como entero de centavos, no como punto flotante. Esto evita errores binarios de redondeo en importes decimales.
- **Línea 20 — `Existencia DWORD ?`:** guarda la cantidad disponible.
- **Línea 21 — `Producto ENDS`:** cierra la definición. `TYPE Producto` permite calcular el tamaño de un elemento al recorrer el arreglo.

## 4. Datos globales, mensajes y configuración de secciones (líneas 23–101)

### Estado y buffers (líneas 23–48)

- **Línea 23 — `.data`:** empieza la sección de datos globales.
- **Líneas 24–25 — `rutaInventario` y `rutaRespaldo`:** cadenas terminadas en cero para las rutas de archivo. Primero se usa `data\inventario_papeleria.dat`; si no se puede abrir esa ruta, se intenta `inventario_papeleria.dat` en el directorio actual.
- **Línea 26 — `arregloProductos`:** reserva diez estructuras. `<>` deja que los campos sin inicializador explícito queden sin un valor útil hasta ser escritos; la cantidad válida la determina `cantidadProductos`.
- **Línea 27 — `cantidadProductos`:** cuenta los elementos activos; evita recorrer todo el arreglo sin inicializar.
- **Línea 28 — `codigoTemporal`:** área de captura para código; el tamaño excede el código válido para poder detectar entradas más largas.
- **Línea 29 — `nombreTemporal`:** área temporal de captura. Después se rechazan nombres vacíos o mayores de 25 caracteres.
- **Línea 30 — `entradaTemporal`:** buffer declarado pero no usado por el código actual.
- **Línea 31 — `opcionMenu`:** recibe la selección de menú y también la respuesta S/N al salir.
- **Línea 32 — `bufferEntrada`:** buffer compartido para precio y números. Reutilizarlo evita reservar un área distinta para cada captura.
- **Línea 33 — `bufferArchivo`:** recibe el contenido del catálogo antes de analizarlo.
- **Línea 34 — `arregloTemporal`:** arreglo de trabajo usado durante la carga. Permite validar el catálogo completo antes de sustituir el arreglo activo.
- **Líneas 35–37 — `bufferNumero`, `bufferCentavos`, `digitosInvertidos`:** buffers para convertir números a texto; `bufferCentavos` contiene los dos dígitos decimales seguidos del sufijo ` MXN`.
- **Línea 38 — `saltoLinea`:** contiene CR y LF (13 y 10), escritos al final de cada fila.
- **Línea 39 — `separador`:** byte `|` que separa campos del archivo. Se escribe con longitud explícita, no como cadena terminada en cero.
- **Línea 40 — `identificadorArchivo`:** conserva el handle devuelto por Irvine32 y lo usan lectura, escritura y cierre.
- **Línea 41 — `errorEntradaSalida`:** una vez que una escritura queda incompleta, bloquea nuevas escrituras de esa operación y comunica el error al final.
- **Línea 42 — `cambiosSinGuardar`:** indica si una acción modificó el catálogo desde el último guardado/carga exitosa.
- **Línea 43 — `guardadoExitoso`:** informa si el último guardado terminó correctamente; `principal` lo consulta antes de salir.
- **Línea 44 — `cargaExitosa`:** se pone a cero/al éxito en `CargarCatalogo`, pero no se consulta en otro punto del programa.
- **Línea 45 — `usaRespaldo`:** registra si se intentó la ruta alternativa al guardar; el estado no altera otras decisiones.
- **Línea 46 — `bytesArchivo`:** recibe el número de bytes leído; no se vuelve a usar después de asignarlo.
- **Línea 47 — `cantidadTemporal`:** cuenta las filas ya validadas en `arregloTemporal`.
- **Línea 48 — `ingresosTotales QWORD`:** acumula ventas de la sesión en 64 bits. No forma parte del archivo y se reinicia al iniciar el programa.

### Textos de interfaz (líneas 50–100)

Todos los textos terminados en `0` son cadenas que puede imprimir `WriteString`. Los valores `13, 10` son salto de línea Windows. Su definición como datos separa las palabras de la lógica y hace que el programa use mensajes consistentes.

- **Línea 50:** título del sistema.
- **Líneas 51–60:** rótulos de las opciones 1 a 9 y 0; el orden coincide con los saltos de selección del programa principal.
- **Líneas 61–65:** preguntas para menú, código, nombre, precio y cantidad.
- **Líneas 66–82:** mensajes de entrada inválida, alta, mercancía, duplicados, búsquedas fallidas, guardado/carga, resumen, regla de negocio, salida y límites/errores de validación.
- **Líneas 83–91:** prefijos de importes y datos del resumen. Algunos no separan el salto de línea porque el valor se imprime inmediatamente después.
- **Líneas 92–93:** errores de archivo y de formato de catálogo.
- **Líneas 94–98:** textos para cantidad cargada, número de productos y preguntas específicas por operación.
- **Líneas 99–100:** confirmación de cambios pendientes y aviso si no se pudo guardar al salir.
- **Línea 101 — `.code`:** empieza la sección de instrucciones ejecutables.

Los mensajes presentan texto sin acentos en el fuente para mantener compatibilidad sencilla con la página de códigos de la consola y con herramientas MASM antiguas.

## 5. Contratos y validación de código (líneas 103–158)

- **Líneas 103–105:** documentan el convenio del archivo: entradas, salidas, registros preservados y el uso de `USES`, `LOCAL` e `INVOKE`.
- **Líneas 107–110:** comentario de contrato de `EsCodigoValido`: recibe puntero en `EDX` y devuelve `AL=1` o `AL=0`.
- **Línea 112 — `EsCodigoValido PROC USES ESI ECX`:** inicia el procedimiento y preserva los registros de trabajo que altera.
- **Línea 113:** copia el puntero de `EDX` a `ESI`, que servirá para recorrer la cadena.
- **Líneas 114–115:** exige cero en el índice 7. Así confirma que la cadena tenga exactamente siete caracteres antes del terminador.
- **Línea 118:** inicializa `ECX` en tres, el número de letras del prefijo.
- **Líneas 119–121:** lazo de letras: si el contador llega a cero pasa al guion; si no, lee el carácter actual.
- **Líneas 122–125:** comprueba que cada carácter esté entre `A` y `Z`. La comparación ASCII rechaza minúsculas, símbolos y números en el prefijo.
- **Líneas 126–128:** avanza al siguiente byte, decrementa el contador y repite.
- **Líneas 130–134:** exige `-` en la posición posterior a las tres letras y avanza al primer dígito.
- **Línea 137:** configura tres iteraciones para los dígitos finales.
- **Líneas 138–140:** termina al validar los tres dígitos; de lo contrario, lee el byte actual.
- **Líneas 141–144:** exige que el carácter esté en el rango ASCII `'0'`–`'9'`.
- **Líneas 145–147:** avanza y repite por los tres dígitos.
- **Líneas 149–150:** devuelve uno cuando todas las comprobaciones pasaron.
- **Líneas 152–153:** ruta común de error: devuelve cero.
- **Línea 154:** cierra el procedimiento.

El formato fijo hace que comparar códigos sea sencillo. La validación también se reaprovecha durante la carga del archivo, por lo que un catálogo externo no puede introducir códigos con formato distinto.

## 6. Conversión de precio a centavos (líneas 160–273)

`ConvertirPrecioACentavos` recorre la cadena manualmente. Acepta números positivos como `185.50`, `12.05`, `185` y `0.01`; no acepta signos, comas, más de un punto ni más de dos dígitos decimales.

- **Líneas 160–165:** describen el contrato, registros y valores de retorno.
- **Línea 167:** declara el procedimiento, preserva `ESI`, `ECX` y `EBX`, y recibe `texto` como parámetro.
- **Línea 168:** reserva variables locales para parte entera, fracción, presencia del punto, cantidad de decimales y dígito actual.
- **Líneas 170–175:** apuntan `ESI` al texto e inicializan acumuladores/flags. Inicializar explícitamente evita depender del contenido previo de la pila.
- **Líneas 177–180:** lee el carácter actual; el byte cero termina el bucle y el punto decimal deriva a su lógica específica.
- **Líneas 181–184:** si no es punto ni dígito ASCII, abandona por entrada inválida.
- **Líneas 188–190:** convierte el carácter en el entero 0–9 y lo guarda temporalmente.
- **Líneas 191–192:** distingue si el punto decimal ya se leyó.
- **Líneas 194–202:** parte entera: multiplica el acumulado por diez, comprueba el desbordamiento alto de `mul`, añade el dígito y comprueba el acarreo. Así evita que un precio enorme se envuelva silenciosamente.
- **Líneas 203–215:** parte fraccionaria: rechaza un tercer dígito, agrega el siguiente decimal y cuenta cuántos hay.
- **Líneas 217–220:** solo permite un punto decimal.
- **Líneas 223–225:** avanza al carácter siguiente y vuelve a leerlo.
- **Líneas 227–231:** al terminar, exige un valor: si parte entera es cero también debe existir al menos un decimal. Esto permite `0.01`/`.01`, pero rechaza una cadena vacía o solo `.`.
- **Líneas 232–241:** si no hubo dígitos decimales, se dirige al caso de precio entero; si hubo uno, se prepara para completar centavos.
- **Líneas 243–245:** verifica que en el caso decimal haya exactamente dos dígitos (el caso de uno ya fue normalizado).
- **Líneas 247–256:** multiplica los pesos por 100, controla desbordamiento, suma los centavos y retorna éxito en `EDX`. El resultado entero de centavos queda en `EAX`.
- **Líneas 258–267:** para un entero sin punto, lo multiplica por 100 y devuelve éxito; si se escribió un punto sin fracción, lo rechaza.
- **Líneas 269–272:** retorno común de error: `EAX=0`, `EDX=0`.
- **Línea 269:** finaliza el procedimiento.

La representación en centavos es una decisión importante: los precios, descuentos, ventas y valores de inventario se calculan con enteros, por lo que no se acumulan errores de punto flotante. El llamador, además, rechaza un precio final de cero.

## 7. Búsqueda en el arreglo (líneas 275–325)

- **Líneas 275–279:** contrato; recibe un puntero a código y devuelve índice o `-1`.
- **Línea 281:** declara los registros que preservará y el parámetro.
- **Líneas 283–284:** empieza por índice cero y prepara un contador con el número de productos válidos.
- **Líneas 286–288:** si no quedan productos, salta a “no encontrado”; en otro caso comienza el cuerpo del lazo.
- **Líneas 290–294:** calcula `índice * TYPE Producto`, forma la dirección de ese registro y obtiene la dirección de su código. `imul` permite saltar una estructura completa, no asumir que sus campos son independientes.
- **Líneas 296–297:** inicializa puntero al código buscado y límite de comparación.
- **Líneas 299–301:** compara hasta ocho bytes; si llega a cero caracteres pendientes, considera que encontró la cadena.
- **Líneas 302–305:** compara byte por byte. Una diferencia salta al producto siguiente; dos ceros iguales significan fin idéntico de ambas cadenas.
- **Líneas 306–309:** avanza los punteros y reduce el límite de comparación.
- **Líneas 311–313:** incrementa el índice y reduce el número de productos a revisar.
- **Líneas 315–316:** al encontrarlo devuelve el índice en `EAX`.
- **Líneas 318–319:** al agotarse el arreglo devuelve `-1`.
- **Línea 320:** termina la función.

La búsqueda lineal es adecuada para un catálogo limitado a diez elementos: mantiene el diseño simple y no requiere ordenar ni mantener otro índice.

## 8. Menú y entrada de consola (líneas 327–442)

### Mostrar menú (líneas 327–364)

- **Líneas 327–331:** contrato de entrada y salida.
- **Línea 333:** inicia `MostrarMenu`.
- **Línea 334:** separa visualmente el menú con una línea vacía.
- **Líneas 335–358:** para cada cadena, carga su dirección en `EDX` y llama a `WriteString`. Esta repetición es explícita porque cada llamada de Irvine32 imprime una cadena C independiente.
- **Líneas 359–361:** imprime la pregunta, pasa a `ReadString` la dirección del buffer de menú y su capacidad.
- **Línea 362:** retorna dejando la longitud capturada en `EAX`.
- **Línea 364:** cierra el procedimiento.

### Leer una entrada con pregunta (líneas 366–377)

- **Líneas 366–368:** especifican pregunta, buffer, límite y longitud devuelta.
- **Línea 370:** declara el procedimiento con tres parámetros y preservación de `EDX`/`ECX`.
- **Líneas 371–372:** imprime la pregunta.
- **Líneas 373–375:** coloca el buffer y límite en los registros que espera `ReadString`.
- **Línea 376:** captura la línea; `EAX` queda como longitud.
- **Línea 377:** retorna.

Centralizar esta secuencia evita repetir la preparación de `ReadString` en cada operación.

### Convertir una cadena de dígitos a entero (líneas 379–426)

- **Líneas 379–382:** contrato: entero sin signo, límite dado por parámetro, `EDX` como indicador de éxito.
- **Línea 384:** inicia el procedimiento, declara parámetros y preserva registros auxiliares.
- **Línea 385:** reserva `valor`, `digito` y contador de dígitos.
- **Líneas 386–388:** posiciona el puntero y pone los acumuladores a cero.
- **Líneas 390–393:** lee cada byte y termina al encontrar cero.
- **Líneas 394–397:** rechaza cualquier byte fuera de `'0'`–`'9'`.
- **Líneas 398–400:** convierte el carácter ASCII en dígito numérico.
- **Líneas 401–405:** calcula `valor * 10`; `EDX` no debe quedar distinto de cero, pues eso indicaría que el producto excede 32 bits.
- **Líneas 406–409:** añade el dígito y comprueba acarreo.
- **Líneas 410–412:** compara con `valorMaximo` y rechaza valores mayores.
- **Líneas 413–416:** acepta el nuevo acumulado y avanza.
- **Líneas 418–420:** al final rechaza cadena vacía; un cero escrito sí cuenta como un dígito.
- **Líneas 418–420:** devuelve el valor en `EAX` y estado de éxito `EDX=1`.
- **Líneas 422–425:** en error devuelve cero y `EDX=0`.

### Capturar número entero (líneas 428–442)

- **Líneas 428–430:** contrato de `LeerNumero`, que usa `-1` para distinguir error de cualquier cantidad permitida.
- **Línea 431:** declara pregunta y límite.
- **Líneas 432–434:** captura en `bufferEntrada` y rechaza longitud cero.
- **Líneas 435–437:** convierte la cadena con el máximo solicitado e interpreta `EDX=0` como error.
- **Línea 438:** retorna el valor válido.
- **Líneas 439–440:** etiqueta de error y valor centinela `-1`.
- **Línea 442:** termina el procedimiento.

La cantidad de productos y movimientos se captura como texto deliberadamente: permite rechazar letras, signos y valores fuera de rango antes de modificar el stock.

## 9. Cálculo y formato de enteros de 64 bits (líneas 444–554)

### División de un QWORD por diez (líneas 444–467)

- **Líneas 444–448:** explican que la entrada de 64 bits llega como `EDX:EAX`, y retorna cociente de 64 bits y residuo.
- **Línea 449:** inicia la rutina y preserva `EBX`.
- **Línea 450:** reserva partes alta/baja y un residuo intermedio.
- **Líneas 451–452:** copia la entrada para poder reutilizar `EAX`/`EDX` en `div`.
- **Líneas 453–457:** divide primero la mitad alta por diez. El cociente será la parte alta del resultado y el residuo será el “resto parcial” para dividir la mitad baja.
- **Líneas 458–463:** combina ese residuo con la mitad baja y divide otra vez. Así se simula la división de un número de 64 bits usando divisiones de 32 bits.
- **Líneas 464–466:** guarda el residuo final en `ECX`, restaura el cociente a `EDX:EAX` y retorna.
- **Línea 467:** cierra el procedimiento.

### Imprimir entero sin signo de 64 bits (líneas 469–511)

- **Líneas 469–472:** contrato y registros.
- **Línea 473:** declara la rutina y preserva registros auxiliares.
- **Línea 474:** reserva copia alta/baja, cantidad de dígitos y residuo.
- **Líneas 475–477:** copia la entrada e inicia el contador.
- **Líneas 479–485:** primera mitad de cada iteración: divide la parte alta por diez y conserva su residuo.
- **Líneas 486–492:** continúa la división sobre la parte baja, usando el residuo alto. Obtiene el siguiente dígito menos significativo en `DL` y lo almacena como ASCII.
- **Líneas 493–496:** si alguna parte del cociente sigue siendo distinta de cero, repite. El cero también pasa una vez por el ciclo, así que se imprime correctamente.
- **Líneas 498–500:** prepara el índice al último dígito generado.
- **Líneas 501–505:** copia los dígitos en orden inverso hacia `bufferNumero`, ahora en orden decimal normal.
- **Línea 506:** agrega el terminador cero requerido por `WriteString`.
- **Líneas 507–508:** imprime la cadena.
- **Línea 509:** retorna.
- **Línea 511:** cierra la rutina.

### Imprimir moneda desde centavos (líneas 513–554)

- **Líneas 513–516:** contrato: recibe centavos en 64 bits.
- **Línea 517:** declara procedimiento y preserva `EBX`.
- **Línea 518:** reserva partes del importe y residuo de la división por cien.
- **Línea 519:** reserva las decenas/unidades de centavos.
- **Líneas 520–521:** copia el valor de entrada.
- **Líneas 522–532:** divide `EDX:EAX` entre 100 con dos divisiones de 32 bits, con el mismo procedimiento de residuo intermedio. Guarda el cociente de pesos y el residuo de centavos (0–99).
- **Líneas 533–535:** pasa los pesos a la rutina de entero de 64 bits.
- **Líneas 536–537:** imprime el punto decimal.
- **Líneas 538–543:** divide los centavos restantes entre diez; cociente son decenas y residuo son unidades.
- **Líneas 544–549:** convierte decenas y unidades de centavo a ASCII y las guarda en el inicio de `bufferCentavos`.
- **Línea 550:** escribe un espacio tras los dos dígitos; la cadena ` MXN` ya está almacenada a continuación en el mismo buffer.
- **Líneas 551–552:** imprime juntos los dos decimales y el sufijo de moneda, incluso con un cero inicial (`.05 MXN`).
- **Línea 553:** retorna.
- **Línea 554:** termina el procedimiento.

Estas rutinas evitan depender de conversiones numéricas de Irvine32; los importes se forman con operaciones aritméticas y cadenas propias, en línea con la restricción descrita en el informe del proyecto. `EscribirMoneda64` añade ` MXN` al final, por lo que la moneda queda identificada en precio, total de venta y valores del resumen.

## 10. Presentación del catálogo y registro (líneas 556–712)

### Mostrar un producto (líneas 556–585)

- **Líneas 556–558:** contrato: recibe un índice.
- **Línea 559:** inicia el procedimiento preservando `ESI` y `EBX`.
- **Líneas 560–563:** multiplica índice por tamaño de estructura y calcula la dirección del producto.
- **Líneas 564–565:** imprime el código; `Codigo` se ubica al inicio de la estructura.
- **Líneas 566–569:** imprime un espacio y el nombre, localizado mediante `Producto.Nombre`.
- **Líneas 570–576:** imprime espacio, `$` y el precio en centavos convertido a moneda.
- **Líneas 577–580:** separa e imprime la etiqueta de existencia.
- **Líneas 581–584:** imprime la existencia como entero decimal, agrega salto de línea y retorna; **línea 585** cierra el procedimiento.

### Mostrar todo el inventario (líneas 587–608)

- **Líneas 587–589:** contrato.
- **Línea 590:** declara el índice local y preserva `ESI`.
- **Líneas 592–596:** si no hay productos, imprime el aviso y retorna.
- **Líneas 597–598:** si sí hay, inicia el índice en cero.
- **Líneas 599–603:** compara el índice con la cantidad activa; al agotarse sale; si aún hay producto, llama a `MostrarProducto`.
- **Líneas 604–605:** aumenta índice y repite.
- **Líneas 606–607:** retorno al terminar.
- **Línea 608:** cierre.

### Registrar producto (líneas 610–712)

- **Líneas 610–612:** contrato: captura, valida y solo después cambia el arreglo.
- **Línea 613:** inicia el procedimiento, preserva los registros auxiliares.
- **Línea 614:** crea variables locales para guardar precio y existencia ya validados.
- **Líneas 615–619:** verifica primero el límite de diez productos. Si está lleno, muestra el mensaje y retorna antes de pedir datos.
- **Líneas 620–628:** captura el código y valida `ABC-123`; si no cumple, muestra error y sale.
- **Líneas 629–635:** busca el código en el catálogo; si existe, rechaza duplicado; si no, continúa.
- **Líneas 636–650:** captura el nombre, exige longitud entre 1 y 25 y recorre sus caracteres. Rechaza `|`, pues ese carácter separa columnas del archivo y admitirlo rompería el formato de persistencia.
- **Líneas 651–660:** pide precio, lo convierte a centavos, comprueba el estado de conversión y rechaza cero.
- **Líneas 661–666:** captura existencia con máximo 100 y rechaza cero o una conversión inválida.
- **Líneas 668–676:** calcula la dirección del siguiente registro libre y copia los ocho bytes del código.
- **Líneas 678–686:** calcula de nuevo la dirección del campo nombre y copia 26 bytes, incluyendo el terminador cero desde `nombreTemporal`.
- **Líneas 687–694:** calcula dirección del registro y escribe los campos numéricos validados.
- **Líneas 695–699:** incrementa la cantidad, marca cambios sin guardar, muestra confirmación y retorna.
- **Líneas 700–703:** ruta de error para nombre, muestra entrada inválida.
- **Líneas 704–707:** ruta de error del precio.
- **Líneas 708–711:** ruta de error de existencia.
- **Línea 712:** cierra el procedimiento.

El uso de buffers temporales es clave: errores de código, nombre, precio o cantidad no dejan un producto parcialmente agregado. La copia al catálogo ocurre una sola vez cuando todos los campos son válidos.

## 11. Búsqueda y recepción de mercancía (líneas 714–793)

### Leer código reutilizable (líneas 714–722)

- **Líneas 714–716:** describen la pregunta configurable y el estado de salida.
- **Línea 717:** inicia el auxiliar.
- **Línea 718:** delega la lectura a `LeerEntrada`, usando el mismo buffer temporal.
- **Líneas 719–720:** llama al validador y retorna su valor en `AL`.
- **Línea 722:** cierra el procedimiento.

### Buscar un producto desde el menú (líneas 724–744)

- **Líneas 724–726:** indican que lee un código, busca y muestra el producto.
- **Línea 727:** inicia el procedimiento.
- **Líneas 728–730:** pide código con el mensaje apropiado y bifurca por el resultado de validación.
- **Líneas 731–733:** mensaje y retorno si el formato no es válido.
- **Líneas 734–739:** busca el código; si obtiene índice, llama a `MostrarProducto`.
- **Líneas 740–743:** mensaje de producto no encontrado.
- **Línea 744:** cierra.

### Recibir mercancía (líneas 746–793)

- **Líneas 746–748:** contrato de operación.
- **Línea 749:** declara locales para índice y cantidad, y preserva `EBX`/`ESI`.
- **Líneas 751–756:** lee y valida código; un formato inválido termina sin mutar el inventario.
- **Líneas 757–761:** busca el producto y guarda el índice; si no existe, muestra el mensaje correspondiente.
- **Líneas 762–767:** lee la cantidad, rechaza errores y valores menores que uno.
- **Líneas 768–775:** calcula la dirección de estructura, suma la cantidad propuesta al stock y comprueba el máximo de 100.
- **Líneas 776–780:** solo si es válida, escribe existencia nueva, marca cambios pendientes y confirma.
- **Líneas 781–784:** salida por código inexistente.
- **Líneas 785–788:** salida por cantidad inválida.
- **Líneas 789–792:** salida por superar el máximo de existencias.
- **Línea 793:** cierre.

La suma se verifica antes de escribir en memoria: el límite protege el estado del inventario y también se aplica consistentemente a los catálogos importados.

## 12. Venta, descuento e ingresos (líneas 795–873)

- **Líneas 795–797:** contrato de la venta.
- **Línea 798:** declara locales de índice, unidades y producto de 64 bits en dos DWORD; preserva registros auxiliares.
- **Líneas 800–805:** captura y valida código.
- **Líneas 806–810:** busca el código y termina con mensaje si no está en el catálogo.
- **Líneas 811–816:** captura la cantidad y exige al menos una unidad.
- **Líneas 817–826:** localiza el producto y comprueba `existencia >= cantidad`; en caso contrario, retorna sin descontar stock.
- **Línea 827 — `CalcularVenta`:** entrada a cálculos solo si hay mercancía suficiente.
- **Líneas 828–831:** multiplica precio unitario por cantidad. `mul` produce importe de hasta 64 bits; se separa en parte baja/alta para no truncar.
- **Líneas 832–833:** compara unidades con cinco; menos de cinco saltan a la venta sin descuento.
- **Líneas 834–841:** para cinco o más, divide el importe bruto entre diez y resta ese 10%. `sub` y `sbb` restan las mitades baja/alta incluyendo el préstamo. La división entera descarta una posible fracción de centavo.
- **Líneas 842–844:** informa que no aplica descuento.
- **Líneas 845–852:** vuelve a localizar el producto y resta la cantidad. La comprobación previa garantiza que la resta no quede negativa.
- **Línea 853:** marca el catálogo como modificado.
- **Líneas 854–857:** suma el total cobrado al QWORD `ingresosTotales`; `adc` incluye acarreo de los 32 bits bajos.
- **Líneas 858–864:** imprime etiqueta, total ya descontado como moneda y salto de línea.
- **Líneas 865–868:** salida por producto inexistente.
- **Líneas 869–872:** salida por cantidad inválida.
- **Línea 873:** cierra el procedimiento.

La regla de negocio implementada es exactamente “10% si se venden 5 o más unidades del mismo producto en una operación”. No suma unidades de productos distintos para alcanzar el umbral. El stock se modifica después de validar y calcular la venta.

## 13. Resumen del inventario (líneas 875–926)

- **Líneas 875–877:** contrato: mostrar cantidades, valor de stock e ingresos de sesión.
- **Línea 878:** declara acumuladores locales y preserva `ESI`.
- **Líneas 880–883:** pone unidades, importe de inventario (alto/bajo) e índice en cero.
- **Líneas 884–887:** recorre hasta `cantidadProductos`.
- **Líneas 888–892:** calcula la dirección del producto, suma existencia al total de unidades y multiplica existencia por precio.
- **Líneas 893–897:** acumula el producto de 64 bits (`add` suma los bits bajos y `adc` los altos con acarreo), incrementa índice y repite.
- **Líneas 899–907:** imprime encabezado y cantidad de productos registrados.
- **Líneas 908–912:** imprime total de unidades.
- **Líneas 913–918:** imprime el valor total del inventario formateado como moneda.
- **Líneas 919–924:** imprime ingresos acumulados durante esta ejecución del programa.
- **Línea 925:** retorna; **línea 926** cierra el procedimiento.

El valor del inventario es la suma de `existencia * precio` de cada producto; no es una suma de las ventas ni un valor contable con costos distintos. Los ingresos se reinician al ejecutar de nuevo y no se guardan en el archivo.

## 14. Longitud y formato de enteros (líneas 928–984)

### `LongitudCadena` (líneas 928–941)

- **Líneas 928–930:** contrato y registro preservado.
- **Línea 931:** inicia función con parámetro puntero.
- **Línea 932:** copia el puntero a `ESI`.
- **Línea 933:** pone en cero el índice/longitud.
- **Líneas 934–937:** consulta byte a byte hasta cero; aumenta longitud en cada carácter.
- **Líneas 938–939:** retorna longitud en `EAX`.
- **Línea 941:** cierre.

### `FormatearEnteroSinSigno` (líneas 943–974)

- **Líneas 943–945:** contrato: convertir DWORD en cadena decimal y dejar su longitud en `EAX`.
- **Línea 946:** declara la rutina y preserva registros de trabajo.
- **Líneas 947–948:** inicializa contador y divisor decimal diez.
- **Líneas 949–953:** caso especial para cero; escribe `'0'` como primer dígito para que el bucle posterior no produzca una cadena vacía.
- **Líneas 954–961:** para valores no cero, divide repetidamente entre diez. El residuo (`DL`) es el dígito menos significativo, que se convierte a ASCII y se guarda invertido.
- **Líneas 960–961:** repite mientras quede cociente.
- **Líneas 962–964:** prepara el índice al último dígito almacenado.
- **Líneas 965–970:** copia en orden inverso al buffer final.
- **Líneas 971–973:** añade el terminador cero, devuelve la longitud en `EAX` y retorna.
- **Línea 974:** cierre.

### `EscribirEnteroSinSigno` (líneas 976–984)

- **Líneas 976–978:** contrato.
- **Línea 979:** inicia y preserva `EDX`.
- **Línea 980:** transforma el valor de `EAX` mediante `FormatearEnteroSinSigno`.
- **Líneas 981–982:** pasa la dirección del buffer a `WriteString` y lo imprime.
- **Línea 983:** retorna; **línea 984** cierra.

El conversor propio también permite mostrar cantidades y valores guardados sin invocar funciones de conversión numérica de Irvine32.

## 15. Escritura y guardado del catálogo (líneas 986–1073)

### Escribir bytes comprobando resultado (líneas 986–1004)

- **Líneas 986–988:** contrato de dirección y longitud.
- **Línea 989:** declara `EscribirBytes`, preserva registros y recibe longitud.
- **Línea 990:** reserva la cantidad esperada.
- **Líneas 991–992:** si ya hubo un error, evita emitir más escrituras.
- **Líneas 993–994:** conserva el número de bytes solicitado.
- **Líneas 995–998:** prepara handle, dirección y longitud para `WriteToFile`; compara bytes escritos con los esperados.
- **Líneas 999–1001:** si las cantidades no coinciden, marca error de E/S.
- **Líneas 1002–1004:** etiqueta de salida, retorno y cierre.

### Guardar catálogo (líneas 1006–1073)

- **Líneas 1006–1008:** contrato: guardar productos y cambiar estados de éxito/cambios pendientes.
- **Línea 1009:** inicia el procedimiento; la línea 1010 declara locales y preserva `ESI`.
- **Líneas 1011–1012:** inicializa resultado de guardado y estado de ruta alternativa.
- **Líneas 1013–1016:** intenta crear el archivo principal y salta al procesamiento si se abre.
- **Líneas 1017–1021:** si falla la primera ruta, marca el intento de respaldo, prueba la ruta secundaria y va al error si tampoco abre.
- **Líneas 1023–1025:** guarda el handle, limpia estado de error y comienza por producto cero.
- **Líneas 1027–1030:** itera por el catálogo; al terminar todos los productos salta al cierre.
- **Líneas 1031–1036:** calcula dirección del registro, la conserva y escribe el código y primer separador.
- **Líneas 1037–1043:** calcula longitud del nombre, obtiene dirección del campo y lo escribe sin incluir su terminador; después escribe separador.
- **Líneas 1045–1049:** carga precio en centavos, lo convierte a decimal y escribe los caracteres formateados y el separador.
- **Líneas 1051–1055:** convierte existencia a decimal, escribe ese texto y agrega CRLF.
- **Líneas 1056–1057:** incrementa índice y repite.
- **Líneas 1059–1063:** cierra el archivo y comprueba el indicador de escritura.
- **Líneas 1064–1068:** marca guardado exitoso, limpia cambios pendientes y muestra confirmación.
- **Líneas 1069–1072:** en error, muestra el mensaje y retorna sin indicar éxito.
- **Línea 1073:** cierra el procedimiento.

El formato resultante es `codigo|nombre|precio_en_centavos|existencia`, por ejemplo `ABC-123|Cuaderno profesional|25000|30`. El precio se guarda como entero para que la carga no dependa de analizar separadores decimales o locales. Las llamadas comprueban que cada bloque se haya escrito completo. Un fallo de escritura se informa, aunque el código no crea un archivo temporal ni garantiza que el archivo anterior sobreviva intacto a un fallo a mitad de guardado.

## 16. Carga y validación transaccional (líneas 1075–1308)

`CargarCatalogo` tiene dos fases: analiza las filas en `arregloTemporal` y, únicamente si todas son válidas, copia ese arreglo al principal. La protección evita que un archivo incorrecto reemplace parcialmente el catálogo activo.

### Abrir y leer archivo (líneas 1075–1104)

- **Líneas 1075–1077:** contrato: solo sustituir catálogo después de validar todas las filas.
- **Línea 1078:** declara registros auxiliares preservados.
- **Líneas 1079–1081:** reserva punteros e índices temporales para fila, campos y datos ya convertidos.
- **Línea 1083:** inicializa estado de carga.
- **Líneas 1084–1088:** intenta abrir la ruta principal y, si no se abre, la ruta de respaldo.
- **Líneas 1089–1090:** si no se abre ninguna, informa error de carga.
- **Líneas 1092–1097:** conserva el handle, prepara buffer y límite de lectura, y lee el archivo.
- **Líneas 1098–1100:** usa carry para detectar error de lectura y rechaza una lectura que llena el límite, porque podría estar truncada.
- **Líneas 1101–1104:** registra longitud, agrega terminador cero al buffer, reinicia el contador temporal y apunta al inicio.

El respaldo se intenta solo cuando `OpenInputFile` de la primera ruta falla. Si el primer archivo sí abre pero su contenido no es válido o falla su lectura, se reporta el error; no se prueba automáticamente el segundo archivo.

### Separar filas y saltos de línea (líneas 1106–1147)

- **Líneas 1106–1114:** el bucle termina al encontrar el terminador; ignora CR o LF aislados y guarda el inicio de la fila en `inicioLinea`.
- **Líneas 1115–1123:** avanza `EBX` hasta el final de la fila: cero, CR o LF.
- **Líneas 1124–1134:** si se llegó al final del archivo, deriva a la última línea; si no, calcula si debe saltar uno o dos bytes de fin de línea.
- **Líneas 1135–1141:** completa la detección de LF, conserva la dirección de la siguiente línea, reemplaza el salto actual por cero y pasa al analizador.
- **Líneas 1142–1144:** trata la última línea, que puede terminar directamente en cero.
- **Líneas 1145–1147:** rechaza más de diez registros antes de analizar otra fila.

### Analizar código y duplicados (líneas 1149–1205)

- **Líneas 1149–1157:** parte del inicio de la fila, busca el primer separador y rechaza una fila sin él.
- **Líneas 1158–1168:** exige longitud exacta de siete caracteres, separa temporalmente la cadena, reutiliza `EsCodigoValido` e inicializa la búsqueda de duplicados.
- **Líneas 1169–1178:** recorre los códigos temporales ya procesados y prepara comparación byte a byte.
- **Líneas 1179–1187:** compara hasta ocho bytes; una coincidencia completa significa duplicado y vuelve inválido el catálogo.
- **Líneas 1188–1190:** si el registro no coincide, revisa el siguiente código.
- **Líneas 1191–1199:** al no encontrar duplicado, avanza más allá del separador, calcula el nuevo registro temporal y prepara la copia.
- **Líneas 1200–1205:** copia los ocho bytes del código en el registro temporal.

### Analizar nombre, precio y existencia (líneas 1207–1267)

- **Líneas 1207–1214:** establece inicio del nombre, busca su separador y rechaza ausencia del campo.
- **Líneas 1215–1228:** termina el nombre temporalmente, calcula longitud, exige entre 1 y 25 caracteres y prepara la copia.
- **Líneas 1229–1235:** copia el nombre al registro temporal y escribe explícitamente el byte cero final.
- **Líneas 1237–1244:** inicia el precio y busca el siguiente separador; si no está, la fila es inválida.
- **Líneas 1245–1253:** termina el campo de precio, lo convierte con el parser entero, exige conversión válida y precio mayor que cero.
- **Líneas 1255–1259:** toma el campo de existencia, lo convierte con máximo 100 y rechaza error de conversión.
- **Líneas 1260–1267:** escribe precio/existencia en el registro temporal, cuenta la fila y avanza a la siguiente línea.
- **Líneas 1269–1271:** omite caracteres de salto de línea extra y continúa.

La comprobación de duplicados se repite al cargar porque el archivo puede haber sido modificado fuera del programa. Los nombres no pueden contener `|` al registrarse y, en un archivo, el primer separador de cada campo delimita su contenido.

### Confirmar o abortar carga (líneas 1273–1308)

- **Líneas 1273–1277:** al llegar al final válido, copia cantidad temporal a la cantidad activa, limpia cambios pendientes y marca éxito.
- **Líneas 1278–1283:** calcula bytes correspondientes a los productos validados y copia desde arreglo temporal al principal con `rep movsb`. `cld` asegura que la copia avance hacia direcciones mayores.
- **Líneas 1284–1290:** cierra archivo e informa número cargado.
- **Líneas 1291–1293:** muestra confirmación final y retorna.
- **Líneas 1295–1301:** si falla la lectura o no puede abrirse ninguna ruta, cierra cuando hay handle y muestra formato/lectura inválidos.
- **Líneas 1302–1307:** para una fila inválida, cierra archivo y muestra el mismo mensaje; no copia los productos temporales al arreglo principal.
- **Línea 1308:** cierra el procedimiento.

La lectura acepta CRLF, LF y líneas vacías entre registros. El tamaño del archivo es limitado a menos de 4095 bytes, además del máximo de diez productos. Un archivo vacío se interpreta como catálogo vacío válido. Cargar un catálogo tampoco restablece `ingresosTotales`: esa cifra representa las ventas de la sesión, no un dato persistido.

## 17. Bucle principal y salida (líneas 1310–1417)

- **Líneas 1310–1314:** comentario de contrato del programa.
- **Línea 1316:** inicia `principal`.
- **Línea 1317:** carga catálogo al comenzar. Si no se puede abrir, el arreglo global parte vacío por su inicialización.
- **Línea 1319:** etiqueta del bucle de menú.
- **Línea 1320:** imprime y lee la opción.
- **Líneas 1321–1322:** verifica que el segundo byte sea cero. De esta forma exige una sola tecla y rechaza entradas como `12`.
- **Líneas 1323–1325:** compara la opción con ASCII `'0'`; esa opción inicia la secuencia de salida.
- **Líneas 1326–1343:** compara con `'1'` a `'9'` y salta a la etiqueta correspondiente.
- **Líneas 1345–1348:** cualquier opción no reconocida muestra error y vuelve al menú.
- **Líneas 1350–1377:** cada etiqueta llama al procedimiento de su función y retorna al bucle. La opción 9 imprime directamente la regla del negocio.
- **Línea 1379:** inicia la salida.
- **Líneas 1380–1381:** si no hay modificaciones pendientes, omite confirmación; si las hay, imprime la pregunta.
- **Líneas 1382–1388:** muestra la pregunta, lee respuesta en el mismo buffer del menú y exige un único carácter.
- **Líneas 1389–1397:** acepta S/s para guardar y N/n para salir sin guardar; otra respuesta se rechaza.
- **Líneas 1398–1401:** mensaje de error y regreso al menú ante respuesta inválida.
- **Líneas 1402–1406:** al elegir guardar, llama a `GuardarCatalogo`; solo continúa si `guardadoExitoso` quedó en uno.
- **Líneas 1407–1410:** si guardar falla, informa que no saldrá y regresa al menú para que el usuario pueda resolverlo o reintentar.
- **Líneas 1411–1414:** salida final: mensaje de despedida y macro `exit`.
- **Línea 1415:** cierra `principal`.
- **Línea 1417 — `END principal`:** marca el punto de entrada para el enlazador.

El bucle mantiene el programa activo después de opciones inválidas y después de un guardado fallido. La salida con `N` es una decisión explícita del usuario, no un guardado automático.

## 18. Cómo se cubren los requisitos y las limitantes

| Requisito o límite | Cómo se resuelve en el ASM |
|---|---|
| Catálogo pequeño y acotado | Arreglo estático de 10 estructuras; no necesita asignación dinámica ni administración de memoria. |
| Identificador único con formato | Validador común `ABC-123`; búsqueda lineal detecta duplicados. |
| Nombre acotado y persistencia delimitada | Límite de 25 caracteres; se rechaza `|` porque ese byte separa campos del archivo. |
| Precio decimal sin errores de punto flotante | Se captura como cadena y se convierte a centavos enteros; para imprimir se recompone con dos decimales. |
| Cantidades razonables | Parser propio de enteros positivos; operaciones de ingreso/carga respetan el máximo de 100 unidades. |
| No vender unidades inexistentes | Se compara stock disponible antes de calcular y actualizar la venta. |
| Descuento de negocio | A partir de cinco unidades de un mismo producto, se calcula 10% y se descuenta con aritmética entera. |
| Sumas que superen 32 bits | Importes de venta, inventario e ingresos usan pares de DWORD (`EDX:EAX`) o `QWORD` y sumas con acarreo. |
| Lectura de archivo posiblemente corrupto | Límites de tamaño, formato por campos, validación de código, nombre, precio, cantidad y duplicados. |
| Evitar reemplazo parcial del catálogo durante carga | Se analiza primero en `arregloTemporal`; solo se copia al principal tras validar todo el archivo. |
| Directorio `data` no disponible | Se intenta la ruta principal y, si no se puede abrir/crear, una ruta alternativa en el directorio actual. |
| Cambios accidentales al salir | `cambiosSinGuardar` activa pregunta; si el guardado solicitado falla, el programa permanece abierto. |
| Restricciones del entorno MASM/Irvine32 | Se usa Win32 x86, `ReadString`/`WriteString` y rutinas de archivo Irvine32; conversiones numéricas y presentación decimal se implementan en procedimientos propios. |

El proyecto documenta como entorno de compilación Visual Studio 2022, herramientas MASM y la biblioteca Irvine32 de 32 bits. Esa dependencia explica por qué el código no es ensamblador x64 ni una aplicación portátil a cualquier sistema sin cambios.

## 19. Detalles que conviene no confundir

- La opción “Guardar catálogo” persiste productos, precios y existencias; no guarda ingresos de sesión.
- La opción “Cargar catálogo” reemplaza el catálogo activo únicamente si todas las filas pasan validación. En cambio, al iniciarse sin un archivo abrible, el arreglo parte vacío.
- El respaldo se prueba si falla la apertura de la ruta principal; no se usa como recuperación automática ante cualquier archivo principal malformado.
- El descuento se aplica en una venta individual de cinco o más unidades del mismo código. La división por diez descarta fracciones de centavo.
- El archivo usa precio en centavos; la consola recibe pesos con dos decimales y muestra los importes con el sufijo `MXN`.
- El resumen suma el valor de venta de las existencias actuales (`precio * existencia`); no es un cálculo de utilidad.
- Algunos datos declarados en la sección global (`entradaTemporal`, `bytesArchivo`, `usaRespaldo`) no participan en decisiones posteriores; `cargaExitosa` se actualiza, pero tampoco se consulta fuera de la carga. Son detalles del estado actual del fuente, no características adicionales.
- Los errores de validación muestran un mensaje y regresan al menú; no mantienen al usuario en una rutina repitiendo automáticamente el mismo campo.

## 20. Archivos relacionados

- [Código principal](../src/Papeleria.asm)
- [README y requisitos de compilación](../README.md)
- [Informe breve del proyecto](./informe.md)
- [Tabla de pruebas](./tabla_pruebas.md)
