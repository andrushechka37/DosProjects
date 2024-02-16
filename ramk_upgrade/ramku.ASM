.model tiny
.code
.286
org 100h


Start:

;----------------------------------------------------------------------
user_input = 99h
up_left_corner = (80 * 5 + 20) * 2

begin_of_command_line = 80h
begin_0f_video_mem    = 0b800h

size_of_control_str = 9

size_sym_line         = 80
size_sym_col_default  = 24

;----------------------------------------------------------------------
    mov bx, offset control_str
    call parse_command_line

    mov di, begin_0f_video_mem	              ; adress of the begin of video memory
	mov es, di


	;mov di, up_left_corner	                  ; begin of ramk
    call set_left_up_corner


    cmp ax, 0                                 ; ax is flag user or control string (makes in parse_command_line)
    ja user
    jmp array

array:
    call draw_ramka
    mov si, begin_of_command_line + 13        ; 13 is magic const counted vruchnuy

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

                        mov ah, size_of_control_str * 2      ; offset for array
                        mul ah          ;

                        add ax, bx      ;
                        mov si, ax      ; si += x * 18

                        mov bl, cl      ; length in bl

                        xor ax, ax      ; for flag

                        ret
                        

        parse_command_line_user:

                        mov bl, cl      ; width in bl
                        sub bl, 2       ; strange fix----------------------?
                        add si, 1       ; start of array
                    
                        mov ax , 1      ; for flag
                        ret
                        endp


;======================================================================
;                       draw_line
;======================================================================
;
; Require: di - left_up_corner
;          si - begin of control array
;          es - 0b800h
;                   
; Destr: si, di
;
;----------------------------------------------------------------------

draw_line       proc

                call get_number
                call draw_symbol

                call get_number



                push cx

                xor cx, cx                  ;   
                mov cl, bl                  ; mov cx, bl

    draw_line_loop:

                call draw_symbol

                loop draw_line_loop

                pop cx

                call get_number
                call draw_symbol

                add di, size_sym_line * 2   ; next line

                push bx

                xor bh, bh                  ;
                                            ;
                shl bx, 1h                  ;
                                            ; to begin of str
                sub di, bx                  ;
                sub di, 4                   ;


                pop bx

                ret
                endp

;======================================================================
;                       get_number
;======================================================================
; reads from ds:[si] one byte
;
;
; Dest: al, DF
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
; makes al number instead of symbol (sym to hex)
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
; Require : colour in dl
;
; Dest: si,
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
; Require: di - left_up_corner
;          si - begin of control array
;          es - 0b800h
;                   
; Destr: si, di
;----------------------------------------------------------------------
draw_ramka      proc

                call draw_line

                push cx

                xor cx, cx      ;
                mov cl, dh      ; cx = count of middle strs
                sub cl, 2

    draw_ramka_loop:

                call draw_line
                sub si, 6       ; to print again middle symbols

                loop draw_ramka_loop

                add si, 6       ; to skip middle symbols

                call draw_line


                pop cx


                ret
                endp


;======================================================================
;                       print_text
;======================================================================
;
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;           !!!!!!!!!!!!!!!PLACE HOLDER!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; destr ax, bx, dh
;
;----------------------------------------------------------------------

;   dh - width      
;   bl - length  

print_text      proc

                push dx
                ;mov di, up_left_corner 
                call set_left_up_corner

                shr dh, 1                           ; width / 2

                mov al, dh                          ; 
                mov ah, size_sym_line * 2           ; ax = width/ 2 * 160
                mul ah                              ;

                add di, ax
                xor bh, bh
;---------------------------------------------------------------------------------------
                test bx, 1
                jne print_text_nech     ; costul because smth happens and need to alline
                add di, 1
    print_text_nech:            
;---------------------------------------------------------------------------------------
                add di, bx                          ; in di center 

                add si, 1                           ; text

                nop
                nop

                mov bx, begin_of_command_line

                xor cx, cx
                mov cl, [bx]                        ; size of cmd

                xor ax, ax
                mov ax, si
                sub ax, begin_of_command_line       ; cx = [80h] - (si - 80h)

                sub cx, ax

                sub di, cx                          ; di - cx/2 * 2 - offset for text
                add cx, 1

                mov ax, cx

                call make_di_parity

                pop dx


    print_loop:

                lodsb               ; al = ds:[SI++]
                call draw_symbol    ; es:[DI++] = AL

                loop print_loop
                
                ret
                endp

;======================================================================
;                       set_left_up_corner
;======================================================================
;
;
; Ret: di - up_left corner
;
; Destr: di
;----------------------------------------------------------------------
;   dh - width      
;   bl - length 

set_left_up_corner      proc

                        push ax
                        push bx

                        xor di, di

                        mov al, size_sym_col_default     ;   
                        sub al, dh                       ; y = (y0 - wigth) / 2 | countity of lines
                        shr al, 1

                        mov ah, size_sym_line * 2   ; ax = 160 * y
                        mul ah                      ;

                        add di, ax

                        xor ax, ax                  
                        xor bh, bh                 

                        mov al, size_sym_line       ;
                        sub al, bl                  ; di += (default_length - length_ramka) / 2 * 2

                        add di, ax                  ;

                        xor ax, ax
                        mov al, bl
                        call make_di_parity

                        pop bx
                        pop ax

                        ;mov di, up_left_corner

                        ret
                        endp

;======================================================================
;                       make_di_parity
;======================================================================
;
;
; 
; Destr: di
;
;----------------------------------------------------------------------
make_di_parity      proc

                    test ax, 1
                    jne nechet
                    jmp skip_chetn

        nechet:
                    add di, 1       ; becaue di - cx can be nechetn
        skip_chetn:
                    ret
                    endp

end	Start