//
//  ClientListView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]

    @State private var searchText = ""
    @State private var isPresentingCreateForm = false
    @State private var editClient: Client?
    @State private var deleteBlockedMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Group {
                if filteredClients.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredClients) { client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(client.name)
                                .font(AppTheme.sectionTitleFont)

                            if !client.contactPerson.isEmpty {
                                Text(client.contactPerson)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            HStack(spacing: 12) {
                                Text(client.email.isEmpty ? localization.phrase("No email") : client.email)
                                Text("\(client.paymentTermDays)d")
                            }
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.cardBackground)
                    .swipeActions {
                        Button(localization.phrase("Edit")) {
                            editClient = client
                        }
                        .tint(AppTheme.accentColor)

                        Button(localization.phrase("Delete"), role: .destructive) {
                            delete(client)
                        }
                    }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.screenBackground)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Clients"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateForm) {
            NavigationStack {
                ClientFormView()
            }
        }
        .sheet(item: $editClient) { client in
            NavigationStack {
                ClientFormView(client: client)
            }
        }
        .alert(localization.phrase("Unable to Delete Client"), isPresented: deleteBlockedAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(deleteBlockedMessage ?? "")
        }
        .toolbarBackground(AppTheme.screenBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField(localization.phrase("Search clients"), text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.secondaryText)

            Text(
                clients.isEmpty
                    ? localization.phrase("No clients yet")
                    : localization.phrase("No clients match your search")
            )
            .font(AppTheme.sectionTitleFont)
            .foregroundStyle(AppTheme.primaryText)

            Text(
                clients.isEmpty
                    ? localization.phrase("Add your first client to start invoicing and tracking work.")
                    : localization.phrase("Try another search term or clear the filter.")
            )
            .font(AppTheme.bodyFont)
            .foregroundStyle(AppTheme.secondaryText)

            if clients.isEmpty {
                Button(localization.phrase("Add Client")) {
                    isPresentingCreateForm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }

    private var filteredClients: [Client] {
        guard !searchText.isEmpty else { return clients }

        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.contactPerson.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var deleteBlockedAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteBlockedMessage != nil },
            set: { if !$0 { deleteBlockedMessage = nil } }
        )
    }

    private func delete(_ client: Client) {
        guard client.workEntries.isEmpty, client.invoices.isEmpty, client.quotes.isEmpty else {
            deleteBlockedMessage = localization.phrase("This client has linked work entries, invoices, or quotes and cannot be deleted.")
            return
        }

        modelContext.delete(client)
        try? modelContext.save()
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        ClientListView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
