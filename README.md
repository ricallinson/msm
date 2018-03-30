# Microkernel Service Maker

A command line tool that creates a Linux disk image with an executable automatically loaded.

## Prerequisites

* [QEMU](https://www.qemu.org/)
* [Shellcheck](https://github.com/koalaman/shellcheck)
* [extFS](https://www.paragon-software.com/home/extfs-mac/)

## Install

Using git, clone this repository into a directory named `~/.msm`.

    git clone git@github.com:ricallinson/msm.git ~/.msm

To activate msm, you need to source it from your shell:

    source ~/.msm/src/msm.sh

I always add this line to my _~/.bashrc_, _~/.profile_, or _~/.zshrc_ file to have it automatically sourced upon login. For OSX this can be achieved with the following command;

	echo "source ~/.msm/src/msm.sh" >> ~/.bash_profile

## Usage

Once a Msm workspace has been created anything you place in the workspaces `./srv` directory will be added to the `./pkg/service.img` disk image. The `./svr/init.sh` file can then be used for whatever you want to happen after the kernel has booted.

### Example

The following commands will create a Msm workspace, build a Tiny Core Linux disk image and then load it with QEMU. Once the Linux kernel has booted it will execute whatever is in the `./svr/init.sh` file.

	mkdir ./msmtest
	cd ./msmtest
	msm here .
	msm run

Once this is completed you should see a QEMU window with the words "Hello World!" above the Tiny Core header once the kernel has booted.

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
