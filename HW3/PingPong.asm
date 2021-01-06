SetScreenMode MACRO mode
    PUSH AX
    MOV AH, 0     ; SET MODE OPTION
    MOV AL, mode  
    INT 10H 
    POP AX
ENDM      

EXIT MACRO
    ; go back to text mode
    SetScreenMode 3      
    ; Exit to operating system
    MOV AX, 4C00H 
    INT 21h  
ENDM  

MACRO CheckExit
    LOCAL excape_key_not_presseed 
    MOV AH, 01
    INT 16H  
    CMP AL, 27
    JNE excape_key_not_presseed
        MOV AH, 0
        INT 16H
        EXIT
    excape_key_not_presseed:
ENDM   

data_segment SEGMENT  
    buffer_length EQU 100   
    buffer LABEL BYTE
    buffer_max_size DB buffer_length
    buffer_current_length DW ?
    buffer_data DB buffer_length DUP (0FFH)
    
    CR EQU 0DH
    LF EQU 0AH
    newLine DB CR, LF, '$'
       
    center_row EQU 12
    center_column EQU 20
    
    start_message DB "Start game by press space ..."
    start_message_end LABEL BYTE
    start_message_length EQU start_message_end-OFFSET start_message    
    
    end_message DB "Game Over"
    end_message_end LABEL BYTE
    end_message_length EQU end_message_end-OFFSET end_message 
    
    ; Board
    board_width EQU 3
    board_up_row EQU 20
    board_down_row EQU 180
    board_left_column EQU 20  
    board_right_column EQU 270
    board_right_up EQU 
    
    ; Player
    player_row DW 100
    player_column EQU 272 ; board_right_column + player_width
    player_width EQU 2
    player_height EQU 20 
    player_speed EQU 10
      
    ; Ball
    ball_frame DW 0
    ball_frame_dafault EQU 50
    ball_row DW 100
    ball_column DW 250
    ball_size EQU 3 
    ball_row_speed DW -1
    ball_column_speed DW -1
    ball_color DW 0FH
     
    ; Score   
    score DW 0
    score_row EQU 1
    score_column EQU 17             
    
    ; Random number
    random_seed DW ? 
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
ENDP 

InitRandomNumberGenerator PROC  
    PUSH CX
    PUSH DX 
       
    ; Interrupt to get system timer in CX:DX 
    MOV AH, 2CH
    INT 21H 
    MOV random_seed, DX
        
    POP DX
    POP CX

    RET  
ENDP      

GenerateNextRandom PROC  
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH DI
    PUSH SI 
       
    ; Use Linear Congruential Generator (LCG) to generate random number from seed
    MOV AX, 25173           ; LCG Multiplier
    MUL random_seed         ; DX:AX = LCG multiplier * seed
    ADD AX, 13849           ; Add LCG increment value
                            ; Modulo 65536, AX = (multiplier*seed+increment) mod 65536
    MOV random_seed, AX     ; Update seed
        
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX  

    RET  
ENDP 

PrintCharMultiTime PROC  
    MOV BP, SP  
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH DI
    PUSH SI               
       
    ; setting the cursor to the begin of message
    MOV BH, 0  ; page 0
    MOV DH, [BP] + 6 ; row 
    MOV DL, [BP] + 4 ; column
    MOV AH, 02
    INT 10H   
    ; Print character at the cursor position
    MOV AL, [BP] + 10 ; character
    MOV BH, 0
    MOV BL, [BP] + 8 ; format
    MOV CX, [BP] + 2 ; length
    MOV AH, 09
    INT 10H
        
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX            
    
    RET  
ENDP 

PrintString PROC  
    MOV BP, SP  
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH DI
    PUSH SI 
                             
    ; Calculate center of column
    MOV DL, [BP] + 4 ; column
    MOV AX, [BP] + 2 ; length
    SHR AX, 1
    SUB DL, AL ; DL is column centered               
       
    MOV AL, 1
    MOV BH, 0
    MOV BL, [BP] + 8 ; format   
    MOV CX, [BP] + 2 ; length
    MOV DH, [BP] + 6 ; row     
    ; Provide string in buffer
    PUSH DS 
    POP ES
    MOV BP, [BP] + 10 ; OFFSET of string data
    MOV AH, 13H
    INT 10H
        
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX            
    
    RET  
ENDP
    
; Input value will be converted to decimal format and put in buffer
ConvertToInteger PROC  
    MOV BP, SP  
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH DI
    PUSH SI               
       
    MOV CX, 0   
    MOV AX, [BP] + 2 ; value
    divide_loop:
        MOV BX, 10 
        MOV DX, 0
        DIV BX ; Reminder in DX and quotient in AX
        PUSH DX
        INC CX
        CMP AX, 0
    JNE divide_loop
     
    ; CX is at least 1 if number >= 0 
    MOV buffer_current_length, CX
    ; setting the cursor to the begin of column 
    MOV DI, OFFSET buffer_data   
    get_digit_loop:
        POP BX
        ADD BL, '0' 
        MOV [DI], BL
        INC DI
    LOOP get_digit_loop
        
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX            
    
    RET  
ENDP

DrawRectangle PROC  
    MOV BP, SP  
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX 
    PUSH DI
    PUSH SI 
       
    MOV DX, [BP] + 10 ; up_row_of_draw_rectangle
    MOV DI, [BP] + 4 ; right_column_of_draw_rectangle
    MOV SI, [BP] + 8 ; down_row_of_draw_rectangle
    draw_height:
        MOV CX, [BP] + 6 ; left_column_of_draw_rectangle
        draw_width: 
            MOV AX, [BP] + 2 ; color 
            MOV AH, 0CH
            INT 10H
            INC CX
            CMP CX, DI     
        JB draw_width
        INC DX
        CMP DX, SI     
    JB draw_height 
        
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX   
         
    
    RET  
ENDP

DrawPlayer PROC
    MOV BP, SP     
    PUSH AX 
    
    MOV AX, player_row
    SUB AX, player_height                       ; up row  
    PUSH AX
    MOV AX, player_row
    ADD AX, player_height                       ; down row   
    PUSH AX
    MOV AX, player_column            
    SUB AX, player_width                        ; left column     
    PUSH AX
    MOV AX, player_column            
    ADD AX, player_width                        ; right column                      
    PUSH AX  
    MOV AX, [BP] + 2 ; color
    PUSH AX    
    CALL DrawRectangle 
    ADD SP, 5 * 2
    
    POP AX   
    
    RET
ENDP 

DrawBall PROC
    MOV BP, SP     
    PUSH AX 
    
    MOV AX, ball_row
    SUB AX, ball_size                           ; up row  
    PUSH AX
    MOV AX, ball_row
    ADD AX, ball_size                           ; down row   
    PUSH AX
    MOV AX, ball_column
    SUB AX, ball_size                           ; left column
    PUSH AX
    MOV AX, ball_column
    ADD AX, ball_size                           ; right column                   
    PUSH AX  
    MOV AX, [BP] + 2 ; color
    PUSH AX    
    CALL DrawRectangle 
    ADD SP, 5 * 2
    
    POP AX   
    
    RET
ENDP

DrawScore PROC    
    PUSH AX 
    
    ; Convert score to a integer and store it in buffer  
    MOV AX, score
    PUSH AX
    CALL ConvertToInteger
    ADD SP, 2
    
    ; We call another function so we set it again
    ; We must consider AX in stack too
    MOV BP, SP 
     
    ; Print score in center of screen
    MOV AX, OFFSET buffer_data
    PUSH AX
    MOV AX, [BP] + 4 ; format
    PUSH AX
    MOV AX, [BP] + 8 ; row 
    PUSH AX
    MOV AX, [BP] + 6 ; column
    PUSH AX
    MOV AX, buffer_current_length
    PUSH AX
    CALL PrintString
    ADD SP, 5 * 2 
    
    ; Show it in LEDs
    MOV AX, score
    OUT 199, AX 
    
    POP AX   
    
    RET
ENDP

main PROC NEAR                 
    CALL InitRandomNumberGenerator
    
    ; Calculate ball location randomly
    CALL GenerateNextRandom  
    MOV AX, random_seed
    MOV DX, 0
    MOV CX, board_down_row
    SUB CX, board_up_row
    SUB CX, player_height
    SUB CX, player_height
    DIV CX ; DX contains the remainder      
    ADD DX, board_up_row        
    ADD DX, player_height
    MOV ball_row, DX     
    ; MOV player_row, DX

    ; 640x200 16 colors graphical screen
    SetScreenMode 02H

    ; Print start game message 
    MOV AX, OFFSET start_message
    PUSH AX
    MOV AX, 0ACH
    PUSH AX
    MOV AX, center_row
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, start_message_length
    PUSH AX
    CALL PrintString
    ADD SP, 5 * 2  
           
    ; Read until get space from input
    read_loop:
        MOV AH, 7H
        INT 21H
        CMP AL, ' '
    JNE read_loop
    
    ; Remove start game message    
    MOV AX, ' '
    PUSH AX
    MOV AX, 07H
    PUSH AX
    MOV AX, center_row
    PUSH AX
    MOV AX, 40 - start_message_length / 2
    PUSH AX
    MOV AX, start_message_length
    PUSH AX
    CALL PrintCharMultitime
    ADD SP, 5 * 2
    
    ; 320x200 256 colors graphical screen
    SetScreenMode 13H
           
    ; Draw left vertical line of board
    MOV AX, board_up_row - board_width          ; up row  
    PUSH AX
    MOV AX, board_down_row + board_width        ; down row   
    PUSH AX
    MOV AX, board_left_column - board_width     ; left column   
    PUSH AX
    MOV AX, board_left_column                   ; right column
    PUSH AX  
    MOV AX, 0FH
    PUSH AX
    CALL DrawRectangle
    ADD SP, 5 * 2
                    
    ; Draw down line of board  
    MOV AX, board_down_row                      ; up row  
    PUSH AX
    MOV AX, board_down_row + board_width        ; down row   
    PUSH AX
    MOV AX, board_left_column                   ; left column   
    PUSH AX
    MOV AX, board_right_column                  ; right column
    PUSH AX  
    MOV AX, 0FH
    PUSH AX
    CALL DrawRectangle
    ADD SP, 5 * 2
    
    ; Draw up line of board 
    MOV AX, board_up_row - board_width          ; up row  
    PUSH AX
    MOV AX, board_up_row                        ; down row   
    PUSH AX
    MOV AX, board_left_column                   ; left column   
    PUSH AX
    MOV AX, board_right_column                  ; right column
    PUSH AX  
    MOV AX, 0FH
    PUSH AX
    CALL DrawRectangle 
    ADD SP, 5 * 2 
    
    ; Draw player first time
    MOV AX, 0FH  
    PUSH AX
    CALL DrawPlayer 
    ADD SP, 2  
    
     ; Print score first time
    MOV AX, score_row 
    PUSH AX
    MOV AX, score_column
    PUSH AX
    MOV AX, 07H
    PUSH AX
    CALL DrawScore
    ADD SP, 3 * 2
    
    game_loop:               
        ; Check escape is pressed 
        CheckExit  
        
        ; Check up arrow key is pressed
        MOV AH, 01
        INT 16H
        CMP AH, 48H
        JNE up_key_not_presseed
            MOV AH, 0
            INT 16H
             
            ; Check up limit
            MOV AX, player_row 
            SUB AX, player_height
            SUB AX, player_speed
            CMP AX, board_up_row
            JL up_key_not_presseed
            
            ; Clear last player
            MOV AX, 0
            PUSH AX
            CALL DrawPlayer
            ADD SP, 2
            
            ; Update player position
            MOV AX, player_row
            SUB AX, player_speed
            MOV player_row, AX 
            
            ; Draw player
            MOV AX, 0FH  
            PUSH AX
            CALL DrawPlayer 
            ADD SP, 2

            JMP after_key_pressed
        up_key_not_presseed: 
        
        ; Check down arrow key is pressed 
        MOV AH, 01
        INT 16H
        CMP AH, 50H
        JNE down_key_not_presseed
            MOV AH, 0
            INT 16H   
                                     
            ; Check down limit
            MOV AX, player_row 
            ADD AX, player_height
            ADD AX, player_speed
            CMP AX, board_down_row
            JG down_key_not_presseed
            
            ; Clear last player
            MOV AX, 0
            PUSH AX
            CALL DrawPlayer
            ADD SP, 2 
            
            ; Update player position
            MOV AX, player_row
            ADD AX, player_speed
            MOV player_row, AX  
            
            ; Draw player
            MOV AX, 0FH  
            PUSH AX
            CALL DrawPlayer 
            ADD SP, 2
            
            JMP after_key_pressed
        down_key_not_presseed:
        
        ; Ignore any other key
        CheckExit
        MOV AH, 01
        INT 16H
        
        JZ ignore_key
            MOV AH, 0
            INT 16H    
        ignore_key:
        
        after_key_pressed:
        
        ; Update ball position
        MOV AX, ball_frame
        INC AX
        MOV ball_frame, AX
        CMP AX, ball_frame_dafault
        JNE after_update_ball 
            MOV ball_frame, 0
            
            ; Check position
            ; Check up limit
            MOV AX, ball_row 
            SUB AX, ball_size
            ADD AX, ball_row_speed
            CMP AX, board_up_row
            JG ball_up_check_skipped 
                ; Check corner up limit
                MOV AX, ball_row_speed
                NEG AX
                MOV ball_row_speed, AX    
            ball_up_check_skipped:    
            
            ; Check left limit
            MOV AX, ball_column 
            SUB AX, ball_size
            ADD AX, ball_column_speed
            CMP AX, board_left_column
            JG ball_left_check_skipped
                MOV AX, ball_column_speed
                NEG AX
                MOV ball_column_speed, AX    
            ball_left_check_skipped:
            
            ; Check down limit
            MOV AX, ball_row 
            ADD AX, ball_size
            ADD AX, ball_row_speed
            CMP AX, board_down_row
            JB ball_down_check_skipped
                MOV AX, ball_row_speed
                NEG AX
                MOV ball_row_speed, AX    
            ball_down_check_skipped:  
            
            ; Check right limit
            MOV AX, ball_column 
            ADD AX, ball_size
            ADD AX, ball_column_speed
            CMP AX, board_right_column
            JB ball_right_check_skipped  
                ; Check player failed when ball go outside from up
                MOV AX, player_row
                SUB AX, player_height
                MOV BX, ball_row
                ADD BX, ball_size
                CMP BX, AX
                JGE skip_fail_up  
                    JMP exit_game_loop
                skip_fail_up:
                
                ; Check player failed when ball go outside from down
                MOV AX, player_row
                ADD AX, player_height
                MOV BX, ball_row
                SUB BX, ball_size
                CMP BX, AX
                JBE skip_fail_down  
                    JMP exit_game_loop
                skip_fail_down:    
                
                ; Ball hit racket 
                ; Update score 
                MOV AX, score
                INC AX
                MOV score, AX 
                
                ; Print score
                MOV AX, score_row 
                PUSH AX
                MOV AX, score_column
                PUSH AX
                MOV AX, 07H
                PUSH AX
                CALL DrawScore
                ADD SP, 3 * 2
           
                ; Change ball color randomly
                CALL GenerateNextRandom  
                MOV AX, random_seed
                MOV DX, 0
                MOV CX, 13
                DIV CX        
                ADD DX, 2        ; DX contains the remainder - from 2 to 14
                MOV ball_color, DX
                
                ; Update direction of ball
                MOV AX, ball_column_speed
                NEG AX
                MOV ball_column_speed, AX    
            ball_right_check_skipped:
            
            ; Clear last ball
            MOV AX, 0  
            PUSH AX
            CALL DrawBall 
            ADD SP, 2
            
            ; Update position
            MOV AX, ball_row
            ADD AX, ball_row_speed
            MOV ball_row, AX
            MOV AX, ball_column
            ADD AX, ball_column_speed
            MOV ball_column, AX 
            
        after_update_ball:  
        
        ; Draw ball
        MOV AX, ball_color  
        PUSH AX
        CALL DrawBall 
        ADD SP, 2
        
    JMP game_loop
    
    exit_game_loop:
    ; 640x200 16 colors graphical screen
    SetScreenMode 02H 

    ; Print end game message   
    MOV AX, OFFSET end_message
    PUSH AX
    MOV AX, 0EH
    PUSH AX
    MOV AX, center_row 
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, end_message_length
    PUSH AX
    CALL PrintString
    ADD SP, 5 * 2 
    
    ; Print score
    MOV AX, center_row 
    INC AX
    PUSH AX
    MOV AX, 40
    PUSH AX
    MOV AX, 0EH
    PUSH AX
    CALL DrawScore
    ADD SP, 3 * 2
           
    ; Read until get space from input
    exit_button_loop:
        MOV AH, 7H
        INT 21H
        CMP AL, ' '
    JNE exit_button_loop
    EXIT
    
    RET
main ENDP

code_segment ENDS
END start 
