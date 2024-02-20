.model tiny
.code
.286
org 100h



;; ------------------consts------------------

begin_of_video_mem = 0b800h



Start:
        push begin_of_video_mem
        pop es

        mov bx, (80 * 5 + 40) * 2       ; 
        mov ah, 4eh


Next:   in al, 60h                      ; from 60h port to al
        mov es:[bx], ax
        
        
        cmp al, 11d
        jne Next

        ret        


end Start