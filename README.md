# Microkernel Service Maker (MSM)

Currently broken.

## Prerequisites

This has only been tested on an M2 Air running OSX 13.4.

* [Core](http://tinycorelinux.net/)
* [QEMU](https://www.qemu.org/)
* [extFS](https://www.paragon-software.com/home/extfs-mac/)

## How it Works

The idea is simple. Create a base Linux image that's super small (http://tinycorelinux.net/).
Then add your desired service to it and boot it.

The following details the underpinnings of the "Microkernel Service Maker" (MSM) CLI.

## Creating the Base Image

The base disk-image is what will be used to generate all future service disk-images.

First make an empty disk image (taking into account how much disk space you will need).

	qemu-img create -f raw ./images/base.img 50M

Now boot your base Linux `iso` image into the empty disk image.
As of writing [Core](http://tinycorelinux.net/downloads.html) was the kernel used in this example.
Everything following is specific to this distribution.

	qemu-system-x86_64 -m 512 -hda ./images/base.img -cdrom ./iso/core-x86-14.0.iso -boot d

Once the VM loads the boot screen, hit `return`. No boot options are required at this point.

Now type the following to install the `install tool`.

	tce-load -wil tc-install

When the downloads have completed, execute the tool via `sudo`.

	sudo tc-install.sh

Then enter the following answers to the options when asked.

* c (from booted CDROM)
* f (frugal)
* 1 (whole Disk)
* 2 (sda)
* y (install boot loader)
* return (skip, not required)
* 3 (ext4)
* opt=sda1 waitusb=0 noautologin
* y (yes)

Now `poweroff` the VM to commit the settings.

	sudo poweroff

With that done, boot up the base-image VM with the following command.

	qemu-system-x86_64 -m 512 -hda ./images/base.img

Then `poweroff` again. This creates the `/opt/` directory used later to load services.

	sudo poweroff

### Creating a Service Disk Image

This process uses the disk-image built above as the *base* for any services created.

Create a new empty disk image.

	qemu-img create -f raw "./pkg/service.img" 50M

Attach the empty image.

	hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount ./pkg/service.img

Copy the base-image into the new empty disk image image.

	dd if="../../new/images/base.img" of="/dev/disk4"

Eject the new disk image.

	hdiutil eject /dev/disk4

### Adding a Service to the Disk Image

[Core](http://tinycorelinux.net/) has a simple system for running a shell script after boot.
All this step does is copy the service executable(s) and a shell script to start said service.

	hdiutil attach ./pkg/service.img -mountpoint ./mnt

	cp -r ./srv ./mnt/opt/msm/
	echo "/opt/msm/start.sh" >> "./mnt/opt/bootlocal.sh"

	hdiutil eject ./mnt

### Running the Service Image

The *Microkernel Service* is now ready to perform it's duties.

To run the service in a VM (with network bridging) use the following command.

	qemu-system-x86_64 -m 512 -hda ./pkg/service.img -nic vmnet-bridged,ifname=en0

Once running you can use `ifconfig` to discover the VM's IP address.
