# AIC8800D80 Linux Driver for UGREEN USB WiFi Adapters

## Overview

Complete installation guide for AIC8800D80-based USB WiFi 6 adapters, specifically tested with UGREEN devices. This driver provides full WiFi functionality on Linux systems.

## Supported Devices

- **UGREEN AX900 USB WiFi 6 Adapter**
- **UGREEN devices with USB ID**: `368b:8d88` (WiFi mode), `a69c:5724` (mass storage mode)
- Other AIC8800D80-based adapters

## Hardware Information

- **Chipset**: AIC8800D80 (AICSemi)
- **USB Mode Switching**: Device appears as mass storage first, then switches to WiFi mode
- **Interface Naming**: Creates MAC-based interface names (e.g., `wlx6c1ff779ca6c`)

## Prerequisites

Install required build tools and kernel headers:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
```

## Complete Installation Guide

### Step 1: Clone Repository

```bash
git clone https://github.com/shenmintao/aic8800d80.git
cd aic8800d80
```

### Step 2: Install Firmware

Clean any existing AIC8800 firmware:
```bash
sudo rm -rf /lib/firmware/aic8800*
```

Install the correct firmware:
```bash
sudo cp -r firmwares/aic8800D80 /lib/firmware/
```

### Step 3: Install USB Mode Switching Rules

```bash
sudo cp 50-usb-realtek-net.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### Step 4: Add UGREEN Device ID Support

**CRITICAL STEP**: UGREEN devices require manual device ID addition to work.

#### Edit USB Header File

Edit `drivers/aic8800/aic8800_fdrv/aicwf_usb.h` and add this line after line 50:

```c
#define USB_PRODUCT_ID_AIC8800D80_UGREEN 0x8D88
```

The line should be added after `#define USB_PRODUCT_ID_AIC8800M80_CUS6  0x8D8C`.

#### Add to USB Device Table

Edit `drivers/aic8800/aic8800_fdrv/aicwf_usb.c` and add this line to the `aicwf_usb_id_table[]` around line 2671:

```c
{USB_DEVICE(USB_VENDOR_ID_AIC_V2, USB_PRODUCT_ID_AIC8800D80_UGREEN)},
```

Add this line before the `#endif` in the USB device table.

#### Add to Device Detection Logic

In the same file, find the chip detection logic around line 2350-2354 and add `|| pid == USB_PRODUCT_ID_AIC8800D80_UGREEN` to the existing condition:

```c
}else if(pid == USB_PRODUCT_ID_AIC8800D81 || pid == USB_PRODUCT_ID_AIC8800D41
    || pid == USB_PRODUCT_ID_TENDA_U11 || pid == USB_PRODUCT_ID_TENDA_U11_PRO
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS1 || pid == USB_PRODUCT_ID_AIC8800M80_CUS2
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS3 || pid == USB_PRODUCT_ID_AIC8800M80_CUS4
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS5 || pid == USB_PRODUCT_ID_AIC8800M80_CUS6
    || pid == USB_PRODUCT_ID_AIC8800D80_UGREEN){
```

### Step 5: Compile and Install Driver

Navigate to the driver directory:
```bash
cd drivers/aic8800
```

Compile the driver:
```bash
make clean
make
```

Install the driver:
```bash
sudo make install
```

### Step 6: Load Driver Modules

```bash
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv
```

### Step 7: Connect and Test Device

1. Plug in the UGREEN USB WiFi adapter
2. The device will initially appear as mass storage (`a69c:5724`)
3. After a few seconds, it should automatically switch to WiFi mode (`368b:8d88`)
4. Check that the device is recognized:

```bash
lsusb | grep "368b:8d88"
```

You should see:
```
Bus XXX Device XXX: ID 368b:8d88 AICSemi AIC 8800D80
```

5. Verify the WiFi interface is created:

```bash
ip link show | grep wlx
```

You should see a new WiFi interface like `wlx6c1ff779ca6c`.

6. Test WiFi scanning:

```bash
sudo iwlist scan | head -10
```

## What to Avoid

- **Do not attempt manual device binding** without adding device ID to source code first
- **Do not skip the device ID addition step** - UGREEN devices will not work without it
- **Do not mix different AIC8800 firmware versions** - clean old firmware first

## Troubleshooting

### Device Not Switching Modes

Check if udev rules are properly installed:
```bash
ls -la /etc/udev/rules.d/50-usb-realtek-net.rules
```

Reload udev rules:
```bash
sudo udevadm control --reload-rules
```

Unplug and replug the device.

### Driver Not Recognizing Device

Verify device ID was added to all three locations in the source code:
1. Header file (`aicwf_usb.h`)
2. USB device table (`aicwf_usb.c`)
3. Chip detection logic (`aicwf_usb.c`)

Rebuild and reinstall the driver after making changes.

### No WiFi Interface Created

Check kernel messages:
```bash
dmesg | tail -20
```

Verify driver modules are loaded:
```bash
lsmod | grep aic
```

Check firmware files exist:
```bash
ls -la /lib/firmware/aic8800D80/
```

### Firmware Loading Issues

Verify firmware path in kernel messages:
```bash
dmesg | grep -i firmware
```

Ensure firmware files have correct permissions:
```bash
sudo chmod -R 644 /lib/firmware/aic8800D80/
```

## Testing WiFi Functionality

After successful installation:

1. **Check interface**: `ip link show`
2. **Scan networks**: `sudo iwlist wlx[TAB] scan`
3. **Connect to network**: Use NetworkManager or wpa_supplicant

The adapter supports full WiFi 6 functionality and works with standard Linux WiFi management tools.

## Technical Notes

- **Kernel Compatibility**: Tested on kernels 6.1-6.8
- **Device Naming**: Interface uses MAC-based naming (e.g., `wlx6c1ff779ca6c`)
- **Bluetooth**: Not supported with this driver
- **Performance**: Full WiFi 6 speeds supported

## Credits

- **Original driver**: https://github.com/shenmintao/aic8800d80
- **Hardware**: AICSemi AIC8800D80 chipset
- **Testing**: UGREEN AX900 USB WiFi 6 adapter on Linux 6.8.0-71-generic

## License

Refer to the original repository for licensing information. This guide is provided for educational purposes.
