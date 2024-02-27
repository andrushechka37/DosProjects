.model tiny
.code
.286
org 100h



;; ------------------const----------------------------------------------

KEYBOARD_ENTER  = 0ah
EXIT_CODE       = 4c00h
LEN_OF_PASSWORD = 6

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

                cld

                mov si, offset right_password   ; 1 array
                mov di, offset str_buffer       ; 2 array
                add di, 2                       ; skip len and size

                push ds                         ;
                pop es                          ; es = ds

                mov cx, LEN_OF_PASSWORD         

                repe cmpsb                      ; cmp ds:[SI++] to es:[DI++] | (SI - DI)

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

                mov dx, offset right_input
                int 21h

                ret
                endp




;; =====================================================================
;;                          memcmp_asm
;; =====================================================================
;; works like standart memcmp
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;
;; Expect: /ES/ = /DS/
;;
;;        
;;
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

                push ds
                pop es


                pop si
                pop di
                pop cx




                ret
                endp


right_input db "pravilno!!!$"
wrong_input db "nepravilno$"





new_str:
       db 10
       db '$'

str_buffer:

       db 100                       ; max chars to enter
buffer db 8 DUP (?)                 ; password buffer

;<------------------------ a place for canary-----------------------------------------------------------------------------------------------------------

is_password_right    db 0

;<------------------------ a place for canary-----------------------------------------------------------------------------------------------------------
; write check canaries

right_password db "233211"



end Start

