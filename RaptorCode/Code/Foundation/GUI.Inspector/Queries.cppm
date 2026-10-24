// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// foundation.gui.inspector - :queries partition
//
// What the inspector asks of a GUI (E8e of Specs/gui-lab-evolution.md), over the core's public API
// alone: the tree in order, a node described (its identity, states, box, reflected properties,
// bindings, commands and listeners), the nodes a selector matches, and a property set through the
// path markup uses. The panes draw these; a tool (an MCP server, once the GUI is hosted) can serve
// the same answers.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.inspector:queries;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui::inspector
{
    /// A node as a line of the tree: its type, then #id and .classes for a widget ("Button #ok .primary").
    [[nodiscard]] inline core::String Label(const Node& node)
    {
        const core::TypeInfo* type = node.GetType();
        core::String out(type != nullptr ? core::StringView(reinterpret_cast<const char8_t*>(type->name)) : core::StringView(u8"Node"));
        if (const UIWidget* widget = core::Cast<UIWidget>(&node))
        {
            if (widget->GetId().Size() != 0)
            {
                out += core::StringView(u8" #");
                out += widget->GetId();
            }
            for (const core::String& cls : widget->Classes())
            {
                out += core::StringView(u8" .");
                out += cls.AsView();
            }
        }
        return out;
    }

    /// One node of a tree, as the tree pane lists it.
    struct TreeEntry
    {
        Node* Target = nullptr;
        u32 Depth = 0;
        core::String Label;
        bool Shown = true; ///< visible and in the layout, with its ancestors
    };

    /// The tree under `root` (itself included) in document order, each node at its depth below it.
    [[nodiscard]] inline Array<TreeEntry> Tree(Node& root)
    {
        Array<TreeEntry> out;
        const auto walk = [&out](auto& self, Node& node, u32 depth, bool shown) -> void
        {
            const bool here = shown && node.IsVisible() && node.IsDisplayed();
            out.PushBack(TreeEntry{&node, depth, Label(node), here});
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* child = node.GetChildAt(i))
                    self(self, *child, depth + 1, here);
        };
        walk(walk, root, 0, true);
        return out;
    }

    /// A reflected property of a node and its value now.
    struct ReflectedValue
    {
        core::String Name;    ///< as the type names it
        core::String CssName; ///< as markup and sheets name it (empty when they cannot set it)
        core::String Value;   ///< as text (empty when it has none)
        core::String Key;     ///< the key it is translated from (E9a; empty when it is not)
        bool ReadOnly = false;
    };

    /// What the inspector shows of one node.
    struct NodeDescription
    {
        core::String Type;
        core::String Tag;
        core::String Id;
        Array<core::String> Classes;
        Array<core::String> States; ///< the pseudo-classes it has now ("hover", "focus"; "(forced)" when forced)
        Rect Bounds;                ///< its border box in the GUI's world
        Thickness Margin;
        Thickness Padding;
        bool Shown = true;
        bool Enabled = true;
        bool TabFocusable = false;
        Array<ReflectedValue> Properties;
        usize Bindings = 0;
        Array<core::String> Commands;  ///< each command it handles ("menu.open (capture)")
        Array<core::String> Listeners; ///< each event it listens for ("click", "keydown (capture)")
    };

    /// `node` described for the inspector.
    [[nodiscard]] inline NodeDescription Describe(const Node& node)
    {
        NodeDescription d;
        const core::TypeInfo* type = node.GetType();
        d.Type = core::String(type != nullptr ? core::StringView(reinterpret_cast<const char8_t*>(type->name)) : core::StringView(u8"Node"));
        d.Bounds = node.GetScreenBounds();
        d.Margin = node.GetMargin();
        d.Padding = node.GetPadding();
        d.Shown = node.IsTreeVisible();
        d.Enabled = node.IsTreeEnabled();
        d.TabFocusable = node.IsTabFocusable();
        d.Bindings = node.BindingCount();
        const u32 forced = node.GetForcedStyleStates();
        const auto state = [&](bool on, u32 bit, const char8_t* name)
        {
            const bool isForced = (forced & bit) != 0;
            if (!on && !isForced)
                return;
            core::String s(name);
            if (isForced && !on)
                s += core::StringView(u8" (forced)");
            d.States.PushBack(core::Move(s));
        };
        if (const UIWidget* widget = core::Cast<UIWidget>(&node))
        {
            d.Tag = core::String(widget->GetTag());
            d.Id = core::String(widget->GetId());
            for (const core::String& cls : widget->Classes())
                d.Classes.PushBack(cls);
            const u32 widgetStates = widget->GetWidgetStates();
            state(widget->IsHovered(), Node::StateHover, u8"hover");
            state(widget->IsPressed(), Node::StateActive, u8"active");
            state(widget->IsFocused(), Node::StateFocus, u8"focus");
            state(widget->IsFocusVisible(), Node::StateFocusVisible, u8"focus-visible");
            state(widget->IsFocusWithin(), Node::StateFocusWithin, u8"focus-within");
            state((widgetStates & WidgetStateChecked) != 0, Node::StateChecked, u8"checked");
            state(!widget->IsEnabled(), Node::StateDisabled, u8"disabled");
            state((widgetStates & WidgetStateSelected) != 0, Node::StateSelected, u8"selected");
        }
        // Its reflected properties, its own type's first.
        for (const core::TypeInfo* t = type; t != nullptr; t = t->base)
            for (usize i = 0; i < core::PropertyCount(*t); ++i)
            {
                const core::PropertyInfo& property = core::PropertyAt(*t, i);
                ReflectedValue value;
                value.Name = core::String(core::StringView(reinterpret_cast<const char8_t*>(property.name)));
                if (const core::Attribute* css = core::FindAttribute(property, u8"css"))
                    if (const core::String* name = css->value.TryGet<core::String>())
                        value.CssName = *name;
                value.ReadOnly = (static_cast<u32>(property.flags) & static_cast<u32>(core::PropertyFlags::ReadOnly)) != 0;
                if (const core::String* key = node.TranslationKey(value.Name.AsView()))
                    value.Key = *key;
                const core::Variant now = core::GetProperty(property, core::Instance::From(const_cast<Node*>(&node)));
                const core::Variant text = ConvertVariant(now, core::TypeOf<core::String>());
                if (const core::String* s = text.TryGet<core::String>())
                    value.Value = *s;
                d.Properties.PushBack(core::Move(value));
            }
        node.ForEachCommandHandler([&d](core::StringView id, CommandPhase phase)
        {
            core::String s(id);
            if (phase == CommandPhase::Capture)
                s += core::StringView(u8" (capture)");
            d.Commands.PushBack(core::Move(s));
        });
        node.ForEachListener([&d](EventType type, bool capture)
        {
            const core::StringView name = EventTypeName(type);
            core::String s(name.Size() != 0 ? name : core::StringView(u8"(an event)"));
            if (capture)
                s += core::StringView(u8" (capture)");
            d.Listeners.PushBack(core::Move(s));
        });
        return d;
    }

    /// What a screen reader is told of a node (E9d).
    struct AccessDescription
    {
        bool Own = false;         ///< it has a node of its own (else it reads as part of an ancestor)
        core::String ReadAs;      ///< when not: the ancestor it reads as part of (its tree label)
        core::String Role;
        core::String Name;
        core::String Value;
        core::String Description;
        Array<core::String> States;
        Array<core::String> Actions;
    };
    [[nodiscard]] inline AccessDescription DescribeAccess(Node& node)
    {
        AccessDescription d;
        SceneRoot* root = node.GetSceneRoot();
        if (root == nullptr)
            return d;
        AccessNode a;
        if (!root->GetContext().DescribeAccess(node, a))
        {
            for (Node* up = node.GetParent(); up != nullptr; up = up->GetParent())
                if (root->GetContext().DescribeAccess(*up, a))
                {
                    d.ReadAs = Label(*up);
                    break;
                }
            return d;
        }
        d.Own = true;
        d.Role = core::String(AccessRoleName(a.Role));
        d.Name = a.Name;
        d.Value = a.HasNumber ? core::Format(u8"{} (from {} to {}, by {})", a.Number, a.Min, a.Max, a.Step) : a.Value;
        d.Description = a.Description;
        struct Named
        {
            u32 Bit;
            const char8_t* Name;
        };
        static constexpr Named kStates[] = {
            {AccessFocusable, u8"focusable"}, {AccessFocused, u8"focused"},     {AccessDisabled, u8"disabled"},
            {AccessChecked, u8"checked"},     {AccessMixed, u8"mixed"},         {AccessSelected, u8"selected"},
            {AccessExpanded, u8"expanded"},   {AccessCollapsed, u8"collapsed"}, {AccessEditable, u8"editable"},
        };
        for (const Named& s : kStates)
            if ((a.States & s.Bit) != 0)
                d.States.PushBack(core::String(s.Name));
        static constexpr Named kActions[] = {
            {AccessActionBit(AccessAction::Focus), u8"focus"},       {AccessActionBit(AccessAction::Activate), u8"activate"},
            {AccessActionBit(AccessAction::SetValue), u8"set value"}, {AccessActionBit(AccessAction::Increment), u8"increment"},
            {AccessActionBit(AccessAction::Decrement), u8"decrement"}, {AccessActionBit(AccessAction::ScrollIntoView), u8"scroll into view"},
            {AccessActionBit(AccessAction::Expand), u8"expand"},     {AccessActionBit(AccessAction::Collapse), u8"collapse"},
        };
        for (const Named& s : kActions)
            if ((a.Actions & s.Bit) != 0)
                d.Actions.PushBack(core::String(s.Name));
        return d;
    }

    /// One thing a screen reader would trip on.
    struct AccessIssue
    {
        Node* Target = nullptr;
        core::String Message;
    };
    /// What under `root` a screen reader would trip on (E9d): a control the keyboard reaches with no
    /// name, and an aria relation naming no widget.
    [[nodiscard]] inline Array<AccessIssue> AuditAccess(SceneRoot& root)
    {
        Array<AccessIssue> out;
        const auto byId = [&root](core::StringView id)
        {
            const auto find = [id](auto& self, Node& node) -> bool
            {
                if (const UIWidget* w = core::Cast<UIWidget>(&node); w != nullptr && w->GetId() == id)
                    return true;
                for (usize i = 0; i < node.ChildCount(); ++i)
                    if (Node* child = node.GetChildAt(i); child != nullptr && self(self, *child))
                        return true;
                return false;
            };
            return find(find, root);
        };
        const auto relation = [&](Node& node, const char8_t* attribute, const core::String& ids)
        {
            usize i = 0;
            const core::StringView list = ids.AsView();
            while (i < list.Size())
            {
                while (i < list.Size() && list[i] == u8' ')
                    ++i;
                const usize start = i;
                while (i < list.Size() && list[i] != u8' ')
                    ++i;
                if (i > start && !byId(list.SubStr(start, i - start)))
                    out.PushBack(AccessIssue{&node, core::Format(u8"{} names no widget: #{}", core::StringView(attribute), list.SubStr(start, i - start))});
            }
        };
        const auto walk = [&](auto& self, Node& node) -> void
        {
            if (UIWidget* widget = core::Cast<UIWidget>(&node))
            {
                AccessNode a;
                if (node.IsTabFocusable() && root.GetContext().DescribeAccess(node, a) && a.Name.Size() == 0)
                    out.PushBack(AccessIssue{&node, core::Format(u8"a focusable {} with no name", AccessRoleName(a.Role))});
                relation(node, u8"aria-labelledby", widget->GetAccessLabelledBy());
                relation(node, u8"aria-describedby", widget->GetAccessDescribedBy());
                relation(node, u8"aria-controls", widget->GetAccessControls());
            }
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* child = node.GetChildAt(i))
                    self(self, *child);
        };
        walk(walk, root);
        return out;
    }

    /// The widgets under `root` (itself included) a CSS selector matches, in document order.
    [[nodiscard]] inline Array<Node*> Query(Node& root, core::StringView selector)
    {
        Array<Node*> out;
        const StyleSelector parsed(selector);
        if (parsed.IsEmpty())
            return out;
        const auto walk = [&](auto& self, Node& node) -> void
        {
            if (const UIWidget* widget = core::Cast<UIWidget>(&node); widget != nullptr && parsed.Select(*widget))
                out.PushBack(&node);
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* child = node.GetChildAt(i))
                    self(self, *child);
        };
        walk(walk, root);
        return out;
    }

    /// Sets property `name` (its CSS name, or its type's name) to `text` as markup does: an
    /// attribute the widget claims, else inline CSS the next restyle applies (which a sheet's rules
    /// do not outrank). False when the node is no widget, or has no such property or attribute.
    inline bool SetProperty(Node& node, core::StringView name, core::StringView text)
    {
        UINode* uinode = core::Cast<UINode>(&node);
        if (uinode == nullptr)
            return false;
        if (uinode->SetMarkupAttribute(name, text)) // one the widget claims (a label's text)
            return true;
        core::StringView attribute = name;
        bool known = FindStyleProperty(name) != nullptr;
        for (const core::TypeInfo* t = node.GetType(); t != nullptr && !known; t = t->base)
            for (usize i = 0; i < core::PropertyCount(*t) && !known; ++i)
            {
                const core::PropertyInfo& property = core::PropertyAt(*t, i);
                const core::Attribute* css = core::FindAttribute(property, u8"css");
                const core::String* cssName = css != nullptr ? css->value.TryGet<core::String>() : nullptr;
                const core::StringView own(reinterpret_cast<const char8_t*>(property.name));
                if (cssName != nullptr && (cssName->AsView() == name || own == name))
                {
                    attribute = cssName->AsView();
                    known = true;
                }
            }
        if (!known)
            return false;
        uinode->SetInlineStyle(attribute, text);
        return true;
    }
}
