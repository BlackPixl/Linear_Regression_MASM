INCLUDE Irvine32.inc
INCLUDE macros.inc

TAM_BUFER = 500

.data
	endl EQU <0dh, 0ah>; end of line sequence

	message LABEL BYTE
	BYTE "			Bienvenido a Regresion Lineal V1 !!!", endl
	BYTE "	ASIGNATURA: Arquitectura de Computadores", endl
	BYTE "	ANIO:       2020", endl
	BYTE "	SEMESTRE:   2019-2", endl
	BYTE "	REALIZADO POR:", endl
	BYTE "		Cristhian Salazar Jaramillo. CC (INSERTE CEDULA)", endl
	BYTE "		Cristian Jaramillo Herrera. CC (INSERTE CEDULA)", endl
	BYTE "		Javier Dario. CC (INSERTE CEDULA)", endl
	BYTE "	DESCRIPCION: ", endl
	BYTE "		Este programa lee un archivo de datos, los muestra ", endl
	BYTE "		en consola, calcula su media, desviacion tipica y estandar, ", endl
	BYTE "		luego calcula la correlacion de Pearson entre las variable, ", endl
	BYTE "		y por ultimo realiza la regresion lineal simple entre los datos ", endl
	BYTE "		mostrando en pantalla la pendiente (A) y el intercepto de la recta (B).", endl

	messageSize DWORD($ - message)
	consoleHandle HANDLE 0; handle to standard output device
	bytesWritten  DWORD ? ; number of bytes written

	bufer BYTE TAM_BUFER DUP(? )
	nombreArchivo BYTE "DATOS.csv",0
	manejadorArchivo  HANDLE ?
	cadTitulo BYTE "LinearRegresion", 0

.code
	main PROC
	; ------------ bienvenida  ---------------------
	; Change the console´s name
	INVOKE SetConsoleTitle, ADDR cadTitulo

	; Change the text and console´s colors
	mov eax,green
	call SetTextColor
	call Clrscr

	; Get the console output handle :
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov consoleHandle, eax

	; Write a string to the console :
	INVOKE WriteConsole,
	consoleHandle,			; console output handle
	ADDR message,			; string pointer
	messageSize,			; string length
	ADDR bytesWritten,		; returns num bytes written
	0					; not used

	;--------------- leer datos --------------------

	mov edx, OFFSET nombreArchivo
	mov ecx, SIZEOF nombreArchivo

	; Abre el archivo en modo de entrada.
	mov edx, OFFSET nombreArchivo
	call OpenInputFile
	mov manejadorArchivo, eax

	; Comprueba errores.
	cmp eax, INVALID_HANDLE_VALUE				; ¿error al abrir el archivo ?
	jne archivo_ok							; no: salta
	mWrite <"No se puede abrir el archivo", 0dh, 0ah>
	jmp terminar							; y termina
	archivo_ok :

	; Lee el archivo y lo coloca en un búfer.
	mov edx, OFFSET bufer
	mov ecx, TAM_BUFER
	call ReadFromFile
	jnc comprobar_tamanio_bufer				; ¿error al leer ?
	mWrite "Error al leer el archivo"			; sí: muestra mensaje de error
	call WriteWindowsMsg
	jmp cerrar_archivo
	comprobar_tamanio_bufer :
	cmp eax, TAM_BUFER						; ¿el búfer es lo bastante grande ?
	jb tam_buf_ok							; sí
	mWrite <"Error: Bufer demasiado chico para el archivo", 0dh, 0ah>
	jmp terminar							; y termina
	tam_buf_ok :
	mov bufer[eax], 0						; inserta terminador nulo
	mWrite "Tamanio del archivo: "
	call WriteDec							; muestra el tamaño del archivo
	call Crlf

	; Muestra el búfer.
	mWrite <"Bufer:", 0dh, 0ah, 0dh, 0ah>
	mov edx, OFFSET bufer					; muestra el búfer
	call WriteString
	call Crlf
	cerrar_archivo :
	mov eax, manejadorArchivo
	call CloseFile
	terminar :
		exit

	main ENDP
END main
