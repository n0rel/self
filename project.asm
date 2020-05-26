; Norel Glick's Portal Snake coded in 86x assembly.
; Project was made as the 30% of my Bagrut in Computer Science
; Teacher: Inon Barnea


IDEAL
MODEL small
STACK 1000h
DATASEG
; var for delay
Clock equ es:6Ch

; score text
endText db "YOU DIED$"
endText2 db " Apples Eaten$"
endText3 db "Press 1 to Exit Game$"

; score var
score dw 0

; displayedScore
displayedScore dw 0
scoreDisplayed dw 0

; X and Y for printing dots
x dw 0
y dw 0

; Color for printing dots
color db 15

; variable for storing the direction the snake is looking
direction db 0 ; [0] -> North, [1] -> East, [2] -> South, [3] -> West 

; variable for storing the snakes length
snakeLength dw 1

; array that will hold apple coords
appleX dw 0
appleY dw 0

; boolean to check if we continue looping infinitely or stop
continue db 0

; placeholders for code
snakeHeadX dw 0
snakeHeadY dw 0

; vars for the random number generator
randX dw 0
randY dw 70

; temp variables to store numbers for loops without using CX
temp dw 0
headX dw 0
headY dw 0

; collision boolean
colliding db 1

; bool to know what random to do
randBool db 0

CODESEG


;							-= [Random] Function =-
proc random
;------------------------------------------------------------------------

	;"""
	; Generates a number based on current clock time
	; Taken from: Ori Shamir
	;"""
	
	push ax
	push dx
	push cx
	
	; RANDOM X VALUE
	mov ah, 2Ch
	int 21h

   ; dl = millisec
   ; dh = sec
   xor dl, dh
   
   xor ax, ax ; clear
   mov al, dl
	
	xor dx, dx
	
	cmp [randBool], 0
	je randomX
	
	randomY:
		mov  cx, 199
		inc cx
		div  cx       ; here dx contains the remainder of the division - from 0 to 2
		add dx, 31
		mov [randY], dx
		mov [randBool], 0
		jmp finishRandom
	
	randomX:
		mov  cx, 299
		inc cx
		div  cx       ; here dx contains the remainder of the division - from 0 to 2
		add dx, 21
		mov [randX], dx
		mov [randBool], 1
	
	finishRandom:
		pop cx
		pop dx
		pop ax
;------------------------------------------------------------------------
ret
endp random


;							-= [Delay] function =-
proc delay
;------------------------------------------------------------------------

	;"""
	; Delay function creates a small delay. 
	; Taken from: Yanir Shmulevitz
	;"""

	push ax
	mov ax, 40h
	mov es, ax
	mov ax, [Clock]
	FirstTick:
		cmp ax, [Clock]
		mov cx, 1
	DelayLoop:
		mov ax, [Clock]
	Tick:
		cmp ax, [Clock]
		je Tick
	
	loop DelayLoop
	pop ax
;------------------------------------------------------------------------
ret
endp delay


;							-= [Round] function =-
proc round
;------------------------------------------------------------------------
	;"""
	; The round function will be executed in a loop, to act as the games core
	; This function is what holds all other functions together.
	; From here, we call all the collisions, inputs, delays and handle the snake
	;"""
	
	; Delay
	call delay

	; Get input
	call random ; this will generate a random number
	call input
	
	; Move
	call move
	
	; Collision
	call appleCollision
	call borderCollision
	call snakeCollision
	
	; Draw Screen
	call drawBorder
	call printScore
	call drawApple
	call drawSnake
	
;------------------------------------------------------------------------
	ret
endp round


;							-= [Move] Function =-
proc move
;------------------------------------------------------------------------
	;"""
	; The Move function moves the snakes body.
	; This will be achieved by going into the stack and switching the coords of each block untill we reach the head.
	; The head will be moved in the direction the user is currently looking
	;"""
	
	push ax
	push bx
	push cx
	push dx
	push bp
	
	mov bp, sp
	
	; turn the last snake part into black (erase it)
	mov ax, [bp+14] ; y value of last part
	mov [y], ax
	
	mov ax, [bp+16] ; x value of last part
	mov [x], ax
	
	; draw the black dot
	mov [color], 0
	dec [y]
	dec [x]
	call drawSnakePart
	mov [color], 2
	
	mov ax, [snakeLength]
	; if the only part we have is the head, jump to MoveSnakeHead
	cmp ax, 1
	je MoveSnakeHead
	
	dec ax
	
	mov cx, ax ; the loop counter will be the snakeLength-1 (length minus the head)
	
	MoveSnake:
		mov ax, [bp+18] ; get the y value of the second to last snake part

		mov bx, [bp+20] ; get the x value
		
		; update the values of the part after
		
		mov [bp+14], ax ; set the y value
		mov [bp+16], bx ; set the x value
		
		add bp, 4; add 4 so that we jump to the next part
		loop MoveSnake
		
	MoveSnakeHead:
		; reset bp
		mov bp, sp
	
		;multiply snakeLength by 4
		mov ax, [snakeLength]
		push cx
		mov cx, 4
		mul cx
		pop cx
		
		add bp, ax ; add the answer of snakeLength*4 to bp
		sub bp, 2 ; delete 2
		
	
		cmp [direction], 0
		je moveN
		
		cmp [direction], 1
		je moveE
		
		cmp [direction], 2
		je moveS
		
		cmp [direction], 3
		je moveW

		moveN:
			
			; The North is up, so we decrease the Y value of the head by 1
			mov ax, [bp+12] ; snake head's Y
			sub ax, 3
			;dec ax
			mov [bp+12], ax ; set it back
			jmp endMove
			
		moveE:
			; The East is right, so we increase the X value of the head by 1
			mov ax, [bp+14] ; snake head's X
			add ax, 3
			;inc ax
			mov [bp+14], ax ; set it back
			jmp endMove
			
		moveS:
			; The South is down, so we increase the Y value of the head by 1
			mov ax, [bp+12] ; snake head's Y
			add ax, 3
			;inc ax
			mov [bp+12], ax ; set it back
			jmp endMove
			
		moveW:
			; The West is left, so we decrease the X value of the head by 1
			mov ax, [bp+14] ; snake head's X
			sub ax, 3
			;dec ax
			mov [bp+14], ax ; set it back
	
	endMove:
		pop bp
		pop dx
		pop cx
		pop bx
		pop ax
;------------------------------------------------------------------------
ret
endp move


;							-= [Apple Collision] Function =-
proc appleCollision
;------------------------------------------------------------------------

	;"""
	; Uses the snakeAppleCollision function to check if a collision has occured
	; If occured, we increase the score and snake length
	; This function also spawns an apple if there is no apple currently
	;"""

	; check if apple is eaten
	push ax
	push bx
	
	; CHECK IF APPLE EXISTS. IF IT DOESNT, SPAWN ONE IN
	cmp [appleX], 0 ; x coord is 0
	jne appleExists

	cmp [appleY], 0 ; y coord is 0
	je spawnApple ; if both x and y coords are 0, apple does not exist (eaten)
	jmp appleExists
		
	spawnApple:
		; random coords (for now it will be [75, 75]		
		mov ax, [randX]
		mov [appleX], ax
		
		
		mov ax, [randY]
		mov [appleY], ax
		
		
		call drawApple
		jmp notColliding
	
	appleExists:
		; check if head is colliding with the apple coord
		; apple head is (snakeLength)*2 + 8 in stack
		mov bp, sp
		
		;multiply snakeLength by 2
		mov ax, [snakeLength]
		push cx
		mov cx, 4
		mul cx
		pop cx
		
		add bp, ax ; add the answer of snakeLength*2 to bp	
		sub bp, 2		
		
		mov ax, [bp+6] ; snake head Y (middle)
		mov bx, [bp+8] ; snake head X (middle)
		
		dec ax
		dec bx

		mov [snakeHeadY], ax
		mov [snakeHeadX], bx
	
		call snakeAppleCollision

		cmp [colliding], 0
		jne notColliding

		detectedCollision:
		
			; delete apple coords
			mov [appleX], 0
			mov [appleY], 0

			; increase score
			add [score], 1
			
			; add snake part
			
			mov bp, sp ; reset bp

			mov ax, [bp+6] ; last snake part Y
			mov bx, [bp+8] ; last snake part X
			
			; depending on the direction of where the snake head is going, we need to add the part differently.
			; to do this, we will check a few things with the last snake part and the one after it it
			
			cmp ax, [bp+10] ; compare the last snake part Y and second to last snake part Y
			je YisEqual ; the Y's are parralel 
			
			; else the X's are parralel
			; if the X is parralel we have to check if the last part is greater or smaller
			
			cmp bx, [bp+12] ; compare last part X and second to last part X
			JC lastPartIsSmallerX ; if last part is smaller
			
			; second to last part is smaller
			add bx, 3
			jmp after
			
			lastPartIsSmallerX:
				sub bx, 3
				jmp after
				
			YisEqual:
				cmp ax, [bp+10] ; compare last part Y and second to last part Y
				JC lastPartIsSmallerY
				
				add ax, 3
				jmp after
				
				lastPartIsSmallerY:
					sub ax, 3
					jmp after
			
	after:
		
		mov [snakeHeadX], bx
		mov [snakeHeadY], ax
		
		; pop all things so that we can store the snake part
		pop bx
		pop ax
		
		pop cx ; pop procedure value into cx
		pop dx ; pop other procedure value into dx
		
		push [snakeHeadX]
		push [snakeHeadY]

		inc [snakeLength]
		
		push dx
		push cx
		
		jmp ecksdee
		
	notColliding:
		pop bx
		pop ax
	
	ecksdee:
;------------------------------------------------------------------------
ret
endp appleCollision

;							-= [Snake Collision] Function =-
proc snakeCollision
;------------------------------------------------------------------------

	;"""
	; Checks if the current snake head is colliding with any of the snakes body parts
	;"""

	push ax
	push bx
	
	; check if head is colliding with itself
	; snake head is (snakeLength)*2 + 8 in stack
	mov bp, sp
	
	;multiply snakeLength by 2
	mov ax, [snakeLength]
	push cx
	mov cx, 4
	mul cx
	pop cx
	
	add bp, ax ; add the answer of snakeLength*2 to bp
	sub bp, 2

	mov ax, [bp+6] ; snake head Y
	mov bx, [bp+8] ; snake head X
	
	push cx
	mov cx, [snakeLength]
	dec cx
	
	mov bp, sp
	
	checkSnakeCollision:
		cmp [bp+10], ax ; compare snake part and snake head Y
		jne noSnakeCollisionYet
		
		cmp [bp+12], bx ; compare snake part and snake head X
		je snakeCollided
		
	noSnakeCollisionYet:
		add bp, 4
		loop checkSnakeCollision
		jmp didNotSnakeCollide
		
	snakeCollided:
		mov [continue], 1
	
	didNotSnakeCollide:
		pop cx
		pop bx
		pop ax
;------------------------------------------------------------------------
ret
endp snakeCollision


;							-= [Border Collision] Function =-
proc borderCollision
;------------------------------------------------------------------------

	;"""
	; Checks for collision with the play area border and teleports the snake head
	; For example, if we collide with the northern border our head will teleport to the southern border, in the same X
	;"""

	push ax
	push bx
	
	; check if head is colliding with the apple coord
	; snake head is (snakeLength)*2 + 8 in stack
	mov bp, sp
	
	;multiply snakeLength by 2
	mov ax, [snakeLength]
	push cx
	mov cx, 4
	mul cx
	pop cx
	
	add bp, ax ; add the answer of snakeLength*2 to bp

	sub bp, 2

	mov ax, [bp+6] ; snake head Y
	mov bx, [bp+8] ; snake head X
	
	; northern border (20, 30) - (300, 30)
	cmp ax, 30
	jle northernBorder
	
	; eastern border (300, 30) - (300, 180)
	cmp bx, 300
	jge easternBorder
	
	; southern border (20, 180) - (200, 180)
	cmp ax, 179
	jge southernBorder
	
	; western border (20, 30) - (20, 180)
	cmp bx, 20
	jle westernBorder
	jmp finishBorderCollide
	
	northernBorder:
		mov [word ptr bp+6], 177 ; set the Y of the head to the bottom of the play area
		jmp finishBorderCollide
	
	easternBorder:
		mov [word ptr bp+8], 22 ; set the X of the head to the left of the play area
		jmp finishBorderCollide
		
	southernBorder:
		mov [word ptr bp+6], 32 ; set the Y of the head to the top of the play area
		jmp finishBorderCollide
		
	westernBorder:
		mov [word ptr bp+8], 298 ; set the X of the head to the right of the play area
		
	finishBorderCollide:
		pop bx
		pop ax
;------------------------------------------------------------------------
ret
endp borderCollision


;							-= [Snake Apple Collision] Function =-
proc snakeAppleCollision
;------------------------------------------------------------------------

	;"""
	; Checks if the current snake head is colliding with the current apple
	;"""

	push ax
	push bx
	
	mov ax, [snakeHeadY]
	mov bx, [snakeHeadX]
	
	collisionNorth:
		cmp ax, [appleY]
		jne collisionEast
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		;jmp noCollision
	
	collisionEast:
		
		mov bx, [snakeHeadX]
		inc ax
		;cmp bx, [appleX]
		;jne noCollision
		
		cmp ax, [appleY]
		jne collisionSouth
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		;jmp noCollision
		
	collisionSouth:
		;add ax, 2
		
		mov bx, [snakeHeadX]
		inc ax
		
		cmp ax, [appleY]
		jne noCollision
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		
		inc bx
		
		cmp bx, [appleX]
		je collisionFound
		jmp noCollision
		
	noCollision:
		mov [colliding], 1	
		jmp finish
	
	collisionFound:
		mov [colliding], 0
	
	finish:
		pop bx
		pop ax
;------------------------------------------------------------------------
ret
endp snakeAppleCollision


;							-= [Input] Function =-
proc input
;------------------------------------------------------------------------

	;"""
	; Checks for user input and changes direction
	;"""
	
	in al, 64h
	cmp al, 10b
	in al, 60h
	
	cmp al, 11h ; Compare to W key
	je changeN
	cmp al, 1Eh ; Compare A key
	je changeW
	cmp al, 1Fh ; Compare S key
	je changeS
	cmp al, 20h ; Compare D key
	je changeE
	
	jmp finishedInput
	
	changeN:
		mov [direction], 0 ; change direction to north
		jmp finishedInput
		
	changeW:
		mov [direction], 3 ; change direction to west
		jmp finishedInput

	changeS:
		mov [direction], 2 ; change direction to south
		jmp finishedInput
	changeE:
		mov [direction], 1 ; change direction to east
		jmp finishedInput

finishedInput:
;------------------------------------------------------------------------
ret
endp input


;							-= [Draw Apple] Function =-
proc drawApple
;------------------------------------------------------------------------

	;"""
	; Uses the [X] and [Y] variables to draw the apple (1 pixel)
	;"""

	push ax
	push bx

	mov ax, [appleX]
	mov bx, [appleY]

	mov [x], ax
	mov [y], bx

	mov [color], 4

	call drawDot

	pop bx
	pop ax
;------------------------------------------------------------------------
ret
endp drawApple


;							-= [Draw Snake] Function =-
proc drawSnake
;------------------------------------------------------------------------

	;"""
	; Draws the current snake part positions onto the screen
	;"""

	push cx
	push ax
	push dx
		
	; Since we pushed 3 things, the snake's position is pushed up by 6
	
	; change color to green
	mov [color], 2
	
	mov cx, [snakeLength]
	mov bp, sp


	DrawPart:
		; get the y value
		mov ax, [bp+10]
		mov [y], ax
		
		; get the x value
		mov ax, [bp+12]
		mov [x], ax

		dec [x]
		dec [y]
		
		call drawSnakePart

		add bp, 4
		loop DrawPart
	
	; change color back to white
	mov [color], 15
	
	pop dx
	pop ax
	pop cx
;------------------------------------------------------------------------
	ret
endp drawSnake


;							-= [Draw Snake Part] Function =-
proc drawSnakePart
;------------------------------------------------------------------------

	;"""
	; Draws one snake part (3x3 cube) where [X] and [Y] are
	;"""

	push ax
	push bx
	push dx
	
	mov dx, [x]
	
	mov ax, [x]
	add ax, 3
	
	mov bx, [y]
	add bx, 3

	draw_row:
		cmp [x], ax
		; if x == AX: the row is finished.
		je finished_row
		; else: we need to keep drawing		
		call drawDot
		inc [x]		
		jmp draw_row
	
	finished_row:
		; compare and check if y == 50
        cmp [y], bx
        je finished_square

		; else
		mov [x], dx
		inc [y]
		jmp draw_row

	finished_square:
		mov [x], 0
		mov [y], 0
		
		pop dx
		pop bx
		pop ax
;------------------------------------------------------------------------
ret
endp drawSnakePart


;							-= [Print Score] Function =-
proc printScore
;------------------------------------------------------------------------

	;"""
	; Prints the current score (apples eaten)
	;"""

	push ax
	push dx
	push cx
	push bx
	
	; Set cursor position	
	mov dh, 2
	mov dl, 19
	mov bh, 0
	mov ah, 2
	int 10h	
		
	printTheScore:
		; print current score (numbers)
		mov ax, [score]
		; CODE TAKEN FROM: @sidon (stackoverflow)
		; Link: https://stackoverflow.com/questions/4244624/print-integer-to-console-in-x86-assembly
		; -------------------------------------------------------------------------------------------------
		
		mov cx, 0
		mov bx, 10
		loophere:
			mov dx, 0
			div bx                          ;divide by ten

			; now ax <-- ax/10
			;     dx <-- ax % 10

			; print dx
			; this is one digit, which we have to convert to ASCII
			; the print routine uses dx and ax, so let's push ax
			; onto the stack. we clear dx at the beginning of the
			; loop anyway, so we don't care if we much around with it

			push ax
			add dl, '0'                     ;convert dl to ascii

			pop ax                          ;restore ax
			push dx                         ;digits are in reversed order, must use stack
			inc cx                          ;remember how many digits we pushed to stack
			cmp ax, 0                       ;if ax is zero, we can quit
			jnz loophere

		;cx is already set
		mov ah, 2                       ;2 is the function number of output char in the DOS Services.
		loophere2:
			pop dx                          ;restore digits from last to first
			int 21h                         ;calls DOS Services
			loop loophere2
			
		; -------------------------------------------------------------------------------------------------
	
	pop bx
	pop cx
	pop dx
	pop ax
;------------------------------------------------------------------------
ret
endp printScore

;							-= [Draw Border] Function =-
proc drawBorder
;------------------------------------------------------------------------

	;"""
	; Draws the play area border
	;"""

	mov [color], 15

	; Draw the left side
	mov cx, 150
	mov [x], 20
	mov [y], 30
	
	DrawLeft:
		call drawDot
		inc [y]
		loop DrawLeft
		
	; Draw the right side
	mov cx, 150
	mov [x], 300
	mov [y], 30
	
	DrawRight:
		call drawDot
		inc [y]
		loop DrawRight
		
	; Draw the top
	mov cx, 280
	mov [x], 20
	mov [y], 30
	
	DrawTop:
		call drawDot
		inc [x]
		loop DrawTop
	
	; Draw the bottom
	mov cx, 280
	mov [x], 20
	mov [y], 180
	
	DrawBottom:
		call drawDot
		inc [x]
		loop DrawBottom	
;------------------------------------------------------------------------
ret
endp drawBorder

;							-= [Print Game Over Screen] Function =-
proc printGameOverScreen
;------------------------------------------------------------------------

	;"""
	; When the player dies, we print the game over screen
	;"""

	push dx
	push ax
	push bx
	push cx

	; reset screen (draw a black cube all over the screen)
	; code taken from @YonBruchim (Stack Overflow)
	; https://stackoverflow.com/questions/23723904/how-to-draw-a-square-int-10h-using-loops
	;===================================
	mov cx, 0  ;col
	mov dx, 0  ;row
	mov al, 0
	mov ah, 0ch ; put pixel

	colcount:
	inc cx
	int 10h
	cmp cx, 320
	JNE colcount

	mov cx, 0  ; reset to start of col
	inc dx      ;next row
	cmp dx, 200
	JNE colcount
	;===================================

	; move cursor to  (15, 7) and print "YOU DIED"
	mov dh, 7
	mov dl, 15
	mov bh, 0
	mov ah, 2
	int 10h
	
	mov ah, 09
	mov dx, offset endText ;"YOU DIED$"
	int 21h
	
	xor dx, dx
	xor bx, bx
	xor ax, ax
	
	; more cursor to (12, 10) and print "X Apples Eaten"
	mov dh, 10
	mov dl, 12
	mov bh, 0
	mov ah, 2
	int 10h

	; print current score (numbers)
	mov ax, [score]
	; CODE TAKEN FROM: @sidon (stackoverflow)
	; Link: https://stackoverflow.com/questions/4244624/print-integer-to-console-in-x86-assembly
	;===================================================================================================
	
	mov cx, 0
	mov bx, 10
	loophereSECOND:
		mov dx, 0
		div bx                          ;divide by ten

		; now ax <-- ax/10
		;     dx <-- ax % 10

		; print dx
		; this is one digit, which we have to convert to ASCII
		; the print routine uses dx and ax, so let's push ax
		; onto the stack. we clear dx at the beginning of the
		; loop anyway, so we don't care if we much around with it

		push ax
		add dl, '0'                     ;convert dl to ascii

		pop ax                          ;restore ax
		push dx                         ;digits are in reversed order, must use stack
		inc cx                          ;remember how many digits we pushed to stack
		cmp ax, 0                       ;if ax is zero, we can quit
		jnz loophereSECOND

	;cx is already set
	mov ah, 2                       ;2 is the function number of output char in the DOS Services.
	loophere2SECOND:
		pop dx                          ;restore digits from last to first
		int 21h                         ;calls DOS Services
		loop loophere2SECOND
		
	;===================================================================================================

	mov ah, 09
	mov dx, offset endText2 ;" Apples Eaten$"
	int 21h

	xor dx, dx
	xor bx, bx
	xor ax, ax

	; more cursor to (9, 17) and print "press 1 to exit"
	mov dh, 13
	mov dl, 10
	mov bh, 0
	mov ah, 2
	int 10h
	
	mov ah, 09
	mov dx, offset endText3
	int 21h

	; wait for key
	waitForKey:
		in al, 64h
		cmp al, 10b
		je waitForKey
		
		in al, 60h
		
		cmp al, 2h ; Compare to 1 key
		jne waitForKey	
	
	pop cx
	pop bx
	pop ax
	pop dx
;------------------------------------------------------------------------
ret
endp printGameOverScreen



;							-= [Draw Dot] Function =-
proc drawDot
;------------------------------------------------------------------------

	;"""
	; Draws one dot where [X] and [Y] are with the color [color]
	;"""

	; Push all the registers we use during the draw process
	push bx
	push cx
	push dx
	push ax
	
	; draw the dot
	mov bh, 0h
	mov cx, [x]
	mov dx, [y]
	mov al, [color]
	mov ah, 0ch
	int 10h
	
	; Pop all the registers we used
	pop ax
	pop dx
	pop cx
	pop bx
;------------------------------------------------------------------------
ret
endp drawDot


;							-= MAIN FUNCTION =-
start:
;------------------------------------------------------------------------

	;"""
	; The main function sets up the start of the game.
	; We set the snake position, draw the border and score.
	; Then, an infinite loop that continues to call the @round function runs. 
	; The loop constantly compares our [continue] variable to check if the player has lost
	; If a loose occurs, we display the game over screen
	;"""
	
	mov ax,@data
	mov ds,ax
	
	; Go into graphic mode
	mov ax, 13h
	int 10h
	
	; Set the snake body starting position by pushing into stack
	; snake head
	mov ax, 160
	push ax
	mov ax, 100
	push ax
	
	; Second snake part
	mov ax, 160
	push ax
	mov ax, 101
	push ax
	
	; third part
	mov ax, 160
	push ax
	mov ax, 102
	push ax
	
	; fourth part
	mov ax, 160
	push ax
	mov ax, 103
	push ax
	
	mov [snakeLength], 4
	
	; Draw border and score
	call drawBorder
	call printScore
	
	; infinite loop
	RoundLoop:
		; Call round proc
		call round
		; check if lost
		cmp [continue], 0
		je RoundLoop
		
	call printGameOverScreen
	
	; exit graphic mode
	mov ah, 0
	mov al, 2
	int 10h
;------------------------------------------------------------------------

exit:
	mov ax,4c00h
	int 21h
	End start
