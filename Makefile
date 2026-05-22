MODULE_MAIN_OBJ := module.o
COMMON_MODULES := utils gpio wiegand atecc
MODULE_EXTRA_OBJS := pcf2131/pcf2131.o
UDEV_RULES := 99-ionopi-v3.rules

SOURCE_DIR := $(if $(src),$(src),$(CURDIR))
include $(SOURCE_DIR)/commons/scripts/kmod-common.mk
