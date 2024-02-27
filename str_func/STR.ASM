.model tiny
.code
.286
org 100h

;----------------------------------------------------------------------
; TODO:
;
;   strlen
;   memchr  (DONE)
;   memset  (DONE)
;   memcpy  (DONE)
;   movmem  (DONE)
;   memcmp  (DONE)
;----------------------------------------------------------------------


Start:

    mov dx, offset array_1
    mov ax, offset array_2

    push 9      ; 3 arg
    push ax     ; 2 arg
    push dx     ; 1 arg


    ;call memset_asm
    ;call memchr_asm
    ;call memcpy_asm
    ;call memcmp_asm
    call memmove_asm

    mov ah, 09h
    int 21h

    mov ax, 4c00h
    int 21h

array_1 db '12345b789$'
array_2 db '12345a789$'

;----------------------------------------------------------------------
;                        memset_asm     
;----------------------------------------------------------------------
;
; Entry:
;
;   1 arg - ptr to array
;   2 arg - number of symbol to set
;   3 arg - size of block of memory
;
; Destr: 
;   al, cx, es, DI
;
; cdecl
;----------------------------------------------------------------------
memset_asm  proc

            CLD                 ; increment

            push ds
            pop es

            push BP             ; save bp
            mov BP, SP  

            mov DI, [BP + 4]    ; bx = 1 agr
            mov al, [BP + 6]    ; al = 2 arg
            mov cx, [BP + 8]    ; ah = 3 arg

            rep stosb           ; for (cx) byte ES:[DI++] = al 

            pop BP
            ret 6               ; clean 3 args in stack
            endp



;----------------------------------------------------------------------
;                        memchr_asm     
;----------------------------------------------------------------------
;
; Entry:
;
;   1 arg - ptr to array
;   2 arg - number of symbol to search
;   3 arg - size of searchinr area
;
; Destr: 
;   al, cx, es, DI, DF
;
;
; Ret:
;   di
;
; cdecl
;----------------------------------------------------------------------
memchr_asm  proc

            CLD                 ; increment

            push ds
            pop es

            push BP             ; save bp
            mov BP, SP  

            mov DI, [BP + 4]    ; bx = 1 agr
            mov al, [BP + 6]    ; al = 2 arg
            mov cx, [BP + 8]    ; ah = 3 arg

            repne scasb         ; for (cx && (al - array[i]) != 0) di++

            sub DI, [BP + 4]    ; str[i] - str | to get index

            pop BP
            ret 6
            endp


;----------------------------------------------------------------------
;                           memcpy_asm
;----------------------------------------------------------------------
;
; Entry:
;
;   1 arg - ptr to destination
;   2 arg - ptr to source
;   3 arg - size of copy area
;
; Destr:
;   al, DI, SI, cx, es
;
;----------------------------------------------------------------------
memcpy_asm      proc  
                CLD                 ; increment

                push ds
                pop es

                push BP             ; save bp
                mov BP, SP  

                mov DI, [BP + 4]    ; bx = 1 dst
                mov SI, [BP + 6]    ; al = 2 src
                mov cx, [BP + 8]    ; ah = 3 size


                memcpy_loop:

                lodsb               ; al = ds:[SI++]
                stosb               ; es:[DI++] = AL

                loop memcpy_loop


                pop bp
                ret 6
                endp


;----------------------------------------------------------------------
;                           memcmp_asm
;----------------------------------------------------------------------
;
;
; Entry:
;
;   1 arg - ptr to array_1
;   2 arg - ptr t0 array_2
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

                repe cmpsb         ; cmp ds:[SI++] to es:[DI++] | (SI - DI)

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



;----------------------------------------------------------------------
;                       memmove_asm
;----------------------------------------------------------------------
;
; Entry:
;
;   1 arg - ptr to destination
;   2 arg - ptr to source
;   3 arg - size of copy area
;
;
; Destr: 
;   di, si, cx, al, es
;----------------------------------------------------------------------
memmove_asm     proc

                push ds
                pop es

                push BP             ; save bp
                mov BP, SP  

                mov DI, [BP + 4]    ; bx = 1 dst
                mov SI, [BP + 6]    ; al = 2 src
                mov cx, [BP + 8]    ; ah = 3 size



                cmp DI, SI ; because in cmp can`t be two blocks of memory

                jae dst_bigger_src
                CLD
                jmp memmove_next

    dst_bigger_src:
                STD   

    memmove_next:        


                memmove_loop:

                lodsb               ; al = ds:[SI++]
                stosb               ; es:[DI++] = AL

                loop memmove_loop

                pop bp
                ret 6
                endp

end Start




        mov ah, 09h                 ;
        mov dx, offset new_str      ; print("\n")
        int 21h                     ;




        

        add dx, 2                   ; skip len and max    
        mov ah, 09h                 ; 
        int 21h                     ; print input password

        mov dx, offset new_str      ; print("\n")
        int 21h                     ;

        mov dx, offset right_password
        int 21h

        mov dx, offset new_str      ; print("\n")
        int 21h                     ;

