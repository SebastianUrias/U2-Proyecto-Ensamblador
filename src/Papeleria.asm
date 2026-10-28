;===========================================================
; Proyecto: Sistema de ventas e inventario para papelería
; Curso: Lenguajes de Interfaz - Unidad 2
; Descripción: base de código MASM x86 con registro de inventario,
; ventas y menú de control para una papelería.
;===========================================================

INCLUDE Irvine32.inc

MAX_PRODUCTS = 10
MAX_NAME_LEN = 25
MAX_CODE_LEN = 8
FILE_BUFFER_SIZE = 4096
MAX_STOCK = 100

Product STRUCT
    Code        BYTE MAX_CODE_LEN DUP(0)
    ProdName    BYTE (MAX_NAME_LEN + 1) DUP(0)
    PriceCents  DWORD ?
    Quantity    DWORD ?
Product ENDS

.data
    inventoryFile   BYTE "data\inventario_papeleria.dat", 0
    fallbackFile    BYTE "inventario_papeleria.dat", 0
    productArray    Product MAX_PRODUCTS DUP(<>)
    productCount    DWORD 0
    tempCode        BYTE 16 DUP(0)
    tempName        BYTE 40 DUP(0)
    tempEntry       BYTE 40 DUP(0)
    menuChoice      BYTE 16 DUP(0)
    inputBuffer     BYTE 64 DUP(0)
    fileBuffer      BYTE FILE_BUFFER_SIZE DUP(0)
    stagingArray    Product MAX_PRODUCTS DUP(<>)
    numberBuffer    BYTE 12 DUP(0)
    reverseDigits   BYTE 20 DUP(0)
    lineBreak       BYTE 13, 10
    separator       BYTE '|'
    fileHandle      DWORD ?
    ioError         DWORD 0
    unsavedChanges  DWORD 0
    saveSucceeded   DWORD 0
    loadSucceeded   DWORD 0
    usingFallback   DWORD 0
    fileBytes       DWORD 0
    stageCount      DWORD 0
    totalRevenue    QWORD 0

    msgTitle        BYTE "=== PAPELERIA DEL VALLE ===", 13, 10, 0
    msgMenu1        BYTE "1) Registrar producto", 13, 10, 0
    msgMenu2        BYTE "2) Mostrar inventario", 13, 10, 0
    msgMenu3        BYTE "3) Buscar por codigo", 13, 10, 0
    msgMenu4        BYTE "4) Recibir mercancia", 13, 10, 0
    msgMenu5        BYTE "5) Vender producto", 13, 10, 0
    msgMenu6        BYTE "6) Mostrar resumen", 13, 10, 0
    msgMenu7        BYTE "7) Guardar catalogo", 13, 10, 0
    msgMenu8        BYTE "8) Cargar catalogo", 13, 10, 0
    msgMenu9        BYTE "9) Regla de negocio", 13, 10, 0
    msgMenu0        BYTE "0) Salir", 13, 10, 0
    promptMenu      BYTE "Seleccione una opcion: ", 0
    promptCode      BYTE "Codigo (ABC-123): ", 0
    promptName      BYTE "Nombre del producto: ", 0
    promptPrice     BYTE "Precio en MXN (ej. 185.50): ", 0
    promptQty       BYTE "Cantidad: ", 0
    msgInvalid      BYTE "Entrada invalida. Intente otra vez.", 13, 10, 0
    msgCreated      BYTE "Producto registrado correctamente.", 13, 10, 0
    msgStockReceived BYTE "Mercancia recibida correctamente.", 13, 10, 0
    msgDuplicate    BYTE "Codigo duplicado.", 13, 10, 0
    msgNotFound     BYTE "Producto no encontrado.", 13, 10, 0
    msgSaved        BYTE "Catalogo guardado correctamente.", 13, 10, 0
    msgLoaded       BYTE "Catalogo cargado correctamente.", 13, 10, 0
    msgSummary      BYTE "Resumen general:", 13, 10, 0
    msgRule         BYTE "Regla del negocio: descuento del 10% en compras de 5 o mas unidades.", 13, 10, 0
    msgExit         BYTE "Gracias por usar la papeleria.", 13, 10, 0
    msgDemo         BYTE "Catalogo inicial cargado.", 13, 10, 0
    msgNoProducts   BYTE "No hay productos registrados.", 13, 10, 0
    msgFull         BYTE "El inventario ya tiene 10 productos.", 13, 10, 0
    msgInvalidCode  BYTE "Codigo invalido. Use el formato ABC-123.", 13, 10, 0
    msgInvalidPrice BYTE "Precio invalido. Use un valor mayor que cero, por ejemplo 185.50.", 13, 10, 0
    msgInvalidQty   BYTE "Cantidad invalida. Debe estar entre 1 y 100.", 13, 10, 0
    msgStockLimit   BYTE "La existencia no puede superar 100 unidades.", 13, 10, 0
    msgInsufficient BYTE "No hay existencias suficientes.", 13, 10, 0
    msgSaleTotal    BYTE "Total de la venta: $", 0
    msgDiscount     BYTE "Se aplico descuento del 10%.", 13, 10, 0
    msgNoDiscount   BYTE "No aplica descuento.", 13, 10, 0
    msgStock        BYTE "Existencias: ", 0
    msgPrice        BYTE "Precio: $", 0
    msgQuantity     BYTE "Cantidad a procesar: ", 0
    msgUnits        BYTE "Unidades en inventario: ", 0
    msgValue        BYTE "Valor del inventario: $", 0
    msgRevenue      BYTE "Ingresos de la sesion: $", 0
    msgFileError    BYTE "No se pudo leer o escribir el archivo de inventario.", 13, 10, 0
    msgFileFormat   BYTE "El archivo no existe o su formato no es valido.", 13, 10, 0
    msgLoadedCount  BYTE "Productos cargados: ", 0
    msgProductCount BYTE "Productos registrados: ", 0
    msgCodePrompt   BYTE "Codigo a buscar: ", 0
    msgCodeForStock BYTE "Codigo del producto: ", 0
    msgCodeForSale  BYTE "Codigo del producto a vender: ", 0
    msgUnsaved      BYTE "Hay cambios sin guardar. Guardar antes de salir? (S/N): ", 0
    msgSaveCancelled BYTE "No se pudo guardar. El programa seguira abierto.", 13, 10, 0

.code

;===========================================================
; Valida el formato ABC-123.
; Entrada: EDX = puntero a la cadena.
; Salida:  AL = 1 si es valido, 0 si es invalido.
;===========================================================
IsValidCode PROC USES ESI ECX
    mov ESI, EDX
    cmp BYTE PTR [ESI+7], 0
    jne InvalidCode

    ; 3 letras iniciales
    mov ECX, 3
CheckLetters:
    cmp ECX, 0
    je CheckDash
    mov AL, [ESI]
    cmp AL, 'A'
    jb InvalidCode
    cmp AL, 'Z'
    ja InvalidCode
    inc ESI
    dec ECX
    jmp CheckLetters

CheckDash:
    mov AL, [ESI]
    cmp AL, '-'
    jne InvalidCode
    inc ESI

    ; 3 digitos finales
    mov ECX, 3
CheckDigits:
    cmp ECX, 0
    je ValidCode
    mov AL, [ESI]
    cmp AL, '0'
    jb InvalidCode
    cmp AL, '9'
    ja InvalidCode
    inc ESI
    dec ECX
    jmp CheckDigits

ValidCode:
    mov AL, 1
    ret

InvalidCode:
    mov AL, 0
    ret
IsValidCode ENDP

;===========================================================
; Convierte una cadena con decimales a centavos enteros.
; Acepta 185.50, 12.05, 185, 0.01.
;===========================================================
ParseMoneyToCents PROC USES ESI ECX EBX, pText:PTR BYTE
    LOCAL whole:DWORD, frac:DWORD, sawDot:DWORD, digitsAfter:DWORD, digit:DWORD

    mov ESI, pText
    mov whole, 0
    mov frac, 0
    mov sawDot, 0
    mov digitsAfter, 0
    mov digit, 0

ScanLoop:
    mov AL, [ESI]
    cmp AL, 0
    je FinishScan
    cmp AL, '.'
    je DotFound
    cmp AL, '0'
    jb InvalidMoney
    cmp AL, '9'
    ja InvalidMoney

    movzx EAX, AL
    sub EAX, '0'
    mov digit, EAX
    cmp sawDot, 0
    jne FractionDigit

    mov EAX, whole
    mov ECX, 10
    mul ECX
    test EDX, EDX
    jnz InvalidMoney
    add EAX, digit
    jc InvalidMoney
    mov whole, EAX
    jmp NextChar

FractionDigit:
    cmp digitsAfter, 2
    jae InvalidMoney
    mov EAX, frac
    mov ECX, 10
    mul ECX
    test EDX, EDX
    jnz InvalidMoney
    add EAX, digit
    mov frac, EAX
    inc digitsAfter
    jmp NextChar

DotFound:
    cmp sawDot, 0
    jne InvalidMoney
    mov sawDot, 1
    jmp NextChar

NextChar:
    inc ESI
    jmp ScanLoop

FinishScan:
    cmp whole, 0
    jne HasValue
    cmp digitsAfter, 0
    je InvalidMoney
HasValue:
    cmp digitsAfter, 0
    je MoneyWithoutFraction
    cmp digitsAfter, 1
    jne CheckTwoDigits
    mov EAX, frac
    mov ECX, 10
    mul ECX
    mov frac, EAX
    jmp ComposeMoney

CheckTwoDigits:
    cmp digitsAfter, 2
    jne InvalidMoney

ComposeMoney:
    mov EAX, whole
    mov ECX, 100
    mul ECX
    test EDX, EDX
    jnz InvalidMoney
    add EAX, frac
    jc InvalidMoney
    mov EDX, 1
    ret

MoneyWithoutFraction:
    cmp sawDot, 0
    jne InvalidMoney
    mov EAX, whole
    mov ECX, 100
    mul ECX
    test EDX, EDX
    jnz InvalidMoney
    mov EDX, 1
    ret

InvalidMoney:
    mov EAX, 0
    xor EDX, EDX
    ret
ParseMoneyToCents ENDP

;===========================================================
; Busca un producto por su código.
; Retorna el índice del arreglo si existe, o -1 si no existe.
;===========================================================
FindProductByCode PROC USES ESI EDI EBX ECX, pCode:PTR BYTE
    LOCAL charCount:DWORD
    mov EDI, 0
    mov ECX, productCount

SearchLoop:
    cmp ECX, 0
    je NotFound

    mov EAX, EDI
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    lea ESI, [ESI + Product.Code]

    mov EBX, pCode
    mov charCount, MAX_CODE_LEN

CompareLoop:
    cmp charCount, 0
    je Found
    mov AL, [ESI]
    mov DL, [EBX]
    cmp AL, DL
    jne NextItem
    cmp AL, 0
    je Found
    inc ESI
    inc EBX
    dec charCount
    jmp CompareLoop

NextItem:
    inc EDI
    dec ECX
    jmp SearchLoop

Found:
    mov EAX, EDI
    ret

NotFound:
    mov EAX, -1
    ret
FindProductByCode ENDP

;===========================================================
; Muestra el menú principal.
;===========================================================
DisplayMenu PROC
    call Crlf
    mov EDX, OFFSET msgTitle
    call WriteString
    mov EDX, OFFSET msgMenu1
    call WriteString
    mov EDX, OFFSET msgMenu2
    call WriteString
    mov EDX, OFFSET msgMenu3
    call WriteString
    mov EDX, OFFSET msgMenu4
    call WriteString
    mov EDX, OFFSET msgMenu5
    call WriteString
    mov EDX, OFFSET msgMenu6
    call WriteString
    mov EDX, OFFSET msgMenu7
    call WriteString
    mov EDX, OFFSET msgMenu8
    call WriteString
    mov EDX, OFFSET msgMenu9
    call WriteString
    mov EDX, OFFSET msgMenu0
    call WriteString
    mov EDX, OFFSET promptMenu
    call WriteString

    mov EDX, OFFSET menuChoice
    mov ECX, SIZEOF menuChoice
    call ReadString
    ret
DisplayMenu ENDP

;===========================================================
; Inicializa un catálogo de demostración.
;===========================================================
InitDemoInventory PROC
    mov productCount, 3

    ; Producto 1: ABC-123
    mov ESI, OFFSET productArray
    lea EAX, [ESI + Product.Code]
    mov BYTE PTR [EAX], 'A'
    mov BYTE PTR [EAX+1], 'B'
    mov BYTE PTR [EAX+2], 'C'
    mov BYTE PTR [EAX+3], '-'
    mov BYTE PTR [EAX+4], '1'
    mov BYTE PTR [EAX+5], '2'
    mov BYTE PTR [EAX+6], '3'
    mov BYTE PTR [EAX+7], 0

    lea EAX, [ESI + Product.ProdName]
    mov BYTE PTR [EAX], 'C'
    mov BYTE PTR [EAX+1], 'u'
    mov BYTE PTR [EAX+2], 'a'
    mov BYTE PTR [EAX+3], 'd'
    mov BYTE PTR [EAX+4], 'e'
    mov BYTE PTR [EAX+5], 'r'
    mov BYTE PTR [EAX+6], 'n'
    mov BYTE PTR [EAX+7], 'o'
    mov BYTE PTR [EAX+8], ' '
    mov BYTE PTR [EAX+9], 'p'
    mov BYTE PTR [EAX+10], 'r'
    mov BYTE PTR [EAX+11], 'o'
    mov BYTE PTR [EAX+12], 'f'
    mov BYTE PTR [EAX+13], 'e'
    mov BYTE PTR [EAX+14], 's'
    mov BYTE PTR [EAX+15], 'i'
    mov BYTE PTR [EAX+16], 'o'
    mov BYTE PTR [EAX+17], 'n'
    mov BYTE PTR [EAX+18], 'a'
    mov BYTE PTR [EAX+19], 'l'
    mov BYTE PTR [EAX+20], 0
    mov DWORD PTR [ESI + Product.PriceCents], 25000
    mov DWORD PTR [ESI + Product.Quantity], 30

    ; Producto 2: DEF-456
    add ESI, TYPE Product
    lea EAX, [ESI + Product.Code]
    mov BYTE PTR [EAX], 'D'
    mov BYTE PTR [EAX+1], 'E'
    mov BYTE PTR [EAX+2], 'F'
    mov BYTE PTR [EAX+3], '-'
    mov BYTE PTR [EAX+4], '4'
    mov BYTE PTR [EAX+5], '5'
    mov BYTE PTR [EAX+6], '6'
    mov BYTE PTR [EAX+7], 0

    lea EAX, [ESI + Product.ProdName]
    mov BYTE PTR [EAX], 'P'
    mov BYTE PTR [EAX+1], 'l'
    mov BYTE PTR [EAX+2], 'u'
    mov BYTE PTR [EAX+3], 'm'
    mov BYTE PTR [EAX+4], 'a'
    mov BYTE PTR [EAX+5], ' '
    mov BYTE PTR [EAX+6], 'a'
    mov BYTE PTR [EAX+7], 'z'
    mov BYTE PTR [EAX+8], 'u'
    mov BYTE PTR [EAX+9], 'l'
    mov BYTE PTR [EAX+10], 0
    mov DWORD PTR [ESI + Product.PriceCents], 18000
    mov DWORD PTR [ESI + Product.Quantity], 50

    ; Producto 3: GHI-789
    add ESI, TYPE Product
    lea EAX, [ESI + Product.Code]
    mov BYTE PTR [EAX], 'G'
    mov BYTE PTR [EAX+1], 'H'
    mov BYTE PTR [EAX+2], 'I'
    mov BYTE PTR [EAX+3], '-'
    mov BYTE PTR [EAX+4], '7'
    mov BYTE PTR [EAX+5], '8'
    mov BYTE PTR [EAX+6], '9'
    mov BYTE PTR [EAX+7], 0

    lea EAX, [ESI + Product.ProdName]
    mov BYTE PTR [EAX], 'R'
    mov BYTE PTR [EAX+1], 'e'
    mov BYTE PTR [EAX+2], 's'
    mov BYTE PTR [EAX+3], 'a'
    mov BYTE PTR [EAX+4], 'l'
    mov BYTE PTR [EAX+5], 't'
    mov BYTE PTR [EAX+6], 'a'
    mov BYTE PTR [EAX+7], 'd'
    mov BYTE PTR [EAX+8], 'o'
    mov BYTE PTR [EAX+9], 'r'
    mov BYTE PTR [EAX+10], ' '
    mov BYTE PTR [EAX+11], 'a'
    mov BYTE PTR [EAX+12], 'm'
    mov BYTE PTR [EAX+13], 'a'
    mov BYTE PTR [EAX+14], 'r'
    mov BYTE PTR [EAX+15], 'i'
    mov BYTE PTR [EAX+16], 'l'
    mov BYTE PTR [EAX+17], 'l'
    mov BYTE PTR [EAX+18], 'o'
    mov BYTE PTR [EAX+19], 0
    mov DWORD PTR [ESI + Product.PriceCents], 12000
    mov DWORD PTR [ESI + Product.Quantity], 25

    mov EDX, OFFSET msgDemo
    call WriteString
    ret
InitDemoInventory ENDP

; Lee una linea y devuelve su longitud en EAX.
ReadInput PROC USES EDX ECX, pPrompt:PTR BYTE, pBuffer:PTR BYTE, maxLength:DWORD
    mov EDX, pPrompt
    call WriteString
    mov EDX, pBuffer
    mov ECX, maxLength
    call ReadString
    ret
ReadInput ENDP

; Convierte una cadena de digitos a DWORD.
; EDX=1 indica exito; EDX=0 indica entrada invalida.
ParseUnsigned PROC USES EBX ECX ESI, pText:PTR BYTE, maxValue:DWORD
    LOCAL value:DWORD, digit:DWORD, digitCount:DWORD
    mov ESI, pText
    mov value, 0
    mov digitCount, 0

ParseUnsignedLoop:
    mov AL, [ESI]
    cmp AL, 0
    je ParseUnsignedDone
    cmp AL, '0'
    jb ParseUnsignedInvalid
    cmp AL, '9'
    ja ParseUnsignedInvalid
    movzx EAX, AL
    sub EAX, '0'
    mov digit, EAX
    mov EAX, value
    mov EBX, 10
    mul EBX
    test EDX, EDX
    jnz ParseUnsignedInvalid
    add EAX, digit
    jc ParseUnsignedInvalid
    cmp EAX, maxValue
    ja ParseUnsignedInvalid
    mov value, EAX
    inc digitCount
    inc ESI
    jmp ParseUnsignedLoop

ParseUnsignedDone:
    cmp digitCount, 0
    je ParseUnsignedInvalid
    mov EAX, value
    mov EDX, 1
    ret

ParseUnsignedInvalid:
    xor EAX, EAX
    xor EDX, EDX
    ret
ParseUnsigned ENDP

ReadNumber PROC, pPrompt:PTR BYTE, maxValue:DWORD
    invoke ReadInput, pPrompt, ADDR inputBuffer, SIZEOF inputBuffer-1
    cmp EAX, 0
    je ReadNumberInvalid
    invoke ParseUnsigned, ADDR inputBuffer, maxValue
    test EDX, EDX
    jz ReadNumberInvalid
    ret
ReadNumberInvalid:
    mov EAX, -1
    ret
ReadNumber ENDP

; Divide el valor de 64 bits EDX:EAX entre 10.
; Devuelve el cociente en EDX:EAX y el residuo en ECX.
Divide64By10 PROC USES EBX
    LOCAL highPart:DWORD, lowPart:DWORD, remainder:DWORD
    mov highPart, EDX
    mov lowPart, EAX
    mov EAX, highPart
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov highPart, EAX
    mov remainder, EDX
    mov EAX, lowPart
    mov EDX, remainder
    div EBX
    mov lowPart, EAX
    mov ECX, EDX
    mov EDX, highPart
    mov EAX, lowPart
    ret
Divide64By10 ENDP

; Imprime como decimal sin signo el valor de 64 bits en EDX:EAX.
WriteUnsigned64 PROC USES EBX ECX ESI
    LOCAL highPart:DWORD, lowPart:DWORD, digitCount:DWORD, remainder:DWORD
    mov highPart, EDX
    mov lowPart, EAX
    mov digitCount, 0

WriteUnsignedConvert:
    mov EAX, highPart
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov highPart, EAX
    mov remainder, EDX
    mov EAX, lowPart
    mov EDX, remainder
    div EBX
    mov lowPart, EAX
    mov ESI, digitCount
    mov BYTE PTR reverseDigits[ESI], DL
    add BYTE PTR reverseDigits[ESI], '0'
    inc digitCount
    mov EAX, highPart
    or EAX, lowPart
    jnz WriteUnsignedConvert

WriteUnsignedOutput:
    mov ECX, digitCount
    dec ECX
    mov AL, reverseDigits[ECX]
    call WriteChar
    dec digitCount
    jnz WriteUnsignedOutput
    ret
WriteUnsigned64 ENDP

; Convierte EDX:EAX (centavos) a moneda con dos decimales y la imprime.
WriteCurrency64 PROC USES EBX
    LOCAL highPart:DWORD, lowPart:DWORD, remainder:DWORD
    LOCAL fractionTens:DWORD, fractionUnits:DWORD
    mov highPart, EDX
    mov lowPart, EAX
    mov EAX, highPart
    xor EDX, EDX
    mov EBX, 100
    div EBX
    mov highPart, EAX
    mov remainder, EDX
    mov EAX, lowPart
    mov EDX, remainder
    div EBX
    mov lowPart, EAX
    mov remainder, EDX
    mov EDX, highPart
    mov EAX, lowPart
    call WriteUnsigned64
    mov AL, '.'
    call WriteChar
    mov EAX, remainder
    xor EDX, EDX
    mov EBX, 10
    div EBX
    mov fractionTens, EAX
    mov fractionUnits, EDX
    mov EAX, fractionTens
    add AL, '0'
    call WriteChar
    mov EAX, fractionUnits
    add AL, '0'
    call WriteChar
    ret
WriteCurrency64 ENDP

PrintProduct PROC USES ESI EBX, productIndex:DWORD
    LOCAL fraction:DWORD
    mov EAX, productIndex
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EDX, ESI
    call WriteString
    mov AL, ' '
    call WriteChar
    lea EDX, [ESI + Product.ProdName]
    call WriteString
    mov AL, ' '
    call WriteChar
    mov AL, '$'
    call WriteChar
    mov EAX, [ESI + Product.PriceCents]
    xor EDX, EDX
    mov EBX, 100
    div EBX
    mov fraction, EDX
    call WriteDec
    mov AL, '.'
    call WriteChar
    cmp fraction, 10
    jae PrintProductFraction
    mov AL, '0'
    call WriteChar
PrintProductFraction:
    mov EAX, fraction
    call WriteDec
    mov AL, ' '
    call WriteChar
    mov EDX, OFFSET msgStock
    call WriteString
    mov EAX, [ESI + Product.Quantity]
    call WriteDec
    call Crlf
    ret
PrintProduct ENDP

ShowInventory PROC USES ESI
    LOCAL itemIndex:DWORD
    cmp productCount, 0
    jne ShowInventoryItems
    mov EDX, OFFSET msgNoProducts
    call WriteString
    ret
ShowInventoryItems:
    mov itemIndex, 0
ShowInventoryLoop:
    mov EAX, itemIndex
    cmp EAX, productCount
    jae ShowInventoryDone
    invoke PrintProduct, EAX
    inc itemIndex
    jmp ShowInventoryLoop
ShowInventoryDone:
    ret
ShowInventory ENDP

AddProduct PROC USES ESI EDI EBX
    LOCAL enteredPrice:DWORD, enteredQuantity:DWORD
    cmp productCount, MAX_PRODUCTS
    jb AddProductInput
    mov EDX, OFFSET msgFull
    call WriteString
    ret
AddProductInput:
    invoke ReadInput, ADDR promptCode, ADDR tempCode, SIZEOF tempCode-1
    mov EDX, OFFSET tempCode
    call IsValidCode
    cmp AL, 1
    je AddProductCheckDuplicate
    mov EDX, OFFSET msgInvalidCode
    call WriteString
    ret
AddProductCheckDuplicate:
    invoke FindProductByCode, ADDR tempCode
    cmp EAX, -1
    je AddProductName
    mov EDX, OFFSET msgDuplicate
    call WriteString
    ret
AddProductName:
    invoke ReadInput, ADDR promptName, ADDR tempName, SIZEOF tempName-1
    cmp EAX, 0
    je AddProductInvalidName
    cmp EAX, MAX_NAME_LEN
    ja AddProductInvalidName
    mov ESI, OFFSET tempName
AddProductCheckName:
    mov AL, [ESI]
    cmp AL, 0
    je AddProductNameAccepted
    cmp AL, '|'
    je AddProductInvalidName
    inc ESI
    jmp AddProductCheckName
AddProductNameAccepted:
    invoke ReadInput, ADDR promptPrice, ADDR inputBuffer, SIZEOF inputBuffer-1
    cmp EAX, 0
    je AddProductInvalidPrice
    invoke ParseMoneyToCents, ADDR inputBuffer
    test EDX, EDX
    jz AddProductInvalidPrice
    cmp EAX, 0
    je AddProductInvalidPrice
    mov enteredPrice, EAX
    invoke ReadNumber, ADDR promptQty, MAX_STOCK
    cmp EAX, -1
    je AddProductInvalidQuantity
    cmp EAX, 1
    jb AddProductInvalidQuantity
    mov enteredQuantity, EAX

    mov EAX, productCount
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    lea EDI, [ESI + Product.Code]
    mov ESI, OFFSET tempCode
    mov ECX, MAX_CODE_LEN
    cld
    rep movsb

    mov EAX, productCount
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    lea EDI, [ESI + Product.ProdName]
    mov ESI, OFFSET tempName
    mov ECX, MAX_NAME_LEN+1
    cld
    rep movsb
    mov EAX, productCount
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EAX, enteredPrice
    mov [ESI + Product.PriceCents], EAX
    mov EAX, enteredQuantity
    mov [ESI + Product.Quantity], EAX
    inc productCount
    mov unsavedChanges, 1
    mov EDX, OFFSET msgCreated
    call WriteString
    ret
AddProductInvalidName:
    mov EDX, OFFSET msgInvalid
    call WriteString
    ret
AddProductInvalidPrice:
    mov EDX, OFFSET msgInvalidPrice
    call WriteString
    ret
AddProductInvalidQuantity:
    mov EDX, OFFSET msgInvalidQty
    call WriteString
    ret
AddProduct ENDP

ReadProductCode PROC, pPrompt:PTR BYTE
    invoke ReadInput, pPrompt, ADDR tempCode, SIZEOF tempCode-1
    mov EDX, OFFSET tempCode
    call IsValidCode
    ret
ReadProductCode ENDP

SearchProduct PROC
    invoke ReadProductCode, ADDR msgCodePrompt
    cmp AL, 1
    je SearchProductFind
    mov EDX, OFFSET msgInvalidCode
    call WriteString
    ret
SearchProductFind:
    invoke FindProductByCode, ADDR tempCode
    cmp EAX, -1
    je SearchProductMissing
    invoke PrintProduct, EAX
    ret
SearchProductMissing:
    mov EDX, OFFSET msgNotFound
    call WriteString
    ret
SearchProduct ENDP

ReceiveStock PROC USES EBX ESI
    LOCAL productIndex:DWORD, amount:DWORD
    invoke ReadProductCode, ADDR msgCodeForStock
    cmp AL, 1
    je ReceiveStockFind
    mov EDX, OFFSET msgInvalidCode
    call WriteString
    ret
ReceiveStockFind:
    invoke FindProductByCode, ADDR tempCode
    cmp EAX, -1
    je ReceiveStockMissing
    mov productIndex, EAX
    invoke ReadNumber, ADDR msgQuantity, MAX_STOCK
    cmp EAX, -1
    je ReceiveStockInvalid
    cmp EAX, 1
    jb ReceiveStockInvalid
    mov amount, EAX
    mov EAX, productIndex
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EAX, [ESI + Product.Quantity]
    add EAX, amount
    cmp EAX, MAX_STOCK
    ja ReceiveStockLimit
    mov [ESI + Product.Quantity], EAX
    mov unsavedChanges, 1
    mov EDX, OFFSET msgStockReceived
    call WriteString
    ret
ReceiveStockMissing:
    mov EDX, OFFSET msgNotFound
    call WriteString
    ret
ReceiveStockInvalid:
    mov EDX, OFFSET msgInvalidQty
    call WriteString
    ret
ReceiveStockLimit:
    mov EDX, OFFSET msgStockLimit
    call WriteString
    ret
ReceiveStock ENDP

SellProduct PROC USES EBX ESI
    LOCAL productIndex:DWORD, amount:DWORD, saleLow:DWORD, saleHigh:DWORD
    invoke ReadProductCode, ADDR msgCodeForSale
    cmp AL, 1
    je SellProductFind
    mov EDX, OFFSET msgInvalidCode
    call WriteString
    ret
SellProductFind:
    invoke FindProductByCode, ADDR tempCode
    cmp EAX, -1
    je SellProductMissing
    mov productIndex, EAX
    invoke ReadNumber, ADDR msgQuantity, MAX_STOCK
    cmp EAX, -1
    je SellProductInvalid
    cmp EAX, 1
    jb SellProductInvalid
    mov amount, EAX
    mov EAX, productIndex
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EAX, [ESI + Product.Quantity]
    cmp EAX, amount
    jae SellProductCalculate
    mov EDX, OFFSET msgInsufficient
    call WriteString
    ret
SellProductCalculate:
    mov EAX, [ESI + Product.PriceCents]
    mul amount
    mov saleLow, EAX
    mov saleHigh, EDX
    cmp amount, 5
    jb SellProductNoDiscount
    mov EAX, saleLow
    mov EDX, saleHigh
    call Divide64By10
    sub saleLow, EAX
    sbb saleHigh, EDX
    mov EDX, OFFSET msgDiscount
    call WriteString
    jmp SellProductUpdate
SellProductNoDiscount:
    mov EDX, OFFSET msgNoDiscount
    call WriteString
SellProductUpdate:
    mov EAX, productIndex
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EAX, [ESI + Product.Quantity]
    sub EAX, amount
    mov [ESI + Product.Quantity], EAX
    mov unsavedChanges, 1
    mov EAX, saleLow
    add DWORD PTR [totalRevenue], EAX
    mov EAX, saleHigh
    adc DWORD PTR [totalRevenue+4], EAX
    mov EDX, OFFSET msgSaleTotal
    call WriteString
    mov EDX, saleHigh
    mov EAX, saleLow
    call WriteCurrency64
    call Crlf
    ret
SellProductMissing:
    mov EDX, OFFSET msgNotFound
    call WriteString
    ret
SellProductInvalid:
    mov EDX, OFFSET msgInvalidQty
    call WriteString
    ret
SellProduct ENDP

ShowSummary PROC USES ESI
    LOCAL totalUnits:DWORD, valueLow:DWORD, valueHigh:DWORD, itemIndex:DWORD
    mov totalUnits, 0
    mov valueLow, 0
    mov valueHigh, 0
    mov itemIndex, 0
SummaryLoop:
    mov EAX, itemIndex
    cmp EAX, productCount
    jae SummaryFinished
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov EAX, [ESI + Product.Quantity]
    add totalUnits, EAX
    mul DWORD PTR [ESI + Product.PriceCents]
    add valueLow, EAX
    adc valueHigh, EDX
    inc itemIndex
    jmp SummaryLoop

SummaryFinished:
    mov EDX, OFFSET msgSummary
    call WriteString
    mov EDX, OFFSET msgProductCount
    call WriteString
    mov EAX, productCount
    xor EDX, EDX
    call WriteUnsigned64
    call Crlf
    mov EDX, OFFSET msgUnits
    call WriteString
    mov EAX, totalUnits
    call WriteDec
    call Crlf
    mov EDX, OFFSET msgValue
    call WriteString
    mov EDX, valueHigh
    mov EAX, valueLow
    call WriteCurrency64
    call Crlf
    mov EDX, OFFSET msgRevenue
    call WriteString
    mov EDX, DWORD PTR [totalRevenue+4]
    mov EAX, DWORD PTR [totalRevenue]
    call WriteCurrency64
    call Crlf
    ret
ShowSummary ENDP

StringLength PROC USES ESI, pText:PTR BYTE
    mov ESI, pText
    xor EAX, EAX
StringLengthLoop:
    cmp BYTE PTR [ESI+EAX], 0
    je StringLengthDone
    inc EAX
    jmp StringLengthLoop
StringLengthDone:
    ret
StringLength ENDP

; Convierte EAX a decimal terminado en cero en numberBuffer.
FormatUnsigned PROC USES EBX ECX EDX EDI
    mov ECX, 0
    mov EBX, 10
    cmp EAX, 0
    jne FormatUnsignedLoop
    mov BYTE PTR reverseDigits[0], '0'
    mov ECX, 1
    jmp FormatUnsignedCopy
FormatUnsignedLoop:
    xor EDX, EDX
    div EBX
    add DL, '0'
    mov BYTE PTR reverseDigits[ECX], DL
    inc ECX
    test EAX, EAX
    jnz FormatUnsignedLoop
FormatUnsignedCopy:
    mov EDI, 0
    dec ECX
FormatUnsignedCopyLoop:
    mov AL, reverseDigits[ECX]
    mov numberBuffer[EDI], AL
    inc EDI
    dec ECX
    jns FormatUnsignedCopyLoop
    mov BYTE PTR numberBuffer[EDI], 0
    mov EAX, EDI
    ret
FormatUnsigned ENDP

WriteBytes PROC USES ECX EDX, pBytes:PTR BYTE, byteCount:DWORD
    LOCAL expectedBytes:DWORD
    cmp ioError, 0
    jne WriteBytesDone
    mov EAX, byteCount
    mov expectedBytes, EAX
    mov EAX, fileHandle
    mov EDX, pBytes
    mov ECX, expectedBytes
    call WriteToFile
    cmp EAX, expectedBytes
    je WriteBytesDone
    mov ioError, 1
WriteBytesDone:
    ret
WriteBytes ENDP

SaveCatalog PROC USES ESI
    LOCAL itemIndex:DWORD, itemAddress:DWORD, textLength:DWORD
    mov saveSucceeded, 0
    mov usingFallback, 0
    mov EDX, OFFSET inventoryFile
    call CreateOutputFile
    cmp EAX, -1
    jne SaveCatalogOpened
    mov usingFallback, 1
    mov EDX, OFFSET fallbackFile
    call CreateOutputFile
    cmp EAX, -1
    je SaveCatalogError
SaveCatalogOpened:
    mov fileHandle, EAX
    mov ioError, 0
    mov itemIndex, 0

SaveCatalogLoop:
    mov EAX, itemIndex
    cmp EAX, productCount
    jae SaveCatalogClose
    imul EAX, TYPE Product
    mov ESI, OFFSET productArray
    add ESI, EAX
    mov itemAddress, ESI
    invoke WriteBytes, ESI, 7
    invoke WriteBytes, ADDR separator, 1
    lea EAX, [ESI + Product.ProdName]
    invoke StringLength, EAX
    mov textLength, EAX
    mov EAX, itemAddress
    lea EAX, [EAX + Product.ProdName]
    invoke WriteBytes, EAX, textLength
    invoke WriteBytes, ADDR separator, 1

    mov EAX, itemAddress
    mov EAX, [EAX + Product.PriceCents]
    invoke FormatUnsigned
    invoke WriteBytes, ADDR numberBuffer, EAX
    invoke WriteBytes, ADDR separator, 1

    mov EAX, itemAddress
    mov EAX, [EAX + Product.Quantity]
    invoke FormatUnsigned
    invoke WriteBytes, ADDR numberBuffer, EAX
    invoke WriteBytes, ADDR lineBreak, SIZEOF lineBreak
    inc itemIndex
    jmp SaveCatalogLoop

SaveCatalogClose:
    mov EAX, fileHandle
    call CloseFile
    cmp ioError, 0
    jne SaveCatalogError
    mov saveSucceeded, 1
    mov unsavedChanges, 0
    mov EDX, OFFSET msgSaved
    call WriteString
    ret
SaveCatalogError:
    mov EDX, OFFSET msgFileError
    call WriteString
    ret
SaveCatalog ENDP

LoadCatalog PROC USES ESI EDI EBX
    LOCAL lineStart:DWORD, nextLine:DWORD, fieldStart:DWORD
    LOCAL itemAddress:DWORD, fieldLength:DWORD, loadedPrice:DWORD, loadedQuantity:DWORD
    LOCAL duplicateIndex:DWORD

    mov loadSucceeded, 0
    mov EDX, OFFSET inventoryFile
    call OpenInputFile
    cmp EAX, -1
    jne LoadCatalogOpened
    mov EDX, OFFSET fallbackFile
    call OpenInputFile
    cmp EAX, -1
    je LoadCatalogError
LoadCatalogOpened:
    mov fileHandle, EAX
    mov EAX, fileHandle
    mov EDX, OFFSET fileBuffer
    mov ECX, FILE_BUFFER_SIZE-1
    call ReadFromFile
    jc LoadCatalogReadError
    cmp EAX, FILE_BUFFER_SIZE-1
    jae LoadCatalogReadError
    mov fileBytes, EAX
    mov BYTE PTR fileBuffer[EAX], 0
    mov stageCount, 0
    mov ESI, OFFSET fileBuffer

LoadCatalogNextLine:
    cmp BYTE PTR [ESI], 0
    je LoadCatalogCommit
    cmp BYTE PTR [ESI], 13
    je LoadCatalogSkipBreak
    cmp BYTE PTR [ESI], 10
    je LoadCatalogSkipBreak
    mov lineStart, ESI
    mov EBX, ESI
LoadCatalogFindLineEnd:
    cmp BYTE PTR [EBX], 0
    je LoadCatalogLineEndFound
    cmp BYTE PTR [EBX], 13
    je LoadCatalogLineEndFound
    cmp BYTE PTR [EBX], 10
    je LoadCatalogLineEndFound
    inc EBX
    jmp LoadCatalogFindLineEnd
LoadCatalogLineEndFound:
    cmp BYTE PTR [EBX], 0
    je LoadCatalogLastLine
    mov EAX, EBX
    inc EAX
    cmp BYTE PTR [EBX], 13
    jne LoadCatalogCheckLF
    cmp BYTE PTR [EAX], 10
    jne LoadCatalogSaveNext
    inc EAX
    jmp LoadCatalogSaveNext
LoadCatalogCheckLF:
    cmp BYTE PTR [EBX], 10
    jne LoadCatalogSaveNext
LoadCatalogSaveNext:
    mov nextLine, EAX
    mov BYTE PTR [EBX], 0
    jmp LoadCatalogParseLine
LoadCatalogLastLine:
    mov nextLine, EBX
    mov BYTE PTR [EBX], 0
LoadCatalogParseLine:
    cmp stageCount, MAX_PRODUCTS
    jae LoadCatalogInvalid

    mov ESI, lineStart
    mov fieldStart, ESI
LoadCatalogCodeEnd:
    cmp BYTE PTR [ESI], '|'
    je LoadCatalogCodeFound
    cmp BYTE PTR [ESI], 0
    je LoadCatalogInvalid
    inc ESI
    jmp LoadCatalogCodeEnd
LoadCatalogCodeFound:
    mov EAX, ESI
    sub EAX, fieldStart
    cmp EAX, 7
    jne LoadCatalogInvalid
    mov BYTE PTR [ESI], 0
    mov EDX, fieldStart
    call IsValidCode
    cmp AL, 1
    jne LoadCatalogInvalid
    mov duplicateIndex, 0
LoadCatalogCheckDuplicate:
    mov EAX, duplicateIndex
    cmp EAX, stageCount
    jae LoadCatalogCodeUnique
    imul EAX, TYPE Product
    mov EDI, OFFSET stagingArray
    add EDI, EAX
    lea EDI, [EDI + Product.Code]
    mov EBX, fieldStart
    mov ECX, MAX_CODE_LEN
LoadCatalogCompareDuplicate:
    mov AL, [EBX]
    mov DL, [EDI]
    cmp AL, DL
    jne LoadCatalogNextDuplicate
    inc EBX
    inc EDI
    loop LoadCatalogCompareDuplicate
    jmp LoadCatalogInvalid
LoadCatalogNextDuplicate:
    inc duplicateIndex
    jmp LoadCatalogCheckDuplicate
LoadCatalogCodeUnique:
    inc ESI
    mov EAX, stageCount
    imul EAX, TYPE Product
    mov EDI, OFFSET stagingArray
    add EDI, EAX
    mov itemAddress, EDI
    mov EBX, fieldStart
    mov ECX, MAX_CODE_LEN
LoadCatalogCopyCode:
    mov AL, [EBX]
    mov [EDI], AL
    inc EBX
    inc EDI
    loop LoadCatalogCopyCode

    mov fieldStart, ESI
LoadCatalogNameEnd:
    cmp BYTE PTR [ESI], '|'
    je LoadCatalogNameFound
    cmp BYTE PTR [ESI], 0
    je LoadCatalogInvalid
    inc ESI
    jmp LoadCatalogNameEnd
LoadCatalogNameFound:
    mov BYTE PTR [ESI], 0
    mov EAX, ESI
    sub EAX, fieldStart
    cmp EAX, 1
    jb LoadCatalogInvalid
    cmp EAX, MAX_NAME_LEN
    ja LoadCatalogInvalid
    mov fieldLength, EAX
    inc ESI
    mov EDI, itemAddress
    add EDI, Product.ProdName
    mov EBX, fieldStart
    mov ECX, fieldLength
LoadCatalogCopyName:
    mov AL, [EBX]
    mov [EDI], AL
    inc EBX
    inc EDI
    loop LoadCatalogCopyName
    mov BYTE PTR [EDI], 0

    mov fieldStart, ESI
LoadCatalogPriceEnd:
    cmp BYTE PTR [ESI], '|'
    je LoadCatalogPriceFound
    cmp BYTE PTR [ESI], 0
    je LoadCatalogInvalid
    inc ESI
    jmp LoadCatalogPriceEnd
LoadCatalogPriceFound:
    mov BYTE PTR [ESI], 0
    invoke ParseUnsigned, fieldStart, -1
    test EDX, EDX
    jz LoadCatalogInvalid
    cmp EAX, 0
    je LoadCatalogInvalid
    mov loadedPrice, EAX
    inc ESI

    mov fieldStart, ESI
    invoke ParseUnsigned, fieldStart, MAX_STOCK
    test EDX, EDX
    jz LoadCatalogInvalid
    mov loadedQuantity, EAX
    mov EDI, itemAddress
    mov EAX, loadedPrice
    mov [EDI + Product.PriceCents], EAX
    mov EAX, loadedQuantity
    mov [EDI + Product.Quantity], EAX
    inc stageCount
    mov ESI, nextLine
    jmp LoadCatalogNextLine

LoadCatalogSkipBreak:
    inc ESI
    jmp LoadCatalogNextLine

LoadCatalogCommit:
    mov EAX, stageCount
    mov productCount, EAX
    mov unsavedChanges, 0
    mov loadSucceeded, 1
    imul EAX, TYPE Product
    mov ECX, EAX
    mov ESI, OFFSET stagingArray
    mov EDI, OFFSET productArray
    cld
    rep movsb
    mov EAX, fileHandle
    call CloseFile
    mov EDX, OFFSET msgLoadedCount
    call WriteString
    mov EAX, productCount
    call WriteDec
    call Crlf
    mov EDX, OFFSET msgLoaded
    call WriteString
    ret

LoadCatalogReadError:
    mov EAX, fileHandle
    call CloseFile
LoadCatalogError:
    mov EDX, OFFSET msgFileFormat
    call WriteString
    ret
LoadCatalogInvalid:
    mov EAX, fileHandle
    call CloseFile
    mov EDX, OFFSET msgFileFormat
    call WriteString
    ret
LoadCatalog ENDP

;===========================================================
; Programa principal.
;===========================================================
main PROC
    call InitDemoInventory
    call LoadCatalog

MenuLoop:
    call DisplayMenu
    cmp BYTE PTR menuChoice[1], 0
    jne InvalidMenuChoice
    mov AL, menuChoice
    cmp AL, '0'
    je ExitProgram
    cmp AL, '1'
    je MenuAddProduct
    cmp AL, '2'
    je MenuShowInventory
    cmp AL, '3'
    je MenuSearchProduct
    cmp AL, '4'
    je MenuReceiveStock
    cmp AL, '5'
    je MenuSellProduct
    cmp AL, '6'
    je MenuShowSummary
    cmp AL, '7'
    je MenuSaveCatalog
    cmp AL, '8'
    je MenuLoadCatalog
    cmp AL, '9'
    je MenuShowRule

InvalidMenuChoice:
    mov EDX, OFFSET msgInvalid
    call WriteString
    jmp MenuLoop

MenuAddProduct:
    call AddProduct
    jmp MenuLoop
MenuShowInventory:
    call ShowInventory
    jmp MenuLoop
MenuSearchProduct:
    call SearchProduct
    jmp MenuLoop
MenuReceiveStock:
    call ReceiveStock
    jmp MenuLoop
MenuSellProduct:
    call SellProduct
    jmp MenuLoop
MenuShowSummary:
    call ShowSummary
    jmp MenuLoop
MenuSaveCatalog:
    call SaveCatalog
    jmp MenuLoop
MenuLoadCatalog:
    call LoadCatalog
    jmp MenuLoop
MenuShowRule:
    mov EDX, OFFSET msgRule
    call WriteString
    jmp MenuLoop

ExitProgram:
    cmp unsavedChanges, 0
    je ExitWithoutWarning
    mov EDX, OFFSET msgUnsaved
    call WriteString
    mov EDX, OFFSET menuChoice
    mov ECX, SIZEOF menuChoice
    call ReadString
    cmp BYTE PTR menuChoice[1], 0
    jne ExitInvalidResponse
    mov AL, menuChoice
    cmp AL, 'S'
    je ExitSaveChanges
    cmp AL, 's'
    je ExitSaveChanges
    cmp AL, 'N'
    je ExitWithoutWarning
    cmp AL, 'n'
    je ExitWithoutWarning
ExitInvalidResponse:
    mov EDX, OFFSET msgInvalid
    call WriteString
    jmp MenuLoop
ExitSaveChanges:
    call SaveCatalog
    cmp saveSucceeded, 1
    jne ExitSaveFailed
    jmp ExitWithoutWarning
ExitSaveFailed:
    mov EDX, OFFSET msgSaveCancelled
    call WriteString
    jmp MenuLoop
ExitWithoutWarning:
    mov EDX, OFFSET msgExit
    call WriteString
    exit
main ENDP

END main
