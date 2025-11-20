; Programa: Nr. 2

; Programa, kurios pirmas ir antras parametrai - eilutės,
; visi kiti - failų vardai. Visuose failuose pirma įvesta eilutė pakeičiama antrąja.
; Atliko: Ainis Laurinavičius id: 2412598

.model small
.stack 100H

JUMPS

.data
row1 dw ?
row2 dw ?

apie    	db 'Programa sukeicia pasirinktas eilutes vietomis',13,10,9,'2_uzd.exe [/?] row 1 row 2 [ - | sourceFile1 [sourceFile2] [...] ]',13,10,13,10,9,'/? - pagalba',13,10,'$'
err_num     db 'Abu skaiciai turi buti naturalus skaiciai > 0 $'
err_s    	db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'
err_bounds  db 'Tokia eilute faile neegzistuoja $'
startRow    db 'Row start',13,10,'$'
endRow      db 'Row end',13,10,'$'
new_line    db 13,10,13,10,'$'
err_fileName db 'Source failo vardas per ilgas', 13, 10, '$'
no_source_file db 'Privalote irasyti, bent viena source failo pavadinima', 13, 10, '$'

buffer  	db 1 dup (?)

rowStarts   dw 500 dup(0)
currentPos dw 0
currentRow dw 0
rowStartPos dw 0

rowBuffer db 10 dup(0)

sourceF   	db 13 dup (0) 
sourceFHandle	dw ? 

fileCounter dw 1
outputFileName db 20 dup(0)
outputHandle dw ? 

writeRow  dw 0

newline db 13,10

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
    mov es:row1, ax

    call skip_spaces
    call read_number
    cmp ax, 0
    jbe row_err
    mov es:row2, ax 

	lea	di, sourceF
	call	read_filename

    cmp	byte ptr es:[sourceF], '$'
    je	no_first_sourceFile

	push	ds si

    mov ax, @data
    mov ds, ax

	jmp	startConverting

readSourceFile:
	pop	si ds
	lea	di, sourceF
	call	read_filename

	push	ds si

	mov	ax, @data
	mov	ds, ax
	
	cmp	byte ptr ds:[sourceF], '$'
	jne	startConverting
	jmp	_end
	
startConverting:
	cmp	byte ptr ds:[sourceF], '$'
	jne	source_from_file
	
	mov	sourceFHandle, 0
	jmp	read_loop
	
source_from_file:
    mov currentPos, 0
    mov currentRow, 0
    mov rowStartPos, 0

	mov	dx, offset sourceF
	mov	ah, 3dh            
	mov	al, 2            
	int	21h		
	jc	err_source	
	mov	sourceFHandle, ax	
  
read_loop:
	mov	bx, sourceFHandle
	mov	dx, offset buffer      
	mov	cx, 1  
	mov	ah, 3fh         
	int	21h	 

	cmp	ax, 0         
	je	close_file         

    mov dl, byte ptr [buffer]
    cmp dl, 13
    je handle_row_end

    inc currentPos

	jmp	read_loop	   

close_file:
    mov bx, currentRow 
    shl bx, 1

    mov ax, rowStartPos
    mov rowStarts[bx], ax

    ; call print_data
    call write_row_data

    mov	bx, sourceFHandle	
	mov	ah, 3eh	
	int	21h

	jmp	readSourceFile	

handle_row_end:
    mov ax, currentRow
    inc ax
    mov bx, row1
    cmp ax, bx

    mov bx, currentRow 
    shl bx, 1
    
    mov ax, rowStartPos
    mov rowStarts[bx], ax

    mov ax, currentPos
    add ax, 1
    mov rowStartPos, ax

    ; call print_data 

    inc currentRow
    jmp read_loop

err_source:
    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset err_s       
	mov	ah, 09h              
	int	21h                   
	jmp _end 

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

file_name_too_long:
	mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset err_fileName       
	mov	ah, 09h              
	int	21h                   
	jmp _end  

err_out_bounds:
    mov	bx, sourceFHandle	
	mov	ah, 3eh	
	int	21h

    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset err_bounds       
	mov	ah, 09h              
	int	21h                   
	jmp _end 

no_first_sourceFile: 
    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset no_source_file       
	mov	ah, 09h              
	int	21h                   
	jmp _end  

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
	push	ax
	call	skip_spaces
    xor cx, cx
read_filename_start:
	cmp	byte ptr ds:[si], 13
	je	read_filename_end
	cmp	byte ptr ds:[si], ' '
	jne	read_filename_next
read_filename_end:
    cmp cx, 12
    ja file_name_too_long
    
    mov	al, '$'	
	stosb
	pop	ax
	ret
read_filename_next:
	lodsb	
	stosb
    inc cx
	jmp read_filename_start

read_filename ENDP

print_data PROC near
    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset startRow       
	mov	ah, 09h              
	int	21h  

    mov ax, rowStarts[bx]
    call print_number

    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset new_line       
	mov	ah, 09h              
	int	21h  

    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset endRow       
	mov	ah, 09h              
	int	21h  

    mov	ax, @data          
	mov	ds, ax               
	mov	dx, offset new_line       
	mov	ah, 09h              
	int	21h  

    ret
print_data ENDP

write_row_data PROC near
    mov ax, row1
    mov bx, row2

    dec ax
    dec bx

    cmp ax, 0
    jb err_out_bounds

    cmp bx, 0
    jb err_out_bounds

    cmp ax, currentRow
    ja err_out_bounds

    cmp bx, currentRow
    ja err_out_bounds

    ;;writing to new file logic
    call generate_filename

    mov ah, 3Ch
    mov cx, 0
    mov dx, offset outputFileName
    int 21h
    jc finish
    mov outputHandle, ax

    mov writeRow, 0

    write_loop:
        mov ax, writeRow
        inc ax

        cmp ax, row1
        je move_cursor_row2

        cmp ax, row2
        je move_cursor_row1

        jmp move_cursor_default

        move_cursor_row1:
            mov bx, row1
            dec bx
            add bx, bx

            mov ah, 42h
            mov al, 0
            xor cx, cx
            mov dx, rowStarts[bx]
            mov bx, row1
            dec bx
            add dx, bx
            mov bx, sourceFHandle
            int 21h

            jmp write_row

        move_cursor_row2:
            mov bx, row2
            dec bx
            add bx, bx

            mov ah, 42h
            mov al, 0
            xor cx, cx
            mov dx, rowStarts[bx]
            mov bx, row2
            dec bx
            add dx, bx
            mov bx, sourceFHandle
            int 21h

            jmp write_row
        
        move_cursor_default:
            mov bx, writeRow
            add bx, bx

            mov ah, 42h
            mov al, 0
            xor cx, cx
            mov dx, rowStarts[bx]
            mov bx, writeRow
            add dx, bx
            mov bx, sourceFHandle
            int 21h

            jmp write_row

        write_row:
            mov ah, 3Fh
            mov bx, sourceFHandle
            mov cx, 10
            mov dx, offset rowBuffer
            int 21h
            jc finish

            cmp ax, 0
            je finish

            mov si, offset rowBuffer
            mov cx, ax  

            check_buffer_loop:
                cmp     cx, 0
                je      write_row

                mov     al, [si]

                cmp     al, 13
                je      write_new_line

                push cx

                mov     ah, 40h
                mov     bx, outputHandle
                mov     dx, si
                mov     cx, 1 
                int     21h

                pop cx

            next_char:
                inc     si
                dec     cx
                jmp     check_buffer_loop
            

        write_new_line:
            inc writeRow

            mov ax, writeRow
            cmp ax, currentRow
            ja finish

            mov ah, 40h
            mov bx, outputHandle
            mov cx, 2
            mov dx, offset newline
            int 21h
            
            jmp write_loop

    finish:
        mov ah, 3Eh
        mov bx, outputHandle
        int 21h   

    swap_end:            
        ret
write_row_data ENDP

generate_filename PROC near
    push ax
    push bx
    push cx
    push di
    
    lea di, outputFileName
    mov byte ptr [di], 'r'
    mov byte ptr [di+1], 'e'
    mov byte ptr [di+2], 'z'
    
    mov ax, fileCounter
    inc fileCounter
    
    mov bx, 10
    xor cx, cx
    
convert_num:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convert_num
    
    add di, 3
    
write_digits:
    pop dx
    add dl, '0'
    mov byte ptr [di], dl
    inc di
    loop write_digits
    
    mov byte ptr [di], '.'
    mov byte ptr [di+1], 't'
    mov byte ptr [di+2], 'x'
    mov byte ptr [di+3], 't'
    mov byte ptr [di+4], 0
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
generate_filename ENDP

end START