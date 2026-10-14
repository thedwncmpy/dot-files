import XCTest
@testable import AeroSpaceMenuBar

final class AppOrderStabilizerTests: XCTestCase {
    func testTransientReorderDoesNotMoveIconsButConfirmedReorderDoes() throws {
        let workspace = try JSONDecoder().decode(Workspace.self, from: Data("""
        {"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"h_tiles"}
        """.utf8))
        let windows = try JSONDecoder().decode([Window].self, from: Data("""
        [{"window-id":1,"workspace":"1","app-bundle-id":"a","app-name":"A"},
         {"window-id":2,"workspace":"1","app-bundle-id":"b","app-name":"B"}]
        """.utf8))
        func group(_ apps: [Window]) -> [WorkspaceGroup] {
            [WorkspaceGroup(workspace: workspace, apps: apps, focusedAppBundleID: "b")]
        }

        var stabilizer = AppOrderStabilizer()
        XCTAssertEqual(stabilizer.update(group(windows))[0].apps.map(\.bundleID), ["a", "b"])
        XCTAssertEqual(stabilizer.update(group(windows.reversed()))[0].apps.map(\.bundleID), ["a", "b"])
        XCTAssertTrue(stabilizer.hasPendingChange)
        XCTAssertEqual(stabilizer.update(group(windows))[0].apps.map(\.bundleID), ["a", "b"])
        XCTAssertFalse(stabilizer.hasPendingChange)
        XCTAssertEqual(stabilizer.update(group(windows.reversed()))[0].apps.map(\.bundleID), ["a", "b"])
        XCTAssertEqual(stabilizer.update(group(windows.reversed()))[0].apps.map(\.bundleID), ["b", "a"])
        XCTAssertFalse(stabilizer.hasPendingChange)
    }

    func testInactiveWorkspaceGetsPositionOrderWhenFirstFocused() throws {
        let workspaces = try JSONDecoder().decode([Workspace].self, from: Data("""
        [{"workspace":"1","workspace-is-focused":false,"workspace-root-container-layout":"h_accordion"},
         {"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"h_accordion"}]
        """.utf8))
        let windows = try JSONDecoder().decode([Window].self, from: Data("""
        [{"window-id":1,"workspace":"1","app-bundle-id":"a","app-name":"A"},
         {"window-id":2,"workspace":"1","app-bundle-id":"b","app-name":"B"}]
        """.utf8))
        var stabilizer = AppOrderStabilizer()
        _ = stabilizer.update([WorkspaceGroup(
            workspace: workspaces[0], apps: windows, focusedAppBundleID: nil
        )])
        XCTAssertNil(stabilizer.acceptedOrders["1"])
        let visible = WorkspaceSnapshot.groups(
            workspaces: [workspaces[1]], windows: windows, focusedWindow: windows[1],
            frames: [1: CGRect(x: 100, y: 0, width: 100, height: 100),
                     2: CGRect(x: 0, y: 0, width: 100, height: 100)],
            previousAppOrder: stabilizer.acceptedOrders
        )
        XCTAssertEqual(stabilizer.update(visible)[0].apps.map(\.bundleID), ["b", "a"])
    }
}
