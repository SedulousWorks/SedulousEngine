// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :element_types partition
//
// Which element types exist, and which one GUI may create (G1 of Specs/vg-and-gui-lab.md).
//
// ElementTypes is the registry of element types: type knowledge, so process-wide, as the reflection
// registry is. Any library adds its widgets (the GUI's own, a toolkit, a game kit, a viewport) by
// registering their reflected types once at start-up; an element type is a reflected Node type with
// a creator (TypeBuilder::Creator), under a tag (its `element` attribute, else its type name) that
// markup names and a script's `add` takes. A tag another type already holds is refused, loudly.
//
// ElementSet is what one GUI may create from those: every registered type by default (including
// ones registered later), or only the tags it allows, with aliases of its own. A GUI holds one
// (GUIContext::SetElementSet), so two GUIs in one process can offer different elements, e.g. a mod's
// markup limited to a few.

module;
#include "Core/Prelude.h"

export module foundation.gui:element_types;

import foundation.core;
import :node;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    struct ElementTypes
    {
        /// Registers `type` as an element under its tag, and with the reflection registry (so
        /// scripts reach it). False, with an error logged, when it is not a Node type, has no
        /// creator, or its tag is another type's.
        static bool Register(const TypeInfo& type);
        /// Takes `type` out (a library unloading): markup and scripts can no longer create it.
        static void Unregister(const TypeInfo& type);
        /// The element type under `tag`, or null.
        [[nodiscard]] static const TypeInfo* Find(core::StringView tag);
        /// The tag `type` registers under: its `element` attribute, else its type name.
        [[nodiscard]] static core::StringView TagOf(const TypeInfo& type);
        /// Every registered element type, in registration order.
        static void ForEach(const core::Function<void(core::StringView tag, const TypeInfo& type)>& visit);
    };

    /// What one GUI may create: every registered element type, or only the tags it allows, under
    /// aliases of its own.
    class ElementSet
    {
    public:
        /// Every registered element type, now and later.
        [[nodiscard]] static ElementSet All() { return ElementSet{}; }
        /// Only the tags allowed with Allow (none yet).
        [[nodiscard]] static ElementSet None()
        {
            ElementSet set;
            set.m_all = false;
            return set;
        }

        /// Allows `tag` (a registered element's tag) in a set made with None().
        void Allow(core::StringView tag) { m_allowed.PushBack(core::String(tag)); }
        /// `alias` creates what `tag` does (in markup and `add`), allowed where `tag` is.
        void Alias(core::StringView alias, core::StringView tag)
        {
            m_aliases.PushBack(AliasEntry{core::String(alias), core::String(tag)});
        }

        /// The element type `tag` names in this set (through an alias), or null when the set does
        /// not allow it or no such element is registered.
        [[nodiscard]] const TypeInfo* Resolve(core::StringView tag) const
        {
            for (const AliasEntry& alias : m_aliases)
                if (alias.alias.AsView() == tag)
                    tag = alias.tag.AsView();
            if (!m_all)
            {
                bool allowed = false;
                for (const core::String& entry : m_allowed)
                    allowed = allowed || entry.AsView() == tag;
                if (!allowed)
                    return nullptr;
            }
            return ElementTypes::Find(tag);
        }

        /// A new element of what `tag` names, from `allocator`; null when the set does not allow it.
        [[nodiscard]] RefPtr<Node> Create(core::StringView tag, IAllocator& allocator) const
        {
            const TypeInfo* type = Resolve(tag);
            if (type == nullptr)
                return RefPtr<Node>{};
            RefPtr<Object> made = CreateObject(*type, allocator);
            return RefPtr<Node>(Cast<Node>(made.Get()));
        }

    private:
        struct AliasEntry
        {
            core::String alias;
            core::String tag;
        };
        bool m_all = true;
        Array<core::String> m_allowed;
        Array<AliasEntry> m_aliases;
    };

    /// A native weak reference to an element of type T: resolves to the element while it lives in
    /// its GUI, and to null once it is destroyed (or its GUI is), through the element table the
    /// script handles use too. For callbacks, tools and bindings that must not keep a widget alive
    /// nor outlive it. Empty for an element in no GUI.
    template <typename T>
    class Element
    {
    public:
        Element() = default;
        explicit Element(T& element)
        {
            if (const Node::ElementRef ref = element.TakeElementRef(); ref.table != nullptr)
            {
                m_table = RefPtr<ElementTable>(ref.table);
                m_slot = ref.slot;
                m_generation = ref.generation;
            }
        }

        [[nodiscard]] T* Get() const noexcept
        {
            return m_table ? static_cast<T*>(m_table->Resolve(m_slot, m_generation)) : nullptr;
        }
        [[nodiscard]] T* operator->() const noexcept { return Get(); }
        [[nodiscard]] bool IsValid() const noexcept { return Get() != nullptr; }
        explicit operator bool() const noexcept { return IsValid(); }

    private:
        RefPtr<ElementTable> m_table;
        u32 m_slot = 0;
        u32 m_generation = 0;
    };
}
