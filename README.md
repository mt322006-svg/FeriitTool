# Ferrit Tool — skeleton v0.1

Каркас: **техника → модель → узел → симптом → чек-лист + просмотр PDF схем внутри приложения**.

## Как запустить
1) Создай Flutter проект (или вставь этот `lib/` к себе).
2) Установи зависимости:
```bash
flutter pub get
```

3) Положи схемы в папку:
```
assets/pdfs/
```
Пример имён: `dnk10_schema.pdf`, `dnk14_schema.pdf`, `dnk17_schema.pdf`

4) В `pubspec.yaml` уже добавлен assets путь:
```yaml
assets:
  - assets/pdfs/
```

## Где привязка PDF к модели
`lib/screens/symptom_screen.dart` → функция `_guessPdfForModel()`.

---
Цель: **красиво + быстро + оффлайн**.
