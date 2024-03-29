.model small
.stack 16384	

.data 
n dw 0
m dw 0
actLen dw 0
cnt dw 0
cnt2 dw 0
buffLen dw 0

wtf db 'wtf$'
enterN db 'Enter n: $'
enterM db 'Enter m: $'
indent  db '', 0Dh, 0Ah, '$'
space db ' $'
end db '$'



matrix db 10000 dup('$')



; НИЖЕ - ДЛЯ ВВОДА

parN label byte  
maxlenN db 4    
actlenN db ?       
fldN db 4 dup('$')     

parM label byte  
maxlenM db 4    
actlenM db ?        
fldM db 4 dup('$')     

Raw label byte  
maxlenRaw dw 401 
actlenRaw dw ?        
fldRaw db 401 dup('$')   

buffer db 6 dup('$')

.code 

searchSize proc near     ; Ищем размер введённой строки
        push cx

        lea bx, Raw+1    
        mov cx, [bx] 
        xor ch, ch
        mov actLen,cx
        
        pop cx
        ret
searchSize endp

 searchSizeBuff proc near
    push ds    
    pop es

    mov buffLen,0
    push cx
    push ax
    push di
    push bx
    xor cx,cx
    xor ax,ax
    xor di,di
    xor bx,bx

    mov cx , 5
    lea di,buffer 
    @pupa:
    lea si , end      ; разделитель
    cmpsb
    je @bb
    inc buffLen
    loop @pupa
    ;mov cx , buffLen
    
    @bb:
    pop bx
    pop di
    pop ax
    pop cx
    ret
 searchSizeBuff endp

makeIntend proc near
    lea dx, indent
    mov ah, 09
    int 21h
    ret
makeIntend endp

enterNum1 proc near
    mov di, 0           
    mov cx, buffLen                                     ;в CX количество введенных символов
    xor ch, ch
    mov si, 1                                          ;в SI множитель 

    @loopMet1:
    push si                                            ;сохраняем SI (множитель) в стеке
    mov si, cx                                         ;в SI помещаем номер текущего символа 
    cmp cx,1
    je @Signed1
    @NoSigned1:
    mov ax, [bx+si]                                    ;в AX помещаем текущий символ 
    xor ah, ah
    pop si                                             ;извлекаем множитель (SI) из стека
    sub ax, 30h                                        ;получаем из символа (AX) цифру
    mul si                                             ;умножаем цифру (AX) на множитель (SI)
    add di, ax                                         ;складываем с результирующим числом
    mov ax, si                                         ;помещаем множитель (SI) в AX
    mov dx, 10
    mul dx                                             ;увеличиваем множитель (AX) в 10 раз
    mov si, ax                                         ;перемещаем множитель (AX) назад в SI
    loop @loopMet1                                      ;переходим к предыдущему символу
    @return1:
    ret
    @Signed1:
    push dx
    mov dx,[bx+si]
    xor dh,dh
    cmp dl,'-'
    pop dx
    jne @NoSigned1
    neg di
    pop si
    jmp @return1
enterNum1 endp

enterNum proc near
    mov di, 0           
    mov cx, [bx]                                       ;в CX количество введенных символов
    xor ch, ch
    mov si, 1                                          ;в SI множитель 

    @loopMet:
    push si                                            ;сохраняем SI (множитель) в стеке
    mov si, cx                                         ;в SI помещаем номер текущего символа 
    cmp cx,1
    je @Signed
    @NoSigned:
    mov ax, [bx+si]                                    ;в AX помещаем текущий символ 
    xor ah, ah
    pop si                                             ;извлекаем множитель (SI) из стека
    sub ax, 30h                                        ;получаем из символа (AX) цифру
    mul si                                             ;умножаем цифру (AX) на множитель (SI)
    add di, ax                                         ;складываем с результирующим числом
    mov ax, si                                         ;помещаем множитель (SI) в AX
    mov dx, 10
    mul dx                                             ;увеличиваем множитель (AX) в 10 раз
    mov si, ax                                         ;перемещаем множитель (AX) назад в SI
    loop @loopMet                                      ;переходим к предыдущему символу
    @return:
    ret
    @Signed:
    push dx
    mov dx,[bx+si]
    xor dh,dh
    cmp dl,'-'
    pop dx
    jne @NoSigned
    neg di
    pop si
    jmp @return
enterNum endp


parse proc near    ;парс строки
    mov cnt , 0
    mov cnt2 , 0
    
    push ds    
    pop es
    
    push cx
    push ax
    push di
    push bx
    xor cx,cx
    xor ax,ax
    xor di,di
    xor bx,bx

    call searchSize        ; ищем реальную длину входной строки, а не количество цифр
    mov cx, actLen         ; количество символов строки
    lea di , Raw + 2   ; это сама введённая строка
    
    @lpParse:           
    lea si , space      ; разделитель
    cmpsb               ; если не попали на разделитель , то пойдём записывать наш символ в буфер
    je @proceed
    
    @oneSymb:       ; запишем один наш символ в буффер
    inc cnt         ; будем потом домнажать на это число при вставке числа с помощью регистра di и цепочечной команды
    dec di           ; Откатываюсь на символ назад, т.е. на нужный мне символ
    mov al, [di]
    inc di            ; возвращаю всё для компилятора

    push di
    xor di,di
    lea di , [buffer]

    push cx
    mov cx,cnt
    sub cx,1
    test cx,cx
    jz @skip11p
    @stpdlp:
    inc di
    loop @stpdlp
    @skip11p:
    pop cx
    stosb
    pop di
    jmp @exitfromcicle

    @proceed:
    inc cnt2
    push si
    push cx
    push ax
    push di
    push bx

    xor cx,cx
    xor ax,ax
    xor di,di
    xor bx,bx

    call searchSizeBuff
    cmp buffLen,1
    call enterNum1 ; работает неверно
    mov ax,[di]
    
    push di
    xor di,di
    lea di , matrix
    push cx
    xor cx,cx
    mov cx , cnt2
    sub cx,1
    test cx, cx
    jz @skip12p
    @stpdlp2:
    inc di
    loop @stpdlp2
    @skip12p:
    pop cx
    stosb
    pop di
    
    
    pop bx
    pop di
    pop ax
    pop cx
    pop si
    
    




   push di
   push cx
   lea   di, buffer
   mov   cx, 5
   mov   al,' '           ;пробел
   rep   stosb            ;отправляем СХ-пробелов по адресу ES:DI
   pop cx
   pop di

    @exitfromcicle:
    
    loop @lpParse
    
    jmp @exitFromFunc
    @exitFromFunc:
    pop bx
    pop di
    pop ax
    pop cx
    ret
parse endp

matrixLoad1 proc near
    push ds    
    pop es

    push cx
    push ax
    push di
    push bx

    xor cx,cx
    xor ax,ax
    xor di,di
    xor bx,bx

    mov cx, n
    @byRaws:
        lea dx, Raw                 ; ввод строки матрицы
        mov ah, 0Ah
        int 21h
        lea bx, Raw+1
        call makeIntend
        call parse
    
    loop @byRaws

    pop bx
    pop di
    pop ax
    pop cx
    ret
matrixLoad1 endp


start:
    mov ax,@data
    mov ds,ax

        lea dx, enterN                                 ;вводим а   
        mov ah, 09
        int 21h
        lea dx, parN
        mov ah, 0Ah
        int 21h
        lea bx, parN+1                                  ;в BX адрес второго элемента буфера
        call enterNum
        call makeIntend
        mov n , di
          
        lea dx, enterM                                  ;вводим а   
        mov ah, 09
        int 21h
        lea dx, parM
        mov ah, 0Ah
        int 21h
        lea bx, parM+1                                  ;в BX адрес второго элемента буфера
        call enterNum
        call makeIntend
        mov m , di

        cmp n,2
        cmp m,2


        call matrixLoad1

        ;lea dx,buffer
       ; mov ah, 09
        ;int 21h

        lea dx, matrix
        mov ah, 09
        int 21h 

        @exit:
            mov ah, 4ch
            int   21h
end start


;lea di , wtf
;mov al , [di + 1 ]  ; получаю именно одну букву из строки, т.е. один символ
; сравнивать посимвольно, пока не нашёл, заносить в di , когда нашёл, переводить это в число и заносить в массив
; двумя цепочечными командами

; Лабораторная 4 . Вариант 4
; Необходимо определить минимальное значение для каждой строки и каждого столбца матрицы. В качестве результата вычислите сумму полученных значений.