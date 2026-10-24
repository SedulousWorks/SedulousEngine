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
    namespace
    {
        // A script handle's context: plain bytes in the Variant; the table is its retained anchor.
        struct ElementHandleCtx
        {
            ElementTable* table;
            u32 slot;
            u32 generation;
        };

        void* ResolveElement(const core::Variant& handle)
        {
            const auto* ctx = static_cast<const ElementHandleCtx*>(handle.ResolveContext());
            return ctx->table->Resolve(ctx->slot, ctx->generation);
        }

        [[nodiscard]] bool DerivesFrom(const TypeInfo* type, const TypeInfo& base) noexcept
        {
            for (const TypeInfo* t = type; t != nullptr; t = t->base)
                if (t == &base)
                    return true;
            return false;
        }

        // `X.of(node)`: the same node's handle typed as X, or null when it is not an X (or gone).
        template <typename T>
        [[nodiscard]] core::Variant ElementOf(core::Variant handle)
        {
            Node* node = Node::FromHandle(handle);
            T* typed = node != nullptr ? Cast<T>(node) : nullptr;
            return typed != nullptr ? typed->HandleAs(T::StaticType()) : core::Variant{};
        }

        // An event as a script handler sees it: positions in the GUI's units (from device pixels
        // through the root's display scale).
        [[nodiscard]] GuiEvent ScriptEventOf(const Event& event, StringView name)
        {
            GuiEvent out;
            out.type = core::String(name);
            if (const UIWidget* target = Cast<UIWidget>(event.Target))
                out.id = core::String(target->GetId());
            out.phase = core::String(event.Phase == EventPhase::Capture ? u8"capture" : event.Phase == EventPhase::Target ? u8"target" : u8"bubble");
            const auto place = [&](core::Float2 world)
            {
                if (Node* current = event.CurrentTarget; current != nullptr)
                {
                    const core::Float2 inRoot = current->GetRootNode()->ConvertToNodeSpace(world);
                    const core::Float2 local = current->ConvertToNodeSpace(world);
                    out.x = inRoot.x;
                    out.y = inRoot.y;
                    out.localX = local.x;
                    out.localY = local.y;
                }
            };
            switch (event.Type)
            {
            case EventType::MouseDown:
            case EventType::MouseUp:
            case EventType::MouseMove:
            case EventType::MouseClick:
            case EventType::MouseEnter:
            case EventType::MouseLeave:
            case EventType::PointerCancel:
            case EventType::ContextMenu:
            {
                const MouseEvent& mouse = static_cast<const MouseEvent&>(event);
                // Over an item view's row: which (a context menu for it).
                for (Node* n = event.Target; n != nullptr; n = n->GetParent())
                    if (const ItemRow* row = Cast<ItemRow>(n))
                    {
                        out.index = row->GetItemIndex();
                        break;
                    }
                place(mouse.Position);
                out.pointer = core::String(mouse.Pointer == PointerType::Touch ? u8"touch" : u8"mouse");
                out.button = static_cast<i32>(mouse.Button);
                out.clickCount = static_cast<i32>(mouse.ClickCount);
                out.modifiers = static_cast<i32>(mouse.Modifiers);
                break;
            }
            case EventType::MouseWheel:
            {
                const WheelEvent& wheel = static_cast<const WheelEvent&>(event);
                place(wheel.Position);
                out.deltaX = wheel.Delta.x;
                out.deltaY = wheel.Delta.y;
                break;
            }
            case EventType::GestureStart:
            case EventType::GestureChange:
            case EventType::GestureEnd:
            case EventType::GestureCancel:
            {
                const GestureEvent& gesture = static_cast<const GestureEvent&>(event);
                place(gesture.Focus);
                out.pointer = core::String(gesture.Pointer == PointerType::Touch ? u8"touch" : u8"mouse");
                out.scale = gesture.Scale;
                out.rotation = gesture.Rotation;
                out.translationX = gesture.Translation.x;
                out.translationY = gesture.Translation.y;
                out.scaleDelta = gesture.ScaleDelta;
                out.rotationDelta = gesture.RotationDelta;
                out.deltaX = gesture.TranslationDelta.x;
                out.deltaY = gesture.TranslationDelta.y;
                break;
            }
            case EventType::KeyDown:
            case EventType::KeyUp:
            {
                const KeyEvent& key = static_cast<const KeyEvent&>(event);
                out.key = static_cast<i32>(key.KeyCode);
                out.modifiers = static_cast<i32>(key.Modifiers);
                break;
            }
            case EventType::TextInput: out.text = core::String(static_cast<const TextInputEvent&>(event).Text); break;
            case EventType::Link: out.text = core::String(static_cast<const LinkEvent&>(event).Link); break; // the link's id
            case EventType::Composition: out.text = core::String(static_cast<const CompositionEvent&>(event).Text); break;
            case EventType::Toggle: // "open", or why it closed
            {
                const ToggleEvent& toggle = static_cast<const ToggleEvent&>(event);
                out.text = core::String(toggle.Open ? core::StringView(u8"open") : PopupCloseReasonName(toggle.Reason));
                break;
            }
            case EventType::TabClose: out.index = static_cast<const TabEvent&>(event).Index; break;
            case EventType::DragStart:
            case EventType::DragEnd:
            case EventType::DragEnter:
            case EventType::DragOver:
            case EventType::DragLeave:
            case EventType::Drop:
            case EventType::DragQuery:
            {
                const DragEvent& drag = static_cast<const DragEvent&>(event);
                place(drag.Position); // the root's space: as a pointer's
                static constexpr const char8_t* kEffects[] = {u8"none", u8"copy", u8"move", u8"link"};
                out.dragType = drag.Payload.Type;
                out.effect = core::String(kEffects[static_cast<usize>(drag.Effect)]);
                const core::String* value = drag.Payload.Value.TryGet<core::String>();
                out.text = value != nullptr ? *value : drag.Payload.Label;
                out.index = drag.Place;
                out.modifiers = static_cast<i32>(drag.Modifiers);
                break;
            }
            case EventType::ItemActivate: out.index = static_cast<const ItemEvent&>(event).Item; break;
            case EventType::Named: out.text = core::String(static_cast<const NamedEvent&>(event).Detail); break;
            case EventType::TransitionEnd:
            case EventType::AnimationEnd:
            {
                const MotionEndEvent& motion = static_cast<const MotionEndEvent&>(event);
                out.text = core::String(motion.Name);
                out.elapsed = motion.Elapsed;
                break;
            }
            default: break;
            }
            return out;
        }

        [[nodiscard]] Node* FindById(Node& node, StringView id)
        {
            if (const UIWidget* widget = Cast<UIWidget>(&node); widget != nullptr && widget->GetId() == id)
                return &node;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (Node* found = FindById(*node.GetChildAt(i), id))
                    return found;
            return nullptr;
        }
    }

    // === Weak references ===

    core::Variant Node::HandleAs(const TypeInfo& type)
    {
        const ElementRef ref = TakeElementRef();
        if (ref.table == nullptr)
            return core::Variant{};
        return core::Variant::Resolving(&type, &ResolveElement, ElementHandleCtx{ref.table, ref.slot, ref.generation},
                                  ref.table);
    }

    Node* Node::FromHandle(const core::Variant& handle)
    {
        if (!handle.IsResolving() || !DerivesFrom(handle.Type(), Node::StaticType()))
            return nullptr;
        return static_cast<Node*>(handle.Resolve());
    }

    // === The tree by name ===

    core::Variant Node::AddElement(StringView tag)
    {
        const ElementSet* elements = GetElementSet();
        RefPtr<Node> element = elements != nullptr ? elements->Create(tag, MemoryAllocator()) : RefPtr<Node>{};
        if (!element)
            return core::Variant{};
        GetChildHost()->AddChild(element.Get());
        return element->HandleAs(Node::StaticType());
    }

    core::Variant Node::FindElement(StringView id)
    {
        Node* found = FindById(*this, id);
        return found != nullptr ? found->HandleAs(Node::StaticType()) : core::Variant{};
    }

    core::Variant Node::ParentElement()
    {
        return m_parent != nullptr ? m_parent->HandleAs(Node::StaticType()) : core::Variant{};
    }

    core::Variant Node::ChildElement(i32 index)
    {
        Node* child = index >= 0 ? GetChildAt(static_cast<usize>(index)) : nullptr;
        return child != nullptr ? child->HandleAs(Node::StaticType()) : core::Variant{};
    }

    i32 Node::On(StringView eventName, RefPtr<foundation::script::IScriptDelegate> handler)
    {
        EventType type = EventType::MouseClick;
        if (!handler || eventName.IsEmpty())
            return 0;
        // A name the core does not know is one a library sends (a gamekit screen's `screenenter`).
        const bool named = !EventTypeNamed(eventName, type);
        if (named)
            type = EventType::Named;
        // The node holds the handler (and with it the script function); the script holds the node
        // only weakly, so neither keeps the other alive.
        // The handler gets the event's data (one ignoring it may take no parameter), and takes the
        // event by returning true.
        return static_cast<i32>(AddEventListener(type,
                               [handler, named, name = core::String(eventName)](const Event& event)
                               {
                                   if (named && static_cast<const NamedEvent&>(event).Name != name.AsView())
                                       return;
                                   core::Variant args[1] = {core::Variant::From<GuiEvent>(ScriptEventOf(event, name.AsView()))};
                                   Result<core::Variant> result = handler->Invoke(Span<core::Variant>(args, 1));
                                   const bool* took = result.HasValue() ? result.Value().TryGet<bool>() : nullptr;
                                   if (took != nullptr && *took)
                                       event.Handled = true;
                               }));
    }

    // === Bindings ===

    bool Node::BindScript(StringView property, RefPtr<foundation::script::IScriptDelegate> expression)
    {
        if (!expression)
            return false;
        // The node holds the function (as it holds an event handler); a failed call binds nothing.
        return BindProperty(property,
                            [expression]
                            {
                                Result<core::Variant> result = expression->Invoke(Span<core::Variant>{});
                                return result.HasValue() ? result.Value() : core::Variant{};
                            });
    }

    bool Node::BindSceneData(StringView property, StringView key)
    {
        SceneRoot* root = GetSceneRoot();
        return root != nullptr && BindData(property, root->GetContext().GetDataRef(), key);
    }

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

    bool Node::FocusElement()
    {
        EventDispatcher* dispatcher = GetEventDispatcher();
        Node* target = dispatcher != nullptr ? FocusTargetOf(*this) : nullptr;
        if (target == nullptr)
            return false;
        dispatcher->SetFocusNode(target);
        return true;
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

    core::Variant Node::OpenPopupScript(core::Variant content)
    {
        Node* node = FromHandle(content);
        EventDispatcher* dispatcher = GetEventDispatcher();
        if (node == nullptr || node == this || dispatcher == nullptr)
            return core::Variant::From<bool>(false);
        node->SetDisplayed(true);
        PopupOptions options;
        options.Anchor = this;
        options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 0.0f, true};
        options.TakesFocus = true;
        options.FitContent = true;
        options.ReturnHome = true; // a script's popup: back where it stood, to open again
        dispatcher->OpenPopup(*this, *node, core::Move(options));
        return core::Variant::From<bool>(dispatcher->IsPopupOpen(*node));
    }

    bool Node::ClosePopupScript()
    {
        EventDispatcher* dispatcher = GetEventDispatcher();
        return dispatcher != nullptr && dispatcher->IsPopupOpen(*this) && dispatcher->ClosePopup(*this);
    }

    i32 Node::OnCommandScript(StringView id, RefPtr<foundation::script::IScriptDelegate> handler)
    {
        if (!handler)
            return 0;
        return static_cast<i32>(OnCommand(id,
                        [handler](CommandEvent& event)
                        {
                            Result<core::Variant> result = handler->Invoke(Span<core::Variant>{});
                            const bool* goOn = result.HasValue() ? result.Value().TryGet<bool>() : nullptr;
                            event.Propagate = goOn != nullptr && *goOn;
                        }));
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

    void RttiRegisterValue_GuiEvent(); // REFLECT_VALUE below
    void RttiRegisterEnum_ToastSeverity();
    void RttiRegisterValue_ToastRequest();

    void RegisterGuiScriptSurface()
    {
        static const bool once = []()
        {
            RegisterGuiElements();
            RttiRegisterValue_GuiEvent();
            TypeRegistry& registry = GlobalTypeRegistry();
            registry.Register(TypeOf<GuiEvent>()); // what a handler is given
            registry.Register(Node::StaticType()); // the bases a script names (Node.of, UIWidget.of)
            registry.Register(SceneRoot::StaticType());
            registry.Register(UINode::StaticType());
            registry.Register(UIWidget::StaticType());
            registry.Register(Gui::StaticType()); // binds as `gui` (its scriptName)
            registry.Register(Tween::StaticType()); // what node.animate gives (E14)
            registry.Register(TweenGroup::StaticType());
            registry.Register(TweenSequence::StaticType());
            registry.Register(TweenParallel::StaticType());
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

    REFLECT_VALUE(GuiEvent, "rtti::gui")
    {
        builder.Property<&GuiEvent::type>("type")
            .Property<&GuiEvent::phase>("phase")
            .Property<&GuiEvent::pointer>("pointer")
            .Property<&GuiEvent::x>("x")
            .Property<&GuiEvent::y>("y")
            .Property<&GuiEvent::localX>("localX")
            .Property<&GuiEvent::localY>("localY")
            .Property<&GuiEvent::button>("button")
            .Property<&GuiEvent::clickCount>("clickCount")
            .Property<&GuiEvent::key>("key")
            .Property<&GuiEvent::modifiers>("modifiers")
            .Property<&GuiEvent::text>("text")
            .Property<&GuiEvent::deltaX>("deltaX")
            .Property<&GuiEvent::deltaY>("deltaY")
            .Property<&GuiEvent::scale>("scale")
            .Property<&GuiEvent::rotation>("rotation")
            .Property<&GuiEvent::translationX>("translationX")
            .Property<&GuiEvent::translationY>("translationY")
            .Property<&GuiEvent::scaleDelta>("scaleDelta")
            .Property<&GuiEvent::rotationDelta>("rotationDelta")
            .Property<&GuiEvent::index>("index")
            .Property<&GuiEvent::id>("id")
            .Property<&GuiEvent::dragType>("dragType")
            .Property<&GuiEvent::effect>("effect")
            .Property<&GuiEvent::elapsed>("elapsed")
            // Constructible, so both languages take it by value and Luau binds it (a type a script
            // can make is one it can be handed).
            .Constructor<>();
    }

    REFLECT_MEMBERS(Node, "rtti::gui")
    {
        builder.Method<&Node::AddElement, Node>("add");
        builder.Method<&Node::FindElement, Node>("find");
        builder.Method<&Node::ParentElement, Node>("parent");
        builder.Method<&Node::ChildElement, Node>("childAt");
        builder.Method<&Node::ElementChildCount>("childCount");
        builder.Method<&Node::On>("on");
        builder.Method<&Node::Off>("off"); // what on and onCommand gave (E16)
        builder.Method<&Node::OpenPopupScript, bool, Node>("popup");
        builder.Method<&Node::ClosePopupScript>("closePopup");
        builder.Method<&Node::BindScript>("bind");
        builder.Method<&Node::BindSceneData>("bindData");
        builder.Method<&Node::OnCommandScript>("onCommand");
        builder.Method<&Node::FocusElement>("focus");
        builder.Method<&Node::Destroy>("destroy");
        builder.Method<&Node::Leave>("leave"); // goes after its exit plays (K0)
        builder.Method<&Node::IsLeaving>("isLeaving");
        builder.Method<&Node::Enter>("enter"); // plays its entrance (K5)
        builder.Method<&Node::IsArriving>("isEntering");
        // Motion (E14): a tween, a spring, a group's run, and the property given back.
        builder.Method<&Node::Animate>("tween"); // `animate` is an expander's property
        builder.Method<&Node::CreateTween>("createTween");
        builder.Method<&Node::SpringTo>("springTo");
        builder.Method<&Node::StopAnimation>("stopAnimation");
        builder.Method<&Node::Play>("play");
        builder.Method<&ElementOf<Node>, Node, Node>("of");
    }

    // Motion (E14): `repeats`, as `repeat` is a word of Luau's.
    REFLECT_MEMBERS(Tween, "rtti::gui")
    {
        builder.Method<&Tween::FromScript>("from");
        builder.Method<&Tween::DelayScript>("delay");
        builder.Method<&Tween::RepeatScript>("repeats");
        builder.Method<&Tween::PingPongScript>("pingPong");
        builder.Method<&Tween::EaseScript>("ease");
        builder.Method<&Tween::WholeScript>("whole"); // a data value counting in whole numbers (K3)
        builder.Method<&Tween::SpringScript>("spring");
        builder.Method<&Tween::OnFinishedScript>("onFinished");
        builder.Method<&Tween::Retarget>("retarget");
        builder.Method<&Tween::Cancel>("cancel");
        builder.Method<&Tween::IsFinished>("isDone");
    }

    REFLECT_MEMBERS(TweenGroup, "rtti::gui")
    {
        builder.Method<&TweenGroup::AddScript>("add");
        builder.Method<&TweenGroup::AddGroupScript>("addGroup");
        builder.Method<&TweenGroup::WaitScript>("wait");
        builder.Method<&TweenGroup::CallScript>("call");
        builder.Method<&TweenGroup::RepeatScript>("repeats");
        builder.Method<&TweenGroup::OnFinishedScript>("onFinished");
        builder.Method<&TweenGroup::IsFinished>("isDone");
    }

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

    REFLECT_MEMBERS(TweenSequence, "rtti::gui")
    {
        builder.Constructor<>(); // a script makes one: TweenSequence() / TweenSequence.new()
    }

    REFLECT_MEMBERS(TweenParallel, "rtti::gui")
    {
        builder.Constructor<>();
    }

    REFLECT_MEMBERS(SceneRoot, "rtti::gui")
    {
        builder.Method<&ElementOf<SceneRoot>, SceneRoot, Node>("of");
    }

    REFLECT_MEMBERS(UINode, "rtti::gui")
    {
        builder.Method<&ElementOf<UINode>, UINode, Node>("of");
    }

    REFLECT_MEMBERS(UIWidget, "rtti::gui")
    {
        builder.Method<&UIWidget::AddClass>("addClass");
        builder.Method<&UIWidget::RemoveClass>("removeClass");
        builder.Method<&UIWidget::HasClass>("hasClass");
        builder.Method<&UIWidget::ToggleClass>("toggleClass");
        builder.Method<&ElementOf<UIWidget>, UIWidget, Node>("of");
    }

    REFLECT_MEMBERS(Label, "rtti::gui")
    {
        builder.Method<&ElementOf<Label>, Label, Node>("of");
    }

    REFLECT_MEMBERS(RichText, "rtti::gui")
    {
        builder.Method<&ElementOf<RichText>, RichText, Node>("of");
    }

    REFLECT_MEMBERS(ButtonBase, "rtti::gui")
    {
        builder.Method<&ElementOf<ButtonBase>, ButtonBase, Node>("of");
    }

    REFLECT_MEMBERS(ButtonIndicator, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(Button, "rtti::gui")
    {
        builder.Method<&ElementOf<Button>, Button, Node>("of");
    }

    REFLECT_MEMBERS(CheckBox, "rtti::gui")
    {
        builder.Method<&ElementOf<CheckBox>, CheckBox, Node>("of");
    }

    REFLECT_MEMBERS(RadioButton, "rtti::gui")
    {
        builder.Method<&ElementOf<RadioButton>, RadioButton, Node>("of");
    }

    REFLECT_MEMBERS(ColorSwatch, "rtti::gui")
    {
        builder.Method<&ElementOf<ColorSwatch>, ColorSwatch, Node>("of");
    }

    REFLECT_MEMBERS(ColorPicker, "rtti::gui")
    {
        builder.Method<&ElementOf<ColorPicker>, ColorPicker, Node>("of");
    }

    // Toasts (T7 of round three): a host markup places; a request a script fills in and posts.
    REFLECT_ENUM(ToastSeverity, "rtti::gui")
    {
        builder.Value("Info", ToastSeverity::Info);
        builder.Value("Success", ToastSeverity::Success);
        builder.Value("Warning", ToastSeverity::Warning);
        builder.Value("Error", ToastSeverity::Error);
    }
    REFLECT_VALUE(ToastRequest, "rtti::gui")
    {
        builder.Property<&ToastRequest::Title>("title")
            .Property<&ToastRequest::Message>("message")
            .Property<&ToastRequest::Rich>("rich")
            .Property<&ToastRequest::Bare>("bare")
            .Property<&ToastRequest::Announcement>("announcement")
            .Property<&ToastRequest::Severity>("severity")
            .Property<&ToastRequest::Duration>("duration")
            .Property<&ToastRequest::Key>("key")
            .Property<&ToastRequest::Classes>("classes"); // `class` is a script's keyword
        builder.Method<&ToastRequest::AddAction>("addAction");
        builder.Constructor();
    }
    namespace
    {
        // `ToastHost.nearest(node)`: the toast host in that node's GUI (its root's subtree), else null.
        [[nodiscard]] ToastHost* FindToastHostUnder(Node& node)
        {
            if (ToastHost* host = Cast<ToastHost>(&node))
                return host;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (ToastHost* host = FindToastHostUnder(*node.GetChildAt(i)))
                    return host;
            return nullptr;
        }
        [[nodiscard]] core::Variant FindToastHost(core::Variant handle)
        {
            Node* node = Node::FromHandle(handle);
            Node* root = node != nullptr ? node->GetRootNode() : nullptr;
            ToastHost* host = root != nullptr ? FindToastHostUnder(*root) : nullptr;
            return host != nullptr ? host->HandleAs(ToastHost::StaticType()) : core::Variant{};
        }
    }
    REFLECT_MEMBERS(ToastHost, "rtti::gui")
    {
        builder.Method<&ToastHost::PostScript>("post");
        builder.Method<&ToastHost::PostContentScript, ToastId, Node>("postContent");
        builder.Method<static_cast<bool (ToastHost::*)(ToastId)>(&ToastHost::Dismiss)>("dismiss");
        builder.Method<&ToastHost::DismissAll>("dismissAll");
        builder.Method<&FindToastHost, ToastHost, Node>("nearest"); // not `find`: a node's find(id) has the name
        builder.Method<&ElementOf<ToastHost>, ToastHost, Node>("of");
    }

    REFLECT_MEMBERS(ToggleSwitch, "rtti::gui")
    {
        builder.Method<&ElementOf<ToggleSwitch>, ToggleSwitch, Node>("of");
    }

    REFLECT_MEMBERS(RangeWidget, "rtti::gui")
    {
        builder.Method<&ElementOf<RangeWidget>, RangeWidget, Node>("of");
    }

    REFLECT_MEMBERS(Slider, "rtti::gui")
    {
        builder.Method<&ElementOf<Slider>, Slider, Node>("of");
    }

    REFLECT_MEMBERS(ProgressBar, "rtti::gui")
    {
        builder.Method<&ElementOf<ProgressBar>, ProgressBar, Node>("of");
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

    REFLECT_MEMBERS(Panel, "rtti::gui")
    {
        builder.Method<&ElementOf<Panel>, Panel, Node>("of");
    }

    REFLECT_MEMBERS(ScrollView, "rtti::gui")
    {
        builder.Method<&ElementOf<ScrollView>, ScrollView, Node>("of");
    }

    REFLECT_MEMBERS(EditableLabel, "rtti::gui")
    {
        builder.Method<&EditableLabel::BeginEdit>("beginEdit");
        builder.Method<&ElementOf<EditableLabel>, EditableLabel, Node>("of");
    }

    REFLECT_MEMBERS(ExpanderHeader, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(Expander, "rtti::gui")
    {
        builder.Method<&Expander::Toggle>("toggle");
        builder.Method<&ElementOf<Expander>, Expander, Node>("of");
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

    REFLECT_MEMBERS(Tab, "rtti::gui")
    {
        builder.Method<&ElementOf<Tab>, Tab, Node>("of");
    }

    REFLECT_MEMBERS(TabBar, "rtti::gui")
    {
        builder.Method<&TabBar::GetTabCount>("tabCount");
        builder.Method<&TabBar::RemoveTab>("removeTab");
        builder.Method<&TabBar::MoveTab>("moveTab");
        builder.Method<&ElementOf<TabBar>, TabBar, Node>("of");
    }

    REFLECT_MEMBERS(TabPage, "rtti::gui")
    {
        builder.Method<&ElementOf<TabPage>, TabPage, Node>("of");
    }

    REFLECT_MEMBERS(TabPageHost, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabView, "rtti::gui")
    {
        builder.Method<&TabView::GetPageCount>("pageCount");
        builder.Method<&TabView::RemovePage>("removePage");
        builder.Method<&ElementOf<TabView>, TabView, Node>("of");
    }

    REFLECT_MEMBERS(SpinButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(NumberField, "rtti::gui")
    {
        builder.Method<&ElementOf<NumberField>, NumberField, Node>("of");
    }

    REFLECT_MEMBERS(Separator, "rtti::gui")
    {
        builder.Method<&ElementOf<Separator>, Separator, Node>("of");
    }

    REFLECT_MEMBERS(Splitter, "rtti::gui")
    {
        builder.Method<&Splitter::ResetWeights>("resetWeights");
        builder.Method<&ElementOf<Splitter>, Splitter, Node>("of");
    }

    REFLECT_MEMBERS(SplitterHandle, "rtti::gui")
    {
        builder.Method<&ElementOf<SplitterHandle>, SplitterHandle, Node>("of");
    }

    REFLECT_MEMBERS(Spacer, "rtti::gui")
    {
        builder.Method<&ElementOf<Spacer>, Spacer, Node>("of");
    }

    REFLECT_MEMBERS(Image, "rtti::gui")
    {
        builder.Method<&ElementOf<Image>, Image, Node>("of");
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

    REFLECT_MEMBERS(ScrollBar, "rtti::gui")
    {
        builder.Method<&ElementOf<ScrollBar>, ScrollBar, Node>("of");
    }

    REFLECT_MEMBERS(MessageBox, "rtti::gui")
    {
        builder.Method<&MessageBox::Show>("show");
        builder.Method<&ElementOf<MessageBox>, MessageBox, Node>("of");
    }

    REFLECT_MEMBERS(MenuSeparator, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(MenuItem, "rtti::gui")
    {
        builder.Method<&ElementOf<MenuItem>, MenuItem, Node>("of");
    }

    REFLECT_MEMBERS(Menu, "rtti::gui")
    {
        builder.Method<&Menu::Close>("close");
        builder.Method<&Menu::OpenAtPoint>("openAt"); // a script's own menus (E16)
        builder.Method<&Menu::OpenBelowNode, bool, Node>("openBelow");
        builder.Method<&Menu::IsOpen>("isOpen");
        builder.Method<&ElementOf<Menu>, Menu, Node>("of");
    }

    REFLECT_MEMBERS(MenuBar, "rtti::gui")
    {
        builder.Method<&ElementOf<MenuBar>, MenuBar, Node>("of");
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

    REFLECT_MEMBERS(ListBox, "rtti::gui")
    {
        builder.Method<&ElementOf<ListBox>, ListBox, Node>("of");
    }

    REFLECT_MEMBERS(ComboBox, "rtti::gui")
    {
        builder.Method<&ElementOf<ComboBox>, ComboBox, Node>("of");
    }

    REFLECT_MEMBERS(Window, "rtti::gui")
    {
        // A script's own windows (E16): opened where they are or modal, closed, listened to (`close`).
        builder.Method<&Window::OpenInPlace>("open");
        builder.Method<&Window::OpenModalOver>("openModal");
        builder.Method<&Window::Close>("close");
        builder.Method<&Window::IsOpen>("isOpen");
        builder.Method<&ElementOf<Window>, Window, Node>("of");
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
