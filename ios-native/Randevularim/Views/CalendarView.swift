import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @State private var selectedDate = Date()

    private var selectedAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: selectedDate) }
    }

    var body: some View {
        RandevularimScreen(title: "Takvim") {
            VStack(spacing: 0) {
                DatePicker("Tarih", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(AppTheme.surface)

                List {
                    Section(selectedDate.formatted(date: .complete, time: .omitted)) {
                        if selectedAppointments.isEmpty {
                            Text("Bu tarihte randevu yok")
                                .foregroundStyle(AppTheme.textSecondary)
                        } else {
                            ForEach(selectedAppointments) { appointment in
                                AppointmentRow(appointment: appointment)
                                    .listRowBackground(AppTheme.surface)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
        }
    }
}
