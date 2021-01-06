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
    input_length_message DB "Enter array length (length > 1): ", '$'  
    input_data_message DB "Enter array data in each line: ", '$'
    error_message DB "Invalid number!", '$' 
    intermediate_output_message DB "intermediate sorted array is: ", '$'     
    final_output_message DB "Final sorted array is: ", '$'
    space_message DB 20H, '$'        
    
    array_length DW ?
    array_length_in_word DW ?
    array_one_data DW ?  
    ; ORG 1000H
    array_data DW 100 DUP (0H)  
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
    PRINT input_length_message              
    READ_INTEGER array_length
    PRINT newLine
      
    ; Get array in input 
    ; First length of array then values in each line
    PRINT input_data_message 
    PRINT newLine
    MOV CX, array_length       
    MOV BX, 0
    MOV SI, OFFSET array_data
    get_array:
        READ_INTEGER array_one_data
        MOV DX, array_one_data
        MOV [SI + BX], DX
        INC BX
        INC BX  
        PRINT newLine
    LOOP get_array
                    
    MOV array_length_in_word, BX
    
    ; Insertion sort        
    MOV BX, OFFSET array_data
    MOV SI, 2 ; Number 2 are because we use word data in array   
    sort_i_th_element:
        MOV AX, [BX + SI]
        MOV DI, SI
        DEC DI
        DEC DI
        
        inner_loop:
            CMP DI, 0
            JL exit   
            MOV CX, [BX + DI]
            CMP CX, AX
            JBE exit
            MOV [BX + DI] + 2, CX
            DEC DI 
            DEC DI
        JMP inner_loop 
      
        exit:
        CMP DI, 0
        JGE set_element
            MOV [BX], AX
            JMP next
        set_element:         
            MOV [BX + DI] + 2, AX 
        
        next:
        ; Print intermedaite array in output
        PRINT newLine  
        PRINT intermediate_output_message
        CALL printArray    
            
        INC SI
        INC SI 
        CMP SI, array_length_in_word 
    JB sort_i_th_element 
    
    ; Print final array in output
    PRINT newLine  
    PRINT final_output_message
    CALL printArray
     
    RET
main ENDP  

printArray PROC   
    PUSH AX 
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH SI
    PUSH DI
    
        
    MOV CX, array_length   
    MOV BX, 0
    MOV SI, OFFSET array_data
    print_array:       
        MOV DX, [SI + BX]   
        MOV array_one_data, DX
        PRINT_INTEGER array_one_data
        PRINT space_message
        INC BX
        INC BX 
    LOOP print_array  
         
    POP DI
    POP SI         
    POP DX 
    POP CX
    POP BX
    POP AX  
    
    RET
printArray ENDP

code_segment ENDS
END start 
