// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :property_editor partition
//
// A property grid's editors (T1 of Specs/gui-lab-evolution-3.md): the value part of a row, bound to
// one property at a time (rows are pooled, so an editor shows one property, then another), editing
// through its host as gestures (begun, previewed, committed or cancelled). The registry chooses an
// editor in layers, as ezEngine's and Zero's do: by the property's hint, then by its kind, then a
// row that says nothing fits; an application registers its own.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:property_editor;

import foundation.core;
import foundation.gui;
import :property_source;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What an editor edits through: its grid, which tracks the gesture and asks the source.
    class IPropertyEditHost
    {
    public:
        virtual ~IPropertyEditHost() = default;
        virtual void BeginPropertyEdit(core::StringView path) = 0;
        virtual void PreviewPropertyEdit(core::StringView path, const PropertyWrite& write) = 0;
        virtual void CommitPropertyEdit(core::StringView path, const PropertyWrite& write) = 0;
        virtual void CancelPropertyEdit(core::StringView path) = 0;
        /// Changes a list (an insert, a removal, a move): one call, one undo entry.
        virtual bool EditPropertyList(core::StringView path, const ListEdit& edit) = 0;
        /// What is under `path` and each one's value: what an editor covering its children shows.
        virtual void GetChildProperties(core::StringView path, core::Array<PropertyInfo>& out) const = 0;
        [[nodiscard]] virtual PropertyValue ReadPropertyValue(core::StringView path, PropertyKind kind) const = 0;
    };

    /// The value part of a property's row.
    class PropertyEditor : public UIWidget
    {
        RTTI_OBJECT(PropertyEditor, UIWidget)
    public:
        PropertyEditor() { SetTag(core::StringView(u8"propertyeditor")); }

        /// Shows `info`'s property at `path`, whose value over the objects is `value`.
        void Bind(IPropertyEditHost& host, core::StringView path, const PropertyInfo& info, const PropertyValue& value)
        {
            m_host = &host;
            m_path = core::String(path);
            m_readOnly = info.ReadOnly;
            OnBind(info, value);
        }
        [[nodiscard]] core::StringView GetPath() const noexcept { return m_path.AsView(); }
        [[nodiscard]] bool IsReadOnly() const noexcept { return m_readOnly; }

    protected:
        [[nodiscard]] IPropertyEditHost* GetHost() const noexcept { return m_host; }

        /// Shows a property and its value; read only, it shows and does not edit.
        virtual void OnBind(const PropertyInfo& info, const PropertyValue& value) = 0;

        // The gesture, through the host. Apply is one begun and committed at once (a click).
        void BeginEdit()
        {
            if (m_host != nullptr && !m_readOnly)
                m_host->BeginPropertyEdit(m_path.AsView());
        }
        void PreviewEdit(const PropertyWrite& write)
        {
            if (m_host != nullptr && !m_readOnly)
                m_host->PreviewPropertyEdit(m_path.AsView(), write);
        }
        void CommitEdit(const PropertyWrite& write)
        {
            if (m_host != nullptr && !m_readOnly)
                m_host->CommitPropertyEdit(m_path.AsView(), write);
        }
        void CancelEdit()
        {
            if (m_host != nullptr && !m_readOnly)
                m_host->CancelPropertyEdit(m_path.AsView());
        }
        void ApplyEdit(const PropertyWrite& write)
        {
            BeginEdit();
            CommitEdit(write);
        }
        bool EditList(const ListEdit& edit) { return m_host != nullptr && !m_readOnly && m_host->EditPropertyList(m_path.AsView(), edit); }

    private:
        IPropertyEditHost* m_host = nullptr;
        core::String m_path;
        bool m_readOnly = false;
    };

    /// What a kind is called (the fallback row's words).
    [[nodiscard]] inline core::StringView PropertyKindName(PropertyKind kind) noexcept
    {
        switch (kind)
        {
        case PropertyKind::Group:
            return core::StringView(u8"group");
        case PropertyKind::Bool:
            return core::StringView(u8"bool");
        case PropertyKind::Integer:
            return core::StringView(u8"integer");
        case PropertyKind::Float:
            return core::StringView(u8"float");
        case PropertyKind::String:
            return core::StringView(u8"string");
        case PropertyKind::Enum:
            return core::StringView(u8"enum");
        case PropertyKind::Flags:
            return core::StringView(u8"flags");
        case PropertyKind::List:
            return core::StringView(u8"list");
        case PropertyKind::Color:
            return core::StringView(u8"colour");
        case PropertyKind::Curve:
            return core::StringView(u8"curve");
        case PropertyKind::Gradient:
            return core::StringView(u8"gradient");
        }
        return core::StringView(u8"value");
    }

    /// The row of a property no editor takes: it says so, the hint or the kind it could not fit.
    class UnknownPropertyEditor : public PropertyEditor
    {
        RTTI_OBJECT(UnknownPropertyEditor, PropertyEditor)
    public:
        UnknownPropertyEditor()
        {
            AddClass(core::StringView(u8"unknown"));
            m_label = core::MakeRef<Label>(MemoryAllocator());
            m_label->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            m_label->SetHitTestVisible(false);
            AddChild(m_label.Get());
        }
        [[nodiscard]] core::StringView GetMessage() const { return m_label->GetText(); }

    protected:
        void OnBind(const PropertyInfo& info, const PropertyValue&) override
        {
            m_label->SetText(core::Format(u8"No editor for {}", info.Hint.Size() != 0 ? info.Hint.AsView() : PropertyKindName(info.Kind)).AsView());
        }
        void OnLayout() override { m_label->Arrange(GetContentBounds()); }
        void OnTextStyleChange() override { ShareTextStyle(*m_label); }

    private:
        core::RefPtr<Label> m_label;
    };

    using PropertyEditorFactory = core::Function<core::RefPtr<PropertyEditor>(core::IAllocator&)>;

    /// The editors a grid chooses from. Each registered editor has a type of row of its own (its
    /// pool), numbered from 1; 0 is the row no editor takes.
    class PropertyEditorRegistry
    {
    public:
        static constexpr u32 kNoEditor = 0;

        PropertyEditorRegistry() = default;
        explicit PropertyEditorRegistry(core::IAllocator& allocator) : m_entries(allocator) {}

        /// The editor for properties hinted `hint`, before their kind's (replaces one of the hint).
        /// One that `coversChildren` shows what is under the property itself: its row has no
        /// chevron and no rows under it (a Float3's three fields on one row).
        void RegisterHint(core::StringView hint, PropertyEditorFactory factory, bool coversChildren = false)
        {
            Register(core::String(hint), false, PropertyKind::Group, core::Move(factory), coversChildren);
        }
        /// The editor for properties of `kind` that no hint takes (replaces the kind's).
        void RegisterKind(PropertyKind kind, PropertyEditorFactory factory) { Register(core::String{}, true, kind, core::Move(factory), false); }

        /// The editor `info` takes: by its hint, then its kind; kNoEditor when none.
        [[nodiscard]] u32 Choose(const PropertyInfo& info) const
        {
            if (info.Hint.Size() != 0)
                for (usize i = 0; i < m_entries.Size(); ++i)
                    if (!m_entries[i].ByKind && m_entries[i].Hint == info.Hint)
                        return static_cast<u32>(i + 1);
            for (usize i = 0; i < m_entries.Size(); ++i)
                if (m_entries[i].ByKind && m_entries[i].Kind == info.Kind)
                    return static_cast<u32>(i + 1);
            return kNoEditor;
        }
        /// Whether the editor of `type` shows what is under its property.
        [[nodiscard]] bool CoversChildren(u32 type) const noexcept { return type != kNoEditor && type <= m_entries.Size() && m_entries[type - 1].CoversChildren; }
        /// A new editor of `type` (Choose's answer).
        [[nodiscard]] core::RefPtr<PropertyEditor> Create(u32 type, core::IAllocator& allocator) const
        {
            if (type != kNoEditor && type <= m_entries.Size() && m_entries[type - 1].Factory)
                if (core::RefPtr<PropertyEditor> made = m_entries[type - 1].Factory(allocator))
                    return made;
            return core::MakeRef<UnknownPropertyEditor>(allocator);
        }
        /// Counts the changes: a grid whose pools were made before one starts them again.
        [[nodiscard]] u32 GetGeneration() const noexcept { return m_generation; }

    private:
        struct Entry
        {
            core::String Hint;
            bool ByKind = false;
            PropertyKind Kind = PropertyKind::Group;
            PropertyEditorFactory Factory;
            bool CoversChildren = false;
        };
        void Register(core::String hint, bool byKind, PropertyKind kind, PropertyEditorFactory factory, bool coversChildren)
        {
            ++m_generation;
            for (Entry& entry : m_entries)
                if (entry.ByKind == byKind && (byKind ? entry.Kind == kind : entry.Hint == hint))
                {
                    entry.Factory = core::Move(factory);
                    entry.CoversChildren = coversChildren;
                    return;
                }
            m_entries.PushBack(Entry{core::Move(hint), byKind, kind, core::Move(factory), coversChildren});
        }

        core::Array<Entry> m_entries;
        u32 m_generation = 0;
    };
}
