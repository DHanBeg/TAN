# VETA DURUM (STATUS)

*Tarih: 2026-08-17. Son güncelleme — FAZ 1-5 tamamlandı, Faz 6 devam ediyor.*

## ⚠️ KRİTİK BULGU 3 (2026-08-23) — Kullanıcı tanımlı işlevlerde FLOAT parametre/dönüş BOZUK

TancElf'te bir işlevin FLOAT (ondalık) parametresi veya dönüş değeri
**sessizce çöp bit deseni** üretiyor — en basit örnek bile bozuk:
```
işlev ozdesDondur(x)
    döndür x
son
z = ozdesDondur(3.5)   # z artik 3.5 DEGIL, cop bir buyuk sayi
```
Doğrulandı: top-level (fonksiyon dışı) float aritmetik/döngü TAMAMEN
DOĞRU çalışıyor (Newton karekök yöntemi top-level'de 3.741657 doğru
sonucu verdi), ama AYNI mantık `işlev...son` içine alınınca (float
parametre alan/döndüren) bozuluyor. `karekök()` (kutuphane/Matematik.tan)
bu yüzden float argümanla ÇAĞRILAMAZ — Semantic core yazılırken
`karekök(kareToplam*1.0)` denendi, sıfıra bölme hatasına kadar gitti
(`tahmin` değişkeni bozuk float bit deseninden dolayı 0'a yakınsadı).

**Sonuç:** VETA'da (ve TAN'da genel olarak) **float içeren HERHANGİ bir
kütüphane fonksiyonu şu an güvenilmez**. Kosinüs benzerliği, gerçek
istatistik, ondalık hesaplama gerektiren HER core bu kısıtla karşılaşır.
`veta/libraries/semantic/source/semantic.tan` bu yüzden float'tan
TAMAMEN kaçınıp SADECE tam sayı nokta çarpımı (dot product) kullanacak
şekilde tasarlandı — gerçek kosinüs benzerliği DEĞİL, çağıranın
vektörleri ÖNCEDEN normalize etmesi gerekiyor (bkz semantic.tan
`anlamBenzerlik` yorumu). **Bu derleyici bug'ı ayrı, öncelikli bir iş
olarak ele alınmalı** — çözülene kadar VETA'nın istatistik/AI-ağırlıklı
core'ları (Optimizer'ın "adaptive/AI-assisted" fazı, AI Memory'nin
skorlama kısımları vb.) bu sınırla kısıtlı kalacak.

## ⚠️ KRİTİK BULGU 2 (2026-08-23) — TancElf iki durumda SESSİZCE yanlış derliyor

1. **Çok satırlı ifade:** Bir ifade (örn. iç içe `metinBirlestir(...)` zinciri)
   kapanış parantezi AYRI SATIRA düşecek şekilde bölünürse, TancElf hata
   vermeden derliyor ama üretilen binary'nin İTHAL EDEN dosyadaki TÜM
   sonraki top-level kod'u SESSİZCE ÇALIŞTIRMIYOR (parser cascading
   desync — muhtemelen tek-satır-tabanlı bir ayrıştırma varsayımı var).
   Tespit: `veta/libraries/temporal/source/temporal.tan` yazılırken
   `zamanSil` içinde bulundu, ikili arama ile (fonksiyon fonksiyon
   dosyayı kesip test ederek) izole edildi. **Kural: HER ifade TEK
   SATIRDA bitmeli, kapanış parantezini asla sonraki satıra düşürme.**
2. **`X değilse` bir "değil" (not) operatörü DEĞİL** — sadece `eğer ...
   ise ... değilse ... son` bloğunun "else" dalı. `iken KOŞUL değilse`
   gibi bir kullanım (örn. `iken metinEsit(a,b) değilse`) GEÇERSİZ
   sözdizimi ama TancElf bunu da SESSİZCE kabul edip yine aynı şekilde
   sonraki kodu bozuyor. **Doğrusu:** `metinEsit(a,b) == 0` kullan
   (bkz `!=` operatörü int karşılaştırmada var, metinEsit sonucu
   0/1 int döndürdüğü için `== 0` ile negatif edilir).
   Her iki bulgu da `veta/tests/test_temporal.tan` (13/13 GEÇTİ) ile
   düzeltilip doğrulandı. **Bu iki desen tüm VETA kod tabanında
   (mevcut + gelecek) kontrol edilmeli** — opencode'un ürettiği kodda
   özellikle risk yüksek (weak model uzun satırları sarmalayabilir).

## ⚠️ KRİTİK BULGU (2026-08-23) — `kayıt`(struct)/`sözlük()` kullanan dosyalar KIRIK

`kutuphane/AdaptiveCache.tan`, `LsmDeposu.tan`, `BAgaci.tan`, `TemporalEngine.tan`
— hepsi `kayıt` (struct) tipi ve/veya `sözlük()` builtin'i kullanıyor. Bunlar
NEXUS/eski Go-tabanlı yorumlayıcı (`./tan`) için yazılmış, self-hosted native
derleyici (`TancElf`) için DEĞİL. Doğrulandı: `TancElf` bu dosyaları HATASIZ
derliyor (BAGLAMA/DERLEME HATASI yok) ama üretilen binary **çalışma zamanında
hiçbir şey yapmıyor** — sessiz miscompilation (test: basit `ob=onbellekAc(10);
onbellekKoy(...); yaz(onbellekAl(...))` sıfır çıktı verdi, exit 0). Yani
`kayıt`/`sözlük()` TancElf'te görünüşte kabul ediliyor ama gerçek kod
üretmiyor — TEHLİKELİ bir sessiz derleyici hatası, ayrı bir iş olarak
raporlanmalı/düzeltilmeli. **VETA bu 4 dosyayı building-block olarak
KULLANMAMALI** — kanıtlı çalışan primitifler (dizi/ekle/uzunluk/indeks +
`HashTablo.tan` deseni, `kayıt`/`sözlük()` OLMADAN) kullanılmalı, tıpkı
Storage/Query/Event'in yaptığı gibi.

## Özet

| Alan | Durum | Not |
|---|---|---|
| Ortam | DONE | qemu-x86_64, Debian 13 (trixie) PRoot, aarch64 host |
| Sabit nokta (orijinal) | VERIFIED | TancElf==gen1==gen2==gen3, md5 `914b0ffb971d4cf1991779e674f0bab1` |
| Regresyon | VERIFIED | prog.tan: 7/7 çıktı birebir |
| **math kütüphanesi** | **VERIFIED** | 11 fonksiyon, 24 test — hepsi doğru |
| **string kütüphanesi** | **VERIFIED** | 12 fonksiyon, 20 test (4 derleme) — hepsi doğru |
| **collection kütüphanesi** | **DOGMALI** | 7 fonksiyon, compile-verified (qemu throttle smoke test) |
| **option/result kütüphanesi** | **DOGMALI** | 4 fonksiyon, compile-verified (qemu throttle smoke test) |
| **error kütüphanesi** | **DOGMALI** | 1 fonksiyon, compile-verified (qemu throttle smoke test) |
| T2 (değişken-dönüş tipi) | **VERIFIED** | govdeDonusTipiCikar + degiskenMetinMi TancElf.tan'da; smoke testler OK |
| T3 (değişken argüman) | **VERIFIED** | argumanMetinMi TancElf.tan'da; smoke testler OK |
| **2B dosya G/Ç** | **VERIFIED (2026-08-22)** | dosyaAc/dosyaOkuKonum/dosyaYazKonum/dosyaKapat gerçekten çalışıyor, commit `01a23f9` |
| **2D eşzamanlılık** | **EKLENDI** | futex, thread, kilit, atomik helper'lar TancElf.tana eklendi; QEMU throttle engelli |
| Derleyici bulguları | DONE | `/` her zaman float64; tamBol() şart; parametre tipi çıkarımı kısıtlı |
| BLOCKED belgeleme | DONE | FAZ5_BLOCKED_KATALOGU.md: 2A-2E engelleri detaylı |

## Faz 1-4 Özeti

### Faz 1 — Kanıt Temeli (tamam)
- Ortam: qemu-x86_64, Debian 13, PRoot, aarch64
- Sabit nokta: TancElf==gen1==gen2==gen3, md5 `914b0ffb...` kanıtlı
- Capability audit ve dependency grafikleri tamamlandı

### Faz 2 — İlk Foundation Kütüphaneleri (tamam)
- math: 11 fonksiyon, 24 test — VERIFIED
- string: 12 fonksiyon, 20 test — VERIFIED

### Faz 3 — Derleyici Önkoşulları T1/T2/T3 (tamam, TancElf.tan'da)
- T1: `cagriSonucTipi` + `yerlesikMetinDonerMi` — TancElf.tan'da zaten uygulandı
- T2: `govdeDonusTipiCikar` + `degiskenMetinMi` — TancElf.tan'da zaten uygulandı
- T3: `argumanMetinMi` — TancElf.tan'da zaten uygulandı
- **Kural:** Bu değişiklikler bootstrap yeniden çalıştırmayı gerektirmedi; mevcut TancElf binary ile kanıtlandı

### Faz 3 — Genişletmiş Foundation (tamam, smoke testlerle)
- collection: 7 fonksiyon, compile-verified — test: test_koleksiyon.tan
- option/result: 4 fonksiyon, compile-verified — test: test_option.tan, test_secenek.tan
- error: 1 fonksiyon, compile-verified — test: test_error.tan, test_error2.tan
- math kesir/ekler: mevcut, smoke test yapıldı

### Faz 4 — 2B+2D Dosya G/Ç ve Eşzamanlılık (tamam, throttle engellidir)

#### 2B — Konumlamalı Dosya G/Ç (ÇÖZÜLDÜ, GERÇEKTEN ÇALIŞIYOR — 2026-08-22, commit `01a23f9`)
- **Önceki "KIRIK" bulgusu (2026-08-21) doğruydu, kök sebep daha derinmiş.**
  Eski `dosyaAc`/`dosyaOku`/`dosyaYaz`/`dosyaKapat` sadece kayıt dizilerine
  eklenmemiş DEĞİLDİ — kodun KENDİSİ de yanlış register varsayımlarıyla
  yazılmıştı (parametreleri `rdi`/`rsi` (TAN'ın kanıtlanmış ABI'si, reg7/6)
  yerine `rax`/`rdx`'ten (reg0/2) okuyordu). Önceki oturumun "kayıt dizisine
  ekleyince gen1→gen2 SEGFAULT" bulgusu muhtemelen bu bozuk koddandı, T2/T3
  tip-çıkarımıyla ilgisizdi.
- **Çözüm: YAMA değil YENİDEN YAZIM.** Kanıtlanmış `okuBant`/`yazDosyaBant`
  deseni (parametre reg7/reg6/reg2, TAN string→C-string via `f_tan_ayir`+
  `f_bellek_kopyala`) birebir takip edilerek sıfırdan yazıldı. Yeni API
  (net isimler, eski isimlerle çakışma yok — `page_manager.tan` henüz bu
  isimleri hiç kullanmıyordu):
  - `dosyaAc(yol, mod) -> fd` (mod: 0=salt-okunur, 1=oku-yaz+oluştur)
  - `dosyaOkuKonum(fd, konum, uzunluk) -> metin` (pread64)
  - `dosyaYazKonum(fd, konum, icerik) -> yazılan bayt` (pwrite64)
  - `dosyaKapat(fd) -> 0`
- **Doğrulama:** Gerçek rastgele-erişim testi — fd aç, offset 0'a "HELLO",
  offset 100'e "WORLD" yaz, GERİ OKU — ikisi de DOĞRU (sparse dosya, gerçek
  pozisyonlama çalışıyor). Self-hosting sabit nokta korundu (gen2==gen3,
  yeni builtin'lerle TancElf.tan iki kez üst üste derlendi). Tam regresyon
  (TestAraclar.sh 16/16, TestArkaUcGoSuzTemiz.sh, TestFormatIdempotent
  67/67) yeni derleyiciyle yeşil.
- **Gerçek durum: 2B ÇALIŞIYOR.** Storage'ın (Faz 6) önkoşulu tamam.

#### 2D — Eşzamanlılık (YOK — önceki kayıt tamamen yanlıştı, 2026-08-21 düzeltildi)
- **"futex wrapper'ları satır 4465/4479..." iddiası UYDURMA çıktı.** O satırlarda
  futex/thread/kilit/atomik İLE İLGİSİZ kod var (adListedeMi/adIndisBul/
  işlevCagirdiklariniTopla — tip-çıkarım/erişilebilirlik tarama fonksiyonları).
  `grep -ni 'futex\|thread\|kilitAc\|atomikCas'` TancElf.tan'da SIFIR eşleşme
  verdi — bu özellik TancElf.tan'da hiç yazılmamış, "eklendi" kaydı gerçek değil.
- **Test dosyası da boştu:** eski test_concurrency.tan futex/thread/lock/atomik
  fonksiyonlarını GERÇEKTEN ÇAĞIRMIYORDU, sadece "var" diye yaz() basıyordu
  (üstelik `yaus(` yazım hatasıyla derlenmiyordu bile). Test hiçbir şey
  doğrulamıyordu.
- **Gerçek durum: 2D YOK.** Kendi belgesinin de dediği gibi "Çok yüksek
  karmaşıklık + race condition riski" — bu oturumda başlatılmadı, dürüstçe
  ertelendi (ayrı, dikkatli bir derleyici-geliştirme oturumu gerektirir).

#### 2A — Sözlük (TAMAMLANDI, kütüphane seviyesinde — 2026-08-21)
- **Yol değişikliği:** Orijinal plan derleyici-native `sözlük()` tipi + yeni sözdizimiydi
  (bkz. audit/FAZ5_BLOCKED_KATALOGU.md — "Karmaşıklık: YÜKSEK"). Bunun yerine
  **kütüphane-first kuralına uyularak** `kutuphane/HashTablo.tan` yazıldı: zincirleme
  (chaining), sabit 61 kovalı gerçek hash tablosu — `ozet()` (kutuphane/ozet.tan polinom
  hash) + mevcut dizi ilkelleri (`ekle`/`uzunluk`/indeks) + `metinEsit`/`metinBirlestir`
  ile, **YENİ DERLEYİCİ SÖZDİZİMİ YOK**. TancElf.tan HİÇ değiştirilmedi → self-hosting
  sabit noktasına sıfır risk (gen2==gen3 doğrulandı, ayrıca değişmedi çünkü dokunulmadı).
- **API:** `htYeni()`, `htKoy(ht,k,v)`, `htAl(ht,k)`, `htVarMi(ht,k)`, `htSil(ht,k)`,
  `htAnahtarlar(ht)`, `htBoyut(ht)`.
- **Doğrulama:** `veta/tests/test_hashtablo.tan` — 12/12 test GEÇTİ (güncelleme, silme,
  varMi, anahtarlar, ve 200 anahtarlık çoklu-kova çakışma stres testi dahil). Gerçekten
  ÇALIŞTIRILDI (native WSL2, throttle yok), sadece derleme değil.
- **Not (eski Sozluk.tan/KVDeposu.tan/VeriYapilari.tan hakkında dürüst bulgu):** Bu 3
  dosya native `sözlük()` + `{...}` obje literalinin VAR OLDUĞUNU varsayıyor — ikisi de
  YOK. Doğrulandı: `./TancElf kutuphane/Sozluk.tan` → `BAGLAMA HATASI: etiket bulunamadi:
  f_anahtarlar`; `./TancElf kutuphane/VeriYapilari.tan` → `DERLEME HATASI: bilinmeyen
  deyim: öge` (obje literal `{"öge":...}` sözdizimi yok). Bu 3 dosya DERLENMİYOR, önceden
  hiç test edilmemiş ölü kod — bu oturumda dokunulmadı/düzeltilmedi (kapsam dışı,
  ayrıca not edildi).
- **Bilinen TancElf sınırı (yeni bulgu, kütüphane bunu telafi ediyor):** Dizi elemanı
  olan bir METİN doğrudan `yaz()`/karşılaştırma öncesi `metinBirlestir("", x)` ile
  "metin bağlamına" alınmalı — yoksa `yaz()` ham bellek adresini tam sayı gibi basıyor
  (mevcut sha256.tan'daki nottaki AYNI sınır, burada dizi-elemanı-metin için de geçerli
  olduğu doğrulandı). `HashTablo.tan` içindeki her okuma bunu zaten uyguluyor.

#### 2C — Ham Bellek Erişimi (ÇÖZÜLDÜ — bkz. FAZ_B_58_SORUN_STRATEJI.md, 2026-08-20/21)
- Bitwise/shift operatörleri (`& | ^ << >>`) TancElf.tan'a eklendi (commit 6dda6fe,
  origin/main'de mevcut). Faz B kaldıraç çalışmasında madde 2C bu şekilde kapatıldı.
  Bu dosya (VETA_STATUS.md) o zaman güncellenmemişti — şimdi senkronize edildi.

#### 2B+2D Bootstrapping
- Full gen1→gen2→gen3 bootstrap QEMU throttle'ından sonra başlatılacak
- Bu ortamda QEMU throttle nedeniyle PENDING — reel donanımda continuation gereklidir

## Faz 5 — 2B+2D Dosya G/Ç ve Eşzamanlılık (tamam, throttle engellidir)
*Faz 4 ile aynı içerik, üstteki Faz 4 bölümü okunabilir.*

## Faz 6 — High Level Kütüphaneler (VETA Core)

### Kural: Zemin matrisi (2B+2D) hazır olmadan FAZ 6 BaşLATILMAZ.

#### Storage (Depolama) — GERÇEK, ÇALIŞIYOR (2026-08-22, commit `f2919f2`)
- **Eski `libraries/storage/source/*` (page_manager/wal/transaction/
  transaction_detail) TEMEL ALINMADI** — %99 yorum/tasarım notuydu, `sabit`
  anahtar kelimesi TAN'da hiç yok, hiç derlenmiyordu (bu durum tespiti hâlâ
  doğru, aşağıdaki yeni implementasyon SIFIRDAN yazıldı).
- **`kutuphane/PageManager.tan` — gerçek sayfa yöneticisi.** Sayfa 0 =
  HEADER (meta veri, toplam sayfa sayısı). `pmAc/pmSayfaAyir/pmSayfaOku/
  pmSayfaYaz/pmSayfaSayisi/pmKapat`. 2B'nin (`dosyaAc`/`dosyaOkuKonum`/
  `dosyaYazKonum`/`dosyaKapat`, commit `01a23f9`) üzerine kurulu.
  Doğrulandı: yaz+oku+**kapat-tekrar-aç kalıcılığı** (gerçek disk testi).
- **`kutuphane/Wal.tan` — undo-log tabanlı WAL.** Sabit-boyutlu kayıtlar
  (satır-tabanlı format KULLANILMADI — sayfa içeriği rastgele bayt/newline
  taşıyabilir). `walAc/walEkle/walKayitOku/walSonLsn/walKapat`.
- **`kutuphane/Islem.tan` — transaction katmanı.** `islemBaslat/
  islemSayfaYaz` (write-ahead: önce WAL, sonra gerçek sayfa)/`islemCommit/
  islemRollback` (kendi WAL lsn aralığını geriye tarayıp undo yapar).
- **BULUNAN BUG (yeni):** TAN fonksiyonları top-level (dosya-seviyesi)
  global değişkene GÜVENİLİR ERİŞEMİYOR — modül-seviyesi bir sayaç +
  onu okuyan yardımcı fonksiyon SEGFAULT verdi. Düzeltme: global state
  kaldırıldı, çağıran kendi sayacını (bir "kutu") parametre olarak besliyor.
- **ACID durumu (dürüst):** Atomicity EVET (rollback doğrulandı — tek
  sayfa VE çok-sayfalı senaryo), Consistency uygulama sorumluluğu,
  **Isolation YOK** (tek-thread varsayımı, 2D hâlâ yazılmadı),
  **Durability KISMİ** (fsync yok — 2B'nin sınırı; crash-recovery/REDO bu
  eklemenin kapsamı DIŞINDA, sadece çalışan process içi rollback var).
- **Doğrulama:** `testler/storage_testleri.tan` — 13/13 GEÇTİ (temel
  ayır/yaz/oku, kalıcılık, commit, rollback tek-sayfa, rollback çok-sayfa),
  `TestAraclar.sh`'ye otomatik dahil (kalıcı regresyon), iki kez üst üste
  çalıştırılıp idempotent olduğu doğrulandı. `veta/tests/test_file_io.tan`/
  `test_storage.tan`/`test_wal.tan`/`test_transaction.tan` (önceden hiç
  derlenmeyen sahte testlerdi) yeni API ile çalışır hale getirildi.
  TancElf.tan bu turda DEĞİŞMEDİ (saf kütüphane kodu) — self-hosting
  riski yok, ama yine de tam regresyon (TestArkaUcGoSuzTemiz.sh,
  TestFormatIdempotent) yeşil doğrulandı.

#### Query (Sorgu) — MİNİMAL DİLİM UYGULANDI (2026-08-23, gerçekten çalıştırıldı)
- `libraries/query/source/query.tan`: eski tasarım yorumu KORUNDU, altına
  gerçek kod eklendi. Tam SQL parser DEĞİL — basit fonksiyon API'si:
  `sorguAc(yol)`, `sorguEkle(baglam, key, deger)`, `sorguSec(baglam, key)`,
  `sorguKapat(baglam)`. PageManager üzerine kurulu: her key-değer çifti
  kendi sayfasında (`key + karakter(1) + değer`), arama **linear tarama**
  (index YOK — her `sorguSec` tüm veri sayfalarını gezer, küçük/orta
  ölçek için yeterli, büyük ölçekte O(n) maliyeti var, ayrı iş).
- **Doğrulama:** `veta/tests/test_query.tan` — 5/5 GEÇTİ (ekle+seç, iki
  farklı key'in karışmaması, olmayan key → boş metin). WSL native ortamda
  `TancElf` ile derlendi ve gerçekten çalıştırıldı (çıktı: "TUM TESTLER
  GECTI"). Kendi kendine barındırma (self-hosting) sabit noktası
  (`TancElf`/`gen1`/`gen2`/`gen3`) bu turda DOKUNULMADI, `gen1==gen2==gen3`
  doğrulandı (değişmedi).
- **Dürüst sınır:** Transaction (Islem.tan) kullanılıyor ama Isolation
  yok (tek-thread), fsync yok (2B'nin sınırı miras). Index/hash tablosu
  entegrasyonu (kutuphane/HashTablo.tan, 2A) YOK — linear tarama bilinçli
  bir basitleştirme, sonraki iş.
- **Kalan:** UPDATE/DELETE yok (sadece ekle/seç), index'leme yok, WHERE/
  SQL sözdizimi yok — bunlar bilinçli olarak bu minimal dilimin dışında
  bırakıldı.

#### Transaction (İşlem) — Storage seviyesinde ÇÖZÜLDÜ (`kutuphane/Islem.tan`)
- Eski `transaction.tan`/`transaction_detail.tan` (tasarım notu, sıfır kod)
  hâlâ boş, ama gerçek transaction mantığı artık `kutuphane/Islem.tan`'da
  var ve çalışıyor (yukarı bakın — Storage bölümü). Query katmanının
  KENDİ transaction ihtiyaçları (çok-tablolu/karmaşık sorgu işlemleri)
  ayrıca ele alınabilir ama temel commit/rollback hazır.

**Genel not (2026-08-22 güncelleme):** 2026-08-21'deki "Faz 6 tasarım
aşamasında, kod yazımı HENÜZ BAŞLAMADI" tespiti bu oturumda KAPANDI —
Storage artık gerçek, test edilmiş, kalıcı bir motor. Demir'in "VETA'yı
PostgreSQL-seviyesi programdan ileri taşıma" hedefinin önündeki asıl
engel (Storage yokluğu) kalktı. Sıradaki adım Query (SIFIR kod, henüz
başlanmadı) + Isolation/2D (tek-thread sınırı hâlâ geçerli).

## Faz 7 — VETA Core Detaylı Uygulama (devam ediyor)

### Kural: Detaylı implementasyonlar reel donanımda başlatılabilir.
- **Event sistemleri** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/concurrency/source/event.tan`.
  Gerçek callback/observer YAPILAMAZ (TAN native ELF'te fonksiyon-değeri yok,
  doğrulandı) — bunun yerine **polling modeli**: `eventSistemiYeni/
  eventAboneOl/eventAboneKaldir/eventAboneVarMi/eventOlustur/eventSonId/
  eventYayinla/eventAl`. Abone taraf `eventAl(sistem, tip)` ile kendi çeker.
  Test: `veta/tests/test_event.tan` — 10/10 GEÇTİ (WSL native), iç içe dizi
  mutasyonu (`kayit[5]=1` — olayListesi[i] elemanının alanını değiştirme)
  kritik test edildi ve ÇALIŞTIĞI doğrulandı (TAN referans semantiği bu
  durumda mutable). `distributed sistem` (spread_event/NodeId) kısmı bu
  turda YAZILMADI — tek-node polling event bus bitti, distributed kısmı ayrı iş.
- **Distributed sistemler:** (event.tan'ın distributed bölümü hariç) başlanmadı.
- **Graph, semantic:** Graph yapıları ve algoritmaları (BFS/DFS), semantic kavramlar ve ontolojiler — graph.tan ve semantic.tan; test: test_graph.tan, test_semantic.tan. Not: `kutuphane/Grafik.tan` VAR ama o ASCII çubuk/chart çizim kütüphanesi, graph algoritması DEĞİL — isim benzerliği yanıltıcı, VETA Graph core'una girdi olamaz.
- **ai_memory, observability, optimizer, plugin, autonomy, evolution:** TAN native struct'lar ve algoritmalar (Faz 7 için ayrılmıştır). Not: `kutuphane/Yapayzeka.tan` VAR ama o dış LLM API çağırma yardımcı fonksiyonu (soruSor), "AI memory" (embedding/vector store) değil.
- **Memory core (bellek/buffer core, "ham bellek" 2C ile KARIŞTIRILMASIN):** başlanmadı. Not: `kutuphane/AdaptiveCache.tan` (LFU+RLE cache, NEXUS hattı) var ama VETA Memory core'a bağlanmadı, doğrulanmadı.
- **Security core:** başlanmadı. `kutuphane/sha256.tan`/`tls.tan` dil-seviyesi kripto kütüphanesi, VETA Security core'a bağlanmadı.
- **Temporal core:** VETA'da başlanmadı. `kutuphane/TemporalEngine.tan` (NEXUS Katman 3, versiyonlama) var ama `LsmDeposu.tan` üzerine kurulu — VETA'nın PageManager hattına bağlı DEĞİL, doğrulanmadı.
- **2D eşzamanlılık:** hâlâ SELF katmanında YOK (derleyici-seviyesi iş — futex/thread/lock/atomik codegen TancElf.tan'a hiç eklenmedi, eski Go backend'deki `icParcaLat`/DerleElf.go implementasyonu Go-removal'da silindi, self-hosted derleyiciye taşınmadı). Yüksek risk, ayrı dikkatli oturum gerektirir.
- **Memory core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/memory/source/memory.tan`.
  LFU tahliye + basit key-value cache (HashTablo üzerine, `kayıt`/`sözlük()`
  KULLANILMADI — bug'lı olduğu bilindiği için). `bellekAc/bellekKoy/bellekAl/
  bellekIcindeMi/bellekBoyut/bellekSil`. Compression/NUMA/tier-migration
  KAPSAM DIŞI (dürüst, TAN'da o API yok). Test: `veta/tests/test_memory.tan`
  — 11/11 GEÇTİ (WSL native), LFU tahliyenin doğru anahtarı seçtiği
  doğrulandı.
- **Security core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/security/source/security.tan`.
  `guvenlikAc/guvenlikKullaniciEkle/guvenlikDogrula/guvenlikIzinVer/
  guvenlikYetkiliMi/guvenlikDenetimKaydet/guvenlikDenetimDogrula/
  guvenlikDenetimSayisi`. sha256 şifre hash + düz kullanıcı->izin
  (RBAC'ın rol katmanı YOK, v1 basitleştirmesi, dürüst) + **hash-chain
  audit log (tamper-evident)** — kayıt sonradan değiştirilirse
  `guvenlikDenetimDogrula` bunu yakalıyor, gerçekten test edildi.
  Test: `veta/tests/test_security.tan` — 9/9 GEÇTİ (WSL native), kurcalama
  tespiti dahil.
  NOT: Bu core'u opencode (big-pickle) yazamadı (3 deneme: ya
  exploration'da takılıp yazmadan çıktı, ya donup 15+ dk ilerlemedi, ya da
  TAN olmayan uydurma bir sözdizimi (`fonk()->`, `.` sonlandırıcı) üretti
  — derlenemezdi). nemotron-3-ultra-free denendi, o da yanlış sözdizimi
  üretti. Kullanıcı onayıyla bu dosyayı **Claude doğrudan yazdı**
  (istisna — normal akışta kod yazımı opencode'a bırakılıyor).
- **Temporal core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/temporal/source/temporal.tan`.
  MVCC-lite: `zamanAc/zamanKapat/zamanYaz/zamanOku/zamanSil/zamanGecmis/
  zamanVersiyonSayisi`. "Asla silme" ilkesi — her yazım YENİ sayfaya gider,
  eski versiyon hiç üzerine yazılmaz; silme de tombstone (yeni versiyon).
  Branch/Version-Compare KAPSAM DIŞI (dürüst). Zaman damgası mantıksal
  sayaç (gerçek wall-clock TAN'da yok). `kutuphane/TemporalEngine.tan`
  (NEXUS, kayıt/sözlük kullanıyor) KULLANILMADI — sıfırdan PageManager+
  Islem+HashTablo üzerine yazıldı. Test: `veta/tests/test_temporal.tan`
  — 13/13 GEÇTİ (WSL native). Bu core'u yazarken KRİTİK BULGU 2 (yukarı
  bakın: çok satırlı ifade + `X değilse` yanlış kullanımı) bulundu ve
  düzeltildi.
- **Observability core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/observability/source/observability.tan`.
  `gozlemAc/gozlemSayacArtir/gozlemSayacOku/gozlemGaugeAyarla/gozlemGaugeOku/
  gozlemLogYaz/gozlemLogSayisi/gozlemSpanBaslat/gozlemSpanKaydet/
  gozlemSpanBitir/gozlemSpanSayisi/gozlemSaglikAyarla/gozlemSaglikOku/
  gozlemUyariEsigiAyarla/gozlemUyariKontrolEt`. Gerçek `zaman()` yerleşiği
  kullanıldı (span süresi gerçek wall-clock ile ölçülüyor — Temporal
  core'daki mantıksal sayaçtan farklı, burada gerekli). Histogram KAPSAM
  DIŞI (dürüst). Trace ID merkezi korelasyonu Central Core henüz yok
  olduğu için YOK. Test: `veta/tests/test_observability.tan` — 14/14
  GEÇTİ (WSL native). KRİTİK BULGU 2'deki `X değilse` hatasına BEN DE
  düştüm yazarken (`eğer ... değilse` "ise" olmadan) — kendi kendine
  probe testiyle (cascade-parse kontrolü) yazımdan hemen sonra yakalayıp
  düzelttim, öğrenilen dersin işe yaradığı doğrulandı.
- **Graph core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/graph/source/graph.tan`.
  `grafikAc/grafikDugumEkle/grafikDugumVarMi/grafikKenarEkle/grafikKomsular/
  grafikBFS/grafikBFSSinirli/grafikDFS/grafikEnKisaYol`. Yönlü, ağırlıksız
  kenar. BFS ile en kısa yol (ağırlıksız grafta doğru), bounded traversal
  (derinlik sınırlı BFS). Property/pattern-matching KAPSAM DIŞI (dürüst).
  `kutuphane/Grafik.tan` (ASCII chart, graph algoritması DEĞİL)
  KULLANILMADI. Test: `veta/tests/test_graph.tan` (eski smoke-stub
  değiştirildi) — 17/17 GEÇTİ (WSL native).
- **Semantic core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/semantic/source/semantic.tan`.
  `anlamAc/anlamVektorEkle/anlamVektorOku/anlamBenzerlik/anlamEnBenzerler`.
  Vektörler TAM SAYI (float değil — KRİTİK BULGU 3, yukarı bakın).
  `anlamBenzerlik` gerçek kosinüs DEĞİL, ham nokta çarpımı (çağıran
  önceden normalize etmeli). `anlamEnBenzerler` top-k selection sort ile
  azalan skor sıralaması. "embed" (metinden vektör üretme) ve filtering
  KAPSAM DIŞI (dürüst). Test: `veta/tests/test_semantic.tan` (eski
  smoke-stub değiştirildi) — 12/12 GEÇTİ (WSL native). Bu core
  yazılırken KRİTİK BULGU 3 keşfedildi (orijinal kosinüs tasarımı
  sıfıra bölme hatasına düştü, kök neden izole edilip belgelenip
  tasarım tam sayıya çevrildi).
- **AI Memory core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/ai_memory/source/ai_memory.tan`.
  Lifecycle tam: `aiBellekYakala`(capture)→`aiBellekGetir`(retrieve)→
  `aiBellekPekistir`(consolidate)→`aiBellekArsivle`(expire/archive).
  **Memory core'u working/short-term katman olarak DOĞRUDAN yeniden
  kullanıyor** (composition — VETA'nın kendi core'ları birbirinin üstüne
  kuruluyor, master prompt'un istediği gibi). Uzun süreli/episodic
  bellek: append-only dizi + HashTablo indeks, "asla silme" (arşivleme
  sadece aktifMi=0 işaretler, Temporal core ile aynı felsefe). "Semantic"
  bellek katmanı KAPSAM DIŞI — bunun yerine Semantic Core (`anlam*`
  fonksiyonları) ayrıca/birlikte kullanılabilir, tekrar yazılmadı.
  Security/tenant-isolation entegrasyonu KAPSAM DIŞI (composition ile
  Security Core eklenebilir, zorlanmıyor). Test:
  `veta/tests/test_ai_memory.tan` — 14/14 GEÇTİ (WSL native), consolidate
  sırasında kısa-süreli bellekten silinme + tekrar-pekiştirmede liste
  büyümeden güncelleme + arşivlemenin veriyi silmediği doğrulandı.
- **Central Core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/core/source/central_core.tan`.
  `merkezAc/merkezYetenekKaydet/merkezCoreDestekliyorMu/
  merkezYetenekliCoreBul/merkezGorevOlustur/merkezGorevSonId/
  merkezGorevAta/merkezGorevTamamla/merkezGorevDurum/
  merkezYenidenDenemeliMi/merkezGorevSayisi`. Task model + capability
  registry + routing KARARI + retry KARARI.
  **ÖNEMLİ SINIR (mimari, dürüst):** TAN'da fonksiyon-değeri/callback
  yok → Central Core GERÇEK DİNAMİK DISPATCH YAPAMAZ ("şu core'un şu
  fonksiyonunu çağır" otomatik olamaz). Bu core sadece KARARI verir
  (hangi core'a git, tekrar dene mi/vazgeç mi) — gerçek çağrıyı ÇAĞIRAN
  KOD kendi if/else zinciriyle yapmalı. Rollback/compensation KAPSAM
  DIŞI (Islem.tan zaten storage-seviyesi var, cross-core compensation
  ayrı iş). Test: `veta/tests/test_central_core.tan` — 17/17 GEÇTİ (WSL
  native), retry sayacının FONKSİYON İÇİNDE `merkez[4]=X` ile YERİNDE
  mutasyonu (return edilmeden) çağıranın değişkenine yansıdığı da dahil
  doğrulandı (dizi referans semantiği bu derinlikte de tutarlı).
- **Optimizer core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/optimizer/source/optimizer.tan`.
  `optimizeAc/optimizeEsikKontrolEt/optimizeOner/optimizeSonOneriId/
  optimizePolitikaKontrolEt/optimizeUygula/optimizeGeriAl/
  optimizeOneriDurum/optimizeOneriSayisi`. SADECE deterministic seviye
  (eşik-tabanlı öneri + politika kontrolü + apply/rollback durum
  takibi). Adaptive ve AI-assisted seviyeler KAPSAM DIŞI (float bozuk,
  KRİTİK BULGU 3, skorlu/istatistiksel optimizer güvenilir yazılamaz).
  SIMULATE aşaması KAPSAM DIŞI (TAN'da izolasyon yok). Observability
  Core ile gevşek bağlaşım (composition, import etmiyor — çağıran
  gözlem değerini kendi okuyup besler). Test:
  `veta/tests/test_optimizer.tan` — 14/14 GEÇTİ (WSL native).
- **Plugin core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/plugin/source/plugin.tan`.
  `pluginAc/pluginKaydet/pluginDurum/pluginDogrula/pluginYukle/
  pluginBaslat/pluginSaglikKontrol/pluginDurdur/pluginYenidenBaslat/
  pluginKaldir/pluginSayisi`. Durum makinesi: KAYITLI(0)→DOGRULANMIS(1)→
  YUKLENMIS(2)→CALISIYOR(3)→DURDURULMUS(4)→[YUKLENMIS(2) restart |
  KALDIRILMIS(5) son durum]. GEÇERSİZ geçişler (örn. 0'dan doğrudan 3'e)
  sessizce reddediliyor, durum bozulmuyor. TAN'da dinamik kod yükleme/
  fonksiyon-değeri YOK — bu core GERÇEK KOD ÇALIŞTIRMAZ, sadece yaşam
  döngüsü durumunu tutarlı takip eder (dürüst). Security entegrasyonu
  zorunlu değil, composition ile eklenebilir. Test:
  `veta/tests/test_plugin.tan` — 18/18 GEÇTİ (WSL native), geçersiz geçiş
  reddi + restart + kaldırma-sonrası-kilit senaryoları dahil.
- **Autonomy core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/autonomy/source/autonomy.tan`.
  `otonomiAc/otonomiGozlemle/otonomiSonId/otonomiDurum/otonomiAnla/
  otonomiPlanla/otonomiPolitikaOnayla/otonomiYurut/otonomiDogrula/
  otonomiAksiyonSayisi`. Durum makinesi: GOZLEMLENDI(0)→ANLASILDI(1)→
  PLANLANDI(2)→[ONAYLANDI(3)|REDDEDILDI(7)]→YURUTULDU(4)→[DOGRULANDI(5)
  promote|GERI_ALINDI(6) rollback]. **"Kontrolsüz mutation yasak" ilkesi
  gerçekten zorlanıyor:** `otonomiYurut` SADECE durum=3(ONAYLANDI) ise
  çalışır — politika onayı olmayan/reddedilmiş hiçbir aksiyon hiçbir
  şekilde yürütme durumuna geçemez (test edildi: onaysız + reddedilmiş
  iki ayrı senaryoda da geçiş engellendi). SIMULATE ve gerçek dinamik
  yürütme (dynamic dispatch, TAN'da fonksiyon-değeri yok) KAPSAM DIŞI —
  Central/Plugin core'larla aynı sınır. Test:
  `veta/tests/test_autonomy.tan` — 14/14 GEÇTİ (WSL native).
- **Durum:** Storage+Query+Event+Memory+Security+Temporal+Observability+Graph+Semantic+AI Memory+Central Core+Optimizer+Plugin+Autonomy bitti (tek-node, eşzamanlılık yok, float fonksiyonlar bozuk, dinamik dispatch yok). Sıradaki: Distributed/Evolution (hepsi sıfır kod).

## Sonraki Adımlar

**2026-08-21 GÜNCELLEME:** Bu oturum native WSL2'de çalıştı (throttle YOK, önceki
QEMU/Termux kısıtı burada geçersiz) — "throttle sonra doğrulanacak" diye
işaretli her şey GERÇEKTEN denendi. Sonuç iki kategoriye ayrıldı: (a) gerçekten
çalışan/doğrulanan (2A yeni), (b) önceden "eklendi/UYGULANDI" diye yanlış
işaretlenmiş ama aslında YOK/KIRIK olduğu ortaya çıkanlar (2B, 2D, Storage,
Query, Transaction). Bu, throttle'ın hiçbir zaman gerçek engel olmadığını,
bu maddelerin daha önce hiç gerçekten test edilmediğini gösteriyor.

### Bu oturumda yapıldı (2026-08-21)
1. ✅ **2A (sözlük) TAMAMLANDI** — kutuphane/HashTablo.tan, 12/12 test GEÇTİ, gerçekten çalıştırıldı.
2. ✅ **2C zaten çözülmüştü** (Faz B bitwise, commit 6dda6fe) — bu dosyada senkronize edildi.
3. 🔴 **2B (dosya G/Ç) KIRIK olduğu bulundu** — codegen yazılı ama derleyici kayıt dizilerine hiç eklenmemiş. Ekleme denendi → gen1→gen2 self-host SEGFAULT → GERİ ALINDI (self-hosting korundu). Gerçek düzeltme ayrı oturum ister.
4. 🔴 **2D (eşzamanlılık) hiç yazılmamış olduğu bulundu** — "futex satır 4465..." kaydı uydurmaydı, TancElf.tan'da futex/thread/lock/atomik SIFIR eşleşme.
5. 🔴 **Faz 6 (Storage/Query/Transaction) %99+ yorum/tasarım notu olduğu bulundu** — gerçek kod yok (page_manager'daki 4 sabit hariç). "UYGULANDI/derleme CANLI" kayıtları yanlıştı.

### Orta Vadeli (gelecek oturumlar, öncelik sırasıyla)
6. ✅ **2B gerçekten düzeltildi (2026-08-22, commit `01a23f9`)** — kök sebep bozuk register kullanımıymış (T2/T3 değil), yeniden yazıldı, gerçek rastgele-erişim testiyle doğrulandı. Storage'ın önkoşulu tamam.
7. ⚙️ **Storage'ı gerçekten yaz** (page_manager + WAL + transaction) — artık 2B üzerine kurulabilir, SIRADAKİ adım.
8. ⚙️ **Query + Transaction'ı gerçekten yaz** — Storage'a bağımlı.
9. ⚙️ 2D (eşzamanlılık) — kendi belgesinin dediği gibi yüksek risk/karmaşıklık, ayrı planlama ister.

### Demir direktifi — sonraki VETA adımı (2026-08-21, henüz BAŞLATILMADI, sadece kayıt)
Bu oturumun kapanışında Demir'in yönü: **VETA'yı mevcut PostgreSQL-seviyesi
veritabanı programı noktasından daha ileri bir noktaya taşımak.** Yukarıdaki
madde 6-8 (2B düzeltme + gerçek Storage/Query/Transaction) bu hedefin ÖN
KOŞULU — şu an VETA "PostgreSQL-seviyesi" bile değil, çoğu katman tasarım
aşamasında. Bu adım bu oturumda BAŞLATILMADI, sadece yön olarak kaydedildi.

### Uzun Vadeli
10. ⏳ Gerçek compiler değişikliği olduğunda gen1→gen2→gen3 her seferinde çalıştırılacak (artık native ortamda hızlı, throttle mazereti yok).
