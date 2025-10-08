//
//  NDEFView.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/12/25.
//

import CoreNFC
import OrderedCollections
import SwiftUI

extension NFCNDEFStatus: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case .notSupported: return "Not Supported"
    case .readOnly: return "Read Only"
    case .readWrite: return "Read/Write"
    @unknown default: return "Unknown"
    }
  }
}

extension NFCTypeNameFormat: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case .empty: return "Empty"
    case .nfcWellKnown: return "NFC Forum Well Known"
    case .media: return "Media"
    case .absoluteURI: return "Absolute URI"
    case .nfcExternal: return "NFC Forum External"
    case .unknown: return "Unknown"
    case .unchanged: return "Unchanged"
    @unknown default: return "Unknown"
    }
  }
}

extension NFCNDEFPayload {
  func wellKnownStr() -> String {
    if let url = self.wellKnownTypeURIPayload() {
      return url.absoluteString
    }
    let (text, _) = self.wellKnownTypeTextPayload()
    if let text = text {
      return text
    }
    return self.payload.hexEncode()
  }
}

@Observable
class NDEFData {
  var status: NFCNDEFStatus
  var capacity: Int
  var used: Int
  var payloads: OrderedSet<NFCNDEFPayload>

  init(
    status: NFCNDEFStatus = .notSupported, capacity: Int = 0, used: Int = 0,
    payloads: [NFCNDEFPayload] = []
  ) {
    self.status = status
    self.capacity = capacity
    self.used = used
    self.payloads = OrderedSet(payloads)
  }
}

struct NDEFView: View {
  var NDEFData: NDEFData

  var body: some View {
    Section("NDEF Info") {
      LabeledContent {
        Text(NDEFData.status.description)
      } label: {
        Text("Status")
      }
      LabeledContent {
        Text("\(NDEFData.capacity) bytes")
      } label: {
        Text("User Capacity")
      }
      LabeledContent {
        Text("\(NDEFData.used) bytes")
      } label: {
        Text("Used")
      }
    }
    Section("NDEF Payloads") {
      ForEach(Array(NDEFData.payloads.enumerated()), id: \.offset) { offset, payload in
        NavigationLink {
          NDEFPayloadView(payload: payload)
        } label: {
          Text("Payload \(offset + 1)")
        }
      }
    }
  }
}

struct NDEFPayloadView: View {
  var payload: NFCNDEFPayload

  var body: some View {
    List {
      LabeledContent {
        Text(payload.typeNameFormat.description)
      } label: {
        Text("Record Type")
      }
      LabeledContent {
        Text(payload.type.hexEncode())
      } label: {
        Text("Type")
      }
      LabeledContent {
        Text(payload.identifier.hexEncode())
      } label: {
        Text("Identifier")
      }
      LabeledContent {
        Text(payload.payload.hexEncode())
      } label: {
        LabeledContent {
          Text("\(payload.payload.count) bytes")
        } label: {
          Text("Payload")
        }
      }
      if payload.wellKnownStr() != payload.payload.hexEncode() {
        LabeledContent {
          Text(payload.wellKnownStr())
        } label: {
          Text("Parsed Content")
        }
      }
    }
    .navigationTitle("Payload")
  }
}

#Preview {
  NavigationStack {
    List {
      NDEFView(
        NDEFData: NDEFData(payloads: [
          NFCNDEFPayload(
            format: .absoluteURI,
            type: Data([0x55]),
            identifier: Data([0x01]),
            payload: Data([0x01, 0x02, 0x03])
          )
        ]))
    }
  }
}
