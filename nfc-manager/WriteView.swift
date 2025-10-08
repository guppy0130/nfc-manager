//
//  WriteView.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/12/25.
//

import CoreNFC
import IdentifiedCollections
import SwiftUI

@Observable
class NDEFPayloadToWrite {
  var payloads: IdentifiedArrayOf<NFCNDEFPayloadIdentified>

  init(payloads: [NFCNDEFPayloadIdentified] = []) {
    self.payloads = IdentifiedArray(uniqueElements: payloads)
  }

  // TODO: figure out if we need to count anything else
  /// count the number of bytes consumed by the payloads?
  func size() -> UInt8 {
    return 0
  }
}

@Observable
class NFCWriter: NSObject, NFCNDEFReaderSessionDelegate {
  public var discoveredTags: [any internalNFCTag] = []
  var session: NFCNDEFReaderSession?

  public func getAvailableTags() {
    self.discoveredTags.removeAll()
    session = NFCNDEFReaderSession(
      delegate: self,
      queue: nil,
      invalidateAfterFirstRead: false
    )
    session?.alertMessage = "Hold your device near an NFC tag"
    session?.begin()
  }

  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
    print(error)
  }

  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    print(messages)
  }
}

struct WriteView: View {
  @State var NDEFData: NDEFPayloadToWrite = NDEFPayloadToWrite()
  @State var nfcWriter = NFCWriter()

  var body: some View {
    List {
      Section("NDEF Info") {
        LabeledContent {
          Text("\(NDEFData.size()) bytes")
        } label: {
          Text("Used")
        }
      }
      Section("NDEF Payloads") {
        Button(
          "Add", systemImage: "plus",
          action: {
            NDEFData.payloads.append(
              NFCNDEFPayloadIdentified(
                payload:
                  NFCNDEFPayload(
                    format: .empty,
                    type: Data(),
                    identifier: Data(),
                    payload: Data()
                  )
              )
            )
          })
        // TODO: probably https://github.com/pointfreeco/swift-identified-collections
        ForEach(NDEFData.payloads) { payload in
          NavigationLink {
            NDEFPayloadView(payload: payload)
          } label: {
            Text("Payload \(payload.payload.payload.hexEncode().prefix(8))")
          }
        }
        .onDelete(perform: deletePayload)
      }
      Button("Write to Tag", systemImage: "pencil") {
        nfcWriter.getAvailableTags()
      }
    }
    .navigationTitle("Write NFC Tag")
  }

  func deletePayload(at offsets: IndexSet) {
    // OrderedSet does not implement remove(atOffsets:)
    for offset in offsets.sorted(by: >) {
      NDEFData.payloads.remove(at: offset)
    }
  }
}

#Preview {
  NavigationStack {
    WriteView(NDEFData: NDEFPayloadToWrite())
  }
}
