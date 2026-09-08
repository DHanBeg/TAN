#!/bin/bash
# wal_crash_harness.sh — GERÇEK crash-injection testi (SIGKILL ile).
# Mevcut testler (storage_testleri.tan) crash'i AYNI process içinde
# simüle ediyor. Bu harness gerçek process ölümü üretir: yazıcıyı arka
# planda başlatır, kısa süre bekler, `kill -9` gönderir, SONRA tamamen
# ayrı bir recovery process'i çalıştırır.
#
# Kullanım: ./wal_crash_harness.sh <derleyici>   (örn. ./gen3)
# Çalışma dizini: repo kökü (testler/ ve kutuphane/ buradan görülmeli)

set -u
DERLEYICI="${1:-./gen3}"
BASARISIZ=0

echo "== wal_crash_harness: derleyici derliyor =="
"$DERLEYICI" testler/wal_crash_writer.tan /tmp/wal_crash_writer || { echo "DERLEME HATASI: writer"; exit 1; }
chmod +x /tmp/wal_crash_writer
"$DERLEYICI" testler/wal_crash_recover.tan /tmp/wal_crash_recover || { echo "DERLEME HATASI: recover"; exit 1; }
chmod +x /tmp/wal_crash_recover

calistir_senaryo() {
    local ad="$1" mod="$2" beklenen_prefix="$3"
    local db="/tmp/wal_crash_${ad}.db"
    local wal="/tmp/wal_crash_${ad}.wal"
    rm -f "$db" "$wal"

    echo "-- senaryo: $ad (mod=$mod) --"
    /tmp/wal_crash_writer "$db" "$wal" "$mod" > /tmp/wal_crash_writer_out.txt 2>&1 &
    yazici_pid=$!

    # yazıcının "HAZIR-BEKLIYOR" yazıp sonsuz döngüye girmesini bekle
    i=0
    while [ $i -lt 50 ]; do
        grep -q "HAZIR-BEKLIYOR" /tmp/wal_crash_writer_out.txt 2>/dev/null && break
        sleep 0.1
        i=$((i+1))
    done

    if ! grep -q "HAZIR-BEKLIYOR" /tmp/wal_crash_writer_out.txt 2>/dev/null; then
        echo "  [KALDI] yazici HAZIR-BEKLIYOR yazmadi (5sn timeout)"
        BASARISIZ=1
        kill -9 "$yazici_pid" 2>/dev/null
        wait "$yazici_pid" 2>/dev/null
        return
    fi

    kill -9 "$yazici_pid"
    wait "$yazici_pid" 2>/dev/null
    echo "  yazici GERCEKTEN oldurulmus (SIGKILL, pid $yazici_pid)"

    sonuc=$(/tmp/wal_crash_recover "$db" "$wal")
    echo "  recovery ciktisi: $sonuc"

    if echo "$sonuc" | grep -q "SONUC:${beklenen_prefix}"; then
        echo "  [GECTI] $ad: sayfa icerigi beklenen ('$beklenen_prefix' ile basliyor)"
    else
        echo "  [KALDI] $ad: sayfa icerigi beklenmedik (beklenen prefix: '$beklenen_prefix')"
        BASARISIZ=1
    fi
}

# Senaryo A: commit ÖNCESİ öldürüldü (commit marker hiç yazılmadı) —
# islemKurtar bunu UNDO etmeli, sayfa TABAN-DEGER'e dönmeli.
calistir_senaryo "uncommitted" "commitsiz" "TABAN-DEGER"

# Senaryo B: islemCommit() TAMAMEN dönmüş (commit marker yazılmış +
# dosyaSenkron çağrılmış), SONRA öldürüldü — gerçek process sınırında
# yeni bir process bu committed veriyi doğru görmeli (REDO/olduğu-gibi-
# kalma), YANLIŞLIKLA geri alınmamalı.
calistir_senaryo "committed" "commit" "CRASH-YAZIMI"

echo ""
if [ "$BASARISIZ" -eq 0 ]; then
    echo "WAL-CRASH-HARNESS: TUM SENARYOLAR GECTI"
    exit 0
else
    echo "WAL-CRASH-HARNESS: EN AZ BIR SENARYO KALDI"
    exit 1
fi
