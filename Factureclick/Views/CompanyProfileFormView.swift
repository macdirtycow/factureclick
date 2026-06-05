//
//  CompanyProfileFormView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import PhotosUI
import SwiftData
import SwiftUI

struct CompanyProfileFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]
    @Query private var appSettings: [AppSettings]

    private let profileID: UUID?
    private let accentOptions = ["#1F6FE5", "#0F766E", "#B45309", "#BE123C", "#374151"]
    private let selectionService = CompanyProfileSelectionService()

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var viewModel: CompanyProfileViewModel
    @State private var shouldSetActiveOnSave: Bool
    @State private var saveMessage: String?

    init(profileID: UUID? = nil, shouldSetActiveOnSave: Bool = false) {
        self.profileID = profileID
        _viewModel = State(initialValue: CompanyProfileViewModel())
        _shouldSetActiveOnSave = State(initialValue: shouldSetActiveOnSave)
    }

    var body: some View {
        Form {
            Section(localization.phrase("Identity")) {
                HStack(spacing: 16) {
                    logoPreview

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text(viewModel.logoData == nil ? localization.phrase("Choose Logo") : localization.phrase("Replace Logo"))
                    }
                    .buttonStyle(.bordered)

                    if viewModel.logoData != nil {
                        Button(localization.phrase("Remove")) {
                            viewModel.logoData = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }

                TextField(localization.phrase("Company name"), text: nameBinding)
                TextField(localization.phrase("Owner name"), text: ownerNameBinding)
                TextField(localization.phrase("Address"), text: addressBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section(localization.phrase("Contact and tax")) {
                TextField(localization.text(.email), text: emailBinding)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField(localization.phrase("Phone"), text: phoneBinding)
                TextField(localization.phrase("VAT number"), text: vatBinding)
                TextField(localization.phrase("KVK number"), text: kvkBinding)
                TextField("IBAN", text: ibanBinding)
            }

            Section(localization.phrase("Invoice defaults")) {
                TextField(localization.phrase("Invoice text"), text: invoiceTextBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField(localization.phrase("Payment text"), text: paymentTextBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                Toggle(localization.enableSEPAPaymentLabel(), isOn: sepaQRCodeBinding)
                Text(localization.sepaPaymentHelperText())
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)

                Toggle(localization.enablePayPalLabel(), isOn: payPalEnabledBinding)
                if viewModel.isPayPalPaymentEnabled {
                    Text(localization.payPalHelperText())
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                    TextField(localization.payPalURLLabel(), text: paypalURLBinding)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                HStack(spacing: 12) {
                    ForEach(accentOptions, id: \.self) { option in
                        Button {
                            viewModel.accentColor = option
                        } label: {
                            Circle()
                                .fill(AppTheme.color(hex: option))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if viewModel.accentColor == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(localization.phrase("Activation")) {
                Toggle(localization.phrase("Set as active company profile"), isOn: activeOnSaveBinding)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(profile == nil ? localization.phrase("New Profile") : localization.phrase("Edit Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: profileRefreshKey) {
            guard profileID == nil || profile != nil else { return }
            viewModel.load(profile: profile)
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self) {
                viewModel.logoData = data
            }
            self.selectedPhotoItem = nil
        }
        .alert(localization.phrase("Company Profile"), isPresented: saveAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    saveProfile()
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private var logoPreview: some View {
        Group {
            if let logoData = viewModel.logoData, let image = UIImage(data: logoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "building.2.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: 72, height: 72)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func saveProfile() {
        do {
            let savedProfile = try viewModel.save(existingProfile: profile, in: modelContext)
            if shouldSetActiveOnSave {
                try selectionService.setActiveProfile(savedProfile, settings: appSettings.first, in: modelContext)
            }
            dismiss()
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private var activeOnSaveBinding: Binding<Bool> { Binding(get: { shouldSetActiveOnSave }, set: { shouldSetActiveOnSave = $0 }) }
    private var nameBinding: Binding<String> { Binding(get: { viewModel.name }, set: { viewModel.name = $0 }) }
    private var ownerNameBinding: Binding<String> { Binding(get: { viewModel.ownerName }, set: { viewModel.ownerName = $0 }) }
    private var kvkBinding: Binding<String> { Binding(get: { viewModel.kvkNumber }, set: { viewModel.kvkNumber = $0 }) }
    private var vatBinding: Binding<String> { Binding(get: { viewModel.vatNumber }, set: { viewModel.vatNumber = $0 }) }
    private var ibanBinding: Binding<String> { Binding(get: { viewModel.iban }, set: { viewModel.iban = $0 }) }
    private var emailBinding: Binding<String> { Binding(get: { viewModel.email }, set: { viewModel.email = $0 }) }
    private var phoneBinding: Binding<String> { Binding(get: { viewModel.phone }, set: { viewModel.phone = $0 }) }
    private var addressBinding: Binding<String> { Binding(get: { viewModel.address }, set: { viewModel.address = $0 }) }
    private var invoiceTextBinding: Binding<String> { Binding(get: { viewModel.defaultInvoiceText }, set: { viewModel.defaultInvoiceText = $0 }) }
    private var paymentTextBinding: Binding<String> { Binding(get: { viewModel.defaultPaymentText }, set: { viewModel.defaultPaymentText = $0 }) }
    private var payPalEnabledBinding: Binding<Bool> { Binding(get: { viewModel.isPayPalPaymentEnabled }, set: { viewModel.isPayPalPaymentEnabled = $0 }) }
    private var paypalURLBinding: Binding<String> { Binding(get: { viewModel.paypalPaymentURL }, set: { viewModel.paypalPaymentURL = $0 }) }
    private var sepaQRCodeBinding: Binding<Bool> { Binding(get: { viewModel.showSEPAPaymentQRCode }, set: { viewModel.showSEPAPaymentQRCode = $0 }) }
    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var profileRefreshKey: String {
        guard let profileID else { return "new-profile" }
        guard let profile else { return "loading-\(profileID.uuidString)" }

        return [
            profileID.uuidString,
            profile.name,
            profile.ownerName,
            profile.kvkNumber,
            profile.vatNumber,
            profile.iban,
            profile.email,
            profile.phone,
            profile.address,
            profile.defaultInvoiceText,
            profile.defaultPaymentText,
            (profile.isPayPalPaymentEnabled ?? false) ? "paypal-on" : "paypal-off",
            profile.paypalPaymentURL ?? "",
            (profile.showSEPAPaymentQRCode ?? true) ? "sepa-qr-on" : "sepa-qr-off",
            profile.accentColor,
            profile.logoData?.base64EncodedString() ?? "no-logo"
        ].joined(separator: "|")
    }

    private var profile: CompanyProfile? {
        guard let profileID else { return nil }
        return companyProfiles.first(where: { $0.id == profileID })
    }
}
