// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :property_source partition
//
// What a property grid reads (T1 of Specs/gui-lab-evolution-3.md): a source of properties over one
// object or several. A property is one value (a bool, an integer, a float, a string, an enum or
// flags) at a path; a group (a vector's parts in T2, a nested object) is a property whose children
// are the paths under it (`position.x`), so values that differ between the objects differ per
// part. The source says what is there and what each object holds; the grid edits through it as
// gestures: begun, previewed live on every object, then committed (the originals put back and the
// edit applied once, one undo entry) or cancelled (the originals put back). The undo is the
// source's (an application's, as ezEngine's and Zero's), never the grid's.
//
// A source may say each object's default for a path: the grid marks what differs from it, and a
// revert puts each object's own back, one undo entry.
//
// Copying and pasting go through the source as edits do: it writes a path and what is under it as
// text and reads it back, one undo entry; the grid has the menu and the keys, and no format.
//
// A list's elements are its children by index, and a change to one (an insert, a removal, a move)
// is one call, one undo entry, made in each object.
//
// PropertyBag is a source of its own values in memory: what tests and a page without objects of
// its own edit, its commits told to whoever keeps the undo.

module;
#include "Core/Prelude.h"

export module foundation.gui.toolkit:property_source;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class PropertyKind : u8
    {
        Group,   ///< no value of its own: its children are the paths under it
        Bool,
        Integer,
        Float,
        String,
        Enum,    ///< an integer, one of its choices
        Flags,   ///< an integer, any of its choices' bits
        List,    ///< its elements are its children by index (`tags.0`); its value is their count
        Color,   ///< a colour, its sRGB values (T4)
        Curve,   ///< Core's curve keys, one value (T5); MaxCount its most keys, a range its values'
        Gradient, ///< a ColorGradient, one value (T5); MaxCount its most stops of each kind
    };

    /// What a list allows (PropertyInfo::ListOps).
    enum PropertyListOps : u8
    {
        PropertyListAdd = 1u << 0,
        PropertyListRemove = 1u << 1,
        PropertyListMove = 1u << 2,
    };

    /// An enum's value or a flag's bit, and what it is called.
    struct PropertyChoice
    {
        core::String Name;
        i64 Value = 0;
    };

    /// What a source says of one property. Read afresh each time the grid asks, so whether it shows
    /// or may be edited can follow other values (T3's `visibleWhen`).
    struct PropertyInfo
    {
        core::String Name;        ///< its segment of the path
        core::String DisplayName; ///< what its row says; empty: its name
        core::String Category;    ///< a top-level property's group in the grid; empty: none
        core::String Description; ///< its row's tooltip
        PropertyKind Kind = PropertyKind::String;
        core::String Hint;        ///< an editor asked for by name ("slider"), before its kind's
        bool HasRange = false;    ///< a number kept between Min and Max; else unbounded
        f64 Min = 0.0;
        f64 Max = 0.0;
        f64 Step = 0.0;           ///< a number's step; 0: the editor's own
        core::Array<PropertyChoice> Choices; ///< an enum's values, flags' bits
        bool ReadOnly = false;
        bool Visible = true;
        bool ShowsAlpha = true;   ///< a colour's alpha is edited (not an HDR colour's, nor one with `noAlpha`)
        u8 ListOps = 0;           ///< a list's: PropertyListOps
        u32 MaxCount = 0;         ///< a list's most elements (a BoundedArray's), a curve's most keys, a gradient's most stops; 0: no limit
        core::Array<core::String> ElementTypes; ///< a list's types an add chooses from; empty: its one

        [[nodiscard]] core::StringView ShownName() const noexcept { return DisplayName.Size() != 0 ? DisplayName.AsView() : Name.AsView(); }
    };

    /// A value written by an edit. For flags only `Mask`'s bits change, each object keeping its
    /// others, so a flag set on several objects leaves the flags they differ in as they were.
    struct PropertyWrite
    {
        Variant Value;
        u64 Mask = ~u64{0};
    };

    /// A change to a list: an element inserted at Index (of ElementType, for a list of several), the
    /// one at Index removed, or moved to To (its place after the move).
    struct ListEdit
    {
        enum class Op : u8
        {
            Insert,
            Remove,
            Move,
        };
        Op Kind = Op::Insert;
        usize Index = 0;
        usize To = 0;
        core::String ElementType;
    };

    /// What a source tells its grid.
    class IPropertySourceClient
    {
    public:
        virtual ~IPropertySourceClient() = default;
        /// Which properties there are, or what they say of themselves, changed: read them again.
        virtual void OnPropertiesChanged() = 0;
        /// Values changed (an undo, another editor, the objects themselves): show them again.
        virtual void OnValuesChanged() = 0;
    };

    class IPropertySource
    {
    public:
        virtual ~IPropertySource() = default;

        /// How many objects it stands for; their values differing is a row's mixed state.
        [[nodiscard]] virtual usize ObjectCount() const = 0;
        /// The properties under `parent` (empty: the top level), in their order.
        virtual void GetProperties(core::StringView parent, core::Array<PropertyInfo>& out) const = 0;
        /// The value at `path` of object `object`.
        [[nodiscard]] virtual Variant GetValue(core::StringView path, usize object) const = 0;

        /// An edit of `path` begins: what each object holds now is what a cancel puts back.
        virtual void BeginEdit(core::StringView path) = 0;
        /// The edit as it goes (a scrub, a picker open): written to every object, live.
        virtual void PreviewEdit(core::StringView path, const PropertyWrite& write) = 0;
        /// The edit ends with `write`: the originals put back, then `write` applied as one change.
        virtual void CommitEdit(core::StringView path, const PropertyWrite& write) = 0;
        /// The edit is given up: the originals put back.
        virtual void CancelEdit(core::StringView path) = 0;
        /// Changes the list `path` in each object, one undo entry; false when nothing changed.
        virtual bool EditList(core::StringView path, const ListEdit& edit) = 0;

        /// What object `object` would hold at `path` by default (the type's, a prefab's: the
        /// source's to say); empty when it has none.
        [[nodiscard]] virtual Variant GetDefault(core::StringView path, usize object) const = 0;
        /// Puts each object's own default back at `path` and under it, one undo entry; false when
        /// nothing changed.
        virtual bool Revert(core::StringView path) = 0;
        /// What a revert of `path` is called ("Revert to default", "Revert to prefab").
        [[nodiscard]] virtual core::String GetRevertText(core::StringView path) const = 0;

        /// `path` and what is under it as text for the clipboard (the engine's serialization is a
        /// source's to use); empty when it cannot be copied.
        [[nodiscard]] virtual core::String CopyValue(core::StringView path) const = 0;
        /// Reads `text` (CopyValue's) into `path` in each object, one undo entry; false, with
        /// `reason` filled, when it does not fit.
        virtual bool PasteValue(core::StringView path, core::StringView text, core::String& reason) = 0;

        void SetClient(IPropertySourceClient* client) noexcept { m_client = client; }
        [[nodiscard]] IPropertySourceClient* GetClient() const noexcept { return m_client; }

    protected:
        void NotifyPropertiesChanged()
        {
            if (m_client != nullptr)
                m_client->OnPropertiesChanged();
        }
        void NotifyValuesChanged()
        {
            if (m_client != nullptr)
                m_client->OnValuesChanged();
        }

    private:
        IPropertySourceClient* m_client = nullptr;
    };

    /// `path` joined under `parent` ("position" and "x": "position.x").
    [[nodiscard]] inline core::String JoinPropertyPath(core::StringView parent, core::StringView name)
    {
        core::String path(parent);
        if (path.Size() != 0)
            path.Append(core::StringView(u8"."));
        path.Append(name);
        return path;
    }
    /// The path `path` is under ("" for a top-level property).
    [[nodiscard]] inline core::StringView ParentPropertyPath(core::StringView path)
    {
        for (usize i = path.Size(); i > 0; --i)
            if (path[i - 1] == u8'.')
                return path.SubStr(0, i - 1);
        return core::StringView{};
    }

    /// `write` applied to `old`: flags keep the bits outside its mask.
    [[nodiscard]] inline Variant ApplyPropertyWrite(const Variant& old, const PropertyWrite& write)
    {
        if (write.Mask == ~u64{0})
            return write.Value;
        const u64 bits = (static_cast<u64>(old.AsInt()) & ~write.Mask) | (static_cast<u64>(write.Value.AsInt()) & write.Mask);
        return Variant(static_cast<i64>(bits));
    }

    /// A property's value over every object: the first object's, whether any differs, and for
    /// flags which bits differ.
    struct PropertyValue
    {
        Variant Value;
        bool Mixed = false;
        u64 MixedBits = 0;
    };

    [[nodiscard]] inline PropertyValue ReadPropertyValue(const IPropertySource& source, core::StringView path, PropertyKind kind)
    {
        PropertyValue out;
        const usize count = source.ObjectCount();
        if (count == 0)
            return out;
        out.Value = source.GetValue(path, 0);
        for (usize i = 1; i < count; ++i)
        {
            const Variant other = source.GetValue(path, i);
            if (kind == PropertyKind::Flags)
                out.MixedBits |= static_cast<u64>(out.Value.AsInt()) ^ static_cast<u64>(other.AsInt());
            else if (out.Value.GetType() != other.GetType() || out.Value.Compare(other) != 0)
                out.Mixed = true;
        }
        if (out.MixedBits != 0)
            out.Mixed = true;
        return out;
    }

    /// A source of its own values in memory: properties declared by path, each object's values
    /// kept here, and lists of values (each object's elements its own). A commit is told (path,
    /// each object's value before, each after) to whoever keeps the undo, which puts values back
    /// with SetValue; a list's change is told as it was asked.
    class PropertyBag : public IPropertySource
    {
    public:
        struct Commit
        {
            core::String Path;
            core::Array<Variant> Before;
            core::Array<Variant> After;
        };

        explicit PropertyBag(core::IAllocator& allocator, usize objects = 1)
            : m_allocator(&allocator), m_properties(allocator), m_originals(allocator), m_defaults(allocator), m_objects(objects)
        {
        }

        /// Declares the property `path` (its name the last segment, under its parent's path) with
        /// `value` for every object; returns its info to fill in.
        PropertyInfo& Add(core::StringView path, PropertyKind kind, const Variant& value = {})
        {
            Entry entry(*m_allocator);
            entry.Path = core::String(path);
            const usize parent = ParentPropertyPath(path).Size();
            entry.Info.Name = core::String(parent == 0 ? path : path.SubStr(parent + 1, path.Size() - parent - 1));
            entry.Info.Kind = kind;
            for (usize i = 0; i < m_objects; ++i)
            {
                entry.Values.PushBack(value);
                entry.Elements.PushBack(core::Array<Variant>(*m_allocator));
            }
            m_properties.PushBack(core::Move(entry));
            NotifyPropertiesChanged();
            return m_properties.Back().Info;
        }
        /// Declares the list `path` of values of `elementKind` (a new element `element`), with
        /// `count` elements in every object; returns its info to fill in (by default it may add,
        /// remove and move its elements).
        PropertyInfo& AddList(core::StringView path, PropertyKind elementKind, const Variant& element, usize count = 0)
        {
            PropertyInfo& info = Add(path, PropertyKind::List);
            info.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
            Entry& entry = m_properties.Back();
            entry.ElementKind = elementKind;
            entry.ElementDefault = element;
            for (core::Array<Variant>& elements : entry.Elements)
                for (usize i = 0; i < count; ++i)
                    elements.PushBack(element);
            return info;
        }
        /// The info of `path`, to change; NotifyPropertiesChanged after.
        [[nodiscard]] PropertyInfo* FindInfo(core::StringView path)
        {
            Entry* entry = Find(path);
            return entry != nullptr ? &entry->Info : nullptr;
        }
        /// Tells the grid what FindInfo's changes were.
        void PropertiesChanged() { NotifyPropertiesChanged(); }

        /// Sets object `object`'s value at `path` (a property's or an element's) from code.
        void SetValue(core::StringView path, usize object, const Variant& value)
        {
            if (Variant* slot = Slot(path, object))
            {
                *slot = value;
                NotifyValuesChanged();
            }
        }
        /// Gives object `object`'s list `path` `count` elements from code (new ones its default).
        void ResizeList(core::StringView path, usize object, usize count)
        {
            Entry* list = Find(path);
            if (list == nullptr || list->Info.Kind != PropertyKind::List || object >= list->Elements.Size())
                return;
            core::Array<Variant>& elements = list->Elements[object];
            while (elements.Size() > count)
                elements.PopBack();
            while (elements.Size() < count)
                elements.PushBack(list->ElementDefault);
            NotifyPropertiesChanged();
        }
        /// How many elements object `object`'s list `path` has.
        [[nodiscard]] usize ElementCount(core::StringView path, usize object) const
        {
            const Entry* entry = Find(path);
            return entry != nullptr && object < entry->Elements.Size() ? entry->Elements[object].Size() : 0;
        }

        /// Object `object`'s default at `path` (a property's or an element's); every object's with
        /// kAllObjects.
        static constexpr usize kAllObjects = ~usize{0};
        void SetDefault(core::StringView path, const Variant& value, usize object = kAllObjects)
        {
            for (Default& known : m_defaults)
                if (known.Path.AsView() == path && (object == kAllObjects || known.Object == object))
                    known.Value = value;
            for (usize i = 0; i < m_objects; ++i)
                if (object == kAllObjects || object == i)
                {
                    bool found = false;
                    for (const Default& known : m_defaults)
                        found = found || (known.Path.AsView() == path && known.Object == i);
                    if (!found)
                        m_defaults.PushBack(Default{core::String(path), i, value});
                }
            NotifyValuesChanged();
        }
        /// Told each revert (the path), to keep it for undo.
        void SetOnReverted(core::Function<void(core::StringView)> onReverted) { m_onReverted = core::Move(onReverted); }

        /// Told each commit, to keep it for undo.
        void SetOnCommit(core::Function<void(const Commit&)> onCommit) { m_onCommit = core::Move(onCommit); }
        /// Told each list change made.
        void SetOnListEdited(core::Function<void(core::StringView, const ListEdit&)> onEdited) { m_onListEdited = core::Move(onEdited); }
        /// The edits begun and not yet ended.
        [[nodiscard]] usize OpenEdits() const noexcept { return m_originals.Size(); }

        [[nodiscard]] usize ObjectCount() const override { return m_objects; }
        void GetProperties(core::StringView parent, core::Array<PropertyInfo>& out) const override
        {
            // A list's elements: as many as the fewest any object has.
            if (const Entry* list = Find(parent); list != nullptr && list->Info.Kind == PropertyKind::List)
            {
                usize count = ~usize{0};
                for (const core::Array<Variant>& elements : list->Elements)
                    count = core::Min(count, elements.Size());
                for (usize i = 0; i < count && i != ~usize{0}; ++i)
                {
                    PropertyInfo info;
                    info.Name = core::Format(u8"{}", i);
                    info.Kind = list->ElementKind;
                    info.ReadOnly = list->Info.ReadOnly;
                    out.PushBack(core::Move(info));
                }
                return;
            }
            for (const Entry& entry : m_properties)
                if (ParentPropertyPath(entry.Path.AsView()) == parent)
                    out.PushBack(entry.Info);
        }
        [[nodiscard]] Variant GetValue(core::StringView path, usize object) const override
        {
            if (const Entry* list = Find(path); list != nullptr && list->Info.Kind == PropertyKind::List)
                return object < list->Elements.Size() ? Variant(static_cast<i64>(list->Elements[object].Size())) : Variant{};
            const Variant* slot = const_cast<PropertyBag*>(this)->Slot(path, object);
            return slot != nullptr ? *slot : Variant{};
        }

        void BeginEdit(core::StringView path) override
        {
            if (FindOriginal(path) != nullptr || Slot(path, 0) == nullptr)
                return;
            Original original{core::String(path), core::Array<Variant>(*m_allocator)};
            for (usize i = 0; i < m_objects; ++i)
                original.Values.PushBack(Read(path, i));
            m_originals.PushBack(core::Move(original));
        }
        void PreviewEdit(core::StringView path, const PropertyWrite& write) override
        {
            if (IsReadOnly(path))
                return;
            for (usize i = 0; i < m_objects; ++i)
                if (Variant* slot = Slot(path, i))
                    *slot = ApplyPropertyWrite(*slot, write);
            NotifyValuesChanged();
        }
        void CommitEdit(core::StringView path, const PropertyWrite& write) override
        {
            if (IsReadOnly(path) || Slot(path, 0) == nullptr)
            {
                EndEdit(path);
                return;
            }
            Commit commit{core::String(path), core::Array<Variant>(*m_allocator), core::Array<Variant>(*m_allocator)};
            const Original* original = FindOriginal(path);
            for (usize i = 0; i < m_objects; ++i)
            {
                Variant* slot = Slot(path, i);
                const Variant before = original != nullptr && i < original->Values.Size() ? original->Values[i] : (slot != nullptr ? *slot : Variant{});
                commit.Before.PushBack(before);
                if (slot != nullptr)
                    *slot = ApplyPropertyWrite(before, write); // from the original, not the previews
                commit.After.PushBack(slot != nullptr ? *slot : Variant{});
            }
            EndEdit(path);
            NotifyValuesChanged();
            if (m_onCommit)
                m_onCommit(commit);
        }
        void CancelEdit(core::StringView path) override
        {
            if (const Original* original = FindOriginal(path))
                for (usize i = 0; i < m_objects && i < original->Values.Size(); ++i)
                    if (Variant* slot = Slot(path, i))
                        *slot = original->Values[i];
            EndEdit(path);
            NotifyValuesChanged();
        }
        [[nodiscard]] Variant GetDefault(core::StringView path, usize object) const override
        {
            for (const Default& known : m_defaults)
                if (known.Object == object && known.Path.AsView() == path)
                    return known.Value;
            return Variant{};
        }
        bool Revert(core::StringView path) override
        {
            bool changed = false;
            for (const Default& known : m_defaults)
            {
                const core::StringView at = known.Path.AsView();
                const bool under = at == path || (at.Size() > path.Size() && at.SubStr(0, path.Size()) == path && at[path.Size()] == u8'.');
                Variant* slot = under ? Slot(at, known.Object) : nullptr;
                if (slot != nullptr && (slot->GetType() != known.Value.GetType() || slot->Compare(known.Value) != 0))
                {
                    *slot = known.Value;
                    changed = true;
                }
            }
            if (!changed)
                return false;
            NotifyValuesChanged();
            if (m_onReverted)
                m_onReverted(path);
            return true;
        }
        [[nodiscard]] core::String GetRevertText(core::StringView) const override { return core::String(u8"Revert to default"); }

        // A single value as its text, the first object's; a group or a list is not copied here.
        [[nodiscard]] core::String CopyValue(core::StringView path) const override
        {
            const Variant* slot = const_cast<PropertyBag*>(this)->Slot(path, 0);
            return slot != nullptr ? slot->ToString() : core::String{};
        }
        bool PasteValue(core::StringView path, core::StringView text, core::String& reason) override
        {
            const PropertyKind kind = KindAt(path);
            Variant value;
            switch (kind)
            {
            case PropertyKind::Bool:
                if (text == core::StringView(u8"true") || text == core::StringView(u8"false"))
                    value = Variant(text == core::StringView(u8"true"));
                break;
            case PropertyKind::Integer:
            case PropertyKind::Enum:
            case PropertyKind::Flags:
                if (const Optional<i64> number = core::ParseInt(core::Trim(text)); number.HasValue())
                    value = Variant(number.Value());
                break;
            case PropertyKind::Float:
                if (const Optional<f64> number = core::ParseFloat(core::Trim(text)); number.HasValue())
                    value = Variant(number.Value());
                break;
            case PropertyKind::String:
                value = Variant(text);
                break;
            case PropertyKind::Color:
                if (const Optional<Color> color = ParseColor(core::Trim(text)); color.HasValue())
                    value = Variant(color.Value());
                break;
            default:
                break;
            }
            if (value.IsEmpty() || IsReadOnly(path) || Slot(path, 0) == nullptr)
            {
                reason = core::Format(u8"\"{}\" is no {}", text, PropertyKindLabel(kind));
                return false;
            }
            BeginEdit(path);
            CommitEdit(path, PropertyWrite{value});
            return true;
        }

        bool EditList(core::StringView path, const ListEdit& edit) override
        {
            Entry* list = Find(path);
            if (list == nullptr || list->Info.Kind != PropertyKind::List || list->Info.ReadOnly)
                return false;
            const u8 needs = edit.Kind == ListEdit::Op::Insert ? PropertyListAdd : (edit.Kind == ListEdit::Op::Remove ? PropertyListRemove : PropertyListMove);
            if ((list->Info.ListOps & needs) == 0)
                return false;
            bool changed = false;
            for (core::Array<Variant>& elements : list->Elements)
                switch (edit.Kind)
                {
                case ListEdit::Op::Insert:
                    if (list->Info.MaxCount == 0 || elements.Size() < list->Info.MaxCount)
                    {
                        elements.Insert(core::Min(edit.Index, elements.Size()), list->ElementDefault);
                        changed = true;
                    }
                    break;
                case ListEdit::Op::Remove:
                    if (edit.Index < elements.Size())
                    {
                        elements.RemoveAt(edit.Index);
                        changed = true;
                    }
                    break;
                case ListEdit::Op::Move:
                    if (edit.Index < elements.Size() && edit.To < elements.Size() && edit.Index != edit.To)
                    {
                        Variant moved = elements[edit.Index];
                        elements.RemoveAt(edit.Index);
                        elements.Insert(edit.To, core::Move(moved));
                        changed = true;
                    }
                    break;
                }
            if (!changed)
                return false;
            NotifyPropertiesChanged();
            if (m_onListEdited)
                m_onListEdited(path, edit);
            return true;
        }

    private:
        struct Entry
        {
            explicit Entry(core::IAllocator& allocator) : Values(allocator), Elements(allocator) {}
            core::String Path;
            PropertyInfo Info;
            core::Array<Variant> Values;                 // each object's
            core::Array<core::Array<Variant>> Elements;  // a list's: each object's elements
            PropertyKind ElementKind = PropertyKind::Float;
            Variant ElementDefault;
        };
        struct Original
        {
            core::String Path;
            core::Array<Variant> Values;
        };
        struct Default
        {
            core::String Path;
            usize Object = 0;
            Variant Value;
        };

        const Entry* Find(core::StringView path) const
        {
            for (const Entry& entry : m_properties)
                if (entry.Path.AsView() == path)
                    return &entry;
            return nullptr;
        }
        Entry* Find(core::StringView path) { return const_cast<Entry*>(static_cast<const PropertyBag*>(this)->Find(path)); }
        // Object `object`'s value at `path`: a property's, or an element of a list ("tags.2").
        Variant* Slot(core::StringView path, usize object)
        {
            if (object >= m_objects)
                return nullptr;
            if (Entry* entry = Find(path))
                return entry->Info.Kind == PropertyKind::List ? nullptr : &entry->Values[object];
            const core::StringView parent = ParentPropertyPath(path);
            Entry* list = parent.Size() != 0 ? Find(parent) : nullptr;
            if (list == nullptr || list->Info.Kind != PropertyKind::List)
                return nullptr;
            const Optional<i64> index = core::ParseInt(path.SubStr(parent.Size() + 1, path.Size() - parent.Size() - 1));
            core::Array<Variant>& elements = list->Elements[object];
            return index.HasValue() && index.Value() >= 0 && static_cast<usize>(index.Value()) < elements.Size() ? &elements[static_cast<usize>(index.Value())] : nullptr;
        }
        [[nodiscard]] Variant Read(core::StringView path, usize object)
        {
            const Variant* slot = Slot(path, object);
            return slot != nullptr ? *slot : Variant{};
        }
        [[nodiscard]] PropertyKind KindAt(core::StringView path) const
        {
            if (const Entry* entry = Find(path))
                return entry->Info.Kind;
            const Entry* list = Find(ParentPropertyPath(path));
            return list != nullptr && list->Info.Kind == PropertyKind::List ? list->ElementKind : PropertyKind::Group;
        }
        static core::StringView PropertyKindLabel(PropertyKind kind) noexcept
        {
            switch (kind)
            {
            case PropertyKind::Bool:
                return core::StringView(u8"bool");
            case PropertyKind::Integer:
            case PropertyKind::Enum:
            case PropertyKind::Flags:
                return core::StringView(u8"integer");
            case PropertyKind::Float:
                return core::StringView(u8"number");
            case PropertyKind::String:
                return core::StringView(u8"text");
            case PropertyKind::Color:
                return core::StringView(u8"colour");
            default:
                return core::StringView(u8"value it can take");
            }
        }
        [[nodiscard]] bool IsReadOnly(core::StringView path) const
        {
            if (const Entry* entry = Find(path))
                return entry->Info.ReadOnly;
            const Entry* list = Find(ParentPropertyPath(path));
            return list != nullptr && list->Info.ReadOnly;
        }
        const Original* FindOriginal(core::StringView path) const
        {
            for (const Original& original : m_originals)
                if (original.Path.AsView() == path)
                    return &original;
            return nullptr;
        }
        void EndEdit(core::StringView path)
        {
            for (usize i = 0; i < m_originals.Size(); ++i)
                if (m_originals[i].Path.AsView() == path)
                {
                    m_originals.RemoveAt(i);
                    return;
                }
        }

        core::IAllocator* m_allocator;
        core::Array<Entry> m_properties;
        core::Array<Original> m_originals;
        core::Array<Default> m_defaults;
        usize m_objects;
        core::Function<void(const Commit&)> m_onCommit;
        core::Function<void(core::StringView, const ListEdit&)> m_onListEdited;
        core::Function<void(core::StringView)> m_onReverted;
    };
}
