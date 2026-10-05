import Foundation

enum AeroSpaceError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message): return message
        }
    }
}

struct AeroSpaceClient {
    static let executablePath: String = {
        let candidates = ["/opt/homebrew/bin/aerospace", "/usr/local/bin/aerospace"]
        return candidates.first(where: FileManager.default.isExecutableFile(atPath:)) ?? "aerospace"
    }()


    func snapshot(previousAppOrder: [String: [String]]) throws -> [WorkspaceGroup] {
        let workspaces: [Workspace] = try query([
            "list-workspaces", "--monitor", "focused", "--json", "--format",
            "%{workspace} %{workspace-is-focused} %{workspace-root-container-layout}",
        ])
        let windows: [Window] = try query([
            "list-windows", "--monitor", "focused", "--json", "--format",
            "%{window-id} %{workspace} %{app-bundle-id} %{app-name}",
        ])
        // AeroSpace returns an error if no window is focused (for example, while
        // the desktop has focus). The workspace and app list still remain valid.
        let focusedWindows: [Window]? = try? query([
            "list-windows", "--focused", "--json", "--format",
            "%{window-id} %{workspace} %{app-bundle-id} %{app-name}",
        ])
        return WorkspaceSnapshot.groups(
            workspaces: workspaces,
            windows: windows,
            focusedWindow: focusedWindows?.first,
            frames: WindowFrames.current(),
            previousAppOrder: previousAppOrder
        )
    }

    func switchToWorkspace(_ name: String) throws {
        _ = try run(["workspace", name])
    }

    private func query<T: Decodable>(_ arguments: [String]) throws -> T {
        try JSONDecoder().decode(T.self, from: run(arguments))
    }

    private func run(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.executablePath)
        process.arguments = arguments
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "AeroSpace command failed"
            throw AeroSpaceError.commandFailed(message)
        }
        return data
    }
}
