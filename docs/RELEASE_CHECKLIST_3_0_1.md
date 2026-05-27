# Release Checklist (v3.0.1)

Дата проверки: 2026-05-25

## Артефакты
- APK (release, signed, obfuscated): `build/app/outputs/flutter-apk/app-release.apk`
- AAB (release, signed, obfuscated): `build/app/outputs/bundle/release/app-release.aab`
- Symbols (для расшифровки крэшей): `build/symbols/`

## Подпись
- Используется release keystore через `android/key.properties`.
- В репозиторий секреты не коммитим (`android/key.properties`, `*.jks`, `*.keystore` в ignore).

## Проверка установки “с нуля”
- `adb uninstall com.example.ferrit_tool` -> Success
- `adb install app-release.apk` -> Success

## PDF performance — приоритет проверки
Самые тяжёлые PDF:
- `assets/pdfs/dnk17_schema.pdf` ~29.29 MB
- `assets/pdfs/dnk14_schema.pdf` ~21.21 MB

Минимальный smoke-тест на устройстве:
1. Открыть ПДМ-17 схему, проверить перелистывание и зум.
2. Открыть ПДМ-14 схему, проверить поиск и переходы.
3. Проверить автоскрытие оверлеев при свайпе/зуме.
4. Проверить поворот схемы.
5. Проверить возврат на последнюю страницу/масштаб после закрытия.
