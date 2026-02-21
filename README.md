# Matrix Rain

A Matrix-style falling character rain — available as a **JavaScript canvas library** and as a **native macOS screensaver**.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)

## Screenshots

![mockups](screenshots/mockups.png)

## Live previews

| Theme | Preview |
|---|---|
| Matrix | [previews/matrix.html](previews/matrix.html) |
| Rain | [previews/rain.html](previews/rain.html) |
| Snow | [previews/snow.html](previews/snow.html) |
| Hearts | [previews/hearts.html](previews/hearts.html) |
| Pac-Man | [previews/pacman.html](previews/pacman.html) |

## JavaScript Library

A lightweight, zero-dependency canvas animation engine. Drop it into any web page and configure it with a single function call.

### Usage

```html
<canvas id="matrix-rain" style="position:absolute;width:100%;height:100%"></canvas>
<script src="javascript/matrix-rain.js"></script>
<script>
    MatrixRain({
        fontSize:    14,
        fadeSpeed:   0.03,
        frameDelay:  80,
        speedMin:    0.5,
        speedMax:    2.0,
        resetChance: 0.5,
        bgColor:     '#000000',
        trailColor:  'hsl(120, 100%, 33%)',
        headColor:   'hsla(120, 100%, 95%, 1)',
        chars:       'アイウエオカキクケコ0123456789',
    });
</script>
```

### Config options

| Option | Type | Description |
|---|---|---|
| `fontSize` | number | Character size in px, also controls column width |
| `fadeSpeed` | number | Opacity of the background fill per frame (0–1); lower = longer trails |
| `frameDelay` | number | Minimum ms between frames |
| `speedMin` | number | Minimum drop speed (characters per frame) |
| `speedMax` | number | Maximum drop speed |
| `resetChance` | number | Probability per frame that a finished column resets (0–1) |
| `bgColor` | string | Background color (any CSS color) |
| `trailColor` | string | Color of trailing characters |
| `headColor` | string | Color of the leading character |
| `chars` | string | Pool of characters to draw from |

---

## macOS Screensaver

A native Swift screensaver built on the same rain effect, fully configurable from **System Settings**.

### Installation

1. Download [`MatrixSaver.zip`](screensaver/MatrixSaver.zip) and unzip it
2. Double-click `MatrixSaver.saver` — macOS will offer to install it
3. Open **System Settings → Screen Saver** and select **Matrix Rain**

> **Note:** macOS may show a Gatekeeper warning because the bundle is not notarized. If that happens, right-click `MatrixSaver.saver` and choose **Open**.

### Building from source

Requires macOS 13.0+ and Xcode Command Line Tools (`xcode-select --install`).

```sh
cd screensaver
make install     # build and install to ~/Library/Screen Savers/
make package     # build and create MatrixSaver.zip for distribution
make uninstall   # remove from ~/Library/Screen Savers/
make clean       # delete local build artifacts
```

### Configuration

Open **System Settings → Screen Saver**, select **Matrix Rain**, then click **Options**.

| Option | Description |
|---|---|
| Character Size | Font size and column width (8–24 px) |
| Rain Speed | How fast characters fall |
| Trail Length | How long the fading trail is |
| Trail Color | Color of the fading trail |
| Head Color | Color of the leading character |
| Glyphs | Character set used for the rain |

---

## Project Structure

```
javascript/
  matrix-rain.js          — canvas animation library

previews/
  matrix.html             — classic Matrix theme
  rain.html               — blue water theme
  snow.html               — white winter theme
  hearts.html             — red Valentine theme
  pacman.html             — yellow Pac-Man theme

screensaver/
  MatrixScreenSaver.swift — screensaver logic and config sheet
  Info.plist              — bundle metadata
  Makefile                — build, install, package targets
  MatrixSaver.zip         — pre-built release bundle

screenshots/              — theme screenshots
```

## How It Works

The JS library drives a `<canvas>` element: each column tracks its own drop position, speed, and character grid. Every frame a semi-transparent background fill fades old characters, creating the trail. The leading character is drawn in a brighter `headColor`.

The macOS screensaver subclasses `ScreenSaverView` and replicates the same algorithm using `NSBitmapImageRep` as an accumulation buffer. Settings are persisted via `ScreenSaverDefaults` and propagated to the running process using Darwin notifications (`CFNotificationCenter`).
