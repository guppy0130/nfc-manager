//
//  WellKnownTypeEnum.swift
//  nfc-manager
//
//  Created by Nick Yang on 11/29/25.
//

// https://nfc-forum.org/build/assigned-numbers

// TODO: fill in the rest of these
enum WellKnownTypeEnum: String, CustomStringConvertible {
  case text = "T"
  case uri = "U"

  var description: String {
    switch self {
    case .text: return "Text"
    case .uri: return "URI"
    }
  }
}
