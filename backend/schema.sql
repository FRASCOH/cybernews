-- ============================================================
-- CyberNews Database Schema (Supabase / PostgreSQL)
-- ============================================================

-- 1. Crea la tabella delle notizie
CREATE TABLE IF NOT EXISTS public.news_articles (
    id TEXT PRIMARY KEY,
    url_hash TEXT UNIQUE NOT NULL,
    title_it TEXT NOT NULL,
    original_title TEXT,
    summary_points JSONB NOT NULL DEFAULT '[]'::jsonb,
    action_mitigation TEXT,
    threat_level TEXT NOT NULL CHECK (threat_level IN ('CRITICO', 'ALTO', 'MEDIO', 'INFORMATIVO')),
    category TEXT NOT NULL CHECK (category IN ('NIS2_GOLDEN_POWER', 'VULNERABILITA_ZERODAY', 'RANSOMWARE_ATTACCHI', 'COMPLIANCE_ISO', 'THREAT_INTEL')),
    target_audience TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    source_name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    published_at TEXT,
    is_breaking BOOLEAN DEFAULT false,
    audio_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Indici per velocizzare le query dell'app iOS
CREATE INDEX IF NOT EXISTS idx_news_category ON public.news_articles(category);
CREATE INDEX IF NOT EXISTS idx_news_threat_level ON public.news_articles(threat_level);
CREATE INDEX IF NOT EXISTS idx_news_created_at ON public.news_articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_is_breaking ON public.news_articles(is_breaking);

-- 3. Attivazione Row Level Security (RLS) - FONDAMENTALE PER LA SICUREZZA
ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;

-- 4. Policy di sola lettura per l'applicazione iOS (chiave ANON pubblica)
-- Chiunque possieda l'app può solo LEGGERE le notizie
CREATE POLICY "Accesso pubblico in sola lettura per App iOS"
ON public.news_articles
FOR SELECT
TO anon, authenticated
USING (true);

-- 5. Policy di scrittura riservata solo al Service Role (Backend / GitHub Actions)
-- Nessun utente esterno può modificare, inserire o cancellare dati
CREATE POLICY "Scrittura riservata solo al backend con service_role"
ON public.news_articles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
