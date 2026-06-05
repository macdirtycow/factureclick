//
//  AgendaViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

struct AgendaDay: Identifiable, Hashable {
    let date: Date
    let isToday: Bool

    var id: Date { date }

    var dayLabel: String {
        AppFormatters.weekdayFormatter.string(from: date)
    }

    var dayNumber: String {
        AppFormatters.dayNumberFormatter.string(from: date)
    }
}

struct AgendaSection: Identifiable {
    let day: AgendaDay
    let entries: [WorkEntry]

    var id: Date { day.date }
}

struct AgendaViewModel {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func weekDays(containing referenceDate: Date) -> [AgendaDay] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return [makeAgendaDay(for: referenceDate)]
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else {
                return nil
            }
            return makeAgendaDay(for: date)
        }
    }

    func makeSections(for entries: [WorkEntry], in week: [AgendaDay]) -> [AgendaSection] {
        week.map { day in
            let dayEntries = entries
                .filter { calendar.isDate($0.date, inSameDayAs: day.date) }
                .sorted { $0.date > $1.date }
            return AgendaSection(day: day, entries: dayEntries)
        }
    }

    func entries(for date: Date, from entries: [WorkEntry]) -> [WorkEntry] {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    func title(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        return AppFormatters.fullDateFormatter.string(from: date)
    }

    func timeString(for date: Date) -> String {
        AppFormatters.shortTimeFormatter.string(from: date)
    }

    private func makeAgendaDay(for date: Date) -> AgendaDay {
        AgendaDay(
            date: calendar.startOfDay(for: date),
            isToday: calendar.isDateInToday(date)
        )
    }
}
