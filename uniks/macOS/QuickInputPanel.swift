//
//  QuickInputPanel.swift
//  uniks
//
//  macOS floating panel and global hotkey for the QuickInput HUD.
//

import SwiftUI
import AppKit
import Carbon

/// Manages the floating QuickInput panel and global keyboard shortcut on macOS.
@MainActor
final class QuickInputPanelManager: ObservableObject {
    private var panel: NSPanel?
    private let viewModel: QuickInputViewModel
    private var hotKeyID: EventHotKeyID?
    private var hotKeyRef: EventHotKeyRef?

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    func install() {
        createPanel()
        registerGlobalHotkey()
    }

    func show() {
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let contentView = QuickInputView(viewModel: viewModel)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Uniks"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.contentView = NSHostingView(rootView: contentView)
        panel.isReleasedWhenClosed = false
        self.panel = panel
    }

    private func registerGlobalHotkey() {
        // Default hotkey: Cmd+Shift+U
        let modifierFlags: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_U)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let hotKeyID = EventHotKeyID(signature: OSType("unks".fourCharCode), id: 1)
        self.hotKeyID = hotKeyID

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<QuickInputPanelManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in manager.show() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        guard self.utf8.count == 4 else { return 0 }
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
