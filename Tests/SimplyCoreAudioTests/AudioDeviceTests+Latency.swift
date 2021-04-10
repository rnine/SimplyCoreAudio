@testable import SimplyCoreAudio
import XCTest

extension AudioDeviceTests {
    func testLatency() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.latency(scope: .output), 0)
        XCTAssertEqual(device.latency(scope: .input), 0)
    }

    func testSafetyOffset() throws {
        let device = try getNullDevice()

        XCTAssertEqual(device.safetyOffset(scope: .output), 0)
        XCTAssertEqual(device.safetyOffset(scope: .input), 0)
    }

    func testBufferFrameSize() throws {
        let device = try getNullDevice()

        // 512 is the default buffer size
        XCTAssertEqual(device.bufferFrameSize(scope: .output), 512)
        XCTAssertEqual(device.bufferFrameSize(scope: .input), 512)

        XCTAssertTrue(device.setBufferFrameSize(256, scope: .output))
        XCTAssertTrue(device.setBufferFrameSize(256, scope: .input))

        XCTAssertEqual(device.bufferFrameSize(scope: .output), 256)
        XCTAssertEqual(device.bufferFrameSize(scope: .input), 256)
    }

    func testLatencyOnInstalledDevices() {
        let devices = simplyCA.allDevices.sorted { (lhs, rhs) -> Bool in
            lhs.name < rhs.name
        }

        Swift.print("\nAll Devices on the system with default settings:\n")
        for i in 0 ..< devices.count {
            let device = devices[i]
            guard let string = info(for: device) else { continue }
            Swift.print("\(i + 1)", string)
        }

        Swift.print("\nChanged to bufferSize of 32:\n")

        for i in 0 ..< devices.count {
            let device = devices[i]
            device.setBufferFrameSize(32, scope: .input)
            device.setBufferFrameSize(32, scope: .output)

            guard let string = info(for: device) else { continue }
            Swift.print("\(i + 1)", string)
        }
    }

    func info(for device: AudioDevice) -> String? {
        let indent = "    "
        let isDefaultDevice = device == simplyCA.defaultInputDevice || device == simplyCA.defaultOutputDevice
        let isSystemOutputDevice = device == simplyCA.defaultSystemOutputDevice

        let aggregateIcon = device.isAggregateDevice ? "👥 (Aggregate Device) " : ""

        var directionIcon = "🎧+🎤"

        if device.isInputOnlyDevice {
            directionIcon = "🎤"
        } else if device.isOutputOnlyDevice {
            directionIcon = "🎧"
        }

        let selectedIcon = isDefaultDevice ? "👉" : ""
        let systemIcon = isSystemOutputDevice ? "🔊" : ""

        guard let sampleRate = device.actualSampleRate else {
            XCTFail("Unable to determine sample rate for device")
            return nil
        }

        // title
        var items: [Any?] = ["\(systemIcon)\(aggregateIcon)\(directionIcon)\(selectedIcon)",
                             device.name + " (\(device.id)) UID:", device.uid,
                             "sampleRate:", sampleRate,
                             "\n"]

        if let aggregateInputs = device.ownedAggregateInputDevices,
           let aggregateOutputs = device.ownedAggregateOutputDevices {
            if !aggregateInputs.isEmpty {
                let inputString = aggregateInputs.map { "🎤 " + $0.name + " (\($0.id)) UID:" + ($0.uid ?? "nil") }
                items += [indent, "👥 Inputs: ", inputString, "\n"]
            }

            if !aggregateOutputs.isEmpty {
                let outputString = aggregateOutputs.map { "🎧 " + $0.name + " (\($0.id)) UID:" + ($0.uid ?? "nil") }
                items += [indent, "👥 Outputs", outputString, "\n"]
            }
        }
        let inputLatency = device.fixedLatency(scope: .input)
        guard let inputPresentationLatency = device.presentationLatency(scope: .input) else {
            XCTFail("Failed to get presentation latency for input")
            return nil
        }

        let outputLatency = device.fixedLatency(scope: .output)
        guard let outputPresentationLatency = device.presentationLatency(scope: .output) else {
            XCTFail("Failed to get presentation latency for output")
            return nil
        }

        items += [indent, "Input", inputLatency, "Total Frames", inputLatency.totalFrames, "\n",
                  indent, "Resulting Input Latency is \(inputPresentationLatency * 1000)ms",
                  "\n",
                  indent, "Output", outputLatency, "Total Frames", outputLatency.totalFrames, "\n",
                  indent, "Resulting Output Latency is \(outputPresentationLatency * 1000)ms",
                  "\n"]

        let content = (items.map {
            String(describing: $0 ?? "nil")
        }).joined(separator: " ")
        return content
    }
}
