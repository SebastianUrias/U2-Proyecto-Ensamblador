# Informe breve del proyecto

## Negocio elegido
Se seleccionó una papelería llamada `Papelería del Valle`.

## Regla adicional del negocio
Se implementa un descuento del 10% cuando se compran 5 o más unidades del mismo producto. La lógica descarta fracciones de centavo aplicando división entera, tal como se indica en la especificación del proyecto.

## Organización de datos en ASM

Los productos se almacenan en un arreglo de hasta 10 estructuras MASM con:
- código único
- nombre del producto
- precio en centavos
- cantidad disponible

Cada operación valida los datos antes de modificar el arreglo. Los códigos usan el formato `ABC-123`, y la existencia por producto no puede exceder 100 unidades.

## Captura y conversión numérica
Las entradas se capturan con `ReadString`. Los precios y cantidades se validan y convierten mediante procedimientos propios. Para mostrar números, el programa genera cadenas decimales terminadas en cero y las presenta con `WriteString`; no usa `ReadDec`, `ReadInt`, `ParseDecimal32`, `WriteDec` ni `WriteHex` para esas conversiones.

## Procedimientos y pila
Los procedimientos documentan sus entradas, salidas y registros modificados. Los recorridos del catálogo usan `ESI`; `USES` conserva los registros indicados, `LOCAL` reserva variables temporales e `INVOKE` realiza llamadas con parámetros sin manipulación manual de la pila.

## Formato del archivo de inventario ASM

El catálogo se guarda como texto delimitado. Cada línea contiene código, nombre, precio en centavos y existencias:

```text
ABC-123|Cuaderno profesional|25000|30
```

El archivo de ejemplo está en `data/inventario_papeleria.dat`. El ingreso acumulado se mantiene en memoria durante la sesión y se reinicia al volver a ejecutar el programa.
Si no existe la carpeta `data` desde el directorio de trabajo, el ASM intenta guardar o cargar `inventario_papeleria.dat` en el directorio actual. Al salir después de registrar productos, recibir mercancía o vender, el programa avisa que hay cambios pendientes y ofrece guardarlos.

## Regla de descuento

La venta de cinco o más unidades de un mismo producto aplica un descuento del 10%. El cálculo usa centavos enteros y división entera, por lo que cualquier fracción de centavo se descarta.

## Versión de la Unidad 3

Se mantuvieron las operaciones, validaciones y la regla de descuento de la versión anterior. Los cambios se enfocaron en reutilizar el cálculo de direcciones, reducir secuencias de salida duplicadas y documentar la preservación de registros.

| Parte del programa | Problema detectado antes | Cambio en Unidad 3 | Beneficio |
| --- | --- | --- | --- |
| Acceso a `arregloProductos` | El cálculo `indice * TYPE Producto + OFFSET arregloProductos` se repetía en varias operaciones. | Se agregó `ObtenerDireccionProducto`, usado al mostrar, registrar, recibir mercancía, vender, resumir y guardar. | Centraliza el acceso al catálogo y facilita mantener una única forma de calcular la dirección. |
| Mensajes y menú | Se repetían los pares `mov EDX, OFFSET ...` y `call WriteString`. | La macro `MostrarTexto` reemplaza esas secuencias en 55 puntos. | Hace más legible la intención de mostrar una cadena y reduce las líneas repetidas en el archivo fuente. La expansión de la macro sigue generando las instrucciones en cada uso. |
| Preservación de registros del menú | `MostrarMenu` usaba `ECX` y `EDX` para llamar a Irvine32 sin declararlos como registros preservados. | Se declaró `MostrarMenu PROC USES ECX EDX`. | Conserva los valores del llamador; `EAX` queda fuera de `USES` porque devuelve la longitud leída. MASM genera el prólogo y epílogo correspondientes. |

### Fragmentos representativos

**Procedimiento reutilizado — `src/Papeleria.asm`:**

```asm
ObtenerDireccionProducto PROC USES ECX, indiceProducto:DWORD
    mov ECX, indiceProducto
    imul ECX, TYPE Producto
    mov EAX, OFFSET arregloProductos
    add EAX, ECX
    ret
ObtenerDireccionProducto ENDP

; Ejemplos de uso
invoke ObtenerDireccionProducto, indiceProducto
mov ESI, EAX
```

El procedimiento recibe un índice y devuelve en `EAX` la dirección del producto. Preserva `ECX`; el registro de retorno `EAX` no está en `USES`. Se reutiliza en más de una operación del catálogo.

**Macro y puntos de uso — `src/Papeleria.asm`:**

```asm
MostrarTexto MACRO direccion
    mov EDX, direccion
    call WriteString
ENDM

; En MostrarMenu y en los mensajes de validación/resultado
MostrarTexto OFFSET mensajeTitulo
MostrarTexto OFFSET mensajeMenu1
MostrarTexto OFFSET mensajeInvalido
```

La macro recibe la dirección de una cadena o buffer. No contiene etiquetas internas, por lo que no requiere `LOCAL`.

**Procedimiento con `USES` — `src/Papeleria.asm`:**

```asm
MostrarMenu PROC USES ECX EDX
    ; ...mostrar opciones...
    mov EDX, OFFSET opcionMenu
    mov ECX, SIZEOF opcionMenu
    call ReadString
    ret
MostrarMenu ENDP
```

`ReadString` entrega la longitud en `EAX`; este registro no se preserva para que el resultado llegue al llamador. `ECX` y `EDX` se restauran al salir.

### Comparación de líneas de código fuente

Con el mismo criterio en ambas versiones, se contaron las líneas no vacías que no son comentarios del archivo `src/Papeleria.asm`; cada invocación de macro cuenta como una línea fuente, no como sus instrucciones expandidas.

| Versión | Líneas fuente |
| --- | ---: |
| Unidad 2, antes de estos cambios | 1227 |
| Unidad 3, después de estos cambios | 1167 |
| Diferencia | 60 menos (4.9%) |

Dejaron de escribirse repetidamente las dos instrucciones de salida de cadenas y los bloques de cálculo de direcciones de producto. Las expansiones de `MostrarTexto` permanecen en el código ensamblado en cada punto de uso, por lo que la reducción corresponde al fuente, no necesariamente al ejecutable.

### Pruebas de Unidad 3

Según la ejecución confirmada, se completaron todos los casos de [la tabla de pruebas](tabla_pruebas.md) con los resultados esperados: registro y búsqueda, entradas de mercancía, ventas aceptadas y rechazadas, resumen, guardado/carga y la regla adicional del descuento.

## Fuentes consultadas

- Medina Jiménez, José Luis. *Lenguajes de Interfaz, Unidad 2*. Presentación del curso, agosto-diciembre de 2026.
- Irvine Library Help. *Irvine Library Help* [documentación en línea]. Página principal: [https://csc.csudh.edu/mmccullough/asm/help/](https://csc.csudh.edu/mmccullough/asm/help/). Se usó como referencia para las rutinas de Irvine32 empleadas en el programa: [ReadString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readstring.htm), [WriteString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writestring.htm), [WriteChar](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writechar.htm), [Crlf](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/crlf.htm), [CreateOutputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/createoutputfile.htm), [OpenInputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/openinputfile.htm), [ReadFromFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readfromfile.htm), [WriteToFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writetofile.htm) y [CloseFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/closefile.htm).

La ayuda de Irvine documenta esas rutinas de entrada, salida y archivos; el formato delimitado del catálogo, la estructura de productos y las validaciones específicas son decisiones de diseño de este proyecto.
