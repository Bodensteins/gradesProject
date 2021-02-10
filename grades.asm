.8086
assume cs:codesg,ds:datasg,ss:stacksg
N equ 100		;学生总数
charSize equ 13		;待查询学生姓名缓冲区长度
datasg segment		;数据段
buf db 'ZhangSan',0,0		;学生信息
	db 100,85,80,'?'
	db 'LiSi',6 dup(0)
	db 80,100,70,'?'
	db N-4 dup('TempValue',0,80,90,95,'?')
	db 'ZhangJw',0,0,0
	db 70,75,60,'?'
	db 'LeiTaomin',0
	db 100,100,90,'?'
suggestion db 'Input a name:$'		;提示输入
unfound db 'Don`t exist$'		;查询失败的提示
in_name db charSize dup('$')		;待查询学生姓名缓冲区
poin dw 0	;待查询学生信息地址存放处
datasg ends

stacksg segment		;栈段
	dw 10 dup(0)
stacksg ends

codesg segment		;代码段

;主程序：
	start:
		call initial	;程序初始化
		call function3		;执行功能3，计算所有学生加权平均成绩
	s0:	
		mov sp,10		;清空栈
		call function1		;执行功能1，输入待查询学生姓名，存入in_name段
		call function2		;执行功能2，查找该学生信息
		call function4		;执行功能4，输出学生成绩等级
		call clear_in_name		;清空in_name段的姓名
		jmp s0		;返回功能一处
	exit:	
		mov ax, 4c00h
		int 21h


function1:
		lea dx,suggestion	;输出提示信息
		mov ah,09h
		int 21h

		call linefeed

		lea dx,in_name		;输入学生姓名，存至in_name处
		mov ah,0ah
		int 21h

		mov bx,dx		
		inc bx
		mov al,[bx]
		cmp al,0		;判断姓名字符串长度，为0则跳转回主程序重新输入
		je s0
		cmp al,1		;若姓名串长度为1且首字母为q则退出程序
		jne	con		;否则子程序返回，执行功能2
		mov al,[bx+1]
		cmp al,'q'
		je exit

	con:
		call linefeed
		ret

function2:
		mov cx,N	;cx存入学生总数
		lea di,buf	
		lea si,in_name	;si存入待查询学生姓名的首地址	
		add si,2
	f0:	
		push cx		;cx入栈
		mov cl,[in_name+1]		;cl存入待查询学生姓名长度
		call cmpstr		;调用字符串比较子程序
		pop cx		;cx出栈
		cmp dx,0	;判断dx是否为0
		je found	;是则说明找到了该学生，跳转至found代码段
		add di,14	;否则继续查找
		loop f0

		lea dx,unfound	;若循环结束后还未找到，则输出提示信息并返回功能1处
		mov ah,09h	
		int 21h
		call linefeed
		jmp s0

	found:		;将找到的学生信息的地址存入poin处
		mov ax,di
		mov [poin],ax
		ret


function3:
		lea bx,buf		;bx存入学生信息的基址
		mov si,10		;si存入待运算数据的偏移地址
		mov di,13		;di存入平均成绩保存的偏移地址
		mov cx,N		;cx存入学生总数
	avg:
		mov dl,[bx+si]		
		mov ax,dx	;将语文成绩存入ax
		push bx			
		mov bx,4	;语文成绩乘4
		mul bx
		pop bx
		
		mov dl,[bx+si+1]
		push ax
		mov ax,dx	;将数学成绩存入ax
		push bx
		mov bx,2	;数学成绩乘2
		mul bx
		pop bx
		mov dx,ax
		pop ax
		add ax,dx	;加上原来的语文加权成绩

		mov dl,[bx+si+2]
		add ax,dx	;将英语成绩直接加入总成绩

		mov dx,0
		push bx
		mov bx,7
		div bx		;将总成绩除以7得到最终的加权平均成绩
		pop bx

		mov byte ptr [bx+di],al		;将加权平均成绩存入指定内存地址

		add bx,14		;基址加14，进行下一位学生成绩的计算
		loop avg
		ret

function4:
		mov bx,[poin]	;bx中存入待查询学生信息的地址
		mov al,[bx+13]		;将学生的加权平均成绩存入al
		cmp al,90		;成绩不低于于90，跳转至A
		jnb A
		cmp al,80		;成绩不低于于80，跳转至B
		jnb B
		cmp al,70		;成绩不低于于70，跳转至C
		jnb C
		cmp al,60		;成绩不低于于60，跳转至D
		jnb D
		mov dl,'F'			;否则直接输出F后退出子程序
		jmp f4_show
	D:mov dl,'D'		;输出D后退出子程序
		jmp f4_show
	C:mov dl,'C'		;输出C后退出子程序
		jmp f4_show
	B:mov dl,'B'		;输出B后退出子程序
		jmp f4_show
	A:mov dl,'A'		;输出A后退出子程序

	f4_show:
		mov ah,02h
		int 21h
		call linefeed
		ret


linefeed:	;换行子程序
		mov dl,0ah
        mov ah,02h
        int 21h
		ret


;字符串比较子程序：
;调用时将两个串的偏移地址分别存入si、di
;将偏移地址在si中的字符串的长度存入cx
;若两个串完全相同则dx中存入0,否则dx中存入1
cmpstr:	
	push ax		;将ax、si、di原来的值暂存入栈中
	push si
	push di
	c0:		;循环比较两个串中每个位置是否相同
		mov al,[si]
		cmp al,[di]		;比较当前位置的内容是否相同
		jne str_not_equal	;不相同则直接退出
		inc si		;相同则递增si、di，继续比较下一位
		inc di
		loop c0
		
		;若循环退出后发现两个串相同：
		mov al,[di]		;检查偏移地址在di中的串的下一个字符是否为0
		cmp al,0
		jne str_not_equal		;若不为0则说明两个串仍不相同
		mov dx,0		;否则说明两个串确实相同，dx存入0
		jmp endpos
	str_not_equal:
		mov dx,1		;两个串不相同则dx存入1
	endpos:
		pop di
		pop si
		pop ax		;si、di、ax恢复原来的值，退出
		ret

initial:		;程序初始化
		;设置各种段地址
		mov ax,datasg
		mov ds,ax
		mov ax,stacksg
		mov ss,ax
		mov sp,10		;清空栈
		ret

clear_in_name:		;一次查询后清空in_name缓冲区
		lea bx,in_name
		mov cx,charSize
	clear:
		mov byte ptr [bx],'$'		;将该缓冲区全部存入字符串结束符
		inc bx
		loop clear
		ret

codesg ends
end start
