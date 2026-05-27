# App Store Connect Yayın Bilgileri

## Mevcut Build

- Uygulama adı: Randevularım
- Bundle identifier: `com.hasanyavuz.randevularim`
- Sürüm: `1.0.0`
- Build: `8`
- Minimum iOS: `16.6`

## App Privacy Yanıtları

Mevcut uygulama davranışına göre App Store Connect'te `Data Not Collected` seçilebilir:

- Müşteri, randevu ve işletme kayıtları yalnız cihaz üzerinde tutulur.
- Rehber erişimi, kullanıcının başlattığı içe aktarma için cihazda kullanılır.
- Yedek dosyası yalnız kullanıcının seçtiği paylaşım hedeflerine gönderilir.
- Analiz, reklam, tracking veya geliştirici sunucusuna aktarım bulunmaz.

Bu beyan, ileride analytics, crash reporting, bulut yedekleme veya hesap sistemi eklenirse yeniden değerlendirilmelidir.

## TestFlight Kabul Kontrolü

- Temiz kurulumda splash sonrası onboarding görülür.
- `Başla` sonrasında ana sayfa açılır ve ikinci açılışta onboarding tekrarlanmaz.
- Yeni müşteri ve randevu kaydedilebilir.
- Bildirim izni onboarding tamamlandıktan sonra istenir.
- JSON yedeği oluşturulur, silinen örnek kayıt geri yüklemeyle döner.
- Rehber izni reddedildiğinde uygulama kapanmaz.

## App Store Öncesi Dış İşlemler

- `docs/privacy-policy.md` içeriğini herkese açık bir URL'de yayınlayıp Privacy Policy URL alanına girin.
- `docs/support.md` içeriğini herkese açık bir URL'de yayınlayıp Support URL alanına girin.
- Destek e-posta adresini iki sayfaya ekleyin.
- TestFlight build `8` cihaz kabul kontrolü tamamlandıktan sonra incelemeye gönderin.
