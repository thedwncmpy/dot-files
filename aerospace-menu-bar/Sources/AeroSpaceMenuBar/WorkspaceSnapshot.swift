import Foundation
import CoreGraphics

struct Workspace: Decodable {
    let name: String
    let isFocused: Bool
    let rootLayout: String

    enum CodingKeys: String, CodingKey {
        case name = "workspace"
        case isFocused = "workspace-is-focused"
        case rootLayout = "workspace-root-container-layout"
    }
}

struct Window: Decodable {
    let id: Int
    let workspace: String
    let bundleID: String
    let appName: String

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case workspace
        case bundleID = "app-bundle-id"
        case appName = "app-name"
    }
}

struct WorkspaceGroup {
    let workspace: Workspace
    let apps: [Window]
    let focusedAppBundleID: String?
}

enum WorkspaceSnapshot {
    static func groups(
        workspaces: [Workspace],
        windows: [Window],
        focusedWindow: Window?,
        frames: [Int: CGRect],
        previousAppOrder: [String: [String]]
    ) -> [WorkspaceGroup] {
        workspaces.map { workspace in
            let previousRanks = Dictionary(uniqueKeysWithValues:
                (previousAppOrder[workspace.name] ?? []).enumerated().map { ($0.element, $0.offset) })
            let orderedWindows = windows.filter { $0.workspace == workspace.name }.sorted { lhs, rhs in
                if workspace.isFocused {
                    let left = frames[lhs.id]
                    let right = frames[rhs.id]
                    if let left, let right {
                        let vertical = workspace.rootLayout.hasPrefix("v_")
                        let leftPrimary = vertical ? left.minY : left.minX
                        let rightPrimary = vertical ? right.minY : right.minX
                        if leftPrimary != rightPrimary { return leftPrimary < rightPrimary }
                        let leftSecondary = vertical ? left.minX : left.minY
                        let rightSecondary = vertical ? right.minX : right.minY
                        if leftSecondary != rightSecondary { return leftSecondary < rightSecondary }
                    } else if left != nil || right != nil {
                        return left != nil
                    }
                }
                let leftRank = previousRanks[lhs.bundleID] ?? Int.max
                let rightRank = previousRanks[rhs.bundleID] ?? Int.max
                if leftRank != rightRank { return leftRank < rightRank }
                if lhs.appName != rhs.appName { return lhs.appName < rhs.appName }
                return lhs.id < rhs.id
            }
            var seen = Set<String>()
            let apps = orderedWindows.filter { seen.insert($0.bundleID).inserted }
            let focusedAppBundleID = focusedWindow?.workspace == workspace.name
                ? focusedWindow?.bundleID : nil
            return WorkspaceGroup(
                workspace: workspace,
                apps: apps,
                focusedAppBundleID: focusedAppBundleID
            )
        }
    }
}
