import Foundation
internal import FaviconFinder

/// Service for discovering and caching favicon URLs
actor FaviconService {

    /// Discovers the favicon URL for a domain using FaviconFinder
    /// Returns the largest favicon URL found, or nil if discovery fails
    func discoverFaviconURL(for domain: String) async -> String? {
        guard let url = URL(string: "https://\(domain)") else { return nil }

        do {
            // Use FaviconFinder to discover favicon URLs
            // Note: We only fetch URLs, not download images
            let faviconURL = try await FaviconFinder(url: url)
                .fetchFaviconURLs()
                .largest()  // Get largest without downloading

            return faviconURL.source.absoluteString
        } catch {
            // Silently fail - favicon discovery is non-critical
            return nil
        }
    }
}
