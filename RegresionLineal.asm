TITLE LinearRegresion (RegresionLineal.asm)

.686
.MODEL FLAT, STDCALL
.STACK

INCLUDE Irvine32.inc
INCLUDE macros.inc
TAM_BUFER = 5000					;// reservamos 5kb para leer el archivo

.DATA

endl EQU <0dh, 0ah>					;// secuencia de fin de linea

message LABEL BYTE
BYTE "			Bienvenido a Regresion Lineal V1 !!!", endl
BYTE "ASIGNATURA: Arquitectura de Computadores", endl
BYTE "ANIO:       2020", endl
BYTE "SEMESTRE:   2019-2", endl
BYTE "REALIZADO POR:", endl
BYTE "	Cristhian Salazar Jaramillo.", endl
BYTE "	Cristian Jaramillo Herrera.", endl
BYTE "	Javier Dario Echavarria Cano.", endl
BYTE "DESCRIPCION: ", endl
BYTE "	Este programa lee un archivo de datos, los muestra ", endl
BYTE "	en consola, calcula su media, desviacion estandar, ", endl
BYTE "	luego calcula la correlacion de Pearson entre las variable, ", endl
BYTE "	y por ultimo realiza la regresion lineal simple entre los datos ", endl
BYTE "	mostrando en pantalla la pendiente (a) y el intercepto de la recta (b).", endl, endl



messageSize DWORD($ - message)		;// tamaño del mensaje
consoleHandle HANDLE 0				;// manejar al dispositivo de salida estandar
bytesWritten  DWORD ?				;// numero de bytes escritos
bufer BYTE TAM_BUFER DUP(0)			;// inicializamos el bufer donce estará el archivo
nombreArchivo BYTE "DATOS.csv", 0		;// el nombre del archivo es DATOS.csv
manejadorArchivo  HANDLE ?			;// manejador del archivo
cadTitulo BYTE "LinearRegresion", 0	;// titulo de la consola
tamanoBufer DWORD ?					;// tamaño real del archivo leído
tabulacion BYTE "    ", 0

sangreA REAL8 500 DUP(? )			;// reservamos 500 bytes para cada arreglo de datos
sangreV REAL8 500 DUP(? )			;// reservamos 500 bytes
coeficiente REAL4 10.0
numero REAL8 0.0
diez DWORD 10
tempNum DWORD 0
comparador DWORD 1
tamLista DWORD 0					;// representa los bytes usados de la lista
despChar DWORD 48

cantidad REAL10 30.0				; // cantidad de elementos en un arreglo
cociente REAL10 ?					; // resultado de sumatoriaA
mediaA REAL10 ?					; // de sum(x) / cantidad
mediaA2 REAL10 ?					; // de elevar la media al cuadrado
mediaV REAL10 ?					; // de sum(y) / cantidad
mediaV2 REAL10 ?					; // de elevar la media al cuadrado
resta REAL8 ?						; // de la resta interna de la raiz
resA REAL8 ?						; // estandar poblacional de sangreA
resV REAL8 ?						; // estandar poblacional de sangreV

cociente2 REAL10 ?					;// cociente2 es el cociente entre la sumatoria Xi * Yi y el tamaño de la lista
ProdMed REAL10 ?					;// ProdMed es el producto de las medias
covarianza REAL10 ?					;// covarianza de X y Y

denpe REAL10 ?						;// Denominador correlacion de pearson
pearson REAL10 ?					;// Coeficiente de correlacion de pearson

resA2 REAL8 ?						;// desviacion Estandar poblacional de sangreA al cuadrado
inter REAL8 ?						;// Intercepto con el eje y
bMediaA REAL8 ?					;// Intercepto con el eje y * mediaA
pend REAL8 ?						;// Pendiente de la recta


.CODE
main PROC

			;// ------------bienvenida-------------------- -
													
	INVOKE SetConsoleTitle, ADDR cadTitulo				;// Cambia el nombre de la consola

												;// Cambia el color de texto
	mov eax, Cyan+(Black*16)
	call SetTextColor
	call Clrscr

	
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE				;// obtiene el manejador de salidas por consola
	mov consoleHandle, eax

												;// Escribe el string de bienvenida en la consola
	INVOKE WriteConsole,
		consoleHandle,								;// Manejador de salida de consola
		ADDR message,								;// apuntador del string
		messageSize,								;// tamano del string
		ADDR bytesWritten,							;// retorna el numero de bytes escritos
		0										;// sin uso

		call WaitMsg
		call Crlf


			; //-------------- - leer datos--------------------

														
	mov edx, OFFSET nombreArchivo								;//Abre el archivo en modo de entrada.
	call OpenInputFile
	mov manejadorArchivo, eax

														;//Comprueba errores.
	cmp eax, INVALID_HANDLE_VALUE								;//¿error al abrir el archivo ?
	jne archivo_ok											;//no: salta
	mWrite <"No se puede abrir el archivo", endl>
	call WaitMsg
	jmp terminar											;//y termina
	
	archivo_ok :											;//Lee el archivo y lo coloca en un búfer.
		mov edx, OFFSET bufer
		mov ecx, TAM_BUFER
		call ReadFromFile
		jnc comprobar_tamanio_bufer							;//¿error al leer ?
		mWrite "Error al leer el archivo"						;//sí: muestra mensaje de error y sale
		call WriteWindowsMsg
		call WaitMsg
		jmp cerrar_archivo

	comprobar_tamanio_bufer :
		cmp eax, TAM_BUFER									;//¿el búfer es lo bastante grande ?
		jb tam_buf_ok										;//sí, salta a tam_buf_ok
		mWrite <"Error: Bufer demasiado chico para el archivo", endl>	;//no: muestra mensaje de error
		call WaitMsg
		jmp terminar										;//y termina
	
	tam_buf_ok :
		mov bufer[eax], 0									;//inserta terminador nulo
		mov tamanoBufer, eax
		call Crlf
		mWrite "Tamanio del archivo: "
		call WriteDec										;//muestra el tamaño del archivo
		mWrite <"Bytes", endl, endl>

	;//--------------- extraer los datos del bufer --------------------

		xor ecx, ecx
		mov esi, 47										;//ignoramos la primera línea ya que contiene el encabezado
		while1:
		cmp esi, tamanoBufer								;//en este while leeremos byte por byte todo el archivo
		jge fin_while1
			mov al, [bufer + esi]							;//movemos el byte al registro al
			cmp al, ","									;//lo comparamos con la coma
			je a											;//si es la coma, significa que el siguiente byte es un número que debemos leer
			jmp b										;//caso contrario saltamos al final del ciclo
			a:
			fild diez										;// inicializamos el coeficiente con un valor de diez
			fstp coeficiente
			inc esi										;//incrementamos esi para leer el valor siguiente a la coma
			while2:
				mov edx, comparador							;//con el comparador sabemos si el numero pertenece a sangre arterial o venosa
				cmp edx, 1								;//en caso de ser 1, el numero pertenece a sangre arterial y finaliza con una coma
				je comp_coma
				comp_saltoLinea:							;// en caso de no ser 1, el numero pertenece a sangre venosa y finaliza con un salto de linea
				mov ebx, 13								;//13 es el codigo ascii para representar el salto de linea, lo metemos en ebx
				jmp fin_if1
				comp_coma :
				mov ebx, 44								;//44 es el codigo ascii para la coma, lo metemos en ebx
				fin_if1:
				xor eax, eax
				mov al, [bufer + esi]						;//movemos a "al" el elemento en la posicion esi del bufer
				cmp eax, ebx								;//como "al" hace parte del registro en eax, podemos comparar lo que hay en eax con lo que hay ebx
				je fin_while2								;//en ebx esta el codigo ascii de salto de linea o coma, lo cual indica que hemos terminado de leer el numero
				cmp eax, 46								;//en caso contrario comparamos lo qe hay en eax con el codigo ascii para el punto
				je pto_decimal
				sub eax, 48								;//restamos 48 a lo que hay en eax para conocer el valor numerico verdadero
				mov tempNum, eax							;//movemos a tempnum el digito que hay en eax
				fld numero									
				fld coeficiente
				fild tempNum
				fmul
				fadd
				fstp numero								;//numero += coeficiente*tempnum
				fld coeficiente
				fild diez
				fdiv
				fstp coeficiente							;//coeficiente = coeficiente/10
				inc esi
				jmp while2
				pto_decimal:								;//cuando llegamos al punto decimal lo ignoramos
				inc esi
				jmp while2
			fin_while2:
			fild diez
			fstp coeficiente								;//coeficiente = 10
			fld numero
			mov edx, comparador
			cmp edx, 1
			je add_SArterial								;//si comparador es 1, añadimos el numero creado a sangreA
			add_SVenosa:									;//en caso contrario lo añadimos a sangreV
			fstp [sangreV + ecx * 8]							;//ecx representa la posicion en el arreglo en el que se metera el numero
			mov comparador, 1
			inc ecx										;//el contador ecx incrementara con cada par de numeros que metamos en los arreglos
			fldz
			fstp numero									;//numero = 0
			jmp continuar
			add_SArterial:
			fstp [sangreA + ecx * 8]
			mov comparador, 2
			inc esi
			fldz
			fstp numero
			jmp while2
			continuar:
			inc esi
		b:
		inc esi
		jmp while1
		fin_while1:

;//---------------imprmir el numero de individuos--------------------
		mov tamLista, ecx									;//aprovechamos el contador del ciclo anterior para conocer el numero de individuos
		mov eax, tamLista
		mWrite<"Numero de individuos: ">
		call WriteDec
		call Crlf
		call Crlf
		xor esi, esi


	;//---------------cambiamos el color de las salidas a verde--------------------

		mov eax, green + (Black * 16)
		call SetTextColor
			

;//---------------imprimir los datos en consola--------------------
		mWrite <"No.   Sangre Arterial   Sangre Venosa", endl>		;//imprimimos el encabezado
		mov edx, OFFSET tabulacion
		whileimprimir:
		cmp esi, tamLista
			je fin_whileimprimir
			mov eax, esi
			inc eax
			call WriteDec									;//imprimimos el numero de individuo
			call WriteString								;//impprmimimos la tabulacion
			fld [sangreA + esi * 8]							;// cargamos en la fpu el elemento en la posicion esi del arreglo
			call WriteFloat								;//lo imprimimios
			fstp numero									;//lo sacamos de la fpu
			call WriteString								;//repretimos el proceso con el segundo arreglo
			fld [sangreV + esi * 8]
			call WriteFloat
			fstp numero
			call Crlf
			inc esi
			jmp whileimprimir
		fin_whileimprimir:

		cerrar_archivo :
			mov eax, manejadorArchivo
			call CloseFile

			mov eax, cyan + (Black * 16)						;// cambio color de texto a cyan
			call SetTextColor
			
			call Crlf
			call WaitMsg
			call Crlf
			call Crlf
			call Crlf
	



	finit
	;// ------------------DESVIACION ESTANDAR POBLACIONAL SANGRE_A--------------------------

	mov esi, 0
	mov ecx, tamLista
	fldz

	sumatoriaA2 :							;// sumatoria de valores al cuadrado del primer arreglo

		fld sangreA[esi]
		fld sangreA[esi]
		fmul
		fadd

		add esi, type REAL8

	loop sumatoriaA2

	fld cantidad
	fdiv									;// divide la suma anterior sobre 30
	fstp cociente


	mov esi, 0
	mov ecx, tamLista
	fldz
	CicloMedia1:							;// sumatoria de valores del primer arreglo

		fld sangreA[esi]
		fadd
		add esi, type REAL8

	loop CicloMedia1

	fld cantidad
	fdiv									;// divide la suma anterior sobre 30

	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Media Sangre Arterial: "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a cyan
	call SetTextColor
	call WriteFloat
	call Crlf
	call Crlf
	fstp mediaA
	fld mediaA
	fld mediaA							;// carga dos veces la mediaA en la pila
	fmul									;// y la eleva al cuadrado multiplicandola por si misma
		
	fstp mediaA2

	;//------------------RAIZ CUADRADA DE LA RESTA--------------------------
	fld cociente
	fld mediaA2
	fsub
	fsqrt
	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Desv.Est Poblacional Sangre Arterial: "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	fstp resA

	;// ------------------DESVIACION ESTANDAR POBLACIONAL SANGRE_V--------------------------


	mov ecx, tamLista
	mov esi, 0
	fldz

	sumatoriaV2 :							; //sumatoria de valores al cuadrado del segundo arreglo
		fld sangreV[esi]
		fld sangreV[esi]
		fmul
		fadd	
		add esi, type REAL8
	loop sumatoriaV2

	fld cantidad
	fdiv									;// divide la suma anterior sobre 30
	fstp cociente


	mov esi, 0
	mov ecx, tamLista
	fldz
	CicloMedia2 :							;// sumatoria de valores del segundo arreglo
		fld sangreV[esi]
		fadd
		add esi, type REAL8
	loop CicloMedia2
		 
	fld cantidad
	fdiv									; //divide la suma anterior sobre 30
	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Media Sangre Venosa: "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	fstp mediaV
	fld mediaV
	fld mediaV							;// carga dos veces la media en la pila
	fmul									;// y la eleva al cuadrado multiplicandola por si misma

	fstp mediaV2

	;//------------------RAIZ CUADRADA DE LA RESTA--------------------------
	fld cociente
	fld mediaV2
	fsub
	fsqrt
	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Desv.Est Poblacional Sangre Venosa: "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	call Crlf

	fstp resV
		
	call WaitMsg
	call Crlf
	call Crlf


	;// ------------------Covarianza--------------------------

		
	mov esi, 0
	mov ecx, tamLista
	fldz

	sumatoriaXY :							;// sumatoria del producto de los valores de Xi * Yi
		fld sangreA[esi]
		fld sangreV[esi]
		fmul
		fadd
		add esi, type REAL8
	loop sumatoriaXY



	fld cantidad
	fdiv									;//divide la suma anterior sobre 30
	fstp cociente2							;//cociente entre sumatoria de Xi*Yi sobre N


	fld mediaA
	fld mediaV
	fmul
	fstp ProdMed							;//Producto de las medias



	fld cociente2
	fld ProdMed
	fsub
	fstp covarianza




		;// ------------------COEFICIENTE CORRELACION DE PEARSON--------------------------
	fld resA
	fld resV
	fmul
	fstp denpe

	fld covarianza
	fld denpe
	fdiv

	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Coeficiente de correlacion de pearson: "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	fstp pearson

	call WaitMsg
	call Crlf
	call Crlf


		;// ------------------REGRESION LINEAL--------------------------
	fld resA
	fld resA
	fmul
	fstp resA2

	fld covarianza
	fld resA2
	fdiv

	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	mWrite <"  Modelo de la recta: Y = a + bX", endl, endl>
	mWrite "  Pendiente de la recta (b): "

	mov eax, cyan + (Black * 16)				;// cambio color de texto a cyan
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	fstp pend								;//Pendiente de la recta

	fld mediaA
	fld pend
	fmul
	fstp bMediaA

	fld mediaV
	fld bMediaA
	fsub
	mov eax, red + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor

	mWrite "  Intercepto con el eje Y (a): "
	mov eax, cyan + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	call WriteFloat

	call Crlf
	call Crlf
	fstp inter							;//intercepto con el eje Y
	call WaitMsg
	call Crlf
	call Crlf


	mov eax, brown + (Black * 16)				;// cambio color de texto a rojo
	call SetTextColor
	mWrite " MUCHAS GRACIAS POR USAR EL PROGRAMA "
	call Crlf
	mWrite <" HASTA PRONTO", endl>
	call Crlf

	mov eax, cyan + (Black * 16)				;// cambio color de texto a cyan
	call SetTextColor

	call WaitMsg
	call Crlf
	terminar:
	exit

	main ENDP
END main
