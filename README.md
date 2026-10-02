# Sıra Masa

Sıra hesaplarının e-posta, seri ve puanını düzenleyen Mac uygulaması.

```bash
cd SiraMasa
swiftc -O -o SiraMasa.app/Contents/MacOS/SiraMasa main.swift
codesign --force --sign - SiraMasa.app
open SiraMasa.app
```
