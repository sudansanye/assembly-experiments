; 绝对值，多字节求和
assume ss:stacksg, cs:codesg, ds:datasg
datasg segment
	DATA1 db 05H, 0H, 0H, 0H, 0H
	DATA2 db 0ffH, 0ffH, 0ffH, 0ffH, 0ffH
	SUM db 0, 0, 0, 0, 0, 0
	LEN db 5
datasg ends
stacksg segment
	db 16 dup(0)
stacksg ends
codesg segment
; data1的开始数据位si,长度在cx中，数据段在ds
; data2的开始数据位di,进入前需要清除CF
; sum的开始数据位bx
add_2 PROC
	push si
	push di
	push bx; 用于指向sum
	push cx
r:
	mov al, [si]
	adc al, [di]
	mov [bx], al

	inc bx
	inc si
	inc di
	loop r
	adc byte ptr [bx], 0 ; 进位
return:
	pop cx
	pop bx
	pop di
	pop si
	ret
add_2 ENDP
; 处理一个数据
; 长度存在bx, 起始地址在si中，数据段地址在ds
; 程序执行后，源地址为其绝对值，进入前要求CF为1
abs PROC
	push ax
	push cx
	push si

	mov al, [si + bx-1]
	and al, al
	mov cx, bx
	jns retu
	; body
	STC
s:
	not byte ptr [si]
	adc byte ptr [si], 0
	inc si
	loop s
retu:
	pop si
	pop cx
	pop ax
	ret
abs ENDP

start:
	mov ax, stacksg
	mov ss, ax
	mov sp, 16

	mov ax, datasg
	mov ds, ax

	mov bx, 0
	mov bl, LEN
	LEA si, data1
	call abs 

	mov bx, 0
	mov bl, LEN
	LEA si, data2
	call abs

	LEA si, data1
	LEA di, data2
	LEA bx, SUM
	mov cx, 0
	mov cl, [LEN]
	CLC
	call add_2

	mov ax, 4c00h
	int 21h
codesg ends
end start