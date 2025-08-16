# AIC8800D80 Linux Driver

## Overview

This driver provides Linux support for USB WiFi 6 adapters based on the AIC8800D80 chipset, including the UGREEN AX900 and other devices with Vendor ID `368B`.

## Supported Devices

- **UGREEN AX900 USB WiFi 6 Adapter** (requires device ID modification)
- Tenda U11 and AX913B
- Other devices with Vendor ID `368B` (AIC_V2)

## Hardware Information - UGREEN AX900

- **Device**: UGREEN AX900 USB WiFi 6 Adapter
- **Chipset**: AIC8800D80 (AICSemi)
- **USB IDs**: 
  - Mass storage mode: `a69c:5724`
  - WiFi mode: `368b:8d88`

## Known Limitations

- **Bluetooth functionality is NOT working**
- Tested on Linux kernels 6.1.0.27 (Debian 12), 6.8.0.51 (Linux Mint), and 6.16 (Ubuntu 25.04)
- May require manual device ID addition for some UGREEN variants
- Device creates interface with MAC-based naming (e.g., `wlx6c1ff779ca6c`)

## Prerequisites

Install the required build tools and kernel headers:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
```

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/retteghy/aic8800d80.git
cd aic8800d80
```

### Step 2: Install Firmware

First, clean any existing AIC8800 firmware (as recommended by the original driver author):

```bash
sudo rm -rf /lib/firmware/aic8800*
```

Install the correct firmware:

```bash
sudo cp -r fw/aic8800D80 /lib/firmware/
```

### Step 3: Install USB Mode Switching Rules

Copy the udev rules for automatic device recognition:

```bash
sudo cp aic.rules /lib/udev/rules.d/
sudo udevadm control --reload-rules
```

### Step 4: Compile and Install the Driver

Navigate to the driver directory and compile:

```bash
cd drivers/aic8800
make
```

Install the compiled driver:

```bash
sudo make install
```

### Step 5: Load the Driver

Load the driver using modprobe:

```bash
sudo modprobe aic8800_fdrv
```

## For UGREEN AX900 Users - Important Notes

### USB Mode Switching Process

The UGREEN AX900 implements a two-stage boot process:

1. **Stage 1** (`a69c:5724`): Device appears as mass storage containing Windows drivers
2. **Stage 2** (`368b:8d88`): After firmware loading, device switches to WiFi mode

### Installation Steps Specific to UGREEN AX900

1. Device will initially appear as mass storage device
2. After driver installation and firmware loading, **unplug and replug the device**
3. Device should automatically switch to WiFi mode
4. If device doesn't switch modes, check udev rules installation

### Device ID Support

If your UGREEN AX900 isn't recognized, you may need to add the device ID manually:

#### Edit the USB header file:

Add the device ID definition to `aic8800_fdrv/aicwf_usb.h`:

```c
#define USB_PRODUCT_ID_AIC8800D80_UGREEN 0x8D88
```

#### Add to USB device table:

In `aic8800_fdrv/aicwf_usb.c`, add the entry to the `aicwf_usb_id_table[]`:

```c
{USB_DEVICE(USB_VENDOR_ID_AIC_V2, USB_PRODUCT_ID_AIC8800D80_UGREEN)},
```

#### Add to device type detection:

In the same file, add the device to the chip detection logic:

```c
}else if(pid == USB_PRODUCT_ID_AIC8800D81 || pid == USB_PRODUCT_ID_AIC8800D41
    || pid == USB_PRODUCT_ID_TENDA_U11 || pid == USB_PRODUCT_ID_TENDA_U11_PRO
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS1 || pid == USB_PRODUCT_ID_AIC8800M80_CUS2
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS3 || pid == USB_PRODUCT_ID_AIC8800M80_CUS4
    || pid == USB_PRODUCT_ID_AIC8800M80_CUS5 || pid == USB_PRODUCT_ID_AIC8800M80_CUS6
    || pid == USB_PRODUCT_ID_AIC8800D80_UGREEN){
```

#### Rebuild and Install

After making the modifications:

```bash
make clean
make
sudo make install
```

## Testing

Verify the interface is created:

```bash
ip link show
iwconfig
```

You should see a new WiFi interface (e.g., `wlx6c1ff779ca6c`) with device identification "AIC@8800".

## Troubleshooting

### Device Not Recognized

Check USB device status:
```bash
lsusb | grep -E "(aic|368b|a69c)"
```

Check kernel messages:
```bash
dmesg | tail -20
```

Verify driver is loaded:
```bash
lsmod | grep aic
```

### Firmware Loading Issues

Check for firmware loading errors:
```bash
dmesg | grep -i firmware
```

Verify firmware files exist:
```bash
ls -la /lib/firmware/aic8800D80/
```

Check firmware path issues:
```bash
dmesg | grep "firmware path"
```

### Common Issues

1. **Device stays in mass storage mode**: Check udev rules installation and try unplugging/replugging
2. **Driver probe fails**: Verify firmware is in correct location and device ID is supported
3. **Interface not created**: Check dmesg for error messages and ensure driver recognizes device ID

### Firmware Loading Sequence

The driver loads firmware in this order:
1. `fw_patch_table_8800d80_u02.bin`
2. `fw_patch_8800d80_u02.bin` 
3. `fw_patch_8800d80_u02_ext0.bin`
4. `fmacfw_8800d80_u02.bin`

## Technical Details

### Kernel Compatibility

- Compatible with kernels 3.10-6.8
- May require modifications for kernels 6.9+
- Tested extensively on Ubuntu 25.04, Debian 12, and Linux Mint

### Driver Architecture

This driver is based on the original AIC8800 driver with modifications for:
- USB device ID support for Vendor ID `368B`
- Kernel compatibility improvements
- UGREEN-specific device handling

## Contributing

When reporting issues, please include:
- Your specific hardware model and USB ID
- Linux distribution and kernel version
- Complete dmesg output
- Steps you've already tried

## Credits

- **Original driver source**: https://github.com/shenmintao/aic8800d80
- **Author note**: "I did not develop this software... I only made some modifications to the code to adapt it to newer kernel versions"
- **Original AIC8800 driver**: Developed by AICSemi
- **Community contributions**: Linux kernel compatibility improvements

## License

This driver is provided as-is for educational and development purposes. Please refer to the original source repository for licensing information.

## Final Result

After successful installation, supported devices will appear as working WiFi interfaces with:

- **Interface name**: MAC-based naming (e.g., `wlx6c1ff779ca6c`)
- **Device identification**: "AIC@8800"
- **Full WiFi 6 functionality**: Ready for network connections
- **Automatic recognition**: Works immediately after plugging in (after initial setup)

The adapter is fully functional and ready for use with standard Linux WiFi management tools like NetworkManager, wpa_supplicant, and iw/iwconfig.
