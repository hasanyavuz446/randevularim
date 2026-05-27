import SwiftUI

struct AppointmentListView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        RandevularimScreen(title: "Randevular") {
            List {
                ForEach(store.appointments.sorted { $0.dateTime < $1.dateTime }) { appointment in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(appointment.customerName)
                                .font(.headline)
                            Spacer()
                            Text(appointment.status.label)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.secondarySurface, in: Capsule())
                        }

                        Text(appointment.serviceName)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text(appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
    }
}
