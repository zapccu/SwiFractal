//
//  Toast.swift
//  SwiFractal
//
//  Created by Dirk Braner on 12.10.26.
//
// Example
//

import Foundation
import SwiftUI


/// Toast message control instance. Callable from anywhere in main thread:
///
/// `ToastCenter.shared.show("Image saved")`
///
/// **Example**
/// ```
/// @main
/// struct MyApp: App {
///    var body: some Scene {
///        WindowGroup {
///            ContentView()
///                .toastHost()
///        }
///    }
/// }
///```
/// **Simple toast message**
///```
/// Button("Save") {
///    ToastCenter.shared.show("Image saved", systemImage: "checkmark.circle.fill")
/// }
///```
/// **With button and closure**
///```
/// ToastCenter.shared.show("Preset gelöscht",
///                        duration: .seconds(5),
///                        actionTitle: "Rückgängig") {
///    undoDelete()
/// }
/// ```
/// **With button and async/await**
/// ```
/// Task {
///    let undo = await ToastCenter.shared.showAndWait("Preset gelöscht",
///                                                    actionTitle: "Rückgängig")
///    if undo { undoDelete() }
/// }
/// ```
@MainActor @Observable
final class ToastCenter {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let systemImage: String?
        let actionTitle: String?
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?
    
    /// Completion action. true = pressed, false = Timeout/ersetzt/geschlossen
    private var completion: ((Bool) -> Void)?

    /// Show toast message and optionally a button.
    /// `onAction` will be executed if the button is pressed wihin duration.
    /// - Parameters:
    ///   - message: The toast message
    ///   - systemImage: System image. Default = nil (no image)
    ///   - duration: Duration of toast. Default = 2.5 seconds
    ///   - actionTitle: Title of action button. Default = nil (no button)
    ///   - onAction: Closure to be executed when button is pressed
    func show(_ message: String, systemImage: String? = nil, duration: Duration = .seconds(2.5),
              actionTitle: String? = nil, onAction: (() -> Void)? = nil)
    {
        present(message, systemImage: systemImage, duration: duration, actionTitle: actionTitle) { pressed in
            if pressed { onAction?() }
        }
    }

    // MARK: Variante 2: async/await

    /// Zeigt einen Toast mit Button und wartet auf das Ergebnis.
    /// Rückgabe: true, wenn der Button gedrückt wurde; false bei Timeout,
    /// Schließen oder wenn ein neuer Toast den Toast ersetzt hat.
    @discardableResult
    func showAndWait(_ message: String,
                     systemImage: String? = nil,
                     duration: Duration = .seconds(4),
                     actionTitle: String) async -> Bool {
        await withCheckedContinuation { continuation in
            present(message, systemImage: systemImage, duration: duration,
                    actionTitle: actionTitle) { pressed in
                continuation.resume(returning: pressed)
            }
        }
    }

    // MARK: Intern

    private func present(_ message: String,
                         systemImage: String?,
                         duration: Duration,
                         actionTitle: String?,
                         completion: @escaping (Bool) -> Void) {
        // Vorherigen Toast abschließen (Ergebnis: nicht gedrückt)
        resolve(pressed: false)

        let toast = Toast(message: message, systemImage: systemImage, actionTitle: actionTitle)
        self.completion = completion
        withAnimation(.spring(duration: 0.35)) {
            current = toast
        }

        // Für VoiceOver ankündigen
        AccessibilityNotification.Announcement(message).post()

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismiss(toast.id)
        }
    }

    /// Ruft die Completion genau einmal auf und stoppt den Timer.
    private func resolve(pressed: Bool) {
        dismissTask?.cancel()
        dismissTask = nil
        let c = completion
        completion = nil
        c?(pressed)
    }

    fileprivate func actionPressed(_ id: UUID) {
        guard current?.id == id else { return }
        resolve(pressed: true)
        hide()
    }

    func dismiss(_ id: UUID? = nil) {
        if let id, current?.id != id { return }
        resolve(pressed: false)
        hide()
    }

    private func hide() {
        withAnimation(.easeOut(duration: 0.25)) {
            current = nil
        }
    }
}

// MARK: - Darstellung

private struct ToastView: View {
    let toast: ToastCenter.Toast
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let name = toast.systemImage {
                Image(systemName: name)
            }
            Text(toast.message)
                .multilineTextAlignment(.center)

            if let title = toast.actionTitle {
                Button(action: onAction) {
                    Text(title)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        // Deutlich größer als die Standard-UI-Schrift (~13–17 pt)
        .font(.system(size: 24, weight: .semibold, design: .rounded))
        .foregroundStyle(.primary)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.12))
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        .frame(maxWidth: 600)
        .padding(.horizontal, 20)
    }
}

// MARK: - ViewModifier

private struct ToastHost: ViewModifier {
    @State private var center = ToastCenter.shared

    func body(content: Content) -> some View {
        content.overlay(alignment: .center) {
            if let toast = center.current {
                ToastView(toast: toast) {
                    center.actionPressed(toast.id)
                }
                .id(toast.id)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                // Nur Toasts mit Button fangen Klicks ab, reine Meldungen nicht
                .allowsHitTesting(toast.actionTitle != nil)
            }
        }
    }
}

extension View {
    /// Einmal an der Wurzel-View des Fensters anhängen.
    func toastHost() -> some View {
        modifier(ToastHost())
    }
}
