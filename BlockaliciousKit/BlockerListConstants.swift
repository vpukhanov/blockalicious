import Foundation

/// Platform-specific constants for Safari content blocking
public enum BlockerListConstants {
    #if os(iOS)
    public static let contentBlockerBundleId = "ru.pukhanov.Blockalicious.Content-Blocker-iOS"
    public static let securityGroupId = "group.BFJQQT3YDX.Blockalicious"
    #else
    public static let contentBlockerBundleId = "ru.pukhanov.Blockalicious.Content-Blocker"
    public static let securityGroupId = "BFJQQT3YDX.Blockalicious"
    #endif
}
