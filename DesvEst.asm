INCLUDE Irvine32.inc
INCLUDE macros.inc

.data

sangreA REAL4 18.2, 20.5, 20.9, 18.5, 21.9, 18.4, 17.4, 22.3, 20.4, 18.2,
19.3, 20.3, 18.3, 20.3, 20.3, 20.6, 20.8, 18.7, 19.6, 17.5,
18.8, 18.8, 20.9, 20.0, 19.4, 20.4, 20.1, 20.1, 19.0, 18.6

sangreV REAL4 11.4, 14.0, 15.1, 12.0, 14.6, 12.0, 11.3, 15.3, 11.9, 12.7, 12.7,
12.8, 12.2, 14.8, 13.4, 13.5, 14.4, 13.8, 11.7, 10.6, 13.2,
12.5, 12.5, 13.9, 11.9, 14.2, 13.3, 12.6, 14.5, 11.6

tamLista = 30
res1 REAL10 ?		;resultado de sumatoriaA
res2 REAL10 ?		;resultado de sumatoriaV
cantidad REAL10 30.0

.code
main proc
finit
mov esi, 0
mov ecx, tamLista
fldz

sumatoria2A :			; sumatoria de valores al cuadrado del primer arreglo

	fld sangreA[esi]
	fld sangreA[esi]
	fmul
	fadd
	add esi, type REAL4

	loop sumatoria2A

call ShowFPUStack
fld cantidad
fdiv					; divide la suma anterior sobre 30
mWrite "sum(x^2)/N: "
call WriteFloat
fstp res1


mov esi, 0
mov ecx, tamLista
fldz
mediaA :				; sumatoria de valores del primer arreglo

	fld sangreA[esi]
	fadd
	add esi, type REAL4

	loop mediaA
call ShowFPUStack
fld cantidad
fdiv					; divide la suma anterior sobre 30
mWrite "sum(x)/N: "
call WriteFloat
fstp res2


mov ecx, tamLista
mov esi, 0
fldz

; sumatoriaV:			 sumatoria de valores al cuadrado del segundo arreglo
;	call ShowFPUStack
;	fld sangreV[esi]
;	fld sangreV[esi]
;	fmul
;	call ShowFPUStack
;	fadd
;	add esi, type REAL4

;	loop sumatoriaV
;	fstp res2



exit
main endp
end main