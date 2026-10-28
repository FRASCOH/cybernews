"""
Test Remote Alerts (Telegram & OneSignal)
=========================================
Esegui questo script per verificare l'invio istantaneo di un allarme di prova
sul tuo Bot Telegram o tramite OneSignal.

Uso:
  python backend/test_remote_alerts.py
"""

import os
from dotenv import load_dotenv
from notifier import dispatch_remote_alerts

load_dotenv()

mock_critical_article = {
    "id": "test-cve-2026",
    "title_it": "Vulnerabilità RCE Zero-Day PHP2Shell (Test Push Remoto)",
    "original_title": "PHP2Shell Critical RCE actively exploited in the wild",
    "summary_points": [
        "Vulnerabilità critica confermata con sfruttamento attivo in corso su target governativi ed enterprise.",
        "Consente l'esecuzione di codice arbitrario da remoto (RCE) senza credenziali di autenticazione.",
        "CISA e CSIRT Italia raccomandano l'applicazione prioritaria delle patch d'emergenza."
    ],
    "action_mitigation": "Aggiornare immediatamente i cluster esposti alla versione corretta o bloccare l'accesso WAN.",
    "threat_level": "CRITICO",
    "category": "VULNERABILITA_ZERODAY",
    "target_audience": "SysAdmin & CISO",
    "tags": ["PHP2Shell", "Zero-Day", "RCE", "CISA", "CSIRT"],
    "source_name": "CSIRT Italia",
    "source_url": "https://www.csirt.gov.it",
    "published_at": "Adesso"
}

if __name__ == "__main__":
    tg_token = os.getenv("TELEGRAM_BOT_TOKEN")
    tg_chat = os.getenv("TELEGRAM_CHAT_ID")
    os_app = os.getenv("ONESIGNAL_APP_ID")

    print("\n🔍 Verifica configurazione notifiche remote:")
    print(f"  • Telegram Bot Token: {' Configurato' if tg_token else '❌ Mancante'}")
    print(f"  • Telegram Chat ID:   {' Configurato' if tg_chat else '❌ Mancante'}")
    print(f"  • OneSignal App ID:   {' Configurato' if os_app else '❌ Mancante'}")

    if not tg_token and not os_app:
        print("\n⚠️ Nessun canale di notifica remota configurato in backend/.env!")
        print("Aggiungi TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID nel tuo file backend/.env per ricevere gli alert su iPhone.")
    else:
        print("\n🚀 Invio allarme di prova in corso...")
        success = dispatch_remote_alerts(mock_critical_article)
        if success:
            print(" Allarme inviato! Controlla il tuo iPhone.")
        else:
            print("⚠️ Invio non riuscito. Controlla i log sopra per i dettagli.")
