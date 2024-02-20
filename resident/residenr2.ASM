.model tiny
.code
.286
org 100h


;; ------------------consts------------------

begin_of_video_mem = 0b800h




Start:

;; ------------------save old adress------------------

        mov ax, 3509h                                   ;
        int 21h                                         ; returns es:bx 0f IRQ(1 + 8)

        mov OriginalKeyboardIntFunctionOffset, bx       ;
        mov bx, es                                      ; save segment and offset for old addres
        mov OriginalKeyboardIntFunctionSegment, bx      ;






        push 0                                  ;
        pop es                                  ; es = 0  | table of addrresses of sis funcs in yhe begin of memory

        mov bx, 4 * 09h                         ; IRQ1 interrupt vector address (number 0f IRQ + 8)
                                                ; 4 because offset + segment

        cli                                     ; prohibit interruptions

        mov es:[bx], offset IntOverride09       ; addr offset

		push cs                                 ; to get our segment
		pop ax                                  ;

        mov es:[bx + 2], ax                     ; addr segment

        sti                                     ; allow interruptions


;; ---------------------------------------------------------------------

	mov dx, offset EndOfProg                ; address of end of programm
	shr dx, 4                               ; length in paragraphs
	inc dx 		                            ; sizeof(prog) / 16 + 1

	mov ax, 3100h                           ;
	int 21h                                 ; Terminate and stay resident
											; ----------------------------
											; in dx quantity of paragraphs
											; stores in memory dx paragraphs beginning from cs
											; ----------------------------


;; ---------------------------------------------------------------------

IntOverride09	proc
		push ax bx es

		push begin_of_video_mem
		pop es

		mov bx, ((80 * 3) + 40) * 2
		mov ah, 4eh ; color

		in al, 60h ; symbol
		mov es:[bx], ax



;; ------------------blink 61 port higher bit--------------------------
	
		in al, 61h              		; al = symbol from 61h(status of keyboard)
		or al, 80h                      ; al or 1000|0000   (make higher bit 1)
		out 61h, al                     ; put al in 61h

		and al, not 80h                 ; al and 0111|1111  (make higher bit 0)
		out 61h, al                     ; put al in 61h

;; ---------------------------------------------------------------------


;; ------------------EOI-----------------------------------------------

		mov al, 20h
		out 20h, al

;; ---------------------------------------------------------------------


		pop es bx ax

		db 0EAh											;
        OriginalKeyboardIntFunctionOffset   dw 0		; long jump OriginalKeyboardIntFunctionSegment:OriginalKeyboardIntFunctionOffset
        OriginalKeyboardIntFunctionSegment  dw 0		;


		iret
		endp


;; ------------------blink 61 port higher bit--------------------------
	
		in al, 61h              		; al = symbol from 61h(status of keyboard)
		or al, 80h                      ; al or 1000|0000   (make higher bit 1)
		out 61h, al                     ; put al in 61h

		and al, not 80h                 ; al and 0111|1111  (make higher bit 0)
		out 61h, al                     ; put al in 61h

;; ---------------------------------------------------------------------

;; ------------------EOI-----------------------------------------------

		mov al, 20h						; say to PPI that our interrupt is over
		out 20h, al						; so other interrupts can play

;; ---------------------------------------------------------------------




EndOfProg:

end Start