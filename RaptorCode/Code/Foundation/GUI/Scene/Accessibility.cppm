// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :accessibility partition
//
// The accessibility tree's model (E9d of Specs/gui-lab-evolution.md), AccessKit's owned in C++:
// an AccessNode for each widget a screen reader sees (a stable id, a role, a name, a description
// and a value, a number with its range, bounds in its root's space, states, children, the nodes
// that label, describe and are controlled by it, and the actions it takes), an AccessTreeUpdate
// with the nodes that changed (all of them, the first time) and the focus, and an
// AccessActionRequest a platform sends back. IAccessibilityBridge is the host's: it says whether
// anything listens and takes the updates and announcements; the GUI builds the tree only while it
// listens. The platform adapters (UI Automation, NSAccessibility, AT-SPI) are host work.

module;
#include "Core/Prelude.h"

export module foundation.gui:accessibility;

import foundation.core;
import :rect;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What a node is to a screen reader. None: no node of its own (what it holds belongs to the
    /// nearest ancestor that has one).
    enum class AccessRole : u8
    {
        None,
        Window,
        Dialog,
        Group,
        Label,
        Button,
        CheckBox,
        RadioButton,
        Switch,
        Slider,
        ProgressIndicator,
        SpinButton,
        TextInput,
        MultilineTextInput,
        ComboBox,
        List,
        ListItem,
        Tree,
        TreeItem,
        Table,
        Row, ///< a table's (E17b)
        TabList,
        Tab,
        TabPanel,
        Menu,
        MenuBar,
        MenuItem,
        Separator,
        Image,
        ScrollView,
        ScrollBar,
        Count,
    };

    /// The role's name as a type attribute, markup's `role` and the inspector write it.
    [[nodiscard]] inline core::StringView AccessRoleName(AccessRole role) noexcept
    {
        constexpr core::StringView kNames[static_cast<usize>(AccessRole::Count)] = {
            u8"none",     u8"window",      u8"dialog",  u8"group",     u8"label",     u8"button",   u8"checkbox",
            u8"radio",    u8"switch",      u8"slider",  u8"progress",  u8"spinbutton", u8"textbox", u8"textarea",
            u8"combobox", u8"list",        u8"listitem", u8"tree",     u8"treeitem",  u8"table",    u8"row",      u8"tablist",
            u8"tab",      u8"tabpanel",    u8"menu",    u8"menubar",   u8"menuitem",  u8"separator", u8"image",
            u8"scrollview", u8"scrollbar",
        };
        return kNames[static_cast<usize>(role)];
    }
    /// The role a name means; false for one that is none.
    [[nodiscard]] inline bool AccessRoleNamed(core::StringView name, AccessRole& out) noexcept
    {
        for (usize i = 0; i < static_cast<usize>(AccessRole::Count); ++i)
            if (AccessRoleName(static_cast<AccessRole>(i)) == name)
            {
                out = static_cast<AccessRole>(i);
                return true;
            }
        return false;
    }
    /// A role whose parts are no nodes of their own (a button's label, a slider's thumb): a screen
    /// reader reads it whole.
    [[nodiscard]] constexpr bool IsLeafRole(AccessRole role) noexcept
    {
        switch (role)
        {
        case AccessRole::Label:
        case AccessRole::Button:
        case AccessRole::CheckBox:
        case AccessRole::RadioButton:
        case AccessRole::Switch:
        case AccessRole::Slider:
        case AccessRole::ProgressIndicator:
        case AccessRole::SpinButton:
        case AccessRole::TextInput:
        case AccessRole::MultilineTextInput:
        case AccessRole::ComboBox:
        case AccessRole::Tab:
        case AccessRole::MenuItem:
        case AccessRole::Separator:
        case AccessRole::Image:
        case AccessRole::Row:
        case AccessRole::ScrollBar: return true;
        default: return false;
        }
    }

    /// A node's states, one bit each.
    enum AccessState : u32
    {
        AccessFocusable = 1u << 0,
        AccessFocused = 1u << 1,
        AccessDisabled = 1u << 2,
        AccessChecked = 1u << 3,
        AccessMixed = 1u << 4, ///< neither checked nor not (an indeterminate check box)
        AccessSelected = 1u << 5,
        AccessExpanded = 1u << 6,
        AccessCollapsed = 1u << 7,
        AccessEditable = 1u << 8, ///< the user edits its value
        AccessOffscreen = 1u << 9, ///< an item scrolled out of view, its bounds estimated (UIA's IsOffscreen)
    };

    /// What a platform may ask of a node, one bit each in what it advertises.
    enum class AccessAction : u8
    {
        Focus,
        Activate,
        SetValue,
        Increment,
        Decrement,
        ScrollIntoView,
        Expand,
        Collapse,
    };
    [[nodiscard]] constexpr u32 AccessActionBit(AccessAction action) noexcept { return 1u << static_cast<u32>(action); }

    /// An item view's item's node id (E17b): this bit, the view's key among the GUI's item views,
    /// and the item's key in its view. A node's own id is its element handle, which never sets it.
    inline constexpr u64 kAccessItemIdBit = u64{1} << 63;
    [[nodiscard]] constexpr bool IsAccessItemId(u64 id) noexcept { return (id & kAccessItemIdBit) != 0; }

    /// One node of the tree, as the bridge sees it.
    struct AccessNode
    {
        u64 Id = 0; ///< stable while the node lives (its GUI's element handle; an item's, kAccessItemIdBit)
        AccessRole Role = AccessRole::None;
        core::String Name;
        core::String Description;
        core::String Value; ///< a text's, or a number's as it shows
        bool HasNumber = false;
        f64 Number = 0.0;
        f64 Min = 0.0;
        f64 Max = 0.0;
        f64 Step = 0.0;
        Rect Bounds{}; ///< in its window's pixels (its root's world space)
        // Where it stands among its own (E17b, ARIA's and AccessKit's): an item's position, from 1,
        // of how many there are (a list's every item, though only some have nodes); a tree item's
        // level, from 1; a table's rows and columns, and a row's index, from 1. 0: not said.
        i32 PositionInSet = 0;
        i32 SetSize = 0;
        i32 Level = 0;
        i32 RowCount = 0;
        i32 ColumnCount = 0;
        i32 RowIndex = 0;
        u32 States = 0;
        u32 Actions = 0; ///< AccessActionBit of each it takes
        Array<u64> Children;
        Array<u64> LabelledBy;
        Array<u64> DescribedBy;
        Array<u64> Controls;
        [[nodiscard]] bool Has(AccessState state) const noexcept { return (States & state) != 0; }
        [[nodiscard]] bool Takes(AccessAction action) const noexcept { return (Actions & AccessActionBit(action)) != 0; }
    };

    /// What changed in one root's tree since the last update.
    struct AccessTreeUpdate
    {
        u64 Root = 0;      ///< the root's node (its window)
        bool Full = false; ///< every node of the tree: the first update, or one asked for
        Array<AccessNode> Nodes;
        u64 Focus = 0; ///< the focused node, or the root
        [[nodiscard]] const AccessNode* Find(u64 id) const noexcept
        {
            for (const AccessNode& n : Nodes)
                if (n.Id == id)
                    return &n;
            return nullptr;
        }
    };

    /// An action a platform asks of a node (a screen reader's "press", a value typed into it).
    struct AccessActionRequest
    {
        u64 Target = 0;
        AccessAction Action = AccessAction::Focus;
        core::String Text; ///< SetValue's text
        bool HasNumber = false;
        f64 Number = 0.0; ///< SetValue's number
    };

    /// How an announcement interrupts: after what is being read, or at once.
    enum class AnnouncePriority : u8
    {
        Polite,
        Assertive,
    };

    /// The host's side: a platform adapter, or a stand-in (GUISandbox's --narrate).
    class IAccessibilityBridge
    {
    public:
        virtual ~IAccessibilityBridge() = default;
        /// Whether anything listens (a screen reader running): the tree is built only then.
        [[nodiscard]] virtual bool IsListening() const = 0;
        /// A root's nodes that changed, once a frame (the whole tree the first time).
        virtual void Update(const AccessTreeUpdate& update) = 0;
        /// Text to speak that no node holds (a score, a level loaded).
        virtual void Announce(core::StringView text, AnnouncePriority priority) = 0;
    };
}
