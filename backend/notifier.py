"""
CyberNews Remote Alert Dispatcher
=================================
Invia notifiche push istantanee a costo zero a schermo spento
tramite Apple APNs (diretto con chiave .p8), Bot Telegram e OneSignal.
"""

import os
import html
import time
import requests
from typing import Dict, Any, List

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

def send_apns_alert(article: Dict[str, Any], device_token: str = None) -> bool:
    """Invia notifiche push native iOS direttamente tramite Apple APNs (HTTP/2 con chiave .p8)."""
    import glob
    
    key_id = os.getenv("APNS_KEY_ID")
    team_id = os.getenv("APNS_TEAM_ID")
    private_key_env = os.getenv("APNS_PRIVATE_KEY")
    p8_path = os.getenv("APNS_P8_PATH")
    bundle_id = os.getenv("APNS_BUNDLE_ID", "it.cybernews.app")
    use_sandbox = os.getenv("APNS_USE_SANDBOX", "true").lower() in ("true", "1")

    # Ricerca automatica file .p8 se non specificato direttamente
    clean_key = None
    if private_key_env:
        if os.path.exists(private_key_env):
            with open(private_key_env, "r", encoding="utf-8") as f:
                clean_key = f.read().strip()
        elif "BEGIN PRIVATE KEY" in private_key_env:
            clean_key = private_key_env.replace("\\n", "\n").strip()

    if not clean_key and p8_path and os.path.exists(p8_path):
        with open(p8_path, "r", encoding="utf-8") as f:
            clean_key = f.read().strip()

    if not clean_key:
        found_p8 = glob.glob("backend/AuthKey_*.p8") + glob.glob("AuthKey_*.p8")
        if found_p8:
            target_p8 = found_p8[0]
            with open(target_p8, "r", encoding="utf-8") as f:
                clean_key = f.read().strip()
            if not key_id:
                # Estrae il Key ID dal nome file AuthKey_XXXXXXXXXX.p8
                filename = os.path.basename(target_p8)
                if filename.startswith("AuthKey_") and filename.endswith(".p8"):
                    key_id = filename[len("AuthKey_"):-len(".p8")]

    if not clean_key:
        return False

    if not key_id or not team_id:
        print("⚠️ [APNs] Chiave .p8 rilevata ma mancano APNS_KEY_ID o APNS_TEAM_ID.")
        return False

    tokens: List[str] = []
    if device_token:
        tokens.append(device_token)
    elif os.getenv("APNS_DEVICE_TOKEN"):
        tokens.append(os.getenv("APNS_DEVICE_TOKEN"))

    # Cerca token registrati su Supabase se disponibile
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if supabase_url and supabase_key:
        try:
            from supabase import create_client
            sb = create_client(supabase_url, supabase_key)
            res = sb.table("device_tokens").select("device_token").execute()
            if res.data:
                for row in res.data:
                    t = row.get("device_token")
                    if t and t not in tokens:
                        tokens.append(t)
        except Exception:
            pass

    if not tokens:
        print("ℹ️ [APNs] Nessun device token iOS memorizzato. Apri l'app su iPhone per registrarlo.")
        return False

    try:
        import jwt
        jwt_token = jwt.encode(
            {"iss": team_id, "iat": int(time.time())},
            clean_key,
            algorithm="ES256",
            headers={"kid": key_id}
        )
    except Exception as e:
        print(f"❌ [APNs] Errore generazione token crittografico JWT: {e}")
        return False

    apns_host = "api.sandbox.push.apple.com" if use_sandbox else "api.push.apple.com"

    title = f"🚨 [{article.get('threat_level', 'CRITICO')}] {article.get('source_name', 'CyberNews')}"
    subtitle = article.get("title_it") or article.get("original_title") or "Allarme di Sicurezza"
    body = article.get("action_mitigation") or (article.get("summary_points", ["Nuovo allarme"])[0])

    payload = {
        "aps": {
            "alert": {
                "title": title,
                "subtitle": subtitle,
                "body": body
            },
            "sound": "default",
            "badge": 1
        },
        "article_id": article.get("id"),
        "url": article.get("source_url")
    }

    headers = {
        "authorization": f"bearer {jwt_token}",
        "apns-topic": bundle_id,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0"
    }

    success_count = 0
    try:
        import httpx
        with httpx.Client(http2=True, timeout=10.0) as client:
            for token in tokens:
                url = f"https://{apns_host}/3/device/{token}"
                try:
                    resp = client.post(url, json=payload, headers=headers)
                    if resp.status_code == 200:
                        print(f"📲 [APNs] Notifica push nativa inviata all'iPhone ({token[:8]}...)!")
                        success_count += 1
                    else:
                        print(f"⚠️ [APNs] Status {resp.status_code}: {resp.text}")
                except Exception as post_err:
                    print(f"❌ [APNs] Errore invio a {token[:8]}: {post_err}")
    except Exception as e:
        print(f"❌ [APNs] Errore client HTTP/2: {e}")

    return success_count > 0

def send_onesignal_alert(article: Dict[str, Any]) -> bool:
    """Invia una notifica push tramite OneSignal."""
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
    apns_sent = send_apns_alert(article)
    tg_sent = send_telegram_alert(article)
    os_sent = send_onesignal_alert(article)
    return apns_sent or tg_sent or os_sent
