#!/usr/bin/env python3
"""flutter create ile üretilen android/ klasörünü yayına hazırlar:
 - release imzası: android/key.properties varsa gerçek anahtar, yoksa debug (yalnızca test)
 - INTERNET izni, uygulama adı
Hem Kotlin DSL (build.gradle.kts) hem Groovy (build.gradle) için çalışır.
Beklenen yapı bulunamazsa hata verir (sessizce başarısız olmaz)."""
import re
import sys
from pathlib import Path

app = Path("android/app")
kts, groovy = app / "build.gradle.kts", app / "build.gradle"


def fail(msg):
    print("HATA:", msg)
    sys.exit(1)


if kts.exists():
    f, s = kts, kts.read_text(encoding="utf-8")
    if "keystoreProperties" in s:
        print("build.gradle.kts zaten yamalı")
    else:
        header = "import java.util.Properties\nimport java.io.FileInputStream\n\n"
        load = (
            "val keystoreProperties = Properties()\n"
            'val keystorePropertiesFile = rootProject.file("key.properties")\n'
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        signing = (
            "    signingConfigs {\n"
            '        create("release") {\n'
            '            keyAlias = keystoreProperties["keyAlias"] as String?\n'
            '            keyPassword = keystoreProperties["keyPassword"] as String?\n'
            '            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }\n'
            '            storePassword = keystoreProperties["storePassword"] as String?\n'
            "        }\n"
            "    }\n\n"
        )
        if not re.search(r"^android\s*\{", s, re.M) or "buildTypes" not in s:
            fail("build.gradle.kts beklenen yapıda değil")
        s = re.sub(r"^android\s*\{", load + "android {", s, count=1, flags=re.M)
        s = re.sub(r"^(\s*)buildTypes\s*\{", signing + r"\1buildTypes {", s, count=1, flags=re.M)
        new, n = re.subn(
            r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
            'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
            s,
        )
        if n != 1:
            fail("release signingConfig satırı bulunamadı")
        f.write_text(header + new, encoding="utf-8")
elif groovy.exists():
    f, s = groovy, groovy.read_text(encoding="utf-8")
    if "keystoreProperties" in s:
        print("build.gradle zaten yamalı")
    else:
        load = (
            "def keystoreProperties = new Properties()\n"
            "def keystorePropertiesFile = rootProject.file('key.properties')\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        signing = (
            "    signingConfigs {\n"
            "        release {\n"
            "            keyAlias keystoreProperties['keyAlias']\n"
            "            keyPassword keystoreProperties['keyPassword']\n"
            "            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n"
            "            storePassword keystoreProperties['storePassword']\n"
            "        }\n"
            "    }\n\n"
        )
        if not re.search(r"^android\s*\{", s, re.M) or "buildTypes" not in s:
            fail("build.gradle beklenen yapıda değil")
        s = re.sub(r"^android\s*\{", load + "android {", s, count=1, flags=re.M)
        s = re.sub(r"^(\s*)buildTypes\s*\{", signing + r"\1buildTypes {", s, count=1, flags=re.M)
        new, n = re.subn(
            r"signingConfig\s+signingConfigs\.debug",
            "signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug",
            s,
        )
        if n != 1:
            fail("release signingConfig satırı bulunamadı")
        f.write_text(new, encoding="utf-8")
else:
    fail("android/app/build.gradle(.kts) bulunamadı")

manifest = app / "src/main/AndroidManifest.xml"
m = manifest.read_text(encoding="utf-8")
if "android.permission.INTERNET" not in m:
    m = m.replace("<application", '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="Altın Takip"', m, count=1)
manifest.write_text(m, encoding="utf-8")
print("Android yapılandırması hazır:", f)
