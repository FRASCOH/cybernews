import os
import sys
import json
import requests
from dotenv import load_dotenv

# Carica le variabili da .env
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

if not api_key or api_key.strip() == "":
    print("❌ ERRORE: GEMINI_API_KEY non trovata o vuota nel file backend/.env")
    print("👉 Apri il file backend/.env e inserisci la tua chiave API:")
    print("   GEMINI_API_KEY=AIzaSy...")
    sys.exit(1)

print("🔑 Chiave API rilevata (lunghezza:", len(api_key), "caratteri)")
print("📡 Connessione a Google Gemini (Modello Flash)...")

sample_news = """
CISA and the FBI have released a joint Cybersecurity Advisory warning of active exploitation 
of critical vulnerabilities in Fortinet FortiOS and FortiProxy (CVE-2024-47575). 
Threat actors are executing arbitrary code and deploying backdoors to exfiltrate configurations. 
Organizations are urged to immediately update to the latest patched firmware and inspect 
logs for unauthorized configuration changes.
"""

prompt = f"""
Sei l'analista di CyberNews. Analizza la seguente notizia di sicurezza informatica e restituisci 
esclusivamente un oggetto JSON valido conforme a questo schema:
{{
    "title_it": "Titolo chiaro, sintetico e tecnico in italiano (max 75 caratteri)",
    "summary_points": [
        "Punto 1: Cosa è successo in dettaglio",
        "Punto 2: Chi o cosa è a rischio / CVE coinvolte",
        "Punto 3: Dettaglio tecnico dell'attacco o della norma"
    ],
    "action_mitigation": "Azione precisa e operativa che deve compiere il CISO / SysAdmin / DPO",
    "threat_level": "CRITICO | ALTO | MEDIO | INFORMATIVO",
    "category": "NIS2_GOLDEN_POWER | VULNERABILITA_ZERODAY | RANSOMWARE_ATTACCHI | COMPLIANCE_ISO | THREAT_INTEL",
    "target_audience": "SysAdmin | CISO | DPO | DevOps",
    "tags": ["Tag1", "Tag2", "Tag3"]
}}

Notizia:
{sample_news}
"""

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={api_key}"
headers = {"Content-Type": "application/json"}
payload = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {
        "responseMimeType": "application/json",
        "temperature": 0.1
    }
}

try:
    response = requests.post(url, headers=headers, json=payload, timeout=20)
    if response.status_code == 200:
        data = response.json()
        raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
        parsed = json.loads(raw_text)

        print("\n✅ RISPOSTA OTTENUTA CON SUCCESSO DA GEMINI:")
        print("=" * 65)
        print(f"📌 TITOLO IT: {parsed.get('title_it')}")
        print(f"⚠️ RISCHIO:   {parsed.get('threat_level')}")
        print(f"🏷️ CATEGORIA: {parsed.get('category')}")
        print(f"🎯 TARGET:    {parsed.get('target_audience')}")
        print("\n📝 PUNTI CHIAVE:")
        for idx, p in enumerate(parsed.get("summary_points", []), 1):
            print(f"   {idx}. {p}")
        print(f"\n⚡ AZIONE CONSIGLIATA: {parsed.get('action_mitigation')}")
        print(f"🏷️ TAGS: {', '.join(parsed.get('tags', []))}")
        print("=" * 65)
        print("🎯 Test completato con successo! Il modello risponde velocemente e con il formato perfetto.")
    else:
        print(f"❌ Errore HTTP {response.status_code}: {response.text}")
        sys.exit(1)

except Exception as e:
    print("❌ Errore durante la chiamata a Gemini:", str(e))
    sys.exit(1)
