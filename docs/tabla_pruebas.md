# Tabla de pruebas

| Caso | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| Alta valida | `JKL-012`, `Goma`, `12.50`, `8` | Producto aceptado | Pendiente de ejecutar en MASM |
| Alta duplicada | `ABC-123` | Rechazo por código duplicado | Pendiente de ejecutar en MASM |
| Código inválido | `AB-12` | Rechazo con mensaje de validación | Pendiente de ejecutar en MASM |
| Límite del catálogo | Registrar más de 10 productos | Rechazo al intentar registrar el producto 11 | Pendiente de ejecutar en MASM |
| Búsqueda | `DEF-456` | Producto y datos encontrados | Pendiente de ejecutar en MASM |
| Recibir mercancía | Agregar existencias hasta 100 | Actualiza inventario | Pendiente de ejecutar en MASM |
| Entrada excesiva | Agregar cantidad que supere 100 | Rechazo sin cambiar existencias | Pendiente de ejecutar en MASM |
| Venta sin descuento | `ABC-123`, `3` | Total normal y disminuye stock | Pendiente de ejecutar en MASM |
| Venta con descuento | `ABC-123`, `5` | 10% de descuento y disminuye stock | Pendiente de ejecutar en MASM |
| Venta rechazada | `GHI-789`, `999` | Rechazo por existencias insuficientes | Pendiente de ejecutar en MASM |
| Resumen | Ejecutar resumen | Muestra unidades, valor e ingresos de sesión | Pendiente de ejecutar en MASM |
| Guardado y carga | Guardar, modificar y cargar catálogo | Recupera datos del archivo delimitado | Pendiente de ejecutar en MASM |

La compilación y ejecución final debe comprobarse en MASM x86 con Irvine32; esas herramientas no están instaladas en el entorno de edición.
