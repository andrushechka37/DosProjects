.model tiny
.code
.286
org 100h



;; ------------------const----------------------------------------------

KEYBOARD_ENTER = 0ah
EXIT_CODE      = 4c00h

;; ---------------------------------------------------------------------

        
Start:

        mov ah, 09h                 ;
        mov dx, offset new_str      ; print("\n")
        int 21h                     ;

        call get_password
        call transform_password

        add dx, 2                   ; skip len and max    
        mov ah, 09h                 ; 
        int 21h                     ; print password

        mov dx, offset new_str      ; print("\n")
        int 21h                     ;

        mov dx, offset right_password
        int 21h

        mov dx, offset new_str      ; print("\n")
        int 21h                     ;


        mov dx, offset str_buffer
        add dx, 2
        call check_password

;; ---------------------------------------------------------------------

        mov ax, EXIT_CODE    ; Terminate
        int 21h              ;











;; =====================================================================
;;                          get_password
;; =====================================================================
;; gets password from stdin
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Return: 
;;
;;
;; Destr:  /AH/  --  KEYBOARD_ENTER
;;
;;         /DX/  --  &password_buffer
;; ---------------------------------------------------------------------
get_password         proc

                mov ah, KEYBOARD_ENTER             ; arg for 21h        
                mov dx, offset str_buffer          ; &password_buffer   
                int 21h                            ;                    

                ret
                endp




;; =====================================================================
;;                          transform_password
;; =====================================================================
;; makes password very very encrypted
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect:    /DX/  --  ptr to array like --------> |max|len|. . . . . . .CR 000000000|     CR -  CR (ASCII 0dH), ENTER
;;                                                          |            |            |
;;                                                          |  <-len->   |            |
;;                                                          |                         |
;;                                                          | <-------- max --------> |
;;
;; Entry: 
;;
;; Destr: /BX/  /CX/  
;; ---------------------------------------------------------------------
transform_password          proc

                mov bx, dx

                xor cx, cx

                mov cl, [bx + 1]            ; cx = len of array
                sub cl, 2

                add bx, 2                   ; skip len and max

;; --------------------exchange of password------------------------------

        exchange_cycle:

                mov al, [bx]

                xchg al, [bx + 1]          ;

                mov [bx], al
                inc bx                     ; need to do it fast -------------------------------------------------------------------------------------------???????????????????

                loop exchange_cycle

;; ---------------------------------------------------------------------

                ret
                endp




;; =====================================================================
;;                          check_password
;; =====================================================================
;; checks if password right and exposes flag of password to 0 or 1
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect:    /DX/  --  ptr to array like --------> |max|len|. . . . . . .CR 000000000|     CR -  CR (ASCII 0dH), ENTER
;;                                                          |            |            |
;;                                                          |  <-len->   |            |
;;                                                          |                         |
;;                                                          | <-------- max --------> |
;;
;; Destr: 
;; ---------------------------------------------------------------------
check_password       proc

                cld

                mov si, offset right_password   ; 1 array

                mov di, offset str_buffer       ; 2 array
                add di, 2                       ; skip len and size

                push ds                         ;
                pop es                          ; es = ds

                mov cx, 6

                repe cmpsb          ; cmp ds:[SI++] to es:[DI++] | (SI - DI)


                mov ah, 09h
                
                jne not_equal

                
                mov dx, offset right_input      
                int 21h                  

                ret

not_equal:                

                mov dx, offset wrong_input      
                int 21h   
                ret

                endp






;----------------------------------------------------------------------
;                           memcmp_asm
;----------------------------------------------------------------------
;
;
; Entry:
;
;   1 arg - ptr to array_1
;   2 arg - ptr to array_2
;   3 arg - size of compare area
;
; Destr:
;   es, di, di, si, cx
;
; Ret: cx (not to spoil ax)
;
;   cx =  0  -> arrays are equal
;   cx = -1  -> 2 array is bigger
;   cx =  1  -> 1 array is bigger
;-----------------------------------------
memcmp_asm      proc
                CLD                 ; increment

                push ds
                pop es

                push BP             ; save bp
                mov BP, SP  

                mov DI, [BP + 4]    ; bx = 1 arr 1
                mov SI, [BP + 6]    ; al = 2 arr 2
                mov cx, [BP + 8]    ; ah = 3 size

                repe cmpsb          ; cmp ds:[SI++] to es:[DI++] | (SI - DI)

                je equal_memcpy
                ja second_bigger
                jmp first_bigger

    equal_memcpy:

                mov cx, 0
                jmp  end_mempy 
    second_bigger:

                mov cx, -1
                jmp  end_mempy
    first_bigger:

                mov cx, 1
                jmp  end_mempy       

    end_mempy:
                pop bp
                ret 6
                endp



right_input db "pravilno!!!$"
wrong_input db "nepravilno$"









new_str:
       db 10
       db '$'

str_buffer:

       db 100                       ; max chars to enter
buffer db 60 DUP (?)                ; password buffer
is_password_right    db 0

right_password db "233211$"


        
end Start