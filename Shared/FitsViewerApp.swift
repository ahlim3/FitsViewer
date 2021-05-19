//
//  FitsViewerApp.swift
//  Shared
//
//  Created by anthony lim on 4/20/21.
//

import SwiftUI

@main
struct FitsViewerApp: App {
    @StateObject var fitsHandler = FITSHandler()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fitsHandler)
        }
    }
}
