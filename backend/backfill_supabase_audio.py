"""
Genera l'audio neurale per TUTTI gli articoli presenti su Supabase Cloud.
"""

import os
import asyncio
from dotenv import load_dotenv
from supabase import create_client
from audio_generator import generate_article_audio

load_dotenv("backend/.env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def main():
    print("Recupero tutti gli articoli da Supabase...")
    res = supabase.table("news_articles").select("*").order("created_at", desc=True).execute()
    articles = res.data or []
    print(f"Trovati {len(articles)} articoli in Supabase.")

    # Elenco file già caricati nello storage
    existing_files = {f["name"] for f in supabase.storage.from_("news-audio").list()}
    print(f"File già presenti nello storage: {len(existing_files)}")

    to_process = [a for a in articles if f"{a['id']}.mp3" not in existing_files]
    print(f"Articoli da generare: {len(to_process)}")

    for idx, art in enumerate(to_process):
        art_id = art["id"]
        title = art.get("title_it") or art.get("original_title") or "Senza titolo"
        print(f"[{idx+1}/{len(to_process)}] 🎙️ Genero audio per: {title[:40]}...")
        url = generate_article_audio(art, supabase)
        if url:
            print(f"     ✅ Caricato: {url}")
        else:
            print(f"     ❌ Fallito per {art_id[:8]}")

    print("\n🎉 Generazione completata per tutti gli articoli di Supabase!")

if __name__ == "__main__":
    main()
