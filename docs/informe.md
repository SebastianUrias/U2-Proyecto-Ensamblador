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

## Fuentes consultadas

- Medina Jiménez, José Luis. *Lenguajes de Interfaz, Unidad 2*. Presentación del curso, agosto-diciembre de 2026.
- Irvine Library Help. *Irvine Library Help* [documentación en línea]. Página principal: [https://csc.csudh.edu/mmccullough/asm/help/](https://csc.csudh.edu/mmccullough/asm/help/). Se usó como referencia para las rutinas de Irvine32 empleadas en el programa: [ReadString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readstring.htm), [WriteString](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writestring.htm), [WriteChar](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writechar.htm), [Crlf](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/crlf.htm), [CreateOutputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/createoutputfile.htm), [OpenInputFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/openinputfile.htm), [ReadFromFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/readfromfile.htm), [WriteToFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/writetofile.htm) y [CloseFile](https://csc.csudh.edu/mmccullough/asm/help/source/irvinelib/closefile.htm).

La ayuda de Irvine documenta esas rutinas de entrada, salida y archivos; el formato delimitado del catálogo, la estructura de productos y las validaciones específicas son decisiones de diseño de este proyecto.
