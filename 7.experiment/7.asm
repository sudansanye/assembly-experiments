; 数据段
datasg segment
	; 前两个数据回车加换行
    PROMPT_SRC db 0DH, 0AH, 'please input the src file: ', 0DH, 0AH, '$'
    PROMPT_DST db 0DH, 0AH, 'please input the dst file: ', 0DH, 0AH, '$'
    ; 程序提示信息输出格式：
	MSG_SUCCESS db 0DH, 0AH, 'the copy operation is successful', 0DH, 0AH, '$'
    MSG_ERR_OPEN db 0DH, 0AH, 'error: can`t open the src!', 0DH, 0AH, '$'
    MSG_ERR_CREATE db 0DH, 0AH, 'error: can`t create file!', 0DH, 0AH, '$'
    MSG_ERR_READ db 0DH, 0AH, 'error: can`t read the src! ', 0DH, 0AH, '$'
    MSG_ERR_WRITE db 0DH, 0AH, 'error: can`t write the src! ', 0DH, 0AH, '$'
	; 缓冲 774：0 779：0 (debug地址)
	FILE_NAME1 db 50H, 0, 50 dup(0)
	FILE_NAME2 db 50H, 0, 50 dup(0)
	; 句柄
	HANDLE_SRC dw 0
	HANDLE_DST dw 0
	; 存数据的缓冲区
	BUFFER_SIZE equ 512
	BUFFER db BUFFER_SIZE dup(0)
datasg ends

;栈段
stacksg segment
	db 100H dup(0)
stacksg ends

;代码段
codesg segment
assume cs:codesg, ds:datasg, ss:stacksg
start:
	mov ax, datasg
	mov ds, ax
	mov ax, stacksg
	mov ss, ax
	mov sp, 100H
; 第一段输出
	LEA dx, PROMPT_SRC
	mov ah, 09H
	int 21H
; 第一段读入
	LEA dx, FILE_NAME1
	mov ah, 0AH
	int 21H
	LEA dx, FILE_NAME1
	call NAME_2_ASCII

; 第二段
	LEA dx, PROMPT_DST
	mov ah, 09H
	int 21H

	LEA dx, FILE_NAME2
	mov ah, 0AH
	int 21H
	LEA dx, FILE_NAME2
	call NAME_2_ASCII


;打开文件
	LEA dx, FILE_NAME1 + 2
	; 07b1:003f(debug地址)
	; 07a4;003f(debug地址)
	mov ah, 3DH
	mov al, 0
	; 043
	int 21H
	jc OPEN_SRC_ERROR
	mov [HANDLE_SRC], ax

;目标文件
	LEA dx, FILE_NAME2 + 2
	mov ah, 3CH
	mov cx, 0
	int 21H
	jc CREATE_DST_ERROR
	mov [HANDLE_DST], ax
; 开始文件内容复制
COPY_FILE:
	mov ah, 3FH
	mov bx, [HANDLE_SRC]
	mov cx, BUFFER_SIZE
	LEA dx, BUFFER
	int 21H
	jc READ_ERROR
	cmp ax, 0
	jz COPY_END

	mov cx, ax
	mov ah, 40H
	mov bx, [HANDLE_DST]
	LEA dx, BUFFER
	int 21H
	jc WRITE_ERROR
	
	jmp COPY_FILE

; 判断复制完毕
COPY_END:
	mov ah, 3EH
	mov bx, [HANDLE_SRC]
	int 21H

	mov ah, 3EH
	mov bx, [HANDLE_DST]
	int 21H
	jmp SUCCESS

; 各类报错
OPEN_SRC_ERROR:
	LEA dx, MSG_ERR_OPEN
	mov ah, 09H
	int 21H
	jmp return

CREATE_DST_ERROR:
	LEA dx, MSG_ERR_CREATE
	mov ah, 09H
	int 21H
	jmp return
READ_ERROR:
	LEA dx, MSG_ERR_READ
	mov ah, 09H
	int 21H
	jmp return
WRITE_ERROR:
	LEA dx, MSG_ERR_WRITE
	mov ah, 09H
	int 21H
	jmp return
; 成功完成工作
SUCCESS:
	LEA dx, MSG_SUCCESS
	mov ah, 09H
	int 21H
	jmp return

; 输入文件名转成ascii码的字符串
; 去除最后读入的回车键
; 读入信息使用dx指向;
NAME_2_ASCII PROC
	push dx
	push si
	push ax
	push bx

	mov si, dx
	mov al, [si + 1]
	xor bh, bh
	mov bl, al
	mov byte ptr [si + bx + 2], 0

	pop bx
	pop ax
	pop si
	pop dx
	ret
NAME_2_ASCII ENDP

return:

	mov ah, 4cH
	int 21H
codesg ends
end start