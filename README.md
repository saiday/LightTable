# Light Table

A macOS app that scans your Apple Photos library and shows which photos take up the most space — so you can reclaim storage.

[![Download DMG](https://img.shields.io/github/v/release/saiday/LightTable?label=Download%20DMG&style=for-the-badge)](https://github.com/saiday/LightTable/releases/latest/download/LightTable.dmg)

## Features

- Scans your Photos library and ranks photos by file size
- Visual size distribution chart
- Built-in compression shortcut — converts photos to JPEG with minimal quality loss
- Works with macOS 13+

## Install

Download the latest DMG from [Releases](https://github.com/saiday/LightTable/releases/latest).

## Build from Source

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open LightTable.xcodeproj
```
