# USB-C Adapter / USB-C 変換アダプタ

3D-printable adapter that converts the keyboard's proprietary connector to a
USB-C receptacle.

キーボードの専用コネクタを USB-C メスに変換する、3Dプリント用アダプタです。

## Files / ファイル

| File | Description |
|---|---|
| [`stl/12pin-to-usb.stl`](stl/12pin-to-usb.stl) | Adapter shell / アダプタ筐体 |

## Wiring / 配線

### Keyboard-side connector / キーボード側コネクタ

2.54 mm pitch QI connector, 2 x 6.

2.54 mm ピッチの QI コネクタ（2 x 6）です。

Viewed with the latch facing up, columns are numbered 1-6 from the left.

ラッチを上に向けた状態で、左から 1 〜 6 列とします。

```
        ============LATCH / ラッチ===========
        +-----+-----+-----+-----+-----+-----+
Row 1   | 5V  | D+  | GND | NC  | NC  | NC  |
        +-----+-----+-----+-----+-----+-----+
Row 2   | GND | D-  | GND | NC  | NC  | NC  |
        +-----+-----+-----+-----+-----+-----+
Col        1     2     3     4     5     6
```

| Column / 列 | Row 1 / 行1 | Row 2 / 行2 |
|---|---|---|
| 1 | 5V | GND |
| 2 | D+ | D- |
| 3 | GND | GND |
| 4 | NC | NC |
| 5 | NC | NC |
| 6 | NC | NC |

- **NC** — not connected / 未結線
- D+ and D- sit adjacent in column 2 so they can be routed as a differential
  pair. / D+ と D- は列 2 に隣接配置されており、差動ペアとして配線できます。
- GND is present on column 1 row 2 and on both rows of column 3.
  / GND は列 1 行2 と列 3 の両行にあります。

### Mapping to USB-C / USB-C への対応

| Signal | Keyboard connector / キーボード側 | USB-C receptacle / USB-C レセプタクル |
|---|---|---|
| VBUS (5V) | Col 1, Row 1 | A4, A9, B4, B9 |
| GND | Col 1 Row 2 / Col 3 both rows | A1, A12, B1, B12 |
| D+ | Col 2, Row 1 | A6 **and** B6 |
| D- | Col 2, Row 2 | A7 **and** B7 |

D+/D- must be bridged to both the A and B sides of the receptacle so the cable
works in either orientation.

ケーブルを裏表どちらでも挿せるようにするため、D+/D- はレセプタクルの A 側・B 側
の両方に接続してください。

### CC pull-down resistors / CC プルダウン抵抗

> **TODO:** Confirm and document the CC resistor implementation.
> CC 抵抗の実装を確認し、記載してください。

A USB-C receptacle on a device (UFP) requires a 5.1 kohm pull-down to GND on
**both** CC1 (A5) and CC2 (B5). Without them, a host connected with a C-to-C
cable will not supply VBUS and the keyboard will not enumerate. An A-to-C cable
will still work, because a legacy-A host supplies VBUS unconditionally.

デバイス側（UFP）の USB-C レセプタクルには、CC1（A5）と CC2（B5）の**両方**に
5.1 kΩ の GND プルダウン抵抗が必要です。これがないと、C-to-C ケーブルで接続した
ホストは VBUS を供給せず、キーボードは認識されません。A-to-C ケーブルの場合は、
レガシー A ポートが無条件で VBUS を供給するため動作します。

**Note / 注意:** This adapter carries USB 2.0 signalling only (D+/D-, VBUS,
GND). It does not implement USB-C Power Delivery or alternate modes.

このアダプタが扱うのは USB 2.0 の信号（D+/D-、VBUS、GND）のみです。USB-C の
Power Delivery やオルタネートモードには対応しません。

**Note / 注意:** 5V and GND are adjacent on the keyboard-side connector. Check
continuity and isolation with a multimeter before applying power.

キーボード側コネクタでは 5V と GND が隣接しています。通電前にテスターで導通と
絶縁を確認してください。

## Disclaimer / 免責

Use at your own risk. Verify the pinout against your own hardware before
connecting it to a host — incorrect wiring can damage the keyboard, the
adapter, or the host port.

自己責任でご利用ください。ホストに接続する前に、必ずお手元のハードウェアで
ピンアサインを確認してください。誤配線はキーボード・アダプタ・ホスト側ポートの
破損につながります。

## License / ライセンス

[CC BY-SA 4.0](LICENSE)
