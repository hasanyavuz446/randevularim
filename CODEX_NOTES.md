# Codex Devam Notları

Bu proje `/Volumes/macprojects/Projects/randevularim` altında duran Flutter iOS randevu yönetimi uygulamasıdır.

## Mimari Yön

- Uygulama **iOS-first**. Android Flutter codebase'i ikincil olarak sürdürülüyor.
- Zaman içinde Live Activities, Home Screen Widget, Siri Shortcuts gibi derin iOS özellikleri eklenecek.
- Bu özellikler yoğunlaştığında iOS versiyonu **Swift/SwiftUI ile yeniden yazılacak**. Geçişte SQLite v9 ve backup formatı uyumluluğuna dikkat edilmeli.
- Android versiyonu Flutter olarak kalır.

## Ürün Durumu

- Uygulama adı: `Randevularım`
- Bundle ID: `com.hasanyavuz.randevularim`
- Flutter iOS deployment target: `16.6`
- Native SwiftUI iOS deployment target: `17.0`
- Güncel kaynak sürümü: `1.0.0+9`
- Veritabanı sürümü: `9`
- Tema/konsept: koyu mor/nightBlue, profesyonel randevu yönetimi

## Önemli Geçmiş

- iOS app icon ve launch screen yenilendi.
- İlk açılış onboarding eklendi.
- JSON yedek alma ve yedekten geri yükleme eklendi.
- İngilizce dil seçeneği kaldırıldı; uygulama Türkçe.
- `PrivacyInfo.xcprivacy`, privacy/support dokümanları ve App Store Connect notları eklendi.
- `file_picker` kaldırıldı, yerine `file_selector` kullanılıyor. Sebep: `file_picker` App Store Connect'te fotoğraf/kamera/konum purpose string hatalarına yol açmıştı.
- Android desteği eklendi (2026-05-28): APK derlenip GM 9 Pro'da test edildi.

## TestFlight Durumu

- App Store Connect'e yüklenen son başarılı TestFlight build: `1.0.0 (9)`.
- Build `9` yükleme tarihi: `2026-05-27`, `IN_BETA_TESTING` durumunda.
- Build `9` da aynı hatayı veriyor — sorun uygulama veya hesap yapılandırmasında değil.
- Apple Developer Support case ID: `102901090045` — güncellendi, yanıt bekleniyor.

### TestFlight Kurulum Sorunu — Kapsamlı Analiz (2026-05-27)

**Hata:** `İstenilen uygulama kullanılamıyor veya yok.` — tüm build'larda, her iki tester hesabında.

API üzerinden doğrulanan kontroller (Build 9):

| Kontrol | Sonuç |
|---|---|
| processingState | `VALID` |
| internalBuildState | `IN_BETA_TESTING` |
| externalBuildState | `NOT_APPLICABLE` |
| Minimum OS | `16.6` |
| Encryption | `false` |
| hasanyavuz446@icloud.com | `ACCEPTED` |
| hasanyavuz446@gmail.com | `ACCEPTED` |

**Eliminasyon listesi — bunların hiçbiri sorun değil:**
- `testFlightInternalTestingOnly` → `true` yapıldı, değişmedi
- `manageAppVersionAndBuildNumber` → `false` yapıldı, değişmedi
- Podfile platform → `16.6` yapıldı
- Tester davetleri, beta grubu yapılandırması
- SDK sürümü (Xcode 26.5 ile derlendi)
- Ad Hoc kurulum aynı cihazda çalışıyor

**Sonuç:** Sorun iOS 26.5 üzerindeki TestFlight altyapısında. Apple destek case yanıtı bekleniyor.

## Ad Hoc Cihaz Testi

- Gerçek cihaz: `Hasan iPhone’u (3)`, iPhone 15 Plus, iOS `26.5`
- Cihaz UDID: `00008120-000E7CA40172201E`
- Ad Hoc profile bu UDID’yi içeriyor.
- Telefona kurulan son Ad Hoc build: `1.0.0 (9)`.
- Build `7` telefona kurulduktan sonra doğrulanan düzeltmeler:
  - Arama alanlarında klavye kapanmama problemi düzeldi.
  - Müşteriler, Randevular ve Rehberden Aktar aramalarında klavye dış dokunuş/sürükleme/klavye aksiyonu ile kapanıyor.
  - Ana sayfadaki `Sıradaki Diğer Randevular` satırlarında tüm beyaz alan tıklanabilir oldu.

## Build 8 İçeriği

Bu değişiklikler kaynakta mevcut, `flutter analyze` ve `flutter test` geçti; build `8` olarak telefona kuruldu:

- Randevu detayındaki WhatsApp hatırlatma metni artık sabit `yarın` yazmıyor; gerçek randevu tarihini kullanıyor.
- Randevu bildirim modeli genişletildi:
  - Her randevuda `reminderMinutes` saklanıyor.
  - Her randevuda `startNotificationEnabled` saklanıyor.
  - Formda hatırlatma seçenekleri eklendi: `10 dk`, `15 dk`, `30 dk`, `45 dk`, `1 sa`, `2 sa`, `3 sa`, `6 sa`, `12 sa`, `1 gün`, `Manuel`.
  - Manuel seçenek dakika bazlı özel değer alıyor.
  - Ayrı `Başlangıç Bildirimi` switch'i eklendi.
  - Randevu saatindeki bildirim ayrı planlanıyor.
  - Eski sabit `Yarın Randevunuz Var` local notification planlaması kaldırıldı.
- Database migration `9` eklendi:
  - `appointments.reminder_minutes`
  - `appointments.start_notification_enabled`
- Backup version `9` yapıldı.
- Ana sayfadaki iki istatistik kartı tıklanabilir oldu:
  - `Bugün planlanan` kartı Randevular sekmesine götürür.
  - `Tamamlandı / Ciro` kartı Raporlar sekmesine götürür.

## Android Durumu

- `applicationId`: `com.hasanyavuz.randevularim`
- Test cihazı: GM 9 Pro, Android 9 (API 28)
- Son Android build: debug APK, `1.0.0+9`, 2026-05-28
- Uygulama açılıyor, ikon doğru görünüyor.
- `fast_contacts` `5.0.1`'e yükseltildi (Android Gradle Plugin uyumluluğu için).
- `Phone.number` API değişikliği `import_contacts_view.dart`'ta güncellendi.
- Core library desugaring etkinleştirildi (`flutter_local_notifications` gereksinimi).
- Android SDK: `/Users/hasanyavuz/Library/Android/sdk`
- `JAVA_HOME`: `/Applications/Android Studio.app/Contents/jbr/Contents/Home` (`.zshrc`'ye eklendi)

Android APK derlemek için:
```sh
flutter build apk --debug
```

Telefona yüklemek için (USB bağlı, MTP modunda):
```sh
adb -s e1679221869 install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Son Doğrulamalar

Son kaynak durumunda:

- `flutter test`: geçti.
- `flutter analyze`: geçti.
- 2026-05-28: `ios/Runner.xcodeproj/project.pbxproj` içindeki Runner `CURRENT_PROJECT_VERSION` değerleri `pubspec.yaml` ile uyumlu şekilde `9` yapıldı. `Info.plist` zaten `FLUTTER_BUILD_NUMBER=9` kullanıyordu.
- 2026-05-28: Temiz SwiftUI rewrite için `ios-native/` altında ayrı native iOS uygulama iskeleti başlatıldı. Bundle ID `com.hasanyavuz.randevularim`, minimum iOS `16.6`, sürüm `1.0.0 (9)`. İlk SwiftUI tab yapısı, tema, örnek ana sayfa/randevu/müşteri/ayarlar ekranları ve temel domain modelleri eklendi. `xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build` başarılı geçti.
- 2026-05-28: Native SwiftUI hedefinde minimum iOS `17.0` yapıldı ve veri katmanı SwiftData'ya taşınmaya başlandı. `Business`, `Customer`, `Service`, `Appointment` modelleri SwiftData `@Model` oldu; ekranlar `@Query` ile SwiftData verisini okuyor; ilk açılış seed akışı eklendi.

Flutter komutlarını paralel çalıştırma; startup lock nedeniyle bazen `ios/Flutter/ephemeral/Packages/.packages` silme hatası veriyor. Böyle olursa komutu tek başına yeniden çalıştır.

## Sonraki Olası Adım

Kullanıcı birkaç değişiklik daha yaptıktan sonra yeni build isteyebilir. O zaman:

1. Gerekirse build numarasını `1.0.0+10` yap.
2. `flutter analyze`
3. `flutter test`

**iOS Ad Hoc:**
```sh
flutter build ipa --release --export-method ad-hoc
xcrun devicectl device install app --device 00008120-000E7CA40172201E /private/tmp/<audit-dir>/Payload/Runner.app
xcrun devicectl device process launch --device 00008120-000E7CA40172201E com.hasanyavuz.randevularim
```

**iOS TestFlight:**
```sh
flutter build ipa --release --export-options-plist ios/ExportOptions-appstore.plist
```
`ios/ExportOptions-appstore.plist` ayarları: `testFlightInternalTestingOnly: true`, `manageAppVersionAndBuildNumber: false`, `method: app-store-connect`

TestFlight kurulumu şu an iOS 26.5 kaynaklı Apple altyapı sorunu nedeniyle çalışmıyor (case `102901090045`). Apple yanıtı gelene kadar cihaz testleri Ad Hoc ile yapılmalı.

**Android debug APK:**
```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
flutter build apk --debug
adb -s e1679221869 install -r build/app/outputs/flutter-apk/app-debug.apk
```
