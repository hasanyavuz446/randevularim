# Randevularim Native iOS

Bu klasor, Flutter iOS uygulamasini SwiftUI ile temiz sekilde yeniden yazmak icin baslatilan native iOS uygulamasidir.

## Hedef

- Bundle ID: `com.hasanyavuz.randevularim`
- App adi: `Randevularım`
- Minimum iOS: `17.0`
- Surum: `1.0.0 (13)`
- Tasarim dili: Flutter uygulamadaki koyu night blue tema ve profesyonel randevu yonetimi akisi

## Mevcut Kapsam

- SwiftUI app iskeleti
- SwiftData model container ve ilk seed akisi
- Ana tab yapisi: Bugun, Takvim, Randevular, Musteriler, Raporlar
- Ana sayfa, randevular, takvim, musteriler, raporlar ve ayarlar ekranlari
- Flutter veri modeline denk ilk Swift modelleri:
  - `Business`
  - `Customer`
  - `Service`
  - `Appointment`
  - `AppointmentStatus`
- Musteri, hizmet ve randevu CRUD akislarinin native karsiliklari
- Gun/hafta/ay takvim gorunumleri
- JSON backup/restore
- Rehberden musteri aktarma
- Local notifications
- App Intents / Siri Shortcuts
- Live Activities ve Dynamic Island
- WidgetKit extension ve App Group uzerinden canli randevu ozeti
- Tema secici, acik/koyu/otomatik gorunum modu, onboarding ve veri sifirlama

## Dogrulama

```sh
xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build
```

Son dogrulama: 2026-05-28 14:07, build basarili.

## Notlar

Flutter uygulama simdilik referans uygulama olarak korunuyor. Native iOS tamamlanana kadar Android ayagi Flutter tarafinda yasamaya devam edebilir.

App ve widget icin App Group ayni: `group.com.hasanyavuz.randevularim`. Gercek cihaz/App Store build oncesi Apple Developer tarafinda hem `com.hasanyavuz.randevularim` hem de `com.hasanyavuz.randevularim.widget` icin bu capability acik olmali.
