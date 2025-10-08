//
//  ContentView.swift
//  nfc-manager
//
//  Created by Nick Yang on 10/7/25.
//

import SwiftData
import SwiftUI

enum Tabs: Equatable, Hashable, Identifiable {
  var id: Self { self }
  case read
  case write
}

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var selectedTab: Tabs = .read

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Read", systemImage: "wave.3.right", value: .read) {
        NavigationStack {
          ReadView()
        }
      }
      Tab("Write", systemImage: "pencil", value: .write) {
        NavigationStack {
          WriteView()
        }
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: [], inMemory: true)
}
