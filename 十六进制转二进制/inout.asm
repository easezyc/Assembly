
code    segment para 'code'
        assume cs:code, ds:code, es:code, ss:code
        org 100h
main    proc far

start:
        mov bx,1000h

l:      call input    
        call output   
        jmp  l  

        mov ax,4c00h
        int 21h

main    endp

num0      db  '0000 ', '$'
num1      db  '0001 ', '$'
num2      db  '0010 ', '$'
num3      db  '0011 ', '$'
num4      db  '0100 ', '$'
num5      db  '0101 ', '$'
num6      db  '0110 ', '$'
num7      db  '0111 ', '$'
num8      db  '1000 ', '$'
num9      db  '1001 ', '$'
num10     db  '1010 ', '$'
num11     db  '1011 ', '$'
num12     db  '1100 ', '$'
num13     db  '1101 ', '$'
num14     db  '1110 ', '$'
num15     db  '1111 ', '$'
save      db  '1111 ' , '$'

input   proc near
		lea		di,save
		mov		cx,4h
lp:		mov		ah,01h
		int		21h
		stosb
		dec		cx
		jnz		lp
		call	disp_cr
        ret
input   endp
output	proc	near
		lea  si,save
		mov  cx,4
a:		lodsb
		cmp  al,3ah
		jnc  t
		sub  al,30h
		jmp  p
t:		cmp  al,5Bh
        jnc  o
        sub  al,37h 
        jmp  p
o:      sub  al,57h       
p:		mov  ah,0h
        mov  bl,06h
        mul  bl
		mov  dx,offset num0
		add  dx,ax
        mov  ah, 09h
        int  21h
		dec  cx
		jnz  a 
		call disp_cr
		ret
output	endp
disp_cr proc near        ; 子程序功能: 显示回车换行
        mov  ah, 02h
        mov  dl, 0dh
        int  21h
        mov  ah, 02h
        mov  dl, 0ah
        int  21h
        ret
disp_cr endp
code    ends

        end main

ret




