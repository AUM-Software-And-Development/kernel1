# Location Home/programming/

# Operates fasm on asm
bootSector.bin:
	fasm ../assembly/bootSector.asm
	mv ../assembly/bootSector.bin ./

# Operates fasm on asm
FileTable.bin:
	fasm ../assembly/FileTable.asm
	mv ../assembly/FileTable.bin ./

# Operates fasm on asm
Kernel.bin:
	fasm ../assembly/Kernel.asm
	mv ../assembly/Kernel.bin ./

# Concatenates asm binary files
os: bootSector.bin FileTable.bin Kernel.bin
	cat bootSector.bin FileTable.bin Kernel.bin > OS.bin
	qemu-system-i386 -fda OS.bin 

OS:
	rm -f *.bin
	make os

clean:
	rm *.bin
