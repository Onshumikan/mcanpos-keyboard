# Toshiba Global Commerce POS Keyboard — USB-C Adapter & TrackPoint Scrolling

[日本語版 / Japanese version](README.ja.md)

Resources for using a Toshiba Global Commerce Solutions **USB Compact
Alphanumeric POS Keyboard** (USB ID `04b3:4609`) as an everyday keyboard on a
normal PC:

| Directory | Contents |
|---|---|
| [`hardware/`](hardware/) | 3D-printable adapter from the keyboard's proprietary connector to a USB-C receptacle |
| [`trackpoint-scroll/`](trackpoint-scroll/) | Linux daemon that makes the TrackPoint scroll, despite the keyboard having no physical middle button |

These keyboards are sold cheaply as surplus retail hardware, but two things
get in the way of daily use: the non-standard cable, and a TrackPoint that
cannot scroll out of the box. This repository addresses both.

---

## Hardware — USB-C adapter

The keyboard terminates in a proprietary connector rather than a standard USB
plug. `hardware/` contains STL files for an adapter housing that exposes a
USB-C receptacle, so the keyboard can be used with an ordinary USB-C cable.

See [`hardware/README.md`](hardware/README.md) for printing notes and wiring.

---

## Software — TrackPoint scrolling on Linux

The TrackPoint has only left and right buttons. There is no physical middle
button, so the usual "hold middle button and push the stick" scrolling does
not work. This daemon assigns scrolling to a spare key instead.

| Action | Result |
|---|---|
| Hold the scroll key and push the TrackPoint | Scrolls while held |
| Tap the scroll key | Scroll mode latches on; tap again to release |

The latching behaviour mirrors libinput's own `ScrollButtonLock`.

### Why a daemon is necessary

This is the part worth reading before you try to solve it with configuration
alone — it cannot be done that way.

libinput's on-button scrolling requires that **the scroll button be a physical
button on the same device that produces the motion events** (see
[libinput: Scrolling](https://wayland.freedesktop.org/libinput/doc/latest/scrolling.html)).
Two consequences follow:

1. **Middle-button emulation does not help.** Enabling `MiddleEmulation` and
   setting `ScrollButton=2` looks like the obvious fix, and it is what many
   guides suggest. It does not work: libinput tests the scroll button against
   the *raw* event code from the kernel, and the emulated `BTN_MIDDLE` is
   synthesized after that test. Pressing left+right produces a middle *click*,
   but never scrolling. (Confirmed on libinput 1.31 / Ubuntu 26.04.)

2. **A key on the keyboard cannot be used directly.** The keyboard and the
   TrackPoint are separate event devices, and libinput does not combine them.

This daemon resolves both by exclusively grabbing the TrackPoint and
re-emitting its motion through a virtual input device, into which the chosen
key is injected as a genuine `BTN_MIDDLE`. libinput then sees a single device
with both motion and a real middle button, and its standard button scrolling
applies with no further configuration.

The virtual device sets `INPUT_PROP_POINTING_STICK`, so systemd's `input_id`
tags it `ID_INPUT_POINTINGSTICK=1` and libinput enables on-button scrolling by
default.

**The keyboard itself is never grabbed.** If the daemon stops, typing still
works and you can recover normally.

### Requirements

- Linux with libinput (works on both Wayland and X11)
- `python3-evdev`
- systemd

### Installation

```sh
sudo apt install -y python3-evdev        # Debian/Ubuntu
git clone https://github.com/Aaron-Morimoto/mcanpos-keyboard.git
sudo ./mcanpos-keyboard/trackpoint-scroll/install.sh
```

The default scroll key is **F19**. See the configuration section if you want a
different one.

### Important: disable middle-click emulation

On GNOME:

```sh
gsettings set org.gnome.desktop.peripherals.mouse middle-click-emulation false
```

If middle-click emulation is enabled, libinput's emulation state machine
consumes `BTN_MIDDLE` and scrolling stops working. Left+right middle-click and
TrackPoint scrolling are mutually exclusive; you cannot have both.

If you need middle-click (paste), assign a second spare key to it rather than
re-enabling emulation.

### Configuration

Edit `/etc/default/mcanpos-scroll`, then
`sudo systemctl restart mcanpos-scroll`.

| Variable | Default | Meaning |
|---|---|---|
| `SCROLL_KEY` | `KEY_F19` | Key that triggers scrolling |
| `LOCK_THRESHOLD_MS` | `250` | Presses shorter than this latch scroll mode |
| `DEVICE_VENDOR` | `0x04B3` | USB vendor ID |
| `DEVICE_PRODUCT` | `0x4609` | USB product ID |

#### Choosing a scroll key

This keyboard has many unlabelled keys, but not all are safe. Their X keysyms
decide whether a desktop will react to them:

| evdev code | Key | X keysym | Safe? |
|---|---|---|---|
| 189 | F19 | *(none)* | ✅ inert — recommended |
| 194 | F24 | *(none)* | ✅ inert |
| 184–188 | F14–F18 | `XF86Launch5`–`9` | ⭕ usually unbound |
| 183 | F13 | `XF86Tools` | ❌ opens GNOME Settings |
| 191–193 | F21–F23 | `XF86Touchpad*` | ❌ touchpad toggles |
| 117 | KPEQUAL | `=` | ❌ types a character |

Twenty further keys emit a `Compose`+letter macro rather than a single
keycode. They cannot express a held state and will leak characters into
applications, so they are unusable here.

To find the code of a key on your own unit:

```sh
sudo evtest /dev/input/eventN | grep --line-buffered EV_KEY
```

A usable key reports `value 1` on press, `value 2` while held, and `value 0`
on release.

### Optional udev rule

`99-mcanpos-pointingstick.rules` tags the *physical* TrackPoint as a pointing
stick. The daemon does not need it — the virtual device carries its own
pointing-stick property — but it makes the hardware behave correctly if the
daemon is not running. Install it only if you want that:

```sh
sudo install -m 644 trackpoint-scroll/99-mcanpos-pointingstick.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

Replug the keyboard afterwards; udev properties are not re-evaluated until the
device is re-enumerated.

### Troubleshooting

```sh
systemctl status mcanpos-scroll
journalctl -u mcanpos-scroll -n 30
```

On a healthy start the log shows the devices it bound to:

```
pointer=/dev/input/event5 keyboard=/dev/input/event4 scroll_key=KEY_F19
```

To confirm that libinput is producing scroll events, find the virtual device's
event node and watch it while pressing the scroll key:

```sh
sudo libinput debug-events --device /dev/input/eventN
```

You should see `POINTER_SCROLL_CONTINUOUS`. If you see those but nothing
scrolls on screen, middle-click emulation is still enabled in your desktop.

The daemon exits when the keyboard is unplugged and systemd restarts it
automatically; device numbering is re-resolved from the USB IDs, so event
numbers may change freely.

---

## License

- Code (`trackpoint-scroll/`) — [MIT](LICENSE)
- 3D models (`hardware/`) — [CC BY-SA 4.0](hardware/LICENSE)
