//
//  AudioDevice+DataSource.swift
//
//  Created by Ruben Nine on 20/3/21.
//

import CoreAudio
import Foundation

// MARK: - ⚄ Data Source Functions

public extension AudioDevice {
    /// A list of item IDs for the currently selected data sources.
    ///
    /// - Returns: *(optional)* A `UInt32` array containing all the item IDs.
    func dataSource(scope: Scope) -> [UInt32]? {
        guard let address = validAddress(selector: kAudioDevicePropertyDataSource,
                                         scope: scope.asPropertyScope) else { return nil }

        var dataSourceIDs = [UInt32]()
        let status = getPropertyDataArray(address, value: &dataSourceIDs, andDefaultValue: 0)

        guard noErr == status else { return nil }

        return dataSourceIDs
    }

    /// A list of all the IDs of all the data sources currently available.
    ///
    /// - Returns: *(optional)* A `UInt32` array containing all the item IDs.
    func dataSources(scope: Scope) -> [UInt32]? {
        guard let address = validAddress(selector: kAudioDevicePropertyDataSources,
                                         scope: scope.asPropertyScope) else { return nil }

        var dataSourceIDs = [UInt32]()
        let status = getPropertyDataArray(address, value: &dataSourceIDs, andDefaultValue: 0)

        guard noErr == status else { return nil }

        return dataSourceIDs
    }

    /// Returns the data source name for a given data source ID.
    ///
    /// - Parameter dataSourceID: A data source ID.
    ///
    /// - Returns: *(optional)* A `String` with the data source name.
    func dataSourceName(dataSourceID: UInt32, scope: Scope) -> String? {
        var name: CFString = "" as CFString
        var mDataSourceID = dataSourceID

        let status: OSStatus = withUnsafeMutablePointer(to: &mDataSourceID) { mDataSourceIDPtr in
            withUnsafeMutablePointer(to: &name) { namePtr in
                var translation = AudioValueTranslation(
                    mInputData: mDataSourceIDPtr,
                    mInputDataSize: UInt32(MemoryLayout<UInt32>.size),
                    mOutputData: namePtr,
                    mOutputDataSize: UInt32(MemoryLayout<CFString>.size)
                )

                let address = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDataSourceNameForIDCFString,
                    mScope: scope.asPropertyScope,
                    mElement: Element.main.asPropertyElement
                )

                return getPropertyData(address, andValue: &translation)
            }
        }

        return noErr == status ? (name as String) : nil
    }
}
