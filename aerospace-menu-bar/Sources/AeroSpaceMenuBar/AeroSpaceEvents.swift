import Foundation

final class AeroSpaceEvents {
    private var process: Process?
    private var output: Pipe?
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        ensureRunning()
    }

    func ensureRunning() {
        guard process?.isRunning != true else { return }
        output?.fileHandleForReading.readabilityHandler = nil

        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: AeroSpaceClient.executablePath)
        process.arguments = ["subscribe", "focus-changed", "focused-workspace-changed", "window-detected"]
        process.standardOutput = output
        process.standardError = Pipe()
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard !handle.availableData.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            DispatchQueue.main.async { self?.onChange() }
        }
        do {
            try process.run()
            self.process = process
            self.output = output
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
        }
    }

    func stop() {
        output?.fileHandleForReading.readabilityHandler = nil
        if process?.isRunning == true { process?.terminate() }
        process = nil
        output = nil
    }

    deinit { stop() }
}
