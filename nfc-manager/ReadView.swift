//
//  ReadView.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/8/25.
//

import CoreNFC
import IdentifiedCollections
import SwiftUI

@Observable
class NFCReader: NSObject, NFCTagReaderSessionDelegate {
  public var generatedTags: [any internalNFCTag] = []
  var tagCount: Int = 0
  var tagIdx: Int = 0
  var session: NFCTagReaderSession?

  public func read() {
    self.generatedTags.removeAll()
    session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)
    session?.alertMessage = "Hold your device near an NFC tag"
    session?.begin()
  }

  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
    print(error)
    self.session = nil
  }

  private func queryNDEFHandler(status: NFCNDEFStatus, capacity: Int, error: (any Error)?) {
    if error != nil {
      return
    }
    self.generatedTags[tagIdx].NDEFData = nfc_manager.NDEFData(status: status, capacity: capacity)
  }

  private func readNDEFHandler(message: NFCNDEFMessage?, error: (any Error)?) {
    if error != nil {
      invalidateSession(error: error)
      return
    }
    if message == nil {
      return
    }

    // update used
    if let used = message?.length {
      generatedTags[tagIdx].NDEFData?.used = used
    }
    // list payloads
    if let payloads = message?.records {
      for payload in payloads {
        let identifiedPayload = NFCNDEFPayloadIdentified(payload: payload)
        generatedTags[tagIdx].NDEFData?.payloads.append(identifiedPayload)
      }
    }

    // only invalidate when we've read all the tags
    if tagIdx == (tagCount - 1) {  // count vs idx
      invalidateSession()
    }
  }

  private func invalidateSession(error: (any Error)? = nil) {
    // nothing to do
    guard let session = self.session else {
      return
    }
    // if there is no error, invalidate the session (successfully read tag?)
    guard let err = error else {
      session.invalidate()
      self.session = nil
      return
    }
    self.session?.invalidate(errorMessage: err.localizedDescription)
    self.session = nil
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
    if tags.count == 0 {
      session.invalidate(errorMessage: "No tags?")
      invalidateSession()
      return
    }

    // store how many tags we have to populate
    tagCount = tags.count

    for (idx, tag) in tags.enumerated() {
      // TODO: this might be escaping
      tagIdx = idx
      print(tag)

      // handle some spec-specific fields here
      switch tag {
      case .iso15693(let isoTag):
        let generatedTag = ISO15693(
          manufacturer: isoTag.icManufacturerCode,
          serialNumber: isoTag.icSerialNumber
        )
        self.generatedTags.append(generatedTag)
        // connect to the tag to retrieve some info
        session.connect(to: tag) { (error: Error?) in
          if error != nil {
            self.invalidateSession(error: error)
            return
          }
          isoTag.queryNDEFStatus(completionHandler: self.queryNDEFHandler)
          isoTag.readNDEF(completionHandler: self.readNDEFHandler)
        }
        break
      case .miFare(let mifareTag):
        let generatedTag = ISO14443(
          manufacturer: Int(mifareTag.identifier[0]),  // the uint8 is guaranteed to fit
          serialNumber: mifareTag.identifier
        )
        self.generatedTags.append(generatedTag)

        session.connect(to: tag) { (error: Error?) in
          if error != nil {
            self.invalidateSession(error: error)
            return
          }
          mifareTag.queryNDEFStatus(completionHandler: self.queryNDEFHandler)
          mifareTag.readNDEF(completionHandler: self.readNDEFHandler)
        }

        break
      default: break
      }
    }
  }
}

struct ReadView: View {
  @State var nfcReader = NFCReader()

  var body: some View {
    List {
      // stupid protocol-related hacks require hardcoded id
      ForEach(nfcReader.generatedTags, id: \.id) { tag in
        NavigationLink {
          NFCTagView(tag: tag)
        } label: {
          Text(tag.serialNumber.hexEncode())
        }
      }
    }
    .navigationTitle("Tag Details")
    .refreshable {
      nfcReader.read()
    }
    .overlay {
      if nfcReader.generatedTags.isEmpty {
        ContentUnavailableView {
          Label("No NFC tags read", systemImage: "magnifyingglass")
        } description: {
          Text("Pull to scan")
        } actions: {
          Button("Scan") {
            nfcReader.read()
          }
        }

      }
    }
  }
}

#Preview {
  NavigationStack {
    ReadView()
  }
}
