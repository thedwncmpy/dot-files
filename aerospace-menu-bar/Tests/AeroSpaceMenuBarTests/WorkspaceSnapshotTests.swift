import XCTest
import CoreGraphics
@testable import AeroSpaceMenuBar

final class WorkspaceSnapshotTests: XCTestCase {
    func testGroupsKeepWorkspaceOrderAndDeduplicateApps() throws {
        let workspaces = try JSONDecoder().decode([Workspace].self, from: Data("""
        [{"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"h_accordion"},
         {"workspace":"2","workspace-is-focused":false,"workspace-root-container-layout":"h_tiles"}]
        """.utf8))
        let windows = try JSONDecoder().decode([Window].self, from: Data("""
        [
          {"window-id":3,"workspace":"2","app-bundle-id":"com.apple.Safari","app-name":"Safari"},
          {"window-id":1,"workspace":"1","app-bundle-id":"com.apple.finder","app-name":"Finder"},
          {"window-id":2,"workspace":"1","app-bundle-id":"com.apple.finder","app-name":"Finder"}
        ]
        """.utf8))
        let groups = WorkspaceSnapshot.groups(
            workspaces: workspaces,
            windows: windows,
            focusedWindow: windows[1],
            frames: [:],
            previousAppOrder: [:]
        )
        XCTAssertEqual(groups.map(\.workspace.name), ["1", "2"])
        XCTAssertEqual(groups.map { $0.apps.count }, [1, 1])
        XCTAssertTrue(groups[0].workspace.isFocused)
        XCTAssertEqual(groups[0].focusedAppBundleID, "com.apple.finder")
        XCTAssertNil(groups[1].focusedAppBundleID)
    }

    func testNoFocusedWindowLeavesAppMarkersOff() throws {
        let workspaces = try JSONDecoder().decode([Workspace].self, from: Data("""
        [{"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"h_tiles"}]
        """.utf8))
        let groups = WorkspaceSnapshot.groups(
            workspaces: workspaces, windows: [], focusedWindow: nil,
            frames: [:], previousAppOrder: [:]
        )
        XCTAssertNil(groups[0].focusedAppBundleID)
    }

    func testVisibleAppsFollowHorizontalLayoutAndInactiveAppsKeepLastOrder() throws {
        let workspaces = try JSONDecoder().decode([Workspace].self, from: Data("""
        [{"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"h_accordion"},
         {"workspace":"2","workspace-is-focused":false,"workspace-root-container-layout":"v_tiles"}]
        """.utf8))
        let windows = try JSONDecoder().decode([Window].self, from: Data("""
        [
          {"window-id":1,"workspace":"1","app-bundle-id":"b","app-name":"B"},
          {"window-id":2,"workspace":"1","app-bundle-id":"a","app-name":"A"},
          {"window-id":3,"workspace":"2","app-bundle-id":"c","app-name":"C"},
          {"window-id":4,"workspace":"2","app-bundle-id":"d","app-name":"D"}
        ]
        """.utf8))
        let groups = WorkspaceSnapshot.groups(
            workspaces: workspaces, windows: windows, focusedWindow: nil,
            frames: [1: CGRect(x: 20, y: 0, width: 100, height: 100),
                     2: CGRect(x: 10, y: 0, width: 100, height: 100)],
            previousAppOrder: ["2": ["d", "c"]]
        )
        XCTAssertEqual(groups[0].apps.map(\.bundleID), ["a", "b"])
        XCTAssertEqual(groups[1].apps.map(\.bundleID), ["d", "c"])
    }

    func testVerticalLayoutUsesTopToBottomOrder() throws {
        let workspaces = try JSONDecoder().decode([Workspace].self, from: Data("""
        [{"workspace":"1","workspace-is-focused":true,"workspace-root-container-layout":"v_tiles"}]
        """.utf8))
        let windows = try JSONDecoder().decode([Window].self, from: Data("""
        [
          {"window-id":1,"workspace":"1","app-bundle-id":"a","app-name":"A"},
          {"window-id":2,"workspace":"1","app-bundle-id":"b","app-name":"B"}
        ]
        """.utf8))
        let groups = WorkspaceSnapshot.groups(
            workspaces: workspaces, windows: windows, focusedWindow: nil,
            frames: [1: CGRect(x: 0, y: 200, width: 100, height: 100),
                     2: CGRect(x: 50, y: 100, width: 100, height: 100)],
            previousAppOrder: [:]
        )
        XCTAssertEqual(groups[0].apps.map(\.bundleID), ["b", "a"])
    }
}
