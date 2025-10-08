//
//  nfc_managerApp.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/7/25.
//

import SwiftData
import SwiftUI

@main
struct nfc_managerApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
}

extension Data {
  func hexEncode() -> String {
    if self.count == 1 {
      return String(format: "0x%02hhX", self[0])
    }
    return self.map { String(format: "%02hhX", $0) }.joined(separator: ":")
  }
}
