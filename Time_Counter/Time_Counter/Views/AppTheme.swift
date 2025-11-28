//
//  Theme.swift
//  Time_Counter
//
//  Created by Baby Tinishu on 11/2/25.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case system
    case light
    case dark
    
    // MARK: Display Name
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    // MARK: Optional ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    // MARK: Primary Color
    var primaryColor: Color {
        switch self {
        default: return Color.accentColor
        }
    }
    
    // MARK: Background Color (platform-safe)
    var backgroundColor: Color {
        switch self {
        default:
            #if os(watchOS)
            return Color.black
            #else
            return Color(UIColor.systemBackground)
            #endif
        }
    }
    
    var secondaryColor: Color {
        switch self {
        default:
            #if os(watchOS)
            return Color.gray.opacity(0.2)
            #else
            return Color(UIColor.secondarySystemBackground)
            #endif
        }
    }
}
