PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM




data segment
    msg_base db 'Entrer la base :',0dh, 0ah,'0: binaire',0dh, 0ah,'1: decimal',0dh, 0ah,'2: hexadecimal',0dh, 0ah,'$'
    
    msg_op db 0Dh,0Ah,"Entrer l'operateur arithmetique : +  -  /  *",0dh, 0ah,"$"
    opr db ?
    
    msg_num1 db 0Dh,0Ah ,"Entrer le 1er nombre : $"
    num1 dw ?
    
    msg_num2 db 0Dh,0Ah ,"Entrer le 2eme nombre : $"
    num2 dw ?
    
    msg_resultat db  0dh,0ah , 'Le resultat est :',9,'$'    ; 9 = TAB
    msg_large db 0dh, 0ah, "Le resultat est trop large!$"
               
    msg_merci db 0dh,0ah ,'Merci !$'
    msg_reste db  0dh,0ah ,"Le reste est    :",9,"$"
    ;    
     num dw ?
     charhex db ?
    ;edit 14h
    ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
    scanner dw OFFSET SCAN_BIN,  OFFSET SCAN_NUM,  OFFSET SCAN_HEX
    printer dw OFFSET PRINT_BIN, OFFSET PRINT_NUM, OFFSET PRINT_HEX
ends



start:
    mov ax, data
    mov ds, ax


main:
;MAIN               ; "donner base"
lea dx, msg_base
mov ah, 09h    ;AFFICHAGE DE PREMIER MSG
int 21h  

input_base:
    xor ah, ah    ; AH=0 scan sans afficher
    int 16h
    sub al, 30h   ; '0'->0 ascii to num
    cmp al, 2     
ja input_base
    ; si 0,1,2
        ; print base
        mov ah, 0Eh
        add al, 30h ; num to ASCII for print
        int 10h
    sub al, 30h ; back to num
    xor ah, ah  ;  AX := AL
    add al, al  ;  AX = AX*2 = deplacement; *2 car les tables sont en 2 OCTETS
    mov si, ax  ; SI = AX    = depl
    
    mov ax, scanner[si]
    mov scanner, ax     ; scanner = scanner[base]
    mov ax, printer[si]
    mov printer, ax     ; printer = printer[base]
               
               

lea dx, msg_op
mov ah, 09h   ; AFFICHAGE DE MSG OP
int 21h

;;;;;;;;; OPPPPP
              ; AVOIR L'OPERATEUR
    input_op:
mov ah, 00h   ; single char input to AL.
int 16h
;mov opr, al



cmp al, 'q'      ; q LE CAS DE QUITER
je exit
cmp al, '*'
jb input_op 
cmp al, '/'
ja input_op 
cmp al, 2Ch
je input_op
cmp al, 2Eh
je input_op
; opr valide
putc al
mov opr, al

; ENDOPPP???


lea dx, msg_num1
mov ah, 09h    ; AFFICHAGE DE MSG "entrer le 1er nombre"
int 21h  

call scanner ; cx = input(nombre)
;STOCKER LE PREMIER NOMBRE 
mov num1, cx 



; INPUT NUM2
lea dx, msg_num2
mov ah, 09h
int 21h  

call scanner
mov num2, cx 




xor dx, dx      ; prepare for calculs etc



; calculate:


cmp opr, '-'
je soustraction

cmp opr, '*'
je multiplication

cmp opr, '/'
je division

;xor dx, dx


;exit:
; output of a string at ds:dx
;lea dx, msg5
;mov ah, 09h
;int 21h  
; wait for any key...
;mov ah, 0
;int 16h
;ret  ; return back to os.


addition:
mov ax, num1
add ax, num2
jc too_large_
jo too_large_

call print_resultat  

call printer    ; print ax value.

jmp exit



soustraction:

mov ax, num1
sub ax, num2
jc too_large_
jo too_large_

call print_resultat

call printer    ; print ax value.

jmp exit




multiplication:

mov ax, num1
imul num2 ; (dx ax) = ax * num2.

jnc print_mul
jno print_mul
    jmp too_large_    ;CF=OF=1

print_mul:
call print_resultat
cmp dx, 0
    je motfaible
xchg dx, ax
call printer
xchg ax, dx

cmp si, 0004h   ; si hex
jne motfaible
    call ScreenDelChar   ; supprimer le suffixe 'h' apres DX

motfaible: 
call printer    ; print ax value.
; dx is ignored (calc works with tiny numbers only).

jmp exit



division:
; dx is ignored (calc works with tiny integer numbers only).
mov ax, num1
idiv num2  ; ax = (dx ax) / num2.
call print_resultat
cmp dx, 0000h
    jne reste
call printer    ; print ax & exit
jmp exit

    reste:
call printer    ; print ax...
mov bx, dx      ; save le reste
    ; print(msg_reste)
    lea dx, msg_reste
    mov ah, 09h    ; Le reste est :\t
    int 21h

mov ax, bx      ; >reste
call printer
jmp exit


too_large_:
 lea dx, msg_large
 mov ah, 09h
 int 21h
 jmp skip_merci

exit:
 lea dx, msg_merci
 mov ah, 09h
 int 21h
skip_merci:
mov ah, 4ch
int 21h  
;;;;;;;
  


;proc-12  
print_resultat  proc
    push ax
    push dx  
lea dx, msg_resultat
mov ah, 09h      ; output string at ds:dx
int 21h    
    pop dx
    pop ax
print_resultat  endp 



;;;;;;;
;proc-11     
;input/output   NONE
ScreenDelChar   PROC
    push ax
    MOV AH, 0Eh
    
    MOV AL, 08
    INT 10h     ;backspace
    
    MOV AL, ' '
    INT 10h ;erase
    
    MOV AL, 08
    INT 10h     ;backspace

    pop ax
    RET
ScreenDelChar   ENDP
    
                

;proc-10                
;input  AX
;output SCREEN
;vars   NONE                
PRINT_BIN   PROC
    PUSH CX
    PUSH DX
    PUSH AX    
    MOV DX, AX      ; save AX
    MOV CX, 16
    MOV AX, 0E30h   ; AH: func affichage char. AL='0'
    ADD DH, 0
        JNZ PrintBinLoop
    huit:    
    ;MOV CX, 8
    MOV DH, DL
    MOV DL, 00h ; DX = XX00h
    SHR CL, 1   ; CL = 0008h
PrintBinLoop:    
    ROL DX, 1   ; CF = MSB et decaler a gauche
    MOV AL, '1'
   JC PRINTBIT
    MOV AL, '0'
   PRINTBIT:
    INT     10h
DEC CL    
JNZ PrintBinLoop    
        MOV AL, 'b'
        INT 10h     ; print('b')
    POP AX
    POP DX
    POP CX
    RET
PRINT_BIN   ENDP
       

                
;proc-9
;input      keyboard
;output     cx, num
;vars       num dw
SCAN_BIN    PROC
    push dx
    push ax
    xor ax, ax
    mov num, 0
    mov cx, 16
    xor dx, dx

input_loop:
    ; input 0/1
    xor ax, ax    ; AH=0 : don't display
    int 16h

    CMP al, 0Dh
    je saveBin      ; Entrer: stop rec.
    ; Pas Entrer
    
    CMP al, 8       ; backspace
    JNE not_backspace
        ; SI BACKSPACE:
        
        CMP CX, 16           
            JE input_loop
        ; si bin pas vide
        CALL ScreenDelChar  ; effacer last char de l'ecran
        INC CX              ; annuler DEC CX
        SHR num, 1          ; depiler last char.
            JMP input_loop      
not_backspace:
    SUB al, '0'
    CMP al, 1
    ja input_loop   ; pas binaire : input again.
        ;cas: estBinaire
        ;display char:
        add al, 30h
        mov ah, 0Eh  ; affichage caractere
        int 10h
        sub al, 30h
    ;(empilage de bits: le sommet est a droite)
    SHL num, 1  ; creer un espace pour ce bit.
    xor ah, ah
    add num, ax ; forcer le poids faible a 1    
DEC CX
jnz input_loop       

saveBin:
    ;shr num, cl      ; Reglage du decalage si l'utilisateur saisie <16bits
    mov cx, num
    pop ax
    pop dx
RET

SCAN_BIN    ENDP



;proc-8
; entre/sortie : DL
HEX2CHAR PROC
    and dl, 0Fh
    cmp dl, 0Ah
    jb hexChiffre
        add dl, 37h
        RET
    hexChiffre:
        add dl, 30h
        RET
HEX2CHAR ENDP
;;;;;;;;;;;;



;proc-7
; entree : AX (ne change pas) / sortie: PRINT
PRINT_HEX PROC
    push dx
    xor dl, dl
    ;1
    mov dl, ah
    shr dl, 4
    CALL HEX2CHAR
    PUTC DL    
    ;2
    mov dl, ah
    CALL HEX2CHAR
    PUTC DL
    ;3
    mov dl, al
    shr dl, 4
    CALL HEX2CHAR
    PUTC DL
    ;4
    mov dl, al
    CALL HEX2CHAR
    PUTC DL
    ; dyn
    putc 'h'
    pop dx
    RET
PRINT_HEX ENDP
       
       
       
;proc-6
; exemple 'A'->0Ah; un char seulement: 0..9, a..f, A..F
; entree/sortie : charhex db  
CHAR2HEX PROC
    CMP charhex, '0'
    jb invalid_hexchar
     
    CMP charhex, '9'        
    jbe num2hex
    ; >'9'
    cmp charhex, 'A'
    jb invalid_hexchar
    ; >='A'
    cmp charhex, 'Z'
    ja min2hex
    ; <='F'
    maj2hex:sub charhex, 37h
            RET
    num2hex:sub charhex, 30h
            RET
    min2hex:cmp charhex, 'a'
            jb invalid_hexchar; <a
            cmp charhex, 'f'
            ja invalid_hexchar; >f
            ; sinon a..z
            sub charhex, 57h
            RET
    invalid_hexchar:
        mov charhex, 0ffh    ; not hex
    RET
CHAR2HEX ENDP   



;proc-5
; input : 4
; vars  : charhex db ?  (pour CHAR2HEX) 
; sortie: cx            (resultat comme OxFE7A)
SCAN_HEX    PROC
    push dx
    push ax
    mov dx, 0004h
    xor cx, cx
hex_input_loop:
    ; input hex
    xor ax, ax    ; AH=0 : don't display
    int 16h

    CMP al, 0Dh
    je saveHex      ; Entrer: stop rec.
    ; Pas Entrer
    
    CMP al, 8       ; backspace
    JNE hex_not_backspace
        ; SI BACKSPACE:
        
        CMP DL, 0004h           
            JE hex_input_loop
        ; si bin pas vide
        CALL ScreenDelChar  ; effacer last char de l'ecran
        INC DL              ; annuler DEC CX
        SHR  CX, 4          ; depiler last char.
            JMP hex_input_loop      
hex_not_backspace:
    mov charhex, al
    CALL CHAR2HEX
    CMP charhex, 0Fh
    ;jump if not hex
    ja hex_input_loop   ; pas hex : input again.
        ;cas: esthex
        ;display char:
        mov ah, 0Eh
        int 10h
    ;(empilage de chars: le sommet est a droite)
    SHL  CX, 4  ; creer un espace pour ce CHAR.
    mov al, charhex
    OR   CL, AL ; forcer le poids faible a hexnew
DEC DL
jnz hex_input_loop       
saveHex:
    pop ax
    pop dx
RET
SCAN_HEX    ENDP



;proc-4
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 13  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
;ten             DW      10      ; used as multiplier.
SCAN_NUM        ENDP

;ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
          

            
; proc-3
; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



;proc-2
; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP



;


;proc-1
GET_STRING      PROC    NEAR
PUSH    AX
PUSH    CX
PUSH    DI
PUSH    DX

MOV     CX, 0                   ; char counter.

CMP     DX, 1                   ; buffer too small?
JBE     empty_buffer            ;

DEC     DX                      ; reserve space for last zero.



; Eternal loop to get
; and processes key presses:

wait_for_key:

MOV     AH, 0                   ; get pressed key.
INT     16h

CMP     AL, 0Dh                  ; 'RETURN' pressed?
JZ      exit_GET_STRING


CMP     AL, 8                   ; 'BACKSPACE' pressed?
JNE     add_to_buffer
JCXZ    wait_for_key            ; nothing to remove!
DEC     CX
DEC     DI
PUTC    8                       ; backspace.
PUTC    ' '                     ; clear position.
PUTC    8                       ; backspace again.
JMP     wait_for_key

add_to_buffer:

        CMP     CX, DX          ; buffer is full?
        JAE     wait_for_key    ; if so wait for 'BACKSPACE' or 'RETURN'...

        MOV     [DI], AL
        INC     DI
        INC     CX
        
        ; print the key:
        MOV     AH, 0Eh
        INT     10h

JMP     wait_for_key


exit_GET_STRING:

; terminate by null:
MOV     [DI], 0

empty_buffer:

POP     DX
POP     DI
POP     CX
POP     AX
RET
GET_STRING      ENDP



end start
