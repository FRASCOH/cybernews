"""
CyberNews Neural AI Audio Generator
====================================
Genera audio vocali neurali realistici da studio radiofonico a costo zero
usando Microsoft Edge TTS (senza limiti e senza API key).
Se un testo o un titolo è in lingua inglese, viene automaticamente tradotto
in italiano impeccabile tramite Gemini prima della sintesi vocale.
Carica automaticamente gli MP3 nel bucket Supabase Storage 'news-audio'.
"""

import os
import re
import html
import json
import asyncio
import tempfile
import requests
from typing import Dict, Any, Optional, Tuple, List
import edge_tts
from dotenv import load_dotenv

load_dotenv("backend/.env")

VOICE = os.getenv("TTS_VOICE", "it-IT-DiegoNeural") # Voce maschile giornalistica (oppure 'it-IT-ElsaNeural')
VOICE_RATE = os.getenv("TTS_RATE", "+4%")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

def strip_html(text: str) -> str:
    """Rimuove tag HTML residui ed entità per una lettura vocale pulita."""
    if not text:
        return ""
    clean = re.sub(r"<[^>]+>", " ", text)
    clean = html.unescape(clean)
    clean = re.sub(r"\s+", " ", clean)
    return clean.strip()

def is_likely_english(text: str) -> bool:
    """Rileva se una stringa è in lingua inglese."""
    if not text:
        return False
    words = set(re.findall(r"\b[a-zA-Z]{2,}\b", text.lower()))
    common_english = {
        "the", "is", "in", "at", "which", "on", "and", "a", "to", "of", "for", "with", "as", "by",
        "has", "have", "from", "be", "this", "that", "are", "was", "were", "after", "confirms",
        "warns", "patches", "flaws", "vulnerabilities", "attack", "exploited", "users", "data",
        "security", "breach", "remote", "execution", "code", "puts", "members", "risk", "flaw",
        "critical", "advisory", "now", "threat", "leaked", "disclosed"
    }
    return len(words & common_english) >= 2

def translate_to_italian_with_gemini(title: str, summary_points: List[str], action: str) -> Tuple[str, List[str], str]:
    """
    Traduce titolo, punti di sintesi e mitigazione in italiano naturale
    e professionale per lo speaker radiofonico.
    """
    if not GEMINI_API_KEY:
        return title, summary_points, action

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={GEMINI_API_KEY}"
    prompt = f"""Sei un esperto giornalista e divulgatore radiofonico di cybersecurity.
Traduci integralmente e fedelmente questo titolo, sommario e mitigazione in italiano naturale, autorevole e chiaro per la lettura vocale.
Tutti i testi devono essere in italiano (mantieni intatti solo codici tecnici come CVE-xxxx-xxxx, vendor come Apple, Microsoft, CISA o acronimi tecnici universali come RCE, MFA, IoC).

Rispondi rigorosamente ed esclusivamente con un JSON valido nel formato:
{{
  "title_it": "Titolo tradotto in italiano",
  "summary_points": ["Punto 1 in italiano", "Punto 2 in italiano", "Punto 3 in italiano"],
  "action_mitigation": "Mitigazione tradotta in italiano"
}}

Titolo originale: {title}
Sommario originale: {' | '.join(summary_points)}
Mitigazione originale: {action}
"""

    try:
        resp = requests.post(
            url,
            json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"responseMimeType": "application/json", "temperature": 0.1}
            },
            timeout=12
        )
        if resp.status_code == 200:
            data = resp.json()
            raw_json = data["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(raw_json)
            new_title = parsed.get("title_it", title)
            new_points = parsed.get("summary_points", summary_points)
            new_action = parsed.get("action_mitigation", action)
            return new_title, new_points, new_action
    except Exception as e:
        print(f"⚠️ Errore traduzione Gemini: {e}")

    return title, summary_points, action

def build_spoken_script(article: Dict[str, Any], supabase_client = None) -> Tuple[str, bool]:
    """
    Costruisce un testo parlato fluente, autorevole e rigorosamente in italiano.
    Se rileva contenuti in inglese, li traduce prima di formulare lo script.
    Ritorna una tupla (script, was_translated).
    """
    source = article.get("source_name", "CyberNews")
    threat = article.get("threat_level", "MEDIO")
    raw_title = article.get("title_it") or article.get("original_title") or ""
    raw_points = [strip_html(p) for p in article.get("summary_points", []) if p]
    raw_action = strip_html(article.get("action_mitigation", ""))

    title = strip_html(raw_title)
    summary_points = raw_points
    action = raw_action
    was_translated = False

    # Controllo se il titolo o i punti contengono testo in inglese
    has_english = is_likely_english(title) or any(is_likely_english(p) for p in summary_points)

    if has_english:
        print(f"  🌐 Rilevato testo in inglese per: '{title[:40]}...'. Traduzione automatica in italiano...")
        title, summary_points, action = translate_to_italian_with_gemini(title, summary_points, action)
        was_translated = True
        
        # Aggiorna il dizionario dell'articolo con i testi in italiano
        article["title_it"] = title
        article["summary_points"] = summary_points
        article["action_mitigation"] = action

        # Sincronizza su Supabase se connesso
        if supabase_client and article.get("id"):
            try:
                supabase_client.table("news_articles").update({
                    "title_it": title,
                    "summary_points": summary_points,
                    "action_mitigation": action
                }).eq("id", article["id"]).execute()
                print(f"     ✅ Articolo {article['id'][:8]} tradotto e aggiornato su Supabase!")
            except Exception as up_err:
                print(f"     ⚠️ Errore update Supabase traduzione: {up_err}")

    # Costruzione dello script parlato
    script = f"CyberNews Briefing. Fonte: {source}. Livello di rischio: {threat.lower()}. {title}. "

    if summary_points:
        script += "I punti chiave dell'evento. "
        for idx, pt in enumerate(summary_points[:3]):
            clean_pt = strip_html(pt)
            if clean_pt:
                script += f"Punto {idx + 1}: {clean_pt}. "

    if action:
        clean_action = strip_html(action)
        if clean_action:
            script += f"Azione di mitigazione consigliata: {clean_action}."

    return script.strip(), was_translated

async def render_mp3_async(text: str, output_path: str):
    """Genera il file MP3 via edge-tts in modo asincrono."""
    communicate = edge_tts.Communicate(text, voice=VOICE, rate=VOICE_RATE)
    await communicate.save(output_path)

def generate_article_audio(article: Dict[str, Any], supabase_client = None) -> Optional[str]:
    """
    Genera l'audio MP3 per l'articolo e lo carica su Supabase Storage.
    Traduce automaticamente qualsiasi porzione in inglese in italiano perfetto.
    Ritorna la URL pubblica dell'audio streamable.
    """
    article_id = article.get("id")
    if not article_id:
        return None

    script, was_translated = build_spoken_script(article, supabase_client)
    if not script:
        return None

    filename = f"{article_id}.mp3"

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        # Genera l'MP3 con Edge Neural TTS
        asyncio.run(render_mp3_async(script, tmp_path))

        # Carica nel bucket pubblico 'news-audio'
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
