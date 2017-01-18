	  PAGE	  60,132
	  .MODEL  small
	  .DATA
	  EXTRN	  statatr:BYTE,scrnatr:BYTE,sbuffer:WORD,pbuffer:WORD
	  EXTRN	  fsize:WORD,cell:WORD,statline:BYTE,linenum:WORD
	  EXTRN	  rows:WORD,vidadr:WORD,cga:BYTE
	  EXTRN	  searchmark:BYTE,searchline:BYTE
	  EXTRN	  strlen:BYTE,searchstr:BYTE,matchedline:BYTE,count:WORD
	  EXTRN	  scannum:WORD,scanhead:WORD,highlight:BYTE
	  .CODE
	  PUBLIC  Pager,isEGA,Dissearch,Disinput

; Procedure Pager
; Purpose   Displays status and	text lines
; Input	    Stack variable: lines to scroll (negative up, positive down)
;	    Global variables: "sbuffer", "pbuffer", "linenum"
; Output    To screen

Pager	  PROC
	  push	  bp
	  mov	  bp,sp

	  mov	  es,sbuffer		; Initialize buffer position
	  mov	  di,pbuffer

	  mov	  cx,[bp+4]		; Get count argument
	  mov	  ax,10			; Search for linefeed

	  or	  cx,cx			; Argument 0?
	  jg	  forward		; If above, forward
	  jl	  backward		; If below, backward
	  jmp	  SHORT	show		; If equal, done

backward: call	  GoBack		; Adjust backward
	  jmp	  SHORT	show		; Show screen
forward:  call	  GoForwd		; Adjust forward

; Write	line number to status line

show:	  cld				; Go forward
	  push	  di
	  push	  es
	  push	  ds			; Load DS to ES
	  pop	  es

; BinToStr (linenum,OFFSET statline[7])

	  push	  linenum		; Arg 1
	  mov	  ax,OFFSET statline[7]
	  push	  ax			; Arg 2
	  call	  BinToStr		; Convert to string

; Fill in status line

	  mov	  cx,7			; Seven	spaces to fill
	  sub	  cx,ax			; Subtract those already done
	  mov	  al," "		; Fill with space
	  rep	  stosb
	  pop	  es

	  mov	  bl,statatr		; Load status attribute
	  mov	  BYTE PTR cell[1],bl

; CellWrt (DS,OFFSET statline,0,cell)

	  push	  ds			; Arg 1
	  mov	  ax,OFFSET statline	; Arg 2
	  push	  ax
	  sub	  ax,ax			; Arg 3
	  push	  ax
	  push	  cell			; Arg 4
	  call	  CellWrt		; Write	status line

	  pop	  di
	  mov	  bl,scrnatr		; Load screen attribute
	  mov	  BYTE PTR cell[1],bl
	  mov	  si,di			; Update position
	  mov	  cx,rows		; Lines	per screen

show1:	  mov	  bx,rows		; Lines	of text
	  inc	  bx			; Adjust for 0
	  sub	  bx,cx			; Calculate current row
	  push	  cx			; Save line number

; CellWrt (sbuffer,position,line,cell)

	  push	  sbuffer		; Arg 1
	  push	  si			; Arg 2
	  push	  bx			; Arg 3
	  push	  cell			; Arg 4
	  call	  cellwrt		; Write	line

	  push	  ss			; Restore DS from SS
	  pop	  ds

	  pop	  cx			; Restore line number
	  mov	  si,ax			; Get returned position

	  cmp	  ax,fsize		; Beyond end of	file?
	  jae	  fillout		; Yes? Fill screen with	spaces
	  loop	  show1			;    else next line
	  jmp	  SHORT	pagedone	; Get out if done

; Fill the rest	with spaces

fillout:  dec	  cx			; Adjust
	  jcxz	  pagedone
	  mov	  al,80			; Columns times	remaining lines
	  mul	  cl

; CellFil (sbuffer,count,cell)

	  push	  sbuffer		; Arg 1
	  push	  ax			; Arg 2
	  push	  cell			; Arg 3
	  call	  CellFil		; Fill screen with spaces

	  push	  ss			; Restore DS from SS
	  pop	  ds

pagedone: 
	  mov	  searchmark,0
	  pop	  bp
	  ret	  2
Pager	  ENDP

; Procedure CellWrt (segment,offset,line,cell)
; Purpose   Writes a line to screen buffer
; Input	    Stack variables: 1 - segment of line
;			     2 - offset
;			     3 - line number
;			     4 - attribute
; Output    Line to screen buffer

CellWrt	  PROC
	  push	  bp
	  mov	  bp,sp
	  sub	  dx,dx			; Clear	as flag	for scan
	  cmp	  cga,1			; CGA?
	  jne	  noscan
	  mov	  dx,03DAh		; Load port #

noscan:	  mov	  es,vidadr		; Load screen buffer segment
	  mov	  ds,[bp+10]		; Buffer segment
	  mov	  si,[bp+8]		; Buffer position
	  mov	  cx,80			; Cells	per row
	  mov	  ax,[bp+6]		; Starting row
	  mov	  bx,80*2		; Bytes	per row
	  mul	  bl			; Figure columns per row
	  mov	  di,ax			; Load as destination
	  mov	  bx,di			; Save start for tab calculation
	  mov	  ax,[bp+4]		; Attribute
movechar: lodsb				; Get character
	  cmp	  al,13			; CR?
	  je	  fillspc
	  cmp	  al,9			; Tab?
	  jne	  notab
	  call	  filltab		; Yes? fill with spaces
	  jcxz	  nextline		; If beyond limit done
	  jmp	  SHORT	movechar

notab:	  or	  dx,dx			; CGA?
	  je	  notab2
	  call	  Retrace		; Yes? Write during retrace
	  loop	  movechar
	  jmp	  SHORT	nextline

notab2:	  stosw				; Write
	  loop	  movechar
	  jmp	  SHORT	nextline	; Done

fillspc:  mov	  al," "		; Fill with space

	  or	  dx,dx			; CGA?
	  je	  space2
space1:	  call	  Retrace		; Yes? Write during retrace
	  loop	  space1
	  inc	  si			; Adjust
	  jmp	  SHORT	exit		; Done

space2:	  rep	  stosw			; Write
	  inc	  si			; Adjust for LF
	  jmp	  SHORT	exit		; Done

nextline: mov	  ah,10			; Search for next line feed
chklf:	  lodsb				; Load and compare
	  cmp	  al,ah
	  loopne  chklf

exit:	  mov	  ax,si			; Return position
	  pop	  bp
	  ret	  8
CellWrt	  ENDP

; Procedure CellFil (segment,count,cell)
; Purpose   Fills screen with character
; Input	    Stack variables: 1 - segment of text (offset 0)
;			     2 - number	of characters
;			     3 - attribute and character
; Output    Characters to screen buffer

CellFil	  PROC
	  push	  bp
	  mov	  bp,sp
	  sub	  dx,dx			; Clear	as flag	for scan
	  cmp	  cga,1			; CGA?
	  jne	  noscan2
	  mov	  dx,03DAh		; Load port #

noscan2:  mov	  es,vidadr		; Load screen buffer segment
	  mov	  ds,[bp+8]		; Buffer segment (position 0)
	  mov	  cx,[bp+6]		; Characters to	fill
	  mov	  ax,[bp+4]		; Attribute
	  or	  dx,dx			; CGA?
	  je	  fillem2
fillem1:  call	  Retrace		; Yes? Write during retrace
	  loop	  fillem1
	  jmp	  SHORT	filled		; Done
fillem2:  rep	  stosw			; Write

filled:	  pop	  bp
	  ret	  6
CellFil	  ENDP

; Procedure FillTab
; Purpose   Writes spaces for tab to screen
; Input	    BX points to start of line,	DI points to current position
; Output    Spaces to screen buffer

FillTab	  PROC
	  push	  bx
	  push	  cx

	  sub	  bx,di			; Get current position in line
	  neg	  bx
	  shr	  bx,1			; Divide by 2 bytes per	character

	  mov	  cx,8			; Default count	8
	  and	  bx,7			; Get modulus
	  sub	  cx,bx			; Subtract
	  mov	  bx,cx			; Save modulus

	  mov	  al," "		; Spaces
	  or	  dx,dx			; CGA?
	  je	  tabem2

tabem1:	  call	  Retrace		; Yes? Write during retrace
	  loop	  tabem1
	  jmp	  SHORT	tabbed
tabem2:	  rep	  stosw			; Write

tabbed:	  pop	  cx
	  sub	  cx,bx			; Adjust count
	  jns	  nomore		; Make negative	count 0
	  sub	  cx,cx
nomore:	  pop	  bx
	  ret
FillTab	  ENDP

; Procedure GoBack
; Purpose   Searches backward through buffer
; Input	    CX has number of lines; ES:DI has buffer position
; Output    Updates "linenum" and "pbuffer"

GoBack	  PROC
	  std				; Go backward
	  neg	  cx			; Make count positive
	  mov	  dx,cx			; Save a copy
	  inc	  cx			; One extra to go up one
	  or	  di,di			; Start	of file?
	  je	  exback		; If so, ignore
findb:	  push	  cx			;   else save count
	  mov	  cx,0FFh		; Load maximum character count
	  cmp	  cx,di			; Near start of	buffer?
	  jl	  notnear		; No? Continue
	  mov	  cx,di			;   else search	only to	start
notnear:  repne	  scasb			; Find last previous LF
	  jcxz	  atstart		; If not found,	must be	at start
	  pop	  cx
	  loop	  findb
	  cmp	  linenum,0FFFFh	; End of file flag?
	  jne	  notend		; No? Continue
	  add	  di,2			; Adjust for cr/lf
	  mov	  pbuffer,di		; Save position
	  call	  EndCount		; Count	back to	get line number
	  ret

notend:	  sub	  linenum,dx		; Calculate line number
	  jg	  positive
	  mov	  linenum,1		; Set to 1 if negative
positive: add	  di,2			; Adjust for cr/lf
	  mov	  pbuffer,di		; Save position
	  ret

atstart:  pop	  cx
	  sub	  di,di			; Load start of	file
	  mov	  linenum,1		; Line 1
	  mov	  pbuffer,di		; Save position
exback:	  ret
GoBack	  ENDP

; Procedure GoForwd
; Purpose   Searches forward through a buffer
; Input	    CX has number of lines; ES:DI has buffer position
; Output    Updates "linenum" and "pbuffer"

GoForwd	  PROC
	  cld				; Go forward
	  mov	  dx,cx			; Copy count
findf:	  push	  cx			; Save count
	  mov	  cx,0FFh		; Load maximum character count
	  repne	  scasb			; Find next LF
	  jcxz	  atend			; If not found,	must be	at end
	  cmp	  di,fsize		; Beyond end?
	  jae	  atend
	  pop	  cx
	  loop	  findf
	  add	  linenum,dx		; Calulate line	number
	  mov	  pbuffer,di		; Save position
	  ret

atend:	  pop	  cx
	  mov	  di,pbuffer		; Restore position
	  ret
GoForwd	  ENDP

; Procedure EndCount
; Purpose   Counts backward to count lines in file
; Input	    ES:DI has buffer position
; Output    Modifies "linenum"

EndCount  PROC
	  push	  di

	  mov	  al,13			; Search for CR
	  mov	  linenum,0		; Initialize

findstrt: inc	  linenum		; Adjust count
	  mov	  cx,0FFh		; Load maximum character count
	  cmp	  cx,di			; Near start of	buffer?
	  jl	  notnear2		; No? Continue
	  mov	  cx,di			;   else search	only to	start
notnear2: repne	  scasb			; Find last previous cr
	  jcxz	  found			; If not found,	must be	at start
	  jmp	  SHORT	findstrt

found:	  pop	  di
	  ret
EndCount  ENDP

; Procedure isEGA
; Purpose   Determines if an EGA is active
; Input	    None
; Output    0 if no; lines per screen if yes

isEGA	  PROC
	  push	  bp
	  push	  es
	  mov	  ah,12h		; Call EGA status function
	  mov	  bl,10h
	  sub	  cx,cx			; Clear	status bits
	  int	  10h
	  sub	  ax,ax			; Segment 0 and	assume no EGA
	  jcxz	  noega			; If status still clear, no EGA

	  mov	  es,ax			; ES=0
	  test	  BYTE PTR es:[487h],1000b ; Test active bit
	  jnz	  noega			; If set, not active
	  mov	  ax,1130h		; Get EGA information
	  int	  10h
	  mov	  al,dl			; Return lines per screen
	  cbw

noega:	  pop	  es
	  pop	  bp
	  ret
isEGA	  ENDP

; Procedure BinToStr (number,address)
; Purpose   Converts integer to	string
; Input	    Stack arguments: 1 - Number	to convert; 2 -	Near address for write
; Output    AX has characters written

BinToStr  PROC
	  push	  bp
	  mov	  bp,sp
	  mov	  ax,[bp+6]		; Arg 1
	  mov	  di,[bp+4]		; Arg 2

	  sub	  cx,cx			; Clear	counter
	  mov	  bx,10			; Divide by 10

; Convert and save on stack backwards

getdigit: sub	  dx,dx			; Clear	top
	  div	  bx			; Divide to get	last digit as remainder
	  add	  dl,"0"		; Convert to ASCII
	  push	  dx			; Save on stack
	  or	  ax,ax			; Quotient 0?
	  loopnz  getdigit		; No? Get another

; Take off the stack and store forward

	  neg	  cx			; Negate and save count
	  mov	  dx,cx
putdigit: pop	  ax			; Get character
	  stosb				; Store	it
	  loop	  putdigit
	  mov	  ax,dx			; Return digit count

	  pop	  bp
	  ret	  4
BinToStr  ENDP

; Procedure Retrace
; Purpose   Writes cell	during horizontal retrace (CGA)
; Input	    ES:DI has screen buffer position, AX has cell
; Output    Character to screen	buffer

Retrace	  PROC
	  push	  bx
	  mov	  bx,ax			; Save character
lscan2:	  in	  al,dx			; Look in the port
	  shr	  al,1			;   until it goes low
	  jc	  lscan2
	  cli
hscan2:	  in	  al,dx			; Look in the port
	  shr	  al,1			;   until it goes high
	  jnc	  hscan2
	  mov	  ax,bx			; Restore and write it
	  stosw
	  sti
	  pop	  bx
	  ret
Retrace	  ENDP

;显示搜索栏

Dissearch   PROC
	  push	bp
	  mov	bp,sp
	  push	dx;保存dx后面会用到
	  mov	dl,searchmark; 搜索栏可见标志
	  cmp	dl,0
	  je	dis	;为0不可见，则切换为可见
	  mov	searchmark,0	;否则，置为0
	  sub	dx,dx	;参数，显示第0行
	  push	dx	;参数压栈
	  call	Pager	;调用Pager，显示状态栏，覆盖搜索栏          
	  pop	dx	;弹出dx
	  pop	bp	;弹出bp
	  ret
dis:
	  mov	strlen, 0	;待搜索字符串长度设为0
	  mov	count, 0	;匹配到的数量清空
	  push	es	;保存es
	  push	ds	;把ds传给es
	  pop	es
	  mov	di,OFFSET searchline+14	;14是searchline的前面的需要显示的字符数量
	  mov	cx,30	;可输入字符串的空位数
	  mov	al," "	;al中放入空格
	  rep	stosb;填充空格
	  mov	di,OFFSET matchedline	;matchedline地址
	  mov	cx,7	;统计数量最大数量7位
	  mov	al," "	;al中放入空格
	  rep	stosb;填充空格
	  pop	es 
	  push	ds	;参数1，段地址
	  mov	dx,OFFSET searchline	;参数2，偏移地址
	  push	dx
	  mov	dx,0	;参数3在第0行显示
	  push	dx
	  mov	dl,statatr	;参数4，配色，和导航栏相同
	  mov	BYTE PTR cell[1], dl
	  push	cell
	  call	CellWrt	;显示搜索栏
	  mov	searchmark,1;设置搜索栏可见     
	  pop	dx	;弹出dx
	  pop	bp	;弹出bp
	  ret
Dissearch	ENDP
;获得并显示输入的字符
Disinput	PROC
	  push	dx	;保存dx后面会用到
	  push	cx	;保存cx后面会用到
	  mov	cl,searchmark	;获得当前搜索栏状态
	  cmp	cl,0	;比较搜索栏是否存在
	  je	goout	;若不存在就跳出
	  cmp	al,8	;比较输入的字符是否为退格
	  jne	getinput	;如果不是就获取现在输入的字符
	  mov	cl,strlen	;获取已输入的字符串长度
	  cmp	cl,0	;比较是否为0
	  je	goout	;等于0直接跳出
	  dec	strlen	;字符串长度减1
	  jmp	disstr	;显示退格后的字符串
getinput:
	  mov	cl,strlen	;获得已有字符串长度
	  cmp	cl,30	;比较字符是否已经有30个
	  jge	goout	;如果已经多于30个就跳出
	  mov	ch,0	;cx高位清零
	  mov	si,cx	;cl不能用表示偏移
	  mov	searchstr[si],al	;将输入的字符存入待搜索字符串
	  inc	cl	;字符串长度加一
	  mov	strlen,cl	;更新字符串长度
disstr:
	  push	es
	  push	ds
	  pop	es	;把ds放入es
	  mov	ch,0	;将ch清0，后面用到串重复操作的指令
	  lea	si,searchstr	;将待搜索串的地址给si
	  mov	di,offset searchline+14	;待填充地址
	  rep	movsb	;将searchstr复制到searchline的相应位置
	  mov	dl,strlen	;把字符串长度给dl
	  mov	dh,0	;dx高位清零
	  mov	cx,30	;可输入的最长字符串长度
	  sub	cx,dx	;计算需要填充多少空格
	  add	dx,offset searchline+14	;开始填充空格的位置
	  mov	di,dx	;di作为串操作目标地址
	  mov	al," "	;al中存放空格
	  rep	stosb	;填充空格
	  pop	es
	  call	Search
	  ;重新显示搜索栏
	  push	ds	;参数一，段基址
	  mov	dx,offset searchline	;参数2，缓冲偏移
	  push	dx
	  mov	dx,0	;参数3，行号0，搜索栏显示在第0行
	  push	dx
	  mov	dl,statatr	;参数4，配色
	  mov	BYTE PTR cell[1],dl
	  push	cell
	  call	CellWrt	;显示搜索栏
goout:
	  pop	cx;恢复cx
	  pop	dx;恢复dx
	  ret
Disinput	ENDP

;搜索字符串
Search	PROC
	  push	dx	;使用到dx，先保存
	  call	ClearBackground	;屏幕清空
	  mov	count,0	;将统计计数清0
	  mov	scannum,1	;当前扫描行为1
	  mov	scanhead,-1	;当前扫描行首偏移为0
	  mov	ax,fsize	;把文件大小放入ax
	  mov	bl,strlen	;把待搜索字符串长度放入bx
	  mov	bh,0	;高位清空
	  cmp	bx,0	;待搜索字符串长度是否为0
	  je	searchend	;是0就结束
	  sub	ax,bx	;获得需要比较的次数
	  jb	searchend	;如果原本比待搜索串短，结束
	  mov	dx,0FFFFh	;初始化计数
xunhuan:
	  inc	dx	;记次++
	  cmp	dx,ax	;比较次数有没有达到最大次数
	  jg	searchend	;若比较次数大于需比较次数，结束
	  cld	;串比较方向为加方向
	  push	es	;保存es的值
	  mov	es,sbuffer	;获得文件的基址
	  mov	di,dx	;把文件内容偏移量放入di
	  lea	si,searchstr	;待比较字符串偏移量放入si
	  mov	al,es:[di]	;把当前比较串的首字符放入al
	  cmp	al,13	;判断字符是不是换行符
	  jne	t	;不是就跳转t开始比较
	  inc	scannum	;扫描的行号++
	  mov	scanhead,di	;把该换行符偏移存入scanhead
	  inc	scanhead	;获得下一行首字符的偏移
t:	  mov	cx,bx	;把待搜索字符串长度给cx
	  repe	cmpsb	;循环比较
	  pop	es	;弹出es
	  jz	matched	;匹配到，处理
	  jmp	xunhuan	;循环
matched:
	  inc	count	;匹配到的数量加一
	  push	dx	;保存dx
	  mov	dx,di	;把当前比较后的偏移放入dx
	  sub	dx,bx	;偏移减去bx得到比较的第二个字符的偏移
	  call	DisHighlight	;高亮显示匹配到的字符
	  pop	dx	;弹出dx
	  jmp	xunhuan	;循环扫描比较
searchend:
	  pop	dx	;弹出之前保存的dx
	  push	ds	;把ds传给es
	  pop	es
	  push	count	;参数一要转换为字符的数字
	  lea	ax,matchedline	;参数二，目标地址
	  push	ax
	  call	BinToStr	;调用函数，把统计的字符数量放入目标地址
	  mov	cx,7	;总共7位可以用来放统计的数量
	  sub	cx,ax	;ax存放的数字的长度，相减获得需要清空的长度
	  mov	al," "
	  rep	stosb	;循环清空
	  ret
Search	ENDP

ClearBackground	PROC
	  push	es	;保存寄存器
	  push	di
	  push	ax
	  push	cx
	  mov	di,80*2	;第一行不清空，从第二行第一个开始记
	  mov	cx,24*80	;清空24行，每行80个字，作为循环次数
	  mov	es,vidadr	;屏幕缓冲区
xunhuan1:
	  mov	ax,es:[di]	;取出屏幕缓冲区相应偏移处的值
	  mov	ah,scrnatr	;修改配色
	  mov	es:[di],ax	;将修改后的内容存回去
	  add	di,2	;字节编制，每个显示单位一个字，所以到下一个显示单位需要加2
	  loop	xunhuan1
	  pop	cx
	  pop	ax
	  pop	di
	  pop	es
	  ret
ClearBackground	ENDP

;高亮显示,用寄存器dx传递偏移
DisHighlight	PROC
	  push	bp	;保存寄存器
	  mov	bp,sp
	  push	es
	  push	di
	  push	ax
	  push	bx
	  push	cx
	  push	dx
	  mov	es,sbuffer	;把文件的起始地址放入es
	  mov	di,dx	;把偏移存入di
	  dec	di	;在搜索函数中偏移加了1
	  mov	ax,scannum	;把扫描行号放入ax
	  cmp	ax,linenum	;比较扫描行号和当前显示行号，若果小于就跳出
	  jl	goout1
	  sub	ax,linenum	;获得当前扫描行号对应屏幕的行号
	  inc	ax	;第一行为搜索栏，从第二行开始显示
	  cmp	ax,rows	;比较是否超过了24，如果超过就跳出
	  ja	goout1
	  sub	di,scanhead	;获得行内偏移
	  add	di,di	;每格一个字，需要偏移乘以二才是真实地址
	  mov	bx,80*2	;每行160个字节
	  mul	bl	;获得当前行首对应的屏幕缓冲的地址
	  add	di,ax	;获得当前字符对应的屏幕缓冲的地址
	  mov	cl,strlen	;取待搜索字符串长度作为循环次数
	  mov	ch,0	;高位清0
	  mov	es,vidadr	;去屏幕缓冲区地址
change:
	  mov	ax,es:[di]	;取出屏幕缓冲的di偏移处内容
	  mov	ah,highlight	;修改配色为高亮显示
	  mov	es:[di],ax	;更新屏幕缓冲
	  add	di,2	;屏幕上显示的每格对应一个字，就是两个字节
	  loop	change
goout1:
	  pop	dx	;恢复寄存器
	  pop	cx
	  pop	bx
	  pop	ax
	  pop	di
	  pop	es
	  pop	bp
	  ret
DisHighlight	ENDP
	  END
