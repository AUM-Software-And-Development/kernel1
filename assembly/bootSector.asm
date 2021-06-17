org 0x7c00; 1 = boot Sector

	mov cl, 2 	; Sector number
	mov ax, 0x1000  ; Location beginning which receives what's in the data sector
			call SectorFlags
			call OneSectorDiskLoad
	mov cl, 3 		
	mov ax, 0x2000   
			call SectorFlags
			call NineSectorDiskLoad
			jmp MemoryJump

SectorFlags:
	mov ch, 0 	; Cylinder number
	mov dh, 0 	; Head number 
	mov dl, 0 	; Drive number
	mov es, ax 	; Segment register
	mov bx, 0 	; Diskload requires es:bx
ret

			;;;;;;;;; int 13 opens data segment to all possible drives

OneSectorDiskLoad:			
	mov al, 1 	; Number of sectors to read
	mov ah, 2 	; Read disk interrupt argument
int 19
			jc OneSectorDiskLoad ; If error, restore al, ah and try again.
ret

NineSectorDiskLoad:
	mov al, 9	
	mov ah, 2	
int 19
			jc NineSectorDiskLoad
ret

;;;;;;;;; Jump to Kernel

MemoryJump:
	mov ax, 0x2000  ; Set registers to reference the appropriate location.
	mov ds, ax     
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
			jmp 0x2000:0 ; Go to Kernel

times 510-($-$$) db 0 ; Pads out file array with zeros up until location minus magic number.
dw 0xaa55
