# Ferrit Tool — Tech Spec (v0.1)

## 1. Стек
- Flutter (Dart >= 3.x)
- pdfx (PdfViewPinch + PdfControllerPinch)
- Хранение данных: JSON в assets (без БД в v0.1)

## 2. Структура проекта (рекоменд.)
lib/
  app/ (theme, routes)
  data/ (models, repositories, json loader)
  features/
    home/
    model/
    unit/
    symptom/
    pdf/
assets/
  pdfs/
  index/
docs/

## 3. PDF Viewer требования
- PdfViewPinch (pinch zoom + swipe)
- Быстрый переход:
  - jumpToPage(n)
  - UI:
    - AppBar action "страницы"
    - bottom sheet: список "узел → страница"
    - плюс поле ввода номера страницы / слайдер (по желанию)
- Ошибки:
  - если PDF не найден → показать “Схема не привязана” и скрыть кнопку открытия

## 4. Индексы страниц
assets/index/pdf_index.json
Формат:
{
  "dnk10": { "Передняя рама": 1, "Кабина": 2 },
  "dnk14": { ... },
  "dnk17": { ... }
}

Важно: номера страниц — реальные по PDF (как листает viewer), без “логических”.

## 5. Правило "без выдумывания"
Все значения типа:
- разъём (KP/KPR/KZS/…)
- контакт (pin number)
- провод/обозначение
- предохранитель/реле
берутся только из схем/таблиц.
Если чего-то нет — выводим "нет данных в схеме" (не подставляем предположения).

## 6. Версии
Версию приложения меняет только автор (ты). Любые предложения — через issue/PR.
