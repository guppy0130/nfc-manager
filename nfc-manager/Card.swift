//
//  Card.swift
//  nfc-manager
//
//  Created by Nick Yang on 11/27/25.
//

import SwiftUI

protocol internalNFCTag: Identifiable {
  var tagType: String { get }
  var manufacturer: Int { get set }
  var serialNumber: Data { get set }
  var NDEFData: NDEFData? { get set }

  var id: Data { get }

  // from https://www.iso.org/committee/45144.html?view=documents
  func serializeManufacturer() -> String
}

struct NFCTagView: View {
  @State var tag: any internalNFCTag

  var body: some View {
    List {
      Section("Tag Info") {
        LabeledContent {
          Text(tag.tagType)
        } label: {
          Text("Tag Type")
        }
        LabeledContent {
          Text(tag.serializeManufacturer())
        } label: {
          Text("Manufacturer")
        }
        LabeledContent {
          Text(tag.serialNumber.hexEncode())
        } label: {
          Text("Serial Number")
        }
      }
      NDEFView(NDEFData: tag.NDEFData ?? NDEFData())
    }
    .navigationTitle(tag.serialNumber.hexEncode())
  }
}
