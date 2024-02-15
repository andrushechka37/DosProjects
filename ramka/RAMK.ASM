.model tiny
.code
.286
org 100h


Start:
;-----------------------------consts----------------------------------

	colour = 33d    ; 00010001 - green phon

	up_left = 201
	up_right = 187
	
	down_left = 200
	down_right = 188

	middle_left = 204
	middle_right = 185

	up = 203
	down = 202d

	width_ramka = 15
	length_ramka = 10

	symbol_count = 80*2

control_str db '123456789'
			db 'abcdefght'

;----------------------------------------------------------------------


	mov bx, 0b800h	; adress of the begin of video memory
	mov es, bx

	mov bx, (80 * 5 + 20) * 2	; begin of ramk

	

	call draw_ramk
	



	mov ax, 4c00h
	int 21h	

;----------------------------------------------------------------------
; Draw a given symbol
;
; Entry:
;	
;	AL - symbol
;	bx - part adress(ofset)
;
; Assume:
;
;	es = ob800h
;----------------------------------------------------------------------

draw_sym	proc
		
		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 1], colour
		ret

		endp
;----------------------------------------------------------------------
; Draw a line in console with givem width
;
; Entry:
;	AL - first symbol
;	AH - middle elements
;	DH - last elem
;
; Destr:  BP DL
;
;----------------------------------------------------------------------

draw_line	proc

		mov DL, AL
		call draw_sym	; draws first symbol
		add bx, 2       ; move to the next place

		mov al, ah		; make al the second symbol

		mov bp, cx		; save prev cx

		mov cx, width_ramka	; counter of cycle in draw_line

		Cycle_draw_line:

		call draw_sym   ; draw al

		add bx, 2		; bx += 2
		
		LOOP Cycle_draw_line

		mov al, dh		; last symbol
		call draw_sym

		mov cx, bp 		; restore cx

		add bx, 2		; bx += 2

		mov al, dl

		ret
	
		endp
;----------------------------------------------------------------------
; Draw a ramka using draw a line
;
; Use constants given in the top of the program
;
;
;----------------------------------------------------------------------

draw_ramk	proc

		mov al, up_left 	;
		mov ah, up			; => first line
		mov dh, up_right	;

		call draw_line

		add bx, symbol_count
		sub bx, (width_ramka + 2)*2

		mov al, middle_left 	;
		mov ah, ' '			    ; => body lines
		mov dh, middle_right	;

		mov cx, length_ramka

		Cycle_draw_body:

		call draw_line   ; draw line

		add bx, symbol_count		; bx += 80 (next line) ! magic const
		sub bx, (width_ramka + 2)*2
		
		LOOP Cycle_draw_body


		mov al, down_left 		;
		mov ah, down			; => last line
		mov dh, down_right		;

		call draw_line

		ret

		endp

end	Start