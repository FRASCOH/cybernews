"""
CyberNews Remote Alert Dispatcher
=================================
Invia notifiche push istantanee a costo zero a schermo spento
tramite Bot Telegram e/o OneSignal quando viene rilevata una
minaccia CRITICA (Zero-Day) o un provvedimento ad alta priorità.
"""

import os
import html
import requests
from typing import Dict, Any

def send_telegram_alert(article: Dict[str, Any]) -> bool:
    """Invia un messaggio di allarme formattato al Bot / Canale Telegram."""
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    chat_id = os.getenv("TELEGRAM_CHAT_ID")
    if not token or not chat_id:
        return False

    title = html.escape(article.get("title_it") or article.get("original_title") or "Allarme di Sicurezza")
    source = html.escape(article.get("source_name") or "CyberNews")
    threat = article.get("threat_level", "CRITICO")
    action = html.escape(article.get("action_mitigation") or "Consultare il bollettino ufficiale.")
    target = html.escape(article.get("target_audience") or "CISO / SysAdmin")
    url = article.get("source_url") or "https://www.acn.gov.it"
    
    points = article.get("summary_points") or []
    points_text = ""
    for idx, p in enumerate(points[:3]):
        points_text += f"\n  <b>{idx + 1}.</b> {html.escape(p)}"

    raw_tags = article.get("tags") or []
    tags = " ".join([f"#{t.replace(' ', '_').replace('-', '_')}" for t in raw_tags[:5]])

    icon = "🚨" if threat == "CRITICO" else "🛡️"

    message = f"""{icon} <b>CYBERNEWS ALERT [{threat}]</b>
━━━━━━━━━━━━━━━━━━━━
📌 <b>{title}</b>

🏢 <b>Fonte:</b> {source}
🎯 <b>Target:</b> {target}

⚡ <b>Azione Consigliata:</b>
👉 <i>{action}</i>

🔍 <b>Punti Chiave (Analisi AI):</b>{points_text}

🏷️ {tags}
🔗 <a href="{url}">Consulta Bollettino Ufficiale</a>
"""

    api_url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "HTML",
        "disable_web_page_preview": False
    }

    try:
        resp = requests.post(api_url, json=payload, timeout=10)
        if resp.status_code == 200:
            print(f"📲 [TELEGRAM] Push inviata: '{title[:35]}...'")
            return True
        else:
            print(f"⚠️ [TELEGRAM] Status {resp.status_code}: {resp.text}")
            return False
    except Exception as e:
        print(f"❌ [TELEGRAM] Errore chiamata: {e}")
        return False

def send_onesignal_alert(article: Dict[str, Any]) -> bool:
    """Invia una notifica push nativa tramite le API di OneSignal."""
    app_id = os.getenv("ONESIGNAL_APP_ID")
    api_key = os.getenv("ONESIGNAL_REST_API_KEY")
    if not app_id or not api_key:
        return False

    title = article.get("title_it") or article.get("original_title") or "Allarme CyberNews"
    threat = article.get("threat_level", "CRITICO")
    source = article.get("source_name", "CyberNews")
    action = article.get("action_mitigation") or "Nuovo aggiornamento critico."
    url = article.get("source_url")

    headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": f"Basic {api_key}"
    }

    payload = {
        "app_id": app_id,
        "included_segments": ["All"],
        "headings": {"en": f"🚨 [{threat}] {source}", "it": f"🚨 [{threat}] {source}"},
        "contents": {"en": title, "it": title},
        "subtitle": {"en": action, "it": action},
        "url": url,
        "ios_sound": "default",
        "priority": 10
    }

    try:
        resp = requests.post("https://onesignal.com/api/v1/notifications", json=payload, headers=headers, timeout=10)
        if resp.status_code == 200:
            print("📲 [ONESIGNAL] Push remoto inviato con successo.")
            return True
        else:
            print(f"⚠️ [ONESIGNAL] Status {resp.status_code}: {resp.text}")
            return False
    except Exception as e:
        print(f"❌ [ONESIGNAL] Errore chiamata: {e}")
        return False

def dispatch_remote_alerts(article: Dict[str, Any]):
    """Spedisce le notifiche remote attraverso tutti i canali attivi."""
    tg = send_telegram_alert(article)
    os_sent = send_onesignal_alert(article)
    return tg or os_sent
