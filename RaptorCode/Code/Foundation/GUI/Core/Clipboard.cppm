// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :clipboard partition
//
// IClipboard: the GUI core's abstract system-clipboard seam. Text widgets (TextField)
// cut/copy/paste through this interface, so the core stays platform-agnostic - exactly
// like the platform text-input (IME) seam. The concrete implementation lives in the
// gui.shell bridge (ShellClipboard, wrapping shell::IShell's clipboard); tests supply a
// trivial in-memory one. The dispatcher holds a non-owning pointer a widget reaches via
// GetEventDispatcher()->GetClipboard(), which may be null (then cut/copy/paste no-op).

module;
#include "Core/Prelude.h"

export module foundation.gui:clipboard;

import foundation.core; // String, StringView

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class IClipboard
    {
    public:
        virtual ~IClipboard() = default;

        // True if the clipboard currently holds text.
        [[nodiscard]] virtual bool HasText() const = 0;

        // The clipboard's text (empty string if none).
        [[nodiscard]] virtual core::String GetText() const = 0;

        // Replace the clipboard's text.
        virtual void SetText(core::StringView text) = 0;
    };
}
