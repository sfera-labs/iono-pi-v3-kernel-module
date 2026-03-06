obj-m += ionopi-v3.o

ionopi-v3-objs := module.o
ionopi-v3-objs += commons/commons.o
ionopi-v3-objs += gpio/gpio.o
ionopi-v3-objs += wiegand/wiegand.o
ionopi-v3-objs += atecc/atecc.o
ionopi-v3-objs += pcf2131/pcf2131.o

all:
	make -C /lib/modules/$(shell uname -r)/build/ M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build/ M=$(PWD) clean

install:
	sudo install -m 644 -c ionopi-v3.ko /lib/modules/$(shell uname -r)
	sudo depmod
