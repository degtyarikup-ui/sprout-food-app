# 🥑 Sprout — AI-Powered Zero-Waste Food Planner & Smart Cooking Assistant

<p align="center">
  <b>Умное планирование еды • Радар свежести холодильника • Zero-Waste Loop • Hands-Free Шеф</b>
</p>

<p align="center">
  <a href="https://degtyarikup-ui.github.io/sprout-food-app/"><b>🌐 Попробовать Web-версию онлайн</b></a>
</p>

---

## ✨ Ключевые возможности

- 🧊 **Мой Холодильник & Радар Свежести**: Отслеживание сроков годности продуктов (🔥 *Срочно*, ⏳ *3-5 дней*, 🌱 *Свежее*, ❄️ *Долгосрочно*).
- ⚡ **Алгоритм Zero-Waste Loop**: Автоматическое планирование рациона на 7 дней так, чтобы скоропортящиеся продукты использовались в первую очередь, а остатки ингредиентов переходили в блюда следующего дня.
- 📸 **Мультимодальный AI-сканер (Gemini Vision)**: Мгновенное распознавание чеков супермаркета и содержимого полок холодильника.
- 📱 **AI Social Video Importer**: Вставка ссылок из Instagram Reels, TikTok и YouTube с автоматической расшифровкой ингредиентов и таймингов.
- 👨‍🍳 **Hands-Free Cooking Mode**: Пошаговый режим приготовления с голосовым управлением, параллельными таймингами процессов и встроенными таймерами.
- 🛒 **Умный список покупок**: Группировка по отделам магазина (Овощи, Молочка, Мясо, Бакалея) и автоматический перенос купленного в Холодильник при вычеркивании.
- 🏆 **Эко-импакт & Экономия**: Дашборд сэкономленного бюджета, спасенных кг еды и предотвращенных выбросов CO2 с геймификацией и бейджами.

---

## 🛠 Технологический стек

- **Frontend**: Flutter 3 (Dart 3) — кроссплатформенная единая кодовая база (iOS, Android, Web, macOS).
- **State Management**: Riverpod (StateNotifier + Providers).
- **AI & Vision**: Google Gemini 1.5 Flash (Multimodal OCR, Recipe Transformation & Social Video Parsing).
- **UI / Design**: Fresh & Warm Modern / Minimalist Glassmorphism (Editorial Gastronomy).
- **Storage**: Offline-first Local Storage (SharedPreferences / Isar caching).

---

## 🚀 Запуск проекта

### 1. Клонирование репозитория
```bash
git clone https://github.com/degtyarikup-ui/sprout-food-app.git
cd sprout-food-app
```

### 2. Установка зависимостей
```bash
flutter pub get
```

### 3. Запуск на мобильном устройстве / эмуляторе
```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome

# macOS Desktop
flutter run -d macos
```

---

## 📄 Сборка для GitHub Pages
```bash
flutter build web --base-href "/sprout-food-app/" --release
```
