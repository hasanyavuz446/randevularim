import Foundation
import EventKit
import UIKit

@Observable final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let store = EKEventStore()
    private let defaults = UserDefaults.standard

    private static let enabledKey    = "calendarSync.enabled"
    private static let calendarIdKey = "calendarSync.calendarIdentifier"
    private static let mapKey        = "calendarSync.appointmentEventMap"

    var isEnabled: Bool = false

    private var calendarIdentifier: String? {
        get { defaults.string(forKey: Self.calendarIdKey) }
        set { defaults.set(newValue, forKey: Self.calendarIdKey) }
    }

    private var eventMap: [String: String] {
        get { defaults.dictionary(forKey: Self.mapKey) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Self.mapKey) }
    }

    private init() {
        isEnabled = defaults.bool(forKey: Self.enabledKey)
    }

    // MARK: - Public API

    func syncAll(appointments: [Appointment]) async -> Bool {
        guard await requestAccess() else { return false }
        guard let calendar = getOrCreateCalendar() else { return false }

        // Tüm mevcut eventları temizle
        var map = eventMap
        for ekId in map.values {
            if let event = store.event(withIdentifier: ekId) {
                try? store.remove(event, span: .thisEvent, commit: false)
            }
        }
        map.removeAll()

        // Tüm randevuları ekle
        for appointment in appointments {
            let event = makeEvent(for: appointment, in: calendar)
            try? store.save(event, span: .thisEvent, commit: false)
            map[appointment.id] = event.eventIdentifier
        }

        try? store.commit()
        eventMap = map
        isEnabled = true
        defaults.set(true, forKey: Self.enabledKey)
        return true
    }

    func add(_ appointment: Appointment) {
        guard isEnabled, let calendar = getOrCreateCalendar() else { return }
        var map = eventMap
        // Varsa eskiyi sil
        if let ekId = map[appointment.id], let event = store.event(withIdentifier: ekId) {
            try? store.remove(event, span: .thisEvent)
        }
        let event = makeEvent(for: appointment, in: calendar)
        try? store.save(event, span: .thisEvent)
        map[appointment.id] = event.eventIdentifier
        eventMap = map
    }

    func update(_ appointment: Appointment) {
        add(appointment)
    }

    func remove(_ appointment: Appointment) {
        guard isEnabled else { return }
        var map = eventMap
        if let ekId = map[appointment.id] {
            if let event = store.event(withIdentifier: ekId) {
                try? store.remove(event, span: .thisEvent)
            }
            map.removeValue(forKey: appointment.id)
        }
        eventMap = map
    }

    func removeAll() {
        for ekId in eventMap.values {
            if let event = store.event(withIdentifier: ekId) {
                try? store.remove(event, span: .thisEvent, commit: false)
            }
        }
        try? store.commit()

        if let id = calendarIdentifier, let cal = store.calendar(withIdentifier: id) {
            try? store.removeCalendar(cal, commit: true)
        }

        eventMap = [:]
        calendarIdentifier = nil
        isEnabled = false
        defaults.set(false, forKey: Self.enabledKey)
    }

    // MARK: - Private

    private func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
            }
        }
    }

    private func getOrCreateCalendar() -> EKCalendar? {
        if let id = calendarIdentifier, let cal = store.calendar(withIdentifier: id) {
            return cal
        }
        guard let source = store.defaultCalendarForNewEvents?.source
                        ?? store.sources.first(where: { $0.sourceType == .local || $0.sourceType == .calDAV })
        else { return nil }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = "Randevularım"
        cal.cgColor = UIColor.systemPurple.cgColor
        cal.source = source
        guard (try? store.saveCalendar(cal, commit: true)) != nil else { return nil }
        calendarIdentifier = cal.calendarIdentifier
        return cal
    }

    private func makeEvent(for appointment: Appointment, in calendar: EKCalendar) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = "\(appointment.customerName) – \(appointment.serviceName)"
        event.startDate = appointment.dateTime
        event.endDate = appointment.endTime
        event.calendar = calendar
        if !appointment.notes.isEmpty { event.notes = appointment.notes }
        return event
    }
}
