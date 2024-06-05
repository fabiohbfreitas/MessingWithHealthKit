//
//  ContentView.swift
//  MessingWithHealthKit
//
//  Created by Fabio Freitas on 09/05/24.
//

import SwiftUI
import HealthKit


struct ContentView: View {
    @State var healthStore = HealthStore()
    
    var body: some View {
        TabView {
            Group {
                HealthKitDemo()
            }.tabItem {
                Text("HealthKit")
            }
            
            Group {
                MessingWithCoreMotion()
            }.tabItem {
                Text("CoreMotion")
            }
            
            Group {
                MessingWithDeviceMotion()
            }.tabItem {
                Text("DeviceMotion")
            }
        }
    }
}

#Preview {
    ContentView()
}
