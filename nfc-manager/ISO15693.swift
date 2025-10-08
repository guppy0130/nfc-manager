//
//  ISO15693.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/12/25.
//

import CoreNFC
import SwiftUI

@Observable
class ISO15693: internalNFCTag {
  var tagType: String
  var manufacturer: Int
  var serialNumber: Data
  var NDEFData: NDEFData?

  init(
    tagType: String = "ISO 15693",
    manufacturer: Int = 0,
    serialNumber: Data = Data(),
    NDEFData: NDEFData? = nil
  ) {
    self.tagType = tagType
    self.manufacturer = manufacturer
    self.serialNumber = serialNumber
    self.NDEFData = NDEFData
  }

  var id: Data {
    return self.serialNumber
  }

  func serializeManufacturer() -> String {
    if let fileURL = Bundle.main.url(
      forResource: "ManufacturerCodeNameMap", withExtension: ".json")
    {
      do {
        let data = try Data(contentsOf: fileURL)
        let contents = try JSONDecoder().decode([String: String].self, from: data)
        if let value = contents[self.manufacturer.formatted()] {
          return value
        }
      } catch {
        // not really anything to do here
      }
    }
    return self.manufacturer.formatted()
  }
}
