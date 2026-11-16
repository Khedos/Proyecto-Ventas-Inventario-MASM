; Materia: Lenguajes de Interfaz
; Alumno: Luciano Ivan Villa Zuñiga
; Horario: 8:00 am - 9:00 am
; Docente: Dr. José Luis Medina Jiménez
; Práctica: Proyecto ventas inventario
; Descripción: Sistema de ventas e inventario para un negocio de refacciones de iPhone (versión de la Unidad 3). Usa procedimientos con USES y macros para reducir el código repetido. Registra hasta 10 productos, recibe mercancía, vende con descuento por cantidad, muestra el resumen y guarda/carga el catálogo en inventario.csv.

INCLUDE Irvine32.inc

;==========================================================
;                 MACROS (UNIDAD 3)
; SUSTITUYEN SECUENCIAS CORTAS QUE SE REPETIAN EN EL CODIGO.
; SE DEFINEN AQUI, ANTES DE SU PRIMER USO.
;==========================================================

;----------------------------------------------------------
; mMostrar
; IMPRIME UNA CADENA SIN SALTO DE LINEA.
; RECIBE: texto = VARIABLE CON LA CADENA
; MODIFICA: EDX
;----------------------------------------------------------
mMostrar MACRO texto
    mov edx, OFFSET texto               ; EDX = DIRECCION DE LA CADENA
    call WriteString                    ; IMPRIMIR LA CADENA
ENDM

;----------------------------------------------------------
; mMostrarLn
; IMPRIME UNA CADENA Y UN SALTO DE LINEA.
; RECIBE: texto = VARIABLE CON LA CADENA
; MODIFICA: EDX
;----------------------------------------------------------
mMostrarLn MACRO texto
    mov edx, OFFSET texto               ; EDX = DIRECCION DE LA CADENA
    call WriteString                    ; IMPRIMIR LA CADENA
    call Crlf                           ; SALTO DE LINEA
ENDM

;----------------------------------------------------------
; mError
; IMPRIME UN MENSAJE DE ERROR EN ROJO CON SALTO DE LINEA.
; RECIBE: texto = VARIABLE CON EL MENSAJE
; MODIFICA: EDX
;----------------------------------------------------------
mError MACRO texto
    mov edx, OFFSET texto               ; EDX = DIRECCION DEL MENSAJE
    call mostrarError                   ; IMPRIMIR EN ROJO + SALTO DE LINEA
ENDM

;----------------------------------------------------------
; mRojo
; IMPRIME UN MENSAJE EN ROJO SIN SALTO DE LINEA.
; RECIBE: texto = VARIABLE CON EL MENSAJE
; MODIFICA: EDX
;----------------------------------------------------------
mRojo MACRO texto
    mov edx, OFFSET texto               ; EDX = DIRECCION DEL MENSAJE
    call escribirRojo                   ; IMPRIMIR EN ROJO
ENDM

;----------------------------------------------------------
; mExito
; IMPRIME UN MENSAJE EN VERDE SIN SALTO DE LINEA.
; RECIBE: texto = VARIABLE CON EL MENSAJE
; MODIFICA: EDX
;----------------------------------------------------------
mExito MACRO texto
    mov edx, OFFSET texto               ; EDX = DIRECCION DEL MENSAJE
    call mostrarExito                   ; IMPRIMIR EN VERDE
ENDM

;----------------------------------------------------------
; mColor
; CAMBIA EL COLOR DEL TEXTO DE LA CONSOLA.
; RECIBE: color = COLOR DE TEXTO + (COLOR DE FONDO * 16)
; MODIFICA: EAX
;----------------------------------------------------------
mColor MACRO color
    mov eax, color                      ; EAX = COLOR
    call SetTextColor                   ; APLICAR EL COLOR
ENDM

;----------------------------------------------------------
; mEtiquetaNumero
; IMPRIME UNA ETIQUETA, UN NUMERO Y UN SALTO DE LINEA.
; RECIBE: texto = ETIQUETA, valor = REGISTRO O VARIABLE CON EL NUMERO
; MODIFICA: EAX, EDX
;----------------------------------------------------------
mEtiquetaNumero MACRO texto, valor
    mMostrar texto                      ; ETIQUETA
    mov eax, valor                      ; EAX = NUMERO
    call mostrarNumero                  ; IMPRIMIR EL NUMERO
    call Crlf                           ; SALTO DE LINEA
ENDM

;----------------------------------------------------------
; mEtiquetaImporte
; IMPRIME UNA ETIQUETA, UN IMPORTE EN MXN Y UN SALTO DE LINEA.
; RECIBE: texto = ETIQUETA, valor = REGISTRO O VARIABLE CON LOS CENTAVOS
; MODIFICA: EAX, EDX
;----------------------------------------------------------
mEtiquetaImporte MACRO texto, valor
    mMostrar texto                      ; ETIQUETA
    mov eax, valor                      ; EAX = IMPORTE EN CENTAVOS
    call mostrarImporte                 ; IMPRIMIR "PESOS.CC MXN"
    call Crlf                           ; SALTO DE LINEA
ENDM

;----------------------------------------------------------
; mPonerChar
; ESCRIBE UN CARACTER EN EL BUFFER AL QUE APUNTA EDI Y AVANZA EDI.
; RECIBE: caracter = CONSTANTE (EJ. ',' O 0Dh), EDI = POSICION DE ESCRITURA
; MODIFICA: EDI
;----------------------------------------------------------
mPonerChar MACRO caracter
    mov BYTE PTR [edi], caracter        ; GUARDAR EL CARACTER
    inc edi                             ; SIGUIENTE POSICION
ENDM

;----------------------------------------------------------
; mFueraDeRango
; SALTA A destino SI reg NO ESTA ENTRE minimo Y maximo (SIN SIGNO).
; RECIBE: reg = REGISTRO DE 8 BITS, minimo/maximo = LIMITES, destino = ETIQUETA
; MODIFICA: BANDERAS
;----------------------------------------------------------
mFueraDeRango MACRO reg, minimo, maximo, destino
    cmp reg, minimo
    jb destino                          ; MENOR AL MINIMO
    cmp reg, maximo
    ja destino                          ; MAYOR AL MAXIMO
ENDM

;----------------------------------------------------------
; mExtraerCampoCSV
; COPIA EL SIGUIENTE CAMPO DE LA LINEA A bufferCampo Y REVISA QUE
; TERMINE EN EL DELIMITADOR ESPERADO; SI NO, SALTA A destinoError.
; RECIBE: delimitador = ',' O 0, ESI = POSICION EN LA LINEA, ECX = LONGITUD MAXIMA
; MODIFICA: EAX, ESI, EDI, BANDERAS
;----------------------------------------------------------
mExtraerCampoCSV MACRO delimitador, destinoError
    mov edi, OFFSET bufferCampo         ; DESTINO DEL CAMPO
    call extraerCampo                   ; AL = DELIMITADOR ENCONTRADO
    jc destinoError                     ; CAMPO DEMASIADO LARGO
    cmp al, delimitador
    jne destinoError                    ; FALTAN O SOBRAN CAMPOS
ENDM

;----------------------------------------------------------
; mOpcion
; SI AL ES IGUAL A tecla LLAMA A rutina Y BRINCA A pausaMenu.
; USA LOCAL PORQUE SE EXPANDE 7 VECES EN EL MENU: CADA EXPANSION
; NECESITA SU PROPIA ETIQUETA siguienteOpcion.
; RECIBE: tecla = CARACTER DE LA OPCION, rutina = PROCEDIMIENTO, AL = OPCION CAPTURADA
; MODIFICA: BANDERAS
;----------------------------------------------------------
mOpcion MACRO tecla, rutina
    LOCAL siguienteOpcion
    cmp al, tecla
    jne siguienteOpcion                 ; NO ES ESTA OPCION
    call rutina                         ; EJECUTAR LA OPCION
    jmp pausaMenu                       ; REGRESAR AL MENU
siguienteOpcion:
ENDM

;----------------------------------------------------------
; CONSTANTES DEL NEGOCIO
;----------------------------------------------------------
MAX_PRODUCTOS = 10                  ; CAPACIDAD DEL CATALOGO
LONG_CODIGO = 7                     ; FORMATO ABC-123
MAX_NOMBRE = 25                     ; LONGITUD MAXIMA DEL NOMBRE
PRECIO_MIN = 1                      ; $0.01 EN CENTAVOS
PRECIO_MAX = 999999                 ; $9999.99 EN CENTAVOS
EXIST_MAX = 100                     ; EXISTENCIA MAXIMA POR PRODUCTO
DESC_PIEZAS = 5                     ; REGLA: DESCUENTO DESDE 5 PIEZAS
DESC_PORCENTAJE = 10                ; REGLA: 10% DE DESCUENTO

; ---- COLORES DE LA CONSOLA ----
COLOR_NORMAL = lightGray + (black * 16)
COLOR_ERROR = lightRed + (black * 16)
COLOR_EXITO = lightGreen + (black * 16)

;----------------------------------------------------------
; ORGANIZACION DE CADA PRODUCTO EN MEMORIA (42 BYTES)
; +0  codigo      8 BYTES  (7 CARACTERES + 00h)
; +8  nombre     26 BYTES  (25 CARACTERES + 00h)
; +34 precio      DWORD    (EN CENTAVOS)
; +38 existencia  DWORD    (UNIDADES)
;----------------------------------------------------------
OFS_CODIGO = 0
OFS_NOMBRE = 8
OFS_PRECIO = 34
OFS_EXIST = 38
TAM_PRODUCTO = 42

TAM_ARCHIVO = 2048                  ; CAPACIDAD DEL BUFFER DEL ARCHIVO
MAX_LINEA = 80                      ; LONGITUD MAXIMA DE UNA LINEA DEL CSV
MAX_CAMPO = 31                      ; LONGITUD MAXIMA DE UN CAMPO DEL CSV

.data
; ---- CATALOGO ----
catalogo BYTE (MAX_PRODUCTOS * TAM_PRODUCTO) DUP(0)       ; CATALOGO DE PRODUCTOS
numProductos DWORD 0                                    ; PRODUCTOS REGISTRADOS
catalogoTemp BYTE (MAX_PRODUCTOS * TAM_PRODUCTO) DUP(0)   ; CATALOGO TEMPORAL AL CARGAR EL ARCHIVO
numTemp DWORD 0                                         ; PRODUCTOS LEIDOS DEL ARCHIVO

; ---- DATOS DE LA SESION ----
ingresos DWORD 0                    ; INGRESOS ACUMULADOS EN CENTAVOS
descuentos DWORD 0                  ; DESCUENTOS OTORGADOS EN CENTAVOS
ventasRealizadas DWORD 0            ; CANTIDAD DE VENTAS ACEPTADAS
hayCambios BYTE 0                   ; 1 = HAY CAMBIOS SIN GUARDAR

; ---- PRODUCTO NUEVO (SE LLENA ANTES DE GUARDARLO EN EL CATALOGO) ----
nuevoCodigo BYTE 8 DUP(0)
nuevoNombre BYTE 26 DUP(0)
nuevoPrecio DWORD 0
nuevaExist DWORD 0

; ---- DATOS DE UNA VENTA ----
cantidadVenta DWORD 0
importeBase DWORD 0
descuentoVenta DWORD 0
importeFinal DWORD 0

; ---- BUFFERS ----
bufferEntrada BYTE 64 DUP(0)        ; CAPTURA DEL TECLADO (63 CARACTERES + 00h)
bufferNumero BYTE 32 DUP(0)         ; NUMEROS E IMPORTES CONVERTIDOS A CADENA
bufferArchivo BYTE (TAM_ARCHIVO + 1) DUP(0)  ; CONTENIDO DEL ARCHIVO + 00h
bufferLinea BYTE (MAX_LINEA + 1) DUP(0)      ; UNA LINEA DEL ARCHIVO
bufferCampo BYTE (MAX_CAMPO + 1) DUP(0)      ; UN CAMPO DE LA LINEA

; ---- ARCHIVO ----
nombreArchivo BYTE "inventario.csv", 0
encabezadoCSV BYTE "codigo,nombre,precio,existencia", 0
handleArchivo DWORD 0               ; HANDLE DEL ARCHIVO ABIERTO
longitudArchivo DWORD 0             ; BYTES QUE SE DEBEN ESCRIBIR
bytesEscritos DWORD 0               ; BYTES QUE REGRESO WriteToFile
bytesLeidos DWORD 0                 ; BYTES QUE REGRESO ReadFromFile
resultadoCierre DWORD 0             ; RESULTADO DE CloseFile
lineaArchivo DWORD 0                ; LINEA QUE SE ESTA ANALIZANDO
posArchivo DWORD 0                  ; POSICION DE ESI EN EL ARCHIVO
posLinea DWORD 0                    ; POSICION DE ESI EN LA LINEA
registroTemp DWORD 0                ; DIRECCION DEL REGISTRO TEMPORAL

; ---- MENU ----
msjTitulo BYTE "======== REFACCIONES IPHONE - VENTAS E INVENTARIO ========", 0
msjMenu1 BYTE "1. Registrar producto", 0
msjMenu2 BYTE "2. Mostrar inventario", 0
msjMenu3 BYTE "3. Buscar producto por codigo", 0
msjMenu4 BYTE "4. Recibir mercancia", 0
msjMenu5 BYTE "5. Vender", 0
msjMenu6 BYTE "6. Mostrar resumen", 0
msjMenu7 BYTE "7. Guardar catalogo", 0
msjMenu8 BYTE "8. Cargar catalogo", 0
msjMenu9 BYTE "9. Salir", 0
msjOpcion BYTE "Opcion: ", 0
msjErrOpcion BYTE "Opcion invalida. Escriba un numero del 1 al 9.", 0
msjPausa BYTE "Presione Enter para continuar...", 0

; ---- CAPTURAS ----
msjPideCodigo BYTE "Codigo (ABC-123, Enter para cancelar): ", 0
msjPideNombre BYTE "Nombre (1 a 25 caracteres): ", 0
msjPidePrecio BYTE "Precio en MXN (ej. 185.50): ", 0
msjPideExist BYTE "Existencia inicial (0 a 100): ", 0
msjPideRecibir BYTE "Unidades recibidas: ", 0
msjPideVender BYTE "Unidades a vender: ", 0
msjCancelado BYTE "Operacion cancelada. No se modifico nada.", 0

; ---- ERRORES DE CAPTURA ----
msjErrCodigo BYTE "Codigo invalido: deben ser 3 letras mayusculas, un guion y 3 digitos (ej. PAN-011).", 0
msjErrNombre BYTE "Nombre invalido: 1 a 25 caracteres (letras, numeros, espacios, - y .), sin iniciar con espacio.", 0
msjErrPrecio BYTE "Precio invalido: use 185, 185.5 o 185.50, de 0.01 a 9999.99, sin $, comas ni espacios.", 0
msjErrNumero BYTE "Cantidad invalida: use solo digitos, sin signos ni espacios.", 0
msjErrRango1 BYTE "Cantidad fuera de rango. Debe estar entre ", 0
msjErrRango2 BYTE " y ", 0
msjErrSN BYTE "Respuesta invalida. Escriba S o N.", 0

; ---- REGISTRO Y BUSQUEDA ----
msjLleno BYTE "Registro rechazado: el catalogo ya tiene 10 productos.", 0
msjDuplicado BYTE "Codigo duplicado: ya existe un producto con ese codigo.", 0
msjRegistrado BYTE "Producto registrado correctamente.", 0
msjNoExiste BYTE "No existe un producto con ese codigo.", 0
msjVacio BYTE "El catalogo esta vacio.", 0
msjEncabezado BYTE "No.  CODIGO    NOMBRE                     PRECIO            EXISTENCIA", 0
msjLineaTabla BYTE "---------------------------------------------------------------------", 0
msjTotalProd1 BYTE "Productos registrados: ", 0
msjTotalProd2 BYTE " de 10", 0

; ---- ENTRADAS ----
msjLleno100 BYTE "Entrada rechazada: el producto ya tiene 100 unidades.", 0
msjExcede1 BYTE "Entrada rechazada: la existencia no puede pasar de 100. Puede recibir maximo ", 0
msjExcede2 BYTE " unidades.", 0
msjRecibido BYTE "Mercancia recibida. Nueva existencia: ", 0

; ---- VENTAS ----
msjSinExist BYTE "Venta rechazada: el producto no tiene existencias.", 0
msjInsuf BYTE "Venta rechazada: existencias insuficientes. Disponibles: ", 0
msjDesborde BYTE "Venta rechazada: el calculo produce un desbordamiento.", 0
msjImporteBase BYTE "Importe base:          ", 0
msjDescAplica BYTE "Descuento (10% desde 5 piezas): -", 0
msjDescNoAplica BYTE "Descuento: no aplica (menos de 5 piezas)", 0
msjTotalVenta BYTE "Total de la venta:     ", 0
msjVentaOk BYTE "Venta registrada. Existencia restante: ", 0

; ---- RESUMEN ----
msjResumen BYTE "======================== RESUMEN ========================", 0
msjResUnidades BYTE "Unidades disponibles:              ", 0
msjResValor BYTE "Valor total del inventario:        ", 0
msjResVentas BYTE "Ventas realizadas en la sesion:    ", 0
msjResDesc BYTE "Descuentos otorgados (regla):      ", 0
msjResIngresos BYTE "Ingresos acumulados de la sesion:  ", 0
msjResCambios BYTE "Cambios sin guardar:               ", 0
msjSi BYTE "Si", 0
msjNo BYTE "No", 0
msjMXN BYTE " MXN", 0

; ---- ARCHIVO ----
msjGuardado1 BYTE "Catalogo guardado en inventario.csv (", 0
msjGuardado2 BYTE " productos, ", 0
msjGuardado3 BYTE " bytes).", 0
msjErrCrear BYTE "Error: no se pudo crear inventario.csv.", 0
msjErrEscribir BYTE "Error: no se escribieron todos los bytes en inventario.csv.", 0
msjErrCerrar BYTE "Error: no se pudo cerrar inventario.csv.", 0
msjCargando BYTE "Cargando inventario.csv...", 0
msjNoArchivo BYTE "No se encontro inventario.csv.", 0
msjErrLeer BYTE "Error al leer inventario.csv.", 0
msjMuyGrande BYTE "Archivo invalido: inventario.csv es demasiado grande.", 0
msjInvalido1 BYTE "Archivo invalido: error en la linea ", 0
msjInvalido2 BYTE ". Se conserva el catalogo actual.", 0
msjCargado1 BYTE "Catalogo cargado: ", 0
msjCargado2 BYTE " productos.", 0
msjInicioVacio BYTE "Se inicia con el catalogo vacio.", 0
msjConfirmaCarga BYTE "Hay cambios sin guardar que se perderan. Cargar de todos modos? (S/N): ", 0
msjConfirmaSalir BYTE "Hay cambios sin guardar. Desea guardarlos antes de salir? (S/N): ", 0
msjNoSalir BYTE "No se pudo guardar. Regresando al menu para no perder los cambios.", 0
msjDescartados BYTE "Cambios descartados.", 0
msjAdios BYTE "Fin del programa.", 0


.code
main PROC
    mMostrarLn msjCargando              ; AL INICIAR SE INTENTA CARGAR EL CATALOGO
    call cargarCatalogo                 ; CF = 1 SI NO SE PUDO CARGAR
    jnc menuPrincipal
    mMostrarLn msjInicioVacio           ; SI FALLA SE EMPIEZA CON EL CATALOGO VACIO

    menuPrincipal:
        call mostrarMenu                ; IMPRIMIR LAS OPCIONES
        mov edx, OFFSET msjOpcion
        call leerEntrada                ; EAX = LONGITUD, EDX = bufferEntrada
        call Crlf
        cmp eax, 1
        jne opcionInvalida              ; LA OPCION DEBE SER UN SOLO CARACTER

        mov al, bufferEntrada           ; AL = CARACTER CAPTURADO
        mOpcion '1', registrarProducto  ; CADA OPCION LLAMA A SU PROCEDIMIENTO
        mOpcion '2', mostrarInventario
        mOpcion '3', buscarMenu
        mOpcion '4', recibirMercancia
        mOpcion '5', venderProducto
        mOpcion '6', mostrarResumen
        mOpcion '7', guardarCatalogo
        cmp al, '8'
        je opcion8                      ; CARGAR PIDE CONFIRMACION SI HAY CAMBIOS
        cmp al, '9'
        je opcion9                      ; SALIR PIDE GUARDAR SI HAY CAMBIOS

    opcionInvalida:
        mError msjErrOpcion             ; CUALQUIER OTRA ENTRADA ES INVALIDA
        jmp menuPrincipal

    opcion8:
        cmp hayCambios, 0
        je cargarSinPreguntar           ; SI NO HAY CAMBIOS SE CARGA DIRECTO
        mov edx, OFFSET msjConfirmaCarga
        call confirmar                  ; CF = 0 SI RESPONDE S
        jc pausaMenu
    cargarSinPreguntar:
        call cargarCatalogo
        jmp pausaMenu

    opcion9:
        cmp hayCambios, 0
        je salirPrograma                ; SIN CAMBIOS PENDIENTES SE SALE DIRECTO
        mov edx, OFFSET msjConfirmaSalir
        call confirmar                  ; CF = 0 SI QUIERE GUARDAR
        jc descartar
        call guardarCatalogo            ; CF = 1 SI NO SE PUDO GUARDAR
        jnc salirPrograma
        mError msjNoSalir               ; SI FALLA EL GUARDADO NO SE SALE
        jmp pausaMenu
    descartar:
        mMostrarLn msjDescartados
        jmp salirPrograma

    pausaMenu:
        call pausa                      ; ESPERAR ENTER ANTES DE MOSTRAR EL MENU
        jmp menuPrincipal

    salirPrograma:
        mMostrarLn msjAdios
        exit                            ; TERMINA EL PROGRAMA
main ENDP

;==========================================================
;                 PROCEDIMIENTOS DE PANTALLA
;==========================================================

;----------------------------------------------------------
; mostrarMenu
; IMPRIME EL TITULO Y LAS OPCIONES DEL MENU.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EDX (USES)
;----------------------------------------------------------
mostrarMenu PROC USES edx
    call Crlf
    mMostrarLn msjTitulo
    mMostrarLn msjMenu1
    mMostrarLn msjMenu2
    mMostrarLn msjMenu3
    mMostrarLn msjMenu4
    mMostrarLn msjMenu5
    mMostrarLn msjMenu6
    mMostrarLn msjMenu7
    mMostrarLn msjMenu8
    mMostrarLn msjMenu9
    ret
mostrarMenu ENDP

;----------------------------------------------------------
; leerEntrada
; MUESTRA UN MENSAJE Y CAPTURA UNA CADENA CON ReadString.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: EAX = LONGITUD CAPTURADA, EDX = OFFSET bufferEntrada
; MODIFICA: EAX, EDX (RESULTADOS, FUERA DE USES)
; CONSERVA: ECX (USES)
;----------------------------------------------------------
leerEntrada PROC USES ecx
    call WriteString                    ; MOSTRAR EL MENSAJE
    mov edx, OFFSET bufferEntrada       ; EDX = DIRECCION DEL BUFFER
    mov ecx, SIZEOF bufferEntrada - 1   ; ECX = MAXIMO DE CARACTERES (SE RESERVA 1 BYTE PARA EL 00h)
    call ReadString                     ; EAX = CARACTERES CAPTURADOS, LA CADENA QUEDA EN bufferEntrada
    ret
leerEntrada ENDP

;----------------------------------------------------------
; leerOCancelar (NUEVO EN LA U3)
; CAPTURA UNA CADENA; SI ESTA VACIA AVISA QUE SE CANCELO LA OPERACION.
; ANTES ESTE BLOQUE SE REPETIA EN LOS 4 PROCEDIMIENTOS DE CAPTURA.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: CF = 0: EAX = LONGITUD, EDX = OFFSET bufferEntrada
;          CF = 1: ENTRADA VACIA, OPERACION CANCELADA
; MODIFICA: EAX, EDX
;----------------------------------------------------------
leerOCancelar PROC
    call leerEntrada                    ; EAX = LONGITUD
    cmp eax, 0
    je cancelar                         ; ENTER VACIO = CANCELAR
    clc
    ret
    cancelar:
        mMostrarLn msjCancelado
        stc
        ret
leerOCancelar ENDP

;----------------------------------------------------------
; escribirRojo
; IMPRIME UN MENSAJE DE ERROR EN ROJO (SIN SALTO DE LINEA).
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: NADA
; CONSERVA: EAX (USES)
;----------------------------------------------------------
escribirRojo PROC USES eax
    mColor COLOR_ERROR                  ; TEXTO ROJO
    call WriteString
    mColor COLOR_NORMAL                 ; REGRESAR AL COLOR NORMAL
    ret
escribirRojo ENDP

;----------------------------------------------------------
; mostrarError
; IMPRIME UN MENSAJE DE ERROR EN ROJO Y UN SALTO DE LINEA.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: NADA
; MODIFICA: NADA
;----------------------------------------------------------
mostrarError PROC
    call escribirRojo
    call Crlf
    ret
mostrarError ENDP

;----------------------------------------------------------
; mostrarExito
; IMPRIME UN MENSAJE DE EXITO EN VERDE (SIN SALTO DE LINEA).
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: NADA
; CONSERVA: EAX (USES)
;----------------------------------------------------------
mostrarExito PROC USES eax
    mColor COLOR_EXITO                  ; TEXTO VERDE
    call WriteString
    mColor COLOR_NORMAL                 ; REGRESAR AL COLOR NORMAL
    ret
mostrarExito ENDP

;----------------------------------------------------------
; pausa
; ESPERA A QUE EL USUARIO PRESIONE ENTER.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EDX (USES)
;----------------------------------------------------------
pausa PROC USES eax edx
    call Crlf
    mov edx, OFFSET msjPausa
    call leerEntrada
    ret
pausa ENDP

;----------------------------------------------------------
; confirmar
; HACE UNA PREGUNTA DE SI O NO Y REPITE HASTA RECIBIR S O N.
; RECIBE: EDX = DIRECCION DE LA PREGUNTA
; REGRESA: CF = 0 SI RESPONDIO S, CF = 1 SI RESPONDIO N
; CONSERVA: EAX, EBX, EDX (USES)
;----------------------------------------------------------
confirmar PROC USES eax ebx edx
    mov ebx, edx                        ; GUARDAMOS LA PREGUNTA EN EBX

    preguntar:
        mov edx, ebx
        call leerEntrada                ; EAX = LONGITUD
        cmp eax, 1
        jne respuestaInvalida           ; DEBE SER UN SOLO CARACTER
        mov al, bufferEntrada
        cmp al, 'S'
        je respondioSi
        cmp al, 's'
        je respondioSi
        cmp al, 'N'
        je respondioNo
        cmp al, 'n'
        je respondioNo

    respuestaInvalida:
        mError msjErrSN
        jmp preguntar

    respondioSi:
        clc                             ; CF = 0 (LOS POP DE USES NO CAMBIAN LAS BANDERAS)
        ret
    respondioNo:
        stc                             ; CF = 1
        ret
confirmar ENDP

;==========================================================
;            PROCEDIMIENTOS DE CADENAS Y NUMEROS
;==========================================================

;----------------------------------------------------------
; longitudCadena
; CUENTA LOS CARACTERES DE UNA CADENA TERMINADA EN 00h.
; RECIBE: EDX = DIRECCION DE LA CADENA
; REGRESA: EAX = LONGITUD
; CONSERVA: ESI (USES)
;----------------------------------------------------------
longitudCadena PROC USES esi
    mov esi, edx                        ; ESI RECORRE LA CADENA
    mov eax, 0                          ; CONTADOR = 0

    contar:
        cmp BYTE PTR [esi], 0           ; FIN DE LA CADENA?
        je finContar
        inc eax                         ; UN CARACTER MAS
        inc esi                         ; SIGUIENTE CARACTER
        jmp contar

    finContar:
        ret
longitudCadena ENDP

;----------------------------------------------------------
; copiarCadena
; COPIA UNA CADENA TERMINADA EN 00h (INCLUYE EL 00h).
; RECIBE: EDX = ORIGEN, EDI = DESTINO
; REGRESA: EDI = DIRECCION DEL 00h COPIADO (PARA SEGUIR CONCATENANDO)
; CONSERVA: EAX, ESI (USES)
;----------------------------------------------------------
copiarCadena PROC USES eax esi
    mov esi, edx                        ; ESI RECORRE EL ORIGEN

    copiar:
        mov al, [esi]                   ; CARACTER DEL ORIGEN
        mov [edi], al                   ; SE COPIA AL DESTINO
        cmp al, 0
        je finCopiar                    ; SI ERA EL 00h YA TERMINAMOS
        inc esi
        inc edi
        jmp copiar

    finCopiar:
        ret
copiarCadena ENDP

;----------------------------------------------------------
; compararCadenas
; COMPARA DOS CADENAS TERMINADAS EN 00h.
; RECIBE: EDX = CADENA 1, EDI = CADENA 2
; REGRESA: ZF = 1 SI SON IGUALES, ZF = 0 SI SON DIFERENTES
; CONSERVA: EAX, ESI (USES)
;----------------------------------------------------------
compararCadenas PROC USES eax esi
    mov esi, 0                          ; ESI = INDICE DEL CARACTER

    comparar:
        mov al, [edx + esi]             ; CARACTER DE LA CADENA 1
        cmp al, [edi + esi]             ; SE COMPARA CON LA CADENA 2
        jne finComparar                 ; DIFERENTES: ZF = 0
        cmp al, 0
        je finComparar                  ; AMBAS TERMINARON: ZF = 1
        inc esi
        jmp comparar

    finComparar:
        ret                             ; LOS POP DE USES NO CAMBIAN ZF
compararCadenas ENDP

;----------------------------------------------------------
; escribirColumna
; IMPRIME UNA CADENA Y LA RELLENA CON ESPACIOS HASTA UN ANCHO.
; RECIBE: EDX = DIRECCION DE LA CADENA, ECX = ANCHO DE LA COLUMNA
; REGRESA: NADA
; CONSERVA: EAX (USES)
;----------------------------------------------------------
escribirColumna PROC USES eax
    call WriteString
    call longitudCadena                 ; EAX = CARACTERES YA ESCRITOS

    rellenar:
        cmp eax, ecx
        jae finColumna                  ; YA SE LLEGO AL ANCHO
        push eax
        mov al, ' '
        call WriteChar                  ; ESCRIBIR UN ESPACIO
        pop eax
        inc eax
        jmp rellenar

    finColumna:
        ret
escribirColumna ENDP

;----------------------------------------------------------
; convertirDecimal
; CONVIERTE UN NUMERO SIN SIGNO A CADENA DECIMAL.
; DIVIDE ENTRE 10, GUARDA LOS RESIDUOS EN LA PILA Y LOS SACA
; EN ORDEN INVERSO SUMANDO '0' PARA OBTENER EL ASCII.
; RECIBE: EAX = NUMERO, EDI = DIRECCION DEL BUFFER DESTINO
; REGRESA: EDI = DIRECCION DEL 00h ESCRITO
; CONSERVA: EAX, EBX, ECX, EDX (USES)
;----------------------------------------------------------
convertirDecimal PROC USES eax ebx ecx edx
    mov ebx, 10                         ; DIVISOR
    mov ecx, 0                          ; CONTADOR DE DIGITOS

    extraerDigitos:
        mov edx, 0                      ; EDX = 0 (EDX:EAX ES EL DIVIDENDO)
        div ebx                         ; EAX = COCIENTE, EDX = RESIDUO
        push edx                        ; GUARDAMOS EL DIGITO EN LA PILA
        inc ecx                         ; UN DIGITO MAS
        cmp eax, 0
        jne extraerDigitos              ; SI EL COCIENTE NO ES 0 SEGUIMOS

    construirCadena:
        pop edx                         ; SALE PRIMERO EL DIGITO DE MAYOR VALOR
        add dl, '0'                     ; DIGITO A CARACTER ASCII
        mov [edi], dl                   ; GUARDAMOS EL CARACTER
        inc edi
        loop construirCadena            ; MIENTRAS QUEDEN DIGITOS

    mov BYTE PTR [edi], 0               ; TERMINADOR NULO
    ret
convertirDecimal ENDP

;----------------------------------------------------------
; formatearImporte
; CONVIERTE CENTAVOS A UNA CADENA CON DOS DECIMALES (EJ. 18550 -> 185.50).
; RECIBE: EAX = IMPORTE EN CENTAVOS, EDI = DIRECCION DEL BUFFER DESTINO
; REGRESA: EDI = DIRECCION DEL 00h ESCRITO
; CONSERVA: EAX, EBX, EDX (USES)
;----------------------------------------------------------
formatearImporte PROC USES eax ebx edx
    mov edx, 0                          ; PREPARAR EL DIVIDENDO EDX:EAX
    mov ebx, 100
    div ebx                             ; EAX = PESOS, EDX = CENTAVOS
    call convertirDecimal               ; ESCRIBIR LOS PESOS
    mPonerChar '.'                      ; PUNTO DECIMAL

    mov eax, edx                        ; EAX = CENTAVOS (0 A 99)
    cmp eax, 10
    jae dosDigitos                      ; SI ES 10 O MAS YA TIENE DOS DIGITOS
    mPonerChar '0'                      ; SI ES MENOR A 10 SE AGREGA UN 0 (5 -> 05)

    dosDigitos:
        call convertirDecimal           ; ESCRIBIR LOS CENTAVOS
        ret
formatearImporte ENDP

;----------------------------------------------------------
; mostrarNumero
; IMPRIME UN NUMERO SIN SIGNO (SIN USAR WriteDec).
; RECIBE: EAX = NUMERO
; REGRESA: NADA
; CONSERVA: EDX, EDI (USES)
;----------------------------------------------------------
mostrarNumero PROC USES edx edi
    mov edi, OFFSET bufferNumero
    call convertirDecimal
    mMostrar bufferNumero
    ret
mostrarNumero ENDP

;----------------------------------------------------------
; mostrarImporte
; IMPRIME UN IMPORTE CON DOS DECIMALES Y LA ETIQUETA MXN.
; RECIBE: EAX = IMPORTE EN CENTAVOS
; REGRESA: NADA
; CONSERVA: EDX, EDI (USES)
;----------------------------------------------------------
mostrarImporte PROC USES edx edi
    mov edi, OFFSET bufferNumero
    call formatearImporte               ; bufferNumero = "PESOS.CC"
    mMostrar bufferNumero
    mMostrar msjMXN                     ; " MXN"
    ret
mostrarImporte ENDP

;==========================================================
;                PROCEDIMIENTOS DE VALIDACION
;==========================================================

;----------------------------------------------------------
; validarCodigo
; REVISA EL FORMATO ABC-123: 3 MAYUSCULAS, UN GUION Y 3 DIGITOS.
; RECIBE: EDX = DIRECCION DE LA CADENA
; REGRESA: CF = 0 SI ES VALIDO, CF = 1 SI ES INVALIDO
; CONSERVA: EAX, ECX, ESI (USES)
;----------------------------------------------------------
validarCodigo PROC USES eax ecx esi
    call longitudCadena                 ; EAX = LONGITUD
    cmp eax, LONG_CODIGO
    jne codigoInvalido                  ; DEBE TENER EXACTAMENTE 7 CARACTERES

    mov esi, edx                        ; ESI RECORRE EL CODIGO
    mov ecx, 3                          ; 3 LETRAS
    validarLetras:
        mov al, [esi]
        mFueraDeRango al, 'A', 'Z', codigoInvalido
        inc esi
        loop validarLetras

    cmp BYTE PTR [esi], '-'             ; POSICION 3 DEBE SER EL GUION
    jne codigoInvalido
    inc esi

    mov ecx, 3                          ; 3 DIGITOS
    validarDigitos:
        mov al, [esi]
        mFueraDeRango al, '0', '9', codigoInvalido
        inc esi
        loop validarDigitos

    clc                                 ; CODIGO VALIDO
    ret
    codigoInvalido:
        stc                             ; CODIGO INVALIDO
        ret
validarCodigo ENDP

;----------------------------------------------------------
; validarNombre
; REVISA QUE EL NOMBRE TENGA DE 1 A 25 CARACTERES PERMITIDOS
; (LETRAS, DIGITOS, ESPACIO, GUION Y PUNTO) Y NO INICIE CON ESPACIO.
; RECIBE: EDX = DIRECCION DE LA CADENA
; REGRESA: CF = 0 SI ES VALIDO, CF = 1 SI ES INVALIDO
; CONSERVA: EAX, ESI (USES)
;----------------------------------------------------------
validarNombre PROC USES eax esi
    call longitudCadena                 ; EAX = LONGITUD
    cmp eax, 0
    je nombreInvalido                   ; NO SE ACEPTA VACIO
    cmp eax, MAX_NOMBRE
    ja nombreInvalido                   ; MAXIMO 25 CARACTERES

    mov esi, edx                        ; ESI RECORRE EL NOMBRE
    cmp BYTE PTR [esi], ' '
    je nombreInvalido                   ; NO PUEDE INICIAR CON ESPACIO

    revisarCaracter:
        mov al, [esi]
        cmp al, 0
        je nombreValido                 ; SE REVISARON TODOS
        cmp al, ' '
        je siguienteCaracter
        cmp al, '-'
        je siguienteCaracter
        cmp al, '.'
        je siguienteCaracter
        cmp al, '0'
        jb nombreInvalido
        cmp al, '9'
        jbe siguienteCaracter           ; DIGITO
        cmp al, 'A'
        jb nombreInvalido
        cmp al, 'Z'
        jbe siguienteCaracter           ; MAYUSCULA
        cmp al, 'a'
        jb nombreInvalido
        cmp al, 'z'
        ja nombreInvalido               ; NO ES MINUSCULA
    siguienteCaracter:
        inc esi
        jmp revisarCaracter

    nombreValido:
        clc
        ret
    nombreInvalido:
        stc
        ret
validarNombre ENDP

;----------------------------------------------------------
; convertirEntero
; CONVIERTE UNA CADENA DE DIGITOS A NUMERO (ACUMULADO * 10 + DIGITO).
; RECIBE: EDX = DIRECCION DE LA CADENA
; REGRESA: EAX = NUMERO; CF = 1 SI ESTA VACIA, TIENE OTROS CARACTERES
;          O NO CABE EN 32 BITS
; MODIFICA: EAX (RESULTADO, FUERA DE USES)
; CONSERVA: EBX, ECX, EDX, ESI (USES)
;----------------------------------------------------------
convertirEntero PROC USES ebx ecx edx esi
    mov esi, edx                        ; ESI RECORRE LA CADENA
    cmp BYTE PTR [esi], 0
    je enteroInvalido                   ; CADENA VACIA
    mov eax, 0                          ; ACUMULADO = 0
    mov ecx, 10                         ; MULTIPLICADOR

    siguienteDigito:
        movzx ebx, BYTE PTR [esi]       ; CARACTER ACTUAL
        cmp ebx, 0
        je enteroValido                 ; FIN DE LA CADENA
        mFueraDeRango bl, '0', '9', enteroInvalido
        sub ebx, '0'                    ; ASCII A VALOR (0 A 9)
        mul ecx                         ; EDX:EAX = ACUMULADO * 10
        jc enteroInvalido               ; SI EDX NO ES 0 HUBO DESBORDAMIENTO
        add eax, ebx                    ; ACUMULADO + DIGITO
        jc enteroInvalido               ; ACARREO = DESBORDAMIENTO
        inc esi
        jmp siguienteDigito

    enteroValido:
        clc
        ret
    enteroInvalido:
        stc
        ret
convertirEntero ENDP

;----------------------------------------------------------
; convertirPrecio
; CONVIERTE UN PRECIO EN PESOS A CENTAVOS ENTEROS.
; ACEPTA 1 A 4 DIGITOS ENTEROS Y OPCIONALMENTE UN PUNTO CON 1 O 2
; DECIMALES (185 -> 18500, 185.5 -> 18550, 12.05 -> 1205).
; RECHAZA SIMBOLOS, COMAS, ESPACIOS Y UN TERCER DECIMAL.
; RECIBE: EDX = DIRECCION DE LA CADENA
; REGRESA: EAX = CENTAVOS; CF = 1 SI ES INVALIDO O FUERA DE 0.01 A 9999.99
; MODIFICA: EAX (RESULTADO, FUERA DE USES)
; CONSERVA: EBX, ECX, ESI (USES)
;----------------------------------------------------------
convertirPrecio PROC USES ebx ecx esi
    mov esi, edx                        ; ESI RECORRE LA CADENA
    mov eax, 0                          ; PESOS ACUMULADOS
    mov ecx, 0                          ; CONTADOR DE DIGITOS ENTEROS

    parteEntera:
        movzx ebx, BYTE PTR [esi]       ; CARACTER ACTUAL
        cmp bl, '.'
        je puntoDecimal                 ; EMPIEZA LA PARTE DECIMAL
        cmp bl, 0
        je sinDecimales                 ; TERMINO SIN PUNTO
        mFueraDeRango bl, '0', '9', precioInvalido
        inc ecx
        cmp ecx, 4
        ja precioInvalido               ; MAS DE 4 DIGITOS ENTEROS (> 9999)
        sub ebx, '0'
        imul eax, eax, 10               ; PESOS = PESOS * 10 + DIGITO
        add eax, ebx
        inc esi
        jmp parteEntera

    puntoDecimal:
        cmp ecx, 0
        je precioInvalido               ; DEBE HABER AL MENOS UN DIGITO ANTES DEL PUNTO
        imul eax, eax, 100              ; PESOS A CENTAVOS
        inc esi                         ; SALTAR EL PUNTO

        movzx ebx, BYTE PTR [esi]       ; PRIMER DECIMAL (OBLIGATORIO, INCLUYE "185.")
        mFueraDeRango bl, '0', '9', precioInvalido
        sub ebx, '0'
        imul ebx, ebx, 10               ; EL PRIMER DECIMAL VALE DECENAS DE CENTAVO
        add eax, ebx
        inc esi

        movzx ebx, BYTE PTR [esi]       ; SEGUNDO DECIMAL (OPCIONAL)
        cmp bl, 0
        je revisarRango                 ; SOLO UN DECIMAL
        mFueraDeRango bl, '0', '9', precioInvalido
        sub ebx, '0'
        add eax, ebx
        inc esi

        cmp BYTE PTR [esi], 0           ; DESPUES DEL SEGUNDO DECIMAL DEBE TERMINAR
        jne precioInvalido              ; RECHAZA UN TERCER DECIMAL
        jmp revisarRango

    sinDecimales:
        cmp ecx, 0
        je precioInvalido               ; CADENA VACIA
        imul eax, eax, 100              ; PESOS ENTEROS A CENTAVOS

    revisarRango:
        cmp eax, PRECIO_MIN
        jb precioInvalido               ; MENOR A $0.01
        cmp eax, PRECIO_MAX
        ja precioInvalido               ; MAYOR A $9999.99
        clc
        ret

    precioInvalido:
        stc
        ret
convertirPrecio ENDP

;==========================================================
;                 PROCEDIMIENTOS DE CAPTURA
;==========================================================

;----------------------------------------------------------
; capturarCodigo
; PIDE UN CODIGO HASTA QUE TENGA FORMATO VALIDO. ENTER VACIO CANCELA.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: EDX = OFFSET bufferEntrada CON EL CODIGO; CF = 1 SI SE CANCELO
; MODIFICA: EDX (RESULTADO, FUERA DE USES)
; CONSERVA: EAX, EBX (USES)
;----------------------------------------------------------
capturarCodigo PROC USES eax ebx
    mov ebx, edx                        ; GUARDAMOS EL MENSAJE

    pedirCodigo:
        mov edx, ebx
        call leerOCancelar              ; CF = 1 SI SE CANCELO
        jc terminar
        call validarCodigo
        jnc terminar                    ; FORMATO CORRECTO (CF = 0)
        mError msjErrCodigo
        jmp pedirCodigo                 ; SE VUELVE A PEDIR

    terminar:
        ret
capturarCodigo ENDP

;----------------------------------------------------------
; capturarNombre
; PIDE UN NOMBRE HASTA QUE SEA VALIDO. ENTER VACIO CANCELA.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: EDX = OFFSET bufferEntrada CON EL NOMBRE; CF = 1 SI SE CANCELO
; MODIFICA: EDX (RESULTADO, FUERA DE USES)
; CONSERVA: EAX, EBX (USES)
;----------------------------------------------------------
capturarNombre PROC USES eax ebx
    mov ebx, edx

    pedirNombre:
        mov edx, ebx
        call leerOCancelar
        jc terminar
        call validarNombre
        jnc terminar
        mError msjErrNombre
        jmp pedirNombre

    terminar:
        ret
capturarNombre ENDP

;----------------------------------------------------------
; capturarPrecio
; PIDE UN PRECIO HASTA QUE SEA VALIDO. ENTER VACIO CANCELA.
; RECIBE: EDX = DIRECCION DEL MENSAJE
; REGRESA: EAX = PRECIO EN CENTAVOS; CF = 1 SI SE CANCELO
; MODIFICA: EAX (RESULTADO, FUERA DE USES)
; CONSERVA: EBX, EDX (USES)
;----------------------------------------------------------
capturarPrecio PROC USES ebx edx
    mov ebx, edx

    pedirPrecio:
        mov edx, ebx
        call leerOCancelar
        jc terminar
        call convertirPrecio            ; EAX = CENTAVOS
        jnc terminar
        mError msjErrPrecio
        jmp pedirPrecio

    terminar:
        ret
capturarPrecio ENDP

;----------------------------------------------------------
; capturarCantidad
; PIDE UNA CANTIDAD ENTERA HASTA QUE ESTE DENTRO DEL RANGO. ENTER VACIO CANCELA.
; RECIBE: EDX = DIRECCION DEL MENSAJE, EBX = MINIMO, ECX = MAXIMO
; REGRESA: EAX = CANTIDAD; CF = 1 SI SE CANCELO
; MODIFICA: EAX (RESULTADO, FUERA DE USES)
; CONSERVA: EDX, ESI (USES)
;----------------------------------------------------------
capturarCantidad PROC USES edx esi
    mov esi, edx                        ; GUARDAMOS EL MENSAJE

    pedirCantidad:
        mov edx, esi
        call leerOCancelar
        jc terminar
        call convertirEntero            ; EAX = CANTIDAD
        jc cantidadNoNumerica
        cmp eax, ebx
        jb cantidadFueraRango           ; MENOR AL MINIMO
        cmp eax, ecx
        ja cantidadFueraRango           ; MAYOR AL MAXIMO
        clc
    terminar:
        ret

    cantidadNoNumerica:
        mError msjErrNumero
        jmp pedirCantidad

    cantidadFueraRango:
        mRojo msjErrRango1              ; "DEBE ESTAR ENTRE MIN Y MAX"
        mov eax, ebx
        call mostrarNumero
        mRojo msjErrRango2
        mov eax, ecx
        call mostrarNumero
        call Crlf
        jmp pedirCantidad
capturarCantidad ENDP

;==========================================================
;               PROCEDIMIENTOS DEL CATALOGO
;==========================================================

;----------------------------------------------------------
; buscarCodigo
; RECORRE UNA TABLA DE PRODUCTOS CON ESI BUSCANDO UN CODIGO.
; RECIBE: EDX = CODIGO BUSCADO, EBX = DIRECCION DE LA TABLA,
;         ECX = CANTIDAD DE PRODUCTOS EN LA TABLA
; REGRESA: CF = 0 SI LO ENCONTRO (ESI = DIRECCION DEL REGISTRO,
;          EAX = INDICE); CF = 1 SI NO LO ENCONTRO
; MODIFICA: EAX, ESI (RESULTADOS, FUERA DE USES)
; CONSERVA: EBX, EDI (USES)
;----------------------------------------------------------
buscarCodigo PROC USES ebx edi
    mov esi, ebx                        ; ESI = PRIMER REGISTRO
    mov eax, 0                          ; INDICE = 0

    siguienteRegistro:
        cmp eax, ecx
        jae noEncontrado                ; YA SE REVISARON TODOS
        mov edi, 0                      ; EDI = POSICION DEL CARACTER

    compararCaracter:
        mov bl, BYTE PTR [esi + edi]    ; CARACTER DEL REGISTRO (EL CODIGO ESTA EN EL DESPLAZAMIENTO 0)
        cmp bl, BYTE PTR [edx + edi]    ; CARACTER BUSCADO
        jne avanzarRegistro             ; DIFERENTE: PASAR AL SIGUIENTE
        inc edi
        cmp edi, LONG_CODIGO
        jb compararCaracter             ; FALTAN CARACTERES POR COMPARAR
        clc                             ; LOS 7 CARACTERES SON IGUALES
        ret

    avanzarRegistro:
        add esi, TAM_PRODUCTO           ; ESI = SIGUIENTE REGISTRO
        inc eax
        jmp siguienteRegistro

    noEncontrado:
        stc
        ret
buscarCodigo ENDP

;----------------------------------------------------------
; buscarProducto
; BUSCA UN CODIGO EN EL CATALOGO PRINCIPAL.
; RECIBE: EDX = CODIGO BUSCADO
; REGRESA: CF = 0 SI LO ENCONTRO (ESI = REGISTRO, EAX = INDICE); CF = 1 SI NO
; MODIFICA: EAX, ESI (RESULTADOS, FUERA DE USES)
; CONSERVA: EBX, ECX (USES)
;----------------------------------------------------------
buscarProducto PROC USES ebx ecx
    mov ebx, OFFSET catalogo
    mov ecx, numProductos
    call buscarCodigo
    ret                                 ; LOS POP DE USES NO CAMBIAN CF
buscarProducto ENDP

;----------------------------------------------------------
; pedirProductoExistente (NUEVO EN LA U3)
; PIDE UN CODIGO, LO BUSCA EN EL CATALOGO Y MUESTRA EL PRODUCTO.
; ANTES ESTE BLOQUE SE REPETIA EN BUSCAR, RECIBIR Y VENDER.
; RECIBE: NADA
; REGRESA: CF = 0: ESI = REGISTRO, EAX = INDICE (EL PRODUCTO YA SE MOSTRO)
;          CF = 1: SE CANCELO O EL CODIGO NO EXISTE
; MODIFICA: EAX, ESI (RESULTADOS, FUERA DE USES)
; CONSERVA: EDX (USES)
;----------------------------------------------------------
pedirProductoExistente PROC USES edx
    mov edx, OFFSET msjPideCodigo
    call capturarCodigo                 ; EDX = CODIGO VALIDO
    jc terminar                         ; SE CANCELO
    call buscarProducto                 ; ESI = REGISTRO, EAX = INDICE
    jnc encontrado
    mError msjNoExiste
    stc
    ret

    encontrado:
        call Crlf
        call mostrarEncabezado
        call mostrarProducto
        clc
    terminar:
        ret
pedirProductoExistente ENDP

;----------------------------------------------------------
; mostrarEncabezado
; IMPRIME LOS TITULOS DE LA TABLA DE PRODUCTOS.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EDX (USES)
;----------------------------------------------------------
mostrarEncabezado PROC USES edx
    mMostrarLn msjEncabezado
    mMostrarLn msjLineaTabla
    ret
mostrarEncabezado ENDP

;----------------------------------------------------------
; mostrarProducto
; IMPRIME UN RENGLON DE LA TABLA CON LOS DATOS DE UN PRODUCTO.
; RECIBE: ESI = DIRECCION DEL REGISTRO, EAX = INDICE DEL PRODUCTO
; REGRESA: NADA
; CONSERVA: EAX, ECX, EDX, EDI (USES)
;----------------------------------------------------------
mostrarProducto PROC USES eax ecx edx edi
    inc eax                             ; NUMERO DE RENGLON = INDICE + 1
    mov edi, OFFSET bufferNumero
    call convertirDecimal
    mov edx, OFFSET bufferNumero
    mov ecx, 5
    call escribirColumna                ; COLUMNA No.

    mov edx, esi
    add edx, OFS_CODIGO
    mov ecx, 10
    call escribirColumna                ; COLUMNA CODIGO

    mov edx, esi
    add edx, OFS_NOMBRE
    mov ecx, 27
    call escribirColumna                ; COLUMNA NOMBRE

    mov eax, [esi + OFS_PRECIO]         ; PRECIO EN CENTAVOS
    mov edi, OFFSET bufferNumero
    call formatearImporte               ; "PESOS.CC"
    mov edx, OFFSET msjMXN
    call copiarCadena                   ; SE AGREGA " MXN"
    mov edx, OFFSET bufferNumero
    mov ecx, 18
    call escribirColumna                ; COLUMNA PRECIO

    mov eax, [esi + OFS_EXIST]
    call mostrarNumero                  ; COLUMNA EXISTENCIA
    call Crlf
    ret
mostrarProducto ENDP

;----------------------------------------------------------
; mostrarTotalProductos (NUEVO EN LA U3)
; IMPRIME "Productos registrados: N de 10". SE USA EN EL INVENTARIO Y EN EL RESUMEN.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EDX (USES)
;----------------------------------------------------------
mostrarTotalProductos PROC USES eax edx
    mMostrar msjTotalProd1
    mov eax, numProductos
    call mostrarNumero
    mMostrarLn msjTotalProd2
    ret
mostrarTotalProductos ENDP

;----------------------------------------------------------
; mostrarInventario
; RECORRE EL CATALOGO CON ESI Y MUESTRA TODOS LOS PRODUCTOS.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EDX, ESI (USES)
;----------------------------------------------------------
mostrarInventario PROC USES eax edx esi
    cmp numProductos, 0
    jne hayProductos
    mMostrarLn msjVacio
    ret

    hayProductos:
        call mostrarEncabezado
        mov esi, OFFSET catalogo        ; ESI = PRIMER REGISTRO
        mov eax, 0                      ; INDICE = 0

    recorrerCatalogo:
        cmp eax, numProductos
        jae finRecorrido
        call mostrarProducto
        add esi, TAM_PRODUCTO           ; ESI = SIGUIENTE REGISTRO
        inc eax
        jmp recorrerCatalogo

    finRecorrido:
        call Crlf
        call mostrarTotalProductos
        ret
mostrarInventario ENDP

;----------------------------------------------------------
; registrarProducto
; DA DE ALTA UN PRODUCTO. VALIDA CAPACIDAD, CODIGO UNICO, NOMBRE,
; PRECIO Y EXISTENCIA. SOLO SE GUARDA SI TODOS LOS DATOS SON VALIDOS.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EBX, ECX, EDX, ESI, EDI (USES)
;----------------------------------------------------------
registrarProducto PROC USES eax ebx ecx edx esi edi
    cmp numProductos, MAX_PRODUCTOS
    jb pedirDatos
    mError msjLleno                     ; YA HAY 10 PRODUCTOS
    ret

    pedirDatos:
        mov edx, OFFSET msjPideCodigo
        call capturarCodigo             ; EDX = CODIGO VALIDO
        jc terminar                     ; SE CANCELO
        call buscarProducto
        jc codigoNuevo                  ; NO EXISTE: SE PUEDE USAR
        mError msjDuplicado             ; YA EXISTE: SE RECHAZA Y SE PIDE OTRO
        jmp pedirDatos

    codigoNuevo:
        mov edi, OFFSET nuevoCodigo     ; GUARDAMOS EL CODIGO TEMPORALMENTE
        call copiarCadena

        mov edx, OFFSET msjPideNombre
        call capturarNombre             ; EDX = NOMBRE VALIDO
        jc terminar
        mov edi, OFFSET nuevoNombre
        call copiarCadena

        mov edx, OFFSET msjPidePrecio
        call capturarPrecio             ; EAX = PRECIO EN CENTAVOS
        jc terminar
        mov nuevoPrecio, eax

        mov edx, OFFSET msjPideExist
        mov ebx, 0                      ; MINIMO 0
        mov ecx, EXIST_MAX              ; MAXIMO 100
        call capturarCantidad           ; EAX = EXISTENCIA
        jc terminar
        mov nuevaExist, eax

    ; ---- TODOS LOS DATOS SON VALIDOS: SE GUARDAN EN EL CATALOGO ----
        mov eax, numProductos
        mov ebx, TAM_PRODUCTO
        mul ebx                         ; EAX = INDICE * 42 (DESPLAZAMIENTO)
        mov esi, OFFSET catalogo
        add esi, eax                    ; ESI = REGISTRO LIBRE

        mov edi, esi
        add edi, OFS_CODIGO
        mov edx, OFFSET nuevoCodigo
        call copiarCadena               ; CODIGO

        mov edi, esi
        add edi, OFS_NOMBRE
        mov edx, OFFSET nuevoNombre
        call copiarCadena               ; NOMBRE

        mov eax, nuevoPrecio
        mov [esi + OFS_PRECIO], eax     ; PRECIO
        mov eax, nuevaExist
        mov [esi + OFS_EXIST], eax      ; EXISTENCIA

        inc numProductos                ; UN PRODUCTO MAS
        mov hayCambios, 1               ; HAY CAMBIOS SIN GUARDAR
        mExito msjRegistrado
        call Crlf

    terminar:
        ret
registrarProducto ENDP

;----------------------------------------------------------
; buscarMenu
; PIDE UN CODIGO Y MUESTRA EL PRODUCTO SI EXISTE.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, ESI (USES)
;----------------------------------------------------------
buscarMenu PROC USES eax esi
    call pedirProductoExistente         ; BUSCA Y MUESTRA EL PRODUCTO (O EL ERROR)
    ret
buscarMenu ENDP

;----------------------------------------------------------
; recibirMercancia
; SUMA UNIDADES A UN PRODUCTO EXISTENTE SIN PASAR DE 100.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EBX, ECX, EDX, ESI (USES)
;----------------------------------------------------------
recibirMercancia PROC USES eax ebx ecx edx esi
    call pedirProductoExistente         ; ESI = REGISTRO
    jc terminar
    call Crlf

    mov ebx, EXIST_MAX
    sub ebx, [esi + OFS_EXIST]          ; EBX = UNIDADES QUE TODAVIA CABEN
    cmp ebx, 0
    jne pedirUnidades
    mError msjLleno100                  ; YA TIENE 100
    ret

    pedirUnidades:
        push ebx                        ; GUARDAMOS EL ESPACIO DISPONIBLE
        mov edx, OFFSET msjPideRecibir
        mov ebx, 1                      ; LA ENTRADA DEBE SER MAYOR QUE CERO
        mov ecx, EXIST_MAX
        call capturarCantidad           ; EAX = UNIDADES
        pop ebx                         ; EBX = ESPACIO DISPONIBLE (POP NO CAMBIA CF)
        jc terminar
        cmp eax, ebx
        jbe aplicarEntrada              ; CABE SIN PASAR DE 100

        mRojo msjExcede1                ; ENTRADA EXCESIVA: SE RECHAZA Y SE PIDE OTRA
        mov eax, ebx
        call mostrarNumero
        mRojo msjExcede2
        call Crlf
        jmp pedirUnidades

    aplicarEntrada:
        add [esi + OFS_EXIST], eax      ; SUMAR A LA EXISTENCIA
        mov hayCambios, 1
        mExito msjRecibido
        mov eax, [esi + OFS_EXIST]
        call mostrarNumero
        call Crlf

    terminar:
        ret
recibirMercancia ENDP

;----------------------------------------------------------
; calcularImporte (NUEVO EN LA U3)
; CALCULA EL IMPORTE DE UNA VENTA Y APLICA LA REGLA DEL NEGOCIO:
; 10% DE DESCUENTO DESDE 5 PIEZAS (SE DESCARTA LA FRACCION DE CENTAVO).
; NO MODIFICA EL CATALOGO NI LOS INGRESOS.
; RECIBE: ESI = REGISTRO DEL PRODUCTO, EAX = CANTIDAD
; REGRESA: CF = 0: EAX = IMPORTE FINAL, importeBase Y descuentoVenta CALCULADOS
;          CF = 1: EL CALCULO SE DESBORDA
; MODIFICA: EAX (RESULTADO, FUERA DE USES)
; CONSERVA: EBX, ECX, EDX (USES)
;----------------------------------------------------------
calcularImporte PROC USES ebx ecx edx
    mov ebx, eax                        ; EBX = CANTIDAD
    mov eax, [esi + OFS_PRECIO]         ; EAX = PRECIO EN CENTAVOS
    mul ebx                             ; EDX:EAX = PRECIO * CANTIDAD
    jc terminar                         ; NO CABE EN 32 BITS
    mov importeBase, eax

    mov descuentoVenta, 0
    cmp ebx, DESC_PIEZAS
    jb calcularTotal                    ; MENOS DE 5 PIEZAS: NO APLICA
    mov ecx, DESC_PORCENTAJE
    mul ecx                             ; EDX:EAX = IMPORTE * 10
    jc terminar
    mov ecx, 100
    div ecx                             ; EAX = DESCUENTO (SE DESCARTA LA FRACCION DE CENTAVO)
    mov descuentoVenta, eax

    calcularTotal:
        mov eax, importeBase
        sub eax, descuentoVenta         ; IMPORTE FINAL
        clc
    terminar:
        ret
calcularImporte ENDP

;----------------------------------------------------------
; venderProducto
; VENDE UN SOLO PRODUCTO: COMPRUEBA EXISTENCIAS, CALCULA EL IMPORTE
; CON calcularImporte Y SOLO AL FINAL ACTUALIZA EXISTENCIA E INGRESOS.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EBX, ECX, EDX, ESI (USES)
;----------------------------------------------------------
venderProducto PROC USES eax ebx ecx edx esi
    call pedirProductoExistente         ; ESI = REGISTRO
    jc terminar
    call Crlf

    cmp DWORD PTR [esi + OFS_EXIST], 0
    jne pedirUnidades
    mError msjSinExist                  ; NO HAY NADA QUE VENDER
    ret

    pedirUnidades:
        mov edx, OFFSET msjPideVender
        mov ebx, 1                      ; LA VENTA DEBE SER MAYOR QUE CERO
        mov ecx, EXIST_MAX
        call capturarCantidad           ; EAX = UNIDADES A VENDER
        jc terminar
        cmp eax, [esi + OFS_EXIST]
        jbe hayExistencia               ; ALCANZA LA EXISTENCIA

        mRojo msjInsuf                  ; VENTA RECHAZADA: NO ALCANZA
        mov eax, [esi + OFS_EXIST]
        call mostrarNumero
        call Crlf
        jmp pedirUnidades

    hayExistencia:
        mov cantidadVenta, eax
        call calcularImporte            ; EAX = IMPORTE FINAL, CF = 1 SI SE DESBORDA
        jc desbordamiento
        mov importeFinal, eax
        mov ebx, ingresos
        add ebx, eax                    ; INGRESOS + VENTA
        jc desbordamiento               ; LOS INGRESOS NO CABEN EN 32 BITS

    ; ---- VENTA ACEPTADA: AHORA SI SE ACTUALIZAN LOS DATOS ----
        mov ingresos, ebx
        mov eax, cantidadVenta
        sub [esi + OFS_EXIST], eax      ; DESCONTAR UNIDADES
        mov eax, descuentoVenta
        add descuentos, eax
        inc ventasRealizadas
        mov hayCambios, 1

    ; ---- TICKET ----
        mEtiquetaImporte msjImporteBase, importeBase
        cmp descuentoVenta, 0
        je sinDescuento
        mEtiquetaImporte msjDescAplica, descuentoVenta
        jmp mostrarTotal
    sinDescuento:
        mMostrarLn msjDescNoAplica
    mostrarTotal:
        mEtiquetaImporte msjTotalVenta, importeFinal
        mExito msjVentaOk
        mov eax, [esi + OFS_EXIST]
        call mostrarNumero
        call Crlf
        ret

    desbordamiento:
        mError msjDesborde              ; NO SE MODIFICO NINGUN DATO
    terminar:
        ret
venderProducto ENDP

;----------------------------------------------------------
; mostrarResumen
; RECORRE EL CATALOGO CON ESI PARA SUMAR UNIDADES Y VALOR DEL
; INVENTARIO (PRECIO * EXISTENCIA) Y MUESTRA LOS DATOS DE LA SESION.
; RECIBE: NADA
; REGRESA: NADA
; CONSERVA: EAX, EBX, ECX, EDX, ESI, EDI (USES)
;----------------------------------------------------------
mostrarResumen PROC USES eax ebx ecx edx esi edi
    mov ebx, 0                          ; EBX = UNIDADES DISPONIBLES
    mov edi, 0                          ; EDI = VALOR DEL INVENTARIO
    mov ecx, 0                          ; ECX = INDICE
    mov esi, OFFSET catalogo            ; ESI = PRIMER REGISTRO

    sumarProductos:
        cmp ecx, numProductos
        jae mostrarDatos
        mov eax, [esi + OFS_EXIST]
        add ebx, eax                    ; SUMAR UNIDADES
        mul DWORD PTR [esi + OFS_PRECIO]    ; EDX:EAX = EXISTENCIA * PRECIO
        add edi, eax                    ; SUMAR AL VALOR (MAXIMO 999,999,000 CABE EN 32 BITS)
        add esi, TAM_PRODUCTO           ; SIGUIENTE REGISTRO
        inc ecx
        jmp sumarProductos

    mostrarDatos:
        call Crlf
        mMostrarLn msjResumen
        call mostrarTotalProductos
        mEtiquetaNumero msjResUnidades, ebx
        mEtiquetaImporte msjResValor, edi
        mEtiquetaNumero msjResVentas, ventasRealizadas
        mEtiquetaImporte msjResDesc, descuentos
        mEtiquetaImporte msjResIngresos, ingresos
        mMostrar msjResCambios
        mov edx, OFFSET msjNo
        cmp hayCambios, 0
        je imprimirCambios
        mov edx, OFFSET msjSi
    imprimirCambios:
        call WriteString
        call Crlf
        ret
mostrarResumen ENDP

;==========================================================
;                 PROCEDIMIENTOS DE ARCHIVO
;==========================================================

;----------------------------------------------------------
; guardarCatalogo
; ARMA EL TEXTO CSV EN bufferArchivo Y LO ESCRIBE EN inventario.csv.
; FORMATO: codigo,nombre,precio,existencia (PRECIO CON 2 DECIMALES).
; RECIBE: NADA
; REGRESA: CF = 0 SI SE GUARDO, CF = 1 SI HUBO ERROR
; CONSERVA: EAX, ECX, EDX, ESI, EDI (USES)
;----------------------------------------------------------
guardarCatalogo PROC USES eax ecx edx esi edi
    ; ---- ARMAR EL CONTENIDO ----
    mov edi, OFFSET bufferArchivo       ; EDI = POSICION DE ESCRITURA
    mov edx, OFFSET encabezadoCSV
    call copiarCadena                   ; PRIMERA LINEA: ENCABEZADO
    mPonerChar 0Dh                      ; FIN DE LINEA CR LF
    mPonerChar 0Ah

    mov esi, OFFSET catalogo            ; ESI = PRIMER REGISTRO
    mov ecx, 0                          ; INDICE

    armarLinea:
        cmp ecx, numProductos
        jae escribirArchivo
        mov edx, esi
        add edx, OFS_CODIGO
        call copiarCadena               ; CODIGO
        mPonerChar ','
        mov edx, esi
        add edx, OFS_NOMBRE
        call copiarCadena               ; NOMBRE
        mPonerChar ','
        mov eax, [esi + OFS_PRECIO]
        call formatearImporte           ; PRECIO (EJ. 1850.50)
        mPonerChar ','
        mov eax, [esi + OFS_EXIST]
        call convertirDecimal           ; EXISTENCIA
        mPonerChar 0Dh                  ; FIN DE LINEA
        mPonerChar 0Ah
        add esi, TAM_PRODUCTO           ; SIGUIENTE REGISTRO
        inc ecx
        jmp armarLinea

    ; ---- ESCRIBIR EL ARCHIVO ----
    escribirArchivo:
        mov eax, edi
        sub eax, OFFSET bufferArchivo   ; BYTES A ESCRIBIR = FIN - INICIO
        mov longitudArchivo, eax

        mov edx, OFFSET nombreArchivo
        call CreateOutputFile           ; EAX = HANDLE
        cmp eax, INVALID_HANDLE_VALUE
        je errorCrear
        mov handleArchivo, eax

        mov eax, handleArchivo          ; EAX = HANDLE
        mov edx, OFFSET bufferArchivo   ; EDX = DATOS
        mov ecx, longitudArchivo        ; ECX = BYTES SOLICITADOS
        call WriteToFile                ; CF = 0: EAX = BYTES ESCRITOS, CF = 1: EAX = CODIGO DE ERROR
        jnc guardarBytes
        mov eax, 0                      ; SI HUBO ERROR SE CUENTA COMO 0 BYTES ESCRITOS
    guardarBytes:
        mov bytesEscritos, eax

        mov eax, handleArchivo
        call CloseFile                  ; EAX = 0 SI FALLO EL CIERRE
        mov resultadoCierre, eax

        mov eax, bytesEscritos
        cmp eax, longitudArchivo
        jne errorEscribir               ; NO SE ESCRIBIERON TODOS LOS BYTES
        cmp resultadoCierre, 0
        je errorCerrar

        mov hayCambios, 0               ; YA NO HAY CAMBIOS PENDIENTES
        mExito msjGuardado1
        mov eax, numProductos
        call mostrarNumero
        mMostrar msjGuardado2
        mov eax, longitudArchivo
        call mostrarNumero
        mMostrarLn msjGuardado3
        clc
        ret

    errorCrear:
        mError msjErrCrear
        stc
        ret
    errorEscribir:
        mError msjErrEscribir
        stc
        ret
    errorCerrar:
        mError msjErrCerrar
        stc
        ret
guardarCatalogo ENDP

;----------------------------------------------------------
; cargarCatalogo
; LEE inventario.csv, LO VALIDA COMPLETO EN UN CATALOGO TEMPORAL Y
; SOLO SI TODO ES CORRECTO REEMPLAZA EL CATALOGO ACTUAL.
; RECIBE: NADA
; REGRESA: CF = 0 SI SE CARGO, CF = 1 SI NO EXISTE, FALLO O ES INVALIDO
; CONSERVA: EAX, ECX, EDX, ESI, EDI (USES)
;----------------------------------------------------------
cargarCatalogo PROC USES eax ecx edx esi edi
    mov edx, OFFSET nombreArchivo
    call OpenInputFile                  ; EAX = HANDLE
    cmp eax, INVALID_HANDLE_VALUE
    jne archivoAbierto
    mError msjNoArchivo                 ; EL ARCHIVO NO EXISTE
    stc
    ret

    archivoAbierto:
        mov handleArchivo, eax
        mov edx, OFFSET bufferArchivo   ; EDX = BUFFER
        mov ecx, TAM_ARCHIVO            ; ECX = CAPACIDAD (SE DEJA 1 BYTE PARA EL 00h)
        call ReadFromFile               ; CF = 1 SI HUBO ERROR, EAX = BYTES LEIDOS
        jc errorLectura
        mov bytesLeidos, eax
        mov eax, handleArchivo
        call CloseFile

        mov eax, bytesLeidos
        cmp eax, TAM_ARCHIVO
        jae archivoMuyGrande            ; SE LLENO EL BUFFER: PUEDE HABER MAS DATOS
        mov bufferArchivo[eax], 0       ; 00h DESPUES DEL ULTIMO BYTE LEIDO

        call analizarCSV                ; LLENA catalogoTemp, CF = 1 SI ES INVALIDO
        jc archivoInvalido

    ; ---- EL ARCHIVO ES VALIDO: SE REEMPLAZA EL CATALOGO ----
        mov esi, OFFSET catalogoTemp
        mov edi, OFFSET catalogo
        mov ecx, MAX_PRODUCTOS * TAM_PRODUCTO
    copiarCatalogo:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        loop copiarCatalogo
        mov eax, numTemp
        mov numProductos, eax
        mov hayCambios, 0

        mExito msjCargado1
        mov eax, numProductos
        call mostrarNumero
        mMostrarLn msjCargado2
        clc
        ret

    errorLectura:
        mov eax, handleArchivo
        call CloseFile
        mError msjErrLeer
        stc
        ret

    archivoMuyGrande:
        mError msjMuyGrande
        stc
        ret

    archivoInvalido:
        mRojo msjInvalido1              ; SE INDICA LA LINEA CON ERROR
        mov eax, lineaArchivo
        call mostrarNumero
        mRojo msjInvalido2
        call Crlf
        stc
        ret
cargarCatalogo ENDP

;----------------------------------------------------------
; extraerLinea
; COPIA UNA LINEA DEL ARCHIVO (HASTA CR, LF O 00h) Y AVANZA ESI.
; RECIBE: ESI = POSICION EN EL ARCHIVO, EDI = DESTINO
; REGRESA: ESI = INICIO DE LA SIGUIENTE LINEA, EAX = LONGITUD;
;          CF = 1 SI LA LINEA PASA DE MAX_LINEA CARACTERES
; MODIFICA: EAX, ESI (RESULTADOS, FUERA DE USES)
; CONSERVA: EDX, EDI (USES)
;----------------------------------------------------------
extraerLinea PROC USES edx edi
    mov eax, 0                          ; LONGITUD = 0

    copiarCaracter:
        mov dl, [esi]
        cmp dl, 0
        je finLinea                     ; FIN DEL ARCHIVO
        cmp dl, 0Ah
        je saltoLinea                   ; LF
        cmp dl, 0Dh
        je retornoCarro                 ; CR
        cmp eax, MAX_LINEA
        jae lineaMuyLarga
        mov [edi], dl                   ; COPIAR EL CARACTER
        inc edi
        inc eax
        inc esi
        jmp copiarCaracter

    retornoCarro:
        inc esi                         ; SALTAR CR
        cmp BYTE PTR [esi], 0Ah
        jne finLinea
    saltoLinea:
        inc esi                         ; SALTAR LF

    finLinea:
        mov BYTE PTR [edi], 0           ; TERMINAR LA LINEA CON 00h
        clc
        ret

    lineaMuyLarga:
        stc
        ret
extraerLinea ENDP

;----------------------------------------------------------
; extraerCampo
; COPIA UN CAMPO DE LA LINEA HASTA LA COMA O EL 00h Y AVANZA ESI.
; RECIBE: ESI = POSICION EN LA LINEA, EDI = DESTINO, ECX = LONGITUD MAXIMA
; REGRESA: ESI = DESPUES DE LA COMA (O EN EL 00h), AL = DELIMITADOR (',' O 0);
;          CF = 1 SI EL CAMPO EXCEDE LA LONGITUD MAXIMA
; MODIFICA: EAX, ESI (RESULTADOS, FUERA DE USES)
; CONSERVA: EBX, EDI (USES)
;----------------------------------------------------------
extraerCampo PROC USES ebx edi
    mov ebx, 0                          ; LONGITUD DEL CAMPO

    copiarCampo:
        mov al, [esi]
        cmp al, ','
        je finPorComa
        cmp al, 0
        je finPorCadena
        cmp ebx, ecx
        jae campoMuyLargo
        mov [edi], al
        inc edi
        inc ebx
        inc esi
        jmp copiarCampo

    finPorComa:
        inc esi                         ; SALTAR LA COMA (AL SIGUE VALIENDO ',')
    finPorCadena:
        mov BYTE PTR [edi], 0
        clc
        ret

    campoMuyLargo:
        stc
        ret
extraerCampo ENDP

;----------------------------------------------------------
; analizarCSV
; VALIDA EL TEXTO DE bufferArchivo Y LO GUARDA EN catalogoTemp.
; EL ENCABEZADO DEBE SER EXACTO; CADA LINEA DEBE TENER 4 CAMPOS VALIDOS,
; SIN CODIGOS REPETIDOS Y MAXIMO 10 PRODUCTOS. LAS LINEAS VACIAS SE IGNORAN.
; RECIBE: bufferArchivo TERMINADO EN 00h
; REGRESA: CF = 0 SI ES VALIDO (numTemp = PRODUCTOS LEIDOS);
;          CF = 1 SI ES INVALIDO (lineaArchivo = LINEA CON ERROR)
; CONSERVA: EAX, EBX, ECX, EDX, ESI, EDI (USES)
;----------------------------------------------------------
analizarCSV PROC USES eax ebx ecx edx esi edi
    mov numTemp, 0
    mov lineaArchivo, 1
    mov esi, OFFSET bufferArchivo       ; ESI RECORRE EL ARCHIVO

    ; ---- ENCABEZADO ----
    cmp BYTE PTR [esi], 0
    je csvInvalido                      ; ARCHIVO VACIO
    mov edi, OFFSET bufferLinea
    call extraerLinea
    jc csvInvalido
    mov edx, OFFSET bufferLinea
    mov edi, OFFSET encabezadoCSV
    call compararCadenas
    jne csvInvalido                     ; ENCABEZADO INCORRECTO

    siguienteLinea:
        cmp BYTE PTR [esi], 0
        je csvValido                    ; FIN DEL ARCHIVO
        inc lineaArchivo
        mov edi, OFFSET bufferLinea
        call extraerLinea               ; EAX = LONGITUD
        jc csvInvalido
        cmp eax, 0
        je siguienteLinea               ; LINEA VACIA: SE IGNORA
        cmp numTemp, MAX_PRODUCTOS
        jae csvInvalido                 ; MAS DE 10 PRODUCTOS
        mov posArchivo, esi             ; GUARDAMOS LA POSICION EN EL ARCHIVO

        mov eax, numTemp
        mov ebx, TAM_PRODUCTO
        mul ebx
        add eax, OFFSET catalogoTemp
        mov registroTemp, eax           ; REGISTRO TEMPORAL DONDE SE GUARDARA

        mov esi, OFFSET bufferLinea     ; AHORA ESI RECORRE LA LINEA
        mov ecx, MAX_CAMPO

    ; ---- CAMPO 1: CODIGO ----
        mExtraerCampoCSV ',', csvInvalido
        mov edx, OFFSET bufferCampo
        call validarCodigo
        jc csvInvalido
        mov posLinea, esi
        mov ebx, OFFSET catalogoTemp
        mov ecx, numTemp
        call buscarCodigo               ; CODIGO REPETIDO EN EL ARCHIVO?
        jnc csvInvalido
        mov edi, registroTemp
        add edi, OFS_CODIGO
        call copiarCadena
        mov esi, posLinea
        mov ecx, MAX_CAMPO

    ; ---- CAMPO 2: NOMBRE ----
        mExtraerCampoCSV ',', csvInvalido
        mov edx, OFFSET bufferCampo
        call validarNombre
        jc csvInvalido
        mov edi, registroTemp
        add edi, OFS_NOMBRE
        call copiarCadena

    ; ---- CAMPO 3: PRECIO ----
        mExtraerCampoCSV ',', csvInvalido
        mov edx, OFFSET bufferCampo
        call convertirPrecio            ; EAX = CENTAVOS
        jc csvInvalido
        mov edi, registroTemp
        mov [edi + OFS_PRECIO], eax

    ; ---- CAMPO 4: EXISTENCIA (DEBE SER EL ULTIMO) ----
        mExtraerCampoCSV 0, csvInvalido
        mov edx, OFFSET bufferCampo
        call convertirEntero            ; EAX = EXISTENCIA
        jc csvInvalido
        cmp eax, EXIST_MAX
        ja csvInvalido
        mov edi, registroTemp
        mov [edi + OFS_EXIST], eax

        inc numTemp                     ; PRODUCTO VALIDO
        mov esi, posArchivo             ; REGRESAMOS A LA POSICION DEL ARCHIVO
        jmp siguienteLinea

    csvValido:
        clc
        ret
    csvInvalido:
        stc
        ret
analizarCSV ENDP

END main
