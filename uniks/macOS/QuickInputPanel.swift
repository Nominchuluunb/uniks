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
///
/// - Important: The manager must remain alive while the hotkey is installed.
///   Call `uninstall()` before the manager is deallocated to unregister the
///   hotkey and release the reference retained by the Carbon event handler.
@MainActor
final class QuickInputPanelManager: ObservableObject {
    private var panel: NSPanel?
    private let viewModel: QuickInputViewModel
    private var hotKeyID: EventHotKeyID?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    deinit {
        uninstall()
    }

    /// Creates the panel and registers the global hotkey.
    func install() {
        createPanel()
        registerGlobalHotkey()
    }

    /// Brings the QuickInput panel to the front and activates the app.
    func show() {
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Dismisses the QuickInput panel without releasing it.
    func hide() {
        panel?.orderOut(nil)
    }

    /// Unregisters the global hotkey and removes the Carbon event handler.
    ///
    /// This must be called before the manager is deallocated to balance the
    /// retain passed to Carbon during `install()`.
    func uninstall() {
        if let hotKeyRef {
            let status = UnregisterEventHotKey(hotKeyRef)
            if status != noErr {
                print("QuickInputPanel: failed to unregister hotkey (status: \(status))")
            }
            self.hotKeyRef = nil
        }
        if let handlerRef {
            let status = RemoveEventHandler(handlerRef)
            if status == noErr {
                self.handlerRef = nil
                // Balance the retain passed to Carbon in `registerGlobalHotkey()`.
                Unmanaged.passUnretained(self).release()
            } else {
                print("QuickInputPanel: failed to remove event handler (status: \(status))")
            }
        }
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

        let userData = Unmanaged.passRetained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<QuickInputPanelManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in manager.show() }
                return noErr
            },
            1,
            &eventType,
            userData,
            &handlerRef
        )

        guard installStatus == noErr else {
            // The retained reference was not handed to Carbon; release it now.
            Unmanaged.passUnretained(self).release()
            // Diagnostic only; never log user data.
            print("QuickInputPanel: failed to install Carbon event handler (status: \(installStatus))")
            return
        }

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            // Roll back the partially-installed handler so the retained
            // reference is not leaked.
            if let handlerRef {
                let removeStatus = RemoveEventHandler(handlerRef)
                if removeStatus == noErr {
                    self.handlerRef = nil
                    Unmanaged.passUnretained(self).release()
                } else {
                    print("QuickInputPanel: failed to remove partial event handler (status: \(removeStatus))")
                }
            }
            // Diagnostic only; never log user data.
            print("QuickInputPanel: failed to register global hotkey (status: \(registerStatus))")
            return
        }
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
