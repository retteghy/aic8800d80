# UGREEN AX900 USB WiFi Adapter Setup Guide for Linux

## Overview

This guide provides a complete solution for getting the UGREEN AX900 USB WiFi 6 adapter working on Linux systems. The adapter uses an AIC8800D80 chipset and requires specific drivers and firmware.

## Hardware Information

- **Device**: UGREEN AX900 USB WiFi 6 Adapter
- **Chipset**: AIC8800D80 (AICSemi)
- **USB IDs**: 
  - Mass storage mode: `a69c:5724`
  - WiFi mode: `368b:8d88`

## Prerequisites

Install the required build tools and kernel headers:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
```

## Solution Overview

The UGREEN AX900 requires a two-stage setup process:

1. **USB Mode Switching**: Device starts in mass storage mode and must be switched to WiFi mode
2. **Driver Installation**: Install the specialized AIC8800D80 driver that supports the `368b:8d88` device ID

## Step 1: Download the Correct Driver

The key breakthrough was finding the correct driver repository that supports the UGREEN AX900's device ID:

```bash
git clone https://github.com/shenmintao/aic8800d80.git
cd aic8800d80
```

This repository specifically supports devices with Vendor ID `368B` (including the UGREEN AX900).

## Step 2: Install Firmware

First, clean any existing AIC8800 firmware (as recommended by the driver author):

```bash
sudo rm -rf /lib/firmware/aic8800*
```

Install the correct firmware:

```bash
sudo cp -r fw/aic8800D80 /lib/firmware/
```

## Step 3: Install USB Mode Switching Rules

Copy the udev rules for automatic device recognition:

```bash
sudo cp aic.rules /lib/udev/rules.d/
sudo udevadm control --reload-rules
```

## Step 4: Compile and Install the Driver

Navigate to the driver directory and compile:

```bash
cd drivers/aic8800
make
```

Install the compiled driver:

```bash
sudo make install
```

## Step 5: Add Support for UGREEN Device ID

The original driver didn't include the UGREEN device ID `368b:8d88`. We need to add it manually:

### Edit the USB header file:

Add the device ID definition to `aic8800_fdrv/aicwf_usb.h`:

```c
#define USB_PRODUCT_ID_AIC8800D80_UGREEN 0x8D88
```

### Add to USB device table:

In `aic8800_fdrv/aicwf_usb.c`, add the entry to the `aicwf_usb_id_table[]`:

```c
{USB_DEVICE(USB_VENDOR_ID_AIC_V2, USB_PRODUCT_ID_AIC8800D80_UGREEN)},
```

### Add to device type detection:

In the same file, add the device to the chip detection logic:

```c
}else if(pid == USB_PRODUCT_ID_AIC8800D81 || pid == USB_PRODUCT_ID_AIC8800D41
    || pid == USB_PRODUCT_ID_TENDA_U11 || pid == USB_PRODUCT_ID_TENDA_U11_PRO
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS1 || pid == USB_PRODUCT_ID_AIC8800M80_CUS2
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS3 || pid == USB_PRODUCT_ID_AIC8800M80_CUS4
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS5 || pid == USB_PRODUCT_ID_AIC8800M80_CUS6
    || pid == USB_PRODUCT_ID_AIC8800D80_UGREEN){
```

## Step 6: Rebuild and Install

After making the modifications:

```bash
make clean
make
sudo make install
```

## Step 7: Load the Driver

Load the driver using modprobe:

```bash
sudo modprobe aic8800_fdrv
```

## Step 8: Test the Device

Unplug and replug the UGREEN AX900. The device should:

1. Start in mass storage mode (`a69c:5724`)
2. Automatically switch to WiFi mode (`368b:8d88`) 
3. Create a WiFi interface (e.g., `wlx6c1ff779ca6c`)

Verify the interface is created:

```bash
ip link show
iwconfig
```

## Troubleshooting

### Check USB device detection:
```bash
lsusb | grep -E "(aic|368b|a69c)"
```

### Check kernel messages:
```bash
dmesg | tail -20
```

### Verify driver is loaded:
```bash
lsmod | grep aic
```

### Check for firmware loading errors:
```bash
dmesg | grep -i firmware
```

## Key Technical Details

### USB Mode Switching Process

The UGREEN AX900 implements a two-stage boot process:

1. **Stage 1** (`a69c:5724`): Device appears as mass storage containing Windows drivers
2. **Stage 2** (`368b:8d88`): After firmware loading, device switches to WiFi mode

### Firmware Loading Sequence

The driver loads firmware in this order:
1. `fw_patch_table_8800d80_u02.bin`
2. `fw_patch_8800d80_u02.bin` 
3. `fw_patch_8800d80_u02_ext0.bin`
4. `fmacfw_8800d80_u02.bin`

### Driver Source Information

- **Repository**: https://github.com/shenmintao/aic8800d80
- **Author Note**: "I did not develop this software... I only made some modifications to the code to adapt it to newer kernel versions"
- **Tested On**: Linux kernel 6.16 (Ubuntu 25.04) and 6.1.0.27 (Debian 12)
- **Known Issue**: Bluetooth functionality not working

## Credits

- Driver source: https://github.com/shenmintao/aic8800d80
- Original AIC8800 driver development by AICSemi
- Community modifications for Linux kernel compatibility

## Final Result

After successful installation, the UGREEN AX900 will appear as a working WiFi interface with:

- **Interface name**: (MAC-based naming)
- **Device identification**: "AIC@8800"
- **Full WiFi 6 functionality**: Ready for network connections
- **Automatic recognition**: Works immediately after plugging in

The adapter is now fully functional and ready for use with standard Linux WiFi management tools.
