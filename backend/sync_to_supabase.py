import os
import sys
import json
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print("❌ ERRORE: SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY mancanti nel file .env")
    sys.exit(1)

print(f"📡 Connessione a Supabase ({SUPABASE_URL})...")

try:
    client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    # Carica le notizie salvate da latest_news.json
    json_path = os.path.join(os.path.dirname(__file__), "latest_news.json")
    if not os.path.exists(json_path):
        print("❌ File latest_news.json non trovato.")
        sys.exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        articles = json.load(f)

    print(f"📦 Caricamento di {len(articles)} notizie nel database cloud...")

    inserted_count = 0
    for art in articles:
        record = {
            "id": art["id"],
            "url_hash": art["url_hash"],
            "title_it": art["title_it"],
            "original_title": art.get("original_title"),
            "summary_points": art.get("summary_points", []),
            "action_mitigation": art.get("action_mitigation"),
            "threat_level": art["threat_level"],
            "category": art["category"],
            "target_audience": art.get("target_audience", "CISO"),
            "tags": art.get("tags", []),
            "source_name": art["source_name"],
            "source_url": art["source_url"],
            "published_at": art.get("published_at"),
            "is_breaking": art.get("is_breaking", False)
        }
        res = client.table("news_articles").upsert(record).execute()
        inserted_count += 1
        print(f"  ✅ Sincronizzato [{art['threat_level']}]: {art['title_it'][:45]}...")

    print(f"\n🎉 Sincronizzazione completata con successo! {inserted_count} notizie attive nel cloud!")

except Exception as e:
    print(f"❌ Errore durante la sincronizzazione su Supabase:\n{e}")
    print("\n👉 Suggerimento: Hai eseguito lo script SQL (Passo 1) nell'SQL Editor di Supabase per creare la tabella 'news_articles'?")
    sys.exit(1)
