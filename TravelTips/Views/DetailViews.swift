import SwiftUI
import SwiftData
import PhotosUI
import QuickLook
import UIKit
import UniformTypeIdentifiers

// MARK: - File Utilities

private func documentsDir() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

private func attachmentsDir() -> URL {
    let dir = documentsDir().appendingPathComponent("attachments", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

func localURL(for path: String) -> URL {
    documentsDir().appendingPathComponent(path)
}

private func fileSizeString(bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

enum AttachmentError: LocalizedError {
    case copyFailed(name: String, underlying: Error)
    case writeFailed(underlying: Error)
    case photoLoadFailed
    case fileMissing(name: String)
    case cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .copyFailed(let name, let err): return String(localized: "Couldn't import \"\(name)\".") + " " + err.localizedDescription
        case .writeFailed(let err):          return String(localized: "Couldn't save the photo.") + " " + err.localizedDescription
        case .photoLoadFailed:               return String(localized: "Couldn't load the selected photo. If it is stored in iCloud, try again once it has downloaded.")
        case .fileMissing(let name):         return String(localized: "\"\(name)\" is no longer on this device. Delete it and attach the file again.")
        case .cameraUnavailable:             return String(localized: "The camera isn't available on this device.")
        }
    }
}

private func saveFileAttachment(from url: URL, linkedItemId: UUID, context: ModelContext) throws {
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }

    let ext = url.pathExtension.lowercased()
    let fileName = UUID().uuidString + (ext.isEmpty ? "" : "." + ext)
    let destURL = attachmentsDir().appendingPathComponent(fileName)

    do {
        try FileManager.default.copyItem(at: url, to: destURL)
    } catch {
        throw AttachmentError.copyFailed(name: url.lastPathComponent, underlying: error)
    }

    let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    let fileType = ext == "pdf" ? "pdf" : "image"
    let att = Attachment(
        name: url.lastPathComponent,
        fileType: fileType,
        fileSize: fileSizeString(bytes: bytes),
        localPath: "attachments/\(fileName)",
        linkedItemId: linkedItemId
    )
    context.insert(att)
}

private func saveImageAttachment(data: Data, name: String, linkedItemId: UUID, context: ModelContext) throws {
    let fileName = UUID().uuidString + ".jpg"
    let destURL = attachmentsDir().appendingPathComponent(fileName)
    do {
        try data.write(to: destURL)
    } catch {
        throw AttachmentError.writeFailed(underlying: error)
    }

    let att = Attachment(
        name: name,
        fileType: "image",
        fileSize: fileSizeString(bytes: data.count),
        localPath: "attachments/\(fileName)",
        linkedItemId: linkedItemId
    )
    context.insert(att)
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .data])
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPick(url) }
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        init(onCapture: @escaping (Data) -> Void) { self.onCapture = onCapture }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let img = info[.originalImage] as? UIImage,
               let data = img.jpegData(compressionQuality: 0.8) {
                onCapture(data)
            }
        }
    }
}

// MARK: - Attachment Section

struct AttachmentSectionView: View {
    let linkedItemId: UUID

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Attachment.createdAt) private var allAttachments: [Attachment]

    @State private var showAddMenu = false
    @State private var showDocPicker = false
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var previewURL: URL? = nil
    @State private var errorMessage: String? = nil

    private var attachments: [Attachment] {
        allAttachments.filter { $0.linkedItemId == linkedItemId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Attachments")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .kerning(1)
                Spacer()
                Button { showAddMenu.toggle() } label: {
                    Text("+ Add File")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.primary)
                }
            }

            // Inline add menu
            if showAddMenu {
                VStack(spacing: 0) {
                    let menu: [(icon: String, label: LocalizedStringKey)] = [
                        ("folder", "Choose from Files"),
                        ("photo.on.rectangle", "Choose from Photos"),
                        ("camera", "Take Photo"),
                    ]
                    ForEach(menu, id: \.icon) { icon, label in
                        if icon == "photo.on.rectangle" {
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                menuRow(icon: icon, label: label)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                showAddMenu = false
                                if icon == "folder" { showDocPicker = true }
                                else if UIImagePickerController.isSourceTypeAvailable(.camera) { showCamera = true }
                                else { report(AttachmentError.cameraUnavailable) }
                            } label: {
                                menuRow(icon: icon, label: label)
                            }
                            .buttonStyle(.plain)
                        }
                        Divider()
                    }
                    Button { showAddMenu = false } label: {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textSec)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .background(Theme.card)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 2)
                .padding(.bottom, 4)
            }

            if attachments.isEmpty && !showAddMenu {
                Text("No attachments yet. Tap \"+ Add File\" to attach PDFs or photos.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textTer)
                    .padding(.vertical, 8)
            }

            ForEach(attachments) { att in
                AttachmentRow(
                    att: att,
                    onTap: {
                        let url = localURL(for: att.localPath)
                        if FileManager.default.fileExists(atPath: url.path) {
                            previewURL = url
                        } else {
                            report(AttachmentError.fileMissing(name: att.name))
                        }
                    },
                    onDelete: {
                        AttachmentStore.deleteFile(for: att)
                        modelContext.delete(att)
                    }
                )
            }
        }
        .padding(.top, 8)
        .sheet(isPresented: $showDocPicker) {
            DocumentPickerView { url in
                do { try saveFileAttachment(from: url, linkedItemId: linkedItemId, context: modelContext) }
                catch { report(error) }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { data in
                let name = "Photo_\(UUID().uuidString.prefix(8)).jpg"
                do { try saveImageAttachment(data: data, name: name, linkedItemId: linkedItemId, context: modelContext) }
                catch { report(error) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, item in
            showAddMenu = false
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw AttachmentError.photoLoadFailed
                    }
                    let name = "Photo_\(UUID().uuidString.prefix(8)).jpg"
                    try saveImageAttachment(data: data, name: name, linkedItemId: linkedItemId, context: modelContext)
                } catch let error as AttachmentError {
                    report(error)
                } catch {
                    report(AttachmentError.photoLoadFailed)
                }
                photoPickerItem = nil
            }
        }
        .quickLookPreview($previewURL)
        .alert(
            "Attachment",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func report(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        // Errors often arrive while the file picker / camera is still dismissing;
        // an alert presented mid-dismissal is silently dropped, so wait it out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { errorMessage = message }
    }

    private func menuRow(icon: String, label: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.primary)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct AttachmentRow: View {
    let att: Attachment
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(att.fileType == "pdf"
                                  ? Color.red.opacity(0.1)
                                  : Theme.transport.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Text(att.fileType == "pdf" ? "📄" : "🖼️")
                            .font(.system(size: 16))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(att.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Text("\(att.fileType.uppercased()) · \(att.fileSize)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSec)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTer)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(.systemGray6))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 10, bottomLeadingRadius: 10,
                    bottomTrailingRadius: 0, topTrailingRadius: 0
                ))
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .frame(width: 44, height: 56)
                    .background(Color.red.opacity(0.08))
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 10, topTrailingRadius: 10
                    ))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Transport Detail

struct TransportDetailView: View {
    let transport: TransportInfo
    let day: TripDay

    @Environment(\.dismiss) private var dismiss

    private let rows: [(String, String)]

    init(transport: TransportInfo, day: TripDay) {
        self.transport = transport
        self.day = day
        rows = [
            (String(localized: "Reference"), transport.detail.isEmpty ? "—" : transport.detail),
            (String(localized: "Type"), transport.type.displayName),
            (String(localized: "Departure"), "\(transport.departureTime.isEmpty ? "—" : transport.departureTime) · \(transport.from)"),
            (String(localized: "Arrival"), "\(transport.arrivalTime.isEmpty ? "—" : transport.arrivalTime) · \(transport.to)"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Type pill + date
                    HStack(spacing: 8) {
                        PillView(
                            text: "\(transport.type.emoji) \(transport.type.displayName.uppercased())",
                            bg: Theme.transport.opacity(0.15),
                            fg: Theme.transport
                        )
                        Text(fmtDate(day.date))
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSec)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Route card
                    CardView {
                        HStack(spacing: 8) {
                            VStack(spacing: 3) {
                                Text(transport.departureTime.isEmpty ? "—" : transport.departureTime)
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                Text(transport.from)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSec)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 6) {
                                ZStack {
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundStyle(LinearGradient(
                                            colors: [Theme.transport.opacity(0.3), Theme.transport],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                    Text(transport.type.emoji)
                                        .font(.system(size: 18))
                                        .background(Theme.card)
                                        .padding(.horizontal, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 3) {
                                Text(transport.arrivalTime.isEmpty ? "—" : transport.arrivalTime)
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                Text(transport.to)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSec)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 4)
                    }

                    // Detail rows
                    CardView {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { i, pair in
                                HStack {
                                    Text(pair.0)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textSec)
                                    Spacer()
                                    Text(pair.1)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding(.vertical, 10)
                                if i < rows.count - 1 { Divider() }
                            }
                        }
                    }

                    // Attachments
                    AttachmentSectionView(linkedItemId: transport.id)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .background(Theme.bg)
            .navigationTitle("Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
    }
}

// MARK: - Hotel Detail

struct HotelDetailView: View {
    let trip: Trip
    let linkedId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var stay: HotelStay? {
        var result: [HotelStay] = []
        var current: HotelStay? = nil
        var currentLinkedId: UUID? = nil
        for day in trip.sortedDays {
            guard let acc = day.accommodation else { current = nil; currentLinkedId = nil; continue }
            if let c = current, c.name == acc.name {
                let updated = HotelStay(linkedId: currentLinkedId, name: c.name, address: c.address,
                                        startDate: c.startDate, endDate: day.date, nights: c.nights + 1)
                result[result.count - 1] = updated
                current = updated
            } else {
                currentLinkedId = acc.id
                let s = HotelStay(linkedId: acc.id, name: acc.name, address: acc.address,
                                   startDate: day.date, endDate: day.date, nights: 1)
                current = s
                result.append(s)
            }
        }
        return result.first { $0.linkedId == linkedId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let stay {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(alignment: .top) {
                            HStack(spacing: 6) {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Theme.hotel)
                                Text(stay.name)
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            Spacer()
                            PillView(
                                text: String(localized: "\(stay.nights) nights"),
                                bg: Theme.hotel.opacity(0.13),
                                fg: Theme.hotel
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        // Detail rows
                        let rows: [(String, String)] = [
                            (String(localized: "Address"), stay.address),
                            (String(localized: "Check-in"), fmtDate(stay.startDate)),
                            (String(localized: "Check-out"), fmtDate(stay.endDate)),
                            (String(localized: "Nights"), String(localized: "\(stay.nights) nights")),
                        ]
                        CardView {
                            VStack(spacing: 0) {
                                ForEach(Array(rows.enumerated()), id: \.offset) { i, pair in
                                    HStack {
                                        Text(pair.0)
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textSec)
                                        Spacer()
                                        Text(pair.1)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.textPrimary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    .padding(.vertical, 10)
                                    if i < rows.count - 1 { Divider() }
                                }
                            }
                        }

                        // Copy Address + Open Maps
                        HStack(spacing: 8) {
                            Button {
                                UIPasteboard.general.string = stay.address
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            } label: {
                                Label(copied ? LocalizedStringKey("Copied!") : LocalizedStringKey("Copy Address"),
                                      systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(copied ? Theme.hotel : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button {
                                let encoded = stay.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                if let url = URL(string: "maps://?address=\(encoded)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open Maps", systemImage: "map")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                        // Attachments
                        AttachmentSectionView(linkedItemId: linkedId)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                } else {
                    Text("Hotel not found")
                        .foregroundColor(Theme.textSec)
                        .padding()
                }
            }
            .background(Theme.bg)
            .navigationTitle("Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
    }
}

// MARK: - Place Detail

struct PlaceDetailView: View {
    let dest: Destination
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var dayInfo: (Int, TripDay)? {
        for (i, day) in trip.sortedDays.enumerated() {
            if day.destinations.contains(where: { $0.id == dest.id }) { return (i, day) }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        Text(dest.type.emoji)
                            .font(.system(size: 20))
                        Text(dest.name)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    HStack(spacing: 6) {
                        if let price = dest.ticketPrice {
                            PillView(text: price, bg: Theme.attraction.opacity(0.15), fg: Theme.attraction)
                        }
                        if let (dayIdx, day) = dayInfo {
                            PillView(
                                text: String(localized: "Day \(dayIdx + 1), \(fmtDateShort(day.date))"),
                                bg: Color(.systemGray5), fg: Theme.textSec
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Detail rows
                    let rows: [(String, String)] = [
                        (String(localized: "Address"), dest.address),
                        (String(localized: "Time"), dest.time.map { $0 == TimeRangeField.allDay ? String(localized: "All Day") : $0 } ?? "—"),
                        (String(localized: "Ticket"), dest.ticketPrice ?? String(localized: "Free")),
                        (String(localized: "Type"), dest.type.displayName),
                    ]
                    CardView {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { i, pair in
                                HStack {
                                    Text(pair.0)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textSec)
                                    Spacer()
                                    Text(pair.1)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding(.vertical, 10)
                                if i < rows.count - 1 { Divider() }
                            }
                        }
                    }

                    // Notes
                    if let notes = dest.notes, !notes.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                    .kerning(1)
                                Text("💡 \(notes)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Copy + Maps
                    HStack(spacing: 8) {
                        Button {
                            UIPasteboard.general.string = dest.address
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        } label: {
                            Label(copied ? LocalizedStringKey("Copied!") : LocalizedStringKey("Copy Address"),
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(copied ? dest.type.color : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button {
                            let encoded = dest.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "maps://?address=\(encoded)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open Maps", systemImage: "map")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    // Attachments
                    AttachmentSectionView(linkedItemId: dest.id)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .background(Theme.bg)
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
    }
}

// MARK: - Info Detail

struct InfoDetailView: View {
    let item: InfoItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    CardView {
                        Text(item.details)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AttachmentSectionView(linkedItemId: item.id)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .background(Theme.bg)
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.primary)
                }
            }
        }
    }
}
