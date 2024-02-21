.model tiny
.code
.286
org 100h



;; ------------------consts---------------------------------------------

begin_of_video_mem             =  0b800h
number_of_irq                  =  01h
size_of_interupt_func_adress   =  4
start_symbol		       =  9             ; scan code of '8'
size_sym_line                  =  80

;; ---------------------------------------------------------------------

Start:

;; ------------------Save old address------------------------------------

        mov ah, 35h                                      ;
        mov al, number_of_irq + 08h                      ;
        int 21h                                          ; returns /ES/:/BX/ of IRQ + 8

        mov dedault_IRQ1_address_offset, bx              ;
        mov bx, es                                       ; save segment and offset for old addres
        mov dedault_IRQ1_address_segment, bx             ;
       
;; ---------------------------------------------------------------------



;; ------------------Rewrite interrupt address--------------------------

        push 0                                                             ;
        pop es                                                             ; es = 0  | table of addresses of sis funcs in yhe begin of memory

        mov bx, size_of_interupt_func_adress * (number_of_irq + 08h)       ; IRQ1 interrupt vector address (number 0f IRQ + 8)
                                                                           ; 4 because offset + segment

        cli                                                                ; prohibit interruptions

        mov es:[bx], offset ramka_interrupt                                ; addr offset

	push cs                                                            ; to get our segment
	pop ax                                                             ;

        mov es:[bx + 2], ax                                                ; addr segment

        sti                                                                ; allow interruptions

;; ---------------------------------------------------------------------

;; ------------------Terminate and stay resident------------------------



	mov dx, offset EndOfProg                ; address of end of programm
	shr dx, 4                               ; length in paragraphs
	inc dx 		                        ; sizeof(prog) / 16 + 1

	mov ax, 3100h                           ;
	int 21h                                 ; Terminate and stay resident
						; ----------------------------
						; in dx quantity of paragraphs
						; stores in memory dx paragraphs beginning from cs
						; ----------------------------

;; ---------------------------------------------------------------------


;; =====================================================================
;;                         ramka_interrupt 
;; =====================================================================
;; analog to  stantart 09h interrupt
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Side Effects: draws ramka in up left corner
;;
;; Destr: -
;; ---------------------------------------------------------------------
ramka_interrupt         proc

		;push dx cx bx ax
                push ax bx es




;; ------------------video seg-----------------------------------------

		push begin_of_video_mem
		pop es

                in al, 60h

		cmp al, start_symbol
		jne not_start_symbol

	        mov bx, 0	; begin of ramk

                push cs
                pop ds

                push dx si di cx
	        call draw_ramk
                pop cx di si dx

                call draw_reg


;; ------------------blink 61 port higher bit--------------------------
	
		in al, 61h              	; al = symbol from 61h(status of keyboard)
		or al, 80h                      ; al or 1000|0000   (make higher bit 1)
		out 61h, al                     ; put al in 61h

		and al, not 80h                 ; al and 0111|1111  (make higher bit 0)
		out 61h, al                     ; put al in 61h

;; ---------------------------------------------------------------------

;; ------------------EOI-----------------------------------------------

		mov al, 20h						; say to PPI that our interrupt is over
		out 20h, al						; so other interrupts can play

;; ---------------------------------------------------------------------
                ;pop ax bx cx dx
                pop es bx ax
                iret

;; -------------jump to old adress of interrupt-------------------------

not_start_symbol:

        ;pop ax bx cx dx
        pop es bx ax

	db 0EAh					        ; long jump
        dedault_IRQ1_address_offset   dw 0		; long jump /dedault_IRQ1_address_segment/ : /dedault_IRQ1_address_offset/
        dedault_IRQ1_address_segment  dw 0		;

;; ---------------------------------------------------------------------

        iret
        endp




;; -------------------------------------------------------------------RAMKA---------------------------------------------------------------------------------------------------------------









;-----------------------------consts----------------------------------

	colour = 0ch    ; 00010001 - green phon

	up_left = 0c9h
	up_right = 0bbh
	
	down_left = 0c8h
	down_right = 0bch

	middle_left = 0bah
	middle_right = 0bah

	up = 0cdh
	down = 0cdh

	width_ramka = 15
	length_ramka = 10

	symbol_count = 80*2

;----------------------------------------------------------------------


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
; Destr:  DL BX AL CX
;
;----------------------------------------------------------------------

draw_line	proc

                push bp

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

                pop bp

		ret
	
		endp
;----------------------------------------------------------------------
; Draw a ramka using draw a line
;
; Use constants given in the top of the program
;
; Destr: AX, DX BX CX
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


;; =====================================================================
;;                          draw_reg
;; =====================================================================
;; draws regs
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Expect: 
;;
;;
;; Entry: 
;;
;;
;; Return: 
;;
;;
;; Note: 
;;
;;
;; Call Convention: CDECL
;;
;; Side Effects:
;;
;; Destr: 
;; ---------------------------------------------------------------------
draw_reg        proc

        mov cx, 4
        mov si, offset text_reg
        mov di, 160 + 2
        mov dl, colour

        print_loop:

                lodsb              
                call draw_symbol_right    

                lodsb               
                call draw_symbol_right   

                lodsb                     ; al = ds:[SI++]
                call draw_symbol_right    ; es:[DI++] = AL

                add di, 160 - 6

                loop print_loop



                ret
                endp

;======================================================================
;                       draw_symbol_right
;======================================================================
; 
; Require : colour in dl
;
; Dest: si,
;----------------------------------------------------------------------
draw_symbol_right     proc

                push ax                         ; TODO: mov ah, dl stosw

                stosb       ; ds[si++] = al
                mov al, dl
                stosb

                pop ax
                ret
                endp



text_reg db 'raxrbxrcxdrx'

EndOfProg:

end Start