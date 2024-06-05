//
//  MessingWithDeviceMotion.swift
//  MessingWithHealthKit
//
//  Created by Fabio Freitas on 16/05/24.
//

import SwiftUI
import CoreMotion

@Observable
class DeviceMotionManager {
    var rotationData = ""
    var accelerationData = ""
    
    @ObservationIgnored
    private var deviceMotion = CMMotionManager()
    
    @ObservationIgnored
    private let frequency = 1.0 / 10.0
    
    @ObservationIgnored
    private var q = OperationQueue()
    
    public func startDeviceMotionSensor() {
        guard deviceMotion.isDeviceMotionAvailable else { return }
        deviceMotion.deviceMotionUpdateInterval = frequency
        deviceMotion.showsDeviceMovementDisplay = true
        deviceMotion.startDeviceMotionUpdates(to: q) { [weak self] motion, _ in
            if let motion {
                let acc = motion.userAcceleration
                self?.accelerationData = String(format: "%.6f, %.6f, %.6f", acc.x, acc.y, acc.z)
                let rot = motion.rotationRate
                self?.rotationData = String(format: "%.6f, %.6f, %.6f", rot.x, rot.y, rot.z)
            }
        }
    }
    
    public func stopDeviceMotionSensor() {
        guard deviceMotion.isDeviceMotionActive else { return }
        deviceMotion.stopDeviceMotionUpdates()
    }
    
}

struct MessingWithDeviceMotion: View {
    @State var isReadingData = false
    @State var deviceMotionManager = DeviceMotionManager()
    
    var body: some View {
        VStack {
            Text("**Acceleration:** \(deviceMotionManager.accelerationData)")
                .foregroundStyle(Color.blue.gradient)
                .padding(.vertical)
            Text("**Rotation:** \(deviceMotionManager.rotationData)")
                .foregroundStyle(Color.purple.gradient)
            Divider()
                .padding(.vertical)
            HStack {
                Button("Start") {
                    isReadingData.toggle()
                    deviceMotionManager.startDeviceMotionSensor()
                }
                .padding(.trailing)
                .tint(Color.green.gradient)
                .disabled(isReadingData)
                Button("Stop") {
                    isReadingData.toggle()
                    deviceMotionManager.stopDeviceMotionSensor()
                }
                .tint(Color.red.gradient)
                .disabled(!isReadingData)
            }
        }
    }
}

#Preview {
    MessingWithDeviceMotion()
}
