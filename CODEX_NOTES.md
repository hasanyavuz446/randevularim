# Codex Devam Notları

Bu proje `/Volumes/macprojects/Projects/randevularim` altında duran Flutter tabanlı randevu yönetimi uygulaması ve aynı bundle için başlatılmış native SwiftUI iOS rewrite çalışmasıdır.

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
- Flutter kaynak sürümü: `1.0.0+9`
- Native SwiftUI kaynak sürümü: `1.0.0 (13)`
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
- Native SwiftUI tarafında lokal Xcode proje build numarası `13`.
- Native upload için `ios-native/ExportOptions-upload.plist` içinde `testFlightInternalTestingOnly` yok; TestFlight-only kısıtı kaldırılmış durumda.
- Native export için `ios-native/ExportOptions-appstore.plist` içinde `testFlightInternalTestingOnly: true` hâlâ duruyor. App Store Connect'e gerçek upload hedeflenirse `ExportOptions-upload.plist` tercih edilmeli veya appstore export plist ayrıca gözden geçirilmeli.

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

- 2026-05-28 14:07: Native SwiftUI build geçti:
  `xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build`
- 2026-05-28 14:08: `flutter analyze` geçti. Sadece Flutter'ın SPM uyarısı var: `permission_handler_apple` ve `flutter_local_notifications` iOS/macOS tarafında Swift Package Manager desteklemiyor; gelecekte Flutter bunu hataya çevirebilir.
- 2026-05-28 14:08: `flutter test` geçti (`All tests passed!`, 6 test).
- 2026-05-28: `ios/Runner.xcodeproj/project.pbxproj` içindeki Runner `CURRENT_PROJECT_VERSION` değerleri `pubspec.yaml` ile uyumlu şekilde `9` yapıldı. `Info.plist` zaten `FLUTTER_BUILD_NUMBER=9` kullanıyordu.
- 2026-05-28: Temiz SwiftUI rewrite için `ios-native/` altında ayrı native iOS uygulama iskeleti başlatıldı. Bundle ID `com.hasanyavuz.randevularim`, minimum iOS `16.6`, sürüm `1.0.0 (9)`. İlk SwiftUI tab yapısı, tema, örnek ana sayfa/randevu/müşteri/ayarlar ekranları ve temel domain modelleri eklendi. `xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build` başarılı geçti.
- 2026-05-28: Native SwiftUI hedefinde minimum iOS `17.0` yapıldı ve veri katmanı SwiftData'ya taşınmaya başlandı. `Business`, `Customer`, `Service`, `Appointment` modelleri SwiftData `@Model` oldu; ekranlar `@Query` ile SwiftData verisini okuyor; ilk açılış seed akışı eklendi.
- 2026-05-28: Native SwiftUI uygulamada müşteri/hizmet/randevu CRUD akışları eklendi. Randevu formu müşteri ve hizmet seçiyor, fiyat/süre dolduruyor, çakışma uyarısı veriyor, durum ve bildirim ayarlarını düzenliyor. Takvim ve Raporlar sekmeleri eklendi; Ayarlar ana sayfa dişlisinden açılıyor. Randevu kaydında başlangıç ve hatırlatma local notification planlama, silmede notification iptali eklendi. Native build tekrar başarılı geçti.
- 2026-05-28: Native SwiftUI uygulamada ilk açılış onboarding, SwiftData JSON yedek alma/geri yükleme, rehberden müşteri importu, Siri/AppIntents shortcut'u, Live Activity altyapısı ve WidgetKit extension hedefi eklendi. Widget şu an ilk statik sürüm; canlı SwiftData verisi için sonraki adım App Group ile paylaşımlı özet verisi yazmak. `xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build` başarılı geçti.
- 2026-05-28: Widget artık statik değil. Ana SwiftUI uygulama SwiftData randevu değişikliklerini izleyip `group.com.hasanyavuz.randevularim` App Group `UserDefaults` içine bugünkü sayı, tamamlanan sayı, ciro ve sıradaki randevu özetini JSON olarak yazıyor; WidgetKit extension bu özeti okuyup küçük/orta widget tasarımında gösteriyor. App ve widget entitlements dosyaları eklendi. Gerçek cihaz/App Store build için Apple Developer tarafında aynı App Group capability'si app ve widget bundle id'lerine açılmalı. Native `xcodebuild` başarılı geçti.
- 2026-05-28: Native SwiftUI parity paketi eklendi. Randevular ekranına arama ve durum filtreleri geldi; randevu detayında teyit/tamamlandı/gelmedi/iptal hızlı işlemleri ve WhatsApp yeni randevu/hatırlatma mesajları eklendi; randevu formu çoklu hizmet seçimi, toplam süre/fiyat hesaplama ve çalışma saati uyarısı destekliyor. Müşteriler ekranına arama, müşteriden randevu oluşturma, müşteri detayında randevu geçmişi ve bağlı randevuları da silen onaylı silme akışı eklendi. Raporlar ekranı bu ay özeti, ortalama ciro, no-show, en çok gelen müşteriler ve hizmet dağılımı ile genişletildi. Native `xcodebuild` başarılı geçti.
- 2026-05-28: Native SwiftUI UX polish commitleri geldi: klavye kapatma helper'ı, settings navigation düzeltmesi, calendar scroll iyileştirmesi, durum renkleri ve istatistik period selector için sistem segmented picker. Native build numarası `13` yapıldı.
- 2026-05-28: Native Ayarlar > Hizmetler akışında hizmet düzenleme ekranına girince ana ekrana dönme hatası düzeltildi. Sebep `SettingsView.onDisappear` içinde `themeVersion += 1` ile `ContentView` içindeki `MainTabsView().id(themeVersion)` mekanizmasının navigation push sırasında tüm tab ağacını yeniden yaratmasıydı. `themeVersion` reset mekanizması kaldırıldı. Native `xcodebuild` başarılı geçti.
- 2026-05-28: Native tema/açık-koyu mod Flutter referansına göre yenilendi. `ThemeConfig` artık Flutter'daki `lightBg`, `darkBg`, `darkSurface` mantığına denk çalışıyor; `auto` görünüm modu gerçek sistem `ColorScheme` değerini kullanıyor; ortak metin renkleri `textPrimary/textSecondary` olarak adaptif hale getirildi; Ayarlar > Görünüm bölümü ikonlu açık/koyu/otomatik kartları ve gradient tema swatch'larıyla yeniden tasarlandı. Native smoke build geçti, Ad Hoc export `/private/tmp/RandevularimNativeAdHocExport_20260528_1420_auto/Randevularim.ipa` olarak alındı ve `Hasan iPhone’u (3)` cihazına yüklenip launch edildi.
- 2026-05-28: Açık modda Takvim ve Raporlar ekranlarında koyu kalan sistem segment/yüzey hissi düzeltildi. Native `Picker(.segmented)` yerine tema renkleriyle çizilen `ThemeSegmentedControl` eklendi; Takvim'deki kalan `.primary` metin renkleri `AppTheme.textPrimary` yapıldı. Yeni Ad Hoc export `/private/tmp/RandevularimNativeAdHocExport_20260528_1424/Randevularim.ipa` olarak alındı, cihaza yüklendi ve launch edildi.
- 2026-05-28: Native açık/koyu mod ve tema seçimlerinin bazı ekranlarda sayfa değiştirene kadar eski renkte kalması düzeltildi. `themeRevision` AppStorage sinyali eklendi; `ContentView` tema/mod değişiminde `AppTheme.apply` sonrası revision artırıyor, ana tab ekranları bu değeri okuyarak body'lerini anında yeniden hesaplıyor. Ayarlar'daki görünüm ve tema seçimleri de aynı helper üzerinden anında uygulanıyor. Native smoke build geçti; yeni Ad Hoc export `/private/tmp/RandevularimNativeAdHocExport_20260528_1429/Randevularim.ipa` olarak alındı, `Hasan iPhone’u (3)` cihazına yüklendi ve launch edildi.
- 2026-05-28: Tema/mod geçişinde bazı `List`, `NavigationStack`, `TabView`, toolbar ve sistem segment yüzeylerinin uygulama yeniden açılana kadar eski renkte kalması için daha kapsamlı runtime refresh eklendi. `RandevularimApp` ve `RandevularimScreen` yalnızca `themeRevision` değişince yeniden kimlikleniyor; `AppTheme.apply` artık UIKit appearance değerlerini (`UITableView`, `UINavigationBar`, `UITabBar`, `UISegmentedControl`, window style/tint/background) runtime'da güncelliyor. Randevular filtresindeki kalan sistem segmented picker da `ThemeSegmentedControl` yapıldı. Smoke build, Release archive ve Ad Hoc export geçti; yeni IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1435/Randevularim.ipa` olarak cihaza yüklendi ve launch edildi.
- 2026-05-28: Native Ayarlar ekranının en altına `Sıfırlama` bölümü eklendi. Sıralama: `Kayıtlı Tüm Müşterileri Sil`, `Geçmiş Tüm Randevuları Sil`, en altta `Tüm Verileri Sıfırla`. Müşteri silme işlemi tüm müşterileri ve bağlı randevuları siler; geçmiş randevu silme işlemi sadece `dateTime < now` olan randevuları siler; ikisi de bildirimleri iptal eder ve onay dialogu kullanır. Smoke build, Release archive ve Ad Hoc export geçti; yeni IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1441/Randevularim.ipa` olarak cihaza yüklendi ve launch edildi.
- 2026-05-28: Native uyarı/onay kutularının üstte popover gibi açılması düzeltildi. Projedeki kalan `confirmationDialog` kullanımları kaldırıldı; Ayarlar sıfırlama onayları ve WhatsApp mesaj tipi seçimi `alert` yapısına taşındı, böylece kutular ekran ortasında açılıyor. Smoke build, Release archive ve Ad Hoc export geçti; yeni IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1444/Randevularim.ipa` olarak cihaza yüklendi ve launch edildi.
- 2026-05-28: Veri sıfırlama veya mod değişimi sonrası tema/modun yarım uygulanması ve bazen beyaz ekranda kalması düzeltildi. Sebep `themeRevision` değişiminde `WindowGroup/ContentView` ve `RandevularimScreen` ağacının `.id(...)` ile yeniden yaratılmasıydı; SwiftData/List/Tab state ile çakışınca bazı yüzeyler eski, bazıları yeni palette kalıyordu. Kök yeniden yaratma kaldırıldı; UIKit repaint mevcut view ağacı üzerinde `UITableView`, `UICollectionView`, `UINavigationBar`, `UITabBar`, window style/tint/background güncellenerek yapılıyor. Smoke build, Release archive ve Ad Hoc export geçti; yeni IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1448/Randevularim.ipa` olarak cihaza yüklendi ve launch edildi.

Flutter komutlarını paralel çalıştırma; startup lock nedeniyle bazen `ios/Flutter/ephemeral/Packages/.packages` silme hatası veriyor. Böyle olursa komutu tek başına yeniden çalıştır.

- 2026-05-28: Release hazırlık düzeltmeleri yapıldı (build 14): PrivacyInfo.xcprivacy eklendi (UserDefaults CA92.1), 3 yerde `tel://` force-unwrap crash koruması eklendi, CustomerDetailView WhatsApp URL `wa.me` formatına taşındı, iPhone Landscape yönü kaldırıldı (sadece Portrait), Release config'deki yazım hatası düzeltildi (duyulmaktadır), StatisticsView Divider hardcoded white → AppTheme.divider, Ayarlar'a uygulama versiyon bilgisi eklendi. Archive + Ad Hoc IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1527/Randevularim.ipa` olarak cihaza yüklendi.
- 2026-05-28: Tema/mod değişiminde bazı view'ların (List satırları, sheet'ler, push'lanmış ekranlar) güncellenmemesi kökten düzeltildi. `AppTheme` static var'ları artık `@Observable final class ThemeValues` singleton'ına yönlendiren computed property. SwiftUI, view body'si çalışırken her `AppTheme.*` erişimini otomatik kayıt altına alır ve değişince o view'ı doğrudan yeniler — eski `themeRevision` / `@AppStorage` hack'i tamamen kaldırıldı. Smoke build, Release archive ve Ad Hoc export geçti; yeni IPA `/private/tmp/RandevularimNativeAdHocExport_20260528_1506/Randevularim.ipa` olarak cihaza yüklendi ve launch edildi.

## Native iOS Özellik Durumu (2026-05-28)

Flutter parity + üzeri tamamlandı:
- **Takvim**: Gün (saatlik timeline), Hafta (7-gün agenda), Ay (ızgara) görünümleri; Bugün butonu
- **Tekrarlayan randevular**: Form'da 4/8/12 hafta seçeneği; her hafta için ayrı Appointment nesnesi oluşturuluyor
- **WhatsApp şablonları**: İşletme adı, Türkçe tarih, `wa.me` URL'si; Yeni Randevu ve Hatırlatma şablonları
- **İstatistik period filtresi**: Bugün/Bu Hafta/Bu Ay segmenti; randevu sayısı + ciro filtreli
- **Global bildirim ayarları**: Ayarlar'da toggle + varsayılan hatırlatma süresi (AppStorage)
- **Live Activity**: Otomatik tetikleme — uygulama açıkken her 60 sn + `didBecomeActive`'de kontrol; randevu saati gelince başlar, biter/iptal olunca kapanır; Dynamic Island destekli
- **Uygulama ikonları**: Assets.xcassets eklendi
- **Tema seçici**: Ayarlar'da 8 tema (Flutter eşdeğeri renk paleti); anında uygulama
- **Açık/Koyu/Otomatik mod**: Açık modda iOS sistem arka plan renkleri; Koyu'da tema hex renkleri
- **Hero Card (Ana Sayfa)**: Sıradaki aktif randevu büyük gradient kartta; telefon + WhatsApp aksiyonları
- **Müşteri arama (Randevu Formu)**: Picker yerine arama + filtreleme sheet'i
- **Hizmet seçimi iyileştirmesi**: Müşteri ve hizmet sekmeleri ayrı; satırın tamamı tıklanabilir
- **Hizmet yönetimi**: Ayarlar'dan ayrı sayfada sürükle-sırala + düzenle
- **Rehberden aktarma**: İzin durumu kontrolü; reddedildiyse Ayarlar'a deeplink
- **Demo veri kaldırıldı**: İlk açılışta sahte müşteri/randevu yok; sadece işletme + 6 varsayılan hizmet
- **Veri sıfırlama**: Ayarlar'da "Tüm Verileri Sıfırla" butonu (onay dialoglu)

### Karşılaştırma Kurulumu (Geçici)
- `com.hasanyavuz.randevularim` → Native SwiftUI "Randevularım" (son build)
- `com.hasanyavuz.randevularimold` → Flutter "oldRandevularım" (karşılaştırma amaçlı)
- `com.hasanyavuz.randevularim2` → Silinebilir (eski test build)

## Sonraki Olası Adım

Kullanıcı birkaç değişiklik daha yaptıktan sonra yeni build isteyebilir. O zaman:

1. Hangi hedefin build edileceğini netleştir: Flutter (`pubspec.yaml` şu an `1.0.0+9`) veya native SwiftUI (`ios-native` şu an `1.0.0 (13)`).
2. Flutter değişikliği varsa `flutter analyze` ve `flutter test` çalıştır.
3. Native değişikliği varsa aşağıdaki `xcodebuild` smoke build'i çalıştır.

**Native SwiftUI smoke build:**
```sh
xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/randevularim_native_derived CODE_SIGNING_ALLOWED=NO build
```

**Native SwiftUI upload/export:**
```sh
xcodebuild -project ios-native/Randevularim.xcodeproj -scheme Randevularim -configuration Release -destination 'generic/platform=iOS' -archivePath /private/tmp/RandevularimNative.xcarchive archive
xcodebuild -exportArchive -archivePath /private/tmp/RandevularimNative.xcarchive -exportPath /private/tmp/RandevularimNativeUpload -exportOptionsPlist ios-native/ExportOptions-upload.plist
```

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
