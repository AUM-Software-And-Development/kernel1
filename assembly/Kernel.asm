;;;;;;;;; Boot message:
	mov si, StartString
			jmp Start

Header:
        mov ah, 0	; Video mode.
        mov al, 3 	; Text mode.
int 16

        mov ah, 0x0b 	; Color mode.
        mov bh, 0 	; Color/pallete.
        mov bl, 9 	; Color.
int 16

        mov ah, 0x0e 	; Teletype mode.
        mov al, 49 
int 16
skip:
			call NewLine
			call DisplayString
			call NewLine
	mov al, 48
int 16
			call NewLine
			call NewLine
	mov si, Option1
			call DisplayString
			call NewLine
	mov si, Option0
			call DisplayString
			call NewLine
	mov si, Option2
			call DisplayString
			call NewLine
	mov si, Option3
			call DisplayString
			call NewLine
	mov si, Option4
			call DisplayString
			call NewLine

	mov si, Option5
			call DisplayString
			call NewLine

	mov si, Option6
			call DisplayString
			call NewLine
			call NewLine


	mov si, OptionP
			call DisplayString
			call NewLine
			call NewLine
	
ret

Start:
			call Header ; Call the header to keep visual static.
allowinput:
	mov si, CommandPrompt
			jmp moveon
writePrompt:
	mov si, CommandPrompt
moveon:
			call DisplayString
	mov si, UserChoiceString ; Put empty string into source indexer.
	cld		; Clear the index direction flag, to autoincrement right

KeyInterrupt:
	mov ah, 0    	; Set ah for key interrupt.
int 22
	mov ah, 0x0e 	; Set ah for teletype interrupt.
	cmp al, '~'
			je writePrompt
	cmp al, 0xD  	; Check if enter key has been pressed.
			je Interpreter    ; If so, go to interpreter.
int 16               	; Else, display it.
	cmp al, 'a'
			je ApplicationSearch
	mov [si], al 	; Move return from interrupt 22 onto once empty string.
	inc si       	; Increment the index to store character until "enter".
			jmp KeyInterrupt  ; Jump back to get another key.

Interpreter:

	mov al, [UserChoiceString] ; Move only the first byte into al
	cmp al, 49
			je FileNav
	cmp al, 48
			je EndAll
	cmp al, 50
			je Restart
	cmp al, 51
			je Reboot
	cmp al, 52
			je MakeScreen
	cmp al, 53
			je KeyBinary
	cmp al, 54
			je KeyHexadecimal
			jne NotFound

KeyBinary:
			call NewLine
	mov si, EnterKeyToConvert
			call NewLine
			call DisplayString
			call NewLine
			call NewLine
	mov si, CommandPrompt
			call DisplayString
	mov si, CommandPrompt
			call DisplayString
	mov ah, 0
int 22
	mov ah, 0x0e
int 16
	mov dl, al
		call Space
	mov si, IsBitOrder
		call DisplayString
		call Space
	mov al, dl
		call BinaryConverter
		call DisplayString
		call NewLine
		call NewLine
		jmp allowinput

KeyHexadecimal:
			call NewLine
	mov si, EnterKeyToConvert
			call NewLine
			call DisplayString
			call NewLine
			call NewLine
	mov si, CommandPrompt
			call DisplayString
	mov si, CommandPrompt
			call DisplayString
	mov ah, 0
int 22
	mov ah, 0x0e
int 16
	mov dl, al
		call Space
	mov si, IsHexOrder
		call DisplayString
		call Space
	mov al, dl
		call HexadecimalDisplay
		call NewLine
		call NewLine
		jmp allowinput

FileNav:
			call NewLine
			call NewLine
	xor bx, bx
	xor cx, cx
	xor dx, dx
	mov ax, 0x1000  ; Get all file names from sector 9
	mov es, ax      ; Put starting location into segment register
	mov ah, 0x0e

startfileprintloop:
fileprintloop:
	mov al, [ES:BX] ; Start adding characters per location using bx for location index
int 16
	inc bx          ; Increment the location counter
	inc cl		; Increment the character counter
	cmp al, '~'
			je gobacktoinput
	cmp al, ':'
			je printright
			jmp fileprintloop

printright:
	mov dl, 40      ; Screen is 80 "chars" long
	sub dl, cl      ; Subtract character count from half the screen

printrightloop:
	mov al, ' '
int 16
	inc ch		; Using ch to split the difference until ch + dl = 40
	cmp ch, dl      
			jne printrightloop
			je fileprintloop

gobacktoinput:
			call NewLine
			call NewLine
			jmp allowinput

ApplicationSearch:
	mov si, UserChoiceString
	cld
	xor cl, cl

searchloop:
	mov ah, 0
int 0x16		; Get key
	mov ah, 0x0e
	cmp al, 0xd	; Check if enter
			je startsearching
	inc cl          ; Count the number of keys not "enter"
	mov [si], al    ; Move character into location referenced in si
	inc si          ; Move location referenced in si up by 1
int 0x10		; Display character in al
			jmp searchloop

startsearching:         ; Can put int 16 at top to clear screen
	mov si, UserChoiceString
	cld		; Set index direction to positive (move right)
	xor bx, bx
	xor dx, dx
	mov ax, 0x1000 	; Get all file names from sector 9
	mov es, ax     	; Put starting location into segment register
	mov ah, 0x0e  	; Teletype mode

readbyte:
	mov al, [ES:BX]	; Put first char into al
	cmp al, '~'	; Check if end of list
			je NotFound
	cmp al, [si]	; If not compare it to the first char in si
			je startcompareloop
			jne readnextLocation

readnextLocation:
	inc bp          ; Storing offset/return using Base Pointer (16 bits)
	mov bx, bp
	mov si, UserChoiceString ; Has to be moved to clear index
	cld
			jmp readbyte

startcompareloop:
	mov dl, cl	; Put user input char count into dl

compareloop:
	mov al, [ES:BX]	; Move the loation into al
	cmp al, [si]	; Check if the user input char equals that
			jne readnextLocation ; If not jump back with start of source.
	inc bx		; Move location up by 1
	inc si		; Move into next user input char
	dec dl
	cmp dl, 0
			je foundProgram ; If all characters match, program can end.
			jmp compareloop

foundProgram:		; Compiler optimizer seems to fail if this is near not found.
	dec si
	mov al, [si]
	inc si
	cmp al, '.'
			je skipfinalcheck ; Checks if user entered a closing statement manually.
	mov al, [ES:BX]
	cmp al, '.'
			jne NotFound ; Checks where it left off that file name isnt partial.
skipfinalcheck:
	mov si, RecognizedMessage
			call Space
			call DisplayString
			call NewLine
			call NewLine
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor bp, bp
	cld
			jmp allowinput

Restart:
	xor al, al
	mov [1], al
	mov si, RestartString
			call Header
			jmp allowinput

Reboot:
	xor al, al
	mov [1], al
			jmp 0xFFFF:0x0000 ; reboot vector

EndAll:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor bp, bp
	cld
cli
hlt 			; Application finished.

;;;;;;;;; Display string:
DisplayString:
	xor cl, cl
	mov ah, 0x0e 	; int 10(16) teletype.
	mov bh, 0 	; Page number.
	mov bl, 3 	; Color.

startreadloop:
readcharacterloop:
	mov al, [si]
	cmp al, '~'	; ~ Terminates.
			je endingloop
			jmp displaycharacter

endingloop:
	inc cl		; Keep track of how many "~".
	cmp cl, 9	; If 10, end displaying of characters.
			je enddisplay
	inc si		
			jmp readcharacterloop
enddisplay:
ret

displaycharacter:
int 16
	inc si
			jmp readcharacterloop

;;;;;;;;; Utility:
NewLine:
	mov ah, 0x0e
	mov al, 0xa
int 16
	mov al, 0xd
int 16
ret

Space:
	mov ah, 0x0e
	mov al, 32
int 16
ret

NotFound:		; Compiler optimizer seems to fail if this is near found.
	mov si, NotRecognizedMessage
			call Space
			call DisplayString
			call NewLine
			call NewLine
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor bp, bp
	cld
			jmp allowinput

BinaryConverter:
	mov si, Binary

b8:
	mov byte [si], '0'
	cmp byte al, 127
		jg binaryexit
		je sub127
		jl b7
sub127:
	mov byte [si], '1'
	inc si
	sub al, 127
	jz Zero ; Anything over 127 will fail.

b7:
	inc si
	mov byte [si], '0'
	cmp al, 64
		jge sub64
		jl b6
sub64:
	mov byte [si], '1'
	sub al, 64

b6:
	inc si
	mov byte [si], '0'
	cmp al, 32
		jge sub32
		jl b5
sub32:
	mov byte [si], '1'
	sub al, 32

b5:
	inc si
	mov byte [si], '0'
	cmp al, 16
		jge sub16
		jl b4
sub16:
	mov byte [si], '1'
	sub al, 16

b4:
	inc si
	mov byte [si], '0'
	cmp al, 8
		jge sub8
		jl b3
sub8:
	mov byte [si], '1'
	sub al, 8

b3:
	inc si
	mov byte [si], '0'
	cmp al, 4
		jge sub4
		jl b2
sub4:

	mov byte [si], '1'
	sub al, 4

b2:
	inc si
	mov byte [si], '0'
	cmp al, 2
		jge sub2
		jl b1
sub2:
	mov byte [si], '1'
	sub al, 2

b1:
	inc si
	mov byte [si], '0'
	cmp al, 1
		jge sub1
sub1:
	sub al, 1
	jz One
	jnz Zero
One:
	mov byte [si], '1'
Zero:
	mov si, Binary
	jmp binaryexit

binaryexit:
ret

Binary: db '00000000', '~~~~~~~~~'

HexadecimalDisplay:
; ASCII '0' - '9' = hex 0x30 - 0x39
; ASCII 'a' - 'f' = hex 0x61 - 0x66
; ASCII 'A' - 'F' = hex 0x41 - 0x46
	pusha
	mov cx, 0

startconversionloop: 	; dx is the argument register.
conversionloop:
	cmp cx, 4 	; Is loop at end?
	je endconversionloop
			; Converting
	mov ax, dx
	and ax, 0x000f  ; and 000 against final character in hex. Always makes 000+conversion.
	add al, 0x30	; Put the actual number or char up into an ASCII concurrent.
	cmp al, 0x39  	; 39 is the last number in ASCII. Anything greater is a lettered char.
	jle hexnumber
	add al, 0x7     ; 

hexnumber:
	mov bx, hexadecimal + 5 ; Base address of hex string + length of string.
	sub bx, cx	; Subtract from loop counter
	mov [bx], al
	ror dx, 4
	inc cx
			jmp conversionloop
endconversionloop:
	mov si, hexadecimal
	call DisplayString
	popa
	ret

hexadecimal: db '0x0000', '~~~~~~~~~~' 

;;;;;;;;; Graphics:
MakeScreen:
	mov ah, 0
	mov al, 0x13
int 0x10
	mov ah, 0x0c
	mov al, 0x09
	mov bh, 0x00
	mov cx, 100
	mov dx, 100
int 0x0

startdrawloop:
columnLoop:
	inc cx
int 0x10
	cmp cx, 150
			jne columnLoop

rowLoop:
	inc dx
int 0x10
	mov cx, 99
	cmp dx, 150
			jne columnLoop
			jmp allowinput

;;;;;;;;; Base programs:

;;;;;;;;; Strings:
CommandPrompt: db '...', '~~~~~~~~~'

StartString: db 'Operation successful', '~~~~~~~~~'

RestartString: db 'Sections restarted.', '~~~~~~~~~'

UserEnteringInput: db 'User entering input', '~~~~~~~~~'

EnterKeyToConvert: db 'Enter key to convert:', '~~~~~~~~~'

IsBitOrder: db 'is bit order', '~~~~~~~~~'

IsHexOrder: db 'is hex order', '~~~~~~~~~'

OptionP: db 'Using letter a                          : aApplicationName opens applications', '~~~~~~~~~'

Option1: db '1: Press 1 to access files', '~~~~~~~~~'

Option0: db '0: Press 0 to halt the program', '~~~~~~~~~'

Option2: db '2: Press 2 to restart your location', '~~~~~~~~~'

Option3: db '3: Press 3 to restart your computer', '~~~~~~~~~'

Option4: db '4: Press 4 to open graphics mode', '~~~~~~~~~'

Option5: db '5: Press 5 to convert keys to binary', '~~~~~~~~~'

Option6: db '6: Press 6 to convert keys to hexadecimal', '~~~~~~~~~'

RecognizedMessage: db 'Command recognized, but no method implemented to run it.', '~~~~~~~~~'

NotRecognizedMessage: db 'Command not recognized', '~~~~~~~~~'

Count: db 0

UserChoiceString: db ''

;;;;;;;;; End of file:
times 4608-($-$$) db 0
; 0xd carriage return ; increments cursor location.
; 0x00 video mode.
