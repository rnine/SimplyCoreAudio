//
//  AMCoreAudioDevice+Formatters.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 18/01/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import Foundation

@available(*, deprecated, message="this function will be removed in version 3.0") extension AMCoreAudioDevice {

    public final class func formattedSampleRate(sampleRate: Float64, useShortFormat: Bool) -> String {
        if (useShortFormat) {
            return String(format: NSLocalizedString("%.1f kHz", comment: ""),
                          sampleRate * 0.001)
        } else {
            return String(format: NSLocalizedString("%.3f kHz", comment: ""),
                          sampleRate * 0.001)
        }
    }

    public final class func formattedVolumeInDecibels(volume: Float32) -> String {
        return String(format: NSLocalizedString("%.1fdB", comment: ""), volume)
    }

    public final func actualSampleRateFormattedWithShortFormat(useShortFormat: Bool) -> String {
        return self.dynamicType.formattedSampleRate(actualSampleRate() ?? 0, useShortFormat: useShortFormat)
    }

    public final func numberOfChannelsDescription() -> String {
        let inputChannels = channelsForDirection(.Recording) ?? 0
        let outputChannels = channelsForDirection(.Playback) ?? 0

        return String(format: NSLocalizedString("%d in/ %d out", comment: ""),
                      inputChannels,
                      outputChannels
        )
    }

    public final func latencyDescription() -> String {
        let inLatency = deviceLatencyFramesForDirection(.Recording) ?? 0
        let outLatency = deviceLatencyFramesForDirection(.Playback) ?? 0
        let inSafetyOffsetLatency = deviceSafetyOffsetFramesForDirection(.Recording) ?? 0
        let outSafetyOffsetLatency = deviceSafetyOffsetFramesForDirection(.Playback) ?? 0

        let totalInLatency = inLatency + inSafetyOffsetLatency
        let totalOutLatency = outLatency + outSafetyOffsetLatency

        var formattedString = ""

        if totalInLatency > 0 {
            formattedString.appendContentsOf(String(format: NSLocalizedString("%.1fms in", comment: ""),
                Float64(totalInLatency) / (nominalSampleRate() ?? 0) * 1000)
            )
        }

        if totalOutLatency > 0 {
            if !formattedString.isEmpty {
                formattedString.appendContentsOf(NSLocalizedString("/ ", comment: ""))
            }

            formattedString.appendContentsOf(String(format: NSLocalizedString("%.1fms out", comment: ""),
                Float64(totalOutLatency) / (nominalSampleRate() ?? 0) * 1000)
            )
        }

        return formattedString
    }
}
