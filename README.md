# Sıra Masa

Sıra hesaplarını Mac’te düzenleyen masaüstü uygulama. Listede ad, e-posta, sınıf, son gün, seri ve puan durur. Seçilen hesapta e-posta, seri, puan ya da yeni şifre kaydedilir.

## Kurulum

```bash
cd SiraMasa
swiftc -O -o SiraMasa.app/Contents/MacOS/SiraMasa main.swift
codesign --force --sign - SiraMasa.app
open SiraMasa.app
```

Pencere yaklaşık 1100×680 açılır. Kayıt, Sıra’nın canlı API’sine gider.

## Nasıl kuruldu

Uygulama **Swift** ve **AppKit** ile yazıldı. Tablo ve form `main.swift` içinde. Puan ve e-posta değişikliği yanındaki `edit.mjs` / `score.mjs` dosyaları **Node** ile aynı birleştirme kurallarını uygular: e-posta için `emailRev`, puan için `pointRev`. Böylece eski bir istemci yeni e-postanın üzerine yazamaz.

Derleme bayrağı olarak `-parse-as-library` kullanılmaz; program en üstte `app.run()` ile açılır.
