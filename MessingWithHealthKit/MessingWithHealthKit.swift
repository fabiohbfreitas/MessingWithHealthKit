//
//  MessingWithHealthKit.swift
//  MessingWithHealthKit
//
//  Created by Fabio Freitas on 14/05/24.
//

import SwiftUI
import HealthKit

struct Step: Identifiable {
    let id = UUID()
    let count: Int
    let date: Date
}
extension Step: Comparable {
    static func < (lhs: Step, rhs: Step) -> Bool {
        lhs.date > rhs.date
    }
}

struct Calories: Identifiable {
    let id = UUID()
    let calories: Int
    let date: Date
}
extension Calories: Comparable {
    static func < (lhs: Calories, rhs: Calories) -> Bool {
        lhs.date > rhs.date
    }
}

@Observable
final class HealthStore {
    var healthStore: HKHealthStore?
    var timeStanding: String = ""
    
    var steps: [Step] = []
    @ObservationIgnored
    var stepsOrdered: [Step] {
        steps.sorted()
    }
    
    var calories: [Calories] = []
    @ObservationIgnored
    var caloriesOrdered: [Calories] {
        calories.sorted()
    }
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func calculateCalories() async throws {
        guard let healthStore = self.healthStore else { return }
        
        let type = HKQuantityType(.activeEnergyBurned)
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())
        let endDate = Date()
        
        let queryPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let calories = HKSamplePredicate.quantitySample(type: type, predicate: queryPredicate)
        
        let query = HKStatisticsCollectionQueryDescriptor(predicate: calories, options: .cumulativeSum, anchorDate: endDate, intervalComponents: DateComponents(day: 1))
        let dailyCalories = try await query.result(for: healthStore)
        
        self.calories = []
        dailyCalories.enumerateStatistics(from: startDate!, to: endDate) { stats, _ in
            let count = stats.sumQuantity()?.doubleValue(for: .kilocalorie())
            if let count, count > 0 {
                let calories = Calories(calories: Int(count), date: stats.startDate)
                self.calories.append(calories)
            }
        }
    }
    
    func fetchTimeStanding() async throws {
        guard let healthStore = self.healthStore else { return }
        
        let type = HKQuantityType(.appleStandTime)
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)


        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
         
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            fatalError("*** Unable to create the end date ***")
        }


        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let samplePred = HKSamplePredicate.quantitySample(type: type, predicate: today)
        
        let q = HKStatisticsQueryDescriptor(predicate: samplePred, options: .cumulativeSum)
        
        let res = try await q.result(for: healthStore)
        print(res?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 69)

    }
    
    func calculateSteps() async throws {
        guard let healthStore = self.healthStore else { return }
        
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())
        let endDate = Date()
        
        let stepType = HKQuantityType(.stepCount)
        let everyDay = DateComponents(day:1)
        let thisWeek = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let stepsThisWeek = HKSamplePredicate.quantitySample(type: stepType, predicate:thisWeek)
        
        let sumOfStepsQuery = HKStatisticsCollectionQueryDescriptor(predicate: stepsThisWeek, options: .cumulativeSum, anchorDate: endDate, intervalComponents: everyDay)
        
        let stepsCount = try await sumOfStepsQuery.result(for: healthStore)
        
        guard let startDate = startDate else { return }
        
        self.calories = []
        stepsCount.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = Step(count: Int(count ?? 0), date: statistics.startDate)
            if step.count > 0 {
                self.steps.append(step)
            }
        }
        
    }
    
    func fetchActivitySummary() async throws {
        guard let healthStore else { return }
        
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())
        let endDate = Date()
        
        var startComponents = calendar.dateComponents([.day,.month,.year,.calendar], from: startDate!)
        var endComponents = calendar.dateComponents([.day,.month,.year, .calendar], from: endDate)

        let today = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents, end: endComponents)

        let activeSummaryDescriptor = HKActivitySummaryQueryDescriptor(predicate:today)

        let results = try await activeSummaryDescriptor.result(for: healthStore)
        for result in results {
            dump(result)
        }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else { return }
        let caloriesType  = HKQuantityType(HKQuantityTypeIdentifier.activeEnergyBurned)
        guard let timeStanding = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else { return }
        
        guard let healthStore = self.healthStore else { return }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType, caloriesType, timeStanding, HKQuantityType.activitySummaryType()])
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
}

struct HealthKitDemo: View {
    @State var healthStore = HealthStore()
    
    var body: some View {
        VStack {
            Button("Get steps") {
                Task {
                    do {
                        try await healthStore.calculateSteps()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            .task {
                do {
                    try await healthStore.fetchTimeStanding()
                } catch {
                    print(error.localizedDescription)
                }
            }
            Divider()
            List {
                ForEach(healthStore.stepsOrdered) { step in
                    HStack {
                        Text(step.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("\(step.count) Steps")
                    }
                }
            }
            .padding(.bottom)
            Button("Get calories") {
                Task {
                    do {
                        try await healthStore.calculateCalories()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            Divider()
            List {
                ForEach(healthStore.caloriesOrdered) { cal in
                    HStack {
                        Text(cal.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("\(cal.calories) kcal")
                    }
                }
            }
        }
        .padding(.vertical)
        .task {
            await healthStore.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
