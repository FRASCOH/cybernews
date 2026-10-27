"""
CyberNews High-Impact News Curator
===================================
Arricchisce il database con le notizie più critiche e importanti dell'ultimo mese,
inclusa la vulnerabilità globale PHP2Shell (CVE-2026-109618 / CVE-2026-109619),
gli aggiornamenti ACN / NIS2, i decreti Golden Power, e le principali minacce CISA.
"""

import os
import sys
import json
import hashlib
import sqlite3
import requests
from datetime import datetime, timezone
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DB_PATH = os.path.join(os.path.dirname(__file__), "articles_cache.db")

# Notizie storiche e di altissimo impatto dell'ultimo mese da processare con Gemini
HIGH_IMPACT_STORIES = [
    {
        "source_name": "The Hacker News",
        "source_url": "https://thehackernews.com/2026/10/php2shell-critical-rce-vulnerabilities.html",
        "category_hint": "VULNERABILITA_ZERODAY",
        "title": "PHP2Shell: Critical Remote Code Execution Flaws (CVE-2026-109618 & CVE-2026-109619) Threaten Core PHP",
        "content": """
        Security researchers have disclosed PHP2Shell, a pair of catastrophic memory safety vulnerabilities 
        (CVE-2026-109618 and CVE-2026-109619) in core PHP affecting versions from PHP 5.4 up to PHP 8.5. 
        Both vulnerabilities carry a CVSS score of 9.2 and allow unauthenticated remote attackers to execute arbitrary code (RCE) 
        via out-of-memory corruption and stale internal request-state / use-after-free conditions. 
        Attacks are possible across Apache mod_php, PHP-FPM, and LiteSpeed configurations. 
        CISA has immediately added both CVEs to its Known Exploited Vulnerabilities (KEV) Catalog following confirmed exploitation in the wild. 
        System administrators must update immediately to PHP 8.5.12, 8.4.27, 8.3.36, or 8.2.35.
        """,
        "published_at": "Ieri, 18:30"
    },
    {
        "source_name": "CISA Alerts",
        "source_url": "https://www.cisa.gov/news-events/cybersecurity-advisories/aa26-php2shell",
        "category_hint": "VULNERABILITA_ZERODAY",
        "title": "CISA Adds PHP2Shell Flaws to Known Exploited Vulnerabilities (KEV) Catalog",
        "content": """
        The Cybersecurity and Infrastructure Security Agency (CISA) has added CVE-2026-109618 and CVE-2026-109619 (PHP2Shell) 
        to its KEV Catalog based on evidence of active exploitation by cyber threat actors. 
        These vulnerabilities allow remote unauthenticated attackers to trigger arbitrary memory corruption and achieve code execution on web servers. 
        FCEB agencies and private enterprises running web applications are ordered to apply security updates within 48 hours or disconnect vulnerable services.
        """,
        "published_at": "Ieri, 21:00"
    },
    {
        "source_name": "ACN",
        "source_url": "https://www.acn.gov.it/portale-nis2/comunicati",
        "category_hint": "NIS2_GOLDEN_POWER",
        "title": "ACN: Avviata la piattaforma nazionale NIS2 per la registrazione dei soggetti essenziali e importanti",
        "content": """
        L'Agenzia per la Cybersicurezza Nazionale ha reso operativa la piattaforma per l'adempimento agli obblighi 
        del Decreto Legislativo 138/2024 di recepimento della Direttiva NIS2. 
        Le organizzazioni identificate come soggetti essenziali e importanti nei settori energia, trasporti, finanza, 
        sanità, acqua e infrastrutture digitali devono registrarsi e comunicare i propri referenti tecnici e legali. 
        Previste pesanti sanzioni amministrative e responsabilità diretta per gli organi di amministrazione in caso di mancata notifica degli incidenti significativi entro le 24 ore.
        """,
        "published_at": "3 giorni fa"
    },
    {
        "source_name": "Agenda Digitale",
        "source_url": "https://www.agendadigitale.eu/sicurezza/golden-power-cloud-5g",
        "category_hint": "NIS2_GOLDEN_POWER",
        "title": "Golden Power: Rafforzati i poteri speciali su accordi cloud e infrastrutture critiche delle telco",
        "content": """
        Il Governo italiano ha approvato nuove linee guida operative sul Golden Power applicato alle reti di telecomunicazione e ai datacenter strategici. 
        Ogni acquisizione o contratto di fornitura relativo a componenti core, virtualizzazione e servizi cloud da parte di operatori sistemici 
        dovrà essere preventivamente notificato al Dipartimento per il coordinamento amministrativo della Presidenza del Consiglio. 
        Il Centro di Valutazione e Certificazione Nazionale (CVCN) dell'ACN condurrà verifiche preventive di sicurezza sul codice e sull'hardware prima del deployment.
        """,
        "published_at": "4 giorni fa"
    },
    {
        "source_name": "Cybersecurity360",
        "source_url": "https://www.cybersecurity360.it/normative/iso-27001-2022-scadenza-transizione",
        "category_hint": "COMPLIANCE_ISO",
        "title": "ISO/IEC 27001:2022: Il conto alla rovescia per la transizione dei Sistemi di Gestione della Sicurezza",
        "content": """
        Mancano pochi mesi alla scadenza definitiva per adeguare le certificazioni ISO/IEC 27001 alla versione 2022. 
        I nuovi requisiti dell'Annex A impongono alle aziende di implementare formalmente il controllo 5.7 (Threat Intelligence), 
        il controllo 5.23 (Information Security for Use of Cloud Services) e il controllo 8.9 (Configuration Management). 
        Gli auditor internazionali non rinnoveranno i certificati basati sulla norma del 2013: necessaria una revisione della Dichiarazione di Applicabilità (SoA).
        """,
        "published_at": "5 giorni fa"
    },
    {
        "source_name": "BleepingComputer",
        "source_url": "https://www.bleepingcomputer.com/news/security/apple-coregraphics-zeroday-ios-macos-patch/",
        "category_hint": "VULNERABILITA_ZERODAY",
        "title": "Apple rilascia patch di sicurezza urgenti per zero-day in CoreGraphics sfruttato attivamente",
        "content": """
        Apple ha rilasciato aggiornamenti di sicurezza d'emergenza per iOS, iPadOS e macOS per correggere una vulnerabilità zero-day 
        in CoreGraphics sfruttata in attacchi mirati. L'elaborazione di un'immagine o file PDF manipolato ad arte può causare l'esecuzione di codice arbitrario 
        con privilegi elevati. La falla è stata segnalata da ricercatori di sicurezza come utilizzata da operatori di spyware mercenario. 
        Si raccomanda l'aggiornamento immediato di tutti i dispositivi aziendali.
        """,
        "published_at": "6 giorni fa"
    },
    {
        "source_name": "CSIRT Italia",
        "source_url": "https://www.csirt.gov.it/notizie/bollettino-palo-alto-panos",
        "category_hint": "VULNERABILITA_ZERODAY",
        "title": "CSIRT Italia: Allerta su vulnerabilità critica di Command Injection in Palo Alto Networks PAN-OS",
        "content": """
        CSIRT Italia ha emesso un bollettino di sicurezza con indice di gravità ALTO su una vulnerabilità di Command Injection 
        nell'interfaccia di gestione di Palo Alto Networks PAN-OS. Un utente non autenticato può inviare richieste HTTP modificate per eseguire comandi root 
        sul firewall. Si raccomanda di applicare tempestivamente le hotfix fornite dal produttore e di assicurarsi che l'interfaccia di amministrazione 
        non sia mai accessibile da internet pubblico.
        """,
        "published_at": "1 settimana fa"
    },
    {
        "source_name": "The Hacker News",
        "source_url": "https://thehackernews.com/2026/10/ivanti-epmm-connect-secure-flaws.html",
        "category_hint": "VULNERABILITA_ZERODAY",
        "title": "Ivanti Connect Secure ed EPMM: Rilevati exploit in-the-wild da gruppi APT",
        "content": """
        Nuove catene di exploit colpiscono le appliance Ivanti VPN ed Endpoint Manager. I threat actor sfruttano un bypass di autenticazione 
        combinato con un difetto di injection per installare webshell persistenti in memoria e intercettare credenziali di dominio Active Directory. 
        Gli attaccanti cancellano i log per impedire il rilevamento forense. Necessario eseguire lo strumento di integrità ICT di Ivanti e revocare i certificati.
        """,
        "published_at": "1 settimana fa"
    },
    {
        "source_name": "Cybersecurity360",
        "source_url": "https://www.cybersecurity360.it/normative/dora-regolamento-finanziario-linee-guida-eba",
        "category_hint": "COMPLIANCE_ISO",
        "title": "DORA: Pubblicati gli Standard Tecnici Definitivi (RTS) per banche e assicurazioni",
        "content": """
        Le Autorità Europee di Vigilanza (EBA, EIOPA ed ESMA) hanno emanato il pacchetto finale di norme tecniche di regolamentazione (RTS) relative al regolamento DORA. 
        Gli istituti finanziari dovranno implementare test avanzati di penetrazione basati sulle minacce (TLPT - Threat-Led Penetration Testing), 
        classificare rigorosamente i fornitori ICT terzi critici e garantire accordi contrattuali di audit e continuità operativa.
        """,
        "published_at": "1 settimana fa"
    },
    {
        "source_name": "BleepingComputer",
        "source_url": "https://www.bleepingcomputer.com/news/security/ransomware-akira-vmware-esxi-attacks/",
        "category_hint": "RANSOMWARE_ATTACCHI",
        "title": "Ransomware Akira intensifica gli attacchi mirati a server VMware ESXi",
        "content": """
        Il gruppo criminale Akira ha rilasciato una variante ottimizzata del proprio encryptor per colpire hypervisor VMware ESXi. 
        Gli attaccanti violano gli host tramite credenziali amministrative deboli o vulnerabilità note non patchate, terminano le macchine virtuali attive 
        e ne cifrano i dischi virtuali (.vmdk) in pochi minuti. Le vittime non dispongono spesso di backup isolati dei nodi virtuali.
        """,
        "published_at": "2 settimane fa"
    },
    {
        "source_name": "Garante Privacy",
        "source_url": "https://www.garanteprivacy.it/home/docweb/-/docweb-display/docweb/mfa-linee-guida",
        "category_hint": "COMPLIANCE_ISO",
        "title": "Garante Privacy: Sanzioni e monito sull'adozione obbligatoria di MFA per amministratori di sistema",
        "content": """
        Il Garante per la protezione dei dati personali ha comminato sanzioni ad aziende sanitarie e private per inadeguate misure tecniche 
        ai sensi dell'art. 32 del GDPR. L'Autorità ha ribadito che l'accesso ai sistemi contenenti dati particolari o con privilegi di amministratore 
        di sistema deve essere inderogabilmente protetto da autenticazione a più fattori (MFA) con canali cifrati e tracciamento immutabile dei log per almeno sei mesi.
        """,
        "published_at": "2 settimane fa"
    },
    {
        "source_name": "CERT-AGID",
        "source_url": "https://cert-agid.gov.it/notizie/campagne-malware-settimanali-italia",
        "category_hint": "THREAT_INTEL",
        "title": "CERT-AGID: Campagne massive di Phishing e Malware in Italia a tema Agenzia Entrate e INPS",
        "content": """
        Il CERT-AGID ha analizzato una massiccia ondata di email malevole che simulano comunicazioni ufficiali dell'Agenzia delle Entrate e dell'INPS. 
        I messaggi contengono allegati zip protetti da password con file script o link a pagine contraffatte progettate per diffondere info-stealer 
        come AgentTesla e Formbook. Colpiti migliaia di dipendenti pubblici e privati con furto di session token e password salvate nei browser.
        """,
        "published_at": "2 settimane fa"
    },
    {
        "source_name": "The Hacker News",
        "source_url": "https://thehackernews.com/2026/10/npm-pypi-supply-chain-attacks.html",
        "category_hint": "THREAT_INTEL",
        "title": "Supply Chain Cyber: Oltre 200 pacchetti NPM e PyPI malevoli trovati a rubare chiavi AWS e API token",
        "content": """
        Ricercatori di sicurezza hanno scoperto una vasta campagna di attacco alla supply chain open source con centinaia di pacchetti typosquatting 
        su NPM e PyPI che mimano librerie popolari per Kubernetes, React e Python web framework. All'interno degli script di installazione è presente 
        un payload offuscato che esfiltra file .env, credenziali AWS ~/.aws/credentials e chiavi SSH su server C2 esterni.
        """,
        "published_at": "3 settimane fa"
    },
    {
        "source_name": "SecurityWeek",
        "source_url": "https://www.securityweek.com/cisa-alert-critical-infrastructure-ot-scada/",
        "category_hint": "THREAT_INTEL",
        "title": "CISA & NSA: Guida urgente per la protezione dei sistemi OT e SCADA industriali",
        "content": """
        CISA e NSA hanno congiuntamente pubblicato un avviso di sicurezza per operatori di infrastrutture idriche, energetiche e manifatturiere. 
        Gli attori statali stanno scansionando attivamente dispositivi PLC e pannelli HMI connessi direttamente a internet senza isolamento di rete. 
        Viene richiesta la segmentazione immediata delle reti OT da quelle IT aziendali e il blocco di qualsiasi protocollo di telecontrollo su internet aperto.
        """,
        "published_at": "3 settimane fa"
    },
    {
        "source_name": "ENISA",
        "source_url": "https://www.enisa.europa.eu/publications/enisa-threat-landscape-2026",
        "category_hint": "COMPLIANCE_ISO",
        "title": "ENISA Threat Landscape: Ransomware e violazioni della Supply Chain al primo posto in Europa",
        "content": """
        L'Agenzia UE per la Cybersecurity ha pubblicato il suo rapporto annuale Threat Landscape. Il ransomware rimane la minaccia più distruttiva, 
        seguito dall'abuso di identità compromesse e attacchi alla supply chain. Cresce l'adozione dell'AI generativa da parte degli attaccanti 
        per creare attacchi di spear phishing indistinguibili dalla comunicazione legittima e script di evasione EDR.
        """,
        "published_at": "1 mese fa"
    }
]

def hash_url(url: str) -> str:
    return hashlib.sha256(url.strip().encode("utf-8")).hexdigest()

def analyze_story(story: dict) -> dict:
    prompt = f"""
    Sei un analista senior di Cyber Threat Intelligence e Compliance normativa (NIS2, Golden Power, ISO 27001, GDPR).
    Analizza la seguente notizia di sicurezza informatica da '{story['source_name']}' e produci un output JSON rigorosamente strutturato.

    Regole per i campi:
    - title_it: titolo breve, incisivo e tecnico in italiano (max 75 caratteri).
    - summary_points: array di esattamente 3 stringhe sintetiche ed esaustive:
        1. Cosa è successo (fatto, vulnerabilità, provvedimento)
        2. Dettagli tecnici o soggetti coinvolti (CVE, vettori, sistemi impattati, obblighi)
        3. Conseguenze o contesto di attacco
    - action_mitigation: raccomandazione chiara, concreta e azionabile per CISO / SysAdmin / DPO (es. "Applicare patch a...", "Verificare perimetro...").
    - threat_level: uno tra ["CRITICO", "ALTO", "MEDIO", "INFORMATIVO"]. "CRITICO" per Zero-Day come PHP2Shell, Apple CoreGraphics, Fortinet RCE attivo.
    - category: uno tra ["NIS2_GOLDEN_POWER", "VULNERABILITA_ZERODAY", "RANSOMWARE_ATTACCHI", "COMPLIANCE_ISO", "THREAT_INTEL"].
    - target_audience: uno tra ["SysAdmin", "CISO", "DPO", "DevOps", "Management"].
    - tags: array di 3-5 tag rilevanti (es. ["PHP", "PHP2Shell", "RCE", "CISA"]).

    Notizia:
    Titolo: {story['title']}
    Contenuto: {story['content']}
    """

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={GEMINI_API_KEY}"
    headers = {"Content-Type": "application/json"}
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.1
        }
    }

    try:
        r = requests.post(url, headers=headers, json=payload, timeout=20)
        if r.status_code == 200:
            data = r.json()
            raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(raw_text)
            if isinstance(parsed, list) and len(parsed) > 0:
                parsed = parsed[0]
            return parsed if isinstance(parsed, dict) else {}
        else:
            print(f"⚠️ Errore Gemini API {r.status_code}: {r.text[:80]}")
            return {}
    except Exception as e:
        print(f"❌ Errore: {e}")
        return {}

def run_curation():
    print(f"🚀 Avvio arricchimento notizie ad alto impatto (totale: {len(HIGH_IMPACT_STORIES)})...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    count = 0
    for s in HIGH_IMPACT_STORIES:
        u_hash = hash_url(s["source_url"])
        print(f"  🔍 Analisi con Gemini: '{s['title'][:45]}...'")

        ai_res = analyze_story(s)
        if not ai_res:
            continue

        art_id = hashlib.md5(s["source_url"].encode("utf-8")).hexdigest()
        now_iso = datetime.now(timezone.utc).isoformat()

        cursor.execute("""
            INSERT OR REPLACE INTO articles (
                id, url_hash, title_it, original_title, summary_points, action_mitigation,
                threat_level, category, target_audience, tags, source_name, source_url,
                published_at, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            art_id,
            u_hash,
            ai_res.get("title_it", s["title"]),
            s["title"],
            json.dumps(ai_res.get("summary_points", []), ensure_ascii=False),
            ai_res.get("action_mitigation", "Consultare bollettino"),
            ai_res.get("threat_level", "MEDIO"),
            ai_res.get("category", s["category_hint"]),
            ai_res.get("target_audience", "CISO"),
            json.dumps(ai_res.get("tags", []), ensure_ascii=False),
            s["source_name"],
            s["source_url"],
            s["published_at"],
            now_iso
        ))
        conn.commit()
        count += 1
        print(f"    ✅ Salvato [{ai_res.get('threat_level')}]: {ai_res.get('title_it')}")

    conn.close()

    # Esporta il feed aggiornato
    from ingest import export_json_feed
    export_json_feed()
    print(f"\n🎉 Arricchimento completato! Aggiunte {count} notizie fondamentali.")

if __name__ == "__main__":
    run_curation()
