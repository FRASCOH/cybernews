"""
Script di backfill per generare e caricare gli audio neurali
di tutti gli articoli presenti nel database locale su Supabase Storage.
"""

import os
import sqlite3
import json
from dotenv import load_dotenv
from supabase import create_client
from audio_generator import generate_article_audio
from ingest import export_json_feed

load_dotenv("backend/.env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase_client = None
if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY:
    try:
        supabase_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        print("Connected to Supabase")
    except Exception as e:
        print(f"Supabase connection error: {e}")

DB_PATH = os.path.join(os.path.dirname(__file__), "articles_cache.db")

def backfill():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT id, url_hash, title_it, original_title, summary_points, action_mitigation,
               threat_level, category, target_audience, tags, source_name, source_url,
               published_at, created_at, audio_url
        FROM articles
    """)
    rows = cursor.fetchall()
    
    total = len(rows)
    print(f"Inizio generazione audio per {total} articoli...")

    success_count = 0
    for idx, r in enumerate(rows):
        art_id = r[0]
        existing_audio = r[14]
        
        if existing_audio:
            print(f"[{idx+1}/{total}] Audio già presente per {art_id[:8]}")
            continue

        art = {
            "id": art_id,
            "title_it": r[2],
            "original_title": r[3],
            "summary_points": json.loads(r[4]) if r[4] else [],
            "action_mitigation": r[5],
            "threat_level": r[6],
            "source_name": r[10]
        }

        print(f"[{idx+1}/{total}] 🎙️ Genero audio per: {art['title_it'][:40]}...")
        audio_url = generate_article_audio(art, supabase_client)
        if audio_url:
            cursor.execute("UPDATE articles SET audio_url = ? WHERE id = ?", (audio_url, art_id))
            conn.commit()
            print(f"     ✅ Audio caricato: {audio_url}")
            success_count += 1
        else:
            print(f"     ❌ Errore generazione per {art_id[:8]}")

    conn.close()
    print(f"\n🎉 Backfill completato! Generati con successo: {success_count}/{total} file audio.")
    
    # Aggiorna feed JSON locale
    export_json_feed()

if __name__ == "__main__":
    backfill()
