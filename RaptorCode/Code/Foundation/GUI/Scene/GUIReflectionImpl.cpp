// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the GUI's reflection, element registry and script surface (G1 of
// Specs/vg-and-gui-lab.md).
//
// The widgets and their style-facing properties are reflected here as their native API is spelled
// (StringView text included), so the engine's reflection-driven binding reaches the node tree from
// AngelScript and Luau with no UI-script layer of its own, markup creates the same types by tag,
// and a library adds widgets of its own the same way (ElementTypes::Register). The tree owns its
// nodes; native code (Element<T>) and scripts (a resolve-mode handle, anchored on the table) hold
// them weakly through their GUI's element table. Destroying from a script is deferred to the end
// of the GUI's update (Node::Close).

module;
#include "Core/Prelude.h"
#include "Core/Log/Log.h"
#include "Core/Reflection/Reflect.h"

module foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

namespace foundation::gui
{
    // === The facade and registration ===

    namespace
    {
        DataModel* ScriptDataModel()
        {
            foundation::script::IScriptContext* context = foundation::script::CurrentScriptContext();
            const auto* binding =
                context != nullptr ? static_cast<const GuiScriptBinding*>(context->GetService(kGuiScriptService)) : nullptr;
            SceneRoot* root = binding != nullptr ? binding->Root() : nullptr;
            return root != nullptr ? &root->GetContext().GetData() : nullptr;
        }
    }

    f64 Gui::GetNumber(StringView name)
    {
        DataModel* data = ScriptDataModel();
        const core::Variant value = data != nullptr ? ConvertVariant(data->Get(name), TypeOf<f64>()) : core::Variant{};
        return value.IsEmpty() ? 0.0 : value.Get<f64>();
    }

    core::String Gui::GetText(StringView name)
    {
        DataModel* data = ScriptDataModel();
        return data != nullptr ? FormatVariant(data->Get(name)) : core::String{};
    }

    bool Gui::GetBool(StringView name)
    {
        DataModel* data = ScriptDataModel();
        const core::Variant value = data != nullptr ? ConvertVariant(data->Get(name), TypeOf<bool>()) : core::Variant{};
        return !value.IsEmpty() && value.Get<bool>();
    }

    namespace
    {
        SceneRoot* ScriptRoot()
        {
            foundation::script::IScriptContext* context = foundation::script::CurrentScriptContext();
            const auto* binding =
                context != nullptr ? static_cast<const GuiScriptBinding*>(context->GetService(kGuiScriptService)) : nullptr;
            return binding != nullptr ? binding->Root() : nullptr;
        }
    }

    void Gui::DefineCommand(StringView id, StringView label)
    {
        if (SceneRoot* root = ScriptRoot())
            root->GetContext().DefineCommand(id).SetLabel(label.Size() != 0 ? label : id);
    }
    void Gui::SetCommandEnabled(StringView id, bool enabled)
    {
        if (SceneRoot* root = ScriptRoot())
            root->GetContext().DefineCommand(id).SetEnabled(enabled);
    }
    void Gui::SetCommandChecked(StringView id, bool checked)
    {
        if (SceneRoot* root = ScriptRoot())
            root->GetContext().DefineCommand(id).SetChecked(checked);
    }
    void Gui::SetCommandDisabledReason(StringView id, StringView reason)
    {
        if (SceneRoot* root = ScriptRoot())
            root->GetContext().DefineCommand(id).SetDisabledReason(reason);
    }
    bool Gui::IsCommandChecked(StringView id)
    {
        SceneRoot* root = ScriptRoot();
        const Command* command = root != nullptr ? root->GetContext().GetCommands().Find(id) : nullptr;
        return command != nullptr && command->IsChecked();
    }
    bool Gui::RunCommand(StringView id)
    {
        SceneRoot* root = ScriptRoot();
        return root != nullptr && root->RunCommand(id);
    }

    bool Gui::BindKey(StringView keys, StringView command, StringView context)
    {
        SceneRoot* root = ScriptRoot();
        return root != nullptr && root->GetContext().GetKeymap().Bind(keys, command, context);
    }

    void Gui::CaptureKey(RefPtr<foundation::script::IScriptDelegate> handler)
    {
        SceneRoot* root = ScriptRoot();
        if (root == nullptr || !handler)
            return;
        const auto deliver = [handler](core::StringView keys)
        {
            core::Variant args[1] = {core::Variant::From(core::String(keys))};
            (void)handler->Invoke(Span<core::Variant>(args, 1));
        };
        root->GetEventDispatcher()->CaptureNextKey([deliver](const Keystroke& stroke) { deliver(KeystrokeName(stroke).AsView()); },
                                                   [deliver] { deliver(StringView{}); });
    }

    core::String Gui::KeyText(StringView keys)
    {
        const Optional<Keystroke> stroke = ParseKeystroke(keys);
        return stroke.HasValue() ? KeystrokeText(stroke.Value()) : core::String{};
    }

    namespace
    {
        foundation::i18n::Localization* ScriptLocalization()
        {
            SceneRoot* root = ScriptRoot();
            return root != nullptr ? root->GetContext().GetLocalization() : nullptr;
        }
    }

    core::String Gui::Translate(StringView key)
    {
        foundation::i18n::Localization* localization = ScriptLocalization();
        return localization != nullptr ? localization->TextString(key) : core::String(key);
    }

    core::String Gui::TranslateCount(StringView key, i32 count)
    {
        foundation::i18n::Localization* localization = ScriptLocalization();
        if (localization == nullptr)
            return core::String(key);
        const core::Variant args[1] = {core::Variant::From<i64>(count)};
        return localization->FormatPlural(key, count, Span<const core::Variant>(args, 1));
    }

    core::String Gui::Language()
    {
        foundation::i18n::Localization* localization = ScriptLocalization();
        return localization != nullptr ? core::String(localization->Language()) : core::String{};
    }

    void Gui::Set(StringView name, const core::Variant& value)
    {
        if (DataModel* data = ScriptDataModel())
            data->Set(name, value);
    }

    RefPtr<Tween> Gui::TweenData(StringView name, f64 to, f32 seconds, StringView easing)
    {
        SceneRoot* root = ScriptRoot();
        return root != nullptr ? root->GetContext().AnimateData(name, to, seconds, easing) : RefPtr<Tween>{};
    }

    RefPtr<Tween> Gui::CreateDataTween(StringView name, f64 to, f32 seconds, StringView easing)
    {
        SceneRoot* root = ScriptRoot();
        return root != nullptr ? root->GetContext().CreateDataTween(name, to, seconds, easing) : RefPtr<Tween>{};
    }

    core::String Gui::InputKindNow()
    {
        SceneRoot* root = ScriptRoot();
        return core::String(root != nullptr ? InputKindName(root->GetEventDispatcher()->ObserveInputKind()) : core::StringView(u8"pointer"));
    }

    core::Variant Gui::Root()
    {
        foundation::script::IScriptContext* context = foundation::script::CurrentScriptContext();
        const auto* binding =
            context != nullptr ? static_cast<const GuiScriptBinding*>(context->GetService(kGuiScriptService)) : nullptr;
        SceneRoot* root = binding != nullptr ? binding->Root() : nullptr;
        return root != nullptr ? root->HandleAs(Node::StaticType()) : core::Variant{};
    }

    void RttiRegisterEnum_ToastSeverity();
    void RttiRegisterValue_ToastRequest();

    void RegisterGuiScriptSurface()
    {
        static const bool once = []()
        {
            RegisterGuiElements();
            TypeRegistry& registry = GlobalTypeRegistry();
            registry.Register(Gui::StaticType()); // binds as `gui` (its scriptName)
            registry.Register(ListModel::StaticType()); // a script's list (E16)
            // A toast a script fills in and posts (T7 of round three).
            RttiRegisterEnum_ToastSeverity();
            RttiRegisterValue_ToastRequest();
            registry.Register(TypeOf<ToastSeverity>());
            registry.Register(TypeOf<ToastRequest>());
            foundation::script::RegisterDelegateShape(u8"void KeyHandler(const string &in keys)"); // gui::captureKey's
            return true;
        }();
        (void)once;
    }

    // === Reflection ===

    REFLECT_MEMBERS(ListModel, "rtti::gui")
    {
        builder.Method<&ListModel::Add>("add");
        builder.Method<&ListModel::Insert>("insert");
        builder.Method<&ListModel::Remove>("remove");
        builder.Method<&ListModel::Set>("set");
        builder.Method<&ListModel::Get>("get");
        builder.Method<&ListModel::Count>("count");
        builder.Method<&ListModel::Clear>("clear");
        builder.Constructor<>(); // ListModel() / ListModel.new()
    }

    REFLECT_MEMBERS(ButtonIndicator, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(ColorSwatch, "rtti::gui")
    {
        builder.Method<&ElementOf<ColorSwatch>, ColorSwatch, Node>("of");
    }

    REFLECT_MEMBERS(ColorPicker, "rtti::gui")
    {
        builder.Method<&ElementOf<ColorPicker>, ColorPicker, Node>("of");
    }

    REFLECT_MEMBERS(TextEditBase, "rtti::gui")
    {
        builder.Method<&ElementOf<TextEditBase>, TextEditBase, Node>("of");
    }

    REFLECT_MEMBERS(TextField, "rtti::gui")
    {
        builder.Method<&ElementOf<TextField>, TextField, Node>("of");
    }

    REFLECT_MEMBERS(TextArea, "rtti::gui")
    {
        builder.Method<&ElementOf<TextArea>, TextArea, Node>("of");
    }

    REFLECT_MEMBERS(EditableLabel, "rtti::gui")
    {
        builder.Method<&EditableLabel::BeginEdit>("beginEdit");
        builder.Method<&ElementOf<EditableLabel>, EditableLabel, Node>("of");
    }

    REFLECT_MEMBERS(ExpanderHeader, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabCloseButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabListButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabCloseAllButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabStrip, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabPageHost, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(SpinButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(NumberField, "rtti::gui")
    {
        builder.Method<&ElementOf<NumberField>, NumberField, Node>("of");
    }

    REFLECT_MEMBERS(DragLayer, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(DragPreview, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(MarkupChildHost, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TreeItem, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TreeView, "rtti::gui")
    {
        builder.Method<&TreeView::ExpandItem>("expandItem");
        builder.Method<&TreeView::CollapseItem>("collapseItem");
        builder.Method<&ElementOf<TreeView>, TreeView, Node>("of");
    }

    REFLECT_MEMBERS(TableItem, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TableView, "rtti::gui")
    {
        builder.Method<&ElementOf<TableView>, TableView, Node>("of");
    }

    REFLECT_MEMBERS(MenuSeparator, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(ItemView, "rtti::gui")
    {
        builder.Method<&ItemView::SetListModel>("setModel"); // a script's ListModel (E16)
        builder.Method<&ItemView::BeginEdit>("beginEdit");
        builder.Method<&ItemView::SelectAll>("selectAll");
        builder.Method<&ItemView::ClearSelection>("clearSelection");
        builder.Method<&ElementOf<ItemView>, ItemView, Node>("of");
    }

    REFLECT_MEMBERS(ListView, "rtti::gui")
    {
        builder.Method<&ElementOf<ListView>, ListView, Node>("of");
    }

    REFLECT_MEMBERS(ComboBox, "rtti::gui")
    {
        builder.Method<&ElementOf<ComboBox>, ComboBox, Node>("of");
    }

    REFLECT_MEMBERS(Gui, "rtti::gui")
    {
        builder.Attribute("scriptName", "gui");
        builder.Method<&Gui::Root, Node>("root");
        builder.Method<&Gui::GetNumber>("getNumber");
        builder.Method<&Gui::GetText>("getText");
        builder.Method<&Gui::Translate>("tr"); // the localization's keys (E16)
        builder.Method<&Gui::TranslateCount>("trCount");
        builder.Method<&Gui::Language>("language");
        builder.Method<&Gui::GetBool>("getBool");
        builder.Method<&Gui::Set>("set");
        builder.Method<&Gui::InputKindNow>("inputKind"); // K2b
        builder.Method<&Gui::TweenData>("tween"); // a data value moving (K3)
        builder.Method<&Gui::CreateDataTween>("createTween");
        builder.Method<&Gui::DefineCommand>("defineCommand");
        builder.Method<&Gui::SetCommandEnabled>("setCommandEnabled");
        builder.Method<&Gui::SetCommandChecked>("setCommandChecked");
        builder.Method<&Gui::SetCommandDisabledReason>("setCommandDisabledReason");
        builder.Method<&Gui::IsCommandChecked>("isCommandChecked");
        builder.Method<&Gui::RunCommand>("runCommand");
        builder.Method<&Gui::BindKey>("bindKey");
        builder.Method<&Gui::CaptureKey>("captureKey");
        builder.Method<&Gui::KeyText>("keyText");
    }
}
