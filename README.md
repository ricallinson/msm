# Microkernel Service Maker

A command line tool that creates a Linux disk image from an executable file.

## Prerequisites

* [QEMU](https://www.qemu.org/)
* [Shellcheck](https://github.com/koalaman/shellcheck)

## Testing

	./test.sh

## Creating Kernel Image

	qemu-img create -f raw ./images/core-9.0.img 50M
	qemu-system-x86_64 -m 512 -hda ./images/core-9.0.img -cdrom ./images/TinyCore-9.0.iso -boot d

Boot into the first option and then install __tc-install-GUI__. Execute it via the command line with `tc-install` and select;

* Frugal
* Whole Disk
* sda
* Install boot loader

Click the next arrow then select;

* vfat

Click the next arrow.

Click the next arrow then select;

* Don't install extensions

Click the next arrow and select;

* Proceed

On completion exit QEMU. Now start a new VM with the image just created;

	qemu-system-x86_64 -m 512 -hda ./images/core-9.0.img
