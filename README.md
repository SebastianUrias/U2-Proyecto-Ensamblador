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

- `Papeleria.sln` y `Papeleria.vcxproj`: solución Win32 para Visual Studio 2022 con MASM.
- `src\Papeleria.asm`: aplicación principal MASM x86.
- `data\inventario_papeleria.dat`: catálogo de ejemplo y archivo de persistencia del ASM.
- `docs\informe.md` y `docs\tabla_pruebas.md`: documentación y casos de prueba.

## Compilar y ejecutar

Se requiere Visual Studio 2022 con la carga de trabajo **Desarrollo para el escritorio con C++** (incluye las herramientas de MASM) y la biblioteca Irvine32 de 32 bits.

1. Instala Irvine32 y asegúrate de que `Irvine32.inc` e `Irvine32.lib` estén en la misma carpeta. El proyecto usa `C:\Irvine` como ruta predeterminada.
2. Si Irvine32 está en otra carpeta, define la variable de entorno `IRVINE32_DIR` con esa ruta antes de abrir Visual Studio.
3. Abre `Papeleria.sln`, selecciona la plataforma `Win32` y compila la solución.
4. Ejecuta el proyecto desde Visual Studio. El directorio de trabajo está configurado en la raíz del proyecto para que encuentre `data\inventario_papeleria.dat`.

Los ejecutables y archivos intermedios se generan en `build\Win32\Debug` o `build\Win32\Release`.

Al iniciar, el programa intenta cargar el catálogo guardado; si no encuentra un archivo válido, comienza con el catálogo vacío. Cada guardado escribe un solo archivo y muestra un solo mensaje de confirmación. Las opciones del menú aceptan una línea y requieren Enter; no se necesita una tecla adicional después de mostrar el resultado.

## Formato del catálogo ASM

Cada línea contiene los campos `codigo|nombre|precio_en_centavos|existencia`. Por ejemplo:

```text
ABC-123|Cuaderno profesional|25000|30
```

El programa guarda y carga este formato delimitado. Los nombres no pueden contener `|`. Primero intenta usar `data\inventario_papeleria.dat`; si esa ruta no se abre desde el directorio de trabajo, usa `inventario_papeleria.dat` en el directorio actual. Al salir con cambios pendientes, solicita confirmación y ofrece guardarlos; si el guardado falla, mantiene el programa abierto.
