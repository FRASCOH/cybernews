"""
Scansiona tutti gli articoli nel database Supabase e SQLite.
Se individua articoli con titolo o sommario in lingua inglese:
1. Li traduce in italiano tramite Gemini.
2. Aggiorna Supabase Cloud e il database locale SQLite.
3. Rigenera il file audio MP3 in italiano e lo carica su Supabase Storage.
4. Aggiorna latest_news.json sia per il backend sia per l'app iOS.
"""

import os
import sqlite3
import json
from dotenv import load_dotenv
from supabase import create_client
from audio_generator import is_likely_english, translate_to_italian_with_gemini, generate_article_audio, strip_html
from ingest import export_json_feed

load_dotenv("backend/.env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
DB_PATH = os.path.join(os.path.dirname(__file__), "articles_cache.db")

def main():
    print("Recupero tutti gli articoli da Supabase...")
    res = supabase.table("news_articles").select("*").execute()
    articles = res.data or []
    print(f"Totale articoli in Supabase: {len(articles)}")

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    translated_count = 0

    for idx, a in enumerate(articles):
        art_id = a["id"]
        title = a.get("title_it") or a.get("original_title") or ""
        points = a.get("summary_points") or []
        action = a.get("action_mitigation") or ""

        # Controllo se è presente testo in inglese
        is_eng = is_likely_english(title) or any(is_likely_english(p) for p in points)

        if not is_eng:
            continue

        print(f"\n[{translated_count+1}] 🌐 Rilevato testo in inglese per: '{title[:50]}...'")
        new_title, new_points, new_action = translate_to_italian_with_gemini(
            title,
            [strip_html(p) for p in points],
            strip_html(action)
        )
        print(f"     🇮🇹 Titolo tradotto: '{new_title[:50]}...'")

        # 1. Aggiorna Supabase
        try:
            supabase.table("news_articles").update({
                "title_it": new_title,
                "summary_points": new_points,
                "action_mitigation": new_action
            }).eq("id", art_id).execute()
            print("     ✅ Aggiornato record su Supabase Cloud")
        except Exception as e:
            print(f"     ⚠️ Errore update Supabase: {e}")

        # 2. Aggiorna SQLite locale
        try:
            cursor.execute("""
                UPDATE articles
                SET title_it = ?, summary_points = ?, action_mitigation = ?
                WHERE id = ?
            """, (new_title, json.dumps(new_points, ensure_ascii=False), new_action, art_id))
            conn.commit()
        except Exception as e:
            print(f"     ⚠️ Errore update SQLite: {e}")

        # 3. Rigenera Audio MP3 in italiano con Edge TTS
        updated_article = dict(a)
        updated_article["title_it"] = new_title
        updated_article["summary_points"] = new_points
        updated_article["action_mitigation"] = new_action

        audio_url = generate_article_audio(updated_article, supabase)
        if audio_url:
            print(f"     🎙️ Nuovo audio neurale in italiano caricato: {audio_url}")

        translated_count += 1

    conn.close()
    print(f"\n🎉 Traduzione e rigenerazione completata! Articoli convertiti in italiano: {translated_count}")

    # Esporta i feed JSON aggiornati
    export_json_feed()
    
    # Sincronizza anche con la cartella Resources di iOS
    json_path = os.path.join(os.path.dirname(__file__), "latest_news.json")
    ios_json_path = os.path.join(os.path.dirname(__file__), "..", "ios", "CyberNews", "Resources", "latest_news.json")
    if os.path.exists(json_path):
        import shutil
        shutil.copy2(json_path, ios_json_path)
        print("📱 Sincronizzato con Resources/latest_news.json per iOS")

if __name__ == "__main__":
    main()
