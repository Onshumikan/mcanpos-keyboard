# Toshiba Global Commerce POS キーボード — USB-C 変換アダプタとトラックポイントのスクロール

[English version](README.md)

Toshiba Global Commerce Solutions 製の **USB Compact Alphanumeric POS
Keyboard**（USB ID `04b3:4609`）を、通常の PC で日常的に使うための資料です。

| ディレクトリ | 内容 |
|---|---|
| [`hardware/`](hardware/) | 専用コネクタを USB-C メスに変換するアダプタの3Dモデル |
| [`trackpoint-scroll/`](trackpoint-scroll/) | 物理的な中ボタンが無いトラックポイントでスクロールを実現する Linux 用デーモン |

このキーボードは中古の流通品として安価に入手できますが、日常利用には2つの障壁
があります。非標準のケーブルと、標準状態ではスクロールできないトラックポイント
です。このリポジトリはその両方を扱います。

---

## ハードウェア — USB-C 変換アダプタ

このキーボードのケーブルは標準の USB プラグではなく専用コネクタで終端されて
います。`hardware/` には、USB-C メスコネクタを露出させるアダプタ筐体の STL
ファイルを収録しています。これにより市販の USB-C ケーブルが使えます。

印刷設定と配線については [`hardware/README.md`](hardware/README.md) を参照
してください。

---

## ソフトウェア — Linux でのトラックポイントのスクロール

このトラックポイントには左右のボタンしかありません。物理的な中ボタンが存在し
ないため、一般的な「中ボタンを押しながらスティックを倒す」スクロールが使えま
せん。本デーモンは、代わりに未使用キーへスクロールを割り当てます。

| 操作 | 挙動 |
|---|---|
| スクロールキーを押しながらトラックポイントを倒す | 押している間スクロール |
| スクロールキーを軽く叩く | スクロール状態が継続。もう一度叩いて解除 |

後者は libinput 本来の `ScrollButtonLock` と同じ挙動です。

### なぜデーモンが必要なのか

設定だけで解決しようとする前に読んでいただきたい部分です。**設定では解決でき
ません。**

libinput のボタンスクロールは、**スクロールボタンが「動きを出すデバイス上の
物理ボタン」であること**を要求します
（[libinput: Scrolling](https://wayland.freedesktop.org/libinput/doc/latest/scrolling.html)）。
ここから2つの帰結が生じます。

1. **中ボタンエミュレーションでは解決しません。** `MiddleEmulation` を有効に
   して `ScrollButton=2` を指定するのは一見正しく、多くの解説記事もそう勧めて
   います。しかし動作しません。libinput はスクロールボタンの判定を**カーネル
   から届く生のイベントコード**に対して行い、エミュレーションによる
   `BTN_MIDDLE` の合成はその判定より後に実行されるためです。左右同時押しは
   中「クリック」にはなりますが、スクロールにはなりません。
   （libinput 1.31 / Ubuntu 26.04 で確認）

2. **キーボードのキーをそのまま使うこともできません。** キーボードとトラック
   ポイントは別々のイベントデバイスであり、libinput はそれらを統合しません。

本デーモンはトラックポイントを排他取得し、その動きを仮想入力デバイスへ中継
したうえで、指定キーを**本物の `BTN_MIDDLE`** としてその仮想デバイスに注入し
ます。libinput から見ると「動きと中ボタンを併せ持つ単一のデバイス」になるため、
標準のボタンスクロールが追加設定なしでそのまま機能します。

仮想デバイスには `INPUT_PROP_POINTING_STICK` を設定しているため、systemd の
`input_id` が `ID_INPUT_POINTINGSTICK=1` を付与し、libinput がボタンスクロール
を既定で有効にします。

**キーボード自体は排他取得していません。** デーモンが停止してもキー入力は生き
残り、通常どおり復旧操作ができます。

### 動作要件

- libinput を使う Linux（Wayland / X11 どちらでも動作）
- `python3-evdev`
- systemd

### インストール

```sh
sudo apt install -y python3-evdev        # Debian/Ubuntu
git clone https://github.com/Aaron-Morimoto/mcanpos-keyboard.git
sudo ./mcanpos-keyboard/trackpoint-scroll/install.sh
```

既定のスクロールキーは **F19** です。変更したい場合は設定の節を参照してくだ
さい。

### 重要：中クリックのエミュレーションを無効にすること

GNOME の場合：

```sh
gsettings set org.gnome.desktop.peripherals.mouse middle-click-emulation false
```

中クリックのエミュレーションが有効だと、libinput 側のエミュレーション状態機械
が `BTN_MIDDLE` を取り込んでしまい、スクロールが動作しなくなります。左右同時
押しによる中クリックとトラックポイントのスクロールは排他で、両立できません。

中クリック（貼り付け）が必要な場合は、エミュレーションを再有効化するのではなく、
別の未使用キーに割り当ててください。

### 設定

`/etc/default/mcanpos-scroll` を編集し、
`sudo systemctl restart mcanpos-scroll` で反映します。

| 変数 | 既定値 | 意味 |
|---|---|---|
| `SCROLL_KEY` | `KEY_F19` | スクロールを起動するキー |
| `LOCK_THRESHOLD_MS` | `250` | これより短い押下はスクロール状態を継続させる |
| `DEVICE_VENDOR` | `0x04B3` | USB ベンダ ID |
| `DEVICE_PRODUCT` | `0x4609` | USB プロダクト ID |

#### スクロールキーの選び方

このキーボードには印字のないキーが多数ありますが、すべてが安全とは限りません。
デスクトップ環境が反応するかどうかは、X のキーシンボルで決まります。

| evdev コード | キー | X キーシンボル | 可否 |
|---|---|---|---|
| 189 | F19 | *(なし)* | ✅ 完全に不活性。推奨 |
| 194 | F24 | *(なし)* | ✅ 完全に不活性 |
| 184〜188 | F14〜F18 | `XF86Launch5`〜`9` | ⭕ 通常は未割当 |
| 183 | F13 | `XF86Tools` | ❌ GNOME の設定アプリが起動 |
| 191〜193 | F21〜F23 | `XF86Touchpad*` | ❌ タッチパッドの切替に割当 |
| 117 | KPEQUAL | `=` | ❌ 文字が入力される |

さらに20個のキーは、単独のキーコードではなく `Compose`+英字のマクロを送出し
ます。押下状態を表現できず、アプリケーションに文字が漏れるため使用できません。

お手元の個体でキーコードを調べるには：

```sh
sudo evtest /dev/input/eventN | grep --line-buffered EV_KEY
```

使用可能なキーは、押下で `value 1`、保持中に `value 2`、解放で `value 0` を
報告します。

### 任意：udev ルール

`99-mcanpos-pointingstick.rules` は**物理**トラックポイントをポインティング
スティックとして認識させるものです。デーモンの動作には不要ですが（仮想デバイス
が自前でポインティングスティック属性を持つため）、デーモンが動いていない状況で
ハードウェアを正しく扱わせたい場合に導入します。

```sh
sudo install -m 644 trackpoint-scroll/99-mcanpos-pointingstick.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

導入後はキーボードを抜き差ししてください。udev のプロパティはデバイスが再列挙
されるまで更新されません。

### トラブルシューティング

```sh
systemctl status mcanpos-scroll
journalctl -u mcanpos-scroll -n 30
```

正常に起動していれば、バインドしたデバイスがログに出ます。

```
pointer=/dev/input/event5 keyboard=/dev/input/event4 scroll_key=KEY_F19
```

libinput がスクロールイベントを生成できているかを確認するには、仮想デバイスの
イベントノードを調べ、スクロールキーを押しながら監視します。

```sh
sudo libinput debug-events --device /dev/input/eventN
```

`POINTER_SCROLL_CONTINUOUS` が出ていれば libinput までは正常です。それでも画面
がスクロールしない場合は、デスクトップ側で中クリックのエミュレーションが有効
なままです。

キーボードを抜くとデーモンは終了し、systemd が自動的に再起動します。デバイスは
USB ID から再特定するため、イベント番号が変わっても問題ありません。

---

## ライセンス

- コード（`trackpoint-scroll/`）— [MIT](LICENSE)
- 3Dモデル（`hardware/`）— [CC BY-SA 4.0](hardware/LICENSE)
