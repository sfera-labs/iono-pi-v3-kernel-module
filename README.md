# Iono Pi v3 driver kernel module

Raspberry Pi OS (Debian) Kernel module for [Iono Pi v3](https://www.sferalabs.cc/product/iono-pi-v3/).

[![Build tests [stable oldstable]](https://github.com/sfera-labs/iono-pi-v3-kernel-module/actions/workflows/build-apt.yml/badge.svg)](https://github.com/sfera-labs/iono-pi-v3-kernel-module/actions/workflows/build-apt.yml)
[![Build tests [firmware]](https://github.com/sfera-labs/iono-pi-v3-kernel-module/actions/workflows/build-fw.yml/badge.svg)](https://github.com/sfera-labs/iono-pi-v3-kernel-module/actions/workflows/build-fw.yml)

## Installation

Make sure your system is updated:

    sudo apt update
    sudo apt upgrade

If you are using a **32-bit** OS, add to `/boot/firmware/config.txt` (`/boot/config.txt` in older versions) the following line: [[why?](https://github.com/raspberrypi/firmware/issues/1795)]

    arm_64bit=0

Reboot:

    sudo reboot

After reboot, install required tools:

    sudo apt install git device-tree-compiler dkms linux-headers-$(uname -r)

Clone this repo:

    git clone --depth 1 https://github.com/sfera-labs/iono-pi-v3-kernel-module.git
    
    cd iono-pi-v3-kernel-module

### Recommended installation mode: DKMS

This is the recommended mode. It automatically rebuilds and reinstalls the module when new kernel versions are installed.

Register, build and install with DKMS:

    sudo dkms add .
    sudo dkms build -m $(cat MODULE_NAME) -v $(cat VERSION)
    sudo dkms install -m $(cat MODULE_NAME) -v $(cat VERSION)

### Alternative installation mode: manual install for running kernel only

<details>

<summary>Show</summary>

Use this method only if you specifically want to install for the current running kernel version only.

Compile and install:

    make clean
    make
    sudo make install

Manual mode does not provide automatic rebuild on kernel upgrades.

</details>

### Enable overlay at boot

Add to `/boot/firmware/config.txt` the following line:

    dtoverlay=ionopi-v3

If you want to use DT1 as 1-Wire bus, add this line too:

    dtoverlay=w1-gpio

If you are using a Raspberry Pi 5 you should disable its RTC. Add this line:

    dtparam=rtc=off

### Optional non-root access to `/sys/class/ionopi`

The install process places `99-ionopi-v3.rules`, which sets owner group `ionopi` for sysfs entries. To access the sysfs interface without superuser privileges, create the group and add your user, e.g. for user "pi":

    sudo groupadd ionopi
    sudo usermod -a -G ionopi pi

Reboot:

    sudo reboot


## Usage

After installation, the module adds an RTC device, a hardware watchdog device, and exposes all other Iono Pi features through the sysfs interface in the `/sys/class/ionopi/` directory.

The sysfs interface provides virtual files that can be read and/or written to, enabling easy monitoring and control of Iono Pi’s I/O and other functionalities.

For example, toggle relay **O1** from shell:

    $ echo F > /sys/class/ionopi/digital_out/o1
    
Read the voltage on **AV1**:

    $ cat /sys/class/ionopi/analog_in/av1_mv
    
Or using Python:

    f = open('/sys/class/ionopi/digital_out/o1', 'w')
    f.write('F')
    f.close()
    print('Relay O1 switched')

    f = open('/sys/class/ionopi/analog_in/av1_mv', 'r')
    val = f.read().strip()
    f.close()
    print('AV1: ' + val + ' mv')

Refer to the following paragraphs for usage details of all the available sysfs files.

### RTC

The RTC seamlessly integrates with the system's standard date and time functionalities.

When an NTP server is available, the system automatically synchronizes the RTC date and time. Conversely, if no network connection is available or the NTP service is disabled, the system relies on the RTC's stored values.  

You can manage and configure the RTC using the `timedatectl` and `hwclock` utilities.

The device node is available at `/dev/rtc0`.

The sysfs interface for the RTC is accessible at `/sys/class/rtc/rtc0`. In addition to the standard RTC attributes, it includes the `battery_low` file. Reading this file returns `1` if the RTC backup battery voltage is low and `0` otherwise.

### Watchdog / Timed power control

The watchdog can be used to detect and recover from system failures and to implement programmed power-cycles with configurable off time, useful for low-power applications.

The watchdog is accessible through both the standard device node and the sysfs interface.  

By default, the device node is `/dev/watchdog1`, as `/dev/watchdog0` typically corresponds to the CPU's internal watchdog, unless it has been disabled.  

To identify the correct device, run:  

```
sudo wdctl /dev/watchdog*
```

Iono Pi's watchdog will report *"Iono Pi v3 Watchdog"* as its identity string.

You can manage and configure the watchdog using the `wdctl` and `watchdog` utilities.

To program a shutdown with timed power on, just enable the watchdog and let it expire. The Raspberry Pi will be powered off after the configured timeout and then powered back on after the configured off time.

The sysfs interface is available in `/sys/class/ionopi/watchdog/`:

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=2>enabled</td>
            <td rowspan=2>Watchdog enabling</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Disabled</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Enabled</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>timeout</td>
            <td>Watchdog timeout</td>
            <td>R/W</td>
            <td>5 ... 1016</td>
            <td>Value in seconds. Default: 60</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>off_time</td>
            <td>Raspberry Pi power-off duration after watchdog reset</td>
            <td>R/W</td>
            <td>1 ... (86399 - timeout)</td>
            <td>Value in seconds. Default: 5</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>heartbeat</td>
            <td>Watchdog heartbeat update</td>
            <td>W</td>
            <td>1</td>
            <td>Update heartbeat</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### LED - `/sys/class/ionopi/led/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=3>status</td>
            <td rowspan=3>USR LED control</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Off</td>
        </tr>
        <tr>
            <td>1</td>
            <td>On</td>
        </tr>
        <tr>
            <td>W</td>
            <td>F</td>
            <td>Flip the LED's state</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>blink</td>
            <td rowspan=2>USR LED blink</td>
            <td rowspan=2>W</td>
            <td><i>T</i></td>
            <td>Single blink of <i>T</i> ms</td>
        </tr>
        <tr>
            <td><i>T_ON</i> <i>T_OFF</i> <i>REPS</i></td>
            <td>Blink <i>REPS</i> times <i>T_ON</i> ms on, <i>T_OFF</i> ms off. E.g. "200 50 3"</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Analog Inputs - `/sys/class/ionopi/analog_in/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td>ai<i>N</i>_ua</td>
            <td>Analog current input (AI) <i>N</i> value</td>
            <td>R</td>
            <td>0 ... 20000</td>
            <td>Value in µA</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>ai<i>N</i>_raw</td>
            <td>Analog current input <i>N</i> raw ADC value</td>
            <td>R</td>
            <td>-32768 ... 32767</td>
            <td>16-bit signed value</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>av<i>N</i>_mv</td>
            <td>Analog voltage input (AV) <i>N</i> value</td>
            <td>R</td>
            <td>0 ... 30000</td>
            <td>Value in mV</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>av<i>N</i>_raw</td>
            <td>Analog voltage input <i>N</i> raw ADC value</td>
            <td>R</td>
            <td>-32768 ... 32767</td>
            <td>16-bit signed value</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>osr</td>
            <td>MCP3461R ADC oversampling ratio configuration value</td>
            <td>R/W</td>
            <td>1 ... 15</td>
            <td>Refer to the MCP3461R datasheet. Default: 3</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>az_mux</td>
            <td rowspan=2>MCP3461R ADC auto-zeroing MUX configuration</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Auto-zeroing algorithm is disabled</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Auto-zeroing algorithm is enabled (default)</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Digital Inputs - `/sys/class/ionopi/digital_in/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=2>di<i>N</i></td>
            <td rowspan=2>Digital input (DI) <i>N</i> state</td>
            <td rowspan=2>R</td>
            <td>0</td>
            <td>Low</td>
        </tr>
        <tr>
            <td>1</td>
            <td>High</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=3>di<i>N_deb<sup>(<a href="https://github.com/sfera-labs/knowledge-base/blob/main/raspberrypi/poll-sysfs-files.md">pollable</a>)</sup></td>
            <td rowspan=3>Digital input <i>N</i> debounced state</td>
            <td rowspan=3>R</td>
            <td>0</td>
            <td>Low</td>
        </tr>
        <tr>
            <td>1</td>
            <td>High</td>
        </tr>
        <tr>
            <td>-1</td>
            <td>Undefined (no stable state reached)</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>di<i>N</i>_deb_on_ms</td>
            <td>Minimum time the digital input <i>N</i> signal must remain stable before its debounced state switches to high. If written resets the on and off counters</td>
            <td>R/W</td>
            <td><i>T</i></td>
            <td>Time in milliseconds. Default: 50</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>di<i>N</i>_deb_off_ms</td>
            <td>Minimum time the digital input <i>N</i> signal must remain stable before its debounced state switches to low. If written resets the on and off counters</td>
            <td>R/W</td>
            <td><i>T</i></td>
            <td>Time in milliseconds. Default: 50</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>di<i>N</i>_deb_on_cnt</td>
            <td>Digital input <i>N</i> debounced high state counter</td>
            <td>R/W</td>
            <td>0 ... 4294967295</td>
            <td>Rolls back to 0 after 4294967295</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>di<i>N</i>_deb_off_cnt</td>
            <td>Digital input <i>N</i> debounced low state counter</td>
            <td>R/W</td>
            <td>0 ... 4294967295</td>
            <td>Rolls back to 0 after 4294967295</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Digital I/O - `/sys/class/ionopi/digital_io/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=3>dt<i>N</i>_mode</td>
            <td rowspan=3>DT line <i>N</i> mode</td>
            <td rowspan=3>R/W</td>
            <td>x</td>
            <td>Line not controlled by kernel module</td>
        </tr>
        <tr>
            <td>in</td>
            <td>Line configured as input</td>
        </tr>
        <tr>
            <td>out</td>
            <td>Line configured as output</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>dt<i>N</i></td>
            <td rowspan=2>DT line <i>N</i> state (writable only when in output mode)</td>
            <td rowspan=2>R(/W)</td>
            <td>0</td>
            <td>Line low</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Line low</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Digital outputs - `/sys/class/ionopi/digital_out/`

The hardware driver controlling relays and open collectors only allows for collective commands to set all outputs at once. If a single output needs to be switched, the current state of all the other outputs must be sent in the command too.

This kernel module provides entries for individual outputs control too, which masks this complexity, but since at boot the outputs' state is **unknown**, if a single output is written to as first operation, all other outputs are set to `0`.

If a specific state needs to be preserved after a software reboot, the current combined state must be written to the `outputs` file (see below), before individual commands are issued.

A write operation must occur before a read is allowed.

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=4>o<i>N</i></td>
            <td rowspan=4>Relay (O) <i>N</i> state</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Open</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Closed</td>
        </tr>
        <tr>
            <td rowspan=2>R</td>
            <td>F</td>
            <td>Fault while open</td>
        </tr>
        <tr>
            <td>S</td>
            <td>Fault while closed</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=4>oc<i>N</i></td>
            <td rowspan=4>Open collector (OC) <i>N</i> state</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Open</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Closed</td>
        </tr>
        <tr>
            <td rowspan=2>R</td>
            <td>F</td>
            <td>Fault while open</td>
        </tr>
        <tr>
            <td>S</td>
            <td>Short circuit while closed</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>outputs</td>
            <td>Outputs (relays and open collectors) combined state</td>
            <td>R/W</td>
            <td><i>XXXXXXX</i></td>
            <td>Concatenation of all 7 outputs states (e.g. "01F0001")</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>pdc</td>
            <td rowspan=2>Pulldown current configuration</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Disabled (default)</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Enabled</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>spl</td>
            <td rowspan=2>Short-circuit protection latch-off configuration</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Disabled (default)</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Enabled: an overloaded channel is turned off immediately</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=2>reset</td>
            <td rowspan=2>Reset control</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Normal operation</td>
        </tr>
        <tr>
            <td>1</td>
            <td>All outputs are turned off and all pulldown currents disabled</td>
        </tr>
    </tbody>
</table>

### System - `/sys/class/ionopi/system/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=2>5vout_prot</td>
            <td rowspan=2>Output protection</td>
            <td rowspan=2>R</td>
            <td>0</td>
            <td>5VOUT output OK</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Output protection enabled. Temporarily disabled</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Wiegand - `/sys/class/ionopi/wiegand/`

You can use the TTL lines as Wiegand interfaces for keypads or card readers. Up to two Wiegand devices can be connected: **TTL1/TTL2** serve as **D0/D1** for the first device (**w1**), and **TTL3/TTL4** as **D0/D1** for the second device (**w2**).

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td rowspan=2>w<i>N<i>_enabled</td>
            <td rowspan=2>Wiegand interface <i>N<i> enable control</td>
            <td rowspan=2>R/W</td>
            <td>0</td>
            <td>Disabled (default)</td>
        </tr>
        <tr>
            <td>1</td>
            <td>Enabled</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>w<i>N<i>_data<sup>(<a href="https://github.com/sfera-labs/knowledge-base/blob/main/raspberrypi/poll-sysfs-files.md">pollable</a>)</sup></td>
            <td>Wiegand interface <i>N<i> data</td>
            <td>W</td>
            <td><i>TS</i> <i>BITS</i> <i>DATA</i></td>
            <td>Latest data read from Wiegand interface w<i>N</i>. The first value (<i>TS</i>) is an internal timestamp used to distinguish new data from the previous one. <i>BITS</i> indicates the number of received bits (max 64). <i>DATA</i> represents the received bit sequence as an unsigned integer</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

The following properties can be used to improve noise detection and filtering:

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td>w<i>N<i>_pulse_width_max</td>
            <td>Maximum bit pulse width accepted</td>
            <td>R/W</td>
            <td><i>T<i></td>
            <td>Value in µs</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>w<i>N<i>_pulse_width_min</td>
            <td>Minimum bit pulse width accepted</td>
            <td>R/W</td>
            <td><i>T<i></td>
            <td>Value in µs</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>w<i>N<i>_pulse_itvl_max</td>
            <td>Maximum interval between pulses accepted</td>
            <td>R/W</td>
            <td><i>T<i></td>
            <td>Value in µs</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td>w<i>N<i>_pulse_itvl_min</td>
            <td>Minimum interval between pulses accepted</td>
            <td>R/W</td>
            <td><i>T<i></td>
            <td>Value in µs</td>
        </tr>
        <!-- ------------- -->
        <tr>
            <td rowspan=6>w<i>N<i>_noise</td>
            <td rowspan=6>Latest noise event. Resets to 0 after being read</td>
            <td rowspan=6>R</td>
            <td>0</td>
            <td>No noise</td>
        </tr>
        <tr>
            <td>10</td>
            <td>Detected fast pulses on lines</td>
        </tr>
        <tr>
            <td>11</td>
            <td>Detected pulses with too short interval</td>
        </tr>
        <tr>
            <td>12/13</td>
            <td>Concurrent movement on both D0/D1 lines</td>
        </tr>
        <tr>
            <td>14</td>
            <td>Detected too short pulse</td>
        </tr>
        <tr>
            <td>15</td>
            <td>Detected too long pulse</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### Secure Element - `/sys/class/ionopi/sec_elem/`

<table>
    <thead>
        <tr>
            <th>File</th>
            <th>Description</th>
            <th>R/W</th>
            <th>Value</th>
            <th>Value description</th>
        </tr>
    </thead>
    <!-- ================= -->
    <tbody>
        <tr>
            <td>serial_num</td>
            <td>Secure element serial number</td>
            <td>R</td>
            <td><i>HHHHHHHHHHHHHHHHHH</i></td>
            <td>HEX value</td>
        </tr>
        <!-- ------------- -->
    </tbody>
</table>

### 1-Wire - `/sys/bus/w1/devices/`

If 1-Wire is enabled, the list of **1-Wire sensors** connected to **DT1** can be found in `/sys/bus/w1/devices/`, with IDs formatted as `28-XXXXXXXXXXXX`.  

To retrieve the measured temperature (in °C/1000), read the `temperature` file inside the sensor's directory. E.g.:  

```
cat /sys/bus/w1/devices/28-XXXXXXXXXXXX/temperature
```

Example output:  

```
24625
```
