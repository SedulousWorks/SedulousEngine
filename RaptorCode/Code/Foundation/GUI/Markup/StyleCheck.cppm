// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_check partition
//
// What a sheet's declarations name that nothing takes (E1 of Specs/gui-lab-evolution-3.md): a cook
// warns of a typo (`colour: red`) the style pass would drop without a word. A name stands when the
// style table has it (a property or a shorthand), when it is a custom property (`--accent`), or
// when an element type registered now takes it by its CSS name (`nav-up`, a gamekit screen's
// `covers`): so the check asks the element types the tools register, not a list.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:style_check;

import foundation.core;
import :style_properties; // FindStyleProperty, ExpandStyleShorthand
import :style_rule;
import :style_sheet;
import :element_types;    // ElementTypes::ForEach
import :diagnostic;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// The CSS names the registered element types take as reflected properties (with their bases').
    [[nodiscard]] inline Array<core::String> RegisteredCssNames()
    {
        Array<core::String> names;
        const auto add = [&names](core::StringView name)
        {
            for (const core::String& known : names)
                if (known.AsView() == name)
                    return;
            names.PushBack(core::String(name));
        };
        ElementTypes::ForEach([&](core::StringView, const TypeInfo& element)
        {
            for (const TypeInfo* type = &element; type != nullptr; type = type->base)
                for (usize i = 0; i < PropertyCount(*type); ++i)
                    if (const Attribute* css = FindAttribute(PropertyAt(*type, i), u8"css"))
                        if (const core::String* name = css->value.TryGet<core::String>())
                            add(name->AsView());
        });
        return names;
    }

    /// Whether a declaration's `name` is one a style takes (see the partition's note).
    [[nodiscard]] inline bool IsKnownStyleName(core::StringView name, core::StringView value, const Array<core::String>& cssNames)
    {
        if (name.Size() > 2 && name[0] == u8'-' && name[1] == u8'-')
            return true; // a custom property
        if (FindStyleProperty(name) != nullptr)
            return true;
        Array<StyleLonghand> longhands;
        if (ExpandStyleShorthand(name, value, longhands) && !(longhands.Size() == 1 && longhands[0].Name.AsView() == name))
            return true;
        for (const core::String& known : cssNames)
            if (known.AsView() == name)
                return true;
        return false;
    }

    /// Says each declaration of `sheet`'s rules and keyframe stops whose name nothing takes, with
    /// its rule's line.
    inline void CheckStyleSheetNames(const StyleSheet& sheet, Array<GuiDiagnostic>& out)
    {
        const Array<core::String> cssNames = RegisteredCssNames();
        for (const StyleRule& rule : sheet.Rules())
            for (const StyleProperty& property : rule.Properties())
                if (!IsKnownStyleName(property.Name.AsView(), property.Value.AsView(), cssNames))
                    out.PushBack(GuiDiagnostic{GuiDiagnostic::Severity::Warning, rule.Line(),
                                               core::Format(u8"{} sets '{}', which no style or element takes", rule.SelectorText(),
                                                            property.Name.AsView())});
        for (const Keyframes& keyframes : sheet.AllKeyframes())
        {
            for (const KeyframeStop& stop : keyframes.Stops)
                for (const StyleProperty& property : stop.Properties)
                    if (property.Name.AsView() != core::StringView(u8"animation-timing-function") &&
                        !IsKnownStyleName(property.Name.AsView(), property.Value.AsView(), cssNames))
                        out.PushBack(GuiDiagnostic{GuiDiagnostic::Severity::Warning, 0,
                                                   core::Format(u8"@keyframes {} sets '{}', which no style takes", keyframes.Name.AsView(),
                                                                property.Name.AsView())});
        }
    }
}
