# Guía de respuestas para la revisión oral

Esta guía responde las 12 preguntas de la revisión y señala qué parte del programa conviene mostrar mientras se explica. Las referencias de líneas corresponden a [Papeleria.asm](../src/Papeleria.asm). Las respuestas describen el código actual; cuando hay una limitación o detalle mejorable, se señala en lugar de presentarlo como si ya estuviera resuelto.

## 1. `ReadString`: registros y resultado

En `ReadString`, **antes de la llamada**:

- `EDX` contiene la dirección del buffer donde se guardará el texto.
- `ECX` contiene el máximo de caracteres que se pueden leer.

**Al regresar**, `EAX` contiene la cantidad de caracteres leídos, sin contar el terminador. La entrada queda en el buffer señalado por `EDX`, terminada en cero (`00h`).

Por ejemplo, `LeerEntrada` imprime la pregunta, carga el buffer en `EDX` y el máximo en `ECX`, y llama a `ReadString` ([líneas 370–377](../src/Papeleria.asm#L370)). El menú usa `opcionMenu` como buffer ([líneas 359–362](../src/Papeleria.asm#L359)).

**Para señalar:** la diferencia entre dirección (`EDX`), capacidad (`ECX`), contenido del buffer y longitud leída (`EAX`).

## 2. Conversión de precios a centavos

`ConvertirPrecioACentavos` recorre el texto de izquierda a derecha. Antes del punto acumula `parteEntera` con la operación `acumulado * 10 + dígito`; después del punto acumula `fraccion` del mismo modo. El indicador `hayPunto` decide en qué parte guardar cada dígito. Solo se permite un punto y se rechaza una tercera cifra decimal ([líneas 167–225](../src/Papeleria.asm#L167)).

Ejemplos:

- `185.50`: `parteEntera = 185`, `fraccion = 50`; resultado: `185 * 100 + 50 = 18550` centavos.
- `12.05`: después del punto se leen dos dígitos, `0` y `5`; `fraccion` queda en `5`, que representa cinco centavos porque ya se leyeron dos posiciones decimales. Resultado: `12 * 100 + 5 = 1205` centavos.
- `12.5`: solo se lee un dígito decimal; al final se multiplica la fracción por diez para completar los centavos: `12 * 100 + 50 = 1250` centavos.

Al final se exige una entrada con valor, se completa una fracción de un dígito (por ejemplo, `.5` equivale a `.50`), se exige máximo dos decimales y se convierte la parte entera a centavos. Las multiplicaciones y sumas comprueban desbordamientos de 32 bits ([líneas 227–272](../src/Papeleria.asm#L227)). El procedimiento devuelve centavos en `EAX` y estado en `EDX` (`1` válido, `0` inválido). El alta de producto, además, rechaza un precio igual a cero ([líneas 652–660](../src/Papeleria.asm#L652)).

**Para señalar:** `hayPunto`, `digitosDespues`, las rutas `DigitoFraccion` y `PrecioInvalido`, y `FormarPrecio`.

## 3. Conversión de entero a cadena decimal

Para un DWORD, `FormatearEnteroSinSigno` divide repetidamente el número entre diez. Antes de `DIV`, pone el dividendo en `EDX:EAX` (con `EDX=0`) y el divisor diez en `EBX`. Después de la división, `EAX` contiene el cociente y `EDX` el residuo. El residuo es el último dígito decimal; se le suma `'0'` para obtener su carácter ASCII y se guarda en `digitosInvertidos` ([líneas 946–961](../src/Papeleria.asm#L946)).

Los residuos aparecen de menor a mayor posición. Por ejemplo, al convertir `185`, salen `5`, `8`, `1`; por eso se copian desde el final del buffer temporal hacia el inicio del buffer final. Se agrega un cero al final para formar una cadena imprimible con `WriteString` ([líneas 962–973](../src/Papeleria.asm#L962)).

Para valores de 64 bits se repite el principio con el par `EDX:EAX`, dividiendo primero la parte alta y luego la baja con el residuo intermedio ([líneas 473–511](../src/Papeleria.asm#L473)).

**Para señalar:** residuo → dígito ASCII (`add ..., '0'`) → almacenamiento invertido → copia en orden correcto.

## 4. Separar pesos y centavos con `DIV`

`EscribirMoneda64` recibe centavos en `EDX:EAX`. Guarda las dos mitades porque `DIV` usa y modifica esos registros. Para dividir un valor de 64 bits por 100, primero divide la parte alta y conserva su residuo; después forma el dividendo `residuo:parteBaja` y vuelve a dividir. En ambas divisiones, `EAX` recibe el cociente y `EDX` el residuo. El cociente combinado son los pesos y el residuo final son centavos entre 0 y 99 ([líneas 517–535](../src/Papeleria.asm#L517)).

Después de imprimir los pesos y el punto, divide el residuo entre 10. El cociente (`EAX`) son las decenas de centavo y el residuo (`EDX`) las unidades. Ambos valores se convierten a ASCII y se escriben siempre en dos posiciones. Así, 5 centavos producen `0` y `5`, que se imprimen como `.05`, no `.5`. El buffer continúa con el sufijo ` MXN`, de modo que el importe aparece, por ejemplo, como `$0.05 MXN` ([líneas 536–552](../src/Papeleria.asm#L536)).

**Para señalar:** preparación del dividendo alto/bajo antes de cada `DIV`, los registros de salida y la escritura de `bufferCentavos[0]` y `[1]`.

## 5. Productos en memoria y uso de `ESI`

Cada `Producto` es una estructura con código (8 bytes), nombre (26 bytes), precio en centavos (`DWORD`) y existencia (`DWORD`) ([líneas 16–21](../src/Papeleria.asm#L16)). `arregloProductos` reserva diez estructuras y `cantidadProductos` indica cuántas contienen datos válidos ([líneas 26–27](../src/Papeleria.asm#L26)).

Para localizar un producto por índice, se calcula:

```text
dirección = dirección_base + índice * TYPE Producto
```

`MostrarProducto` implementa ese cálculo con `imul`, carga la dirección base en `ESI` y suma el desplazamiento. Luego obtiene el nombre con `ESI + Producto.Nombre`, el precio con `ESI + Producto.PrecioCentavos` y la existencia con `ESI + Producto.Existencia` ([líneas 559–583](../src/Papeleria.asm#L559)). La búsqueda por código usa también `ESI` para recorrer el arreglo y comparar el campo `Codigo` ([líneas 281–320](../src/Papeleria.asm#L281)).

**Para señalar:** `TYPE Producto` escala el índice por el tamaño completo de la estructura; las constantes de campo evitan calcular a mano sus offsets.

## 6. Comparaciones que rechazan entradas

- **Código duplicado:** `BuscarProductoPorCodigo` devuelve `-1` si no encuentra coincidencia. En el alta, `cmp EAX, -1` seguido de `je` continúa solo si no existe; de otro modo muestra “Codigo duplicado” ([líneas 629–635](../src/Papeleria.asm#L629)).
- **Cantidad inválida:** `LeerNumero` devuelve `-1` si no pudo convertir. Las operaciones lo comparan con `-1` y también exigen que la cantidad sea al menos uno; la conversión recibe `EXISTENCIA_MAXIMA` como tope ([líneas 431–442](../src/Papeleria.asm#L431), [líneas 760–766](../src/Papeleria.asm#L760)).
- **Venta sin existencias:** compara stock con cantidad y salta a calcular la venta solo si `stock >= cantidad` (`jae`). Si no, muestra el error y retorna ([líneas 817–826](../src/Papeleria.asm#L817)).

El formato del código se valida aparte, comprobando tres letras, guion y tres dígitos ([líneas 112–158](../src/Papeleria.asm#L112)).

## 7. Cuándo se actualizan existencias e ingresos

La venta primero valida código, cantidad y stock; después calcula el total y el descuento. Solo al llegar a `ActualizarVenta` resta unidades del producto y marca cambios pendientes. Luego suma el total cobrado a `ingresosTotales` ([líneas 827–864](../src/Papeleria.asm#L827)). Si la venta se rechaza por falta de stock, retorna antes de tocar existencias o ingresos.

El producto de precio por cantidad queda en 64 bits porque `mul` devuelve `EDX:EAX`. Para añadir ese importe a los ingresos, `add` suma los 32 bits bajos y `adc` suma los altos junto con el acarreo ([líneas 828–831](../src/Papeleria.asm#L828), [líneas 854–857](../src/Papeleria.asm#L854)).

La conversión del precio detecta desbordamientos de 32 bits y la venta conserva el producto de 32 × 32 bits en 64 bits. `ADC` propaga el acarreo entre mitades, pero el código **no comprueba un desbordamiento que rebase los 64 bits** de `ingresosTotales`; conviene describirlo como límite, no decir que se detecta todo desbordamiento posible.

## 8. `CALL`, `RET`, registros y pila

`CALL` transfiere el control al procedimiento y guarda en la pila la dirección a la que debe volver. `RET` recupera esa dirección y regresa al punto posterior a la llamada. En este proyecto, los comentarios iniciales explican que se usan `USES`, `LOCAL` e `INVOKE` y no se manipula la pila manualmente con `PUSH`/`POP` ([líneas 103–105](../src/Papeleria.asm#L103)).

Por ejemplo, `BuscarProductoPorCodigo PROC USES ESI EDI EBX ECX` hace que MASM preserve esos registros auxiliares ([línea 281](../src/Papeleria.asm#L281)); `MostrarInventario PROC USES ESI` preserva `ESI` ([línea 590](../src/Papeleria.asm#L590)). `LOCAL` reserva variables temporales y MASM genera el prólogo/epílogo correspondiente. `INVOKE` prepara la llamada con parámetros, por ejemplo `invoke MostrarProducto, EAX` ([línea 603](../src/Papeleria.asm#L603)).

Para comprobar la pila en ejecución, se puede observar `ESP` en el depurador al entrar y salir de una llamada, teniendo en cuenta que los argumentos y registros preservados se apilan y desapilan durante el procedimiento. El fuente no incluye una comprobación explícita de `ESP`; la disciplina se apoya en los prólogos/epílogos generados por MASM y en usar de forma consistente las convenciones del ensamblador.

## 9. Handle y resultado de `WriteToFile`

Un **handle** es el identificador que representa el archivo abierto para que las rutinas de Irvine32 sepan sobre qué archivo operar. `CreateOutputFile` devuelve el handle en `EAX`; el programa lo guarda en `identificadorArchivo` ([líneas 1013–1024](../src/Papeleria.asm#L1013)).

Antes de `WriteToFile`, `EscribirBytes` prepara:

- `EAX`: handle del archivo.
- `EDX`: dirección de los bytes a escribir.
- `ECX`: cantidad de bytes solicitados.

La rutina devuelve en `EAX` cuántos bytes se escribieron. El programa compara ese resultado con `bytesEsperados`; si no coinciden, marca `errorEntradaSalida` ([líneas 989–1004](../src/Papeleria.asm#L989)). Al terminar, `GuardarCatalogo` comprueba ese indicador y solo marca el guardado exitoso si no hubo error ([líneas 1059–1072](../src/Papeleria.asm#L1059)).

## 10. Bytes leídos, capacidad y terminador `00h`

La **capacidad** es el espacio reservado; los **bytes leídos** son los datos que realmente entregó el archivo. No son necesariamente iguales. El catálogo reserva 4096 bytes, pero `ReadFromFile` recibe un máximo de 4095 para dejar disponible un byte de terminación ([líneas 33 y 1092–1102](../src/Papeleria.asm#L33)).

Al regresar, `EAX` indica cuántos bytes se leyeron. Si se alcanza el máximo, el programa rechaza la lectura porque el archivo podría haberse truncado. Si cabe, agrega el terminador en `bufferArchivo[EAX]`:

```asm
mov BYTE PTR bufferArchivo[EAX], 0
```

Ese `00h` es necesario si una rutina como `WriteString` va a tratar el contenido como cadena. El cargador actual no imprime el archivo con `WriteString`: lo recorre y analiza como registros. Sí agrega el terminador para poder detectar el final del buffer.

En las entradas de consola, `LeerEntrada` pasa `SIZEOF buffer - 1` como máximo, reservando espacio para el terminador ([líneas 370–376 y 431–435](../src/Papeleria.asm#L370)). **Detalle para la revisión:** `MostrarMenu` pasa `SIZEOF opcionMenu` directamente, y la lectura de la respuesta al salir también usa ese tamaño ([líneas 359–362 y 1382–1386](../src/Papeleria.asm#L359)). Esas dos llamadas no reservan explícitamente un byte adicional dentro del buffer; el patrón más seguro es pasar tamaño menos uno, como hace `LeerEntrada`.

## 11. Formato y reconstrucción del catálogo

El archivo es texto delimitado; cada fila tiene esta forma:

```text
codigo|nombre|precio_en_centavos|existencia
ABC-123|Cuaderno profesional|25000|30
```

`GuardarCatalogo` escribe los campos en ese orden, convirtiendo precio y existencia a cadenas decimales, y termina cada fila con CRLF ([líneas 1027–1057](../src/Papeleria.asm#L1027)). `CargarCatalogo` separa líneas y campos, valida el formato del código, que no haya códigos duplicados, que el nombre tenga longitud válida, que el precio sea un entero positivo y que la existencia no exceda 100 ([líneas 1106–1267](../src/Papeleria.asm#L1106)).

Los datos se preparan en `arregloTemporal`. Solo al terminar de validar todo el archivo se copian al arreglo principal ([líneas 1273–1285](../src/Papeleria.asm#L1273)); por eso un archivo malformado no deja el catálogo activo parcialmente sustituido. Al fallar, se muestra el mensaje de formato/lectura inválidos ([líneas 1295–1307](../src/Papeleria.asm#L1295)).

Primero se intenta `data\inventario_papeleria.dat`; si no se puede abrir, se prueba `inventario_papeleria.dat` en el directorio actual ([líneas 1084–1091](../src/Papeleria.asm#L1084)). Si el archivo principal abre pero está dañado, el código informa el error y **no** intenta cargar el respaldo. Al iniciar, si ninguna ruta se abre, el programa sigue al menú con la cantidad global inicializada en cero. Un archivo vacío que sí se abre se considera una carga válida de catálogo vacío.

## 12. Regla adicional y fuentes consultadas

La regla adicional es: **10% de descuento al comprar cinco o más unidades del mismo producto en una operación**. En la venta, `cmp cantidad, 5` decide si aplica ([líneas 832–844](../src/Papeleria.asm#L832)). Si aplica, se divide el total bruto entre diez y se resta ese descuento; la división entera descarta cualquier fracción de centavo ([líneas 834–841](../src/Papeleria.asm#L834)).

Ejemplos con precio unitario de `$10.00 MXN`:

- **Sí aplica:** 5 unidades cuestan `$50.00 MXN`; el 10% es `$5.00 MXN`; total: **`$45.00 MXN`**.
- **No aplica:** 4 unidades cuestan `$40.00 MXN`; no se alcanza el mínimo; total: **`$40.00 MXN`**.

La fuente consultada para la regla de negocio es la especificación/presentación **Lenguajes de Interfaz, Unidad 2**, citada en el [informe del proyecto](./informe.md). Para las interfaces de entrada, salida y archivos de Irvine32 se usó **Irvine Library Help**, también referenciada ahí, junto con la documentación de `ReadString`, `WriteString`, `CreateOutputFile`, `OpenInputFile`, `ReadFromFile`, `WriteToFile` y `CloseFile`. Las conversiones a centavos, el formato delimitado y las validaciones concretas son decisiones implementadas en este proyecto, no rutinas que se atribuyan a Irvine32.

## Fuentes utilizadas

- [Código fuente `Papeleria.asm`](../src/Papeleria.asm)
- [Informe del proyecto y bibliografía consultada](./informe.md)
- [README: entorno, compilación y formato del catálogo](../README.md)
- Irvine Library Help: [ReadString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readstring.htm), [WriteString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writestring.htm), [CreateOutputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/createoutputfile.htm), [OpenInputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/openinputfile.htm), [ReadFromFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readfromfile.htm), [WriteToFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writetofile.htm) y [CloseFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/closefile.htm).
