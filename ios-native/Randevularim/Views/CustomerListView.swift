import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Query(sort: \Customer.name) private var customers: [Customer]

    var body: some View {
        RandevularimScreen(title: "Müşteriler") {
            List {
                ForEach(customers) { customer in
                    HStack(spacing: 12) {
                        Text(customer.initials)
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name)
                                .font(.headline)
                            Text(customer.phone)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
    }
}
