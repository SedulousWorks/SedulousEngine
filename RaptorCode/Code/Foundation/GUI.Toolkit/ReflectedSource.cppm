// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :reflected_source partition, what is left of it after the GUI.Toolkit port: what the
// GUI's reflection table (GuiTypeInfo: a type's [GuiProperty] properties, each with a get and a set)
// cannot carry. A property's attributes (displayName, description, range, visibleWhen, flags,
// noAlpha, hdrColor and with it the HDR colour's color and intensity parts), an enum's enumerators
// as choices, lists (Array, BoundedArray, a polymorphic Array<RefPtr<Base>> and the types an add
// makes) and their elements, value structs as groups, and the types an application registers as a
// curve or a gradient by their parts; with them, the list, element, HDR and registered-type
// branches of GetProperties, Step, Read, WriteTarget, SerializeTarget, RevertUnder and ShapeTag.
// The rest is Code/Foundation/Sedulous.GUI.Toolkit/src/ReflectedSource.bf (IPropertyTextFormat,
// ReflectedChange, ReadablePropertyName, ReflectedPropertySource over GuiTypeInfo: values, Float2/3/4,
// a Quaternion as Euler degrees, a node it holds as a group, Core's Curve and the GUI's
// ColorGradient as one value each, defaults, revert, copy and paste, Restore).

export namespace foundation::gui
{
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

    class ReflectedPropertySource : public IPropertySource
    {
    public:
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

    private:
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
        // An HDR colour's parts: its colour (rgb), its intensity (w).
        static constexpr i32 kHdrColorPart = 10;
        [[nodiscard]] static i32 HdrPartIndex(core::StringView segment)
        {
            if (segment == core::StringView(u8"color"))
                return kHdrColorPart;
            return segment == core::StringView(u8"intensity") ? 3 : -1;
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
    };
}
