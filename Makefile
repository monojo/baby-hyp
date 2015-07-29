ARMGNU = ~/tool-chain/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf

xen: baby.S
	$(ARMGNU)-gcc -D__ASSEMBLY__ -O1 -fno-omit-frame-pointer -marm -g -fno-strict-aliasing -Wall -Wstrict-prototypes -Wdeclaration-after-statement -Wno-unused-but-set-variable -Wno-unused-local-typedefs -fno-stack-protector -fno-exceptions -Wnested-externs -msoft-float -mcpu=cortex-a15 -fno-builtin -fno-common -Werror -Wredundant-decls -Wno-pointer-arith -pipe -nostdinc -fno-optimize-sibling-calls -fno-omit-frame-pointer -MMD -MF .baby.o.d -c baby.S -o baby.o
	$(ARMGNU)-ld baby.o -o baby.elf -T rammap.lds
	$(ARMGNU)-objcopy baby.elf -O binary baby

clean:
	rm baby baby.elf *.o
