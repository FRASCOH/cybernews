import Foundation

// MARK: - Modello Record CVE
public struct CVERecord: Identifiable, Codable, Hashable {
    public var id: String { cveId }
    public let cveId: String
    public let title: String?
    public let description: String?
    public let cvssScore: Double?
    public let cvssSeverity: String?
    public let vectorString: String?
    public let vendor: String?
    public let product: String?
    public let publishedDate: String?
    public let isKnownExploited: Bool

    public var severityColorName: String {
        guard let score = cvssScore else { return "threatInformativo" }
        if score >= 9.0 { return "threatCritico" }
        if score >= 7.0 { return "threatAlto" }
        if score >= 4.0 { return "threatMedio" }
        return "threatInformativo"
    }

    public var formattedScore: String {
        if let score = cvssScore {
            return String(format: "%.1f", score)
        }
        return "N/D"
    }
}

// MARK: - CVEService (Actor Concurrency Safe)
public actor CVEService {
    public static let shared = CVEService()
    private init() {}

    private var cache: [String: CVERecord] = [:]

    // URL Utili Ufficiali (nonisolated per accesso immediato sincrono)
    public nonisolated func nvdURL(for cveId: String) -> URL {
        URL(string: "https://nvd.nist.gov/vuln/detail/\(cveId)")!
    }

    public nonisolated func mitreURL(for cveId: String) -> URL {
        URL(string: "https://cve.org/CVERecord?id=\(cveId)")!
    }

    public nonisolated func cisaKevURL(for cveId: String) -> URL {
        URL(string: "https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=\(cveId)")!
    }

    /// Interroga l'API ufficiale MITRE / CVE.org per ottenere i dettagli della vulnerabilità
    public func fetchCVEDetails(cveId: String) async -> CVERecord {
        let cleanId = cveId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Controlla cache locale
        if let cached = cache[cleanId] {
            return cached
        }

        guard let url = URL(string: "https://cveawg.mitre.org/api/cve/\(cleanId)") else {
            return fallbackRecord(cveId: cleanId)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CyberNews-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                return fallbackRecord(cveId: cleanId)
            }

            let record = parseMITREResponse(cveId: cleanId, data: data)
            cache[cleanId] = record
            return record
        } catch {
            return fallbackRecord(cveId: cleanId)
        }
    }

    private func parseMITREResponse(cveId: String, data: Data) -> CVERecord {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let containers = json["containers"] as? [String: Any] else {
            return fallbackRecord(cveId: cveId)
        }

        let cna = containers["cna"] as? [String: Any] ?? [:]
        let title = cna["title"] as? String

        // Descrizione
        var desc: String? = nil
        if let descriptions = cna["descriptions"] as? [[String: Any]], let first = descriptions.first {
            desc = first["value"] as? String
        }

        // Vendor & Product
        var vendor: String? = nil
        var product: String? = nil
        if let affected = cna["affected"] as? [[String: Any]], let first = affected.first {
            vendor = first["vendor"] as? String
            product = first["product"] as? String
        }

        // Metriche CVSS (cerca prima in CNA, poi in ADP CISA/NVD)
        var cvssScore: Double? = nil
        var cvssSeverity: String? = nil
        var vectorString: String? = nil
        var isKnownExploited = false

        // 1. Cerca in CNA
        if let metrics = cna["metrics"] as? [[String: Any]] {
            extractCVSS(from: metrics, score: &cvssScore, severity: &cvssSeverity, vector: &vectorString)
        }

        // 2. Se mancanti, cerca nei blocchi ADP (es. CISA, NVD)
        if let adpList = containers["adp"] as? [[String: Any]] {
            for adp in adpList {
                if let adpMetrics = adp["metrics"] as? [[String: Any]] {
                    if cvssScore == nil {
                        extractCVSS(from: adpMetrics, score: &cvssScore, severity: &cvssSeverity, vector: &vectorString)
                    }

                    // Verifica se presente nel catalogo CISA KEV
                    for item in adpMetrics {
                        if let other = item["other"] as? [String: Any],
                           let type = other["type"] as? String,
                           type.lowercased() == "kev" {
                            isKnownExploited = true
                        }
                    }
                }
            }
        }

        // Data pubblicazione
        var publishedDate: String? = nil
        if let meta = json["cveMetadata"] as? [String: Any] {
            publishedDate = meta["datePublished"] as? String
        }

        return CVERecord(
            cveId: cveId,
            title: title,
            description: desc,
            cvssScore: cvssScore,
            cvssSeverity: cvssSeverity?.uppercased(),
            vectorString: vectorString,
            vendor: vendor,
            product: product,
            publishedDate: publishedDate,
            isKnownExploited: isKnownExploited
        )
    }

    private func extractCVSS(
        from metrics: [[String: Any]],
        score: inout Double?,
        severity: inout String?,
        vector: inout String?
    ) {
        for m in metrics {
            for key in ["cvssV3_1", "cvssV4_0", "cvssV3_0", "cvssV2_0"] {
                if let cvssObj = m[key] as? [String: Any] {
                    if let rawScore = cvssObj["baseScore"] {
                        if let doubleVal = rawScore as? Double {
                            score = doubleVal
                        } else if let intVal = rawScore as? Int {
                            score = Double(intVal)
                        }
                    }
                    if let sev = cvssObj["baseSeverity"] as? String {
                        severity = sev
                    }
                    if let vec = cvssObj["vectorString"] as? String {
                        vector = vec
                    }
                    if score != nil { return }
                }
            }
        }
    }

    private func fallbackRecord(cveId: String) -> CVERecord {
        CVERecord(
            cveId: cveId,
            title: nil,
            description: "Dettagli consultabili direttamente sul portale ufficiale NVD del NIST o su CVE.org.",
            cvssScore: nil,
            cvssSeverity: nil,
            vectorString: nil,
            vendor: nil,
            product: nil,
            publishedDate: nil,
            isKnownExploited: false
        )
    }
}
