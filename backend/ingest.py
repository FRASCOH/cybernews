"""
CyberNews Ingestion Engine
===========================
Raccoglie le notizie dalle 19 fonti ufficiali e autorevoli, le deduplica,
le invia a Gemini 2.0 Flash per la sintesi strutturata in italiano,
e le memorizza localmente (cache SQLite) e/o su Supabase (PostgreSQL).
"""

import os
import sys
import json
import hashlib
import sqlite3
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv
import feedparser
import requests

# Carica le variabili da backend/.env
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

# Inizializza client Supabase se configurato
supabase_client = None
if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY:
    try:
        from supabase import create_client
        supabase_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        print(" Connected to Supabase Cloud Database")
    except Exception as e:
        print(f"⚠️ Supabase warning: {e}")

# Inizializza client Gemini 2.0 Flash
gemini_client = None
if GEMINI_API_KEY and GEMINI_API_KEY.strip():
    try:
        from google import genai
        gemini_client = genai.Client(api_key=GEMINI_API_KEY)
        print(" Connected to Google Gemini 2.0 Flash")
    except Exception as e:
        print(f"⚠️ Gemini client error: {e}")

# Catalogo delle Fonti Monitorate
SOURCES = [
    # 1. NAZIONALI & DIFESA
    {
        "name": "ACN",
        "url": "https://www.acn.gov.it/notizie/rss",
        "category_hint": "NIS2_GOLDEN_POWER",
        "fallback_feed": "https://www.acn.gov.it/comunicati/rss"
    },
    {
        "name": "CSIRT Italia",
        "url": "https://www.csirt.gov.it/notizie/rss",
        "category_hint": "THREAT_INTEL"
    },
    {
        "name": "CERT-AGID",
        "url": "https://cert-agid.gov.it/feed/",
        "category_hint": "THREAT_INTEL"
    },
    # 2. COMPLIANCE & NORMATIVE UE / ITALIA
    {
        "name": "Cybersecurity360",
        "url": "https://www.cybersecurity360.it/feed/",
        "category_hint": "COMPLIANCE_ISO"
    },
    {
        "name": "Agenda Digitale",
        "url": "https://www.agendadigitale.eu/feed/",
        "category_hint": "COMPLIANCE_ISO"
    },
    {
        "name": "Garante Privacy",
        "url": "https://www.garanteprivacy.it/home/rss",
        "category_hint": "COMPLIANCE_ISO"
    },
    {
        "name": "EDPB",
        "url": "https://edpb.europa.eu/news/news/rss.xml",
        "category_hint": "COMPLIANCE_ISO"
    },
    # 3. STANDARD INTERNAZIONALI
    {
        "name": "NIST Cyber",
        "url": "https://www.nist.gov/news-events/cybersecurity/rss.xml",
        "category_hint": "COMPLIANCE_ISO"
    },
    {
        "name": "ENISA",
        "url": "https://www.enisa.europa.eu/news/rss.xml",
        "category_hint": "COMPLIANCE_ISO"
    },
    # 4. THREAT INTEL & VULNERABILITÀ
    {
        "name": "CISA Alerts",
        "url": "https://www.cisa.gov/news-events/cybersecurity-advisories/rss.xml",
        "category_hint": "VULNERABILITA_ZERODAY"
    },
    {
        "name": "BleepingComputer",
        "url": "https://www.bleepingcomputer.com/feed/",
        "category_hint": "RANSOMWARE_ATTACCHI"
    },
    {
        "name": "The Hacker News",
        "url": "https://feeds.feedburner.com/TheHackersNews",
        "category_hint": "THREAT_INTEL"
    },
    {
        "name": "SANS ISC",
        "url": "https://isc.sans.edu/rssfeed.xml",
        "category_hint": "THREAT_INTEL"
    },
    {
        "name": "SecurityWeek",
        "url": "https://feeds.feedburner.com/Securityweek",
        "category_hint": "THREAT_INTEL"
    }
]

# Database locale SQLite di backup / deduplicazione
DB_PATH = os.path.join(os.path.dirname(__file__), "articles_cache.db")

def init_local_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS articles (
            id TEXT PRIMARY KEY,
            url_hash TEXT UNIQUE,
            title_it TEXT,
            original_title TEXT,
            summary_points TEXT,
            action_mitigation TEXT,
            threat_level TEXT,
            category TEXT,
            target_audience TEXT,
            tags TEXT,
            source_name TEXT,
            source_url TEXT,
            published_at TEXT,
            created_at TEXT
        )
    """)
    conn.commit()
    conn.close()

def hash_url(url: str) -> str:
    return hashlib.sha256(url.strip().encode("utf-8")).hexdigest()

def is_already_processed(url_hash: str) -> bool:
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT 1 FROM articles WHERE url_hash = ?", (url_hash,))
    row = cursor.fetchone()
    conn.close()
    return row is not None

def analyze_with_gemini(title: str, content: str, source_name: str, category_hint: str) -> Optional[Dict[str, Any]]:
    if not gemini_client:
        return None
    
    from google.genai import types

    prompt = f"""
    Sei un analista senior di Cyber Threat Intelligence e Compliance normativa (NIS2, Golden Power, ISO 27001, GDPR).
    Analizza il seguente articolo di cybersecurity da '{source_name}' e produci un output JSON rigorosamente strutturato.

    Regole per i campi:
    - title_it: titolo breve, professionale, autorevole in italiano (max 70 caratteri).
    - summary_points: array di esattamente 3 stringhe:
        1. Cosa è successo (fatto, violazione, attacco, provvedimento normativo)
        2. Dettagli tecnici o soggetti coinvolti (CVE, vettori, obbligati, sanzioni)
        3. Impatto o contesto operativo
    - action_mitigation: raccomandazione chiara, concreta e azionabile per CISO / SysAdmin / DPO (es. "Applicare patch KB..., Verificare perimetro NIS2").
    - threat_level: uno tra ["CRITICO", "ALTO", "MEDIO", "INFORMATIVO"]. Usa "CRITICO" solo per Zero-Day attivi, alert ACN/CISA ad altissima gravità o blocchi Golden Power.
    - category: uno tra ["NIS2_GOLDEN_POWER", "VULNERABILITA_ZERODAY", "RANSOMWARE_ATTACCHI", "COMPLIANCE_ISO", "THREAT_INTEL"].
    - target_audience: uno tra ["CISO", "SysAdmin", "DPO", "DevOps", "Management"].
    - tags: array di 3-5 tag rilevanti (es. ["ACN", "NIS2", "Fortinet", "Ransomware"]).

    Articolo:
    Titolo originale: {title}
    Contenuto/Estratto: {content[:2500]}
    """

    try:
        response = gemini_client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.1,
            ),
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"❌ Errore Gemini su '{title[:30]}...': {e}")
        return None

def save_article(article_data: Dict[str, Any]):
    # Salva in SQLite locale
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT OR REPLACE INTO articles (
            id, url_hash, title_it, original_title, summary_points, action_mitigation,
            threat_level, category, target_audience, tags, source_name, source_url,
            published_at, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        article_data["id"],
        article_data["url_hash"],
        article_data["title_it"],
        article_data["original_title"],
        json.dumps(article_data["summary_points"], ensure_ascii=False),
        article_data["action_mitigation"],
        article_data["threat_level"],
        article_data["category"],
        article_data["target_audience"],
        json.dumps(article_data["tags"], ensure_ascii=False),
        article_data["source_name"],
        article_data["source_url"],
        article_data["published_at"],
        article_data["created_at"],
    ))
    conn.commit()
    conn.close()

    # Salva su Supabase se connesso
    if supabase_client:
        try:
            supabase_client.table("news_articles").upsert({
                "id": article_data["id"],
                "url_hash": article_data["url_hash"],
                "title_it": article_data["title_it"],
                "original_title": article_data["original_title"],
                "summary_points": article_data["summary_points"],
                "action_mitigation": article_data["action_mitigation"],
                "threat_level": article_data["threat_level"],
                "category": article_data["category"],
                "target_audience": article_data["target_audience"],
                "tags": article_data["tags"],
                "source_name": article_data["source_name"],
                "source_url": article_data["source_url"],
                "published_at": article_data["published_at"],
                "is_breaking": article_data["threat_level"] == "CRITICO",
            }).execute()
        except Exception as e:
            print(f"⚠️ Errore salvataggio Supabase: {e}")

def run_ingestion(limit_per_source: int = 3):
    print("🚀 Inizio ciclo di ingestion CyberNews...")
    init_local_db()

    total_new = 0

    for source in SOURCES:
        name = source["name"]
        url = source["url"]
        category_hint = source["category_hint"]

        print(f"\n📡 Controllo fonte: {name} ({url})...")
        try:
            headers = {"User-Agent": "CyberNews-Aggregator/1.0 (SecBot/1.0)"}
            resp = requests.get(url, headers=headers, timeout=12)
            feed = feedparser.parse(resp.content)
            
            if not feed.entries and "fallback_feed" in source:
                print(f"  ↪️ Uso fallback feed per {name}...")
                resp = requests.get(source["fallback_feed"], headers=headers, timeout=12)
                feed = feedparser.parse(resp.content)

            entries = feed.entries[:limit_per_source]
            print(f"  Trovati {len(feed.entries)} articoli (esamino i primi {len(entries)})")

            for entry in entries:
                article_url = entry.get("link", "")
                if not article_url:
                    continue

                u_hash = hash_url(article_url)
                if is_already_processed(u_hash):
                    continue

                original_title = entry.get("title", "")
                content = entry.get("summary", "") or entry.get("description", "") or original_title
                pub_date = entry.get("published", "") or datetime.now(timezone.utc).isoformat()

                print(f"  ✨ Nuovo articolo rilevato: '{original_title[:50]}...'")

                ai_result = analyze_with_gemini(original_title, content, name, category_hint)
                if not ai_result:
                    # Fallback semplice se Gemini non è ancora configurato
                    ai_result = {
                        "title_it": original_title,
                        "summary_points": [content[:120] or "Notizia non ancora analizzata"],
                        "action_mitigation": "Consultare il bollettino ufficiale per verificare l'impatto.",
                        "threat_level": "MEDIO",
                        "category": category_hint,
                        "target_audience": "CISO",
                        "tags": [name]
                    }

                article_id = hashlib.md5(article_url.encode("utf-8")).hexdigest()
                now_iso = datetime.now(timezone.utc).isoformat()

                article_record = {
                    "id": article_id,
                    "url_hash": u_hash,
                    "title_it": ai_result.get("title_it", original_title),
                    "original_title": original_title,
                    "summary_points": ai_result.get("summary_points", []),
                    "action_mitigation": ai_result.get("action_mitigation", "Monitorare bollettino"),
                    "threat_level": ai_result.get("threat_level", "MEDIO"),
                    "category": ai_result.get("category", category_hint),
                    "target_audience": ai_result.get("target_audience", "SysAdmin"),
                    "tags": ai_result.get("tags", [name]),
                    "source_name": name,
                    "source_url": article_url,
                    "published_at": pub_date,
                    "created_at": now_iso
                }

                save_article(article_record)
                total_new += 1
                print(f"    Salvato: [{article_record['threat_level']}] {article_record['title_it'][:45]}...")

        except Exception as e:
            print(f"❌ Errore durante il recupero da {name}: {e}")

    print(f"\n Ciclo completato! Nuovi articoli elaborati: {total_new}")

if __name__ == "__main__":
    run_ingestion()
