; Programa: Nr. 2

; Programa, kurios pirmas ir antras parametrai - eilutės (numeriai eilučių), 
; visi kiti - failų vardai. Visuose failuose pirma įvesta eilutė pakeičiama antrąja.

; Atliko: Ainis Laurinavičius id: 2412598

.model small
.stack 100H
JUMPS

.data
apie    	db 'Programa sukeicia pasirinktas eilutes vietomis',13,10,9,'2_uzd.exe [/?] row 1 row 2 [ - | sourceFile1 [sourceFile2] [...] ]',13,10,13,10,9,'/? - pagalba',13,10,'$'
err_num     db 'Abu skaiciai turi buti naturalus skaiciai > 0 $'
; err_s    	db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'
; err_bounds  db 'Tokia eilute faile neegzistuoja $'

row1 dw ?
row2 dw ?

rowStarts   dw 100 dup(0)
rowEnds  dw 100 dup(0)

sourceF   	db 12 dup (0) 
sourceFHandle	dw ? 

.code

START:
    mov ax, @data
    mov es, ax
    
    mov si, 81h 
    call skip_spaces

    mov	al, byte ptr ds:[si]
	cmp	al, 13
	je	help

    mov	ax, word ptr ds:[si]
	cmp	ax, 3F2Fh
	je	help

    call skip_spaces
    call read_number
    cmp ax, 0
    jbe row_err
    mov row1, ax

    call skip_spaces
    call read_number
    cmp ax, 0
    jbe row_err
    mov row2, ax

    mov ax, row1
    call print_number

    mov ax, row2
    call print_number

    call skip_spaces
    lea	di, sourceF            
	call read_filename
    
    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset sourceF       
	mov	ah, 09h              
	int	21h  

    JMP _end

row_err:
    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset err_num       
	mov	ah, 09h              
	int	21h                   
	jmp _end   

help:
	mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset apie       
	mov	ah, 09h              
	int	21h                   
	jmp _end    

_end:
	mov	ax, 4c00h             
	int	21h

; PROCEDURES
skip_spaces PROC near
skip_spaces_loop:
	cmp byte ptr ds:[si], ' ' 
	jne skip_spaces_end        
	inc si                     
	jmp skip_spaces_loop       
skip_spaces_end:
	ret
skip_spaces ENDP

read_number PROC near
    push bx                    
    push cx
    
    xor ax, ax                
    mov bx, 10 

start_reading:
    mov cl, ds:[si]            
    cmp cl, '0'              
    jb done_reading            
    cmp cl, '9'               
    ja done_reading          
    
    sub cl, '0'               
    push cx                   
    mul bx                     
    pop cx                    
    xor ch, ch                 
    add ax, cx                
    
    inc si                     
    jmp start_reading         
    
done_reading:
    pop cx                    
    pop bx
    ret    

read_number ENDP

print_number PROC near
    push ax                    
    push bx
    push cx
    push dx

    xor cx, cx                 
    mov bx, 10                 

convert_loop:
    xor dx, dx                 
    div bx                    
    push dx                   
    inc cx                    
    cmp ax, 0                  
    jne convert_loop         

print_loop:
    pop dx                    
    add dl, '0'               
    mov ah, 02h               
    int 21h                   
    loop print_loop           

    mov dl, ' '                
    mov ah, 02h                
    int 21h                   

    pop dx                     
    pop cx
    pop bx
    pop ax
    ret
print_number ENDP

read_filename PROC near        
	push ax                               
read_filename_start:
	cmp byte ptr ds:[si], 13   
	je read_filename_end       
	cmp byte ptr ds:[si], ' '  
	jne read_filename_next    
read_filename_end:
	mov al, '$'                
	stosb                      
	pop ax                     
	ret                       
read_filename_next:
	lodsb                      
	stosb                      
	jmp read_filename_start    
read_filename ENDP

end START