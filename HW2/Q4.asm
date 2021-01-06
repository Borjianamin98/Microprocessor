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

READ MACRO  
    PUSH AX
    PUSH DX
    MOV AH, 0AH
    MOV DX, OFFSET buffer
    INT 21H 
    POP DX
    POP AX
ENDM

data SEGMENT
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
    input_message DB "Enter your string: ", '$'       
    output_message DB "Converted string is: ", '$'        
    output DB buffer_length DUP(0FFH), '$'
data ENDS

stack SEGMENT
    dw   128  dup(0)
stack ENDS

code SEGMENT
    
start PROC   
    ; Initialize data and extra segment
    ASSUME SS:stack,CS:code,DS:data,ES:data
    MOV AX, data
    MOV DS, AX
    MOV ES, AX
    ; Call program main function  
    CALL main
    ; Exit to operating system
	EXIT
start ENDP 

main PROC NEAR
    PRINT input_message              
    READ
    PRINT newLine
                       
    MOV CX, 0
    MOV CL, buffer_current_length  
    MOV SI, OFFSET buffer_data
    MOV DI, OFFSET output
    MOV BX, 0
    convert:
    MOV AL, [SI + BX]
    CMP AL, 'a'       
    JB next
    CMP AL, 'z'
    JA next
    ADD AL, 'A' - 'a'
    
    next:
    MOV DI[BX], AL
    INC BX
    LOOP convert
    MOV DI[BX], '$'
    
    PRINT output_message 
    PRINT output 
    RET
main ENDP

code ENDS
END start 
