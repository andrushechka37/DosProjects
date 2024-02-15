.model tiny
.code
.286
org 100h


Start:
user_input = 99h
up_left_corner = (80 * 5 + 20) * 2


;----------------------------------------------------------------------
    mov bx, offset control_str
    call parse_command_line

    mov di, 0b800h	; adress of the begin of video memory
	mov es, di

	mov di, up_left_corner	; begin of ramk


    cmp ax, 0
    ja user
    jmp array

array:
    call draw_ramka
    mov si, 80h + 13        ; 13 is magic const counted vruchnuy
    call print_text

    mov ax, 4c00h
	int 21h	
user:

    call draw_ramka
    call print_text

    mov ax, 4c00h
	int 21h	

control_str db 'c9cdbbbab0bac8cdbc'
			db '03030303b003030303'

text db "hui"


;=====================================================================+
;                   parse_command_line                                |
;=====================================================================+
;                                                                     |
; Reqaiure: bx - ptr to control_array[0]                              |
;                                                                     |
;                                                                     |
; Destr:                                                              |
;   dx, cl, ax, si, al                                                |
;                                                                     |
;   dh - width                                                        |
;   bl - length                                                       |
;   dl - colour                                                       |
;                                                                     |
;                                                                     |
;                                                                     |
; Result: in SI the begin of array                                    |
;         ax - 1 if user input, 0 if not                              |
;---------------------------------------------------------------------+

parse_command_line      proc

                        mov si, 82h
;----------------------------------------------------------------------                         
                        call get_number

                        mov dh, al;                               width
                        sub dh, 2
;----------------------------------------------------------------------
                        xor cx, cx      ; ch = 0

                        call skip_spaces
                        call get_number


                        mov cl, al ;                          length ->
;----------------------------------------------------------------------
                        call skip_spaces
                        call get_number

                        mov dl, al ;                             colour
;----------------------------------------------------------------------
                        call skip_spaces  
                        call get_number  
                        
                        ; mov al, al                   number of array
;----------------------------------------------------------------------
                        cmp al, user_input
                        je parse_command_line_user

                        mov ah, 18      ; offset for array
                        mul ah          ;

                        add ax, bx
                        mov si, ax

                        mov bl, cl

                        xor ax, ax ; for flag

                        ret
                        

        parse_command_line_user:
                        mov bl, cl
                        sub bl, 2
                        add si, 1
                    
                        mov ax , 1
                        ret
                        endp


;======================================================================
;                       draw_line
;======================================================================
;
;
;                   lkelgnldf.ghndn
;
;
;----------------------------------------------------------------------

draw_line       proc

                call get_number
                call draw_symbol

                call get_number



                push cx

                xor cx, cx
                mov cl, bl

    draw_line_loop:

                call draw_symbol

                loop draw_line_loop

                pop cx

                call get_number
                call draw_symbol

                add di, 80 * 2

                push bx
                xor bh, bh

                shl bx, 1h

                sub di, bx
                sub di, 4
                pop bx

                ret
                endp

;======================================================================
;                       get_number
;======================================================================
; reads from ds:[si] one byte
;
;
; Dest: al
;
; Ret: al
;----------------------------------------------------------------------
get_number      proc

                CLD
                push cx
                xor cx, cx
                xor al, al
            
                lodsb       ; ds[si++] = al
                mov cl, 4

                call make_to_number

                rol al, cl   ; 0000|smth   -> smth|0000
                mov cl, al   ; save first in cl

                lodsb
                
                call make_to_number

                add al, cl    ; al = first_sym|0000 + 0000|sec_sym

                pop cx
                ret
                endp

;======================================================================
;                       skip_spaces
;======================================================================
;
;
;
; Dest: si
;----------------------------------------------------------------------
skip_spaces     proc

                add si, 1

                ret
                endp

;======================================================================
;                       make_to_number
;======================================================================
; makes al number instead of symbol
;
;
; Dest: al
;----------------------------------------------------------------------
make_to_number      proc

                    cmp al, 'a'

                    jb get_number_next
                    sub al, 'a' - 10
                    jmp skip_get_number_next

        get_number_next:
                    sub al, '0'
        skip_get_number_next:

                    ret
                    endp

;======================================================================
;                       draw_symbol
;======================================================================
; 
; colour in dl
;
; Dest: si
;----------------------------------------------------------------------
draw_symbol     proc

                push ax

                stosb       ; ds[si++] = al
                mov al, dl
                stosb

                pop ax
                ret
                endp


;======================================================================
;                       draw_ramka
;======================================================================
;
;
;
;----------------------------------------------------------------------
draw_ramka      proc

                call draw_line

                push cx

                xor cx, cx
                mov cl, dh

    draw_ramka_loop:

                call draw_line
                sub si, 6

                loop draw_ramka_loop

                add si, 6

                call draw_line


                pop cx




                ret
                endp


;======================================================================
;                       print_text
;======================================================================
;
;
; cx = &text
;
; destr ax, bx, dh
;
;----------------------------------------------------------------------

;   dh - width      
;   bl - length  

print_text      proc

                push dx
                mov di, up_left_corner ;
                add dh, 2

                shr dh, 1    ; width / 2

                mov al, dh   ; 
                mov ah, 160  ; ax = width/ 2 * 160
                mul ah       ;

                add di, ax
                xor bh, bh
                add di, bx   ; in di center 

                add si, 1    ; text

                nop
                nop

                mov bx, 80h

                xor cx, cx
                mov cl, [bx] ; size of cmd

                xor ax, ax
                mov ax, si
                sub ax, 80h       ; cx = [80h] - (si - 80h)

                sub cx, ax

                sub di, cx        ; di - cx/2 * 2 - offset for text
                add cx, 1

                pop dx


    print_loop:

                lodsb               ; al = ds:[SI++]
                call draw_symbol    ; es:[DI++] = AL

                loop print_loop
                
                ret
                endp


end	Start