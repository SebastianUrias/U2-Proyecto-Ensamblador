# Tabla de pruebas

| Caso | Entrada | Resultado esperado | Resultado obtenido |
| --- | --- | --- | --- |
| Alta valida | `JKL-012`, `Goma`, `12.50`, `8` | Producto aceptado | Completada |
| Alta duplicada | `ABC-123` | Rechazo por código duplicado | Salto el error esperado |
| Código inválido | `AB-12` | Rechazo con mensaje de validación | Salto el error esperado |
| Límite del catálogo | Registrar más de 10 productos | Rechazo al intentar registrar el producto 11 | Pendiente |
| Búsqueda | `DEF-456` | Producto y datos encontrados | Completado con exito |
| Recibir mercancía | Agregar existencias hasta 100 | Actualiza inventario | Completada con exito |
| Entrada excesiva | Agregar cantidad que supere 100 | Rechazo sin cambiar existencias | Completado |
| Venta sin descuento | `ABC-123`, `3` | Total normal y disminuye stock | Completada con exito |
| Venta con descuento | `ABC-123`, `5` | 10% de descuento y disminuye stock | Completada |
| Venta rechazada | `GHI-789`, `999` | Rechazo por existencias insuficientes | Completada con exito |
| Resumen | Ejecutar resumen | Muestra unidades, valor e ingresos de sesión | Completado |
| Guardado y carga | Guardar, modificar y cargar catálogo | Recupera datos del archivo delimitado | Completado |
