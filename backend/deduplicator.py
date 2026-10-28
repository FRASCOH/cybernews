"""
CyberNews Semantic Deduplicator
================================
Identifica e raggruppa notizie duplicate o correlate provenienti da fonti multiple
(es. la stessa vulnerabilità Zero-Day o direttiva NIS2 ripresa da CSIRT, BleepingComputer e The Hacker News).
Evita di sprecare token AI, previene notifiche push duplicate e unifica le fonti.
"""

import re
from difflib import SequenceMatcher
from typing import List, Dict, Any, Tuple, Optional, Set

# Stop words in italiano e inglese da filtrare
STOP_WORDS = {
    # Italiano
    "il", "lo", "la", "i", "gli", "le", "un", "uno", "una", "di", "a", "da", "in", "con", "su", "per", "tra", "fra",
    "and", "e", "ed", "or", "o", "del", "dello", "della", "dei", "degli", "delle", "al", "allo", "alla", "ai", "agli", "alle",
    "dal", "dallo", "dalla", "dai", "dagli", "dalle", "nel", "nello", "nella", "nei", "negli", "nelle", "sul", "sullo", "sulla",
    "ha", "hanno", "è", "sono", "stato", "stata", "stati", "state", "dopo", "come", "anche", "più", "nuovo", "nuova", "nuovi",
    "allarme", "allerta", "urgente", "scoperta", "scoperto", "annuncia", "pubblica", "rilascia", "notizia", "notizie",
    # Inglese
    "the", "a", "an", "in", "on", "at", "by", "for", "with", "about", "against", "between", "into", "through", "during",
    "before", "after", "above", "below", "to", "from", "up", "down", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "new", "wave", "cyberattacks", "attack", "attacks", "threat", "threats",
    "targets", "targeting", "critical", "security", "flaw", "flaws", "bug", "bugs", "vulnerability", "vulnerabilities"
}

CVE_REGEX = re.compile(r"\bCVE-\d{4}-\d{4,7}\b", re.IGNORECASE)

def extract_cves(text: str) -> List[str]:
    """Estrae tutti gli identificativi CVE in formato standard maiuscolo."""
    if not text:
        return []
    matches = CVE_REGEX.findall(text)
    # Rimuove duplicati preservando l'ordine
    seen = set()
    result = []
    for m in matches:
        up = m.upper()
        if up not in seen:
            seen.add(up)
            result.append(up)
    return result

def clean_tokens(text: str) -> Set[str]:
    """Estrae i token tecnici rilevanti da un testo rimuovendo punteggiatura e stop words."""
    if not text:
        return set()
    words = re.findall(r"\b[a-zA-Z0-9_\-\.]{3,}\b", text.lower())
    return {w for w in words if w not in STOP_WORDS and not w.isdigit()}

def is_semantic_duplicate(
    new_title: str,
    new_content: str,
    existing_articles: List[Dict[str, Any]],
    similarity_threshold: float = 0.65
) -> Tuple[bool, Optional[Dict[str, Any]], str]:
    """
    Verifica se la nuova notizia è un duplicato semantico di un articolo già archiviato.
    Ritorna: (is_duplicate, matched_article, matching_reason)
    """
    new_cves = set(extract_cves(f"{new_title} {new_content}"))
    new_tokens = clean_tokens(f"{new_title} {new_content[:500]}")
    new_title_clean = new_title.strip().lower()

    for existing in existing_articles:
        ex_title = (existing.get("title_it") or existing.get("original_title") or "").strip().lower()
        ex_content = (existing.get("original_title") or "") + " " + " ".join(existing.get("summary_points") or [])
        ex_tags = existing.get("tags") or []
        if isinstance(ex_tags, str):
            import json
            try:
                ex_tags = json.loads(ex_tags)
            except Exception:
                ex_tags = []

        # 1. Regola CVE: Se entrambe le notizie citano lo stesso CVE primario -> Duplicato Certo
        ex_cves = set(extract_cves(f"{ex_title} {ex_content} {' '.join(ex_tags)}"))
        cve_intersection = new_cves & ex_cves
        if cve_intersection:
            cve_str = ", ".join(list(cve_intersection)[:2])
            return True, existing, f"CVE in comune ({cve_str})"

        # 2. Regola Similarità Testuale Diretta dei Titoli
        seq_ratio = SequenceMatcher(None, new_title_clean, ex_title).ratio()
        if seq_ratio >= similarity_threshold:
            return True, existing, f"Similarità titolo ({int(seq_ratio * 100)}%)"

        # 3. Regola Sovrapposizione Token Tecnici (Jaccard & Entity Co-occurrence)
        ex_tokens = clean_tokens(f"{ex_title} {ex_content}")
        shared_tokens = new_tokens & ex_tokens

        if len(shared_tokens) >= 3:
            jaccard = len(shared_tokens) / max(len(new_tokens | ex_tokens), 1)
            # Se condividono 4+ token specifici, o 3 token con sufficiente densità
            if len(shared_tokens) >= 4 or jaccard >= 0.20 or seq_ratio >= 0.40:
                sample = ", ".join(list(shared_tokens)[:4])
                return True, existing, f"Entità e parole chiave condivise ({sample})"

    return False, None, ""

def merge_article_sources(
    existing: Dict[str, Any],
    new_source_name: str,
    new_source_url: str,
    new_threat_level: str = "MEDIO",
    new_tags: List[str] = None
) -> Dict[str, Any]:
    """
    Unifica le fonti e arricchisce l'articolo esistente senza duplicare la notizia.
    """
    merged = dict(existing)

    # 1. Aggiorna le fonti (es. "CSIRT Italia, The Hacker News")
    current_sources = [s.strip() for s in existing.get("source_name", "").split(",") if s.strip()]
    if new_source_name and new_source_name not in current_sources:
        current_sources.append(new_source_name)
        merged["source_name"] = ", ".join(current_sources)

    # 2. Mantieni il livello di minaccia più alto
    threat_hierarchy = {"CRITICO": 4, "ALTO": 3, "MEDIO": 2, "INFORMATIVO": 1}
    current_level = existing.get("threat_level", "MEDIO").upper()
    incoming_level = new_threat_level.upper() if new_threat_level else "MEDIO"

    if threat_hierarchy.get(incoming_level, 0) > threat_hierarchy.get(current_level, 0):
        merged["threat_level"] = incoming_level

    # 3. Unisci i tag senza duplicati
    current_tags = existing.get("tags") or []
    if isinstance(current_tags, str):
        import json
        try:
            current_tags = json.loads(current_tags)
        except Exception:
            current_tags = []

    if new_tags:
        for t in new_tags:
            if t not in current_tags:
                current_tags.append(t)
    merged["tags"] = current_tags

    return merged
