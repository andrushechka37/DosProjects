.model tiny
.code
.286
org 100h



;; ------------------const----------------------------------------------

KEYBOARD_ENTER  = 0ah
EXIT_CODE       = 4c00h
LEN_OF_PASSWORD = 6
LEN_OF_CANARY   = 3

;; ---------------------------------------------------------------------

        
Start:

        call get_password
        call transform_password

        call check_password
        call give_access

;; ---------------------------------------------------------------------

        mov ax, EXIT_CODE    ; Terminate
        int 21h              ;





;; =====================================================================
;;                          get_password
;; =====================================================================
;; gets password from stdin
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
;; makes password very very encrypted (rol 1  <---)
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect:    /DX/  --  ptr to array like --------> |max|len|. . . . . . .CR 000000000|     CR - (ASCII 0dH), ENTER
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

                mov bx, dx                  ; we cant index on dx

                xor cx, cx

                mov cl, [bx + 1]            ; cx = len of array
                sub cl, 1                   ; not to spoil '$' in the end

                add bx, 2                   ; skip len and max

;; --------------------exchange of password------------------------------

        exchange_cycle:

                mov al, [bx]               ;
                xchg al, [bx + 1]          ; swap([bx], [bx + 1])
                mov [bx], al               ;

                inc bx                     
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
;; Return: is_password_right 0 or 1 depending on password
;;
;;
;; Destr: /SI/  /DI/  /ES/  /CX/
;; ---------------------------------------------------------------------
check_password       proc

;; ----------------------------memcmp-----------------------------------   

                push LEN_OF_PASSWORD
                push offset str_buffer + 2
                push offset right_password

                call memcmp_asm

;; ---------------------------------------------------------------------

                jne not_equal

                mov is_password_right, 1

        not_equal:             

                ret
                endp



;; =====================================================================
;;                          give_access
;; =====================================================================
;; prints pravilno or not 
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Side Effects: prints status of access depenging of staus of flag (is_password_right)
;;
;; Destr: /AH/  /DX/
;; ---------------------------------------------------------------------
give_access     proc

                mov ah, 09h

                cmp is_password_right, 0
                jne eqaual_pass

                mov dx, offset wrong_input
                int 21h
                ret

        eqaual_pass:

;; -----------------------------canary check----------------------------

                push LEN_OF_CANARY
                push offset right_canary
                push offset canary

                call memcmp_asm

;; ---------------------------------------------------------------------

                jne cheater

                mov dx, offset right_input
                int 21h
                ret

        cheater:
                mov dx, offset cheater_input
                int 21h
                ret


                endp




;; =====================================================================
;;                          memcmp_asm
;; =====================================================================
;; works like standart memcmp
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Entry: 1 arg  --  offset to 1 array
;;
;;        2 arg  --  offset to 2 array
;;
;;        3 arg  --  len of arrays(comnpare area)
;;
;;
;; Destr: /ES/  /SI/  /DI/  /CX/
;; ---------------------------------------------------------------------
memcmp_asm      proc

                cld   

                push bp
                mov bp, sp

                push ds
                pop es


                mov si, [bp + 4]
                mov di, [bp + 6]
                mov cx, [bp + 8]


                repe cmpsb                      ; cmp ds:[SI++] to es:[DI++] | (SI - DI)

                pop bp
                ret 6
                endp

;; ---------------------------------------------------------------------


;; --------------------------phrases to print---------------------------

right_input db "pravilno!!!$"
wrong_input db "nepravilno$"
cheater_input db "fuck you:)$"

;; ---------------------------------------------------------------------


right_canary:
        db "abc"

str_buffer:

       db 100                       ; max chars to enter
buffer db 8 DUP (?)                 ; password buffer

canary:

        db "abc"

is_password_right    db 0


right_password db "233211"



end Start

