// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the toolkit widgets' reflection: what markup, sheets and scripts set on them, and
// their registration as elements.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module foundation.gui.toolkit;

import foundation.core;
import foundation.gui;

namespace core = foundation::core;

namespace foundation::gui
{
    REFLECT_MEMBERS(ToolButton, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&ToolButton::ShowsText, &ToolButton::SetShowsText>("showsText").PropAttribute("css", core::String(u8"shows-text"));
        builder.AccessorProperty<&ToolButton::GetOverflowPriority, &ToolButton::SetOverflowPriority>("overflowPriority")
            .PropAttribute("css", core::String(u8"overflow-priority"));
        builder.Creator();
    }

    REFLECT_MEMBERS(ToolMenuButton, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&ToolMenuButton::IsSplit, &ToolMenuButton::SetSplit>("split").PropAttribute("css", core::String(u8"split"));
        builder.Creator();
    }

    REFLECT_MEMBERS(ToolBar, "rtti::gui::toolkit")
    {
        builder.Attribute("accessRole", core::String(u8"group")); // the core has no tool bar role yet
        builder.AccessorProperty<&ToolBar::GetOrientationName, &ToolBar::SetOrientationName>("orientation")
            .PropAttribute("css", core::String(u8"orientation"));
        builder.Creator();
    }

    REFLECT_MEMBERS(StatusItem, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&StatusItem::GetZoneName, &StatusItem::SetZoneName>("zone").PropAttribute("css", core::String(u8"zone"));
        builder.AccessorProperty<&StatusItem::GetTitleString, &StatusItem::SetTitleString>("title").PropAttribute("css", core::String(u8"title")).PropAttribute("translatable", true);
        builder.Creator();
    }

    REFLECT_MEMBERS(StatusBar, "rtti::gui::toolkit")
    {
        builder.Attribute("accessRole", core::String(u8"group")); // the core has no status role yet
        builder.Creator();
    }

    REFLECT_MEMBERS(PropertyGrid, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&PropertyGrid::GetLabelRatio, &PropertyGrid::SetLabelRatio>("labelRatio").PropAttribute("css", core::String(u8"label-ratio"));
        builder.AccessorProperty<&PropertyGrid::GetIndentWidth, &PropertyGrid::SetIndentWidth>("indentWidth").PropAttribute("css", core::String(u8"indent-width"));
        builder.Creator();
    }

    RTTI_DEFINE_OBJECT(PropertySplitHandle, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyCategoryContent, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyRowContent, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(UnknownPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(SingleControlEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(BoolPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(NumberPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(StringPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(EnumPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyFlagsList, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(FlagsPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(FloatsPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(ListPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(ColorPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyColorPopup, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(StopsPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(HdrColorPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyGrip, "rtti::gui::toolkit")
    // T5's views: elements markup places, whose axis and source the application gives in code.
    REFLECT_MEMBERS(TimeRuler, "rtti::gui::toolkit")
    {
        builder.Creator();
    }
    REFLECT_MEMBERS(CurveView, "rtti::gui::toolkit")
    {
        builder.Creator();
    }
    RTTI_DEFINE_OBJECT(GradientStrip, "rtti::gui::toolkit")
    REFLECT_MEMBERS(GradientView, "rtti::gui::toolkit")
    {
        builder.Creator();
    }
    REFLECT_MEMBERS(Dopesheet, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&Dopesheet::GetLabelWidth, &Dopesheet::SetLabelWidth>("labelWidth").PropAttribute("css", core::String(u8"label-width"));
        builder.Creator();
    }
    // T6's view: an element markup places, whose source the application gives in code.
    RTTI_DEFINE_OBJECT(GraphPinRow, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GraphNodeHeader, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GraphNodeWidget, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GraphFrameWidget, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GraphPickerRow, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GraphNodePicker, "rtti::gui::toolkit")
    REFLECT_MEMBERS(GraphView, "rtti::gui::toolkit")
    {
        builder.AccessorProperty<&GraphView::GetGridSize, &GraphView::SetGridSize>("gridSize").PropAttribute("css", core::String(u8"grid-size"));
        builder.Creator();
    }
    // T7's bar: an element markup places, whose items the application gives in code.
    REFLECT_MEMBERS(BreadcrumbSegment, "rtti::gui::toolkit")
    {
        builder.ComputedProperty<&BreadcrumbSegment::GetAccessDescription>("description")
            .PropAttribute("access", core::String(u8"description"));
    }
    RTTI_DEFINE_OBJECT(BreadcrumbSeparator, "rtti::gui::toolkit")
    REFLECT_MEMBERS(BreadcrumbBar, "rtti::gui::toolkit")
    {
        builder.Attribute("accessRole", core::String(u8"group")); // the core has no navigation role yet
        builder.Creator();
    }
    RTTI_DEFINE_OBJECT(PropertyViewPopup, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(PropertyValuePreview, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(CurvePropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(GradientPropertyEditor, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(ToolMenuArrow, "rtti::gui::toolkit")
    RTTI_DEFINE_OBJECT(ToolBarOverflow, "rtti::gui::toolkit")

    void RegisterToolkitElements()
    {
        static const bool once = []()
        {
            const core::TypeInfo* const kElements[] = {
                &ToolButton::StaticType(),
                &ToolMenuButton::StaticType(),
                &ToolBar::StaticType(),
                &StatusItem::StaticType(),
                &StatusBar::StaticType(),
                &PropertyGrid::StaticType(),
                &TimeRuler::StaticType(),
                &CurveView::StaticType(),
                &GradientView::StaticType(),
                &Dopesheet::StaticType(),
                &GraphView::StaticType(),
                &BreadcrumbBar::StaticType(),
            };
            for (const core::TypeInfo* type : kElements)
                (void)ElementTypes::Register(*type);
            return true;
        }();
        (void)once;
    }
}
