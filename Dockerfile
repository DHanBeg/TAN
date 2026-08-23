# Dockerfile — VETA (Query Core HTTP sunucusu) container image.
# Master prompt madde 42 (production hardening) + kullanıcı isteği
# ("Docker tarzı program"). TancElf statik Linux ELF ürettiği için
# (dinamik bağımlılık YOK, doğrulandı) final imaj FROM scratch —
# tek dosya, ~200KB, hiçbir OS/libc katmanı yok.
#
# Derle:  docker build -t veta:latest .
# Çalıştır: docker run -p 8080:8080 -v veta-data:/data veta:latest
# Test:    curl http://localhost:8080/health

# ---- Aşama 1: derleme (TancElf zaten statik binary, repo'da mevcut) ----
FROM debian:bookworm-slim AS derleyici
WORKDIR /src
COPY . .
RUN mkdir -p /out && chmod +x ./TancElf && \
    ./TancElf veta/server/source/veta_sunucu.tan /out/veta_sunucu

# ---- Aşama 2: çalışma zamanı (sıfır bağımlılık, tek statik binary) ----
FROM scratch
COPY --from=derleyici /out/veta_sunucu /veta_sunucu
VOLUME ["/data"]
EXPOSE 8080
ENTRYPOINT ["/veta_sunucu", "8080", "/data/veta.db"]
