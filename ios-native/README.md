# Randevularim Native iOS

Bu klasor, Flutter iOS uygulamasini SwiftUI ile temiz sekilde yeniden yazmak icin baslatilan native iOS uygulamasidir.

## Hedef

- Bundle ID: `com.hasanyavuz.randevularim`
- App adi: `Randevularım`
- Minimum iOS: `17.0`
- Surum: `1.0.0 (9)`
- Tasarim dili: Flutter uygulamadaki koyu night blue tema ve profesyonel randevu yonetimi akisi

## Ilk Kapsam

- SwiftUI app iskeleti
- SwiftData model container ve ilk seed akisi
- Ana tab yapisi
- Ana sayfa, randevular, musteriler, ayarlar ekranlari icin ilk native temel
- Flutter veri modeline denk ilk Swift modelleri:
  - `Business`
  - `Customer`
  - `Service`
  - `Appointment`
  - `AppointmentStatus`

## Sonraki Tasima Sirasi

1. Musteri CRUD
2. Hizmet CRUD
3. Randevu CRUD ve cakisma kontrolu
4. Bildirim planlama
5. JSON backup/restore
6. Rehberden aktarma
7. Takvim/hafta/gun gorunumleri
8. WidgetKit
9. Live Activities
10. App Intents / Siri Shortcuts

Flutter uygulama simdilik referans uygulama olarak korunuyor. Native iOS tamamlanana kadar Android ayagi Flutter tarafinda yasamaya devam edebilir.
