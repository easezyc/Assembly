DATA SEGMENT
CNT DB 00H
msg db 'Interrupt!'
db 0dh,0ah,0
count db 0
last db 51
hour db 0
minute db 0
secd db 0
datafile DB 'setnow.cfg',0
errormsg DB 'open error','$'
time db '23:59:55'
DATA ENDS
STACK SEGMENT STACK
DW 100 DUP(?)
STACK ENDS
CODE SEGMENT PUBLIC 'CODE'
ASSUME CS:CODE,DS:DATA, SS:STACK
main    proc far
START: 	push ds
        xor  ax, ax
        push ax
        mov ax, data
        mov ds, ax
		CLI ; 修改中断向量前关中断
		XOR AX,AX
		MOV ES,AX ;es 段 =0
		MOV BX,08H*4; 修改 08 号向量表的内容
		MOV AX,OFFSET INTR ; 中断入口地址
		MOV ES:[BX],AX ;
		MOV AX,SEG INTR
		MOV ES:[BX+2],AX
		STI ; 开中断
		mov ah,3dh
		lea dx,datafile
		mov al,0
		int 21h
		jc error
		mov bx,ax
		mov ah,3fh
		lea dx,time
		mov cx,8
		int 21h
		jc error
		mov ah,3eh
		int 21h
		jc error
		jmp p
		error:	mov ah,09h
		lea dx,errormsg
		int 21h
		ret
p:		
		mov bl,10
		mov al,time[0]
		sub al,30h
		mul bl
		mov ah,time[1]
		sub ah,30h
		add al,ah
		mov hour,al
		mov al,time[3]
		sub al,30h
		mul bl
		mov ah,time[4]
		sub ah,30h
		add al,ah
		mov minute,al
		mov al,time[6]
		sub al,30h
		mul bl
		mov ah,time[7]
		sub ah,30h
		add al,ah
		mov secd,al
again:	mov al,secd
		cmp al,60
		jc lp1
		mov secd,0 ; 满 60 清 0 0
		inc minute
		mov al,minute
		cmp al,60
		jc lp1
		mov minute,0
		inc hour
		mov al,hour
		cmp al,24
		jc lp1
		mov hour,0
lp1: 	mov al,secd
		cmp al,last; 显示值是否已更新
		jz lp1
		mov last,al
		
		mov al,hour
		mov bl,10
		mov ah,0
		div bl
		mov bx,ax
		add bx,3030h; 变为 ASC 码
		mov ah,02
		mov dl,bl
		int 21h ; 显示十位
		mov ah,02
		mov dl,bh
		int 21h ; 显示个位
		mov dl, 0dh
		
		mov ah,02h
		mov dl,3ah
		int 21h
		
		mov al,minute
		mov bl,10
		mov ah,0
		div bl
		mov bx,ax
		add bx,3030h; 变为 ASC 码
		mov ah,02
		mov dl,bl
		int 21h ; 显示十位
		mov ah,02
		mov dl,bh
		int 21h ; 显示个位
		mov dl, 0dh
		
		mov ah,02h
		mov dl,3ah
		int 21h
		
		mov al,secd
		mov bl,10
		mov ah,0
		div bl
		mov bx,ax
		add bx,3030h; 变为 ASC 码
		mov ah,02
		mov dl,bl
		int 21h ; 显示十位
		mov ah,02
		mov dl,bh
		int 21h ; 显示个位
		mov dl, 0dh
		mov ah, 02; 回车
		int 21h
		jmp again

main    endp
intr proc
	sti
	push ax
	push ds
	mov ax,data
	mov ds,ax
	inc count
	cmp count,18
	jnz lp2
	mov count,0
	inc secd
	lp2: mov al,20h
	out  20h,al ; EOI 命令
	pop ds
	pop ax
	iret
intr endp
CODE ENDS
END START