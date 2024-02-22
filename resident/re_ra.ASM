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
        mov bx, es                                       ; save segment and offset for old addres for 09h interrupt
        mov dedault_IRQ1_address_segment, bx             ;
       
;; ---------------------------------------------------------------------



;; ------------------Rewrite interrupt address--------------------------

        push 0                                                             ;
        pop es                                                             ; es = 0  | table of addresses of sis funcs in the begin of memory

        mov bx, 4 * (number_of_irq + 08h)                                  ; IRQ1 interrupt vector address (number 0f IRQ + 8)
                                                                           ; 4 because offset(2) + segment(2)

        cli                                                                ; prohibit interruptions

        mov es:[bx], offset ramka_interrupt                                ; new addr offset

	push cs                                                            ; to get our segment
	pop ax                                                             ;

        mov es:[bx + 2], ax                                                ; new addr segment

        sti                                                                ; allow interruptions

;; ---------------------------------------------------------------------

;; ------------------Terminate and stay resident------------------------



	mov dx, offset EndOfProg                ; address of end of programm
	shr dx, 4                               ; length in paragraphs
	inc dx 		                        ; (sizeof(prog) / 16) + 1

	mov ax, 3100h                           ;
	int 21h                                 ; Terminate and stay resident
						; ----------------------------
						; in dx quantity of paragraphs
						; stores in memory beginning from cs
						; ----------------------------

;; ---------------------------------------------------------------------


;; =====================================================================
;;                         ramka_interrupt 
;; =====================================================================
;; analog to  stantart 09h interrupt
;; draws a frame in left up corner 
;; in frame a shown values of all registers
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: 09h interrupt is changed to this func
;;
;;
;; Note: draw ramka func is awful
;;
;;
;; Call Convention: CDECL
;;
;; Side Effects: draws a frame in left up corner  
;;
;; Destr: -
;; ---------------------------------------------------------------------
ramka_interrupt         proc


                push cs ss es ds sp bp di si dx cx bx ax           ; push all regs to stack to print them
                                                                ; correctly

                mov bp, sp                                      ; save bp, pointed to ax

;; ------------------main seg of interrupt-----------------------------------------

		push begin_of_video_mem
		pop es

                in al, 60h                                      ; scan value from keyboard port

		cmp al, start_symbol
		jne not_start_symbol

;; ----------------------restore ds value----------------------------------------

                push cs                                         ; ds can be destroyed
                pop ds                                          ; we restore it to use 
                                                                ; lotsb/stosb

;; ------------------------draw segment------------------------------------------

                mov bx, 0	                                ; begin of ramk

	        call draw_ramk 

                call draw_registers

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

                pop ax bx cx dx si di bp sp ds es ss

                add sp, 2               ; pop cs

                iret

;; -------------jump to old adress of interrupt-------------------------

not_start_symbol:

                pop ax bx cx dx si di bp sp ds es ss            ; restore old regs
                add sp, 2                                       ; pop cs

	        db 0EAh					        ; long jump
                dedault_IRQ1_address_offset   dw 0		; long jump /dedault_IRQ1_address_segment/ : /dedault_IRQ1_address_offset/
                dedault_IRQ1_address_segment  dw 0		; ---------------------------------------------------------------
                
;;              iret       <----------------------------------- ; we don`t need to put iret here
                                                                ; because we jump to old func, not call it
                endp                                            ; so iret in old func will do all work



;; -------------------------------------------------------------------RAMKA---------------------------------------------------------------------------------------------------------------

;-----------------------------consts----------------------------------

	colour                          = 0ch   

	up_left                         = 0c9h
	up_right                        = 0bbh
	
	down_left                       = 0c8h
	down_right                      = 0bch

	middle_left                     = 0bah
	middle_right                    = 0bah

	up                              = 0cdh
	down                            = 0cdh

	width_ramka                     = 10
	length_ramka                    = 12

	symbol_count                    = 80*2

        number_of_print_registers       = 12

;----------------------------------------------------------------------



;; =====================================================================
;;                          draw_sym
;; =====================================================================
;; Draw a given symbol
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: es = ob800h
;;
;;
;; Entry:       /AL/  --  symbol to draw
;;      
;;              /BX/  -- part adress(ofset)
;;
;;
;; Call Convention: CDECL
;;
;; Side Effects: draw a given symbol
;;
;; Destr: -
;; ---------------------------------------------------------------------
draw_sym	proc
		
		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 1], colour
		ret

		endp





;; =====================================================================
;;                          draw_line
;; =====================================================================
;; Draw a line in console with givem width
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: es = ob800h
;;
;;
;; Entry:       /AL/  --  first symbol in line             
;;
;;              /AH/  --  middle symbol in line
;;
;;              /DH/  --  last symbol in line
;;
;; Call Convention: CDECL
;;
;; Side Effects: draws line
;;
;; Destr: /DL/  /BX/  /AL/  /CX/
;; ---------------------------------------------------------------------
draw_line	proc

                push bp

		mov DL, AL
		call draw_sym	        ; draws first symbol
		add bx, 2               ; move to the next place

		mov al, ah		; make al the second symbol

		mov bp, cx		; save prev cx

		mov cx, width_ramka	; counter of cycle in draw_line

		Cycle_draw_line:

		call draw_sym           ; draw al

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


;; =====================================================================
;;                        draw_ramk  
;; =====================================================================
;; Draw a ramka using draw a line
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: es = ob800h
;;
;;
;; Entry:       use consts given upper
;;
;;
;; Call Convention: CDECL
;;
;; Side Effects: draw ramka
;;
;; Destr: /AX/  /BX/  /CX/  /DX/
;; ---------------------------------------------------------------------
draw_ramk	proc

		mov al, up_left 	        ;
		mov ah, up			; => first line
		mov dh, up_right	        ;

		call draw_line

		add bx, symbol_count
		sub bx, (width_ramka + 2)*2

		mov al, middle_left 	            ;
		mov ah, ' '			    ; => body lines
		mov dh, middle_right	            ;

		mov cx, length_ramka

		Cycle_draw_body:

		call draw_line                  ; draw line

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
;;                     draw_registers     
;; =====================================================================
;; draws registers and their values in up left frame
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: -
;;
;;
;; Entry:       consts(maybe name them)
;;
;; Call Convention: CDECL
;;
;; Side Effects: draws registers
;;
;; Destr: /CX/  /SI/  /DI/  /DL/
;; ---------------------------------------------------------------------
draw_registers        proc

                mov cx, number_of_print_registers       
                mov si, offset text_reg             ; array with names of regs

                mov di, 160 + 2                     ; left up corner, but -> 1 and 1 down   
                mov dl, colour                      ;                                 
                                                    ;
        print_loop:

                  
                call draw_register_line             ; draws "ax: 0000"

                add di, 160 - 18                    ; go to the next line (\n)

                loop print_loop

                ret
                endp



;; =====================================================================
;                       draw_register_line
;;                          
;; =====================================================================
;; draws line like "ax: 0000"
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect:      /DL/  --  colour 
;;
;; Call Convention: CDECL
;;
;; Side Effects: draws line like "ax: 0000"
;;
;; Destr: /SI/
;; ---------------------------------------------------------------------
draw_register_line     proc


                push ax                        
                push bx

                mov al, ' '
                call draw_symbol_for_registers

                lodsb                           ;
                call draw_symbol_for_registers  ; first letter        
                
                lodsb                           ;
                call draw_symbol_for_registers  ; sec letter     

                mov al, ':'
                call draw_symbol_for_registers

                mov al, ' '
                call draw_symbol_for_registers
;; ---------------------------------------------------------------------

                mov ax, [bp]                    ; take original value from stack

                mov bl, al                      ; firstly print elder number
                mov al, ah                      ; al = ah


                call draw_register_value

 

                mov al, bl                      ; al = al
                call draw_register_value        ; print al


                inc bp                           ; add bp, 2
                inc bp                           ; it is faster

                pop bx
                pop ax
                ret
                endp

;; =====================================================================
;;                          draw_symbol_for_registers
;; =====================================================================
;; another draw symbol because in draw ramka draw_sym is huina
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;;
;; Side Effects: draws symbol and colour in /ES/ : [DI]
;;
;; Destr: /DI/  /AL/
;; ---------------------------------------------------------------------
draw_symbol_for_registers       proc

                                stosb
                                mov al, dl                      
                                stosb  

                                ret
                                endp



;; =====================================================================
;;                          draw_register_value
;; =====================================================================
;; draws reg value not as symbol but as hex number
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: es = 0b800h
;;
;;
;; Entry: /AL/  --  symbol to draw 
;;
;;
;; Call Convention: CDECL
;;
;;
;; Destr: /DI/
;; ---------------------------------------------------------------------
draw_register_value             proc

                                push ax
                                push bx
                                push cx

                                xor ah, ah

                                mov cl, al                              ; save al

                                and al, 11110000b                       ; so we get elder number of al

                                rol al, 4                               ; so we get number 0-15 (it is offset in hex_alphabet)

                                mov bx, offset hex_alphabet             

                                add bx, ax                              ; bx is address of needed symbol

                                mov al, [bx]                            ; print elder number of al
                                stosb                                   ;

                                mov al, dl                              ; colour
                                stosb                                   ;


                                mov al, cl
                                and al, 00001111b
        
                                mov bx, offset hex_alphabet
                                add bx, ax   

                                mov al, [bx]                            ; print younger number of al
                                stosb                                   ;

                                mov al, dl                              ; colour
                                stosb                                   ;


                                pop cx
                                pop bx
                                pop ax


                                ret
                                endp

text_reg db 'axbxcxdxsidibpspdsessscs'

hex_alphabet db '0123456789abcdef'

EndOfProg:

end Start