# Overview
This Dockerfile is used to create a Docker image that can be utilized for executing the NVIDIA SDK Manager in GUI mode by utilizing X11 forwarding.

**Host platforms tested:**
- Ubuntu Linux 24.04.1 LTS

**Sucessfully flashed to:**
- NVIDIA Orin AGX 64GB Devlopment Kit, EMMC

This was originally created for two reasons:
1. I didn't have a Linux system available with an old enough version that was supported by the NVIDIA SDK Manager.
2. The Docker image that NVIDIA provides only has the SDK Manager command line utility and not the GUI. I was having issues with the command line version succesfully flashing my [*NVIDIA Orin AGX Dev Kit*](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/index.html) and wanted to see if the GUI application could provide more information.

# Synopsis
Critical to flashing is making sure the USB auto suspend rules are **not** active for your host systems USB port that is being utilized for your Jetson development kit. Thus first step is to install [**`01-usb-autosuspend.rules`**](#01-usb-autosuspendrules).

```bash
$ ./build
$ ./nvidia
```
After a few seconds the **NVIDIA SDK Manager** GUI will be displayed and you can utilize it as if was being executed on your local system. See the [next](#nvidia-sdk-manager) section below for more details.

# NVIDIA SDK Manager
Once the NVIDIA SDK Manager is launched you should see an interface broken into four steps for your completion. You can follow the online instructions [here](https://developer.ridgerun.com/wiki/index.php/JetPack_6_Migration_and_Developer_Guide/Installing_JetPack_6/Flashing_with_SDK_Manager).

>**NOTE**: At some point you will need to autehnticate to your NVIDIA account. If you don't have one then register for one, there free. In addition **SDK Manager** will not be able to open a browser for authentication so you will need to use the 3D barcode from your phone to launch an authentication screen. (Look to the top right and you will see a 3D bar code peeking out, click on that.)

>**NOTE**: When continuing from **STEP 02** to **STEP 03** you will be asked for the sudo password for the container, the `sudo` password is `nvidia`.

Downloading all of the assets doesn't take that much time; however, waiting for the **SDK Manager** to *Create the OS image* takes quite a bit and actually flashing takes even longer. If you have to abort it should be faster the second time around as the assets that were download will be in the `./jetson/downloads` directory and will be automatically detected.

# Docker `run`
## Mapped Volumes/Directories
### `./jetson/.nvsdkm`
This directory will hold the various logs that SDK Manager generates while executing. These are important for debugging if there is a failure. After successful flashing this directory can be deleted.

### `./jetson/downloads`
This directory will hold all of the various assets that SDK Manager requires for configuring your installation based on your selections. These are stored in a mapped volume/directory so that they are not lost on the occasion that there is a failure and debugging is required. After successful flashing this directory can be deleted.

### `./jetson/nvidia`
This directory will hold built assets necessary for the flashing process. These are stored in a mapped volume/directory so that they are not lost on the occasion that there is a failure and debugging is required. After successful flashing this directory can be deleted.

## Files
### **`01-usb-autosuspend.rules`**
This needs to be installed on your **HOST** system to make sure that auto suspend is turned off for the USB port your development kit is connected to. It uses the vendor id for **NVIDIA (0955)** and the product id **7023** for my **NVIDIA Orin AGX 64GB** development kit. Your product id may be different, if so then update this file before following the directions below on installation.

> **NOTE**: If you have a different Jetson development kit and you can send me your product id then I can incorporate a method to make this part of the supporting script files.

```bash
$ sudo cp ./01-usb-autosuspend.rules /etc/udev/rules.d
$ sudo udevadm control --reload
```
Or even better, reboot if it's not to onerous.

### Wanna check of autosuspend is turned on for a usb device:
```bash
for device in /sys/bus/usb/devices/*/power/control; do
    echo "$device: $(cat $device)"
done
```
If control is set to "on", auto-suspend is disabled.
If control is set to "auto", auto-suspend is enabled.

Similarly, you can check the autosuspend_delay_ms values:

```bash
for device in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
    echo "$device: $(cat $device)"
done
```
A value of -1 generally indicates auto-suspend is disabled for that device.
Any positive value indicates a delay in milliseconds before the device enters suspend mode.

### **`Dockerfile`**
This file contains all of the necessary commands to build an appropriate Docker image. Please note that there are no guarantees that this is the minimal image size. (If you have suggestions on how to make a smaller image then please let me know, I would happy to incorporate them.)

### **`build`**
This shell script builds the Docker image and names it `nvidia-sdkmanager:latest`.

### **`nvidia`**
This shell script runs the image creating a container named `nvidia-sdkmanager` with a hostname of *`NVIDIA`* providing all the the necessary X11 forwarding configuration and volume sharing.

#### Explanation of `docker run`
I will only put additional comments for options that are necessary for the NVIDIA SDK Manager use case.

```bash
docker run -it --rm \
  --net=host \
  --privileged \
  --env DISPLAY=${DISPLAY} \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/bus/usb:/dev/bus/usb \
  -v ./downloads:/home/nvidia/Downloads \
  -v ./.nvsdkm:/home/nvidia/.nvsdkm \
  --hostname NVIDIA \
  --add-host NVIDIA:127.0.0.1 \
  --name nvidia-sdkmanager \
  nvidia-sdkmanager
```

```bash
  --env DISPLAY=${DISPLAY} \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
```
This enables X11 forwarding from the container to the host and therefore allows the NVIDIA SDK Manager GUI to work from a container.

```bash
  -v /dev/bus/usb:/dev/bus/usb \
```
This maps the hosts usb device directory to the container which is necessary for successful flashing. `--privileged` also contributes to the successful flashing.

```bash
  -v ./jetson/.nvsdkm:/home/nvidia/.nvsdkm \
```
This maps a host directory to the containers `.nvsdkm` directory which holds the status and logs for the configuration your attempting to build and flash to your development kit.

```bash
  -v ./jetson/downloads:/home/nvidia/Downloads \
```
This maps a host directory to the containers `Downloads` directory so that whatever is download will not be lost when the container closes which speeds up subsequent flashing.

```bash
  -v ./jetson/nvidia:/home/nvidia/nvidia \
```
This maps a host directory to the containers `nvidia` directory so that whatever is generated by the SDK manager is not lost when the container is closed and can be utilized for debugging or reflashing if necessary.

### **`startup.sh`**
This shell script is copied into the image during the Docker build process and is the `ENTRYPOINT` for the launch of the container. It automatically launches the **NVIDIA SDK Manager** and then drops into a `bash` shell for further commands.

> **NOTE**: You will notice the use of `--privileged`, get over it as the dev kit is NOT mounted as a USB device. This is the only way for the `sdkmanager` to detect the device and still have access to flash. (If you know of a more secure way then I am all ears!)

# Notes
## Interesting SDK CLI Commands

Gives the many options of the NVIDIA SDK Manager.
```bash
$ sdkmanager --help
```

Lists all of the connected Jetson devices.
```bash
$ sdkmanager --list-connected Jetson
```

Text based queries from the NVIDIA SDK Manager to configure a command to the SDK Manager CLI. The queries are interactive and require user input.
```bash
$ sdkmanager --query interactive
```

## QEMU
If you’re using an `x86` host to flash an `ARM` device, **QEMU** is typically required to execute `ARM` binaries in a `chroot` environment. This is why we install the `qemu-user-static` and `binfmt-support` packages.

To see if the alternate platforms are ready for use by QEMU:
```bash
$ ls /proc/sys/fs/binfmt_misc
```

Output:
```bash
qemu-aarch64 qemu-arm
```

Should be present in the list, as likely several others. If for some reason they do not appear then you can manually run:
```bash
$ sudo update-binfmts --enable qemu-arm && sudo update-binfmts --enable qemu-aarch64
```

## TBD
Another method to check on what alternate platforms are ready for use by QEMU:
```bash
$ ls -l /usr/lib/binfmt.d
```

>**NOTE**: After succesful flashing it will attempt to install the SDK so have your ethernet connected so it can find the internet and attempt package downloads.