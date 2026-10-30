# Proyecto Unidad 2 - Papelería del Valle

Sistema de consola para administrar productos e inventario de una papelería. La entrega principal es el programa en ensamblador MASM x86 con Irvine32; el código Python y sus pruebas son auxiliares para revisar reglas de negocio, no reemplazan el programa ASM.

## Funciones del programa ASM

- Registrar hasta 10 productos con código único `ABC-123`, nombre, precio y existencia inicial.
- Mostrar el inventario y buscar productos por código.
- Recibir mercancía sin superar 100 unidades por producto.
- Vender, validar existencias y aplicar 10% de descuento al vender 5 o más unidades del mismo producto.
- Mostrar unidades, valor del inventario e ingresos de la sesión.
- Guardar y cargar el catálogo.

## Archivos

- `src\Papeleria.asm`: aplicación principal MASM x86.
- `data\inventario_papeleria.dat`: catálogo de ejemplo y archivo de persistencia del ASM.
- `docs\informe.md` y `docs\tabla_pruebas.md`: documentación y casos de prueba.

## Compilar y ejecutar

Se requiere MASM de 32 bits, la biblioteca Irvine32 y la configuración de enlazado indicada por el curso. Agrega `src\Papeleria.asm` al proyecto MASM de Visual Studio, verifica que `Irvine32.inc` e `Irvine32.lib` estén configurados, y compila como aplicación Win32.

Al iniciar, el programa intenta cargar el catálogo guardado; si no encuentra un archivo válido, comienza con el catálogo vacío. Ejecuta el programa con el directorio de trabajo en la raíz del repositorio para que utilice `data\inventario_papeleria.dat`. Si Visual Studio usa otro directorio de trabajo, configura la raíz del repositorio en las propiedades de depuración; de lo contrario, el programa puede usar su archivo de respaldo `inventario_papeleria.dat` en el directorio actual. Cada guardado escribe un solo archivo y muestra un solo mensaje de confirmación. Las opciones del menú aceptan una línea y requieren Enter; no se necesita una tecla adicional después de mostrar el resultado.

## Formato del catálogo ASM

Cada línea contiene los campos `codigo|nombre|precio_en_centavos|existencia`. Por ejemplo:

```text
ABC-123|Cuaderno profesional|25000|30
```

El programa guarda y carga este formato delimitado. Los nombres no pueden contener `|`. Primero intenta usar `data\inventario_papeleria.dat`; si esa ruta no se abre desde el directorio de trabajo, usa `inventario_papeleria.dat` en el directorio actual. Al salir con cambios pendientes, solicita confirmación y ofrece guardarlos; si el guardado falla, mantiene el programa abierto.
