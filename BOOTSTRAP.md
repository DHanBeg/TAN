# BOOTSTRAP.md — TancElf'i sıfırdan üretme (tavuk-yumurta çözümü)

> Bu dosya 2026-09-07'de GÜNCEL/AKTİF talimat olarak yeniden yazıldı. Önceki
> içerik (Go→TAN geçiş döneminin tarihsel analizi, BootstrapGoSuz.sh/
> KanitGoSuzTarihce.sh üzerinden) SİLİNMEDİ —
> [BOOTSTRAP_TARIHSEL_ANALIZ.md](BOOTSTRAP_TARIHSEL_ANALIZ.md)'ye taşındı.

## Neden bu dosya var

TancElf (`TancElf.tan`) **kendi kendini derleyen** (self-hosted) bir
derleyicidir — kaynağı TAN dilinde yazılmıştır ve TAN kaynağını derlemek
için bir TAN derleyicisine ihtiyaç duyar. Bu klasik tavuk-yumurta
problemi: ilk derlemeyi yapacak bir derleyici yoksa, bu derleyicinin
kaynağı da derlenemez.

Repo bu yüzden **derlenmiş bir ikili TAKİP ETMEZ** (`.gitignore`'da
`TancElf`, `gen1`, `gen2`, `gen3`) — bayat bir ikili commit'te kalırsa
zamanla kaynak koddan sürüklenir ve sessizce yanlış davranır (bkz.
2026-09-07 denetimi: checked-in ikili 25e3a08/39bae3e düzeltmelerinden
ÖNCEydi, kimse fark etmemişti). Bunun yerine **seed** adında, sadece
bootstrap için var olan bir ikili GitHub Releases'a ayrı asset olarak
konur.

**Seed bir üretim derleyicisi DEĞİLDİR.** Tek işi: bu adımlardaki zinciri
başlatmak. Gerçek kullanılacak derleyici, bu zincirin ürettiği `gen2`/`gen3`dir.

## Ortam gereksinimi

TancElf ELF (x86-64 Linux) ikili üretir ve kendisi de bir ELF ikilidir.
**WSL (Ubuntu) veya native Linux x86-64 gerekir.** Windows üzerinde
doğrudan çalıştırılamaz.

## Adım 1 — seed'i indir

GitHub Releases'tan `tancelf-seed-<commit>` etiketli release'i bul, `seed`
asset'ini indir, çalıştırılabilir yap:

```bash
chmod +x seed
```

Seed hangi kaynak commit'inden üretildiyse (release notlarında yazar) o
commit'teki `TancElf.tan` ile eşleşir — farklı bir HEAD ile kullanmak
sorun değildir (bootstrap aracı, kendi kaynağını taşımaz) ama zincirin
SONUCU her zaman **şu an checkout ettiğin `TancElf.tan`** olur.

## Adım 2 — bootstrap zinciri

Repo kökünde, WSL içinde:

```bash
./seed TancElf.tan gen1 && chmod +x gen1
./gen1 TancElf.tan gen2 && chmod +x gen2
./gen2 TancElf.tan gen3 && chmod +x gen3
```

Her adım aynı şeyi yapar: mevcut derleyiciyle `TancElf.tan`'ın KENDİSİNİ
derleyip bir sonraki nesli üretir.

## Adım 3 — sabit noktayı doğrula

```bash
md5sum gen1 gen2 gen3
```

**Beklenen: `gen2` ve `gen3` birebir aynı (byte-eşit).** `gen1` FARKLI
olabilir — bu bilinen ve zararsız bir durum (seed'in kod üretim/erişilebilirlik
budaması, güncel kaynaktan biraz farklı olabilir; seed'in ürettiği gen1 kendi
kaynağını derlerken düzelir). Asıl garanti gen2==gen3'tür: derleyici artık
kendi çıktısını tekrar tekrar üretse de DEĞİŞMİYOR — kendi kaynağını doğru
derlediğinin kanıtı.

`gen2` ≠ `gen3` çıkarsa (sabit nokta YOK) bu ciddi bir regresyondur —
`TancElf.tan`'a yakın zamanda giren bir değişiklik derleyicinin kendi
kaynağını tutarsız derlemesine yol açmış demektir. Kod incelemesi/bisection
gerekir, `gen3`'ü kullanma.

## Adım 4 — çalıştığını doğrula (opsiyonel ama önerilir)

Sabit nokta byte-eşitliği tek başına "derleyici çalışıyor" demek değildir —
"kendini tutarlı üretiyor" demektir. Gerçekten iş gördüğünü test etmek için:

```bash
./gen3 testler/kesir_tip_cikarimi_testleri.tan /tmp/smoke && chmod +x /tmp/smoke && /tmp/smoke
```

`SONUC: 8/8 gecti` + `TUM TESTLER GECTI` bekleniyor. Daha kapsamlı doğrulama
için `TestAraclar.sh` içindeki döngüyü `gen3`'e işaret ederek çalıştır
(script kendisi `./TancElf`'i hardcode eder, `gen3`'ü `cp gen3 TancElf`
ile geçici olarak kullanabilir ya da script içindeki komutu manuel çalıştır
— `TancElf`'i kalıcı olarak tekrar commit ETME, `.gitignore`'da kalmalı).

## Adım 5 — üretim derleyicisini yerine koy

```bash
cp gen3 TancElf   # ya da gen2, ikisi de aynı
```

Bu dosya `.gitignore`'da olduğu için commit edilmez — her klon/CI çalışması
kendi `TancElf`'ini bu zincirle üretir.

## Yeni seed ne zaman üretilir

Sadece TancElf.tan'da derleyicinin KENDİ kaynağını derleme davranışını
değiştiren bir düzeltme yapıldığında (ör. bir dil özelliği eklenip
derleyicinin kendi kodu o özelliği kullanmaya başladığında) seed'in
GÜNCELLENMESİ gerekebilir — ama bu ZORUNLU değildir, çünkü seed sadece
zinciri başlatan araçtır, doğru kaynak+doğru zincir her zaman doğru
gen2/gen3 üretir (bkz. bu dosyanın "seed bir üretim derleyicisi DEĞİLDİR"
notu). Seed'i güncellemek istersen: mevcut `gen3`'ü (ya da eski seed'i
ARAÇ olarak kullanıp güncel `TancElf.tan`'dan üretilmiş bir `gen2`/`gen3`'ü)
yeni seed olarak yeni bir GitHub Release'e yükle — **asla o an takip
edilen/bayat bir ikiliyi seed olarak kullanma**, aksi halde eski
bug'lar seed üzerinden geleceğe sızabilir.
