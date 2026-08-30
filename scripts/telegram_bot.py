#!/usr/bin/env python3
"""
Sprout Telegram Mini App Bot
Web App URL: https://degtyarikup-ui.github.io/sprout-food-app/
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse
from pathlib import Path

# Load .env if present
def load_env():
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

load_env()

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
WEB_APP_URL = os.environ.get("WEB_APP_URL", "https://degtyarikup-ui.github.io/sprout-food-app/")
API_BASE = f"https://api.telegram.org/bot{BOT_TOKEN}"

if not BOT_TOKEN:
    print("Error: TELEGRAM_BOT_TOKEN not found in environment or .env file!", file=sys.stderr)
    sys.exit(1)

def api_call(method, payload=None):
    url = f"{API_BASE}/{method}"
    headers = {"Content-Type": "application/json"}
    data = json.dumps(payload).encode("utf-8") if payload else None
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"API Error ({method}): {e}", file=sys.stderr)
        return None

def setup_bot():
    # 1. Set Menu Button
    api_call("setChatMenuButton", {
        "menu_button": {
            "type": "web_app",
            "text": "Открыть Sprout 🥑",
            "web_app": {"url": WEB_APP_URL}
        }
    })

    # 2. Set Description
    api_call("setMyDescription", {
        "description": (
            "🥑 Sprout — персональный Шеф-ИИ, умный планировщик меню на неделю и безотходная кухня.\n\n"
            "📸 Распознавание продуктов в холодильнике по фото и чекам\n"
            "📋 Индивидуальный рацион на 7 дней под ваши цели\n"
            "👨‍👩‍👧 Совместный семейный доступ к холодильнику и меню\n"
            "🛒 Умный список покупок"
        )
    })

    # 3. Set Short Description
    api_call("setMyShortDescription", {
        "short_description": "🥑 Персональный Шеф-ИИ, умный холодильник и меню на неделю."
    })

    # 4. Set Commands
    api_call("setMyCommands", {
        "commands": [
            {"command": "start", "description": "🥑 Запустить Sprout Mini App"},
            {"command": "app", "description": "🚀 Открыть приложение"},
            {"command": "family", "description": "👨‍👩‍👧 Семейный доступ"}
        ]
    })
    print("Bot configuration synchronized successfully!")

def handle_update(update):
    message = update.get("message")
    if not message:
        return

    chat_id = message.get("chat", {}).get("id")
    text = (message.get("text") or "").strip()
    first_name = message.get("from", {}).get("first_name", "друг")

    if not chat_id:
        return

    start_param = ""
    if text.startswith("/start"):
        parts = text.split(" ")
        if len(parts) > 1:
            start_param = parts[1]

    web_app_url = WEB_APP_URL
    if start_param:
        web_app_url = f"{WEB_APP_URL}?startapp={start_param}"

    welcome_text = (
        f"Привет, {first_name}! 🥑\n\n"
        "Добро пожаловать в **Sprout** — твой персональный Шеф-ИИ и умный помощник по питанию.\n\n"
        "✨ **Что умеет Sprout:**\n"
        "• 📸 Распознает продукты в холодильнике по фото и чекам\n"
        "• 🥗 Составляет меню на 7 дней из того, что уже есть\n"
        "• 👨‍👩‍👧 Ведет общий холодильник и рацион для всей семьи\n"
        "• 🛒 Формирует умный список покупок\n\n"
        "Нажми кнопку ниже, чтобы запустить приложение прямо в Telegram 👇"
    )

    reply_markup = {
        "inline_keyboard": [
            [
                {
                    "text": "🥑 Открыть Sprout Mini App",
                    "web_app": {"url": web_app_url}
                }
            ],
            [
                {
                    "text": "👨‍👩‍👧 Семейный доступ",
                    "web_app": {"url": web_app_url}
                }
            ]
        ]
    }

    api_call("sendMessage", {
        "chat_id": chat_id,
        "text": welcome_text,
        "parse_mode": "Markdown",
        "reply_markup": reply_markup
    })

def run_polling():
    setup_bot()
    print("Starting Telegram Bot long-polling...")
    last_update_id = 0
    while True:
        try:
            updates = api_call("getUpdates", {
                "offset": last_update_id + 1,
                "timeout": 20
            })
            if updates and updates.get("ok"):
                for item in updates.get("result", []):
                    last_update_id = item["update_id"]
                    handle_update(item)
            time.sleep(0.5)
        except Exception as e:
            print(f"Polling loop error: {e}", file=sys.stderr)
            time.sleep(2)

if __name__ == "__main__":
    run_polling()
