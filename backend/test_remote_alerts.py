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
    apns_key = os.getenv("APNS_KEY_ID")
    apns_team = os.getenv("APNS_TEAM_ID")
    apns_token = os.getenv("APNS_DEVICE_TOKEN")

    import glob
    has_p8 = bool(os.getenv("APNS_PRIVATE_KEY") or os.getenv("APNS_P8_PATH") or glob.glob("backend/AuthKey_*.p8") or glob.glob("AuthKey_*.p8"))

    print("\n🔍 Verifica canali notifiche remote:")
    print(f"  • Apple APNs Key (.p8): {' Configurato' if has_p8 else '❌ Mancante (richiede AuthKey_*.p8)'}")
    print(f"  • Apple APNs Team ID:   {' Configurato' if apns_team else '❌ Mancante'}")
    print(f"  • Apple APNs Key ID:    {' Configurato' if apns_key else '❌ Mancante'}")
    print(f"  • Apple Device Token:   {' Configurato' if apns_token else '⏳ In attesa dall\'iPhone'}")
    print(f"  • Telegram Bot Token:   {' Configurato' if tg_token else '❌ Mancante'}")
    print(f"  • Telegram Chat ID:     {' Configurato' if tg_chat else '❌ Mancante'}")
    print(f"  • OneSignal App ID:     {' Configurato' if os_app else '❌ Mancante'}")

    if not tg_token and not os_app and not (has_p8 and apns_token):
        print("\n⚠️ Nessun canale di notifica remota attivo pronto all'invio!")
        print("Configura i parametri Apple APNs (.p8) o Telegram in backend/.env per ricevere gli allarmi.")
    else:
        print("\n🚀 Invio allarme di prova in corso...")
        success = dispatch_remote_alerts(mock_critical_article)
        if success:
            print(" Allarme inviato con successo! Controlla il tuo iPhone.")
        else:
            print("⚠️ Invio parziale o non riuscito. Controlla i messaggi sopra per i dettagli.")
