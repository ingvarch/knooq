import Foundation

/// Groups items into date buckets: Today, Yesterday, months of the current year (June, May…),
/// and previous years lumped per year (2025, 2024). Section order follows `ascending`.
@MainActor
public enum DateGrouping {
    public static func group(
        _ items: [SavedItem],
        dateFor: (SavedItem) -> Date,
        now: Date,
        ascending: Bool
    ) -> [(title: String, items: [SavedItem])] {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let nowYear = calendar.component(.year, from: now)

        var buckets: [Date: (title: String, items: [SavedItem])] = [:]
        for item in items {
            let date = dateFor(item)
            let key: Date
            let title: String
            if calendar.isDate(date, inSameDayAs: now) {
                key = calendar.startOfDay(for: now); title = "Today"
            } else if calendar.isDate(date, inSameDayAs: yesterday) {
                key = calendar.startOfDay(for: yesterday); title = "Yesterday"
            } else if calendar.component(.year, from: date) == nowYear {
                key = calendar.dateInterval(of: .month, for: date)?.start ?? date
                title = date.formatted(.dateTime.month(.wide))
            } else {
                key = calendar.dateInterval(of: .year, for: date)?.start ?? date
                title = String(calendar.component(.year, from: date))
            }
            buckets[key, default: (title, [])].items.append(item)
        }

        return buckets.keys.sorted(by: ascending ? (<) : (>)).map { key in
            let bucket = buckets[key]!
            let sorted = bucket.items.sorted { ascending ? dateFor($0) < dateFor($1) : dateFor($0) > dateFor($1) }
            return (bucket.title, sorted)
        }
    }
}
