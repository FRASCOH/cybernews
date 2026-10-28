"""
CyberNews Neural AI Audio Generator
====================================
Genera audio vocali neurali realistici da studio radiofonico a costo zero
usando Microsoft Edge TTS (senza limiti e senza API key).
Carica automaticamente gli MP3 nel bucket Supabase Storage 'news-audio'.
"""

import os
import asyncio
import tempfile
from typing import Dict, Any, Optional
import edge_tts
from dotenv import load_dotenv

load_dotenv()

VOICE = os.getenv("TTS_VOICE", "it-IT-DiegoNeural") # Voce maschile giornalistica (oppure 'it-IT-ElsaNeural')
VOICE_RATE = os.getenv("TTS_RATE", "+4%")

def build_spoken_script(article: Dict[str, Any]) -> str:
    """Costruisce un testo parlato fluente, autorevole e naturale per lo speaker."""
    source = article.get("source_name", "CyberNews")
    threat = article.get("threat_level", "MEDIO")
    title = article.get("title_it") or article.get("original_title") or ""
    summary_points = article.get("summary_points", [])
    action = article.get("action_mitigation", "")

    script = f"CyberNews Briefing. Fonte: {source}. Livello di rischio: {threat.lower()}. {title}. "

    if summary_points:
        script += "I punti chiave dell'evento. "
        for idx, pt in enumerate(summary_points[:3]):
            script += f"Punto {idx + 1}: {pt}. "

    if action:
        script += f"Azione di mitigazione consigliata: {action}."

    return script.strip()

async def render_mp3_async(text: str, output_path: str):
    """Genera il file MP3 via edge-tts in modo asincrono."""
    communicate = edge_tts.Communicate(text, voice=VOICE, rate=VOICE_RATE)
    await communicate.save(output_path)

def generate_article_audio(article: Dict[str, Any], supabase_client = None) -> Optional[str]:
    """
    Genera l'audio MP3 per l'articolo e lo carica su Supabase Storage.
    Ritorna la URL pubblica dell'audio streamable.
    """
    article_id = article.get("id")
    if not article_id:
        return None

    script = build_spoken_script(article)
    if not script:
        return None

    filename = f"{article_id}.mp3"

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        # Genera l'MP3 con Edge Neural TTS
        asyncio.run(render_mp3_async(script, tmp_path))

        # Se Supabase è configurato, carica nel bucket pubblico 'news-audio'
        if supabase_client:
            try:
                with open(tmp_path, "rb") as f:
                    file_bytes = f.read()
                    supabase_client.storage.from_("news-audio").upload(
                        path=filename,
                        file=file_bytes,
                        file_options={"content-type": "audio/mpeg", "upsert": "true"}
                    )
                public_url = supabase_client.storage.from_("news-audio").get_public_url(filename)
                return public_url
            except Exception as up_err:
                print(f"⚠️ Errore upload audio su Supabase Storage: {up_err}")
                return None
        return None
    except Exception as e:
        print(f"⚠️ Errore generazione Edge TTS per articolo {article_id[:8]}: {e}")
        return None
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass
