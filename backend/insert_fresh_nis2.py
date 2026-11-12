import os
import sys
import json
import hashlib
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
from supabase import create_client
from audio_generator import generate_article_audio

load_dotenv("backend/.env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print("❌ Credenziali Supabase mancanti.")
    sys.exit(1)

client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

now = datetime.now(timezone.utc)

fresh_nis2_articles = [
    {
        "id": "nis2_" + hashlib.md5(b"acn_linee_guida_notifica_incidenti_2026").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://www.acn.gov.it/nis2/linee-guida-notifiche-2026").hexdigest(),
        "title_it": "ACN: Linee guida definitive sulla notifica obbligatoria degli incidenti NIS2",
        "original_title": "ACN issues final guidelines on NIS2 mandatory early warning incident notifications",
        "summary_points": [
            "L'Agenzia per la Cybersicurezza Nazionale ha emanato la circolare applicativa del D.Lgs. 138/2024 con la tempistica perentoria di allerta precoce entro 24 ore.",
            "Tutti i soggetti essenziali e importanti devono integrare i propri SIEM e SOC con i canali di reporting sicuro del CSIRT Italia.",
            "Definite le soglie quantitative di impatto: interruzione di servizi oltre 2 ore o violazione di dati confidenziali richiedono notifica immediata."
        ],
        "action_mitigation": "Aggiornare il piano di Incident Response aziendale formalizzando i flussi di escalation e testare le credenziali di accesso al portale ACN.",
        "threat_level": "ALTO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "CISO & DPO",
        "tags": ["NIS2", "ACN", "CSIRT", "Compliance", "IncidentResponse", "D.Lgs.138/2024"],
        "source_name": "ACN",
        "source_url": "https://www.acn.gov.it/comunicati/nis2-linee-guida-notifiche",
        "published_at": "Oggi, 15:45",
        "created_at": (now - timedelta(hours=1)).isoformat(),
        "is_breaking": True
    },
    {
        "id": "nis2_" + hashlib.md5(b"golden_power_cloud_datacenter_veto_2026").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://governo.it/golden-power-cloud-delibera-2026").hexdigest(),
        "title_it": "Golden Power: Prescrizioni restrittive su accordi cloud e datacenter critici",
        "original_title": "Government imposes Golden Power security vetoes on critical hyperscale cloud tenders",
        "summary_points": [
            "Il Consiglio dei Ministri ha deliberato l'esercizio dei poteri speciali Golden Power con severe prescrizioni di sovranità tecnologica.",
            "Imposta la localizzazione esclusiva dei dati sensibili e delle chiavi di cifratura (HSM) entro i confini dello Spazio Economico Europeo.",
            "Obbligo di audit semestrale e validazione preventiva del codice sorgente affidata ai laboratori accreditati CVCN."
        ],
        "action_mitigation": "Effettuare una revisione legale e architetturale di tutti i contratti in essere con fornitori cloud extra-UE per verificare la conformità ai vincoli Golden Power.",
        "threat_level": "CRITICO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "CISO & Legal",
        "tags": ["GoldenPower", "Cloud", "SovranitaDigitale", "CVCN", "InfrastruttureStrategiche"],
        "source_name": "Presidenza del Consiglio",
        "source_url": "https://governo.it/it/dipartimenti/dipartimento-il-coordinamento-amministrativo/golden-power",
        "published_at": "Oggi, 11:20",
        "created_at": (now - timedelta(hours=4)).isoformat(),
        "is_breaking": False
    },
    {
        "id": "nis2_" + hashlib.md5(b"sanita_asl_obblighi_nis2_scadenza").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://cybersecurity360.it/sanita-nis2-scadenze-2026").hexdigest(),
        "title_it": "Sanità e NIS2: Scadenza per l'adozione delle misure minime di sicurezza nelle ASL",
        "original_title": "Healthcare sector accelerates NIS2 cybersecurity controls ahead of compliance deadline",
        "summary_points": [
            "Ospedali, aziende sanitarie e laboratori diagnostici classificati come soggetti essenziali devono dimostrare la postura cyber.",
            "Richiesta l'implementazione obbligatoria di autenticazione a più fattori (MFA) su tutti gli accessi remoti e segmentazione delle cartelle cliniche.",
            "Previsti contributi ACN del PNRR per l'adeguamento delle infrastrutture sanitarie contro attacchi ransomware."
        ],
        "action_mitigation": "Isolare i dispositivi elettromedicali e i database sanitari in VLAN dedicate protette da firewall di nuova generazione e crittografia at-rest.",
        "threat_level": "ALTO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "CIO & CISO Sanità",
        "tags": ["Sanità", "NIS2", "CartellaClinica", "MFA", "Ospedali", "PNRR"],
        "source_name": "Cybersecurity360",
        "source_url": "https://www.cybersecurity360.it/normative/sanita-nis2-requisiti-minimi",
        "published_at": "Ieri, 17:30",
        "created_at": (now - timedelta(days=1, hours=2)).isoformat(),
        "is_breaking": False
    },
    {
        "id": "nis2_" + hashlib.md5(b"golden_power_cavi_sottomarini_telecom").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://agendadigitale.eu/cavi-sottomarini-golden-power").hexdigest(),
        "title_it": "Infrastrutture critiche: Estesi i poteri speciali alle landing station sottomarine",
        "original_title": "Italy extends Golden Power protections to submarine communication cable landing stations",
        "summary_points": [
            "Le stazioni di atterraggio dei cavi internet sottomarini nel Mediterraneo entrano ufficialmente nel perimetro di sicurezza nazionale.",
            "Ogni modifica societaria o fornitura tecnologica da parte di entità non comunitarie dovrà essere preventivamente autorizzata.",
            "Previsto il pattugliamento fisico e il monitoraggio telemetry H24 dei nodi di interconnessione strategici da parte della Marina e ACN."
        ],
        "action_mitigation": "I carrier e gli operatori telco devono censire tutti gli apparati attivi DWDM e inviare la scheda di rilevazione al nucleo Golden Power.",
        "threat_level": "MEDIO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "Telco & Network Engineers",
        "tags": ["GoldenPower", "Telco", "CaviSottomarini", "InfrastruttureCritiche", "Dorsali"],
        "source_name": "Agenda Digitale",
        "source_url": "https://www.agendadigitale.eu/sicurezza/golden-power-cavi-sottomarini",
        "published_at": "Ieri, 10:15",
        "created_at": (now - timedelta(days=1, hours=7)).isoformat(),
        "is_breaking": False
    },
    {
        "id": "nis2_" + hashlib.md5(b"acn_ispezioni_audit_fornitori_nis2").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://acn.gov.it/audit-fornitori-nis2-terze-parti").hexdigest(),
        "title_it": "ACN: Avviata la campagna di audit sulla supply chain dei soggetti essenziali",
        "original_title": "ACN kicks off supply chain cybersecurity audits for essential entities",
        "summary_points": [
            "Focus ispettivo sulla sicurezza della catena di fornitura (terze parti, software house, manutentori e MSP).",
            "I soggetti essenziali sono responsabili della verifica di sicurezza dei propri fornitori secondo l'articolo 21 della NIS2.",
            "L'Agenzia potrà richiedere i report di assessment e i contratti di servizio (SLA) con i vendor tecnologici."
        ],
        "action_mitigation": "Inviare un questionario di vendor risk assessment a tutti i fornitori critici e pretendere clausole di notifica incidenti entro 12 ore.",
        "threat_level": "ALTO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "CISO & Procurement",
        "tags": ["NIS2", "SupplyChain", "ThirdPartyRisk", "Audit", "ACN", "VendorManagement"],
        "source_name": "ACN",
        "source_url": "https://www.acn.gov.it/portale-nis2/audit-supply-chain",
        "published_at": "2 giorni fa",
        "created_at": (now - timedelta(days=2)).isoformat(),
        "is_breaking": False
    },
    {
        "id": "nis2_" + hashlib.md5(b"dora_nis2_sovrapposizione_bancaria").hexdigest()[:16],
        "url_hash": hashlib.sha256(b"https://bancaditalia.it/dora-nis2-armonizzazione-finanza").hexdigest(),
        "title_it": "Banca d'Italia e ACN: Chiarimenti sulla convergenza tra DORA e NIS2 nel fintech",
        "original_title": "Bank of Italy and ACN issue clarification on DORA and NIS2 regulatory overlap",
        "summary_points": [
            "Chiarita la prevalenza della disciplina speciale DORA (Digital Operational Resilience Act) per gli istituti di credito e le piattaforme di pagamento.",
            "Rimane tuttavia l'obbligo di coordinamento con il CSIRT Italia per minacce ibride e incidenti sistemici nazionali.",
            "Richiesti test TLPT (Threat-Led Penetration Testing) periodici per le banche a rilevanza sistemica."
        ],
        "action_mitigation": "Allineare i framework di cyber resilienza interna al regolamento DORA pur mantenendo i canali di comunicazione aperti con ACN.",
        "threat_level": "MEDIO",
        "category": "NIS2_GOLDEN_POWER",
        "target_audience": "Risk Manager & CISO Finanza",
        "tags": ["DORA", "NIS2", "BancaDItalia", "Fintech", "TLPT", "ResilienzaOperativa"],
        "source_name": "Banca d'Italia",
        "source_url": "https://www.bancaditalia.it/compiti/vigilanza/resilienza-operativa-dora",
        "published_at": "3 giorni fa",
        "created_at": (now - timedelta(days=3)).isoformat(),
        "is_breaking": False
    }
]

if __name__ == "__main__":
    print(f"🚀 Inserimento e generazione audio per {len(fresh_nis2_articles)} notizie NIS2 & Golden Power...")

    for art in fresh_nis2_articles:
        print(f"\n🎙️ Generazione audio per: {art['title_it'][:45]}...")
        try:
            audio_url = generate_article_audio(art, client)
            print(f"   Audio generato e caricato: {audio_url}")
        except Exception as e:
            print(f"   ⚠️ Avviso audio: {e}")

        # Database payload (NO audio_url column)
        db_record = {
            "id": art["id"],
            "url_hash": art["url_hash"],
            "title_it": art["title_it"],
            "original_title": art["original_title"],
            "summary_points": art["summary_points"],
            "action_mitigation": art["action_mitigation"],
            "threat_level": art["threat_level"],
            "category": art["category"],
            "target_audience": art["target_audience"],
            "tags": art["tags"],
            "source_name": art["source_name"],
            "source_url": art["source_url"],
            "published_at": art["published_at"],
            "created_at": art["created_at"],
            "is_breaking": art["is_breaking"]
        }

        try:
            res = client.table("news_articles").upsert(db_record).execute()
            print(f"   ✅ Articolo salvato in Supabase!")
        except Exception as e:
            print(f"   ❌ Errore salvataggio in Supabase: {e}")

    print("\n🎉 Operazione completata!")
