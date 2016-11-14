

code    segment para 'code'
        assume cs:code, ds:code, es:code, ss:code
        org 100h
main    proc far

start:
        mov bx,1000h
		
		mov cx, offset msg1 - offset data_buf
		
        ; ��ʾԭʼ����
        lea  dx, msg1
        mov  ah, 09h
        int  21h
        call dispall     

	
        ; �����㷨
		mov cx, offset msg1 - offset data_buf
		cld
		call disp_sort

        ; ��ʾ���������
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

dispall proc near          ; �ӳ�����: ��ʾDATA_BUF�е�����
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
disp_al proc near        ; �ӳ�����: ��16���Ʒ�ʽ��ʾAL�е���ֵ
        push cx
        mov  bl, al
        mov  dl, bl
        mov  cl, 4
        rol  dl, cl
        and  dl, 0fh     
        call disp4       ; ��ʾ�ֽڸ�4λ
        mov  dl, bl
        and  dl, 0fh
        call disp4       ; ��ʾ�ֽڵ�4λ
        pop  cx
        ret
disp_al endp

disp4   proc near        ; �ӳ�����: ��DL�е�4 bits��ֵ��ASCII��ʾ����
        add  dl, 30h     ; ����ֵתΪ��Ӧ��ASCII��
        cmp  dl, 3ah     ; ��'0'~'9'תddd
        jb   ddd
        add  dl, 27h     ; ��'A'~'F'
ddd:    mov  ah, 02h
        int  21h         ; ����DOS���ܣ���ʾDL�е��ַ�
        ret
disp4   endp
disp_cr proc near        ; �ӳ�����: ��ʾ�س�����
        mov  ah, 02h
        mov  dl, 0dh
        int  21h
        mov  ah, 02h
        mov  dl, 0ah
        int  21h
        ret
disp_cr endp

disp_sp proc near        ; �ӳ�����: ��ʾ�ո�
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




