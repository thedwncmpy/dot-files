import Foundation

/// Keeps focus-transition frame changes from briefly rearranging app icons.
struct AppOrderStabilizer {
    private var accepted: [String: [String]] = [:]
    private var pending: [String: [String]] = [:]

    var hasPendingChange: Bool { !pending.isEmpty }
    var acceptedOrders: [String: [String]] { accepted }

    mutating func update(_ groups: [WorkspaceGroup]) -> [WorkspaceGroup] {
        let workspaceNames = Set(groups.map { $0.workspace.name })
        accepted = accepted.filter { workspaceNames.contains($0.key) }
        pending = pending.filter { workspaceNames.contains($0.key) }

        return groups.map { group in
            let name = group.workspace.name
            let candidate = group.apps.map(\.bundleID)
            guard let previous = accepted[name] else {
                // An unseen workspace has only app-name order. Establish its
                // order when it first becomes visible and frames are available.
                if group.workspace.isFocused { accepted[name] = candidate }
                return group
            }

            let present = Set(candidate)
            let retained = previous.filter { present.contains($0) }
            let retainedSet = Set(retained)
            let displayed = retained + candidate.filter { !retainedSet.contains($0) }

            if candidate == displayed {
                pending.removeValue(forKey: name)
                accepted[name] = displayed
                return group
            }
            if pending[name] == candidate {
                accepted[name] = candidate
                pending.removeValue(forKey: name)
                return group
            }
            pending[name] = candidate
            accepted[name] = displayed
            let appsByID = Dictionary(uniqueKeysWithValues: group.apps.map { ($0.bundleID, $0) })
            return WorkspaceGroup(
                workspace: group.workspace,
                apps: displayed.compactMap { appsByID[$0] },
                focusedAppBundleID: group.focusedAppBundleID
            )
        }
    }
}
