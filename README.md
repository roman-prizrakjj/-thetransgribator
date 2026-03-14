# Transgribator

Минималистичный транскрибер аудио и видео файлов через **Deepgram API**.

Видео конвертируется в лёгкий MP3 локально через **ffmpeg**, после чего отправляется на распознавание — даже гигабайтное видео улетает в Deepgram за секунды.

## Возможности

- Drag-and-drop или выбор файла
- Поддержка: mp3, wav, ogg, flac, aac, m4a, mp4, webm, mkv, avi, mov
- Видео → автоматическое извлечение аудио (ffmpeg, локально)
- Транскрипция через Deepgram Nova-3 / Nova-2 / Whisper
- Разбивка на абзацы, smart format
- Прогресс на каждом этапе
- Копирование и скачивание результата в .txt
- Тёмная тема

## Требования

- **Python 3.8+**
- **ffmpeg** в PATH ([скачать](https://ffmpeg.org/download.html))
- **Deepgram API ключ** ([получить](https://console.deepgram.com/))

## Запуск

```bash
git clone https://github.com/roman-prizrakjj/-thetransgribator.git
cd -thetransgribator
python server.py
```

Или на Windows — двойной клик по `start.bat`.

Открой в браузере: **http://localhost:8765/transcriber.html**

## Использование

1. Вставь Deepgram API ключ и нажми «Сохранить» (запомнится в браузере)
2. Выбери язык и модель
3. Перетащи аудио/видео файл
4. Нажми «Транскрибировать»
5. Скопируй или скачай результат

---

**PRIZRAKJJ** · [t.me/SafeVibeCode](https://t.me/SafeVibeCode)
