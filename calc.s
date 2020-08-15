section	.rodata			; we define (global) read-only variables in .rodata section
    check: db "check", 5, 0	; format string
	calc: db "calc: ", 7, 0	; format string
    oveflow: db "Error: Operand Stack Overflow",10, 0	; format overflow
    Insufficient: db "Error: Insufficient Number of Arguments on Stack",0 ;format Insufficient
    int_format: db "%d ", 10, 0	; format string
    string_format: db "%s ", 10, 0	; format string
    char_format: db "%c ", 10, 0	; format string
    debug_read: db "input from user: %s",0
    debug_push: db "pushed to stack: ",0
section .bss
    userInput: resb 80		
    index: resb 4
    helpingLink: resb 4
    helpingLink2: resb 4
    numHelper: resb 1
    stack: resb 4
    stackCurrent: resb 4
    stackLimit: resb 4
    stackCounter: resb 4
    array: resb 82
    plusLink1: resb 4
    plusLink2: resb 4
    carry: resb 4
    operationCounter: resb 4
    an: resb 12
    debug: resb 4
    

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern stdin
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  ;extern gets 
  extern getchar 
  extern fgets 
%macro transformString 0
    cmp ecx, 58					
	jl %%less_then_10
	sub ecx, 55					;if more then 10 so make letter
	jmp %%after_cmp
	%%less_then_10:
	sub ecx, 48					;else make it integer by string
	%%after_cmp:
%endmacro

main:
    push ebp
	mov ebp, esp	
    pushad

    ;check if there are arguments
    
    cmp dword [ebp+8], 1    ;check if argc =1 or >1
    je initiate_5
    mov eax, [ebp+12]
    mov ebx, [eax+4]        ;eax= argv[1]   
    movzx ecx, byte[ebx]
    cmp ecx, '-'                ;debug with no number to initiate
    jne makeIntFromString

    mov dword[debug], 1

    jmp initiate_5

    makeIntFromString:
    transformString
    pushad
    mov [numHelper],ecx

    cmp byte[ebx+1], 0x0
    je oneDig
    mov eax, 16
    pushad
    mul ecx
    movzx ecx, byte[ebx]
    transformString
    add eax, ecx
    jmp afterOneDig
    oneDig:
    mov eax, ecx
    afterOneDig:
    mov [stackLimit], eax   ;max= argv[1]

    mov ebx, 4
    pushad
    push ebx
    push eax
    call calloc             ;initiate stack in the size of agrv[1]*4
    add esp, 8
    mov [stack], eax
    mov [stackCurrent], eax
    popad 

    cmp dword [ebp+8], 2    ;check if argc =1 or >1  ;check for debug after number   
    jle noDebug
    mov eax, [ebp+12]
    mov ebx, [eax+8]        ;eax= argv[1]   
    movzx ecx, byte[ebx]
    cmp ecx, '-'                ;debug with no number to initiate
    jne noDebug
    mov dword[debug], 1
    jmp finish_initiate_stack
    noDebug: 
    mov dword[debug], 0

    jmp finish_initiate_stack
    initiate_5:
    mov eax, 5
    mov [stackLimit], eax   ;max= 5
    mov ebx, 4
    pushad
    push ebx
    push eax
    call calloc             ;initiate stack in the size of 5*4
    add esp, 8
    mov [stack], eax
    mov [stackCurrent], eax
    popad
    finish_initiate_stack:
    
    mov dword [stackCounter], 0
    mov dword [operationCounter], 0

    main_loop:
    push calc       ;get the input from the user
    call printf
    add esp, 4
    push 0
    call fflush
    add esp, 4

    pushad
    mov eax, dword[stdin]       ;input from the user
    mov ebx, 80
    push eax
    push ebx
    push userInput
    call fgets
    add esp, 12
    popad
    

    cmp byte [userInput], 'p'
    jne notP
    call pop_and_print
    inc dword[operationCounter]
    jmp main_loop
    notP:

    cmp byte [userInput], '+'
    jne notPlus
    call plus
    inc dword[operationCounter]
    jmp main_loop
    notPlus:

    cmp byte [userInput], 'd'
    jne notDup
    call dup
    inc dword[operationCounter]
    jmp main_loop
    notDup:

    cmp byte [userInput], '&'
    jne notAnd
    call AndFunc
    inc dword[operationCounter]
    jmp main_loop
    notAnd:

    cmp byte [userInput], '|'
    jne notOr
    call OrFunc
    inc dword[operationCounter]
    jmp main_loop
    notOr:

    cmp byte [userInput], 'n'
    jne notNumber
    call nFunc
    inc dword[operationCounter]
    jmp main_loop
    notNumber:

    cmp byte [userInput], 'q'
    je end_main_loop


    cmp dword[debug], 0
    je notDebug
    push userInput
    push debug_read
    call printf
    add esp,8
    notDebug:

    mov eax, [stackCounter]    ;eax= current point of the stack
    cmp eax, [stackLimit]   ;eax= max size of the stack    
    je stack_oveflow
    pushad
    mov ebx, userInput
    call makeList       ;;new linked list int eax
    popad

    mov ecx, [helpingLink]      ;retrive the pointer to the head of the list        
    mov ebx, [stackCurrent]
    mov [ebx], ecx     ;ebx= current free place of the stack
    add dword[stackCounter],1
    add dword[stackCurrent],4 
    inc dword[operationCounter]
    jmp main_loop

    stack_oveflow:      ;in case that there is no space in the stack
    push oveflow
    call printf
    add esp, 4
    end_overflow:
    jmp main_loop

    end_main_loop:
    call printCounter
    call freeStack

    ;end prog
    popad
    mov esp, ebp	
	pop ebp
	ret

;***************************************************
freeStack:
    mov eax, [stackCounter]
    cmp eax, 0
    je freeEmptyStack
    freeListLoop:
    cmp dword[stackCounter],0
    je freeEmptyStack
    sub dword[stackCurrent],4
    call freeListfromCurrent
    sub dword[stackCounter],1
    jmp freeListLoop

    freeEmptyStack:

    mov eax, [stackCurrent]
    push eax
    call free
    add esp, 4
    ret
;****************************************************
freeListfromCurrent:
    mov eax, [stackCurrent]
    mov eax, [eax]
    freeLinkLoop:
    cmp eax, 0
    je endFreeLinkLoop
    mov ebx, [eax+1]
    mov [helpingLink], ebx
    push eax
    call free
    add esp,4
    mov eax,[helpingLink]
    jmp freeLinkLoop

    endFreeLinkLoop:
    ret

;******************************************************
printCounter:
    mov eax, [operationCounter]

    cmp eax, 0
	jne out_not_zero
	mov byte [an], '0'
	mov byte [an+1], 0x0
	jmp printOutput
	
	out_not_zero:
	mov ebx, 16
	mov ecx, 0					;count numbers of chars
	while_loop2:
	cmp eax, 0
	je out_end_loop2
	cdq
	div ebx							;divid eax by 16
	cmp edx, 10					
	jl out_less_then_10
	add edx, 55					;if more then 10 so make letter
	jmp out_after_cmp1
	out_less_then_10:
	add edx, 48					;else make it integer by string
	out_after_cmp1:
	push edx						;put every char in the stack
	inc ecx
	jmp while_loop2
	out_end_loop2:
		
	mov ebx, 0					;ebx is the counter for the string
	while_pop:
	cmp ecx, 0
	je end_while_pop
	pop eax
	mov [an+ebx], eax		;put each char in the string 
	inc ebx
	sub ecx, 1
	jmp while_pop
	end_while_pop:
	mov  byte[an+ebx], 0x0	;put terminated char int the end of the string

    printOutput:
	push dword an					; call printf with 2 arguments -  
	push string_format	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call
    ret
;******************************************


makeList:
    
    mov eax, 0                   ;check the number of digits of the input
    count_digits:                  
    cmp byte [ebx+eax] , 0xA
    je finish_count    
    inc eax
    jmp count_digits
    finish_count:


    mov dword[helpingLink], 0x0
    mov ecx,0
    loose_zero:                  ;earase the initiate 0 in the input
    cmp byte [ebx+ecx] , '0'
    jne check_num_digits
    inc ecx
    cmp eax, ecx
    je number_is_zero
    jmp loose_zero

    check_num_digits:           ;count the number of digits in the str
    add ebx, ecx                ;ebx is the pinter for the string from the first num
    mov eax,0                   ;eax is the num of digits
    loop_count:
    cmp byte [ebx+eax], 0xA
    je finish_str
    inc eax
    jmp loop_count
    finish_str:
                                
    mov ecx,2                   ;check if there are even number of digits
    cdq
    div ecx
        
    cmp edx, 0
    je even_digits
odd_digits:                 ;in case ther is odd digits, the first link will be 1 digit
    movzx ecx, byte[ebx]
    transformString
    inc ebx
    
    ;create new link
    mov [numHelper], ecx
    mov [index], ebx
    push 5
    call malloc
    add esp, 4
    movzx ecx, byte[numHelper]
    mov ebx, dword [index]      ;renew the pointer of the string
    mov byte[eax], cl
    mov dword[eax+1], 0x0   
    mov [helpingLink], eax      ;set the new link

    

even_digits:
    loop1:
    mov eax, 16
    cmp byte [ebx] , 0xA
    je end_loop_1
    movzx ecx, byte [ebx]
    transformString
    inc ebx
    mul ecx
    movzx ecx, byte [ebx]
    transformString
    inc ebx
    add ecx, eax

    mov [numHelper], ecx
    mov [index], ebx
    push 5
    call malloc
    add esp, 4
    movzx ecx, byte[numHelper]
    mov ebx, dword [index]
    mov byte[eax], cl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax      ;first link in helping Link

    jmp loop1
    end_loop_1:
    jmp end_func
    
    number_is_zero:         ;in case that the number is 0
    push 5
    call malloc
    add esp, 4
    mov byte[eax], 0
    mov dword[eax+1],0
    mov [helpingLink],eax
    
    end_func:
    mov eax, [helpingLink]
    ret
;******************************************

print_check:
    push check
    call printf
    add esp, 4
    push 0
    call fflush
    add esp, 4
    ret

;******************************************
pop_and_print:
    cmp dword[stackCounter], 0
    je Insufficient_on_stack1
    sub dword[stackCounter], 1
    sub dword[stackCurrent], 4
    mov eax, [stackCurrent]
    mov eax, [eax]
    call print_list   
    
    ret


    Insufficient_on_stack1:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret
;*******************************************
nFunc:
    mov eax, [stackCounter]
    cmp eax, 1
    jl Insufficient_on_stack5       ;check if there are 1 arg in the stack
      
    sub dword[stackCurrent], 4      ;get first arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink1], ebx
    mov ecx, 0

    loop18:
    cmp dword[plusLink1], 0
    je end_of_count 
    mov ebx, [plusLink1]
    movzx ebx, byte[ebx]
    cmp ebx, 0
    je after_add
    cmp ebx, 15
    jle add_one
    add ecx, 2
    jmp after_add
    add_one:
    inc ecx
    after_add: 
    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    jmp loop18
    end_of_count:

    mov [numHelper], ecx
    push 5
    call malloc
    add esp, 4
    mov [helpingLink],eax
    mov ecx, [numHelper]
    mov byte[eax], cl
    mov dword[eax+1],0
    
    mov ebx, [stackCurrent]
    mov [ebx], eax
    add dword[stackCurrent],4
    ret

    Insufficient_on_stack5:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret

;*************************************************
AndFunc:
    mov eax, [stackCounter]
    cmp eax, 2
    jl Insufficient_on_stack3       ;check if there are 2 args in the stack

    sub dword[stackCounter], 2      
    sub dword[stackCurrent], 4      ;get first arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink1], ebx
    sub dword[stackCurrent], 4      ;get secound arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink2], ebx

    mov dword[helpingLink],0
    loop10:  
    cmp dword[plusLink1], 0
    je stop_anding    
    cmp dword[plusLink2], 0
    je stop_anding   
    
    mov ebx, [plusLink1]
    movzx ebx, byte[ebx]
    mov ecx, [plusLink2]
    movzx ecx, byte[ecx]
    and bl, cl
    mov byte[numHelper],bl

    
    push 5
    call malloc
    add esp, 4
    movzx ebx, byte[numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  
    

    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    
    mov ebx, [plusLink2]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink2], ebx
        pushad                  ;free the link in the second list
        push edx
        call free
        add esp,4
        popad
    jmp loop10
    stop_anding:


    push_in_stack2:
    mov dword [helpingLink2], 0
    mov eax, [helpingLink]
    loop13:
    cmp eax, 0
    je stop_changing2
    mov ebx, [eax+1]
    mov ecx, [helpingLink2]
    mov [eax+1], ecx
    mov [helpingLink2], eax
    mov eax, ebx
    jmp loop13
    stop_changing2:


    mov ecx, [helpingLink2]      ;retrive the pointer to the head of the list        
    mov ebx, [stackCurrent]
    mov [ebx], ecx              ;ebx= current free place of the stack
    add dword[stackCounter],1
    add dword[stackCurrent],4 
    ret

    Insufficient_on_stack3:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret

;************************************************
OrFunc:
    mov eax, [stackCounter]
    cmp eax, 2
    jl Insufficient_on_stack4       ;check if there are 2 args in the stack

    sub dword[stackCounter], 2      
    sub dword[stackCurrent], 4      ;get first arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink1], ebx
    sub dword[stackCurrent], 4      ;get secound arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink2], ebx

    mov dword[helpingLink],0
    loop14:  
    cmp dword[plusLink1], 0
    je or_only_link_2    
    cmp dword[plusLink2], 0
    je or_only_link_1   
    
    mov ebx, [plusLink1]
    movzx ebx, byte[ebx]
    mov ecx, [plusLink2]
    movzx ecx, byte[ecx]
    or ebx, ecx
    mov [numHelper],ebx
    
    push 5
    call malloc
    add esp, 4
    movzx ebx, byte[numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  

    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    
    mov ebx, [plusLink2]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink2], ebx
        pushad                  ;free the link in the second list
        push edx
        call free
        add esp,4
        popad
    jmp loop14

    or_only_link_1:
    loop15:
    cmp dword[plusLink1], 0
    je end_of_or  
    
    mov ebx, [plusLink1]
    movzx ebx, byte[ebx]
    mov [numHelper], ebx    
    push 5
    call malloc
    add esp, 4
    mov ebx, [numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  
    
    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    jmp loop15
    
    
    or_only_link_2:
    loop16:
    cmp dword[plusLink2], 0
    je end_of_or  
    
    mov ebx, [plusLink2]
    movzx ebx, byte[ebx]
    mov [numHelper], ebx    
    push 5
    call malloc
    add esp, 4
    mov ebx, [numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  
    mov ebx, [plusLink2]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink2], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    jmp loop16
    
    end_of_or:

    push_in_stack3:
    mov dword [helpingLink2], 0
    mov eax, [helpingLink]
    loop17:
    cmp eax, 0
    je stop_changing3
    mov ebx, [eax+1]
    mov ecx, [helpingLink2]
    mov [eax+1], ecx
    mov [helpingLink2], eax
    mov eax, ebx
    jmp loop17
    stop_changing3:
    
    mov ecx, [helpingLink2]      ;retrive the pointer to the head of the list        
    mov ebx, [stackCurrent]
    mov [ebx], ecx              ;ebx= current free place of the stack
    add dword[stackCounter],1
    add dword[stackCurrent],4 
    ret

    Insufficient_on_stack4:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret




;*****************************************************
plus:
    mov eax, [stackCounter]
    cmp eax, 2
    jl Insufficient_on_stack2       ;check if there are 2 args in the stack

    sub dword[stackCounter], 2      
    sub dword[stackCurrent], 4      ;get first arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink1], ebx
    sub dword[stackCurrent], 4      ;get secound arg
    mov ebx, [stackCurrent]
    mov ebx, [ebx]
    mov [plusLink2], ebx

    mov dword[carry], 0
    mov dword[helpingLink],0
    loop4:  
    cmp dword[plusLink1], 0
    je add_only_link_2    
    cmp dword[plusLink2], 0
    je add_only_link_1   
    mov ebx, [plusLink1]            ;check for next link
    movzx edx, byte[ebx]
    add edx, [carry]
    mov [numHelper], edx
    mov ebx, [plusLink2]
    movzx edx, byte[ebx]
    add [numHelper], edx
    cmp dword[numHelper], 255
    jle no_carry
    mov dword[carry], 1
    sub dword[numHelper], 256
    jmp after_no_carry
    
    no_carry:                   ;in case that there is no carry
    mov dword[carry],0
    after_no_carry:
    push 5
    call malloc
    add esp, 4
    movzx ebx, byte[numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  

    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    
    mov ebx, [plusLink2]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink2], ebx
        pushad                  ;free the link in the second list
        push edx
        call free
        add esp,4
        popad
    jmp loop4
  

    add_only_link_1:            ;in case that there are only links in the first list
    loop5:
    cmp dword[plusLink1], 0
    je end_of_add  
    mov ebx, [plusLink1]            ;check for next link
    movzx edx, byte[ebx]
    add edx, [carry]
    mov [numHelper], edx
    cmp dword[numHelper], 255
    jle no_carry_list_1
    mov dword[carry], 1
    sub dword[numHelper], 256
    jmp after_no_carry_list_1
    no_carry_list_1:
    mov dword[carry],0
    after_no_carry_list_1:
    push 5
    call malloc
    add esp, 4
    movzx ebx, byte[numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  
    mov ebx, [plusLink1]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink1], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    jmp loop5
    

    add_only_link_2:
    loop6:
    cmp dword[plusLink2], 0
    je end_of_add  
    mov ebx, [plusLink2]            ;check for next link
    movzx edx, byte[ebx]
    add edx, [carry]
    mov [numHelper], edx
    cmp dword[numHelper], 255
    jle no_carry_list_2
    mov dword[carry], 1
    sub dword[numHelper], 256
    jmp after_no_carry_list_2
    no_carry_list_2:
    mov dword[carry],0
    after_no_carry_list_2:
    push 5
    call malloc
    add esp, 4
    movzx ebx, byte[numHelper]
    mov byte[eax], bl
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax  
    mov ebx, [plusLink2]
    mov edx, ebx                ;for free*****
    mov ebx, [ebx+1]
    mov [plusLink2], ebx
        pushad                  ;free the link in the first list
        push edx
        call free
        add esp,4
        popad
    jmp loop6   
    
    
    end_of_add:

    cmp dword[carry],0
    je push_in_stack
    push 5
    call malloc
    add esp, 4
    mov byte[eax], 1
    mov edx, [helpingLink]
    mov dword[eax+1], edx
    mov [helpingLink], eax

    push_in_stack:
    mov dword [helpingLink2], 0
    mov eax, [helpingLink]
    loop7:
    cmp eax, 0
    je stop_changing
    mov ebx, [eax+1]
    mov ecx, [helpingLink2]
    mov [eax+1], ecx
    mov [helpingLink2], eax
    mov eax, ebx
    jmp loop7
    stop_changing:
    
    
    mov ecx, [helpingLink2]      ;retrive the pointer to the head of the list        
    mov ebx, [stackCurrent]
    mov [ebx], ecx              ;ebx= current free place of the stack
    add dword[stackCounter],1
    add dword[stackCurrent],4 
    ret

    Insufficient_on_stack2:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret

;*******************************************

print_list:         ;eax contein the list
    mov ebx, 0      ;ebx counter for the links
    loop2:
     
    cmp dword[eax+1], 0         ;check for the end of the list
    je end_of_list
    movzx ecx, byte[eax]        
    push ecx  
    inc ebx                     
    mov edx, [eax+1]
    
    pushad                      ;free the memory alocated for the link
    push eax
    call free
    add esp, 4
    popad
    mov eax, edx
    jmp loop2

    end_of_list:
    movzx ecx, byte[eax]        
    push ecx                    ;each link will be pushed to the stack
    inc ebx                     ;ebx include the num of links
    pushad                      ;free the memory alocated for the link
    push eax
    call free
    add esp, 4
    popad
        
    ;clear the string array
    mov eax, 0
    clear:
    cmp eax, 82
    je end_clear
    mov byte[array+eax],0
    inc eax
    jmp clear
    end_clear:

    mov dword[index],0               ;general index to add to the array
    loop3:                     
    cmp ebx, 0
    je end_loop3
    pop eax                     ;pop each link to eax
    cmp eax, 0
    jne not_zero
    mov ecx, [index]
    mov byte[array+ecx], '0'
    mov byte[array+ecx+1], '0'
    add dword[index],2
    sub ebx, 1
    jmp loop3

    not_zero:
    cmp eax, 15
    jle firstLink
    mov ecx, 16                 ;make eax hexadecimal by divide by 16
    cdq                         ;we can be sure that eax is at max 255
    div ecx                     ;so divid by 16 twice is enough
    cmp edx, 10					
	jl less_then_10
	add edx, 55					
	jmp after_cmp1
	less_then_10:
	add edx, 48	
    after_cmp1:				    
    mov ecx, [index]
    mov byte[array+ecx+1], dl     
    mov ecx, 16
    cdq
    div ecx
    cmp edx, 10					
	jl less_then_10_1
	add edx, 55					
	jmp after_cmp2
	less_then_10_1:
	add edx, 48	
    after_cmp2:		
    mov ecx, [index]
    mov byte[array+ecx], dl
    add dword[index],2
    sub ebx, 1
    jmp loop3
    
    firstLink:
    mov ecx, 16                 ;make eax hexadecimal by divide by 16
    cdq                         ;we can be sure that eax is at max 255
    div ecx                     ;so divid by 16 twice is enough
    cmp edx, 10					
	jl less_then_10_first_link
	add edx, 55					
	jmp after_cmp1_first_link
	less_then_10_first_link:
	add edx, 48	
    after_cmp1_first_link:
    mov ecx,[index]		
    mov byte[array+ecx+1], dl
    mov byte[array+ecx], '0'
    add dword[index],2
    sub ebx, 1
    jmp loop3
    
    end_loop3:

    mov eax,0           ;earase init 0
    loose_zero1:
    cmp byte[array+eax],0
    je make_zero
    cmp byte[array+eax],'0'
    jne print_array
    inc eax
    jmp loose_zero1    
    
    make_zero:
    mov eax,0
    mov byte[array],'0'
    mov byte[array+1],0

    print_array:
    pushad
    mov ecx, array    
    add eax, ecx

    push dword eax
    push string_format
    call printf
    add esp, 8
    popad

    end_of_print:
    
    ret

;************************************************
dup:
    mov eax, [stackCounter]
    cmp eax, 1
    jl Insufficient_on_stack6
    mov eax, [stackCounter]    ;eax= current point of the stack
    cmp eax, [stackLimit]   ;eax= max size of the stack
    je stack_oveflow1

    mov ebx, [stackCurrent]  
    sub ebx, 4
    mov eax, [ebx]
    
    mov ecx, 0
    loop8:                  ;count number of links
    cmp eax, 0
    je end_loop8
    movzx ebx, byte[eax]
    push ebx
    inc ecx
    mov eax, [eax+1]
    jmp loop8
    
    end_loop8:
    mov dword[helpingLink], 0
    loop9:
    cmp ecx,0

    je end_loop9
    mov [index], ecx    
    push 5
    call malloc
    add esp,4
    mov ecx, [index]
    pop ebx

    mov byte[eax], bl

    mov edx,[helpingLink]
    mov [eax+1], edx
    mov [helpingLink],eax
    sub ecx, 1
    jmp loop9
    end_loop9:

    mov ecx, [helpingLink]      ;retrive the pointer to the head of the list        
    mov ebx, [stackCurrent]
    mov [ebx], ecx              ;ebx= current free place of the stack
    add dword[stackCounter],1
    add dword[stackCurrent],4 
    ret

    Insufficient_on_stack6:
    push Insufficient
    push string_format
    call printf
    add esp, 8
    ret

    stack_oveflow1:      ;in case that there is no space in the stack
    push oveflow
    call printf
    add esp, 4
    ret
