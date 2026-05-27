import SwiftUI
import SwiftData

private enum CalendarMode: String, CaseIterable {
    case day = "Gün"
    case week = "Hafta"
    case month = "Ay"
}

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Query private var businesses: [Business]
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var mode: CalendarMode = .day
    @State private var isShowingForm = false

    private var openingHour: Int {
        Int(businesses.first?.openingTime.split(separator: ":").first ?? "8") ?? 8
    }
    private var closingHour: Int {
        (Int(businesses.first?.closingTime.split(separator: ":").first ?? "19") ?? 19) + 1
    }

    var body: some View {
        RandevularimScreen(title: "Takvim") {
            VStack(spacing: 0) {
                modeBar
                Divider().overlay(AppTheme.textSecondary.opacity(0.2))
                Group {
                    switch mode {
                    case .day:
                        DayTimelineView(
                            date: selectedDate,
                            appointments: appointmentsForDay(selectedDate),
                            openingHour: openingHour,
                            closingHour: closingHour
                        )
                    case .week:
                        WeekAgendaView(anchorDate: selectedDate, appointments: appointments)
                    case .month:
                        MonthCalendarView(selectedDate: $selectedDate, appointments: appointments) {
                            mode = .day
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isShowingForm) {
            AppointmentFormView(initialDate: selectedDate)
        }
    }

    private var modeBar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $mode) {
                ForEach(CalendarMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            Button("Bugün") {
                selectedDate = Calendar.current.startOfDay(for: .now)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
    }

    private func appointmentsForDay(_ date: Date) -> [Appointment] {
        appointments.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: date) }
            .sorted { $0.dateTime < $1.dateTime }
    }
}

// MARK: - Day Timeline

private struct DayTimelineView: View {
    let date: Date
    let appointments: [Appointment]
    let openingHour: Int
    let closingHour: Int

    static let hourHeight: CGFloat = 72
    static let leftWidth: CGFloat = 52

    private var hourCount: Int { max(1, closingHour - openingHour + 1) }
    private var totalHeight: CGFloat { CGFloat(hourCount) * Self.hourHeight + 32 }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                hourGridView
                if Calendar.current.isDateInToday(date) {
                    currentTimeLine
                }
                ForEach(appointments) { appt in
                    apptCard(appt)
                }
            }
            .frame(height: totalHeight)
            .padding(.horizontal, 12)
        }
        .background(AppTheme.background)
    }

    private var hourGridView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(openingHour...closingHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                        .frame(width: Self.leftWidth, alignment: .trailing)
                    Rectangle()
                        .fill(AppTheme.textSecondary.opacity(0.12))
                        .frame(height: 1)
                        .padding(.top, 9)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: Self.hourHeight, alignment: .top)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var currentTimeLine: some View {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: .now)
        let minute = cal.component(.minute, from: .now)
        if hour >= openingHour && hour <= closingHour {
            HStack(spacing: 4) {
                Text(Date.now.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 3))
                    .frame(width: Self.leftWidth, alignment: .trailing)
                Capsule()
                    .fill(Color.red)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, timeOffset(hour: hour, minute: minute) + 16 + 8)
        }
    }

    private func apptCard(_ appointment: Appointment) -> some View {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: appointment.dateTime)
        let minute = cal.component(.minute, from: appointment.dateTime)
        let top = timeOffset(hour: hour, minute: minute) + 16 + 8
        let cardHeight = max(36, CGFloat(appointment.durationMinutes) / 60 * Self.hourHeight - 4)
        let color = Color(hex: appointment.serviceColor)
        let isDim = appointment.status == .cancelled || appointment.status == .noShow

        return NavigationLink {
            AppointmentDetailView(appointment: appointment)
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isDim ? AppTheme.textSecondary : color)
                    .frame(width: 4)
                    .clipShape(
                        UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.customerName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isDim ? AppTheme.textSecondary : .primary)
                        .strikethrough(isDim)
                        .lineLimit(1)
                    if cardHeight > 50 {
                        Text(appointment.serviceName)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 8)
                .padding(.vertical, 5)
                Spacer(minLength: 4)
                Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isDim ? AppTheme.textSecondary : color)
                    .padding(.trailing, 8)
            }
            .frame(height: cardHeight)
            .background(isDim ? AppTheme.textSecondary.opacity(0.07) : color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isDim ? AppTheme.textSecondary.opacity(0.2) : color.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Self.leftWidth + 10)
        .padding(.top, top)
    }

    private func timeOffset(hour: Int, minute: Int) -> CGFloat {
        CGFloat((hour - openingHour) * 60 + minute) / 60 * Self.hourHeight
    }
}

// MARK: - Week Agenda

private struct WeekAgendaView: View {
    let anchorDate: Date
    let appointments: [Appointment]

    private var weekDays: [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: anchorDate)
        let mondayOffset = (weekday == 1 ? -6 : -(weekday - 2))
        guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: anchorDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    DayAgendaSection(day: day, appointments: appointmentsFor(day))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(AppTheme.background)
    }

    private func appointmentsFor(_ day: Date) -> [Appointment] {
        appointments
            .filter { Calendar.current.isDate($0.dateTime, inSameDayAs: day) && $0.status != .cancelled }
            .sorted { $0.dateTime < $1.dateTime }
    }
}

private struct DayAgendaSection: View {
    let day: Date
    let appointments: [Appointment]

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(day.formatted(.dateTime.day().month(.wide).weekday(.wide).locale(Locale(identifier: "tr_TR"))))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isToday ? AppTheme.primary : .primary)
                if isToday {
                    Text("BUGÜN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
            .padding(.top, 16)

            if appointments.isEmpty {
                Text("Randevu yok")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 8)
            } else {
                ForEach(appointments) { appt in
                    NavigationLink {
                        AppointmentDetailView(appointment: appt)
                    } label: {
                        AgendaCard(appointment: appt)
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider().overlay(AppTheme.textSecondary.opacity(0.15))
        }
    }
}

private struct AgendaCard: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 12) {
            Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.customerName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(appointment.serviceName)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Circle()
                .fill(Color(hex: appointment.serviceColor))
                .frame(width: 10, height: 10)
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 4)
    }
}

// MARK: - Month Calendar

private struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    let onDayTapped: () -> Void

    @State private var displayMonth: Date = Calendar.current.startOfDay(for: .now)

    private let cal = Calendar.current
    private let weekdayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var monthDays: [Date?] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth)),
              let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }

        var weekday = cal.component(.weekday, from: monthStart)
        weekday = weekday == 1 ? 7 : weekday - 1
        let leadingBlanks = weekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func appointmentCount(for date: Date) -> Int {
        appointments.filter { cal.isDate($0.dateTime, inSameDayAs: date) && $0.isActive }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            Divider().overlay(AppTheme.textSecondary.opacity(0.1))
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(monthDays.indices, id: \.self) { i in
                        if let day = monthDays[i] {
                            DayCell(
                                date: day,
                                isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                                isToday: cal.isDateInToday(day),
                                apptCount: appointmentCount(for: day)
                            ) {
                                selectedDate = day
                                onDayTapped()
                            }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
        .background(AppTheme.background)
        .onAppear {
            displayMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? displayMonth
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .foregroundStyle(AppTheme.primary)

            Spacer()

            Text(displayMonth.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "tr_TR"))))
                .font(.headline)

            Spacer()

            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(AppTheme.surface)
    }

    private func changeMonth(_ delta: Int) {
        if let newMonth = cal.date(byAdding: .month, value: delta, to: displayMonth) {
            displayMonth = newMonth
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let apptCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(labelColor)
                    .frame(width: 32, height: 32)
                    .background(backgroundView)

                if apptCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(apptCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? .white.opacity(0.8) : AppTheme.primary)
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Spacer().frame(height: 7)
                }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var labelColor: Color {
        if isSelected { return .white }
        if isToday { return AppTheme.primary }
        return .primary
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle().fill(AppTheme.primary)
        } else if isToday {
            Circle().strokeBorder(AppTheme.primary, lineWidth: 1.5)
        } else {
            Color.clear
        }
    }
}
