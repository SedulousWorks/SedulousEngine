// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :reflected_source partition
//
// The property source over core reflection (T3 of Specs/gui-lab-evolution-3.md, ruling 1: the
// toolkit's): one reflected instance or several of one type, their properties as the grid's paths.
//   - bool, every integer width, f32, f64 and String are values; an enum is choices from its
//     enumerators, or flags with a `flags` attribute (read and written as an integer through the
//     property's address); a ReadOnly property is read only.
//   - A Color is a colour (T4), its alpha hidden with `noAlpha`; a Float4 with `hdrColor` (sRGB
//     rgb, a linear intensity in w) is an HDR colour, hinted "ColorHdr", its parts `color` and
//     `intensity` (shown in stops).
//   - Float2, Float3 and Float4 are groups hinted with their names, their parts x, y, z, w; a
//     Quaternion is a Float3 group of Euler degrees (pitch, yaw, roll) the source converts, as the
//     editor's Transform row does; a Nested struct, or a reflected value struct, is a group.
//   - Array<T> and a BoundedArray are lists (reflection's emplaceDefault, removeAt, moveElement),
//     their elements by index; an Array<RefPtr<Base>> adds by type, the types that derive from
//     its base and its factory can make, by their displayName.
//   - A struct's group carries its type's name as its hint, and so does any other type, for an
//     application's editor (a Color until T4, a Ref, an EntityRef); a struct no editor takes shows
//     its own rows, anything else the grid's row saying no editor fits.
//   - A type the application registers as a curve (its keys property, a list of Core's CurveKey)
//     is one value of kind Curve, its keys whole; one registered as a gradient (its colour stops,
//     alpha stops and blend properties) is one value of kind Gradient (T5): the toolkit names no
//     runtime type, the application says which of its types these are and where their parts are.
//   - The attributes the editor's inspector reads: `displayName` (else the name made readable),
//     `description`, `range` (a Float4 of min, max, step), `visibleWhen` ("prop", or "prop=1,2" of
//     its raw integer, a sibling's; shown when it holds for every object), and `flags`.
// Defaults: the type's, read from an instance its creator makes, under any an application stacks
// over it (a prefab's, by path and object); a revert puts each object's own back, a list whole
// from the type's instance.
// Writes go through the property's address, or its setter for a computed one. Each commit is told
// to the application as one change: what, where, and each object's value there before and after as
// text, written with the text format the application gives (its serializer), which Restore reads
// back for an undo; the undo is the application's.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:reflected_source;

import foundation.core;
import foundation.gui;
import :property_source;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What the application gives a reflected source to write text with: its serializer (the
    /// engine's XmlSerializer, say), so the toolkit takes on no format.
    class IPropertyTextFormat
    {
    public:
        virtual ~IPropertyTextFormat() = default;
        /// Text written by `write`; empty when it failed.
        [[nodiscard]] virtual core::String Write(core::Function<void(core::ISerializer&)> write) = 0;
        /// Reads `text` with `read`; false when it is not the format's or the read failed.
        virtual bool Read(core::StringView text, core::Function<void(core::ISerializer&)> read) = 0;
    };

    /// A change a reflected source made: what (in words), where, and each object's value there
    /// before and after as the text format's text (empty without one).
    struct ReflectedChange
    {
        core::String Words;
        core::String Path;
        core::Array<core::String> Before;
        core::Array<core::String> After;
    };

    /// Where a type registered as a curve keeps its keys: a list (an Array or a BoundedArray) of
    /// Core's CurveKey, by its property's name (the most it holds is the list's capacity).
    struct ReflectedCurveParts
    {
        core::String Keys;
    };
    /// Where a type registered as a gradient keeps its parts: its lists of Core's GradientColorStop
    /// and GradientAlphaStop and its GradientInterpolation, by their properties' names (the most
    /// stops of a kind is the smaller list's capacity).
    struct ReflectedGradientParts
    {
        core::String Colors;
        core::String Alphas;
        core::String Interpolation;
    };

    /// "castsShadows" -> "Casts Shadows", "fovYRadians" -> "Fov Y Radians", "IBL" -> "IBL": a
    /// reflected name as a row says it (the editor's convention).
    [[nodiscard]] inline core::String ReadablePropertyName(core::StringView name)
    {
        core::String out;
        bool prevLower = false;
        bool prevUpper = false;
        for (usize i = 0; i < name.Size(); ++i)
        {
            char8_t c = name[i];
            const bool upper = c >= u8'A' && c <= u8'Z';
            const bool lower = c >= u8'a' && c <= u8'z';
            if (i == 0 && lower)
                c = static_cast<char8_t>(c - (u8'a' - u8'A'));
            else if (upper)
            {
                const bool nextLower = i + 1 < name.Size() && name[i + 1] >= u8'a' && name[i + 1] <= u8'z';
                if (prevLower || (prevUpper && nextLower))
                    out.Append(core::StringView(u8" "));
            }
            out.Append(core::StringView(&c, 1));
            prevLower = lower;
            prevUpper = upper;
        }
        return out;
    }

    class ReflectedPropertySource : public IPropertySource
    {
    public:
        explicit ReflectedPropertySource(core::IAllocator& allocator)
            : m_allocator(allocator), m_objects(allocator), m_originals(allocator), m_providers(allocator)
        {
        }

        /// The instances it stands for, all of one type (several components: several objects).
        void SetObjects(core::Span<const core::Instance> objects)
        {
            m_objects.Clear();
            for (const core::Instance& object : objects)
                if (!object.IsEmpty())
                    m_objects.PushBack(object);
            m_originals.Clear();
            // The type's defaults: an instance its creator makes (none for a type without one).
            m_typeDefault = m_objects.IsEmpty() ? core::RefPtr<core::Object>{} : core::CreateObject(*m_objects[0].Type(), m_allocator);
            NotifyPropertiesChanged();
        }
        [[nodiscard]] core::Span<const core::Instance> GetObjects() const noexcept { return m_objects.AsSpan(); }
        /// The text format changes and copies are written in (not owned; null: none).
        void SetTextFormat(IPropertyTextFormat* format) noexcept { m_format = format; }
        /// Told each change made, to keep for undo.
        void SetOnChange(core::Function<void(const ReflectedChange&)> onChange) { m_onChange = core::Move(onChange); }
        /// Puts `change`'s values back, those before it (an undo) or after it (a redo); false
        /// without a text format or when the objects no longer take it.
        bool Restore(const ReflectedChange& change, bool before)
        {
            const core::Array<core::String>& states = before ? change.Before : change.After;
            if (m_format == nullptr || states.Size() != m_objects.Size())
                return false;
            bool ok = true;
            for (usize i = 0; i < m_objects.Size(); ++i)
                ok = ReadState(change.Path.AsView(), i, states[i].AsView()) && ok;
            NotifyPropertiesChanged(); // a list's count may have changed back
            return ok;
        }
        /// A default for a path and an object (empty: it has none there), over the type's own.
        using DefaultProvider = core::Function<Variant(core::StringView path, usize object)>;
        /// Stacks `provider` over the defaults (the last stacked asks first); a revert is then
        /// called `revertText` ("Revert to prefab").
        void PushDefaults(DefaultProvider provider, core::StringView revertText)
        {
            m_providers.PushBack(Provider{core::Move(provider), core::String(revertText)});
            NotifyValuesChanged();
        }
        void ClearDefaults()
        {
            m_providers.Clear();
            NotifyValuesChanged();
        }

        /// Tells the grid the objects changed from outside it (an undo the application made).
        void Refresh() { NotifyPropertiesChanged(); }

        /// Takes the type named `typeName` as a curve: one value, its keys at `parts.Keys`.
        void RegisterCurveType(core::StringView typeName, ReflectedCurveParts parts)
        {
            m_curveTypes.PushBack(CurveType{core::String(typeName), core::Move(parts)});
            NotifyPropertiesChanged();
        }
        /// Takes the type named `typeName` as a gradient: one value of its stops and blend.
        void RegisterGradientType(core::StringView typeName, ReflectedGradientParts parts)
        {
            m_gradientTypes.PushBack(GradientType{core::String(typeName), core::Move(parts)});
            NotifyPropertiesChanged();
        }

        // === IPropertySource ===
        [[nodiscard]] usize ObjectCount() const override { return m_objects.Size(); }

        void GetProperties(core::StringView parent, core::Array<PropertyInfo>& out) const override
        {
            if (m_objects.IsEmpty())
                return;
            Target target;
            if (!Resolve(0, parent, target))
                return;
            if (parent.Size() == 0 || IsGroup(target))
            {
                ListPropertiesOf(parent, target, out);
                return;
            }
            const Shape shape = ShapeOf(*target.Type);
            if (target.Part < 0 && shape == Shape::List)
            {
                ListElements(parent, out);
                return;
            }
            if (target.Part < 0 && target.Hdr)
                ListHdrParts(out);
            else if (target.Part < 0 && (shape == Shape::Float2 || shape == Shape::Float3 || shape == Shape::Float4 || shape == Shape::Quaternion))
                ListParts(shape, out);
        }

        [[nodiscard]] Variant GetValue(core::StringView path, usize object) const override
        {
            Target target;
            return Resolve(object, path, target) ? Read(target) : Variant{};
        }

        void BeginEdit(core::StringView path) override
        {
            Original original{core::String(path), core::Array<Variant>(m_allocator), core::Array<core::String>(m_allocator)};
            for (usize i = 0; i < m_objects.Size(); ++i)
            {
                original.Values.PushBack(GetValue(path, i));
                original.States.PushBack(WriteState(path, i));
            }
            m_originals.PushBack(core::Move(original));
        }
        void PreviewEdit(core::StringView path, const PropertyWrite& write) override
        {
            for (usize i = 0; i < m_objects.Size(); ++i)
                WriteValue(path, i, write);
            NotifyValuesChanged();
        }
        void CommitEdit(core::StringView path, const PropertyWrite& write) override
        {
            ReflectedChange change{core::Format(u8"Set {}", path), core::String(path), core::Array<core::String>(m_allocator),
                                   core::Array<core::String>(m_allocator)};
            const Original* original = FindOriginal(path);
            for (usize i = 0; i < m_objects.Size(); ++i)
            {
                if (original != nullptr && i < original->Values.Size())
                {
                    Target target;
                    if (Resolve(i, path, target))
                        WriteTarget(target, original->Values[i]); // the original back, then the one change
                    change.Before.PushBack(original->States[i]);
                }
                else
                    change.Before.PushBack(WriteState(path, i));
                WriteValue(path, i, write);
                change.After.PushBack(WriteState(path, i));
            }
            DropOriginal(path);
            Changed(path);
            if (m_onChange)
                m_onChange(change);
        }
        void CancelEdit(core::StringView path) override
        {
            if (const Original* original = FindOriginal(path))
                for (usize i = 0; i < m_objects.Size() && i < original->Values.Size(); ++i)
                {
                    Target target;
                    if (Resolve(i, path, target))
                        WriteTarget(target, original->Values[i]);
                }
            DropOriginal(path);
            NotifyValuesChanged();
        }

        bool EditList(core::StringView path, const ListEdit& edit) override
        {
            ReflectedChange change{ListWords(path, edit), core::String(path), core::Array<core::String>(m_allocator), core::Array<core::String>(m_allocator)};
            bool changed = false;
            for (usize o = 0; o < m_objects.Size(); ++o)
            {
                change.Before.PushBack(WriteState(path, o));
                Target target;
                if (Resolve(o, path, target) && target.Type != nullptr && ShapeOf(*target.Type) == Shape::List && !target.ReadOnly && target.Address != nullptr)
                    changed = ChangeList(target, edit) || changed;
                change.After.PushBack(WriteState(path, o));
            }
            if (!changed)
                return false;
            NotifyPropertiesChanged();
            if (m_onChange)
                m_onChange(change);
            return true;
        }
        [[nodiscard]] Variant GetDefault(core::StringView path, usize object) const override
        {
            Target target;
            if (!Resolve(object, path, target) || target.ReadOnly)
                return Variant{}; // nothing to put back where nothing is written
            for (usize i = m_providers.Size(); i > 0; --i)
                if (const Variant value = m_providers[i - 1].Default(path, object); !value.IsEmpty())
                    return value;
            Target byDefault;
            return m_typeDefault && ResolveIn(core::Instance(m_typeDefault.Get(), m_objects[0].Type()), path, byDefault) ? Read(byDefault) : Variant{};
        }
        bool Revert(core::StringView path) override
        {
            ReflectedChange change{core::Format(u8"Reverted {}", path), core::String(path), core::Array<core::String>(m_allocator),
                                   core::Array<core::String>(m_allocator)};
            bool changed = false;
            for (usize o = 0; o < m_objects.Size(); ++o)
            {
                change.Before.PushBack(WriteState(path, o));
                changed = RevertUnder(path, o) || changed;
                change.After.PushBack(WriteState(path, o));
            }
            if (!changed)
                return false;
            NotifyPropertiesChanged();
            if (m_onChange)
                m_onChange(change);
            return true;
        }
        [[nodiscard]] core::String GetRevertText(core::StringView) const override
        {
            return m_providers.IsEmpty() ? core::String(u8"Revert to default") : m_providers.Back().RevertText;
        }
        // The first object's value at `path` in the text format: its shape, then the value.
        [[nodiscard]] core::String CopyValue(core::StringView path) const override
        {
            Target target;
            if (m_format == nullptr || !Resolve(0, path, target) || target.Type == nullptr)
                return core::String{};
            core::String shape = ShapeTag(target);
            if (shape.Size() == 0)
                return core::String{};
            const ReflectedPropertySource* self = this;
            return m_format->Write([self, target, shape](core::ISerializer& ar) mutable
            {
                core::Serialize(ar, "shape", shape);
                self->SerializeTarget(ar, "value", target);
            });
        }
        // Into each object, one change; refused when the shape differs or nothing can be written.
        bool PasteValue(core::StringView path, core::StringView text, core::String& reason) override
        {
            Target target;
            if (m_format == nullptr || !Resolve(0, path, target) || target.Type == nullptr)
            {
                reason = core::String(u8"Nothing to paste into");
                return false;
            }
            if (target.ReadOnly)
            {
                reason = core::Format(u8"{} is read only", path);
                return false;
            }
            core::String copied;
            const bool read = m_format->Read(text, [&copied](core::ISerializer& ar) { core::Serialize(ar, "shape", copied); });
            if (!read || copied.Size() == 0)
            {
                reason = core::String(u8"The clipboard holds no copied property");
                return false;
            }
            const core::String expected = ShapeTag(target);
            if (copied != expected)
            {
                reason = core::Format(u8"A {} does not paste onto a {}", copied, expected);
                return false;
            }
            ReflectedChange change{core::Format(u8"Pasted {}", path), core::String(path), core::Array<core::String>(m_allocator),
                                   core::Array<core::String>(m_allocator)};
            for (usize o = 0; o < m_objects.Size(); ++o)
            {
                change.Before.PushBack(WriteState(path, o));
                Target into;
                if (Resolve(o, path, into))
                {
                    const ReflectedPropertySource* self = this;
                    (void)m_format->Read(text, [self, into](core::ISerializer& ar) mutable
                    {
                        core::String shape;
                        core::Serialize(ar, "shape", shape);
                        self->SerializeTarget(ar, "value", into);
                    });
                }
                change.After.PushBack(WriteState(path, o));
            }
            NotifyPropertiesChanged();
            if (m_onChange)
                m_onChange(change);
            return true;
        }

    protected:
        // What reflection holds, as the grid sees it.
        enum class Shape : u8
        {
            Bool,
            Integer,
            Float,
            String,
            Enum,
            Float2,
            Float3,
            Float4,
            Quaternion,
            Color,
            Curve,    // a type registered as a curve
            Gradient, // a type registered as a gradient
            Group, // a nested or value struct, an object
            List,
            Other,
        };

        // A place a path names in one object: a property of an owner, an element of a list, a part
        // of a Float or a Quaternion, or an object (the root, a nested struct, an element).
        struct Target
        {
            const core::TypeInfo* Type = nullptr;
            void* Address = nullptr;
            core::Instance Owner;                       // a property's
            const core::PropertyInfo* Property = nullptr;
            core::Instance List;                        // an element's list
            usize Index = 0;
            bool Element = false;
            i32 Part = -1;                              // a part of the Float or Quaternion above
            bool Hdr = false;                           // a Float4 that is an HDR colour
            bool ReadOnly = false;
        };

        // A type's shape: one the application registered (a curve, a gradient), else what it is.
        [[nodiscard]] Shape ShapeOf(const core::TypeInfo& type) const
        {
            const core::StringView name(reinterpret_cast<const char8_t*>(type.name));
            if (FindCurveType(name) != nullptr)
                return Shape::Curve;
            if (FindGradientType(name) != nullptr)
                return Shape::Gradient;
            return BaseShapeOf(type);
        }
        [[nodiscard]] const ReflectedCurveParts* FindCurveType(core::StringView name) const
        {
            for (const CurveType& entry : m_curveTypes)
                if (entry.Name.AsView() == name)
                    return &entry.Parts;
            return nullptr;
        }
        [[nodiscard]] const ReflectedGradientParts* FindGradientType(core::StringView name) const
        {
            for (const GradientType& entry : m_gradientTypes)
                if (entry.Name.AsView() == name)
                    return &entry.Parts;
            return nullptr;
        }
        [[nodiscard]] static Shape BaseShapeOf(const core::TypeInfo& type)
        {
            const auto is = [&type]<typename T>() { return &type == &core::TypeOf<T>() || type.id == core::TypeOf<T>().id; };
            if (is.template operator()<bool>())
                return Shape::Bool;
            if (is.template operator()<i8>() || is.template operator()<u8>() || is.template operator()<i16>() || is.template operator()<u16>() ||
                is.template operator()<i32>() || is.template operator()<u32>() || is.template operator()<i64>() || is.template operator()<u64>())
                return Shape::Integer;
            if (is.template operator()<f32>() || is.template operator()<f64>())
                return Shape::Float;
            if (is.template operator()<core::String>())
                return Shape::String;
            if (is.template operator()<core::Float2>())
                return Shape::Float2;
            if (is.template operator()<core::Float3>())
                return Shape::Float3;
            if (is.template operator()<core::Float4>())
                return Shape::Float4;
            if (is.template operator()<core::Quaternion>())
                return Shape::Quaternion;
            if (is.template operator()<core::Color>())
                return Shape::Color;
            if (core::IsEnum(type))
                return Shape::Enum;
            if (type.container != nullptr)
                return Shape::List;
            for (const core::TypeInfo* t = &type; t != nullptr; t = t->base)
                if (t->propertyCount != 0)
                    return Shape::Group;
            return Shape::Other;
        }
        [[nodiscard]] bool IsGroup(const Target& target) const
        {
            return target.Part < 0 && target.Type != nullptr && ShapeOf(*target.Type) == Shape::Group;
        }

        // The place `path` names in object `object`.
        bool Resolve(usize object, core::StringView path, Target& out) const
        {
            return object < m_objects.Size() && ResolveIn(m_objects[object], path, out);
        }
        bool ResolveIn(const core::Instance& root, core::StringView path, Target& out) const
        {
            Target at;
            at.Type = root.Type();
            at.Address = root.Pointer();
            usize start = 0;
            while (start < path.Size())
            {
                usize end = start;
                while (end < path.Size() && path[end] != u8'.')
                    ++end;
                const core::StringView segment = path.SubStr(start, end - start);
                start = end + 1;
                if (!Step(at, segment))
                    return false;
            }
            out = at;
            return true;
        }
        // One segment further from `at`: a property of a group, an element of a list, a part.
        bool Step(Target& at, core::StringView segment) const
        {
            if (at.Part >= 0 || at.Type == nullptr)
                return false;
            const Shape shape = ShapeOf(*at.Type);
            if (shape == Shape::Group)
            {
                if (at.Address == nullptr)
                    return false;
                const core::Instance owner(at.Address, at.Type);
                const core::PropertyInfo* property = FindPropertyNamed(*at.Type, segment);
                if (property == nullptr)
                    return false;
                Target next;
                next.Owner = owner;
                next.Property = property;
                next.Type = property->type;
                next.Address = property->address != nullptr ? property->address(owner) : nullptr;
                next.ReadOnly = at.ReadOnly || (static_cast<u32>(property->flags) & static_cast<u32>(core::PropertyFlags::ReadOnly)) != 0;
                next.Hdr = core::FindAttribute(*property, core::StringView(u8"hdrColor")) != nullptr && ShapeOf(*property->type) == Shape::Float4;
                at = next;
                return true;
            }
            if (shape == Shape::List)
            {
                const core::Optional<i64> index = core::ParseInt(segment);
                const core::ContainerInfo& container = *at.Type->container;
                if (!index.HasValue() || index.Value() < 0 || at.Address == nullptr)
                    return false;
                const core::Instance list(at.Address, at.Type);
                const usize i = static_cast<usize>(index.Value());
                if (i >= core::ContainerSize(container, list))
                    return false;
                Target next;
                next.List = list;
                next.Index = i;
                next.Element = true;
                next.ReadOnly = at.ReadOnly;
                next.Type = container.elementType;
                const core::Instance element = core::ContainerAddressAt(container, list, i);
                if (!element.IsEmpty())
                {
                    next.Address = element.Pointer();
                    next.Type = element.Type(); // a polymorphic element's own type
                }
                at = next;
                return true;
            }
            const i32 part = at.Hdr ? HdrPartIndex(segment) : PartIndex(shape, segment);
            if (part >= 0)
            {
                at.Part = part;
                return true;
            }
            return false;
        }
        [[nodiscard]] static const core::PropertyInfo* FindPropertyNamed(const core::TypeInfo& type, core::StringView name)
        {
            for (const core::TypeInfo* t = &type; t != nullptr; t = t->base)
                for (u32 i = 0; i < t->propertyCount; ++i)
                    if (core::StringView(reinterpret_cast<const char8_t*>(t->properties[i].name)) == name)
                        return &t->properties[i];
            return nullptr;
        }
        // An HDR colour's parts: its colour (rgb), its intensity (w).
        static constexpr i32 kHdrColorPart = 10;
        [[nodiscard]] static i32 HdrPartIndex(core::StringView segment)
        {
            if (segment == core::StringView(u8"color"))
                return kHdrColorPart;
            return segment == core::StringView(u8"intensity") ? 3 : -1;
        }
        [[nodiscard]] static i32 PartIndex(Shape shape, core::StringView segment)
        {
            if (shape == Shape::Quaternion)
            {
                const core::StringView names[] = {core::StringView(u8"pitch"), core::StringView(u8"yaw"), core::StringView(u8"roll")};
                for (i32 i = 0; i < 3; ++i)
                    if (segment == names[i])
                        return i;
                return -1;
            }
            const i32 count = shape == Shape::Float2 ? 2 : (shape == Shape::Float3 ? 3 : (shape == Shape::Float4 ? 4 : 0));
            const core::StringView names[] = {core::StringView(u8"x"), core::StringView(u8"y"), core::StringView(u8"z"), core::StringView(u8"w")};
            for (i32 i = 0; i < count; ++i)
                if (segment == names[i])
                    return i;
            return -1;
        }

        // A group's properties, its type's bases first, as rows.
        void ListPropertiesOf(core::StringView path, const Target& group, core::Array<PropertyInfo>& out) const
        {
            if (group.Type == nullptr || group.Address == nullptr)
                return;
            core::Array<const core::TypeInfo*> chain(m_allocator);
            for (const core::TypeInfo* t = group.Type; t != nullptr; t = t->base)
                chain.Insert(0, t);
            for (const core::TypeInfo* t : chain)
                for (u32 i = 0; i < t->propertyCount; ++i)
                {
                    PropertyInfo info;
                    if (Describe(path, group, t->properties[i], info))
                        out.PushBack(core::Move(info));
                }
        }
        // A property as a row: its kind, hint, names and the attributes it carries.
        bool Describe(core::StringView path, const Target& group, const core::PropertyInfo& property, PropertyInfo& info) const
        {
            const core::StringView name(reinterpret_cast<const char8_t*>(property.name));
            info.Name = core::String(name);
            const core::String* shown = StringAttribute(property, u8"displayName");
            info.DisplayName = shown != nullptr ? *shown : ReadablePropertyName(name);
            if (const core::String* description = StringAttribute(property, u8"description"))
                info.Description = *description;
            info.ReadOnly = group.ReadOnly || (static_cast<u32>(property.flags) & static_cast<u32>(core::PropertyFlags::ReadOnly)) != 0;
            DescribeType(*property.type, core::FindAttribute(property, core::StringView(u8"flags")) != nullptr, info);
            if (info.Kind == PropertyKind::Color)
                info.ShowsAlpha = core::FindAttribute(property, core::StringView(u8"noAlpha")) == nullptr;
            if (ShapeOf(*property.type) == Shape::Float4 && core::FindAttribute(property, core::StringView(u8"hdrColor")) != nullptr)
                info.Hint = core::String(u8"ColorHdr");
            if (const core::Attribute* range = core::FindAttribute(property, core::StringView(u8"range")))
                if (const core::Float4* bounds = range->value.TryGet<core::Float4>())
                {
                    info.HasRange = true;
                    info.Min = bounds->x;
                    info.Max = bounds->y;
                    info.Step = bounds->z;
                }
            if (const core::String* condition = StringAttribute(property, u8"visibleWhen"))
                info.Visible = Holds(path, condition->AsView());
            return true;
        }
        // A type's kind as a row (flags: an enum read as flags), what a property or an element is.
        void DescribeType(const core::TypeInfo& type, bool flags, PropertyInfo& info) const
        {
            switch (ShapeOf(type))
            {
            case Shape::Bool:
                info.Kind = PropertyKind::Bool;
                break;
            case Shape::Integer:
                info.Kind = PropertyKind::Integer;
                break;
            case Shape::Float:
                info.Kind = PropertyKind::Float;
                break;
            case Shape::String:
                info.Kind = PropertyKind::String;
                break;
            case Shape::Enum:
                info.Kind = flags ? PropertyKind::Flags : PropertyKind::Enum;
                for (const core::EnumValue& value : core::Enumerators(type))
                    info.Choices.PushBack(PropertyChoice{ReadablePropertyName(core::StringView(reinterpret_cast<const char8_t*>(value.name))), value.value});
                break;
            case Shape::Float2:
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(u8"Float2");
                break;
            case Shape::Float3:
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(u8"Float3");
                break;
            case Shape::Float4:
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(u8"Float4");
                break;
            case Shape::Quaternion:
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(u8"Float3"); // Euler degrees
                break;
            case Shape::Color:
                info.Kind = PropertyKind::Color;
                break;
            case Shape::Curve:
                info.Kind = PropertyKind::Curve;
                info.MaxCount = PartCapacity(type, FindCurveType(core::StringView(reinterpret_cast<const char8_t*>(type.name)))->Keys.AsView());
                break;
            case Shape::Gradient:
            {
                info.Kind = PropertyKind::Gradient;
                const ReflectedGradientParts& parts = *FindGradientType(core::StringView(reinterpret_cast<const char8_t*>(type.name)));
                const u32 colors = PartCapacity(type, parts.Colors.AsView());
                const u32 alphas = PartCapacity(type, parts.Alphas.AsView());
                info.MaxCount = colors == 0 ? alphas : (alphas == 0 ? colors : core::Min(colors, alphas)); // one most for both kinds
                break;
            }
            case Shape::Group: // its type's name, for an editor of its own (a Color in T4); else its rows
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(reinterpret_cast<const char8_t*>(type.name));
                break;
            case Shape::List:
            {
                info.Kind = PropertyKind::List;
                const core::ContainerInfo& container = *type.container;
                const bool polymorphic = core::IsPolymorphicContainer(container);
                if (!info.ReadOnly)
                    info.ListOps = static_cast<u8>(((polymorphic ? container.createElement != nullptr : container.emplaceDefault != nullptr) ? PropertyListAdd : 0) |
                                                   (container.removeAt != nullptr ? PropertyListRemove : 0) |
                                                   (container.moveElement != nullptr ? PropertyListMove : 0));
                if (polymorphic && container.elementType != nullptr)
                    for (const core::TypeInfo* concrete : CreatableTypes(container))
                        info.ElementTypes.PushBack(core::String(TypeShownName(*concrete)));
                info.MaxCount = static_cast<u32>(core::ContainerCapacity(container)); // a BoundedArray's N
                break;
            }
            case Shape::Other:
                info.Kind = PropertyKind::Group;
                info.Hint = core::String(reinterpret_cast<const char8_t*>(type.name));
                break;
            }
        }
        // A polymorphic list's types an add makes: those deriving from its base its factory takes.
        [[nodiscard]] core::Array<const core::TypeInfo*> CreatableTypes(const core::ContainerInfo& container) const
        {
            core::Array<const core::TypeInfo*> derived(m_allocator);
            core::Array<const core::TypeInfo*> out(m_allocator);
            if (container.elementType == nullptr)
                return out;
            core::EnumerateDerived(*container.elementType, derived);
            for (const core::TypeInfo* type : derived)
                if (core::ContainerCanCreateElement(container, *type))
                    out.PushBack(type);
            return out;
        }
        [[nodiscard]] static core::StringView TypeShownName(const core::TypeInfo& type)
        {
            return core::TypeAttrString(type, "displayName", core::StringView(reinterpret_cast<const char8_t*>(type.name)));
        }
        // A list's elements, the fewest any object has, each named by its index (and an object's
        // by its type's name).
        void ListElements(core::StringView path, core::Array<PropertyInfo>& out) const
        {
            usize count = ~usize{0};
            for (usize o = 0; o < m_objects.Size(); ++o)
                count = core::Min(count, static_cast<usize>(GetValue(path, o).AsInt()));
            if (m_objects.IsEmpty())
                return;
            for (usize i = 0; i < count; ++i)
            {
                const core::String element = core::Format(u8"{}.{}", path, i);
                Target target;
                if (!Resolve(0, element.AsView(), target) || target.Type == nullptr)
                    continue;
                PropertyInfo info;
                info.Name = core::Format(u8"{}", i);
                info.ReadOnly = target.ReadOnly;
                DescribeType(*target.Type, false, info);
                const bool object = info.Kind == PropertyKind::Group && target.Address != nullptr;
                info.DisplayName = object ? core::Format(u8"{} {}", TypeShownName(*target.Type), i + 1) : core::Format(u8"Element {}", i + 1);
                out.PushBack(core::Move(info));
            }
        }
        [[nodiscard]] static const core::String* StringAttribute(const core::PropertyInfo& property, const char8_t* key)
        {
            const core::Attribute* attribute = core::FindAttribute(property, core::StringView(key));
            return attribute != nullptr ? attribute->value.TryGet<core::String>() : nullptr;
        }
        // `visibleWhen` ("prop", or "prop=1,2" of its raw integer): a sibling's value, in every object.
        bool Holds(core::StringView group, core::StringView condition) const
        {
            usize eq = 0;
            while (eq < condition.Size() && condition[eq] != u8'=')
                ++eq;
            if (eq == 0)
                return true;
            const core::String sibling = JoinPropertyPath(group, condition.SubStr(0, eq));
            const auto matches = [&](i64 value)
            {
                if (eq == condition.Size())
                    return value != 0;
                usize start = eq + 1;
                while (start <= condition.Size())
                {
                    usize end = start;
                    while (end < condition.Size() && condition[end] != u8',')
                        ++end;
                    const core::Optional<i64> listed = core::ParseInt(core::Trim(condition.SubStr(start, end - start)));
                    if (listed.HasValue() && listed.Value() == value)
                        return true;
                    start = end + 1;
                }
                return false;
            };
            for (usize o = 0; o < m_objects.Size(); ++o)
            {
                const Variant value = GetValue(sibling.AsView(), o);
                if (!matches(value.GetType() == Variant::Type::Bool ? (value.AsBool() ? 1 : 0) : value.AsInt()))
                    return false;
            }
            return true;
        }
        static void ListHdrParts(core::Array<PropertyInfo>& out)
        {
            PropertyInfo color;
            color.Name = core::String(u8"color");
            color.DisplayName = core::String(u8"Color");
            color.Kind = PropertyKind::Color;
            color.ShowsAlpha = false;
            out.PushBack(core::Move(color));
            PropertyInfo intensity;
            intensity.Name = core::String(u8"intensity");
            intensity.DisplayName = core::String(u8"Intensity");
            intensity.Kind = PropertyKind::Float;
            intensity.Hint = core::String(u8"stops");
            out.PushBack(core::Move(intensity));
        }
        static void ListParts(Shape shape, core::Array<PropertyInfo>& out)
        {
            const char8_t* const floats[] = {u8"x", u8"y", u8"z", u8"w"};
            const char8_t* const shownFloats[] = {u8"X", u8"Y", u8"Z", u8"W"};
            const char8_t* const angles[] = {u8"pitch", u8"yaw", u8"roll"};
            const char8_t* const shownAngles[] = {u8"Pitch", u8"Yaw", u8"Roll"};
            const usize count = shape == Shape::Float2 ? 2 : (shape == Shape::Float4 ? 4 : 3);
            for (usize i = 0; i < count; ++i)
            {
                PropertyInfo info;
                const bool euler = shape == Shape::Quaternion;
                info.Name = core::String(euler ? angles[i] : floats[i]);
                info.DisplayName = core::String(euler ? shownAngles[i] : shownFloats[i]);
                info.Kind = PropertyKind::Float;
                info.Step = euler ? 1.0 : 0.01;
                out.PushBack(core::Move(info));
            }
        }

        // === Values ===

        // A value at a place: through its address, else its property's getter.
        [[nodiscard]] Variant Read(const Target& target) const
        {
            if (target.Type == nullptr)
                return Variant{};
            const Shape shape = ShapeOf(*target.Type);
            if (target.Part == kHdrColorPart)
            {
                core::Float4 parts{};
                return ReadCompound(target, shape, parts) ? Variant(core::Color{parts.x, parts.y, parts.z, 1.0f}) : Variant{};
            }
            if (target.Part >= 0)
                return Variant(PartOf(target, shape));
            if (shape == Shape::List)
                return target.Address != nullptr ? Variant(static_cast<i64>(core::ContainerSize(*target.Type->container, core::Instance(target.Address, target.Type))))
                                                 : Variant{};
            if (shape == Shape::Curve)
                return ReadCurve(target);
            if (shape == Shape::Gradient)
                return ReadGradient(target);
            if (target.Address != nullptr)
                return ReadAt(target.Address, *target.Type, shape);
            if (target.Element && !target.List.IsEmpty())
                return FromCore(core::ContainerGetAt(*target.List.Type()->container, target.List, target.Index), shape, *target.Type);
            if (target.Property != nullptr && target.Property->get != nullptr && !target.Owner.IsEmpty())
                return FromCore(target.Property->get(target.Owner), shape, *target.Type);
            return Variant{};
        }
        // Writes `value` to a place; false when it cannot be written.
        bool WriteTarget(const Target& target, const Variant& value) const
        {
            if (target.Type == nullptr || target.ReadOnly || value.IsEmpty())
                return false;
            const Shape shape = ShapeOf(*target.Type);
            if (target.Part == kHdrColorPart)
            {
                core::Float4 parts{};
                if (!ReadCompound(target, shape, parts))
                    return false;
                const core::Color color = value.AsColor();
                return WriteCompound(target, shape, core::Float4{color.r, color.g, color.b, parts.w});
            }
            if (target.Part >= 0)
                return SetPart(target, shape, value.AsFloat());
            if (shape == Shape::Curve)
                return value.GetType() == Variant::Type::Curve && WriteCurve(target, value.AsCurve());
            if (shape == Shape::Gradient)
                return value.GetType() == Variant::Type::Gradient && WriteGradient(target, value.AsGradient());
            if (target.Address != nullptr)
                return WriteAt(target.Address, *target.Type, shape, value);
            if (target.Element && !target.List.IsEmpty())
            {
                const core::Variant boxed = ToCore(value, shape, *target.Type);
                return boxed.Type() != nullptr && core::ContainerSetAt(*target.List.Type()->container, target.List, target.Index, boxed).IsOk();
            }
            if (target.Property != nullptr && !target.Owner.IsEmpty())
            {
                const core::Variant boxed = ToCore(value, shape, *target.Type);
                return boxed.Type() != nullptr && core::SetProperty(*target.Property, target.Owner, boxed).IsOk();
            }
            return false;
        }
        void WriteValue(core::StringView path, usize object, const PropertyWrite& write) const
        {
            Target target;
            if (Resolve(object, path, target))
                (void)WriteTarget(target, ApplyPropertyWrite(Read(target), write));
        }

        [[nodiscard]] static Variant ReadAt(const void* address, const core::TypeInfo& type, Shape shape)
        {
            const auto is = [&type]<typename T>() { return &type == &core::TypeOf<T>() || type.id == core::TypeOf<T>().id; };
            switch (shape)
            {
            case Shape::Bool:
                return Variant(*static_cast<const bool*>(address));
            case Shape::Integer:
                if (is.template operator()<i8>())
                    return Variant(static_cast<i64>(*static_cast<const i8*>(address)));
                if (is.template operator()<u8>())
                    return Variant(static_cast<i64>(*static_cast<const u8*>(address)));
                if (is.template operator()<i16>())
                    return Variant(static_cast<i64>(*static_cast<const i16*>(address)));
                if (is.template operator()<u16>())
                    return Variant(static_cast<i64>(*static_cast<const u16*>(address)));
                if (is.template operator()<i32>())
                    return Variant(static_cast<i64>(*static_cast<const i32*>(address)));
                if (is.template operator()<u32>())
                    return Variant(static_cast<i64>(*static_cast<const u32*>(address)));
                if (is.template operator()<u64>())
                    return Variant(static_cast<i64>(*static_cast<const u64*>(address)));
                return Variant(*static_cast<const i64*>(address));
            case Shape::Float:
                return is.template operator()<f32>() ? Variant(static_cast<f64>(*static_cast<const f32*>(address))) : Variant(*static_cast<const f64*>(address));
            case Shape::String:
                return Variant(static_cast<const core::String*>(address)->AsView());
            case Shape::Enum:
                return Variant(core::ReadEnumValue(address, type));
            case Shape::Color:
                return Variant(*static_cast<const core::Color*>(address));
            default:
                return Variant{};
            }
        }
        [[nodiscard]] static bool WriteAt(void* address, const core::TypeInfo& type, Shape shape, const Variant& value)
        {
            const auto is = [&type]<typename T>() { return &type == &core::TypeOf<T>() || type.id == core::TypeOf<T>().id; };
            switch (shape)
            {
            case Shape::Bool:
                *static_cast<bool*>(address) = value.AsBool();
                return true;
            case Shape::Integer:
            {
                const i64 v = value.AsInt();
                if (is.template operator()<i8>())
                    *static_cast<i8*>(address) = static_cast<i8>(v);
                else if (is.template operator()<u8>())
                    *static_cast<u8*>(address) = static_cast<u8>(v);
                else if (is.template operator()<i16>())
                    *static_cast<i16*>(address) = static_cast<i16>(v);
                else if (is.template operator()<u16>())
                    *static_cast<u16*>(address) = static_cast<u16>(v);
                else if (is.template operator()<i32>())
                    *static_cast<i32*>(address) = static_cast<i32>(v);
                else if (is.template operator()<u32>())
                    *static_cast<u32*>(address) = static_cast<u32>(v);
                else if (is.template operator()<u64>())
                    *static_cast<u64*>(address) = static_cast<u64>(v);
                else
                    *static_cast<i64*>(address) = v;
                return true;
            }
            case Shape::Float:
                if (is.template operator()<f32>())
                    *static_cast<f32*>(address) = static_cast<f32>(value.AsFloat());
                else
                    *static_cast<f64*>(address) = value.AsFloat();
                return true;
            case Shape::String:
                *static_cast<core::String*>(address) = core::String(value.AsString());
                return true;
            case Shape::Enum:
                core::WriteEnumValue(address, type, value.AsInt());
                return true;
            case Shape::Color:
                *static_cast<core::Color*>(address) = value.AsColor();
                return true;
            default:
                return false;
            }
        }
        // A computed property's core value as the grid's, and back.
        [[nodiscard]] static Variant FromCore(const core::Variant& value, Shape shape, const core::TypeInfo& type)
        {
            if (value.Type() == nullptr || value.ValuePointer() == nullptr)
                return Variant{};
            if (shape == Shape::Enum)
                return Variant(value.AsEnumInt());
            return ReadAt(value.ValuePointer(), type, shape);
        }
        [[nodiscard]] static core::Variant ToCore(const Variant& value, Shape shape, const core::TypeInfo& type)
        {
            const auto is = [&type]<typename T>() { return &type == &core::TypeOf<T>() || type.id == core::TypeOf<T>().id; };
            switch (shape)
            {
            case Shape::Bool:
                return core::Variant::From<bool>(value.AsBool());
            case Shape::Integer:
                if (is.template operator()<i32>())
                    return core::Variant::From<i32>(static_cast<i32>(value.AsInt()));
                if (is.template operator()<u32>())
                    return core::Variant::From<u32>(static_cast<u32>(value.AsInt()));
                if (is.template operator()<u64>())
                    return core::Variant::From<u64>(static_cast<u64>(value.AsInt()));
                if (is.template operator()<i64>())
                    return core::Variant::From<i64>(value.AsInt());
                return core::Variant{};
            case Shape::Float:
                return is.template operator()<f32>() ? core::Variant::From<f32>(static_cast<f32>(value.AsFloat())) : core::Variant::From<f64>(value.AsFloat());
            case Shape::String:
                return core::Variant::From<core::String>(core::String(value.AsString()));
            case Shape::Color:
                return core::Variant::From<core::Color>(value.AsColor());
            default:
                return core::Variant{}; // an enum or a compound: through its address alone
            }
        }

        // A Float's part, or a Quaternion's Euler angle in degrees.
        [[nodiscard]] f64 PartOf(const Target& target, Shape shape) const
        {
            core::Float4 parts{};
            if (!ReadCompound(target, shape, parts))
                return 0.0;
            const f32 values[] = {parts.x, parts.y, parts.z, parts.w};
            return static_cast<f64>(values[target.Part]);
        }
        bool SetPart(const Target& target, Shape shape, f64 value) const
        {
            core::Float4 parts{};
            if (!ReadCompound(target, shape, parts))
                return false;
            f32* slots[] = {&parts.x, &parts.y, &parts.z, &parts.w};
            *slots[target.Part] = static_cast<f32>(value);
            return WriteCompound(target, shape, parts);
        }
        // A Float2/3/4 as x, y, z, w; a Quaternion as its Euler degrees (pitch, yaw, roll).
        bool ReadCompound(const Target& target, Shape shape, core::Float4& out) const
        {
            Target whole = target;
            whole.Part = -1;
            const void* address = whole.Address;
            core::Variant boxed;
            if (address == nullptr && whole.Property != nullptr && !whole.Owner.IsEmpty())
            {
                boxed = whole.Property->get(whole.Owner);
                address = boxed.ValuePointer();
            }
            if (address == nullptr)
                return false;
            switch (shape)
            {
            case Shape::Float2:
            {
                const core::Float2& v = *static_cast<const core::Float2*>(address);
                out = core::Float4{v.x, v.y, 0.0f, 0.0f};
                return true;
            }
            case Shape::Float3:
            {
                const core::Float3& v = *static_cast<const core::Float3*>(address);
                out = core::Float4{v.x, v.y, v.z, 0.0f};
                return true;
            }
            case Shape::Float4:
                out = *static_cast<const core::Float4*>(address);
                return true;
            case Shape::Quaternion:
            {
                f32 yaw = 0.0f, pitch = 0.0f, roll = 0.0f;
                core::ToYawPitchRoll(*static_cast<const core::Quaternion*>(address), yaw, pitch, roll);
                out = core::Float4{core::RadiansToDegrees(pitch), core::RadiansToDegrees(yaw), core::RadiansToDegrees(roll), 0.0f};
                return true;
            }
            default:
                return false;
            }
        }
        bool WriteCompound(const Target& target, Shape shape, const core::Float4& parts) const
        {
            Target whole = target;
            whole.Part = -1;
            if (whole.ReadOnly)
                return false;
            const auto store = [&]<typename T>(const T& value) -> bool
            {
                if (whole.Address != nullptr)
                {
                    *static_cast<T*>(whole.Address) = value;
                    return true;
                }
                return whole.Property != nullptr && !whole.Owner.IsEmpty() &&
                       core::SetProperty(*whole.Property, whole.Owner, core::Variant::From<T>(value)).IsOk();
            };
            switch (shape)
            {
            case Shape::Float2:
                return store(core::Float2{parts.x, parts.y});
            case Shape::Float3:
                return store(core::Float3{parts.x, parts.y, parts.z});
            case Shape::Float4:
                return store(parts);
            case Shape::Quaternion:
                return store(core::FromYawPitchRoll(core::DegreesToRadians(parts.y), core::DegreesToRadians(parts.x), core::DegreesToRadians(parts.z)));
            default:
                return false;
            }
        }

        // === Text: each object's value at a path, written and read with the text format ===

        [[nodiscard]] core::String WriteState(core::StringView path, usize object) const
        {
            if (m_format == nullptr)
                return core::String{};
            Target target;
            if (!Resolve(object, path, target))
                return core::String{};
            const ReflectedPropertySource* self = this;
            return m_format->Write([self, target](core::ISerializer& ar) mutable { self->SerializeTarget(ar, "value", target); });
        }
        bool ReadState(core::StringView path, usize object, core::StringView text)
        {
            Target target;
            if (m_format == nullptr || !Resolve(object, path, target))
                return false;
            const ReflectedPropertySource* self = this;
            return m_format->Read(text, [self, target](core::ISerializer& ar) mutable { self->SerializeTarget(ar, "value", target); });
        }
        // A place either way under `key`: a value as its type, a Float or a Quaternion as Core's
        // own, a group as an object of its properties by name.
        void SerializeTarget(core::ISerializer& ar, const char* key, const Target& target) const
        {
            if (target.Type == nullptr)
                return;
            const bool reading = ar.Mode() == core::SerializeMode::Read;
            const Shape shape = ShapeOf(*target.Type);
            if (target.Part == kHdrColorPart)
            {
                core::Color value = Read(target).AsColor();
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value));
                return;
            }
            if (target.Part >= 0)
            {
                f64 value = PartOf(target, shape);
                core::Serialize(ar, key, value);
                if (reading)
                    (void)SetPart(target, shape, value);
                return;
            }
            switch (shape)
            {
            case Shape::Bool:
            {
                bool value = Read(target).AsBool();
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value));
                return;
            }
            case Shape::Integer:
            case Shape::Enum:
            {
                i64 value = Read(target).AsInt();
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value));
                return;
            }
            case Shape::Float:
            {
                f64 value = Read(target).AsFloat();
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value));
                return;
            }
            case Shape::String:
            {
                core::String value(Read(target).AsString());
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value.AsView()));
                return;
            }
            case Shape::Color:
            {
                core::Color value = Read(target).AsColor();
                core::Serialize(ar, key, value);
                if (reading)
                    (void)WriteTarget(target, Variant(value));
                return;
            }
            case Shape::Float2:
            case Shape::Float3:
            case Shape::Float4:
            case Shape::Quaternion:
            {
                core::Float4 parts{};
                (void)ReadCompound(target, shape, parts);
                if (shape == Shape::Float2)
                {
                    core::Float2 value{parts.x, parts.y};
                    core::Serialize(ar, key, value);
                    parts = core::Float4{value.x, value.y, 0.0f, 0.0f};
                }
                else if (shape == Shape::Float4)
                    core::Serialize(ar, key, parts);
                else
                {
                    core::Float3 value{parts.x, parts.y, parts.z}; // a Quaternion as its Euler degrees, as the grid shows it
                    core::Serialize(ar, key, value);
                    parts = core::Float4{value.x, value.y, value.z, 0.0f};
                }
                if (reading)
                    (void)WriteCompound(target, shape, parts);
                return;
            }
            case Shape::List:
            {
                if (target.Address == nullptr)
                    return;
                SerializeList(ar, key, target);
                return;
            }
            case Shape::Curve: // written as the struct it is: Core reflects its keys and stops
            case Shape::Gradient:
            case Shape::Group:
            {
                if (target.Address == nullptr)
                    return;
                ar.Key(key);
                ar.BeginObject();
                const core::Instance owner(target.Address, target.Type);
                for (const core::TypeInfo* t = target.Type; t != nullptr; t = t->base)
                    for (u32 i = 0; i < t->propertyCount; ++i)
                    {
                        const core::PropertyInfo& property = t->properties[i];
                        Target child;
                        child.Owner = owner;
                        child.Property = &property;
                        child.Type = property.type;
                        child.Address = property.address != nullptr ? property.address(owner) : nullptr;
                        child.ReadOnly = target.ReadOnly || (static_cast<u32>(property.flags) & static_cast<u32>(core::PropertyFlags::ReadOnly)) != 0;
                        if (child.ReadOnly && reading)
                            continue;
                        if (reading && !ar.HasKey(property.name))
                            continue;
                        SerializeTarget(ar, property.name, child);
                    }
                ar.EndObject();
                return;
            }
            default:
                return;
            }
        }

        // A list either way: its count, each polymorphic element's type, then each element. Read,
        // the list takes the count (made or removed at its end) before its elements are read.
        void SerializeList(core::ISerializer& ar, const char* key, const Target& target) const
        {
            const bool reading = ar.Mode() == core::SerializeMode::Read;
            const core::ContainerInfo& container = *target.Type->container;
            const core::Instance list(target.Address, target.Type);
            const bool polymorphic = core::IsPolymorphicContainer(container);
            ar.Key(key);
            ar.BeginObject();
            i64 count = static_cast<i64>(core::ContainerSize(container, list));
            core::Serialize(ar, "count", count);
            if (reading && !target.ReadOnly)
            {
                // Polymorphic: rebuilt from the types written; homogeneous: grown or cut to the count.
                if (polymorphic)
                {
                    while (core::ContainerSize(container, list) != 0)
                        (void)core::ContainerRemoveAt(container, list, core::ContainerSize(container, list) - 1);
                    for (i64 i = 0; i < count; ++i)
                    {
                        core::String type;
                        const core::FixedArray<char, 24> typeKey = ElementKey(i, true);
                        core::Serialize(ar, typeKey.items, type);
                        for (const core::TypeInfo* concrete : CreatableTypes(container))
                            if (core::StringView(reinterpret_cast<const char8_t*>(concrete->name)) == type.AsView())
                            {
                                (void)core::ContainerCreateElement(container, list, static_cast<usize>(i), *concrete);
                                break;
                            }
                    }
                }
                else
                {
                    while (static_cast<i64>(core::ContainerSize(container, list)) > count && count >= 0)
                        (void)core::ContainerRemoveAt(container, list, core::ContainerSize(container, list) - 1);
                    while (static_cast<i64>(core::ContainerSize(container, list)) < count)
                        if (core::ContainerEmplaceDefault(container, list, core::ContainerSize(container, list)).IsEmpty())
                            break; // a bounded array at its most
                }
            }
            else if (polymorphic)
                for (i64 i = 0; i < count; ++i)
                {
                    const core::Instance element = core::ContainerAddressAt(container, list, static_cast<usize>(i));
                    core::String type(element.IsEmpty() ? core::StringView{} : core::StringView(reinterpret_cast<const char8_t*>(element.Type()->name)));
                    const core::FixedArray<char, 24> typeKey = ElementKey(i, true);
                    core::Serialize(ar, typeKey.items, type);
                }
            const usize size = core::ContainerSize(container, list);
            for (usize i = 0; i < size; ++i)
            {
                Target element;
                element.List = list;
                element.Index = i;
                element.Element = true;
                element.ReadOnly = target.ReadOnly;
                element.Type = container.elementType;
                const core::Instance at = core::ContainerAddressAt(container, list, i);
                if (!at.IsEmpty())
                {
                    element.Address = at.Pointer();
                    element.Type = at.Type();
                }
                const core::FixedArray<char, 24> elementKey = ElementKey(static_cast<i64>(i), false);
                if (reading && !ar.HasKey(elementKey.items))
                    continue;
                if (element.Address == nullptr && element.Type != nullptr && ShapeOf(*element.Type) == Shape::Group)
                {
                    // A struct element with no address (a BoundedArray's): a copy written, or read
                    // and set back.
                    core::Variant copy = core::ContainerGetAt(container, list, i);
                    if (copy.ValuePointer() == nullptr)
                        continue;
                    Target held = element;
                    held.Address = copy.ValuePointer();
                    held.Element = false;
                    SerializeTarget(ar, elementKey.items, held);
                    if (reading && !target.ReadOnly)
                        (void)core::ContainerSetAt(container, list, i, copy);
                    continue;
                }
                SerializeTarget(ar, elementKey.items, element);
            }
            ar.EndObject();
        }
        // "e3" for element 3, "t3" for its type: keys the serializer reads as C strings.
        [[nodiscard]] static core::FixedArray<char, 24> ElementKey(i64 index, bool type)
        {
            core::FixedArray<char, 24> key;
            key.Add(type ? 't' : 'e');
            const core::String digits = core::Format(u8"{}", index);
            for (usize i = 0; i < digits.Size() && key.Size() + 1 < key.CapacityValue(); ++i)
                key.Add(static_cast<char>(digits[i]));
            key.Add('\0'); // read as a C string (items)
            return key;
        }

        // Each value at `path` and under it in object `object` given its default; a list whole, as
        // the type's instance has it. Whether anything changed.
        bool RevertUnder(core::StringView path, usize object)
        {
            Target target;
            if (!Resolve(object, path, target) || target.Type == nullptr || target.ReadOnly)
                return false;
            const Shape shape = target.Part >= 0 ? Shape::Float : ShapeOf(*target.Type);
            if (shape == Shape::List)
            {
                if (!m_typeDefault || m_format == nullptr)
                    return false;
                const core::String before = WriteState(path, object);
                Target byDefault;
                if (!ResolveIn(core::Instance(m_typeDefault.Get(), m_objects[0].Type()), path, byDefault))
                    return false;
                const ReflectedPropertySource* self = this;
                const core::String text = m_format->Write([self, byDefault](core::ISerializer& ar) mutable { self->SerializeTarget(ar, "value", byDefault); });
                (void)ReadState(path, object, text.AsView());
                return WriteState(path, object) != before;
            }
            core::Array<PropertyInfo> children(m_allocator);
            if (shape == Shape::Group || shape == Shape::Float2 || shape == Shape::Float3 || shape == Shape::Float4 || shape == Shape::Quaternion)
            {
                GetProperties(path, children);
                bool changed = false;
                for (const PropertyInfo& child : children)
                    changed = RevertUnder(JoinPropertyPath(path, child.Name.AsView()).AsView(), object) || changed;
                return changed;
            }
            const Variant byDefault = GetDefault(path, object);
            const Variant now = Read(target);
            if (byDefault.IsEmpty() || now.Compare(byDefault) == 0)
                return false;
            return WriteTarget(target, byDefault);
        }

        // What a copy is, so a paste takes only its like: a Float's name (a Quaternion's Euler
        // degrees a Float3, as the grid shows it), a struct's type, a list of its elements' type,
        // a value's kind.
        [[nodiscard]] core::String ShapeTag(const Target& target) const
        {
            if (target.Part == kHdrColorPart)
                return core::String(u8"Color");
            if (target.Part >= 0)
                return core::String(u8"number");
            if (target.Hdr)
                return core::String(u8"ColorHdr");
            switch (ShapeOf(*target.Type))
            {
            case Shape::Bool:
                return core::String(u8"bool");
            case Shape::Integer:
            case Shape::Enum:
                return core::String(u8"integer");
            case Shape::Float:
                return core::String(u8"number");
            case Shape::String:
                return core::String(u8"text");
            case Shape::Float2:
                return core::String(u8"Float2");
            case Shape::Float3:
            case Shape::Quaternion:
                return core::String(u8"Float3");
            case Shape::Float4:
                return core::String(u8"Float4");
            case Shape::Color:
                return core::String(u8"Color");
            case Shape::Curve:
            case Shape::Gradient:
            case Shape::Group:
                return core::String(reinterpret_cast<const char8_t*>(target.Type->name));
            case Shape::List:
            {
                const core::TypeInfo* element = target.Type->container->elementType;
                return core::Format(u8"list of {}", element != nullptr ? core::StringView(reinterpret_cast<const char8_t*>(element->name)) : core::StringView(u8"?"));
            }
            default:
                return core::String{};
            }
        }

        // One object's list changed as `edit` asks.
        bool ChangeList(const Target& target, const ListEdit& edit) const
        {
            const core::ContainerInfo& container = *target.Type->container;
            const core::Instance list(target.Address, target.Type);
            const usize size = core::ContainerSize(container, list);
            switch (edit.Kind)
            {
            case ListEdit::Op::Insert:
            {
                const usize at = core::Min(edit.Index, size);
                if (core::IsPolymorphicContainer(container))
                {
                    for (const core::TypeInfo* concrete : CreatableTypes(container))
                        if (TypeShownName(*concrete) == edit.ElementType.AsView() || (edit.ElementType.Size() == 0))
                            return !core::ContainerCreateElement(container, list, at, *concrete).IsEmpty();
                    return false;
                }
                return !core::ContainerEmplaceDefault(container, list, at).IsEmpty();
            }
            case ListEdit::Op::Remove:
                return edit.Index < size && core::ContainerRemoveAt(container, list, edit.Index).IsOk();
            case ListEdit::Op::Move:
                return edit.Index < size && edit.To < size && edit.Index != edit.To && core::ContainerMoveElement(container, list, edit.Index, edit.To).IsOk();
            }
            return false;
        }
        [[nodiscard]] static core::String ListWords(core::StringView path, const ListEdit& edit)
        {
            switch (edit.Kind)
            {
            case ListEdit::Op::Insert:
                return core::Format(u8"Added to {}", path);
            case ListEdit::Op::Remove:
                return core::Format(u8"Removed from {}", path);
            default:
                return core::Format(u8"Moved in {}", path);
            }
        }

        // === Curves and gradients: the parts the application named, read and written whole ===

        // The capacity of the list property `name` of `type` (0: no limit, or no such list).
        [[nodiscard]] static u32 PartCapacity(const core::TypeInfo& type, core::StringView name)
        {
            const core::PropertyInfo* property = FindPropertyNamed(type, name);
            return property != nullptr && property->type != nullptr && property->type->container != nullptr
                       ? static_cast<u32>(core::ContainerCapacity(*property->type->container))
                       : 0u;
        }
        // The list property `name` of the struct at `target`, as a list instance; empty when absent.
        [[nodiscard]] core::Instance PartList(const Target& target, core::StringView name) const
        {
            if (target.Address == nullptr || target.Type == nullptr)
                return core::Instance{};
            const core::PropertyInfo* property = FindPropertyNamed(*target.Type, name);
            if (property == nullptr || property->type == nullptr || property->type->container == nullptr || property->address == nullptr)
                return core::Instance{};
            void* address = property->address(core::Instance(target.Address, target.Type));
            return address != nullptr ? core::Instance(address, property->type) : core::Instance{};
        }
        // The list's elements as `T` (Core's key or stop), by value.
        template <typename T>
        static void ReadElements(const core::Instance& list, core::Array<T>& out)
        {
            if (list.IsEmpty())
                return;
            const core::ContainerInfo& container = *list.Type()->container;
            for (usize i = 0; i < core::ContainerSize(container, list); ++i)
            {
                const core::Variant element = core::ContainerGetAt(container, list, i);
                if (const T* typed = element.TryGet<T>())
                    out.PushBack(*typed);
            }
        }
        // The list made `values`: grown or cut to their count (a bounded array to its most), then
        // each set. False when it could not hold them all.
        template <typename T>
        static bool WriteElements(const core::Instance& list, core::Span<const T> values)
        {
            if (list.IsEmpty())
                return false;
            const core::ContainerInfo& container = *list.Type()->container;
            while (core::ContainerSize(container, list) > values.Size())
                if (!core::ContainerRemoveAt(container, list, core::ContainerSize(container, list) - 1).IsOk())
                    return false;
            while (core::ContainerSize(container, list) < values.Size())
                if (core::ContainerEmplaceDefault(container, list, core::ContainerSize(container, list)).IsEmpty())
                    break; // at its most
            bool all = core::ContainerSize(container, list) == values.Size();
            for (usize i = 0; i < core::ContainerSize(container, list); ++i)
                all = core::ContainerSetAt(container, list, i, core::Variant::From<T>(values[i])).IsOk() && all;
            return all;
        }
        [[nodiscard]] Variant ReadCurve(const Target& target) const
        {
            const ReflectedCurveParts* parts = FindCurveType(core::StringView(reinterpret_cast<const char8_t*>(target.Type->name)));
            const core::Instance list = parts != nullptr ? PartList(target, parts->Keys.AsView()) : core::Instance{};
            if (list.IsEmpty())
                return Variant{};
            core::Array<core::CurveKey> keys(m_allocator);
            ReadElements(list, keys);
            return Variant::FromCurve(keys.AsSpan());
        }
        bool WriteCurve(const Target& target, core::Span<const core::CurveKey> keys) const
        {
            const ReflectedCurveParts* parts = FindCurveType(core::StringView(reinterpret_cast<const char8_t*>(target.Type->name)));
            return parts != nullptr && WriteElements(PartList(target, parts->Keys.AsView()), keys);
        }
        [[nodiscard]] Variant ReadGradient(const Target& target) const
        {
            const ReflectedGradientParts* parts = FindGradientType(core::StringView(reinterpret_cast<const char8_t*>(target.Type->name)));
            if (parts == nullptr || target.Address == nullptr)
                return Variant{};
            ColorGradient gradient;
            ReadElements(PartList(target, parts->Colors.AsView()), gradient.Colors);
            ReadElements(PartList(target, parts->Alphas.AsView()), gradient.Alphas);
            if (const core::PropertyInfo* blend = FindPropertyNamed(*target.Type, parts->Interpolation.AsView()); blend != nullptr && blend->address != nullptr)
                if (const void* address = blend->address(core::Instance(target.Address, target.Type)))
                    gradient.Interpolation = static_cast<core::GradientInterpolation>(core::ReadEnumValue(address, *blend->type));
            return Variant(gradient);
        }
        bool WriteGradient(const Target& target, const ColorGradient& gradient) const
        {
            const ReflectedGradientParts* parts = FindGradientType(core::StringView(reinterpret_cast<const char8_t*>(target.Type->name)));
            if (parts == nullptr || target.Address == nullptr)
                return false;
            bool ok = WriteElements(PartList(target, parts->Colors.AsView()), gradient.Colors.AsSpan());
            ok = WriteElements(PartList(target, parts->Alphas.AsView()), gradient.Alphas.AsSpan()) && ok;
            if (const core::PropertyInfo* blend = FindPropertyNamed(*target.Type, parts->Interpolation.AsView()); blend != nullptr && blend->address != nullptr)
                if (void* address = blend->address(core::Instance(target.Address, target.Type)))
                    core::WriteEnumValue(address, *blend->type, static_cast<i64>(gradient.Interpolation));
            return ok;
        }
        // A property's change may show or hide others (visibleWhen): the properties changed.
        void Changed(core::StringView) { NotifyPropertiesChanged(); }

        struct Original
        {
            core::String Path;
            core::Array<Variant> Values;     // each object's, for a cancel
            core::Array<core::String> States; // each object's text, for the change
        };
        const Original* FindOriginal(core::StringView path) const
        {
            for (const Original& original : m_originals)
                if (original.Path.AsView() == path)
                    return &original;
            return nullptr;
        }
        void DropOriginal(core::StringView path)
        {
            for (usize i = 0; i < m_originals.Size(); ++i)
                if (m_originals[i].Path.AsView() == path)
                {
                    m_originals.RemoveAt(i);
                    return;
                }
        }

        core::IAllocator& m_allocator;
        core::Array<core::Instance> m_objects;
        core::Array<Original> m_originals;
        IPropertyTextFormat* m_format = nullptr; // not owned
        struct Provider
        {
            DefaultProvider Default;
            core::String RevertText;
        };
        core::Array<Provider> m_providers;
        core::RefPtr<core::Object> m_typeDefault; // the type's defaults, made by its creator
        struct CurveType
        {
            core::String Name;
            ReflectedCurveParts Parts;
        };
        struct GradientType
        {
            core::String Name;
            ReflectedGradientParts Parts;
        };
        core::Array<CurveType> m_curveTypes;
        core::Array<GradientType> m_gradientTypes;
        core::Function<void(const ReflectedChange&)> m_onChange;
    };
}
