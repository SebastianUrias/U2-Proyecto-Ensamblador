# Tabla de pruebas

La columna de Unidad 2 conserva el resultado anotado previamente. Según la ejecución confirmada, todos los casos de Unidad 3 se completaron y produjeron el resultado esperado.

| Caso | Entrada | Resultado esperado | Resultado registrado en Unidad 2 | Resultado obtenido en Unidad 3 |
| --- | --- | --- | --- | --- |
| Alta válida | `JKL-012`, `Goma`, `12.50`, `8` | Producto aceptado | Completada | Completada: resultado esperado |
| Alta duplicada | `ABC-123` | Rechazo por código duplicado | Apareció el error esperado | Completada: rechazo esperado |
| Código inválido | `AB-12` | Rechazo con mensaje de validación | Apareció el error esperado | Completada: rechazo esperado |
| Límite del catálogo | Registrar más de 10 productos | Rechazo al intentar registrar el producto 11 | Pendiente | Completada: rechazo esperado |
| Búsqueda | `DEF-456` | Producto y datos encontrados | Completada | Completada: producto encontrado |
| Recibir mercancía | Agregar existencias hasta 100 | Actualiza inventario | Completada | Completada: inventario actualizado |
| Entrada excesiva | Agregar cantidad que supere 100 | Rechazo sin cambiar existencias | Completada | Completada: rechazo sin cambios |
| Venta sin descuento | `ABC-123`, `3` | Total normal y disminuye stock | Completada | Completada: venta aceptada |
| Venta con descuento | `ABC-123`, `5` | 10% de descuento y disminuye stock | Completada | Completada: venta aceptada con descuento |
| Venta rechazada | `GHI-789`, `999` | Rechazo por existencias insuficientes | Completada | Completada: rechazo esperado |
| Resumen | Ejecutar resumen | Muestra unidades, valor e ingresos de sesión | Completado | Completada: resumen mostrado |
| Guardado y carga | Guardar, modificar y cargar catálogo | Recupera datos del archivo delimitado | Completado | Completada: catálogo recuperado |
| Regla del negocio | Mostrar regla; vender 5 unidades del mismo producto | Informa descuento de 10% y aplica el descuento de venta | Reportado en la lógica de Unidad 2 | Completada: regla y descuento verificados |
