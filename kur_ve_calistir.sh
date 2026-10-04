#!/bin/bash
# Altın Takip - tek seferlik kurulum. Mevcut Flutter kurulumunu kullanır.
# Kullanım:  cd AltinTakip && bash kur_ve_calistir.sh
set -e
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter bulunamadı. Terminal'i yeniden açın veya flutter'ı PATH'e ekleyin."; exit 1
fi

# 1) Platform klasörlerini (android, ios, web, macos, windows, linux) üret.
if [ ! -d macos ] || [ ! -d android ]; then
  echo ">> Platform klasörleri oluşturuluyor..."
  TMP="$(mktemp -d)"
  flutter create --org com.altintakip --project-name altin_takip \
    --platforms=android,ios,web,macos,windows,linux "$TMP/scaffold" >/dev/null
  for d in android ios web macos windows linux; do
    [ -d "$TMP/scaffold/$d" ] && [ ! -d "$d" ] && cp -R "$TMP/scaffold/$d" "./$d"
  done
  [ -f .metadata ] || cp "$TMP/scaffold/.metadata" .metadata
  rm -rf "$TMP"
fi

# 2) macOS: internet erişimi için ağ izni (olmazsa fiyatlar hiç gelmez).
for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
  if [ -f "$f" ] && ! grep -q "com.apple.security.network.client" "$f"; then
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.network.client bool true" "$f" 2>/dev/null || true
    echo ">> $f içine ağ izni eklendi"
  fi
done

# 3) Android: release sürümü için INTERNET izni.
M=android/app/src/main/AndroidManifest.xml
if [ -f "$M" ] && ! grep -q "android.permission.INTERNET" "$M"; then
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M" && rm -f "$M.bak"
  echo ">> Android INTERNET izni eklendi"
fi

echo ">> Paketler indiriliyor..."
flutter pub get
echo ">> Statik analiz..."
flutter analyze || true
echo ">> Testler..."
flutter test

echo ""
echo "Hazır. Uygulamayı başlatmak için:  flutter run -d macos"
echo "(Tarayıcıda denemek için: flutter run -d chrome)"
