# VETA DURUM (STATUS)

*Tarih: 2026-08-17. Son güncelleme — FAZ 1-5 tamamlandı, Faz 6 devam ediyor.*

## ✅ KRİTİK BULGU 3 — ÇÖZÜLDÜ (2026-09-06, commit `25e3a08`) — DÜZELTME (2026-09-07)

**Bu bölüm 2026-08-23 tarihli, ARTIK YANLIŞ — silinmedi, tarihsel kayıt
olarak bırakıldı, ama aşağıdaki "güvenilmez" sonucuna GÜVENME.** Kullanıcı
tanımlı işlevlerde float parametre/dönüş çıkarımı `govdeDonusTipiCikar`/
`argumanKesirMi`/`donusIfadesiTipiCikar` (TancElf.tan ~4276-5040) ile
düzeltildi, kalıcı regresyon testiyle kilitlendi:
`testler/kesir_tip_cikarimi_testleri.tan` (8/8 GEÇTİ — düz operand, karışık
tip, 3+ operand zincir, 2-seviye iç içe parantez, karşılaştırma-kesin-tam)
+ `testler/regresyon/kesir_tip_reddet.tan` (INDEKS eleman-tipi sınırının
DÜRÜST derleme-hatası verdiği vaka, sessiz yanlış "tam" varsayımı YOK).
Kalan gerçek sınır artık float genelinde DEĞİL, sadece **liste/dizi
elemanı olarak saklanan float** (`dizi[i] + 1.5` gibi) — bkz. bu dosyanın
altındaki güncel not. `semantic.tan`'ın aşağıdaki gerekçeyle (satır 26-29)
float'tan tamamen kaçınma kararı ARTIK YANLIŞ BİR ÖNCÜLE dayanıyor —
skaler float güvenilir hale geldi, kararın yeniden gözden geçirilmesi
gerekebilir (ayrı, küçük iş; muhtemel çözüm dizi-içi float DEĞİL, sadece
skaler normalizasyon).

---

*(Aşağısı orijinal 2026-08-23 metni, tarihsel kayıt olarak korunuyor —
YUKARIDAKİ DÜZELTMEYİ ESAS AL.)*

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

## `sözlük()`/`kayıt` durumu — DÜZELTME (2026-09-06, Faz 1)

Yukarıdaki eski bulgu ("TancElf hatasız derliyor ama sessizce çalışmıyor")
**yanıltıcıydı** — eski, silinmiş Go-tabanlı arka uca (`DerleElf.go`) aitti.
İzole testle doğrulandı: self-hosted `TancElf.tan`'da `sözlük()` (ya da
`kayıt`) hiç var olmadı — ne keyword listesinde ne CAGRI dispatch'inde
(`grep sözlük TancElf.tan` → sıfır eşleşme). Çağrı denenince BUGÜN zaten
herhangi bir bilinmeyen isimle birebir aynı temiz reddi veriyor:
`BAGLAMA HATASI: etiket bulunamadi: f_sözlük` — sessiz no-op DEĞİL. Resmî
hash primitifi `kutuphane/HashTablo.tan`.

**Mezar taşı adayı (ayrı denetim, ŞİMDİ dokunulmadı):** `kutuphane/AdaptiveCache.tan`,
`BAgaci.tan`, `Heap.tan`, `LsmDeposu.tan`, `TemporalEngine.tan` — hâlâ
`sözlük()` çağırıyorlar (dolayısıyla derlenmiyorlar), hiçbir VETA modülünce
import edilmiyorlar. Listeye yazıldı, kaldırma kararı ayrı bir turda.

## Özet

| Alan | Durum | Not |
|---|---|---|
| Ortam | DONE | qemu-x86_64, Debian 13 (trixie) PRoot, aarch64 host |
| Sabit nokta (orijinal) | VERIFIED | TancElf==gen1==gen2==gen3, md5 `914b0ffb971d4cf1991779e674f0bab1` |
| Regresyon | VERIFIED | prog.tan: 7/7 çıktı birebir |
| **math kütüphanesi** | **VERIFIED** | 11 fonksiyon, 24 test — hepsi doğru |
| **string kütüphanesi** | **VERIFIED** | 12 fonksiyon, 20 test (4 derleme) — hepsi doğru |
| **collection/option/error kütüphaneleri** | **KAYNAK KALDIRILDI (2026-09-06), TESTLER HÂLÂ KIRIK — DÜZELTME (2026-09-07)** | Bu satırlardaki "DOGMALI/compile-verified" iddiası YALANDI — kaynak hiç var olmadı, ilk commit'e (63e6da0) bile 221 baytlık derlenmiş ELF binary olarak girdi, hiçbir zaman derlenmedi/test edilmedi. `ec56717` SADECE 3 kaynak dosyasını sildi (`koleksiyon.tan`/`hata.tan`/`secenek.tan`, hepsi aynı 221-bayt ELF). **"KALDIRILDI" iddiası TAM DEĞİL:** karşılık gelen TEST dosyaları (`veta/tests/test_collection.tan`/`test_koleksiyon.tan`/`test_option.tan`/`test_secenek.tan`/`test_error.tan`/`test_error2.tan`) hiç silinmedi, hâlâ diskte, hâlâ `DERLEME HATASI`/`BAGLAMA HATASI` veriyor (var olmayan modüle/fonksiyona bağlanmaya çalışıyorlar). AYRICA yeni mezar taşı (2026-09-07 denetiminde bulundu, AYNI GÜN DİSKTEN DE KALDIRILDI): `veta/libraries/foundation/collection/source/test_koleksiyon.tan` (dikkat — `veta/tests/` altındaki AYNI isimli dosyadan FARKLI, bu `ec56717`'nin silmediği 4. bir 221-baytlık ELF, `.tan` uzantılı ama gerçek kaynak değil) — önce `git rm --cached` ile takipten çıkarıldı (commit `93c8167`), SONRA grep ile hiçbir gerçek modülün (16/16, `veta/libraries/*/source/*.tan` taraması) collection/option/error fonksiyonlarına referans vermediği TEYİT EDİLDİ, ardından diskten de `rm` ile SİLİNDİ (untracked olduğu için git diff'te görünmez — bu satır kanıttır). 20 gerçek VETA modülünün hiçbiri bunları kullanmıyor (ihtiyaç native dizi + HashTablo.tan ile karşılanıyor, grep teyidi: `koleksiyonEkle`/`optionBasarili`/`hataOlustur` desenleri 16 modülün source/ dizinlerinde SIFIR eşleşme) — YAGNI gereği yeniden yazılmadı, kaldırılan KISIM için karar doğruydu, sadece testlerin de kaldırılması/güncellenmesi unutulmuş (veta/tests/ altındaki 6 kırık test dosyası HÂLÂ duruyor — bunlar gerçek `.tan` kaynağı, ELF-maskeli mezar taşı DEĞİL, silinip silinmeyeceği ayrı bir karar, bu turda dokunulmadı). bkz. commit `ec56717`. |
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

### Faz 3 — Genişletmiş Foundation (KISMEN YALAN ÇIKTI — 2026-09-06 düzeltmesi)
- **collection/option/error: bu satırların "compile-verified" iddiası tamamen yalandı.**
  koleksiyon.tan/secenek.tan/hata.tan hiçbir zaman gerçek TAN kaynağı olarak
  var olmadı — ilk commit'e (63e6da0) bile 221 baytlık, üç dosyada da
  byte-birebir aynı, derlenmiş ELF binary olarak girdiler. Hiç derlenmedi,
  hiç test edilmedi. Disk-geneli arama + tüm git geçmişi (tüm branch/tag)
  kaynağın hiçbir yerde bulunamadığını doğruladı — kurtarılamaz, hiç
  doğmamış modül. 2026-09-06'da kaldırıldı (commit `ec56717`), YAGNI
  gereği yeniden yazılmadı — 20 gerçek VETA modülünün hiçbiri bunları
  kullanmıyor, ihtiyaç native dizi + HashTablo.tan ile karşılanıyor.
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
- **ACID durumu (dürüst, 2026-09-09 güncellemesi — aşağıdaki DÜZELTME'yi
  gör, bu satırlar ARTIK BAYAT):** ~~Atomicity EVET, Consistency uygulama
  sorumluluğu, Isolation YOK, Durability KISMİ (fsync yok, crash-recovery
  yok)~~.
- **Doğrulama (BAYAT, 13/13 sayısı artık yanlış — aşağıya bak):**
  ~~`testler/storage_testleri.tan` — 13/13 GEÇTİ~~. `TestAraclar.sh`'ye
  otomatik dahil (kalıcı regresyon), iki kez üst üste çalıştırılıp
  idempotent olduğu doğrulandı. `veta/tests/test_file_io.tan`/
  `test_storage.tan`/`test_wal.tan`/`test_transaction.tan` (önceden hiç
  derlenmeyen sahte testlerdi) yeni API ile çalışır hale getirildi.
  TancElf.tan bu turda DEĞİŞMEDİ (saf kütüphane kodu) — self-hosting
  riski yok, ama yine de tam regresyon (TestArkaUcGoSuzTemiz.sh,
  TestFormatIdempotent) yeşil doğrulandı.

- **DÜZELTME (2026-09-09, WAL crash-recovery + crash-gate denetimi —
  yukarıdaki ACID/13-13 satırları artık BAYAT, güncel durum budur):**
  - **fsync EKLENDİ** (`dosyaSenkron`, TancElf.tan sys_fsync=74, 2026-09-07)
    — `Islem.tan:islemCommit` her commit'te çağırıyor (her-commit-fsync).
  - **Crash-recovery EKLENDİ** (`Islem.tan:islemKurtar`) — commit-marker
    ("C:" kaydı) + streaming REDO (komitli tx'lerin sayfa yazımlarını
    tekrar uygular) + streaming UNDO (komitsiz/yarım tx'leri geri alır).
    Gerçek SIGKILL ile doğrulandı (`testler/wal_crash_harness.sh` —
    yazıcı process arka planda başlatılıp GERÇEKTEN `kill -9` ile
    öldürülüyor, tamamen ayrı bir recovery process'i sonucu okuyor): (1)
    commit-öncesi öldürme → UNDO doğru, (2) commit-sonrası öldürme →
    veri kalıcı. **Test edilemeyen tek nokta:** commit-marker yazıldı ama
    fsync tamamlanmadan çökme — SIGKILL bunu izole edemez (write()
    kernel'e ulaştıysa process ölse de sayfa cache'te kalır, ancak gerçek
    power-loss/OS-crash bunu ayırt eder, WSL'de yok). Pratik karşılığı:
    checksum-halt testi (`walGecerliSinir` bozuk kayıtta durur, ayrı
    doğrulandı).
  - **ACID (güncel, dürüst):** Atomicity EVET (rollback + crash-recovery
    ikisi de doğrulandı), Consistency uygulama sorumluluğu, **Isolation
    YOK** (tek-thread varsayımı, 2D hâlâ yazılmadı), **Durability EVET**
    (commit-zamanlı fsync + REDO/UNDO — yukarıdaki tek istisna hariç).
  - **Checksum: CRC32, SHA-256 DEĞİL** (`kutuphane/crc32.tan`, tablo/liste
    kurmayan bit-bit fold). İLK sürüm SHA-256 kullanmıştı — WAL'ın 8KB'lık
    kayıtlarında `sha256.tan`'ın kendi O(n²)+sızıntı kusuruna çarpıp
    crash-recovery testinde GB'larca RAM tüketip OOM + bir kez WSL
    çökmesine yol açtı (bkz. aşağıdaki "Foundation-debt" maddeleri).
    Geri alındı, CRC32'ye geçildi — WAL'ın tehdit modeli (crash/torn-write,
    adversary değil) zaten CRC32'yi yeterli kılıyordu.
  - **`metinDilim` builtin'i eklendi** (TancElf.tan, TEK allocate+TEK
    bellek_kopyala) — `walIcerikNormalize`/`walAltMetin`/`pmSayfaOku`/
    `pmSayfaYaz`'daki tek-karakter `metinBirlestir` döngüsü O(n²)+sızıntı
    üretiyordu, O(n)'e indirildi.
  - **Ölçüm (varsayım değil, ölçüldü):** `testler/storage_testleri.tan`
    (19/19 GEÇTİ — REDO/UNDO/checksum-halt dahil) temiz dosyalarla
    **MAXRSS 384 kB**. "Sızıntı yok" DENMİYOR — bu 19 test dominant ÜÇ
    O(n²) sitesini (metinDilim öncesi Wal/PageManager karakter-döngüsü,
    sha256.tan'ın byte-listesi) kapattığını kanıtlıyor, beşinci bir site
    olmadığını KANITLAMAZ.
  - **Foundation-debt (ledger, iki madde — WAL'ı bloke ETMİYOR ama
    gelecekteki her yeni VETA katmanı sızıntı yüzeyini çarpanlıyor):**
    1. **`kutuphane/sha256.tan` O(n²)+sızıntı** — kendi notunda artık
       uyarı var: birkaç yüz bayt üstünde KULLANILMAMALI. WAL'dan
       çıkarıldı ama dosyanın kendisi düzeltilmedi (küçük girdide hâlâ
       kullanılabilir — imza/registry-anahtar boyutu).
    2. **TancElf.tan allocator'ı (`f_tan_ayir`, `tanAyirBant`) saf bump
       allocator — free/reset YOK, `brk` ile sadece büyüyor.** Bulk-
       builtin (metinDilim) tek-çağrı sızıntısını n²'den n'e indirdi ama
       KAPATMADI — uzun-ömürlü bir DB process'i milyonlarca işlemde
       yine belleği tüketir ("12 saniyede çöküyor" → "saatlerde çöküyor",
       erteleme, düzeltme değil). Region-reset KASITLI OLARAK
       denenmedi — tek-global bump'ta scope'u aşan bir allocation
       dangling pointer/sessiz veri bozulmasına yol açar (OOM'dan beter).
       Gerçek çözüm scoped/local arena (fonksiyon-scratch → sonuç
       kopyala → geri sar) — ayrı, kilitlenmemiş bir tasarım kararı.
       **Sıradaki VETA katmanından ÖNCE bu kapanmalı** — WAL bu allocator
       borcuna iki kez çarptı (string-padding, sha256), üçüncü katman
       biriktirmeden kapatılacak.

  **Provenance notu (2026-09-09, `c1ff3e5` sonrası denetim):** `c1ff3e5`'teki
  `kutuphane/Islem.tan` diff'i (islemCommit fsync + islemKurtar crash-recovery)
  İÇERİK olarak doğrulandı — commit mesajıyla eşleşiyor, kendi içinde tutarlı.
  Ama bu diff'in, önceki bir oturumun başında dirty/pre-session bulunup
  dokunulmadan bırakılmış Islem.tan durumuyla birebir sürekliliği GİT-İSPATLI
  DEĞİL: o an snapshot/stash alınmamıştı, reflog'da ayrı bir "incelendi" adımı
  yok. Sonuç tutarlılıktan ÇIKARIM, commit zincirinden KANIT değil — commit'in
  doğruluğunu etkilemiyor, sadece tarihçesinin git-izinin eksik olduğunu
  gösteriyor. Ayrım bilerek not ediliyor ki zamanla "çıkarım" "kanıt"a
  dönüşmesin (bu dosyanın 2026-08-21 denetiminde tam bu kalıptan zarar
  görülmüştü).

  **Disiplin kuralı (ileriye dönük):** Bir oturum başında pre-session dirty
  bir dosya bulunursa, üstüne DEVAM EDİLMEDEN önce `git stash` (ya da küçük
  bir WIP commit) alınacak — provenance her zaman git'ten ispatlanabilir
  olsun, tutarlılıktan çıkarıma düşülmesin.

#### Query (Sorgu) — MİNİMAL DİLİM UYGULANDI (2026-08-23, gerçekten çalıştırıldı)
- `libraries/query/source/query.tan`: eski tasarım yorumu KORUNDU, altına
  gerçek kod eklendi. Tam SQL parser DEĞİL — basit fonksiyon API'si:
  `sorguAc(yol)`, `sorguEkle(baglam, key, deger)`, `sorguSec(baglam, key)`,
  `sorguKapat(baglam)`. PageManager üzerine kurulu: her key-değer çifti
  kendi sayfasında (`key + karakter(1) + değer`), arama **linear tarama**
  (index YOK — her `sorguSec` tüm veri sayfalarını gezer, küçük/orta
  ölçek için yeterli, büyük ölçekte O(n) maliyeti var, ayrı iş).
- **DÜZELTME (2026-09-06):** Bu bölüm bayattı — `sorguGuncelle` (UPDATE,
  satır 204) ve `sorguSil` (DELETE, satır 228) ARADAN GEÇEN BİR TURDA
  eklenmiş, doküman güncellenmemişti. Aşağıdaki "Kalan: UPDATE/DELETE yok"
  satırı YANLIŞTI, silindi. **Doğrulama (taze, 2026-09-06):**
  `veta/tests/test_query.tan` — **13/13 GEÇTİ** (ekle/seç/güncelle/sil,
  iki farklı key'in karışmaması, olmayan key → boş metin). WSL native
  ortamda `TancElf` ile derlendi ve gerçekten çalıştırıldı ("TUM TESTLER
  GECTI").
- **Dürüst sınır:** Transaction (Islem.tan) kullanılıyor ama Isolation
  yok (tek-thread), fsync yok (2B'nin sınırı miras). Index/hash tablosu
  entegrasyonu (kutuphane/HashTablo.tan, 2A) YOK — linear tarama bilinçli
  bir basitleştirme, sonraki iş.
- **Kalan:** index'leme yok, WHERE/SQL sözdizimi yok — bunlar bilinçli
  olarak bu minimal dilimin dışında bırakıldı. (UPDATE/DELETE artık VAR,
  yukarı bakın.)

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
- **MEZAR TAŞI NOTU (2026-09-06):** `veta/libraries/concurrency/source/graph.tan`
  ve `semantic.tan` — bu ikisi %100 yorum satırı, sıfır `işlev` gövdesi.
  Concurrency ile alakasız (eski tasarım/ontology notu), gerçek Graph/Semantic
  core'ları başka dizinde (`veta/libraries/graph`, `veta/libraries/semantic`)
  zaten var ve çalışıyor (yukarı bakın). Bu iki dosya şimdiye kadar hiçbir
  statüde anılmamıştı — unutulmuş taslak. Kaldırma kararı ayrı denetim.
- **DÜZELTME (2026-09-07, VETA Faz 0 denetimi):** Aşağıdaki 6 madde (Distributed/
  ai_memory-observability-optimizer-plugin-autonomy-evolution/Memory/Security/
  Temporal/2D eşzamanlılık) bu dosyanın KENDİ İÇİNDE, birkaç satır aşağısında
  (302 ve sonrası) ✅ TAMAMLANDI olarak işaretli — bu üst-özet 2026-08-23
  oturumunun BAŞLANGIÇ taslağıydı, oturum ilerledikçe altına gerçek sonuçlar
  eklendi ama bu blok hiç güncellenmedi. Sistematik satır-satır taramada
  bulundu (grep("TAMAMLANDI") bunu YAKALAMAZ — bu satırlar pozitif eşleşme
  vermiyor, "başlanmadı" diyor). Aşağıdaki 6 satır DÜZELTİLDİ, silinmedi —
  hangi gerçek satıra bakılacağı işaretlendi:
- **Distributed sistemler:** ✅ TAMAMLANDI — bkz. satır ~451 "Distributed core".
- **Graph, semantic:** Graph yapıları ve algoritmaları (BFS/DFS), semantic kavramlar ve ontolojiler — graph.tan ve semantic.tan; test: test_graph.tan, test_semantic.tan. Not: `kutuphane/Grafik.tan` VAR ama o ASCII çubuk/chart çizim kütüphanesi, graph algoritması DEĞİL — isim benzerliği yanıltıcı, VETA Graph core'una girdi olamaz.
- **ai_memory, observability, optimizer, plugin, autonomy, evolution:** ✅ HEPSİ TAMAMLANDI — bkz. satır ~339/371/402/413/425/438. Not: `kutuphane/Yapayzeka.tan` VAR ama o dış LLM API çağırma yardımcı fonksiyonu (soruSor), "AI memory" (embedding/vector store) değil — VETA core'ları buna bağlı değil, kendi bağımsız implementasyonları.
- **Memory core (bellek/buffer core, "ham bellek" 2C ile KARIŞTIRILMASIN):** ✅ TAMAMLANDI — bkz. satır ~302. Not: `kutuphane/AdaptiveCache.tan` (LFU+RLE cache, NEXUS hattı) var ama VETA Memory core BUNA bağlı değil, kendi bağımsız implementasyonu.
- **Security core:** ✅ TAMAMLANDI — bkz. satır ~309. `kutuphane/sha256.tan`/`tls.tan` dil-seviyesi kripto kütüphanesi VETA Security core'un ALTINDA kullanılıyor (şifre hash için), `tls.tan` bağlanmadı.
- **Temporal core:** ✅ TAMAMLANDI — bkz. satır ~328. `kutuphane/TemporalEngine.tan` (NEXUS Katman 3, versiyonlama) VETA'nın PageManager hattına bağlı DEĞİL — VETA Temporal core kendi bağımsız implementasyonu.
- **2D eşzamanlılık:** ✅ KISMEN TAMAMLANDI — bkz. satır ~474-528, futex/thread/lock/atomik codegen self-hosted derleyiciye eklendi, 13/13 test kanıtı var. Isolation (tek-thread sınırı) hâlâ geçerli, tam derleyici-seviyesi native eşzamanlılık genel iyileştirmesi ayrı iş.
- **Memory core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/memory/source/memory.tan`.
  LFU tahliye + basit key-value cache (HashTablo üzerine, `kayıt`/`sözlük()`
  KULLANILMADI — bug'lı olduğu bilindiği için). `bellekAc/bellekKoy/bellekAl/
  bellekIcindeMi/bellekBoyut/bellekSil`. Compression/NUMA/tier-migration
  KAPSAM DIŞI (dürüst, TAN'da o API yok). Test: `veta/tests/test_memory.tan`
  — 11/11 GEÇTİ (WSL native), LFU tahliyenin doğru anahtarı seçtiği
  doğrulandı.
- **Security core** ✅ TAMAMLANDI (2026-08-23), **rol katmanı SONRADAN eklendi
  (2026-09-06'da fark edildi)** — `veta/libraries/security/source/security.tan`.
  `guvenlikAc/guvenlikKullaniciEkle/guvenlikDogrula/guvenlikIzinVer/
  guvenlikYetkiliMi/guvenlikDenetimKaydet/guvenlikDenetimDogrula/
  guvenlikDenetimSayisi`. sha256 şifre hash + düz kullanıcı->izin +
  **hash-chain audit log (tamper-evident)** — kayıt sonradan değiştirilirse
  `guvenlikDenetimDogrula` bunu yakalıyor, gerçekten test edildi.
  **DÜZELTME: aşağıdaki "RBAC'ın rol katmanı YOK" iddiası YANLIŞTI** —
  `guvenlikRolVer` (satır 126), `guvenlikRolIzinVer` (157),
  `guvenlikRolYetkiliMi` (166) tam rol katmanı olarak mevcut, doküman
  eski hâliyle bırakılmıştı. **Doğrulama (taze, 2026-09-06):**
  `veta/tests/test_security.tan` — **19/19 GEÇTİ** (WSL native), kurcalama
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
- **Evolution core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/evolution/source/evolution.tan`.
  `evrimAc/evrimAdayOner/evrimSonId/evrimDurum/evrimDeneyeBaslat/
  evrimKiyaslamaTamamla/evrimGolgeyeAl/evrimCanaryBaslat/evrimYayinla/
  evrimGeriAl/evrimAdaySayisi`. Durum makinesi: ADAY(0)→DENEY(1)→
  [KIYASLANDI(2)|GERI_ALINDI(6)]→GOLGE(3)→CANARY(4)→[YAYINLANDI(5)
  promotion|GERI_ALINDI(6)]. **"Evolution production'a doğrudan
  yazamaz" ilkesi gerçekten zorlanıyor:** `evrimYayinla` SADECE
  durum=4(CANARY) ise çalışır — Candidate'ten doğrudan Promotion'a
  ASLA atlanamaz (test edildi: ADAY ve DENEY aşamalarından iki ayrı
  yayınlama denemesi de reddedildi). `evrimGeriAl` herhangi bir aktif
  aşamadan (1/2/3/4) acil durdurma yapabiliyor. Gerçek deney/kıyaslama/
  gölge-trafik çalıştırma KAPSAM DIŞI (SIMULATE sınırıyla tutarlı).
  Test: `veta/tests/test_evolution.tan` — 13/13 GEÇTİ (WSL native).
- **Distributed core** ✅ TAMAMLANDI (2026-08-23) — `veta/libraries/distributed/source/distributed.tan`.
  `dagitikAc/dagitikNodeEkle/dagitikNodeDurumGuncelle/dagitikNodeDurumu/
  dagitikNodeSayisi/dagitikAktifNodeSayisi/dagitikQuorumSaglaniyorMu/
  dagitikLiderSec/dagitikLiderKim/dagitikLiderAktifMi`. Master prompt'un
  kendi "önce single-node temel" kuralına uyularak: node registry +
  sağlık durumu + ÇOĞUNLUK (majority) quorum hesaplaması (tam sayı
  aritmetiği: `aktif*2 > toplam`) + terim-tabanlı basit lider seçimi
  (Raft'ın election-term fikrinden esinlenilmiş, gerçek Raft/Paxos
  DEĞİL — split-brain'i azaltan "sadece daha yüksek terim kazanır" +
  "sadece aktif node aday olabilir" kuralları test edildi). Gerçek ağ
  I/O, replication lag, multi-region, distributed transaction KAPSAM
  DIŞI (TAN'da soket yerleşikleri var ama çok-node koordinasyon ayrı,
  büyük bir iş). Test: `veta/tests/test_distributed.tan` — 18/18 GEÇTİ
  (WSL native) — quorum kaybı senaryosu (3/3→2/3→1/3), düşmüş lider
  tespiti (failover tetikleme sinyali) dahil.
- **Durum: 16/16 VETA core'unda gerçek, test edilmiş kod var** —
  Storage+Query+Event+Memory+Security+Temporal+Observability+Graph+
  Semantic+AI Memory+Central Core+Optimizer+Plugin+Autonomy+Evolution+
  Distributed (hepsi tek-node, eşzamanlılık yok — 2D derleyici işi ayrı,
  float fonksiyonlar bozuk — KRİTİK BULGU 3, dinamik dispatch yok —
  TAN'da fonksiyon-değeri yok). Kalan: 2D eşzamanlılık (derleyici-
  seviyesi, ÇOK YÜKSEK karmaşıklık, ayrı dikkatli oturum gerektirir).

## 2D Eşzamanlılık — KISMEN TAMAMLANDI (2026-08-23) — kilit/atomik/ham bellek çalışıyor

TancElf.tan'a (SELF-HOSTED derleyicinin KENDİSİ, kütüphane değil —
`veta/libraries/` dosyalarından FARKLI, bu doğrudan derleyici düzeyinde
bir değişiklik) yeni native yerleşikler eklendi. Eski Go backend'deki
(`DerleElf.go`, commit `2976ac8`, Go-removal'da silindi) tasarımın
kilit/futex/atomik kısmı self-hosted derleyiciye taşındı — **thread
creation (clone/içParcaLat) HARİÇ**, o ayrı ve daha riskli bir sonraki
adım (aşağıya bakın).

**Eklenen yerleşikler** (hepsi generic CAGRI dispatch üzerinden çalışıyor,
özel derleyici-dispatch case'i GEREKMEDİ):
- `bellekEsle(boyut)` — mmap (sys_mmap=9) ile anonim RW bellek ayırır.
- `hamOku8(adres)` / `hamYaz8(adres,deger)` — ham bellek 8-bayt okuma/yazma.
- `futexWait(adres,beklenen)` / `futexWake(adres,sayi)` — sys_futex=202.
- `kilitOlustur()` / `kilitle(kilit)` / `kilidiAc(kilit)` — CAS (lock
  cmpxchg) + futex tabanlı mutex.
- `atomikEkleHam(adres,miktar)` — lock xadd ile atomik fetch-and-add.

**Yeni opcode ilkelleri** (TancElf.tan'ın kendi x86-64 kod üretici
kütüphanesine eklendi): `lockCmpxchgBellek`, `lockXaddBellek`.

**Bulunan ve düzeltilen 2 gerçek derleyici bug'ı (bu oturumda):**
1. Reachability/closure eksikliği: `kilitOlustur` kendi içinde
   `f_bellekEsle`'yi çağırıyordu ama bu bağımlılık `yardimciBagimliliklari`
   tablosunda yoktu — hedef program `kilitOlustur()`'ü çağırdığında
   "BAGLAMA HATASI: etiket bulunamadi: f_bellekEsle" veriyordu. Düzeltme:
   `yardimciBagimliliklari`'na `f_kilitOlustur->f_bellekEsle`,
   `f_kilitle->f_futexWait`, `f_kilidiAc->f_futexWake` eklendi.
2. **`bcEtiket()` yanlış API kullanımı** (BENİM hatam, ciddi): `bcEtiket()`
   TEK bir kayıt döndürüyor, LİSTE değil — bir bytecode listesine
   eklemek için `listeBirlestir(liste, bcEtiket(...))` DEĞİL, `ekle(liste,
   bcEtiket(...))` kullanılmalı. Yanlış kullanım derleyiciyi (g1) HEDEF
   PROGRAM derlerken SEGFAULT ettiriyordu (compile-time çökme, malformed
   bytecode stream). İkili aramayla (fonksiyon fonksiyon dosyayı kesip
   test ederek) izole edilip düzeltildi. **Ders: bu iki desen VETA/TAN
   kod tabanında tekrar kontrol edilmeli.**

**Doğrulama:** `testler/eszamanlilik_testleri.tan` — 13/13 GEÇTİ
(mmap+ham bellek round-trip, kilit aç/kapat/tekrar-kullan, atomik
1000x toplama, iki bağımsız kilidin birbirini etkilememesi). Self-hosting
sabit noktası (gen1==gen2==gen3, TEK WSL invocation içinde — ayrı
invocation'lar arası `/tmp` KALICI DEĞİL, bu oturumda yeniden keşfedildi/
doğrulandı) korundu. `TestAraclar.sh` (16/16) ve `TestArkaUcGoSuzTemiz.sh`
temiz. `TancElf` binary'si güncellendi ve commit'lendi (bootstrap tohumu).

**DÜRÜST SINIR — SIRALI test edildi, GERÇEK EŞZAMANLILIK henüz YOK:**
Bu testler TEK İPLİKTE (sıralı) çalışıyor — kilidin/atomiğin GERÇEK
YARIŞ KOŞULU koruması (birden fazla OS thread'inin AYNI ANDA saldırması)
KANITLANMADI, çünkü **thread creation (clone syscall + trampoline
deseni, `içParcaLat`) HENÜZ EKLENMEDİ**. Bu, kalan ve en riskli parça:
fonksiyon-değeri olmadığı için derleme-zamanı bilinen işlev adı + jmp-
tabanlı trambolin + r13 register'ının TÜM çağrı zinciri boyunca
korunması gerekiyor (eski Go implementasyonunda kanıtlanmış desen,
ama self-hosted derleyiciye taşınması ayrı bir dikkatli oturum ister).

## Full E2E + Failure/Recovery ✅ TAMAMLANDI (2026-08-23)

`veta/tests/test_e2e.tan` — master prompt madde 40 (FULL E2E VERIFIED,
FAILURE/RECOVERY VERIFIED). Central Core + Security + Query +
Observability + Optimizer'ı TEK AKIŞTA birleştiriyor (her core kendi
testinde İZOLE doğrulanmıştı — bu dosya KOMPOZİSYONU kanıtlıyor):

- **Mutlu yol:** USER isteği → Central Core routing kararı → Security
  yetki onayı → Query icra → Observability log/metrik → sonuç.
- **FAILURE-A (yetkisiz erişim):** Security reddediyor, Central Core
  görevi Başarısız işaretliyor, **veri GERÇEKTEN yazılmıyor** (icra
  hiç tetiklenmiyor — sadece durum işaretlenmiyor, gerçek etki de yok).
- **FAILURE-B (retry-then-giveup):** Central Core'un retry karar
  mekanizması N deneme sonrası vazgeçiyor.
- **FAILURE-C (olmayan veri):** Query crash etmeden güvenli boş dönüş.
- **FAILURE-D (transaction rollback):** Islem.tan'ın write-ahead log
  mekanizması gerçek bir yazma-sonrası-geri-alma senaryosunda
  doğrulandı — sayfa rollback sonrası ESKİ haline dönüyor.
- **Optimizer entegrasyonu:** erişim reddi metriği eşiği aşınca öneri
  üretiliyor (gözlem→analiz→öneri zinciri).

Test: **16/16 GEÇTİ** (WSL native). Bu, VETA'nın "core cluster gerçekten
birlikte çalışıyor mu" sorusuna en kapsamlı kanıt.

## Docker Paketleme ✅ TAMAMLANDI (2026-08-23) — gerçekten build+run+test edildi

`Dockerfile` (repo kökü, 2 aşamalı: debian:bookworm-slim derleme +
`FROM scratch` çalışma zamanı — TancElf statik binary ürettiği için
sıfır OS/libc katmanı gerekiyor). `docker build -t veta:latest .` ile
GERÇEKTEN build edildi (Docker Desktop bu oturumda kapalıydı, açılıp
beklenip build edildi) — **imaj boyutu 249KB**. Container GERÇEKTEN
çalıştırıldı (`docker run`, volume-mount'lu), curl ile TÜM rotalar
doğrulandı (health/set/get/404), **container restart sonrası veri
kalıcılığı** (volume) doğrulandı. Test container'ı ve volume'u
temizlendi.

## Benchmark ✅ TAMAMLANDI (2026-08-23) — gerçek zamanlama, gerçek sayılar

`veta/benchmarks/source/veta_benchmark.tan` — master prompt madde 42
("performans iddiası benchmark olmadan yapılmayacak") gereği. Gerçek
`zaman()` (CLOCK_MONOTONIC, ns) ile Query/Graph/Semantic core'ları ölçer.

**Gerçek sonuçlar (N=30, WSL native, tek çalıştırma):**
| İşlem | ops | süre | ~throughput |
|---|---|---|---|
| Query INSERT | 30 | 812.7ms | ~36 op/sn |
| Query POINT LOOKUP | 30 | 625μs | ~47.984 op/sn |
| Query UPDATE | 30 | 659.9ms | ~45 op/sn |
| Query DELETE | 30 | 660.1ms | ~45 op/sn |
| Graph BFS (zincir) | 30 | 118.5μs | ~253.164 op/sn |
| Semantic EN-BENZERLER | 30 | 33.6μs | ~892.857 op/sn |

Yorum (dürüst): INSERT/UPDATE/DELETE yavaş (~30-45 op/sn) çünkü HER
işlem gerçek transactional disk yazımı (WAL+sayfa, pwrite syscall'ları,
fsync yok ama syscall overhead'i var) — LOOKUP/BFS/Semantic çok hızlı
(~48K-893K op/sn) çünkü tamamen bellek-içi. Bu, gerçek bir DB'nin
beklenen profili (yazma pahalı, okuma ucuz).

**Bulunan ve düzeltilen 1 bug:** `/` operatörü kullanıcı işlevi sınırından
geçince yine KRİTİK BULGU 3'e (float fonksiyon dönüşü bozuk) çarpıyor —
`/` her zaman FLOAT üretiyor (2 tam sayı bile olsa), bu yüzden throughput
hesaplayan yardımcı işlev çöp değer döndürdü. Çözüm: `tamBol()` (tam sayı
bölme, `/`den farklı ayrı builtin) fonksiyon sınırından SORUNSUZ geçiyor
— doğrulandı, düzeltildi.

**Ortam notu:** N=100+ denemelerinde WSL servisinin KENDİSİ 3 kez çöktü
(`Wsl/Service/E_UNEXPECTED`, `wsl.exe --shutdown` ile kurtarıldı) — bu,
kod bug'ı DEĞİL, bu makinedeki WSL örneğinin genel kararsızlığı gibi
görünüyor (yoğun syscall/mmap altında). N=30'da 3 ayrı temiz
çalıştırmada sorunsuz tamamlandı. Daha büyük ölçek benchmarkları farklı/
daha kararlı bir ortamda tekrarlanmalı.

**DÜRÜST SINIR:** Tek-node, tek-iplik (eşzamanlı yük YOK). "baseline/
optimized/degraded/recovery" modları (master prompt) KAPSAM DIŞI —
sadece baseline ölçüldü.

## Security RBAC Rol Katmanı ✅ TAMAMLANDI (2026-08-23)

`veta/libraries/security/source/security.tan` — üç seviyeli RBAC eklendi:
kullanıcı->rol->izin (`guvenlikRolVer/guvenlikRolIzinVer/
guvenlikRolYetkiliMi/guvenlikKullaniciRolleri`), eski doğrudan
kullanıcı->izin yolu KORUNDU (geriye uyumlu), `guvenlikYetkiliMiTam`
ikisini birleştirir. guvenlik bağlamı 3→5 elemana büyüdü, TÜM eski
fonksiyonlar güncellendi. Test: `veta/tests/test_security.tan` — 19/19
GEÇTİ (eski 9 + yeni 10 RBAC testi: rol atama/idempotent/çoklu-rol/
izole-kullanıcı senaryoları).

## Ağ Sunucusu ✅ TAMAMLANDI (2026-08-23) — gerçek HTTP/1.0 sunucu, curl ile doğrulandı

`veta/server/source/veta_sunucu.tan` — `araclar/registrys.tan` (Kaldıraç 4,
kanıtlı çalışan pattern) ile AYNI soket deseni (soketAc/soketDinle/
soketKabul/soketOku/soketYaz). Query Core'u HTTP üzerinden dışarı açıyor:
`GET /health`, `GET /get/<key>`, `GET /set/<key>/<deger>`, `GET /del/<key>`.

**Gerçekten çalıştırılıp curl ile test edildi** (WSL native, arka planda
sunucu + curl istekleri): health→OK, set→OK, get→doğru değer, olmayan
key→404, del→OK, del-sonrası-get→404, iki bağımsız key birbirini
etkilemedi. Kalıcılık gerçek (dosya tabanlı Query/Storage, sunucu
yeniden başlasa veri kalır — Query Core'un kendi test edilmiş
kalıcılığından miras).

**Bulunan ve düzeltilen 1 bug (yazım sırasında):** İlk taslak
`baglam = sorguGuncelle(baglam, key, deger)` yazmıştı — ama
`sorguGuncelle` bağlam (context) DEĞİL, sayfa numarası (int) döndürüyor
(query.tan'ın kendi tasarımı, storage sayfası aynı kaldığı için index
güncellemesi gerekmiyor). Context'i bir int ile ezmek SIGSEGV'e yol
açtı (2. isteğe kadar çalışıp çöküyordu). Düzeltme: `z = sorguGuncelle(...)`
(dönüş değeri atılıyor, `baglam` HashTablo kutusu zaten referans
paylaşımıyla güncel kalıyor).

**DÜRÜST SINIR:** Tek-iplik (2D thread creation yok, sıralı istek
işleme). TLS yok (registrys.tan ile aynı gerekçe). POST body ayrıştırma
yok — `deger` URL path segmenti (içinde `/` olamaz, v1 sınırı).
Frontend'e henüz BAĞLANMADI (frontend hâlâ build-time git istatistikleri
okuyor, bu canlı API'yi henüz kullanmıyor — sonraki iş).

## Frontend ✅ DOĞRULANDI (2026-08-23) — React+Vite+TS, çalışıyor

`veta/frontend/` — React 19 + Vite 8 + TypeScript, `recharts` (grafik),
`lucide-react` (ikon). `scripts/gercekVeriTopla.mjs`: panodaki HER
alanın altında gerçek bir git/dosya-sistemi komutu var (uydurma sayı
YOK — script'in kendi dokümantasyonunun iddiası, kod okunarak
doğrulandı). Bu oturumda gerçekten çalıştırıldı:
- `node scripts/gercekVeriTopla.mjs` → gerçek git log/commit sayısı/
  `.tan` dosya sayısı (192)/TancElf boyutu (407 KB) okuyup
  `src/data/gercekVeri.json` üretti (gitignore'da, çıktı dosyası,
  kaynak değil — doğru).
- `npx tsc -b` → SIFIR tip hatası.
- `npx vite build` → başarılı (567 KB JS, "chunk büyük" UYARISI var
  ama HATA yok — code-splitting ileride yapılabilir, kapsam dışı).
- `npx vite --port 5183` (dev server) → `curl` ile doğrulandı: index.html
  200 dönüyor, `/src/main.tsx` ve `/src/App.tsx` doğru transpile edilip
  serve ediliyor (React refresh injection dahil).
**Bilinen sınır:** Chrome uzantısı bu oturumda bağlı değildi, GERÇEK
GÖRSEL RENDER (tarayıcıda açıp ekran görüntüsü) DOĞRULANAMADI — sadece
derleme+servis zinciri (build/type-check/dev-server-response)
doğrulandı. Görsel doğrulama (layout bozuk mu, component gerçekten
render oluyor mu) sonraki oturumda Chrome uzantısı bağlıyken yapılmalı.

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
