# Randevularim Native iOS

Bu klasor, Flutter iOS uygulamasini SwiftUI ile temiz sekilde yeniden yazmak icin baslatilan native iOS uygulamasidir.

## Hedef

- Bundle ID: `com.hasanyavuz.randevularim`
- App adi: `Randevularım`
- Minimum iOS: `16.6`
- Surum: `1.0.0 (9)`
- Tasarim dili: Flutter uygulamadaki koyu night blue tema ve profesyonel randevu yonetimi akisi

## Ilk Kapsam

- SwiftUI app iskeleti
- Ana tab yapisi
- Ana sayfa, randevular, musteriler, ayarlar ekranlari icin ilk native temel
- Flutter veri modeline denk ilk Swift modelleri:
  - `Business`
  - `Customer`
  - `Service`
  - `Appointment`
  - `AppointmentStatus`

## Sonraki Tasima Sirasi

1. SQLite v9 servis katmani
2. Musteri CRUD
3. Hizmet CRUD
4. Randevu CRUD ve cakisma kontrolu
5. Bildirim planlama
6. JSON backup/restore
7. Rehberden aktarma
8. Takvim/hafta/gun gorunumleri
9. WidgetKit
10. Live Activities
11. App Intents / Siri Shortcuts

Flutter uygulama simdilik referans uygulama olarak korunuyor. Native iOS tamamlanana kadar Android ayagi Flutter tarafinda yasamaya devam edebilir.
