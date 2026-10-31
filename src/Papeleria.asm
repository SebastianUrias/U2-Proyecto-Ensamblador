;===========================================================
; Proyecto: Sistema de ventas e inventario para papeleria
; Curso: Lenguajes de Interfaz - Unidad 2
; Descripcion: base de codigo MASM x86 con registro de inventario,
; ventas y menu de control para una papeleria.
;===========================================================

INCLUDE Irvine32.inc

MAX_PRODUCTOS = 10
LONGITUD_MAX_NOMBRE = 25
LONGITUD_MAX_CODIGO = 8
TAMANO_BUFFER_ARCHIVO = 4096
EXISTENCIA_MAXIMA = 100

Producto STRUCT
    Codigo        BYTE LONGITUD_MAX_CODIGO DUP(0)
    Nombre    BYTE (LONGITUD_MAX_NOMBRE + 1) DUP(0)
    PrecioCentavos  DWORD ?
    Existencia    DWORD ?
Producto ENDS

.data
    rutaInventario   BYTE "data\inventario_papeleria.dat", 0
    rutaRespaldo    BYTE "inventario_papeleria.dat", 0
    arregloProductos    Producto MAX_PRODUCTOS DUP(<>)
    cantidadProductos    DWORD 0
    codigoTemporal        BYTE 16 DUP(0)
    nombreTemporal        BYTE 40 DUP(0)
    entradaTemporal       BYTE 40 DUP(0)
    opcionMenu      BYTE 16 DUP(0)
    bufferEntrada     BYTE 64 DUP(0)
    bufferArchivo      BYTE TAMANO_BUFFER_ARCHIVO DUP(0)
    arregloTemporal    Producto MAX_PRODUCTOS DUP(<>)
    bufferNumero    BYTE 21 DUP(0)
    bufferCentavos  BYTE 3 DUP(0)
    digitosInvertidos   BYTE 20 DUP(0)
    saltoLinea       BYTE 13, 10
    separador       BYTE '|'
    identificadorArchivo      DWORD ?
    errorEntradaSalida         DWORD 0
    cambiosSinGuardar  DWORD 0
    guardadoExitoso   DWORD 0
    cargaExitosa   DWORD 0
    usaRespaldo   DWORD 0
    bytesArchivo       DWORD 0
    cantidadTemporal      DWORD 0
    ingresosTotales    QWORD 0

    mensajeTitulo        BYTE "=== PAPELERIA DEL VALLE ===", 13, 10, 0
    mensajeMenu1        BYTE "1) Registrar producto", 13, 10, 0
    mensajeMenu2        BYTE "2) Mostrar inventario", 13, 10, 0
    mensajeMenu3        BYTE "3) Buscar por codigo", 13, 10, 0
    mensajeMenu4        BYTE "4) Recibir mercancia", 13, 10, 0
    mensajeMenu5        BYTE "5) Vender producto", 13, 10, 0
    mensajeMenu6        BYTE "6) Mostrar resumen", 13, 10, 0
    mensajeMenu7        BYTE "7) Guardar catalogo", 13, 10, 0
    mensajeMenu8        BYTE "8) Cargar catalogo", 13, 10, 0
    mensajeMenu9        BYTE "9) Regla de negocio", 13, 10, 0
    mensajeMenu0        BYTE "0) Salir", 13, 10, 0
    preguntaMenu      BYTE "Seleccione una opcion: ", 0
    preguntaCodigo      BYTE "Codigo (ABC-123): ", 0
    preguntaNombre      BYTE "Nombre del producto: ", 0
    preguntaPrecio     BYTE "Precio en MXN (ej. 185.50): ", 0
    preguntaCantidad       BYTE "Cantidad: ", 0
    mensajeInvalido      BYTE "Entrada invalida. Intente otra vez.", 13, 10, 0
    mensajeRegistrado      BYTE "Producto registrado correctamente.", 13, 10, 0
    mensajeMercanciaRecibida BYTE "Mercancia recibida correctamente.", 13, 10, 0
    mensajeDuplicado    BYTE "Codigo duplicado.", 13, 10, 0
    mensajeNoEncontrado     BYTE "Producto no encontrado.", 13, 10, 0
    mensajeGuardado        BYTE "Catalogo guardado correctamente.", 13, 10, 0
    mensajeCargado       BYTE "Catalogo cargado correctamente.", 13, 10, 0
    mensajeResumen      BYTE "Resumen general:", 13, 10, 0
    mensajeRegla         BYTE "Regla del negocio: descuento del 10% en compras de 5 o mas unidades.", 13, 10, 0
    mensajeSalida         BYTE "Gracias por usar la papeleria.", 13, 10, 0
    mensajeSinProductos   BYTE "No hay productos registrados.", 13, 10, 0
    mensajeInventarioLleno         BYTE "El inventario ya tiene 10 productos.", 13, 10, 0
    mensajeCodigoInvalido  BYTE "Codigo invalido. Use el formato ABC-123.", 13, 10, 0
    mensajePrecioInvalido BYTE "Precio invalido. Use un valor mayor que cero, por ejemplo 185.50.", 13, 10, 0
    mensajeCantidadInvalida   BYTE "Cantidad invalida. Debe estar entre 1 y 100.", 13, 10, 0
    mensajeLimiteExistencia   BYTE "La existencia no puede superar 100 unidades.", 13, 10, 0
    mensajeExistenciaInsuficiente BYTE "No hay existencias suficientes.", 13, 10, 0
    mensajeTotalVenta    BYTE "Total de la venta: $", 0
    mensajeDescuento     BYTE "Se aplico descuento del 10%.", 13, 10, 0
    mensajeSinDescuento   BYTE "No aplica descuento.", 13, 10, 0
    mensajeExistencia        BYTE "Existencias: ", 0
    mensajePrecio        BYTE "Precio: $", 0
    mensajeCantidad     BYTE "Cantidad a procesar: ", 0
    mensajeUnidades        BYTE "Unidades en inventario: ", 0
    mensajeValorInventario        BYTE "Valor del inventario: $", 0
    mensajeIngresos      BYTE "Ingresos de la sesion: $", 0
    mensajeErrorArchivo    BYTE "No se pudo leer o escribir el archivo de inventario.", 13, 10, 0
    mensajeFormatoArchivo   BYTE "El archivo no existe o su formato no es valido.", 13, 10, 0
    mensajeCantidadCargada  BYTE "Productos cargados: ", 0
    mensajeCantidadProductos BYTE "Productos registrados: ", 0
    mensajePreguntaCodigo   BYTE "Codigo a buscar: ", 0
    mensajeCodigoMercancia BYTE "Codigo del producto: ", 0
    mensajeCodigoVenta  BYTE "Codigo del producto a vender: ", 0
    mensajeCambiosSinGuardar      BYTE "Hay cambios sin guardar. Guardar antes de salir? (S/N): ", 0
    mensajeGuardadoCancelado BYTE "No se pudo guardar. El programa seguira abierto.", 13, 10, 0
.code

; Documentacion: Entrada, salida y registros modificados se indican en cada
; procedimiento. MASM genera prologos/epilogos para USES y LOCAL; INVOKE
; prepara las llamadas con parametros y no hay PUSH/POP manuales.
;===========================================================
; Valida el formato ABC-123.
; Entrada: EDX = puntero a la cadena.
; Salida:  AL = 1 si es valido, 0 si es invalido.
; Registros modificados: EAX, EFLAGS; ESI y ECX se preservan con USES.
;===========================================================
EsCodigoValido PROC USES ESI ECX
    mov ESI, EDX
    cmp BYTE PTR [ESI+7], 0
    jne CodigoInvalido

    ; 3 letras iniciales
    mov ECX, 3
VerificarLetras:
    cmp ECX, 0
    je VerificarGuion
    mov AL, [ESI]
    cmp AL, 'A'
    jb CodigoInvalido
    cmp AL, 'Z'
    ja CodigoInvalido
    inc ESI
    dec ECX
    jmp VerificarLetras

VerificarGuion:
    mov AL, [ESI]
    cmp AL, '-'
    jne CodigoInvalido
    inc ESI

    ; 3 digitos finales
    mov ECX, 3
VerificarDigitos:
    cmp ECX, 0
    je CodigoValido
    mov AL, [ESI]
    cmp AL, '0'
    jb CodigoInvalido
    cmp AL, '9'
    ja CodigoInvalido
    inc ESI
    dec ECX
    jmp VerificarDigitos

CodigoValido:
    mov AL, 1
    ret

CodigoInvalido:
    mov AL, 0
    ret
EsCodigoValido ENDP

;===========================================================
; Convierte una cadena con decimales a centavos enteros.
; Acepta 185.50, 12.05, 185, 0.01.
; Entrada: texto = cadena terminada en cero.
; Salida: EAX = centavos; EDX = 1 si es valido, 0 si no.
; Registros modificados: EAX, EDX, EFLAGS; ESI, ECX y EBX se preservan.
;===========================================================
ConvertirPrecioACentavos PROC USES ESI ECX EBX, texto:PTR BYTE
    LOCAL parteEntera:DWORD, fraccion:DWORD, hayPunto:DWORD, digitosDespues:DWORD, digito:DWORD

    mov ESI, texto
    mov parteEntera, 0
    mov fraccion, 0
    mov hayPunto, 0
    mov digitosDespues, 0
    mov digito, 0

BucleLectura:
    mov AL, [ESI]
    cmp AL, 0
    je FinLectura
    cmp AL, '.'
    je PuntoEncontrado
    cmp AL, '0'
    jb PrecioInvalido
    cmp AL, '9'
    ja PrecioInvalido

    movzx EAX, AL
    sub EAX, '0'
    mov digito, EAX
    cmp hayPunto, 0
    jne DigitoFraccion

    mov EAX, parteEntera
    mov ECX, 10
    mul ECX
    test EDX, EDX
    jnz PrecioInvalido
    add EAX, digito
    jc PrecioInvalido
    mov parteEntera, EAX
    jmp SiguienteCaracter

DigitoFraccion:
    cmp digitosDespues, 2
    jae PrecioInvalido
    mov EAX, fraccion
    mov ECX, 10
    mul ECX
    test EDX, EDX
    jnz PrecioInvalido
    add EAX, digito
    mov fraccion, EAX
    inc digitosDespues
    jmp SiguienteCaracter

PuntoEncontrado:
    cmp hayPunto, 0
    jne PrecioInvalido
    mov hayPunto, 1
    jmp SiguienteCaracter

SiguienteCaracter:
    inc ESI
    jmp BucleLectura

FinLectura:
    cmp parteEntera, 0
    jne TieneValor
    cmp digitosDespues, 0
    je PrecioInvalido
TieneValor:
    cmp digitosDespues, 0
    je PrecioSinFraccion
    cmp digitosDespues, 1
    jne VerificarDosDigitos
    mov EAX, fraccion
    mov ECX, 10
    mul ECX
    mov fraccion, EAX
    jmp FormarPrecio

VerificarDosDigitos:
    cmp digitosDespues, 2
    jne PrecioInvalido

FormarPrecio:
    mov EAX, parteEntera
    mov ECX, 100
    mul ECX
    test EDX, EDX
    jnz PrecioInvalido
    add EAX, fraccion
    jc PrecioInvalido
    mov EDX, 1
    ret

PrecioSinFraccion:
    cmp hayPunto, 0
    jne PrecioInvalido
    mov EAX, parteEntera
    mov ECX, 100
    mul ECX
    test EDX, EDX
    jnz PrecioInvalido
    mov EDX, 1
    ret

PrecioInvalido:
    mov EAX, 0
    xor EDX, EDX
    ret
ConvertirPrecioACentavos ENDP

;===========================================================
; Busca un producto por su codigo.
; Entrada: codigo = puntero a codigo terminado en cero.
; Salida: EAX = indice encontrado o -1.
; Registros modificados: EAX, EFLAGS; ESI, EDI, EBX y ECX se preservan.
;===========================================================
BuscarProductoPorCodigo PROC USES ESI EDI EBX ECX, codigo:PTR BYTE
    LOCAL cantidadCaracteres:DWORD
    mov EDI, 0
    mov ECX, cantidadProductos

BucleBusqueda:
    cmp ECX, 0
    je NoEncontrado

    mov EAX, EDI
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    lea ESI, [ESI + Producto.Codigo]

    mov EBX, codigo
    mov cantidadCaracteres, LONGITUD_MAX_CODIGO

BucleComparacion:
    cmp cantidadCaracteres, 0
    je Encontrado
    mov AL, [ESI]
    mov DL, [EBX]
    cmp AL, DL
    jne SiguienteProducto
    cmp AL, 0
    je Encontrado
    inc ESI
    inc EBX
    dec cantidadCaracteres
    jmp BucleComparacion

SiguienteProducto:
    inc EDI
    dec ECX
    jmp BucleBusqueda

Encontrado:
    mov EAX, EDI
    ret

NoEncontrado:
    mov EAX, -1
    ret
BuscarProductoPorCodigo ENDP

;===========================================================
; Muestra el menu principal.
; Entrada: ninguna.
; Salida: opcionMenu contiene la seleccion; EAX = longitud leida.
; Registros modificados: EAX, ECX, EDX, EFLAGS.
;===========================================================
MostrarMenu PROC
    call Crlf
    mov EDX, OFFSET mensajeTitulo
    call WriteString
    mov EDX, OFFSET mensajeMenu1
    call WriteString
    mov EDX, OFFSET mensajeMenu2
    call WriteString
    mov EDX, OFFSET mensajeMenu3
    call WriteString
    mov EDX, OFFSET mensajeMenu4
    call WriteString
    mov EDX, OFFSET mensajeMenu5
    call WriteString
    mov EDX, OFFSET mensajeMenu6
    call WriteString
    mov EDX, OFFSET mensajeMenu7
    call WriteString
    mov EDX, OFFSET mensajeMenu8
    call WriteString
    mov EDX, OFFSET mensajeMenu9
    call WriteString
    mov EDX, OFFSET mensajeMenu0
    call WriteString
    mov EDX, OFFSET preguntaMenu
    call WriteString

    mov EDX, OFFSET opcionMenu
    mov ECX, SIZEOF opcionMenu
    call ReadString
    ret
MostrarMenu ENDP

; Lee una linea y devuelve su longitud en EAX.
; Entrada: pregunta, buffer y longitudMaxima en la pila.
; Salida: EAX = longitud leida; buffer contiene el texto.
; Registros modificados: EAX, EFLAGS; EDX y ECX se preservan.
LeerEntrada PROC USES EDX ECX, pregunta:PTR BYTE, buffer:PTR BYTE, longitudMaxima:DWORD
    mov EDX, pregunta
    call WriteString
    mov EDX, buffer
    mov ECX, longitudMaxima
    call ReadString
    ret
LeerEntrada ENDP

; Convierte una cadena de digitos a DWORD.
; EDX=1 indica exito; EDX=0 indica entrada invalida.
; Entrada: texto y valorMaximo en la pila.
; Salida: EAX = valor; EDX = estado de validacion.
; Registros modificados: EAX, EDX, EFLAGS; EBX, ECX y ESI se preservan.
ConvertirEnteroSinSigno PROC USES EBX ECX ESI, texto:PTR BYTE, valorMaximo:DWORD
    LOCAL valor:DWORD, digito:DWORD, cantidadDigitos:DWORD
    mov ESI, texto
    mov valor, 0
    mov cantidadDigitos, 0

BucleConversionEntero:
    mov AL, [ESI]
    cmp AL, 0
    je FinConversionEntero
    cmp AL, '0'
    jb EnteroInvalido
    cmp AL, '9'
    ja EnteroInvalido
    movzx EAX, AL
    sub EAX, '0'
    mov digito, EAX
    mov EAX, valor
    mov EBX, 10
    mul EBX
    test EDX, EDX
    jnz EnteroInvalido
    add EAX, digito
    jc EnteroInvalido
    cmp EAX, valorMaximo
    ja EnteroInvalido
    mov valor, EAX
    inc cantidadDigitos
    inc ESI
    jmp BucleConversionEntero

FinConversionEntero:
    cmp cantidadDigitos, 0
    je EnteroInvalido
    mov EAX, valor
    mov EDX, 1
    ret

EnteroInvalido:
    xor EAX, EAX
    xor EDX, EDX
    ret
ConvertirEnteroSinSigno ENDP

; Entrada: pregunta y valorMaximo en la pila.
; Salida: EAX = numero valido o -1 si la entrada no cumple.
; Registros modificados: EAX, EDX, EFLAGS.
LeerNumero PROC, pregunta:PTR BYTE, valorMaximo:DWORD
    invoke LeerEntrada, pregunta, ADDR bufferEntrada, SIZEOF bufferEntrada-1
    cmp EAX, 0
    je NumeroInvalido
    invoke ConvertirEnteroSinSigno, ADDR bufferEntrada, valorMaximo
    test EDX, EDX
    jz NumeroInvalido
    ret
NumeroInvalido:
    mov EAX, -1
    ret
LeerNumero ENDP

; Divide el valor de 64 bits EDX:EAX entre 10.
; Devuelve el cociente en EDX:EAX y el residuo en ECX.
; Entrada: dividendo sin signo en EDX:EAX.
; Salida: cociente en EDX:EAX y residuo en ECX.
; Registros modificados: EAX, ECX, EDX, EFLAGS; EBX se preserva.
Dividir64Entre10 PROC USES EBX
    LOCAL parteAlta:DWORD, parteBaja:DWORD, residuo:DWORD
    mov parteAlta, EDX
    mov parteBaja, EAX
    mov EAX, parteAlta
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov parteAlta, EAX
    mov residuo, EDX
    mov EAX, parteBaja
    mov EDX, residuo
    div EBX
    mov parteBaja, EAX
    mov ECX, EDX
    mov EDX, parteAlta
    mov EAX, parteBaja
    ret
Dividir64Entre10 ENDP

; Imprime como decimal sin signo el valor de 64 bits en EDX:EAX.
; Entrada: numero sin signo en EDX:EAX.
; Salida: escribe sus digitos mediante WriteString.
; Registros modificados: EAX, EDX, EFLAGS; EBX, ECX, ESI y EDI se preservan.
EscribirEnteroSinSigno64 PROC USES EBX ECX ESI EDI
    LOCAL parteAlta:DWORD, parteBaja:DWORD, cantidadDigitos:DWORD, residuo:DWORD
    mov parteAlta, EDX
    mov parteBaja, EAX
    mov cantidadDigitos, 0

ConvertirParaEscritura:
    mov EAX, parteAlta
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov parteAlta, EAX
    mov residuo, EDX
    mov EAX, parteBaja
    mov EDX, residuo
    div EBX
    mov parteBaja, EAX
    mov ESI, cantidadDigitos
    mov BYTE PTR digitosInvertidos[ESI], DL
    add BYTE PTR digitosInvertidos[ESI], '0'
    inc cantidadDigitos
    mov EAX, parteAlta
    or EAX, parteBaja
    jnz ConvertirParaEscritura

    mov ECX, cantidadDigitos
    dec ECX
    mov EDI, 0
CopiarDigitosSalida:
    mov AL, digitosInvertidos[ECX]
    mov bufferNumero[EDI], AL
    inc EDI
    dec ECX
    jns CopiarDigitosSalida
    mov BYTE PTR bufferNumero[EDI], 0
    mov EDX, OFFSET bufferNumero
    call WriteString
    ret
EscribirEnteroSinSigno64 ENDP

; Convierte EDX:EAX (centavos) a moneda con dos decimales y la imprime.
; Entrada: importe en centavos sin signo en EDX:EAX.
; Salida: escribe pesos y dos digitos de centavos.
; Registros modificados: EAX, EDX, EFLAGS; EBX se preserva.
EscribirMoneda64 PROC USES EBX
    LOCAL parteAlta:DWORD, parteBaja:DWORD, residuo:DWORD
    LOCAL decenasCentavos:DWORD, unidadesCentavos:DWORD
    mov parteAlta, EDX
    mov parteBaja, EAX
    mov EAX, parteAlta
    xor EDX, EDX
    mov EBX, 100
    div EBX
    mov parteAlta, EAX
    mov residuo, EDX
    mov EAX, parteBaja
    mov EDX, residuo
    div EBX
    mov parteBaja, EAX
    mov residuo, EDX
    mov EDX, parteAlta
    mov EAX, parteBaja
    call EscribirEnteroSinSigno64
    mov AL, '.'
    call WriteChar
    mov EAX, residuo
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov decenasCentavos, EAX
    mov unidadesCentavos, EDX
    mov EAX, decenasCentavos
    add AL, '0'
    mov bufferCentavos[0], AL
    mov EAX, unidadesCentavos
    add AL, '0'
    mov bufferCentavos[1], AL
    mov BYTE PTR bufferCentavos[2], 0
    mov EDX, OFFSET bufferCentavos
    call WriteString
    ret
EscribirMoneda64 ENDP

; Entrada: indiceProducto en la pila.
; Salida: muestra codigo, nombre, precio y existencia.
; Registros modificados: EAX, EDX, EFLAGS; ESI y EBX se preservan.
MostrarProducto PROC USES ESI EBX, indiceProducto:DWORD
    mov EAX, indiceProducto
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EDX, ESI
    call WriteString
    mov AL, ' '
    call WriteChar
    lea EDX, [ESI + Producto.Nombre]
    call WriteString
    mov AL, ' '
    call WriteChar
    mov AL, '$'
    call WriteChar
    mov EAX, [ESI + Producto.PrecioCentavos]
    xor EDX, EDX
    call EscribirMoneda64
    mov AL, ' '
    call WriteChar
    mov EDX, OFFSET mensajeExistencia
    call WriteString
    mov EAX, [ESI + Producto.Existencia]
    call EscribirEnteroSinSigno
    call Crlf
    ret
MostrarProducto ENDP

; Entrada: arregloProductos y cantidadProductos globales.
; Salida: muestra todos los productos o el mensaje de catalogo vacio.
; Registros modificados: EAX, EDX, EFLAGS; ESI se preserva.
MostrarInventario PROC USES ESI
    LOCAL indiceProducto:DWORD
    cmp cantidadProductos, 0
    jne HayProductos
    mov EDX, OFFSET mensajeSinProductos
    call WriteString
    ret
HayProductos:
    mov indiceProducto, 0
BucleMostrarProductos:
    mov EAX, indiceProducto
    cmp EAX, cantidadProductos
    jae FinMostrarInventario
    invoke MostrarProducto, EAX
    inc indiceProducto
    jmp BucleMostrarProductos
FinMostrarInventario:
    ret
MostrarInventario ENDP

; Entrada: datos capturados por consola.
; Salida: puede agregar un producto y marcar cambiosSinGuardar.
; Registros modificados: EAX, ECX, EDX, EFLAGS; ESI, EDI y EBX se preservan.
RegistrarProducto PROC USES ESI EDI EBX
    LOCAL precioCapturado:DWORD, existenciaCapturada:DWORD
    cmp cantidadProductos, MAX_PRODUCTOS
    jb CapturarProducto
    mov EDX, OFFSET mensajeInventarioLleno
    call WriteString
    ret
CapturarProducto:
    invoke LeerEntrada, ADDR preguntaCodigo, ADDR codigoTemporal, SIZEOF codigoTemporal-1
    mov EDX, OFFSET codigoTemporal
    call EsCodigoValido
    cmp AL, 1
    je VerificarDuplicado
    mov EDX, OFFSET mensajeCodigoInvalido
    call WriteString
    ret
VerificarDuplicado:
    invoke BuscarProductoPorCodigo, ADDR codigoTemporal
    cmp EAX, -1
    je CapturarNombre
    mov EDX, OFFSET mensajeDuplicado
    call WriteString
    ret
CapturarNombre:
    invoke LeerEntrada, ADDR preguntaNombre, ADDR nombreTemporal, SIZEOF nombreTemporal-1
    cmp EAX, 0
    je NombreInvalido
    cmp EAX, LONGITUD_MAX_NOMBRE
    ja NombreInvalido
    mov ESI, OFFSET nombreTemporal
VerificarNombre:
    mov AL, [ESI]
    cmp AL, 0
    je NombreAceptado
    cmp AL, '|'
    je NombreInvalido
    inc ESI
    jmp VerificarNombre
NombreAceptado:
    invoke LeerEntrada, ADDR preguntaPrecio, ADDR bufferEntrada, SIZEOF bufferEntrada-1
    cmp EAX, 0
    je PrecioCapturadoInvalido
    invoke ConvertirPrecioACentavos, ADDR bufferEntrada
    test EDX, EDX
    jz PrecioCapturadoInvalido
    cmp EAX, 0
    je PrecioCapturadoInvalido
    mov precioCapturado, EAX
    invoke LeerNumero, ADDR preguntaCantidad, EXISTENCIA_MAXIMA
    cmp EAX, -1
    je ExistenciaCapturadaInvalida
    cmp EAX, 1
    jb ExistenciaCapturadaInvalida
    mov existenciaCapturada, EAX

    mov EAX, cantidadProductos
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    lea EDI, [ESI + Producto.Codigo]
    mov ESI, OFFSET codigoTemporal
    mov ECX, LONGITUD_MAX_CODIGO
    cld
    rep movsb

    mov EAX, cantidadProductos
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    lea EDI, [ESI + Producto.Nombre]
    mov ESI, OFFSET nombreTemporal
    mov ECX, LONGITUD_MAX_NOMBRE+1
    cld
    rep movsb
    mov EAX, cantidadProductos
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EAX, precioCapturado
    mov [ESI + Producto.PrecioCentavos], EAX
    mov EAX, existenciaCapturada
    mov [ESI + Producto.Existencia], EAX
    inc cantidadProductos
    mov cambiosSinGuardar, 1
    mov EDX, OFFSET mensajeRegistrado
    call WriteString
    ret
NombreInvalido:
    mov EDX, OFFSET mensajeInvalido
    call WriteString
    ret
PrecioCapturadoInvalido:
    mov EDX, OFFSET mensajePrecioInvalido
    call WriteString
    ret
ExistenciaCapturadaInvalida:
    mov EDX, OFFSET mensajeCantidadInvalida
    call WriteString
    ret
RegistrarProducto ENDP

; Entrada: pregunta = direccion del mensaje para solicitar el codigo.
; Salida: codigoTemporal contiene el texto; AL = 1 si el formato es valido.
; Registros modificados: EAX, EDX, EFLAGS.
LeerCodigoProducto PROC, pregunta:PTR BYTE
    invoke LeerEntrada, pregunta, ADDR codigoTemporal, SIZEOF codigoTemporal-1
    mov EDX, OFFSET codigoTemporal
    call EsCodigoValido
    ret
LeerCodigoProducto ENDP

; Entrada: productos almacenados en arregloProductos.
; Salida: muestra el producto encontrado o un mensaje de error.
; Registros modificados: EAX, EDX, EFLAGS.
BuscarProducto PROC
    invoke LeerCodigoProducto, ADDR mensajePreguntaCodigo
    cmp AL, 1
    je BuscarCoincidencia
    mov EDX, OFFSET mensajeCodigoInvalido
    call WriteString
    ret
BuscarCoincidencia:
    invoke BuscarProductoPorCodigo, ADDR codigoTemporal
    cmp EAX, -1
    je ProductoNoEncontrado
    invoke MostrarProducto, EAX
    ret
ProductoNoEncontrado:
    mov EDX, OFFSET mensajeNoEncontrado
    call WriteString
    ret
BuscarProducto ENDP

; Entrada: codigo y cantidad ingresados por consola.
; Salida: actualiza la existencia si la operacion es valida.
; Registros modificados: EAX, EDX, EFLAGS; EBX y ESI se preservan.
RecibirMercancia PROC USES EBX ESI
    LOCAL indiceProducto:DWORD, cantidad:DWORD
    invoke LeerCodigoProducto, ADDR mensajeCodigoMercancia
    cmp AL, 1
    je BuscarProductoMercancia
    mov EDX, OFFSET mensajeCodigoInvalido
    call WriteString
    ret
BuscarProductoMercancia:
    invoke BuscarProductoPorCodigo, ADDR codigoTemporal
    cmp EAX, -1
    je ProductoMercanciaNoEncontrado
    mov indiceProducto, EAX
    invoke LeerNumero, ADDR mensajeCantidad, EXISTENCIA_MAXIMA
    cmp EAX, -1
    je CantidadMercanciaInvalida
    cmp EAX, 1
    jb CantidadMercanciaInvalida
    mov cantidad, EAX
    mov EAX, indiceProducto
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EAX, [ESI + Producto.Existencia]
    add EAX, cantidad
    cmp EAX, EXISTENCIA_MAXIMA
    ja LimiteMercanciaExcedido
    mov [ESI + Producto.Existencia], EAX
    mov cambiosSinGuardar, 1
    mov EDX, OFFSET mensajeMercanciaRecibida
    call WriteString
    ret
ProductoMercanciaNoEncontrado:
    mov EDX, OFFSET mensajeNoEncontrado
    call WriteString
    ret
CantidadMercanciaInvalida:
    mov EDX, OFFSET mensajeCantidadInvalida
    call WriteString
    ret
LimiteMercanciaExcedido:
    mov EDX, OFFSET mensajeLimiteExistencia
    call WriteString
    ret
RecibirMercancia ENDP

; Entrada: codigo y cantidad ingresados por consola.
; Salida: actualiza existencias e ingresosTotales si la venta es valida.
; Registros modificados: EAX, EDX, EFLAGS; EBX y ESI se preservan.
VenderProducto PROC USES EBX ESI
    LOCAL indiceProducto:DWORD, cantidad:DWORD, ventaParteBaja:DWORD, ventaParteAlta:DWORD
    invoke LeerCodigoProducto, ADDR mensajeCodigoVenta
    cmp AL, 1
    je BuscarProductoVenta
    mov EDX, OFFSET mensajeCodigoInvalido
    call WriteString
    ret
BuscarProductoVenta:
    invoke BuscarProductoPorCodigo, ADDR codigoTemporal
    cmp EAX, -1
    je ProductoVentaNoEncontrado
    mov indiceProducto, EAX
    invoke LeerNumero, ADDR mensajeCantidad, EXISTENCIA_MAXIMA
    cmp EAX, -1
    je CantidadVentaInvalida
    cmp EAX, 1
    jb CantidadVentaInvalida
    mov cantidad, EAX
    mov EAX, indiceProducto
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EAX, [ESI + Producto.Existencia]
    cmp EAX, cantidad
    jae CalcularVenta
    mov EDX, OFFSET mensajeExistenciaInsuficiente
    call WriteString
    ret
CalcularVenta:
    mov EAX, [ESI + Producto.PrecioCentavos]
    mul cantidad
    mov ventaParteBaja, EAX
    mov ventaParteAlta, EDX
    cmp cantidad, 5
    jb VentaSinDescuento
    mov EAX, ventaParteBaja
    mov EDX, ventaParteAlta
    call Dividir64Entre10
    sub ventaParteBaja, EAX
    sbb ventaParteAlta, EDX
    mov EDX, OFFSET mensajeDescuento
    call WriteString
    jmp ActualizarVenta
VentaSinDescuento:
    mov EDX, OFFSET mensajeSinDescuento
    call WriteString
ActualizarVenta:
    mov EAX, indiceProducto
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EAX, [ESI + Producto.Existencia]
    sub EAX, cantidad
    mov [ESI + Producto.Existencia], EAX
    mov cambiosSinGuardar, 1
    mov EAX, ventaParteBaja
    add DWORD PTR [ingresosTotales], EAX
    mov EAX, ventaParteAlta
    adc DWORD PTR [ingresosTotales+4], EAX
    mov EDX, OFFSET mensajeTotalVenta
    call WriteString
    mov EDX, ventaParteAlta
    mov EAX, ventaParteBaja
    call EscribirMoneda64
    call Crlf
    ret
ProductoVentaNoEncontrado:
    mov EDX, OFFSET mensajeNoEncontrado
    call WriteString
    ret
CantidadVentaInvalida:
    mov EDX, OFFSET mensajeCantidadInvalida
    call WriteString
    ret
VenderProducto ENDP

; Entrada: catalogo e ingresosTotales globales.
; Salida: muestra unidades, valor del inventario e ingresos de sesion.
; Registros modificados: EAX, EDX, ECX, EFLAGS; ESI se preserva.
MostrarResumen PROC USES ESI
    LOCAL unidadesTotales:DWORD, valorParteBaja:DWORD, valorParteAlta:DWORD, indiceProducto:DWORD
    mov unidadesTotales, 0
    mov valorParteBaja, 0
    mov valorParteAlta, 0
    mov indiceProducto, 0
BucleResumen:
    mov EAX, indiceProducto
    cmp EAX, cantidadProductos
    jae FinResumen
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov EAX, [ESI + Producto.Existencia]
    add unidadesTotales, EAX
    mul DWORD PTR [ESI + Producto.PrecioCentavos]
    add valorParteBaja, EAX
    adc valorParteAlta, EDX
    inc indiceProducto
    jmp BucleResumen

FinResumen:
    mov EDX, OFFSET mensajeResumen
    call WriteString
    mov EDX, OFFSET mensajeCantidadProductos
    call WriteString
    mov EAX, cantidadProductos
    xor EDX, EDX
    call EscribirEnteroSinSigno64
    call Crlf
    mov EDX, OFFSET mensajeUnidades
    call WriteString
    mov EAX, unidadesTotales
    call EscribirEnteroSinSigno
    call Crlf
    mov EDX, OFFSET mensajeValorInventario
    call WriteString
    mov EDX, valorParteAlta
    mov EAX, valorParteBaja
    call EscribirMoneda64
    call Crlf
    mov EDX, OFFSET mensajeIngresos
    call WriteString
    mov EDX, DWORD PTR [ingresosTotales+4]
    mov EAX, DWORD PTR [ingresosTotales]
    call EscribirMoneda64
    call Crlf
    ret
MostrarResumen ENDP

; Entrada: texto = cadena terminada en cero.
; Salida: EAX = longitud sin contar el terminador.
; Registros modificados: EAX, EFLAGS; ESI se preserva.
LongitudCadena PROC USES ESI, texto:PTR BYTE
    mov ESI, texto
    xor EAX, EAX
BucleLongitudCadena:
    cmp BYTE PTR [ESI+EAX], 0
    je FinLongitudCadena
    inc EAX
    jmp BucleLongitudCadena
FinLongitudCadena:
    ret
LongitudCadena ENDP

; Entrada: EAX = DWORD sin signo.
; Salida: bufferNumero = cadena decimal terminada en cero; EAX = longitud.
; Registros modificados: EAX, EFLAGS; EBX, ECX, EDX y EDI se preservan.
FormatearEnteroSinSigno PROC USES EBX ECX EDX EDI
    mov ECX, 0
    mov EBX, 10
    cmp EAX, 0
    jne BucleFormatoEntero
    mov BYTE PTR digitosInvertidos[0], '0'
    mov ECX, 1
    jmp CopiarDigitosFormato
BucleFormatoEntero:
    xor EDX, EDX
    div EBX
    add DL, '0'
    mov BYTE PTR digitosInvertidos[ECX], DL
    inc ECX
    test EAX, EAX
    jnz BucleFormatoEntero
CopiarDigitosFormato:
    mov EDI, 0
    dec ECX
BucleCopiaDigitos:
    mov AL, digitosInvertidos[ECX]
    mov bufferNumero[EDI], AL
    inc EDI
    dec ECX
    jns BucleCopiaDigitos
    mov BYTE PTR bufferNumero[EDI], 0
    mov EAX, EDI
    ret
FormatearEnteroSinSigno ENDP

; Entrada: EAX = DWORD sin signo.
; Salida: muestra la conversion decimal propia con WriteString.
; Registros modificados: EAX, EFLAGS; EDX se preserva.
EscribirEnteroSinSigno PROC USES EDX
    call FormatearEnteroSinSigno
    mov EDX, OFFSET bufferNumero
    call WriteString
    ret
EscribirEnteroSinSigno ENDP

; Entrada: bytes = direccion del buffer; cantidadBytes = longitud.
; Salida: marca errorEntradaSalida si no se escribieron todos los bytes.
; Registros modificados: EAX, EFLAGS; ECX y EDX se preservan.
EscribirBytes PROC USES ECX EDX, bytes:PTR BYTE, cantidadBytes:DWORD
    LOCAL bytesEsperados:DWORD
    cmp errorEntradaSalida, 0
    jne FinEscrituraBytes
    mov EAX, cantidadBytes
    mov bytesEsperados, EAX
    mov EAX, identificadorArchivo
    mov EDX, bytes
    mov ECX, bytesEsperados
    call WriteToFile
    cmp EAX, bytesEsperados
    je FinEscrituraBytes
    mov errorEntradaSalida, 1
FinEscrituraBytes:
    ret
EscribirBytes ENDP

; Entrada: arregloProductos y cantidadProductos globales.
; Salida: escribe el catalogo y actualiza guardadoExitoso/cambiosSinGuardar.
; Registros modificados: EAX, ECX, EDX, EFLAGS; ESI se preserva.
GuardarCatalogo PROC USES ESI
    LOCAL indiceProducto:DWORD, direccionProducto:DWORD, longitudTexto:DWORD
    mov guardadoExitoso, 0
    mov usaRespaldo, 0
    mov EDX, OFFSET rutaInventario
    call CreateOutputFile
    cmp EAX, -1
    jne ArchivoGuardadoAbierto
    mov usaRespaldo, 1
    mov EDX, OFFSET rutaRespaldo
    call CreateOutputFile
    cmp EAX, -1
    je ErrorGuardarCatalogo
ArchivoGuardadoAbierto:
    mov identificadorArchivo, EAX
    mov errorEntradaSalida, 0
    mov indiceProducto, 0

BucleGuardarCatalogo:
    mov EAX, indiceProducto
    cmp EAX, cantidadProductos
    jae CerrarCatalogoGuardado
    imul EAX, TYPE Producto
    mov ESI, OFFSET arregloProductos
    add ESI, EAX
    mov direccionProducto, ESI
    invoke EscribirBytes, ESI, 7
    invoke EscribirBytes, ADDR separador, 1
    lea EAX, [ESI + Producto.Nombre]
    invoke LongitudCadena, EAX
    mov longitudTexto, EAX
    mov EAX, direccionProducto
    lea EAX, [EAX + Producto.Nombre]
    invoke EscribirBytes, EAX, longitudTexto
    invoke EscribirBytes, ADDR separador, 1

    mov EAX, direccionProducto
    mov EAX, [EAX + Producto.PrecioCentavos]
    invoke FormatearEnteroSinSigno
    invoke EscribirBytes, ADDR bufferNumero, EAX
    invoke EscribirBytes, ADDR separador, 1

    mov EAX, direccionProducto
    mov EAX, [EAX + Producto.Existencia]
    invoke FormatearEnteroSinSigno
    invoke EscribirBytes, ADDR bufferNumero, EAX
    invoke EscribirBytes, ADDR saltoLinea, SIZEOF saltoLinea
    inc indiceProducto
    jmp BucleGuardarCatalogo

CerrarCatalogoGuardado:
    mov EAX, identificadorArchivo
    call CloseFile
    cmp errorEntradaSalida, 0
    jne ErrorGuardarCatalogo
    mov guardadoExitoso, 1
    mov cambiosSinGuardar, 0
    mov EDX, OFFSET mensajeGuardado
    call WriteString
    ret
ErrorGuardarCatalogo:
    mov EDX, OFFSET mensajeErrorArchivo
    call WriteString
    ret
GuardarCatalogo ENDP

; Entrada: archivo de catalogo en la ruta principal o de respaldo.
; Salida: reemplaza el catalogo solo despues de validar todas sus filas.
; Registros modificados: EAX, ECX, EDX, EFLAGS; ESI, EDI y EBX se preservan.
CargarCatalogo PROC USES ESI EDI EBX
    LOCAL inicioLinea:DWORD, siguienteLinea:DWORD, inicioCampo:DWORD
    LOCAL direccionProducto:DWORD, longitudCampo:DWORD, precioCargado:DWORD, existenciaCargada:DWORD
    LOCAL indiceDuplicado:DWORD

    mov cargaExitosa, 0
    mov EDX, OFFSET rutaInventario
    call OpenInputFile
    cmp EAX, -1
    jne ArchivoCargadoAbierto
    mov EDX, OFFSET rutaRespaldo
    call OpenInputFile
    cmp EAX, -1
    je ErrorCargarCatalogo
ArchivoCargadoAbierto:
    mov identificadorArchivo, EAX
    mov EAX, identificadorArchivo
    mov EDX, OFFSET bufferArchivo
    mov ECX, TAMANO_BUFFER_ARCHIVO-1
    call ReadFromFile
    jc ErrorLecturaCatalogo
    cmp EAX, TAMANO_BUFFER_ARCHIVO-1
    jae ErrorLecturaCatalogo
    mov bytesArchivo, EAX
    mov BYTE PTR bufferArchivo[EAX], 0
    mov cantidadTemporal, 0
    mov ESI, OFFSET bufferArchivo

SiguienteLineaCatalogo:
    cmp BYTE PTR [ESI], 0
    je ConfirmarCargaCatalogo
    cmp BYTE PTR [ESI], 13
    je OmitirSaltoLinea
    cmp BYTE PTR [ESI], 10
    je OmitirSaltoLinea
    mov inicioLinea, ESI
    mov EBX, ESI
BuscarFinLinea:
    cmp BYTE PTR [EBX], 0
    je FinLineaEncontrado
    cmp BYTE PTR [EBX], 13
    je FinLineaEncontrado
    cmp BYTE PTR [EBX], 10
    je FinLineaEncontrado
    inc EBX
    jmp BuscarFinLinea
FinLineaEncontrado:
    cmp BYTE PTR [EBX], 0
    je UltimaLineaCatalogo
    mov EAX, EBX
    inc EAX
    cmp BYTE PTR [EBX], 13
    jne VerificarSaltoLinea
    cmp BYTE PTR [EAX], 10
    jne GuardarSiguienteLinea
    inc EAX
    jmp GuardarSiguienteLinea
VerificarSaltoLinea:
    cmp BYTE PTR [EBX], 10
    jne GuardarSiguienteLinea
GuardarSiguienteLinea:
    mov siguienteLinea, EAX
    mov BYTE PTR [EBX], 0
    jmp AnalizarLineaCatalogo
UltimaLineaCatalogo:
    mov siguienteLinea, EBX
    mov BYTE PTR [EBX], 0
AnalizarLineaCatalogo:
    cmp cantidadTemporal, MAX_PRODUCTOS
    jae CatalogoInvalido

    mov ESI, inicioLinea
    mov inicioCampo, ESI
FinCampoCodigo:
    cmp BYTE PTR [ESI], '|'
    je CodigoEncontrado
    cmp BYTE PTR [ESI], 0
    je CatalogoInvalido
    inc ESI
    jmp FinCampoCodigo
CodigoEncontrado:
    mov EAX, ESI
    sub EAX, inicioCampo
    cmp EAX, 7
    jne CatalogoInvalido
    mov BYTE PTR [ESI], 0
    mov EDX, inicioCampo
    call EsCodigoValido
    cmp AL, 1
    jne CatalogoInvalido
    mov indiceDuplicado, 0
VerificarCodigoDuplicado:
    mov EAX, indiceDuplicado
    cmp EAX, cantidadTemporal
    jae CodigoUnico
    imul EAX, TYPE Producto
    mov EDI, OFFSET arregloTemporal
    add EDI, EAX
    lea EDI, [EDI + Producto.Codigo]
    mov EBX, inicioCampo
    mov ECX, LONGITUD_MAX_CODIGO
CompararCodigoDuplicado:
    mov AL, [EBX]
    mov DL, [EDI]
    cmp AL, DL
    jne SiguienteDuplicado
    inc EBX
    inc EDI
    loop CompararCodigoDuplicado
    jmp CatalogoInvalido
SiguienteDuplicado:
    inc indiceDuplicado
    jmp VerificarCodigoDuplicado
CodigoUnico:
    inc ESI
    mov EAX, cantidadTemporal
    imul EAX, TYPE Producto
    mov EDI, OFFSET arregloTemporal
    add EDI, EAX
    mov direccionProducto, EDI
    mov EBX, inicioCampo
    mov ECX, LONGITUD_MAX_CODIGO
CopiarCodigo:
    mov AL, [EBX]
    mov [EDI], AL
    inc EBX
    inc EDI
    loop CopiarCodigo

    mov inicioCampo, ESI
FinCampoNombre:
    cmp BYTE PTR [ESI], '|'
    je NombreEncontrado
    cmp BYTE PTR [ESI], 0
    je CatalogoInvalido
    inc ESI
    jmp FinCampoNombre
NombreEncontrado:
    mov BYTE PTR [ESI], 0
    mov EAX, ESI
    sub EAX, inicioCampo
    cmp EAX, 1
    jb CatalogoInvalido
    cmp EAX, LONGITUD_MAX_NOMBRE
    ja CatalogoInvalido
    mov longitudCampo, EAX
    inc ESI
    mov EDI, direccionProducto
    add EDI, Producto.Nombre
    mov EBX, inicioCampo
    mov ECX, longitudCampo
CopiarNombre:
    mov AL, [EBX]
    mov [EDI], AL
    inc EBX
    inc EDI
    loop CopiarNombre
    mov BYTE PTR [EDI], 0

    mov inicioCampo, ESI
FinCampoPrecio:
    cmp BYTE PTR [ESI], '|'
    je PrecioEncontrado
    cmp BYTE PTR [ESI], 0
    je CatalogoInvalido
    inc ESI
    jmp FinCampoPrecio
PrecioEncontrado:
    mov BYTE PTR [ESI], 0
    invoke ConvertirEnteroSinSigno, inicioCampo, -1
    test EDX, EDX
    jz CatalogoInvalido
    cmp EAX, 0
    je CatalogoInvalido
    mov precioCargado, EAX
    inc ESI

    mov inicioCampo, ESI
    invoke ConvertirEnteroSinSigno, inicioCampo, EXISTENCIA_MAXIMA
    test EDX, EDX
    jz CatalogoInvalido
    mov existenciaCargada, EAX
    mov EDI, direccionProducto
    mov EAX, precioCargado
    mov [EDI + Producto.PrecioCentavos], EAX
    mov EAX, existenciaCargada
    mov [EDI + Producto.Existencia], EAX
    inc cantidadTemporal
    mov ESI, siguienteLinea
    jmp SiguienteLineaCatalogo

OmitirSaltoLinea:
    inc ESI
    jmp SiguienteLineaCatalogo

ConfirmarCargaCatalogo:
    mov EAX, cantidadTemporal
    mov cantidadProductos, EAX
    mov cambiosSinGuardar, 0
    mov cargaExitosa, 1
    imul EAX, TYPE Producto
    mov ECX, EAX
    mov ESI, OFFSET arregloTemporal
    mov EDI, OFFSET arregloProductos
    cld
    rep movsb
    mov EAX, identificadorArchivo
    call CloseFile
    mov EDX, OFFSET mensajeCantidadCargada
    call WriteString
    mov EAX, cantidadProductos
    call EscribirEnteroSinSigno
    call Crlf
    mov EDX, OFFSET mensajeCargado
    call WriteString
    ret

ErrorLecturaCatalogo:
    mov EAX, identificadorArchivo
    call CloseFile
ErrorCargarCatalogo:
    mov EDX, OFFSET mensajeFormatoArchivo
    call WriteString
    ret
CatalogoInvalido:
    mov EAX, identificadorArchivo
    call CloseFile
    mov EDX, OFFSET mensajeFormatoArchivo
    call WriteString
    ret
CargarCatalogo ENDP

;===========================================================
; Programa principal.
; Entrada: ninguna.
; Salida: ejecuta el menu hasta confirmar la salida.
; Registros modificados: EAX, ECX, EDX, EFLAGS.
;===========================================================
principal PROC
    call CargarCatalogo

BucleMenu:
    call MostrarMenu
    cmp BYTE PTR opcionMenu[1], 0
    jne OpcionMenuInvalida
    mov AL, opcionMenu
    cmp AL, '0'
    je SalirPrograma
    cmp AL, '1'
    je OpcionRegistrarProducto
    cmp AL, '2'
    je OpcionMostrarInventario
    cmp AL, '3'
    je OpcionBuscarProducto
    cmp AL, '4'
    je OpcionRecibirMercancia
    cmp AL, '5'
    je OpcionVenderProducto
    cmp AL, '6'
    je OpcionMostrarResumen
    cmp AL, '7'
    je OpcionGuardarCatalogo
    cmp AL, '8'
    je OpcionCargarCatalogo
    cmp AL, '9'
    je OpcionMostrarRegla

OpcionMenuInvalida:
    mov EDX, OFFSET mensajeInvalido
    call WriteString
    jmp BucleMenu

OpcionRegistrarProducto:
    call RegistrarProducto
    jmp BucleMenu
OpcionMostrarInventario:
    call MostrarInventario
    jmp BucleMenu
OpcionBuscarProducto:
    call BuscarProducto
    jmp BucleMenu
OpcionRecibirMercancia:
    call RecibirMercancia
    jmp BucleMenu
OpcionVenderProducto:
    call VenderProducto
    jmp BucleMenu
OpcionMostrarResumen:
    call MostrarResumen
    jmp BucleMenu
OpcionGuardarCatalogo:
    call GuardarCatalogo
    jmp BucleMenu
OpcionCargarCatalogo:
    call CargarCatalogo
    jmp BucleMenu
OpcionMostrarRegla:
    mov EDX, OFFSET mensajeRegla
    call WriteString
    jmp BucleMenu

SalirPrograma:
    cmp cambiosSinGuardar, 0
    je SalirSinAdvertencia
    mov EDX, OFFSET mensajeCambiosSinGuardar
    call WriteString
    mov EDX, OFFSET opcionMenu
    mov ECX, SIZEOF opcionMenu
    call ReadString
    cmp BYTE PTR opcionMenu[1], 0
    jne RespuestaSalidaInvalida
    mov AL, opcionMenu
    cmp AL, 'S'
    je GuardarCambiosSalida
    cmp AL, 's'
    je GuardarCambiosSalida
    cmp AL, 'N'
    je SalirSinAdvertencia
    cmp AL, 'n'
    je SalirSinAdvertencia
RespuestaSalidaInvalida:
    mov EDX, OFFSET mensajeInvalido
    call WriteString
    jmp BucleMenu
GuardarCambiosSalida:
    call GuardarCatalogo
    cmp guardadoExitoso, 1
    jne FalloGuardadoSalida
    jmp SalirSinAdvertencia
FalloGuardadoSalida:
    mov EDX, OFFSET mensajeGuardadoCancelado
    call WriteString
    jmp BucleMenu
SalirSinAdvertencia:
    mov EDX, OFFSET mensajeSalida
    call WriteString
    exit
principal ENDP

END principal
