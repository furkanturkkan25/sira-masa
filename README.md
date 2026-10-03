# Sıra Masa

Sıra hesaplarını Mac’te düzenleyen masaüstü uygulama. Listede ad, e-posta, sınıf, son gün, seri ve puan durur. Seçilen hesapta e-posta, seri, puan ya da yeni şifre kaydedilir.

A Mac desktop app for editing Sıra accounts. The list shows name, email, grade, last day, streak, and points. The selected account can get a new email, streak, score, or password.

## Kurulum / Setup

```bash
cd SiraMasa
swiftc -O -o SiraMasa.app/Contents/MacOS/SiraMasa main.swift
codesign --force --sign - SiraMasa.app
open SiraMasa.app
```

Pencere yaklaşık 1100×680 açılır. Kayıt, Sıra’nın canlı API’sine gider.

The window opens around 1100×680. Saves go to the live Sıra API.

## Teknoloji / Stack

Uygulama **Swift** ve **AppKit** ile yazıldı. Tablo ve form `main.swift` içinde. Puan ve e-posta değişikliği yanındaki `edit.mjs` ve `score.mjs` dosyaları **Node** ile aynı birleştirme kurallarını uygular: e-posta için `emailRev`, puan için `pointRev`. Eski bir istemci yeni e-postanın üzerine yazamaz. Derlemede `-parse-as-library` kullanılmaz; program en üstte `app.run()` ile açılır.

The app is **Swift** and **AppKit**. The table and form are in `main.swift`. `edit.mjs` and `score.mjs` apply the same merge rules in **Node**: `emailRev` for email and `pointRev` for points. An older client cannot overwrite a newer email. The build does not use `-parse-as-library`; the program starts with `app.run()` at the top level.
