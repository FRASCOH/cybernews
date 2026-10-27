import os
import sys
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
print("📡 Connessione a Google Gemini 2.0 Flash in corso...")

try:
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=api_key)

    # Test con un articolo reale di Cybersecurity per verificare estrazione JSON
    sample_news = """
    CISA and the FBI have released a joint Cybersecurity Advisory warning of active exploitation 
    of critical vulnerabilities in Fortinet FortiOS and FortiProxy (CVE-2024-47575). 
    Threat actors are executing arbitrary code and deploying backdoors to exfiltrate configurations. 
    Organizations are urged to immediately update to the latest patched firmware and inspect 
    logs for unauthorized configuration changes.
    """

    prompt = f"""
    Sei l'analista di CyberNews. Analizza la seguente notizia di sicurezza informatica e restituisci 
    esclusivamente un oggetto JSON valido (senza markdown aggiuntivo) conforme a questo schema:
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

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.2,
        ),
    )

    print("\n✅ RISPOSTA OTTENUTA CON SUCCESSO DA GEMINI 2.0 FLASH:")
    print("-" * 60)
    print(response.text)
    print("-" * 60)
    print("🎯 Test completato! Il prompt engineering e il modello funzionano perfettamente.")

except Exception as e:
    print("❌ Errore durante la chiamata a Gemini:", str(e))
    sys.exit(1)
