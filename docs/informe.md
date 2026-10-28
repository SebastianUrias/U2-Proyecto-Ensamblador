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

## Formato del archivo de inventario ASM
El catálogo se guarda como texto delimitado. Cada línea contiene código, nombre, precio en centavos y existencias:

```text
ABC-123|Cuaderno profesional|25000|30
```

El archivo de ejemplo está en `data/inventario_papeleria.dat`. El ingreso acumulado se mantiene en memoria durante la sesión y se reinicia al volver a ejecutar el programa.
Si no existe la carpeta `data` desde el directorio de trabajo, el ASM intenta guardar o cargar `inventario_papeleria.dat` en el directorio actual. Al salir después de registrar productos, recibir mercancía o vender, el programa avisa que hay cambios pendientes y ofrece guardarlos.

## Regla de descuento
La venta de cinco o más unidades de un mismo producto aplica un descuento del 10%. El cálculo usa centavos enteros y división entera, por lo que cualquier fracción de centavo se descarta.

## Implementación auxiliar
La referencia Python y sus pruebas sirven únicamente para verificar reglas de negocio. La aplicación del proyecto es `src/Papeleria.asm`.

## Fuentes consultadas
- Especificación de la Unidad 2 de Lenguajes de Interfaz.
- Reglas básicas de validación de cadenas y entrada numérica.
- Prácticas de almacenamiento y lectura de inventarios con formato JSON.
