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
    case forest
    case midnight
    
    // MARK: Display Name
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        case .forest: return "Forest Green"
        case .midnight: return "Midnight Blue"
        }
    }
    
    // MARK: Optional ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }
    
    // MARK: Primary Color
    var primaryColor: Color {
        switch self {
        case .forest: return Color.green.opacity(0.9)
        case .midnight: return Color.blue.opacity(0.8)
        default: return Color.accentColor
        }
    }
    
    // MARK: Background Color (platform-safe)
    var backgroundColor: Color {
        switch self {
        case .forest: return Color.green.opacity(0.15)
        case .midnight: return Color.blue.opacity(0.15)
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
        case .forest: return Color.green.opacity(0.5)
        case .midnight: return Color.blue.opacity(0.5)
        default:
            #if os(watchOS)
            return Color.gray.opacity(0.2)
            #else
            return Color(UIColor.secondarySystemBackground)
            #endif
        }
    }
}
