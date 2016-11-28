;
; N!
;
code    segment para 'code'
        assume cs:code, ds:code, es:code, ss:code

        org 100h

main    proc near

        cmp  byte ptr ds:[80h], 2
        jnz  error
        mov  al, byte ptr ds:[82h]
        cmp  al, '0'
        jb   error
        cmp  al, '9'
        ja   error

        and  al, 0fh
        xor  ah, ah
;
		mov bx,ax
		cmp ax,1
		ja  t
		mov dx,0
		mov ax,1
		jmp xianshi
t:		mov ax,1
		mov cx,1
xunhuan:inc  cx
		mul  cx
		cmp  cx,bx
		jb   xunhuan
xianshi:push ax
		push dx
        ;  Code for Calculating AX!
        ;  Store result in DX:AX
        ;
        lea  dx, msg
        mov  ah, 09h
        int  21h
		pop dx
		pop ax
        call dispresult

        jmp  short ret_dos

error:
        lea  dx, err_msg
        mov  ah, 09h
        int  21h

ret_dos:
        int  20h

main    endp
dispresult proc      	;将结果转换为十进制并显示  
		mov  si, offset buf
        mov  bx, 10
loop1:  div  bx
        mov  [si], dl
        or   ax, ax
        jz   disp
        inc  si
        xor  dx, dx
        jmp  short loop1
disp:   mov  dl, [si]
        or   dl, 30h
        mov  ah, 2
        int  21h
        dec  si
        cmp  si, offset buf
        jnb  disp

        mov  dl, 0dh 
        mov  ah, 2 
        int  21h 
        mov  dl, 0ah 
        mov  ah, 2 
        int  21h 
        ret
dispresult endp

msg     db 'Result = $'
err_msg db 'Error Parameter !', 0dh, 0ah, '$'
buf     db 10 dup(?)

code    ends

        end main