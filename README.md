# Light Table

Light Table scans your Photos library and shows which photos take up the most space — sorted by size, finally — so you can reclaim storage on both your Mac and iCloud.

I built this app for myself.

[![Download DMG](https://img.shields.io/github/v/release/saiday/LightTable?label=Download%20DMG&style=for-the-badge)](https://github.com/saiday/LightTable/releases/latest/download/LightTable.dmg)

<p align="center">
  <img src="docs/screenshots/main.png" width="600" alt="Light Table main window" />
</p>

<p align="center">
  <img src="docs/screenshots/albums-created.png" width="600" alt="Albums created with compression shortcut" />
</p>

## Install

Download the latest DMG from [Releases](https://github.com/saiday/LightTable/releases/latest).

## Build from Source

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open LightTable.xcodeproj
```
