# CyberNews iOS 🛡️

App nativa per iPhone dedicata a **Cybersecurity, IT Security, ACN, NIS2, Golden Power e ISO 27001**, sviluppata in **SwiftUI / Xcode** con intelligenza artificiale potenziata da **Google Gemini 2.0 Flash**.

---

## 🎨 Design & Stile
* **Tema**: Minimal Dark profondo (`#09090C`).
* **Accento**: Cyber Orange vibrante (`#FF6B00`).
* **Materiali**: Glassmorfismo (`.ultraThinMaterial`), bordi sfumati hairline e linee morbide con curve continue.
* **Interazioni**: Animazioni spring fluide a 120 FPS e feedback aptico nativo Apple.

---

## 📂 Struttura del Progetto

```
NewsCyber/
├── backend/                       # Motore di Ingestion & AI
│   ├── .env                       # Variabili d'ambiente locali (PROTETTO DA GIT)
│   ├── .env.example               # Template per le credenziali
│   ├── requirements.txt           # Dipendenze Python
│   ├── ingest.py                  # Script di scansione 19 fonti + sintesi Gemini 2.0
│   ├── test_gemini.py             # Test rapido di connessione e prompt AI
│   └── schema.sql                 # Schema PostgreSQL per Supabase con Row Level Security
│
├── ios/                           # Applicazione Nativa iPhone
│   ├── CyberNews.xcodeproj        # Progetto Xcode (apribile con doppio clic)
│   ├── project.yml                # Configurazione xcodegen
│   └── CyberNews/
│       ├── Sources/
│       │   ├── CyberNewsApp.swift # Entry point SwiftUI con SwiftData
│       │   ├── Theme/             # Palette colori, glassmorfismo e animazioni
│       │   ├── Models/            # Article, ThreatLevel, NewsCategory, SavedArticle
│       │   ├── ViewModels/        # NewsFeedViewModel
│       │   ├── Services/          # NewsAPIService, HapticManager
│       │   └── Views/             # HomeFeed, Governance, Bookmarks, Detail, Settings
│       └── Resources/             # Assets.xcassets, Info.plist
│
└── .github/workflows/ingest.yml   # Automazione schedulata gratuita su GitHub Actions
```

---

## 🚀 Come avviare l'App su iPhone

1. Fai doppio clic sul file [`ios/CyberNews.xcodeproj`](file:///Users/lorenzofrasconi/Desktop/Progetti/NewsCyber/ios/CyberNews.xcodeproj) per aprirlo in **Xcode**.
2. Collega il tuo iPhone al Mac tramite cavo o Wi-Fi.
3. Nella scheda **Signing & Capabilities**, seleziona il tuo **Team Apple Developer**.
4. Seleziona il tuo iPhone nel selettore in alto e premi il tasto **Play (Run)** ▶️.

---

## 🔒 Sicurezza e Protezione Chiave Gemini

L'applicazione segue l'architettura **Zero-Key on Device**:
* Nessuna chiave privata è inclusa nell'app iPhone.
* L'elaborazione con Gemini 2.0 Flash avviene esclusivamente nel backend schedulato.
* L'app legge solo i dati già pronti via API REST con permessi di sola lettura.
