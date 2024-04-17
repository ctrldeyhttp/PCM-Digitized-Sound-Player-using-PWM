bits 16
org 100h

start:
    mov ax, 0
    mov es, ax

    mov bx, 149 ; Timer divisor for approximately 8000 Hz sample rate
    call change_timer_0
    
    ; Turn on the speaker
    in al, 61h
    or al, 3
    out 61h, al

next_sample:
    ; Wait for the next timer tick
    mov dx, [es:046ch]
delay:
    cmp dx, [es:046ch]
    jz delay

    ; Play a 1 byte sample, shift right to decrease volume
    mov si, [sound_index]
    mov al, [sound_data + si]
    shr al, 1
    out 42h, al

    ; Check for keypress to exit
    mov ah, 1
    int 16h
    jnz exit
    
    ; Increment index and check bounds
    inc si
    cmp si, [sound_size]
    mov [sound_index], si
    jb next_sample

restart_sound:
    mov word [sound_index], 0
    jmp next_sample
    
exit:
    ; Turn off the speaker
    in al, 61h
    and al, 0xFC
    out 61h, al
    
    ; Restore the original 18.2Hz timer
    mov bx, 0
    call change_timer_0
    
    ; Exit to DOS
    mov ah, 4ch
    int 21h
    
change_timer_0:
    cli
    mov al, 36h  ; Command for setting square wave generator mode
    out 43h, al
    mov ax, bx
    out 40h, al  ; Low byte of divisor
    mov al, ah
    out 40h, al  ; High byte of divisor
    sti
    ret
    
sound_index dw 0
sound_size dw 65371   ; Ensure this matches your actual sound data size
sound_data:
    incbin "real.raw"
