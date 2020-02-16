bits 16
org 0x100

section .text
    jmp _start 
    nop 

%define upArrow    0x4800
%define downArrow  0x5000
%define leftArrow  0x4B00
%define rightArrow 0x4D00

%define still 0x00
%define up    0x01
%define down  0x02
%define left  0x03
%define right 0x04

%define key_w 0x1177
%define key_a 0x1E61 
%define key_s 0x1F73
%define key_d 0x2064

%macro print 1
    push ax
    push si
    mov si, %1
    mov ah, 0x0E
.L1:
    lodsb
    or al, al 
    jz .end 
    int 0x10
    jmp .L1
.end:
    pop si 
    pop ax
%endmacro

%macro printChar 1
    push ax
    mov al, %1
    mov ah, 0x0E
    int 0x10
    pop ax
%endmacro

%macro moveCursor 2
    push ax 
    push bx 
    push dx
    mov dl, %1
    mov dh, %2
    xor bh, bh 
    mov ah, 0x02
    int 0x10
    pop dx 
    pop bx 
    pop ax 
%endmacro

delay:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x00 
    int 0x1A
    add bx, dx 
.tloop:
    mov ah, 0x00
    int 0x1A
    cmp dx, bx 
    jg .tloop2 
    jmp .tloop 
.tloop2:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear:
    mov ah, 0
    mov al, 3
    int 0x10        
    ret

clearkeyboardbuffer:
    mov ah, 0x0C
    mov al, 0
    int 0x21
    ret 

_start:
    call init 
    jmp mainGameLoop

_finish:
    mov ax, 0x4C00
    int 0x21

mainGameLoop:
    call clear
    call draw
    xor dx, dx 
    xor bx, bx
    call delay
    call input
    call update
    mov al, [gameOver]
    test al, al 
    jnz _finish
    jz mainGameLoop

init:
    xor ax, ax 
    xor bx, bx 
    xor cx, cx
    xor dx, dx 
    xor si, si 
    xor di, di 
    mov byte [gameOver], 0
    mov byte [playerX], 1
    mov byte [playerY], 10
    mov byte [playerDirection], still
    mov byte [isFiringBullet], 0
    mov cx, 10
    xor bx, bx
.initializeBulletsX:
    mov byte [bulletsX + bx], 0x50
    inc bx 
    loop .initializeBulletsX
    mov cx, 10 
    xor bx, bx 
.initializeBulletsY:
    mov byte [bulletsY + bx], 0x50
    inc bx 
    loop .initializeBulletsY 
    ret 

draw: 
    moveCursor [playerX], [playerY]
    printChar 0x02
    
    mov cx, 10
    xor bx, bx
.printBullets:
    mov al, [isIndividualBulletBeingFired + bx]
    test al, al 
    jz .skip
    moveCursor[bulletsX+bx], [bulletsY+bx]
    printChar '*'
.skip:
    inc bx
    loop .printBullets
    moveCursor 0, 0
    ret

input:
    mov ah, 0x01
    int 0x16
    cmp ax, upArrow
    je .up_pressed
    cmp ax, downArrow
    je .down_pressed
    cmp ax, leftArrow
    je .left_pressed
    cmp ax, rightArrow
    je .right_pressed
    cmp ax, key_w
    je .w_pressed
    cmp ax, key_a 
    je .a_pressed
    cmp ax, key_s 
    je .s_pressed
    cmp ax, key_d 
    je .d_pressed 
    jmp .checkForOtherKeys
.up_pressed:
    call clearkeyboardbuffer
    mov byte[playerDirection], up
    jmp .end
.down_pressed:
    call clearkeyboardbuffer
    mov byte[playerDirection], down 
    jmp .end 
.left_pressed:
    call clearkeyboardbuffer
    mov byte[playerDirection], left
    jmp .end
.right_pressed:
    call clearkeyboardbuffer
    mov byte[playerDirection], right 
    jmp .end 
.w_pressed:
    call clearkeyboardbuffer
    mov byte [isFiringBullet], 1
    mov byte [bulletFiringDirection], up 
    jmp .end 
.a_pressed:
    call clearkeyboardbuffer
    mov byte [isFiringBullet], 1
    mov byte [bulletFiringDirection], left
    jmp .end 
.s_pressed:
    call clearkeyboardbuffer
    mov byte [isFiringBullet], 1
    mov byte [bulletFiringDirection], down 
    jmp .end 
.d_pressed:
    call clearkeyboardbuffer
    mov byte[isFiringBullet], 1
    mov byte [bulletFiringDirection], right
    jmp .end
.checkForOtherKeys:
    mov byte [playerDirection], still
    test ax, ax 
    jz .end 
    call clearkeyboardbuffer
.end:
    ret 

update:
    nop
.movePlayer:
    mov al, [playerDirection]
    cmp al, up 
    je .moveUp
    cmp al, down 
    je .moveDown
    cmp al, left 
    je .moveLeft
    cmp al, right 
    je .moveRight
    jmp .finishMovePlayer
.moveUp:
    dec byte[playerY]
    jmp .finishMovePlayer
.moveDown:
    inc byte[playerY]
    jmp .finishMovePlayer
.moveLeft:
    dec byte[playerX]
    jmp .finishMovePlayer
.moveRight:
    inc byte[playerX]
.finishMovePlayer:
    nop
.checkForBullet:
    mov al, [isFiringBullet]
    test al, al 
    jnz .fireBullet
    jmp .finishFireBullet
.fireBullet:
    mov al, [numberOfBulletsBeingFired]
    cmp al, 10
    jle .thereAreLessThanElevenBullets
    jmp .finishFireBullet
.thereAreLessThanElevenBullets:
    test al, al 
    jz .skipIncrementingBulletCount
    inc byte [numberOfBulletsBeingFired]
.skipIncrementingBulletCount:
    mov bx, [numberOfBulletsBeingFired]
    mov byte [isIndividualBulletBeingFired + bx], 1
    mov al, [bulletFiringDirection]
    cmp al, up
    je .fire_bullet_up
    cmp al, down 
    je .fire_bullet_down
    cmp al, left 
    je .fire_bullet_left 
    cmp al, right 
    je .fire_bullet_right 
    jmp .finishFireBullet
.fire_bullet_up:
    mov byte [individualBulletDirections + bx], up
    mov al, [playerX]
    mov byte [bulletsX + bx], al
    mov al, [playerY]
    mov byte [bulletsY + bx], al
    dec byte [bulletsY + bx]
    jmp .finishFireBullet 
.fire_bullet_down:
    mov byte [individualBulletDirections + bx], down
    mov al, [playerX]
    mov byte [bulletsX + bx], al
    mov al, [playerY]
    mov byte [bulletsY + bx], al
    inc byte [bulletsY + bx]
    jmp .finishFireBullet
.fire_bullet_left:
    mov byte [individualBulletDirections + bx], left 
    mov al, [playerX]
    mov byte [bulletsX + bx], al 
    mov al, [playerY]
    mov byte [bulletsY + bx], al 
    dec byte [bulletsX + bx]
    jmp .finishFireBullet
.fire_bullet_right:
    mov byte [individualBulletDirections + bx], right
    mov al, [playerX]
    mov byte [bulletsX + bx], al 
    mov al, [playerY]
    mov byte [bulletsY + bx], al 
    inc byte [bulletsX + bx]
.finishFireBullet:
    mov byte [isFiringBullet], 0
    mov al, [numberOfBulletsBeingFired]
    test al, al 
    jnz .firingBulletComplete
    inc byte [numberOfBulletsBeingFired]
.firingBulletComplete:
    nop
.moveBullets:
    mov cx, 10 
    xor bx, bx 
.moveBulletsLoop:
    mov al, [isIndividualBulletBeingFired + bx]
    test al, al 
    jz .finishMovingBullet
    mov al, [individualBulletDirections + bx]
    cmp al, up 
    je .moveBulletUp
    cmp al, down 
    je .moveBulletDown
    cmp al, left 
    je .moveBulletLeft 
    cmp al, right 
    je .moveBulletRight
    jmp .finishMovingBullet
.moveBulletUp:
    dec byte[bulletsY + bx]
    mov al, [bulletsY + bx]
    cmp al, 1
    jg .finishMovingBullet
    mov byte [isIndividualBulletBeingFired + bx], 0
    dec byte [numberOfBulletsBeingFired]
    jmp .finishMovingBullet
.moveBulletDown:
    inc byte[bulletsY + bx]
    mov al, [bulletsY + bx]
    cmp al, 24 
    jl .finishMovingBullet
    mov byte [isIndividualBulletBeingFired + bx], 0 
    dec byte [numberOfBulletsBeingFired]
    jmp .finishMovingBullet
.moveBulletLeft:
    dec byte[bulletsX + bx]
    mov al, [bulletsX + bx]
    cmp al, 1
    jg .finishMovingBullet
    mov byte [isIndividualBulletBeingFired + bx], 0
    dec byte [numberOfBulletsBeingFired]
    jmp .finishMovingBullet
.moveBulletRight:
    inc byte[bulletsX + bx]    
    mov al, [bulletsX + bx]
    cmp al, 79
    jl .finishMovingBullet
    mov byte [isIndividualBulletBeingFired + bx], 0
    dec byte [numberOfBulletsBeingFired]
.finishMovingBullet:
    inc bx 
    loop .moveBulletsLoop    
.end:
    ret
section .data

section .bss

gameOver: resb 1
playerX: resb 1
playerY: resb 1

playerDirection: resb 1  

isFiringBullet: resb 1

bulletFiringDirection: resb 1

bulletsX: resb 10
bulletsY: resb 10

isIndividualBulletBeingFired: resb 10
individualBulletDirections: resb 10

numberOfBulletsBeingFired: resb 1

enemiesX: resb 15
enemiesY: resb 15