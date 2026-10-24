// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :commands partition
//
// One command model (G7 of Specs/vg-and-gui-lab.md): a command has an id, a label, an icon, and
// enabled and checked states; buttons, menu items, shortcuts and gamepad buttons name it by id, so
// one disabled command greys every control bound to it. Its dispatch follows GPUI's
// (`zed/crates/gpui/src/key_dispatch.rs`): running a command walks the focus path, capture handlers
// from the root down, then bubble handlers from the focused widget up, a bubble handler stopping it
// unless it lets it go on; and a command is available (its controls lit) when it is enabled and a
// handler for it is on the focus path, so moving focus greys and lights the right controls with no
// bookkeeping. Availability is observable: a control's binding follows focus, the command's
// enabled state and the handlers.

module;
#include "Core/Prelude.h"

export module foundation.gui:commands;

import foundation.core; // String, Array, UniquePtr, Function
import :reactive;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Command
    {
    public:
        explicit Command(core::StringView id) : m_id(id) {}
        Command(const Command&) = delete;
        Command& operator=(const Command&) = delete;

        [[nodiscard]] core::StringView GetId() const noexcept { return m_id.AsView(); }
        [[nodiscard]] core::StringView GetLabel() const { return m_label.Get().AsView(); }
        void SetLabel(core::StringView label) { m_label.Set(core::String(label)); }
        [[nodiscard]] core::StringView GetIcon() const { return m_icon.Get().AsView(); }
        void SetIcon(core::StringView icon) { m_icon.Set(core::String(icon)); }
        /// Reads a binding follows.
        [[nodiscard]] bool IsEnabled() const { return m_enabled.Get(); }
        void SetEnabled(bool enabled) { m_enabled.Set(enabled); }
        [[nodiscard]] bool IsChecked() const { return m_checked.Get(); }
        void SetChecked(bool checked) { m_checked.Set(checked); }
        /// Why it is disabled ("Nothing to save"), which a control bound to it shows while it is
        /// (a tool bar's tooltip); a read a binding follows.
        [[nodiscard]] core::StringView GetDisabledReason() const { return m_disabledReason.Get().AsView(); }
        void SetDisabledReason(core::StringView reason) { m_disabledReason.Set(core::String(reason)); }

    private:
        core::String m_id;
        Property<core::String> m_label;
        Property<core::String> m_icon;
        Property<bool> m_enabled{true};
        Property<bool> m_checked{false};
        Property<core::String> m_disabledReason;
    };

    /// When a node's handler runs: on the way down from the root, or on the way up from the focused
    /// widget (the usual place).
    enum class CommandPhase : u8
    {
        Capture,
        Bubble,
    };

    /// What a handler is given: the command, and a way to let it go on past this handler.
    struct CommandEvent
    {
        core::StringView Id;
        CommandPhase Phase = CommandPhase::Bubble;
        bool Propagate = false; ///< A bubble handler sets it to let the command go on up.
        bool Stop = false;      ///< A capture handler sets it to take the command: none below it, nor any bubble handler, runs.
    };

    using CommandHandler = core::Function<void(CommandEvent&)>;

    /// What a control bound to a command is told of its state (Node::OnBoundCommandState).
    struct BoundCommandState
    {
        bool Available = false; ///< Enabled, with a handler on the focus path.
        bool Checked = false;
        /// Why it is not available: the command's disabled reason while it is disabled, else empty
        /// (no handler where the focus is says nothing a user could act on).
        core::StringView Reason;
    };

    /// A GUI's commands, by id.
    class CommandSet
    {
    public:
        CommandSet() noexcept = default;
        CommandSet(const CommandSet&) = delete;
        CommandSet& operator=(const CommandSet&) = delete;

        /// The command `id`, defined now if new (enabled, its label the id until one is set).
        Command& Define(core::StringView id, IAllocator& allocator)
        {
            if (Command* found = Find(id))
                return *found;
            m_commands.PushBack(MakeUnique<Command>(allocator, id));
            Command& command = *m_commands[m_commands.Size() - 1];
            command.SetLabel(id);
            m_changed.Notify();
            return command;
        }
        [[nodiscard]] Command* Find(core::StringView id) const
        {
            for (const UniquePtr<Command>& command : m_commands)
                if (command->GetId() == id)
                    return command.Get();
            return nullptr;
        }
        /// Something that decides availability changed (a definition, a handler added or removed).
        void NotifyChanged() { m_changed.Notify(); }
        void TrackChanges() const { m_changed.Track(); }

    private:
        Array<UniquePtr<Command>> m_commands;
        Observable m_changed;
    };
}
