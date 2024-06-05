//
//  MessingWithCoreMotion.swift
//  MessingWithHealthKit
//
//  Created by Fabio Freitas on 14/05/24.
//

import Foundation
import SwiftUI
import CoreMotion

@Observable
class SensorsManager {
    var isReadingData = false
    var accelerometerData = ""
    var gyroData = ""
    
    var motionManager = CMMotionManager()
    var accelerometerTimer: Timer?
    var q = OperationQueue()
    
    private var frequency = 1.0 / 10.0
    
    public func start() {
        startAccelerometer()
        startGyroscope()
    }
    
    public func stop() {
        stopAccelerometer()
        stopGyroscope()
        q.cancelAllOperations()
    }
    
    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = frequency
        motionManager.startAccelerometerUpdates(to: q) { [weak self] data, _ in
            if let data {
                let acc = data.acceleration
                self?.accelerometerData = "\(String(format: "%.4f | %.4f | %.4f", acc.x, acc.y, acc.z))"
            }
        }
    }
    
    private func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func startGyroscope() {
        guard motionManager.isGyroAvailable else {  return }
        
        
        motionManager.gyroUpdateInterval = frequency
        motionManager.startGyroUpdates(to: q) { [weak self] data, _ in
            if let data {
                self?.gyroData = "\(String(format: "%.4f | %.4f | %.4f", data.rotationRate.x, data.rotationRate.y, data.rotationRate.z))"
            }
        }
    }
    
    private func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }
}

struct MessingWithCoreMotion: View {
    @State var sensorsManager = SensorsManager()
    @State var isRecievingData = false
    
    var body: some View {
        VStack {
            VStack {
                Text("**Raw Accelerometer:** \(sensorsManager.accelerometerData)")
                    .foregroundStyle(Color.teal.gradient)
                Text("**Raw Gyroscope:** \(sensorsManager.gyroData)")
                    .foregroundStyle(Color.orange.gradient)
                    .padding(.vertical)
            }
            Divider()
                .padding(.vertical)
            HStack {
                Button("Start") {
                    isRecievingData.toggle()
                    sensorsManager.start()
                }
                .padding()
                .disabled(isRecievingData)
                .tint(.green)
                Button("Stop") {
                    isRecievingData.toggle()
                    sensorsManager.stop()
                }
                .padding()
                .disabled(!isRecievingData)
                .tint(.red)
            }
        }
    }
    
    
}

#Preview {
    MessingWithCoreMotion()
}
