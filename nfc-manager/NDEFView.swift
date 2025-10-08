//
//  NDEFView.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/12/25.
//

import CoreNFC
import IdentifiedCollections
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

extension NFCTypeNameFormat: @retroactive CaseIterable {
  public static var allCases: [NFCTypeNameFormat] {
    return [.empty, .nfcWellKnown, .media, .absoluteURI, .nfcExternal, .unknown, .unchanged]
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
class NFCNDEFPayloadIdentified: Identifiable {
  var id: UUID
  var payload: NFCNDEFPayload

  init(id: UUID = UUID(), payload: NFCNDEFPayload) {
    self.id = id
    self.payload = payload
  }

  /// renders well-known string if available (e.g., `0x54 (Text)`)
  func wellKnownTypePretty() -> String {
    var s = self.payload.type.hexEncode()
    if let stringifiedType = String(data: self.payload.type, encoding: .ascii) {
      if let e = WellKnownTypeEnum(rawValue: stringifiedType) {
        s += " (\(e.description))"
      }
    }
    return s
  }
}

@Observable
class NDEFData {
  var status: NFCNDEFStatus
  var capacity: Int
  var used: Int
  var payloads: IdentifiedArrayOf<NFCNDEFPayloadIdentified>

  init(
    status: NFCNDEFStatus = .notSupported,
    capacity: Int = 0,
    used: Int = 0,
    payloads: [NFCNDEFPayload] = []
  ) {
    self.status = status
    self.capacity = capacity
    self.used = used
    self.payloads = IdentifiedArray()
    for payload in payloads {
      self.payloads.append(NFCNDEFPayloadIdentified(payload: payload))
    }
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
      ForEach(NDEFData.payloads) { payload in
        NavigationLink {
          NDEFPayloadView(payload: payload)
            .disabled(true)
        } label: {
          // TODO: first three bytes should be sufficient?
          Text("Payload \(payload.payload.payload.hexEncode().prefix(8))")
        }
      }
    }
  }
}

struct NDEFPayloadView: View {
  @State var payload: NFCNDEFPayloadIdentified

  var body: some View {
    List {
      Picker(selection: $payload.payload.typeNameFormat) {
        ForEach(NFCTypeNameFormat.allCases, id: \.description) { tnf in
          Text(tnf.description).tag(tnf)
        }
      } label: {
        Text("Record Type")
      }
      LabeledContent {
        Text(payload.wellKnownTypePretty())
      } label: {
        Text("Type")
      }
      LabeledContent {
        Text(payload.payload.identifier.hexEncode())
      } label: {
        Text("Identifier")
      }
      LabeledContent {
        Text(payload.payload.payload.hexEncode())
      } label: {
        LabeledContent {
          Text("\(payload.payload.payload.count) bytes")
        } label: {
          Text("Payload")
        }
      }
      if payload.payload.wellKnownStr() != payload.payload.payload.hexEncode() {
        LabeledContent {
          Text(payload.payload.wellKnownStr())
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
        NDEFData: NDEFData(
          status: .readOnly,
          capacity: 1024,
          used: 60,
          payloads: [
            NFCNDEFPayload(
              format: .absoluteURI,
              type: Data([0x55]),
              identifier: Data([0x01]),
              payload: Data([0x01, 0x02, 0x69])
            )
          ]))
    }
  }
}
