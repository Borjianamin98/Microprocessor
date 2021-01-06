EXIT MACRO
    ; Exit to operating system
    MOV AX, 4C00H 
    INT 21h
ENDM

PRINT MACRO message
    PUSH AX
    PUSH DX
    MOV AH, 09
    MOV DX, OFFSET message
    INT 21H 
    POP DX
    POP AX
ENDM       

READ_STRING MACRO
    PUSH AX
    PUSH DX
    MOV AH, 0AH
    MOV DX, OFFSET buffer
    INT 21H 
    POP DX
    POP AX
ENDM  
                          
; Read decimal value from input and put it in result (DW)
READ_INTEGER MACRO result 
    LOCAL read_loop, error, finish
    PUSH AX 
    PUSH BX
    
    MOV BX, 0   ; Result will be in BX   
    read_loop:
        MOV AH, 1
        INT 21H     ; Character will be in AL
        CMP AL, CR
        JE finish
        CMP AL, '0'
        JB error
        CMP AL, '9'
        JA error
        AND AX, 000FH
        PUSH AX
        MOV AX, 10
        MUL BX
        MOV BX, AX
        POP AX
        ADD BX, AX 
    JMP read_loop
    error: 
        PRINT newLine
        PRINT error_message 
        EXIT   
    finish:
    
    MOV result, BX
    POP BX
    POP AX
ENDM
    
; Print decimal format (ascii format) of value (DW)
PRINT_INTEGER MACRO value 
    LOCAL divide_loop, print_loop 
    PUSH AX 
    PUSH BX
    PUSH CX
    PUSH DX
            
    MOV CX, 0   
    MOV AX, value
    divide_loop:
        MOV BX, 10 
        MOV DX, 0
        DIV BX ; Reminder in DX and quotient in AX
        PUSH DX
        INC CX
        CMP AX, 0
    JNE divide_loop
     
    ; CX is at least 1 if number >= 0
    print_loop:
        POP DX
        ADD DL, '0' 
        MOV AH, 2
        INT 21H
    LOOP print_loop
        
    POP DX
    POP CX
    POP BX
    POP AX
ENDM

data_segment SEGMENT
    ; General data  
    buffer_length EQU 100   
    buffer LABEL BYTE
    buffer_max_size DB buffer_length
    buffer_current_length DB ?
    buffer_data DB buffer_length DUP (0FFH)
    
    CR EQU 0DH
    LF EQU 0AH
    newLine DB CR, LF, '$'
       
    ; Specific data
    input_message DB "Enter number for AX register (16 bit): ", '$'
    error_message DB "Invalid number!", '$'       
    output_message DB "Value of DX register: ", '$'        
    
    number DW ?
    result DW ? 
data_segment ENDS

stack_segment SEGMENT
    dw   128  dup(0)
stack_segment ENDS

code_segment SEGMENT     

start PROC   
    ; Initialize data and extra segment
    ASSUME SS:stack_segment,CS:code_segment,DS:data_segment,ES:data_segment
    MOV AX, data_segment
    MOV DS, AX
    MOV ES, AX
    ; Call program main function  
    CALL main
    ; Exit to operating system
    EXIT       
start ENDP 

main PROC NEAR
    PRINT input_message              
    READ_INTEGER number
    PRINT newLine
     
    MOV AX, number
    MOV CX, 0
    MOV CL, 8
    check_bit_loop:
        ; Get first, second, ..., seven bit  
        MOV BX, AX
        MOV DL, 8
        SUB DL, CL
        PUSH CX    ; Only CL can be used for shift
        MOV CL, DL
        SHR BX, CL ; DX-th bit is in bit 0 of BX
        POP CX
        AND BX, 0001H
        PUSH BX
        
        ; Get 15, 14, ..., 8 bit 
        MOV BX, AX
        MOV DL, 7
        ADD DL, CL
        PUSH CX    ; Only CL can be used for shift
        MOV CL, DL
        SHR BX, CL ; DX-th bit is in bit 0 of BX
        POP CX
        AND BX, 0001H
        PUSH BX
        
        POP DX
        POP BX
        CMP BX, DX
        JNE is_not_plaindrome
    LOOP check_bit_loop
    
    MOV DX, 1
    JMP print_result
    is_not_plaindrome:
    MOV DX, 0
    
    print_result:
    PRINT output_message 
    PRINT_INTEGER DX 
    RET
main ENDP

code_segment ENDS
END start 
