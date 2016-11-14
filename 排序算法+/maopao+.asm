

code    segment para 'code'
        assume cs:code, ds:code, es:code, ss:code
        org 100h
main    proc far

start:
        mov bx,1000h
		
		mov cx, offset msg1 - offset data_buf
		
        ; 显示原始数据
        lea  dx, msg1
        mov  ah, 09h
        int  21h
        call dispall     

	
        ; 排序算法
		mov cx, offset msg1 - offset data_buf
		cld
		call disp_sort

        ; 显示排序后数据
		mov cx, offset msg1 - offset data_buf
        lea  dx, msg2
        mov  ah, 09h
        int  21h
        call dispall     

        mov ax,4c00h
        int 21h

main    endp


data_buf  db  50,49,48,-47,46,-45,44,43,42,41
          db  40,39,38,37,36,35,34,33,32,31
          db  30,29,28,27,26,25,24,23,22,21
          db  10, 9, 8, 7, -6, 5, 4, -3, 2, 1
		  db  20,19,18,17,16,15,14,13,12,11
		  db  20,19,18,17,16,15,14,13,12,11
		  db  20,19,18,17,16,15,14,13,12,11
msg1      db  'Raw Data:', 0dh, 0ah, '$'
msg2      db  'Sorted Data:', 0dh, 0ah, '$'

dispall proc near          ; 子程序功能: 显示DATA_BUF中的数据
        lea  si, data_buf
		mov bh,16
loop2:
		push cx
        lodsb
        call disp_al
		dec bh
		cmp bh,0
		jne t
		call disp_cr
		mov bh,16
		jmp t1
t:      call disp_sp
t1:		pop cx
        loop loop2
        call disp_cr
        ret
dispall endp
disp_al proc near        ; 子程序功能: 按16进制方式显示AL中的数值
        push cx
        mov  bl, al
        mov  dl, bl
        mov  cl, 4
        rol  dl, cl
        and  dl, 0fh     
        call disp4       ; 显示字节高4位
        mov  dl, bl
        and  dl, 0fh
        call disp4       ; 显示字节低4位
        pop  cx
        ret
disp_al endp

disp4   proc near        ; 子程序功能: 将DL中的4 bits数值用ASCII显示出来
        add  dl, 30h     ; 由数值转为对应的ASCII码
        cmp  dl, 3ah     ; 是'0'~'9'转ddd
        jb   ddd
        add  dl, 27h     ; 是'A'~'F'
ddd:    mov  ah, 02h
        int  21h         ; 调用DOS功能，显示DL中的字符
        ret
disp4   endp
disp_cr proc near        ; 子程序功能: 显示回车换行
        mov  ah, 02h
        mov  dl, 0dh
        int  21h
        mov  ah, 02h
        mov  dl, 0ah
        int  21h
        ret
disp_cr endp

disp_sp proc near        ; 子程序功能: 显示空格
        mov  ah, 02h
        mov  dl, ' '
        int  21h
        ret
disp_sp endp

disp_sort proc near
disploop:	
		lea si,data_buf
		push cx	
begin:  
		mov bl,[si]
		inc si
		cmp bl,[si]
		jle disp_mark
		xchg bl,[si]
		mov [si-1],bl
disp_mark:		
		loop begin
		pop cx
		loop disploop
		ret
disp_sort endp



code    ends

        end main

ret




