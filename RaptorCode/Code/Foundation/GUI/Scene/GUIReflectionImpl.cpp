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

        // The element registry: type knowledge, one per process (an implementation unit's static,
        // the shared-library rendezvous rule).
        struct RegisteredElement
        {
            String tag;
            const TypeInfo* type = nullptr;
        };
        Array<RegisteredElement>& RegisteredElements()
        {
            static Array<RegisteredElement> elements;
            return elements;
        }
    }

    // === The element registry ===

    StringView ElementTypes::TagOf(const TypeInfo& type)
    {
        return TypeAttrString(type, "element", StringView(reinterpret_cast<const char8_t*>(type.name)));
    }

    bool ElementTypes::Register(const TypeInfo& type)
    {
        const StringView tag = TagOf(type);
        if (!DerivesFrom(&type, Node::StaticType()) || type.creator == nullptr)
        {
            LOG_ERROR(u8"GUI", u8"'{}' is not an element type: a reflected Node type with a creator", tag);
            return false;
        }
        for (const RegisteredElement& element : RegisteredElements())
        {
            if (element.tag.AsView() != tag)
                continue;
            if (element.type == &type)
                return true; // registered already
            LOG_ERROR(u8"GUI", u8"the element tag '{}' is taken by another type ({}); not registered", tag,
                      StringView(reinterpret_cast<const char8_t*>(element.type->namespaceName)));
            return false;
        }
        RegisteredElements().PushBack(RegisteredElement{String(tag), &type});
        GlobalTypeRegistry().Register(type); // scripts reach what markup creates
        return true;
    }

    void ElementTypes::Unregister(const TypeInfo& type)
    {
        Array<RegisteredElement>& elements = RegisteredElements();
        for (usize i = 0; i < elements.Size(); ++i)
        {
            if (elements[i].type == &type)
            {
                elements.RemoveAt(i);
                return;
            }
        }
    }

    const TypeInfo* ElementTypes::Find(StringView tag)
    {
        for (const RegisteredElement& element : RegisteredElements())
            if (element.tag.AsView() == tag)
                return element.type;
        return nullptr;
    }

    void ElementTypes::ForEach(const Function<void(StringView, const TypeInfo&)>& visit)
    {
        for (const RegisteredElement& element : RegisteredElements())
            visit(element.tag.AsView(), *element.type);
    }

    // === Weak references ===

    Node::ElementRef Node::TakeElementRef()
    {
        if (!m_elementTable)
        {
            ElementTable* table = GetElementTable();
            if (table == nullptr)
                return ElementRef{};
            m_elementTable = RefPtr<ElementTable>(table);
            m_elementSlot = table->Take(*this);
        }
        return ElementRef{m_elementTable.Get(), m_elementSlot, m_elementTable->Generation(m_elementSlot)};
    }

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

    bool UIWidget::OpenContextMenu(const MouseEvent& event)
    {
        Menu* menu = Cast<Menu>(m_contextMenu.Get());
        Node* root = GetRootNode();
        if (menu == nullptr)
        {
            menu = Cast<Menu>(FindById(*root, m_contextMenuId.AsView()));
            if (menu == nullptr)
                return false;
            m_contextMenu = RefPtr<Node>(menu); // open, it leaves the page; kept here
        }
        menu->Open(*this, root->ConvertToNodeSpace(event.Position));
        return true;
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

    namespace
    {
        // The reflected property named `name` on `type` or a base, by its own name or the CSS name
        // markup writes it by (`aria-label` for `ariaLabel`), or null.
        const PropertyInfo* FindReflectedProperty(const TypeInfo* type, StringView name)
        {
            for (; type != nullptr; type = type->base)
                for (usize i = 0; i < PropertyCount(*type); ++i)
                {
                    const PropertyInfo& property = PropertyAt(*type, i);
                    if (StringView(reinterpret_cast<const utf8char*>(property.name)) == name)
                        return &property;
                    if (const Attribute* css = FindAttribute(property, u8"css"))
                        if (const core::String* cssName = css->value.TryGet<core::String>(); cssName != nullptr && cssName->AsView() == name)
                            return &property;
                }
            return nullptr;
        }
    }

    bool Node::BindProperty(StringView name, core::Function<core::Variant()> expression)
    {
        const PropertyInfo* property = FindReflectedProperty(GetType(), name);
        if (property == nullptr || property->type == nullptr ||
            (static_cast<u32>(property->flags) & static_cast<u32>(PropertyFlags::ReadOnly)) != 0)
            return false;
        // Bound again, a translation of it ends (BindTranslation records its own after this).
        for (usize i = 0; i < m_translations.Size(); ++i)
            if (FindReflectedProperty(GetType(), m_translations[i].Property.AsView()) == property)
            {
                m_translations.RemoveAt(i);
                break;
            }
        BindFor(property, false, [this, property, expression = core::Move(expression)]() mutable
             {
                 const core::Variant value = ConvertVariant(expression(), *property->type);
                 // The write is not a read: setting a property must not make this binding follow it.
                 if (!value.IsEmpty())
                     Untracked([&] { (void)SetProperty(*property, Instance::From(this), value); });
             });
        return true;
    }

    bool Node::BindTranslation(StringView property, StringView key, RefPtr<DataModel> data, Optional<TranslationArgument> count,
                               Array<TranslationArgument> args, StringView fallback)
    {
        const PropertyInfo* info = FindReflectedProperty(GetType(), property);
        if (info == nullptr || FindAttribute(*info, u8"translatable") == nullptr)
            return false;
        const core::String keyText(key);
        const core::String fallbackText(fallback);
        const bool bound = BindProperty(property,
                            [this, keyText, fallbackText, data = core::Move(data), count = core::Move(count), args = core::Move(args)]() -> core::Variant
                            {
                                // The GUI it is in (a binding made before it joins one reruns when it does).
                                SceneRoot* root = ObserveSceneRoot();
                                foundation::i18n::Localization* loc = root != nullptr ? root->GetContext().GetLocalization() : nullptr;
                                if (root != nullptr)
                                    root->GetContext().TrackLanguage();
                                if (loc == nullptr || !IsAutoTranslating())
                                    return core::Variant::From<core::String>(fallbackText.Size() != 0 ? fallbackText : keyText);
                                if (fallbackText.Size() != 0 && !loc->Has(keyText.AsView()))
                                    return core::Variant::From<core::String>(fallbackText); // no table names it: the widget's own
                                // Arguments as text, a named one read from the GUI's data (followed).
                                const auto value = [&data](const TranslationArgument& a) -> core::Variant
                                {
                                    if (a.IsName && data)
                                        return data->Get(a.Text.AsView());
                                    return core::Variant::From<core::String>(a.Text);
                                };
                                Array<core::Variant> values;
                                i64 n = 0;
                                if (count.HasValue())
                                {
                                    const core::Variant c = ConvertVariant(value(count.Value()), TypeOf<i64>());
                                    if (const i64* v = c.TryGet<i64>())
                                        n = *v;
                                    values.PushBack(core::Variant::From<i64>(n));
                                }
                                for (const TranslationArgument& a : args)
                                    values.PushBack(core::Variant::From<core::String>(FormatVariant(value(a))));
                                const Span<const core::Variant> span(values.Data(), values.Size());
                                if (count.HasValue())
                                    return core::Variant::From<core::String>(loc->FormatPlural(keyText.AsView(), n, span));
                                if (!args.IsEmpty())
                                    return core::Variant::From<core::String>(loc->Format(keyText.AsView(), span));
                                return core::Variant::From<core::String>(core::String(loc->Text(keyText.AsView())));
                            });
        if (!bound)
            return false;
        // Recorded by the property's own name (the inspector asks by it), after the binding, which
        // ends any translation the property had.
        m_translations.PushBack(TranslatedProperty{core::String(StringView(reinterpret_cast<const utf8char*>(info->name))), keyText});
        return true;
    }

    bool Node::BindPropertyBack(StringView name, core::Function<void(const core::Variant&)> write)
    {
        const PropertyInfo* property = FindReflectedProperty(GetType(), name);
        if (property == nullptr || FindAttribute(*property, u8"twoWay") == nullptr)
            return false;
        BindFor(property, true, [this, property, write = core::Move(write)]() mutable
             {
                 const core::Variant value = GetProperty(*property, Instance::From(this)); // followed
                 Untracked([&] { write(value); });
             });
        return true;
    }

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

    // A node's tooltip by default: a Tooltip with its text (here, where the widgets are seen).
    core::RefPtr<Node> Node::CreateTooltipContent(core::StringView text)
    {
        auto tip = core::MakeRef<Tooltip>(MemoryAllocator());
        tip->SetText(text);
        return tip;
    }

    // A drag's default preview: the payload's label (E7).
    core::RefPtr<Node> Node::CreateDragPreview(const DragPayload& payload)
    {
        auto preview = core::MakeRef<DragPreview>(MemoryAllocator());
        preview->SetText(payload.Label.AsView());
        if (const UINode* source = Cast<UINode>(this))
            source->ShareTextStyle(*preview, false); // in the source's font until a sheet says otherwise
        return preview;
    }

    // The hint beside a drag's pointer: a target's reason, a tooltip marked `drophint` (and
    // `refused` when nothing takes the drop).
    core::RefPtr<Node> Node::CreateDropHint(core::StringView reason, bool refused)
    {
        auto hint = core::MakeRef<Tooltip>(MemoryAllocator());
        hint->SetText(reason);
        hint->AddClass(core::StringView(u8"drophint"));
        if (refused)
            hint->AddClass(core::StringView(u8"refused"));
        if (const UINode* source = Cast<UINode>(this))
            source->ShareTextStyle(*hint, false);
        return hint;
    }

    void RegisterGuiElements()
    {
        static const bool once = []()
        {
            const TypeInfo* const kLabElements[] = {
                &Label::StaticType(),        &Button::StaticType(),       &CheckBox::StaticType(),
                &RadioButton::StaticType(),  &Slider::StaticType(),       &ProgressBar::StaticType(),
                &TextField::StaticType(),    &Panel::StaticType(),        &ScrollView::StaticType(),
                &Image::StaticType(),        &ListBox::StaticType(),      &Window::StaticType(),
                &ComboBox::StaticType(),     &RichText::StaticType(),     &TextArea::StaticType(),
                &ToggleSwitch::StaticType(),   &Separator::StaticType(),    &Spacer::StaticType(),
                &NumberField::StaticType(),    &EditableLabel::StaticType(), &Expander::StaticType(),
                &Tab::StaticType(),            &TabBar::StaticType(),        &TabPage::StaticType(),
                &TabView::StaticType(),        &ListView::StaticType(),      &Menu::StaticType(),
                &MenuItem::StaticType(),       &MenuSeparator::StaticType(), &MenuBar::StaticType(),
                &TreeView::StaticType(),       &TreeItem::StaticType(),      &TableView::StaticType(),
                &TableItem::StaticType(),      &ScrollBar::StaticType(),     &MessageBox::StaticType(),
                &Splitter::StaticType(),       &ColorSwatch::StaticType(),   &ColorPicker::StaticType(),
                &ToastHost::StaticType(),
            };
            for (const TypeInfo* type : kLabElements)
                (void)ElementTypes::Register(*type);
            return true;
        }();
        (void)once;
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
        builder.AccessorProperty<&Node::GetX, &Node::SetX>("x");
        builder.AccessorProperty<&Node::GetY, &Node::SetY>("y");
        builder.AccessorProperty<&Node::GetWidth, &Node::SetWidth>("width");
        builder.AccessorProperty<&Node::GetHeight, &Node::SetHeight>("height");
        builder.AccessorProperty<&Node::IsVisible, &Node::SetVisible>("visible"); // hidden keeps its place
        builder.AccessorProperty<&Node::GetDropTypes, &Node::SetDropTypes>("dropTypes").PropAttribute("css", core::String(u8"drop-types"));
        builder.AccessorProperty<&Node::IsDisplayed, &Node::SetDisplayed>("displayed"); // out of the layout when false
        builder.AccessorProperty<&Node::IsEnabled, &Node::SetEnabled>("enabled");
        builder.AccessorProperty<&Node::GetAlpha, &Node::SetAlpha>("opacity");
        builder.AccessorProperty<&Node::IsStickToEnd, &Node::SetStickToEnd>("stickToEnd").PropAttribute("css", core::String(u8"stick-to-end"));
        // Navigation (G7): reflected with their CSS names, so a sheet, markup and a script set them.
        builder.AccessorProperty<&Node::GetNavUp, &Node::SetNavUp>("navUp").PropAttribute("css", core::String(u8"nav-up"));
        builder.AccessorProperty<&Node::GetNavDown, &Node::SetNavDown>("navDown").PropAttribute("css", core::String(u8"nav-down"));
        builder.AccessorProperty<&Node::GetNavLeft, &Node::SetNavLeft>("navLeft").PropAttribute("css", core::String(u8"nav-left"));
        builder.AccessorProperty<&Node::GetNavRight, &Node::SetNavRight>("navRight").PropAttribute("css", core::String(u8"nav-right"));
        builder.AccessorProperty<&Node::GetNavNext, &Node::SetNavNext>("navNext").PropAttribute("css", core::String(u8"nav-next"));
        builder.AccessorProperty<&Node::GetNavPrevious, &Node::SetNavPrevious>("navPrev").PropAttribute("css", core::String(u8"nav-prev"));
        builder.AccessorProperty<&Node::GetNavScopeName, &Node::SetNavScopeName>("navScope").PropAttribute("css", core::String(u8"nav-scope"));
        builder.AccessorProperty<&Node::GetDefaultFocusId, &Node::SetDefaultFocusId>("navDefault").PropAttribute("css", core::String(u8"nav-default"));
        builder.AccessorProperty<&Node::GetTabIndex, &Node::SetTabIndex>("tabIndex").PropAttribute("css", core::String(u8"tab-index"));
        builder.AccessorProperty<&Node::IsFocusGroup, &Node::SetFocusGroup>("focusGroup").PropAttribute("css", core::String(u8"focus-group"));
        builder.AccessorProperty<&Node::GetTabCaptures, &Node::SetTabCaptures>("tabCaptures").PropAttribute("css", core::String(u8"tab-captures"));
        builder.AccessorProperty<&Node::GetCommand, &Node::SetCommand>("command").PropAttribute("css", core::String(u8"command"));
        builder.AccessorProperty<&Node::GetKeyContext, &Node::SetKeyContext>("keyContext").PropAttribute("css", core::String(u8"key-context"));
        builder.AccessorProperty<&Node::GetPointerEvents, &Node::SetPointerEvents>("pointerEvents").PropAttribute("css", core::String(u8"pointer-events"));
        builder.AccessorProperty<&Node::GetCursorName, &Node::SetCursorName>("cursor").PropAttribute("css", core::String(u8"cursor"));
        builder.AccessorProperty<&Node::GetTouchActionName, &Node::SetTouchActionName>("touchAction").PropAttribute("css", core::String(u8"touch-action"));
        builder.AccessorProperty<&Node::GetAutoTranslateName, &Node::SetAutoTranslateName>("autoTranslate")
            .PropAttribute("css", core::String(u8"auto-translate"));
        builder.AccessorProperty<&Node::GetLang, &Node::SetLang>("lang").PropAttribute("css", core::String(u8"lang"));
        builder.AccessorProperty<&Node::GetDirectionName, &Node::SetDirectionName>("direction");
        builder.AccessorProperty<&Node::GetMirrorOnRtl, &Node::SetMirrorOnRtl>("mirrorOnRtl")
            .PropAttribute("css", core::String(u8"mirror-on-rtl"));
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
        builder.AccessorProperty<&UIWidget::GetId, &UIWidget::SetId>("id");
        builder.AccessorProperty<&UIWidget::GetTooltipText, &UIWidget::SetTooltip>("tooltip")
            .PropAttribute("css", core::String(u8"tooltip"))
            .PropAttribute("translatable", true);
        builder.AccessorProperty<&UIWidget::IsTooltipInteractive, &UIWidget::SetTooltipInteractive>("tooltipInteractive")
            .PropAttribute("css", core::String(u8"tooltip-interactive")); // E16
        // Accessibility in markup (E9d): over what its type and its properties say.
        builder.AccessorProperty<&UIWidget::GetAccessRoleName, &UIWidget::SetAccessRoleName>("role").PropAttribute("css", core::String(u8"role"));
        builder.AccessorProperty<&UIWidget::GetAccessLabel, &UIWidget::SetAccessLabel>("ariaLabel")
            .PropAttribute("css", core::String(u8"aria-label"))
            .PropAttribute("translatable", true);
        builder.AccessorProperty<&UIWidget::GetAccessLabelledBy, &UIWidget::SetAccessLabelledBy>("ariaLabelledBy")
            .PropAttribute("css", core::String(u8"aria-labelledby"));
        builder.AccessorProperty<&UIWidget::GetAccessDescribedBy, &UIWidget::SetAccessDescribedBy>("ariaDescribedBy")
            .PropAttribute("css", core::String(u8"aria-describedby"));
        builder.AccessorProperty<&UIWidget::GetAccessControls, &UIWidget::SetAccessControls>("ariaControls")
            .PropAttribute("css", core::String(u8"aria-controls"));
        builder.AccessorProperty<&UIWidget::IsAccessHidden, &UIWidget::SetAccessHidden>("ariaHidden")
            .PropAttribute("css", core::String(u8"aria-hidden"));
        builder.AccessorProperty<&UIWidget::GetContextMenuId, &UIWidget::SetContextMenuId>("contextMenu")
            .PropAttribute("css", core::String(u8"context-menu"));
        builder.AccessorProperty<&UIWidget::GetDragType, &UIWidget::SetDragType>("dragType").PropAttribute("css", core::String(u8"drag-type"));
        builder.AccessorProperty<&UIWidget::GetDragValue, &UIWidget::SetDragValue>("dragValue").PropAttribute("css", core::String(u8"drag-value"));
        builder.AccessorProperty<&UIWidget::GetDragLabel, &UIWidget::SetDragLabel>("dragLabel").PropAttribute("css", core::String(u8"drag-label"));
        builder.AccessorProperty<&UIWidget::GetDragModeName, &UIWidget::SetDragModeName>("drag").PropAttribute("css", core::String(u8"drag"));
        builder.AccessorProperty<&UIWidget::GetDropReason, &UIWidget::SetDropReason>("dropReason").PropAttribute("css", core::String(u8"drop-reason"));
        builder.Method<&UIWidget::AddClass>("addClass");
        builder.Method<&UIWidget::RemoveClass>("removeClass");
        builder.Method<&UIWidget::HasClass>("hasClass");
        builder.Method<&UIWidget::ToggleClass>("toggleClass");
        builder.Method<&ElementOf<UIWidget>, UIWidget, Node>("of");
    }

    REFLECT_MEMBERS(Label, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"label")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Label::GetText, &Label::SetText>("text").PropAttribute("access", core::String(u8"name")).PropAttribute("translatable", true);
        builder.AccessorProperty<&Label::GetTextColor, &Label::SetTextColor>("textColor");
        builder.AccessorProperty<&Label::IsRich, &Label::SetRich>("rich");
        builder.AccessorProperty<&Label::GetTextOverflowName, &Label::SetTextOverflowName>("textOverflow")
            .PropAttribute("css", core::String(u8"text-overflow"));
        builder.AccessorProperty<&Label::GetLineClamp, &Label::SetLineClamp>("lineClamp").PropAttribute("css", core::String(u8"line-clamp"));
        builder.Method<&ElementOf<Label>, Label, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(RichText, "rtti::gui")
    {
        builder.Method<&ElementOf<RichText>, RichText, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ButtonBase, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"button")); // what a screen reader takes it for (E9d)
        builder.Attribute("accessActivate", true); // a screen reader may press it
        builder.AccessorProperty<&ButtonBase::GetText, &ButtonBase::SetText>("text").PropAttribute("access", core::String(u8"name")).PropAttribute("translatable", true);
        builder.AccessorProperty<&ButtonBase::IsToggle, &ButtonBase::SetToggle>("toggle").PropAttribute("css", core::String(u8"toggle"));
        builder.AccessorProperty<&ButtonBase::IsChecked, &ButtonBase::SetChecked>("checked")
            .PropAttribute("css", core::String(u8"checked"))
            .PropAttribute("twoWay", true); // the user changes it: a binding may write it back
        builder.AccessorProperty<&ButtonBase::GetName, &ButtonBase::SetName>("name").PropAttribute("css", core::String(u8"name"));
        builder.AccessorProperty<&ButtonBase::GetActionOnName, &ButtonBase::SetActionOnName>("actionOn")
            .PropAttribute("css", core::String(u8"action-on"));
        builder.AccessorProperty<&ButtonBase::IsRepeat, &ButtonBase::SetRepeat>("repeat").PropAttribute("css", core::String(u8"repeat"));
        builder.AccessorProperty<&ButtonBase::GetRepeatDelay, &ButtonBase::SetRepeatDelay>("repeatDelay")
            .PropAttribute("css", core::String(u8"repeat-delay"));
        builder.AccessorProperty<&ButtonBase::GetRepeatInterval, &ButtonBase::SetRepeatInterval>("repeatInterval")
            .PropAttribute("css", core::String(u8"repeat-interval"));
        builder.AccessorProperty<&ButtonBase::GetIconSource, &ButtonBase::SetIconSource>("icon").PropAttribute("css", core::String(u8"icon"));
        builder.Method<&ElementOf<ButtonBase>, ButtonBase, Node>("of");
    }

    REFLECT_MEMBERS(ButtonIndicator, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(Button, "rtti::gui")
    {
        builder.Method<&ElementOf<Button>, Button, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(CheckBox, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"checkbox")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&CheckBox::IsIndeterminate, &CheckBox::SetIndeterminate>("indeterminate")
            .PropAttribute("css", core::String(u8"indeterminate"));
        builder.Method<&ElementOf<CheckBox>, CheckBox, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(RadioButton, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"radio")); // what a screen reader takes it for (E9d)
        builder.Method<&ElementOf<RadioButton>, RadioButton, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ColorSwatch, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"button")); // a screen reader may press it
        builder.Attribute("accessActivate", true);
        builder.AccessorProperty<&ColorSwatch::GetColor, &ColorSwatch::SetColor>("color").PropAttribute("css", core::String(u8"color-value"));
        builder.Method<&ElementOf<ColorSwatch>, ColorSwatch, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ColorPicker, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"group"));
        builder.AccessorProperty<&ColorPicker::GetColor, &ColorPicker::SetColor>("color").PropAttribute("css", core::String(u8"color-value"))
            .PropAttribute("twoWay", true);
        builder.AccessorProperty<&ColorPicker::ShowsAlpha, &ColorPicker::SetShowsAlpha>("showsAlpha").PropAttribute("css", core::String(u8"shows-alpha"));
        builder.Method<&ElementOf<ColorPicker>, ColorPicker, Node>("of");
        builder.Creator();
    }

    RTTI_DEFINE_OBJECT(ColorPickerArea, "rtti::gui")

    // Toasts (T7 of round three): a host markup places; a request a script fills in and posts.
    RTTI_DEFINE_OBJECT(ToastCard, "rtti::gui")
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
        builder.ComputedProperty<&ToastHost::GetShownCountScript>("shownCount");
        builder.ComputedProperty<&ToastHost::GetWaitingCountScript>("waitingCount");
        builder.AccessorProperty<&ToastHost::GetMaxShownScript, &ToastHost::SetMaxShownScript>("maxShown");
        builder.Method<&FindToastHost, ToastHost, Node>("nearest"); // not `find`: a node's find(id) has the name
        builder.Method<&ElementOf<ToastHost>, ToastHost, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ToggleSwitch, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"switch")); // what a screen reader takes it for (E9d)
        builder.Method<&ElementOf<ToggleSwitch>, ToggleSwitch, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(RangeWidget, "rtti::gui")
    {
        builder.AccessorProperty<&RangeWidget::GetValue, &RangeWidget::SetValue>("value").PropAttribute("access", core::String(u8"value"))
            .PropAttribute("css", core::String(u8"value"))
            .PropAttribute("twoWay", true); // the user changes it: a binding may write it back
        builder.AccessorProperty<&RangeWidget::GetMin, &RangeWidget::SetMin>("min").PropAttribute("access", core::String(u8"min")).PropAttribute("css", core::String(u8"min"));
        builder.AccessorProperty<&RangeWidget::GetMax, &RangeWidget::SetMax>("max").PropAttribute("access", core::String(u8"max")).PropAttribute("css", core::String(u8"max"));
        builder.AccessorProperty<&RangeWidget::GetStep, &RangeWidget::SetStep>("step").PropAttribute("access", core::String(u8"step")).PropAttribute("css", core::String(u8"step"));
        builder.AccessorProperty<&RangeWidget::IsExponential, &RangeWidget::SetExponential>("exponential")
            .PropAttribute("css", core::String(u8"exponential"));
        builder.AccessorProperty<&RangeWidget::AllowsGreater, &RangeWidget::SetAllowGreater>("allowGreater")
            .PropAttribute("css", core::String(u8"allow-greater"));
        builder.AccessorProperty<&RangeWidget::AllowsLesser, &RangeWidget::SetAllowLesser>("allowLesser")
            .PropAttribute("css", core::String(u8"allow-lesser"));
        builder.Method<&ElementOf<RangeWidget>, RangeWidget, Node>("of");
    }

    REFLECT_MEMBERS(Slider, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"slider")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Slider::GetPage, &Slider::SetPage>("page").PropAttribute("css", core::String(u8"page"));
        builder.AccessorProperty<&Slider::GetOrientationName, &Slider::SetOrientationName>("orientation")
            .PropAttribute("css", core::String(u8"orientation"));
        builder.AccessorProperty<&Slider::GetTicks, &Slider::SetTicks>("ticks").PropAttribute("css", core::String(u8"ticks"));
        builder.Method<&ElementOf<Slider>, Slider, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ProgressBar, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"progress")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&ProgressBar::IsIndeterminate, &ProgressBar::SetIndeterminate>("indeterminate")
            .PropAttribute("css", core::String(u8"indeterminate"));
        builder.Method<&ElementOf<ProgressBar>, ProgressBar, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TextEditBase, "rtti::gui")
    {
        builder.AccessorProperty<&TextEditBase::GetPlaceholder, &TextEditBase::SetPlaceholder>("placeholder").PropAttribute("access", core::String(u8"description"))
            .PropAttribute("css", core::String(u8"placeholder"))
            .PropAttribute("translatable", true);
        builder.AccessorProperty<&TextEditBase::GetMaxLength, &TextEditBase::SetMaxLength>("maxLength").PropAttribute("css", core::String(u8"max-length"));
        builder.AccessorProperty<&TextEditBase::IsReadOnly, &TextEditBase::SetReadOnly>("readOnly").PropAttribute("css", core::String(u8"read-only"));
        builder.AccessorProperty<&TextEditBase::GetInputFilterName, &TextEditBase::SetInputFilterName>("inputFilter")
            .PropAttribute("css", core::String(u8"input-filter"));
        builder.AccessorProperty<&TextEditBase::GetText, &TextEditBase::SetText>("text").PropAttribute("access", core::String(u8"value"))
            .PropAttribute("css", core::String(u8"text"))
            .PropAttribute("twoWay", true); // the user changes it: a binding may write it back
        builder.Method<&ElementOf<TextEditBase>, TextEditBase, Node>("of");
    }

    REFLECT_MEMBERS(TextField, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"textbox")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&TextField::IsPassword, &TextField::SetPassword>("password")
            .PropAttribute("css", core::String(u8"password"))
            .PropAttribute("access", core::String(u8"secret")); // its value is not read out (E9d)
        builder.Method<&ElementOf<TextField>, TextField, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TextArea, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"textarea")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&TextArea::GetRows, &TextArea::SetRows>("rows").PropAttribute("css", core::String(u8"rows"));
        builder.Method<&ElementOf<TextArea>, TextArea, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Panel, "rtti::gui")
    {
        builder.Method<&ElementOf<Panel>, Panel, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ScrollView, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"scrollview")); // what a screen reader takes it for (E9d)
        builder.Method<&ElementOf<ScrollView>, ScrollView, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(EditableLabel, "rtti::gui")
    {
        builder.Method<&EditableLabel::BeginEdit>("beginEdit");
        builder.Method<&ElementOf<EditableLabel>, EditableLabel, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ExpanderHeader, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(Expander, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"group")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Expander::GetTitleString, &Expander::SetTitleString>("title").PropAttribute("access", core::String(u8"name")).PropAttribute("css", core::String(u8"title"));
        builder.AccessorProperty<&Expander::IsOpen, &Expander::SetOpen>("open").PropAttribute("access", core::String(u8"expanded"))
            .PropAttribute("css", core::String(u8"open"))
            .PropAttribute("twoWay", true); // the user opens it: a binding may write it back
        builder.AccessorProperty<&Expander::GetName, &Expander::SetName>("name").PropAttribute("css", core::String(u8"name"));
        builder.AccessorProperty<&Expander::IsAnimated, &Expander::SetAnimated>("animate").PropAttribute("css", core::String(u8"animate"));
        builder.Method<&Expander::Toggle>("toggle");
        builder.Method<&ElementOf<Expander>, Expander, Node>("of");
        builder.Creator();
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
        builder.Attribute("accessRole", core::String(u8"tablist")); // what a screen reader takes it for (E9d)
    }

    REFLECT_MEMBERS(Tab, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"tab")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Tab::IsClosable, &Tab::SetClosable>("closable").PropAttribute("css", core::String(u8"closable"));
        builder.Method<&ElementOf<Tab>, Tab, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TabBar, "rtti::gui")
    {
        builder.AccessorProperty<&TabBar::GetSelectedIndex, &TabBar::SetSelectedIndex>("selected")
            .PropAttribute("css", core::String(u8"selected"))
            .PropAttribute("twoWay", true); // the user selects: a binding may write it back
        builder.AccessorProperty<&TabBar::GetCloseDisplayName, &TabBar::SetCloseDisplayName>("closeDisplay")
            .PropAttribute("css", core::String(u8"close-display"));
        builder.AccessorProperty<&TabBar::GetListDisplayName, &TabBar::SetListDisplayName>("listDisplay")
            .PropAttribute("css", core::String(u8"list-display"));
        builder.AccessorProperty<&TabBar::HasCloseAll, &TabBar::SetCloseAll>("closeAll").PropAttribute("css", core::String(u8"close-all"));
        builder.AccessorProperty<&TabBar::IsReorderable, &TabBar::SetReorderable>("reorderable")
            .PropAttribute("css", core::String(u8"reorderable"));
        builder.AccessorProperty<&TabBar::GetGroup, &TabBar::SetGroup>("group").PropAttribute("css", core::String(u8"group"));
        builder.Method<&TabBar::GetTabCount>("tabCount");
        builder.Method<&TabBar::RemoveTab>("removeTab");
        builder.Method<&TabBar::MoveTab>("moveTab");
        builder.Method<&ElementOf<TabBar>, TabBar, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TabPage, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"tabpanel")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&TabPage::GetTitleString, &TabPage::SetTitleString>("title").PropAttribute("access", core::String(u8"name")).PropAttribute("css", core::String(u8"title"));
        builder.AccessorProperty<&TabPage::GetIconSource, &TabPage::SetIconSource>("icon").PropAttribute("css", core::String(u8"icon"));
        builder.AccessorProperty<&TabPage::IsClosable, &TabPage::SetClosable>("closable").PropAttribute("css", core::String(u8"closable"));
        builder.Method<&ElementOf<TabPage>, TabPage, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TabPageHost, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(TabView, "rtti::gui")
    {
        builder.AccessorProperty<&TabView::GetSelectedIndex, &TabView::SetSelectedIndex>("selected")
            .PropAttribute("css", core::String(u8"selected"))
            .PropAttribute("twoWay", true);
        builder.AccessorProperty<&TabView::GetCloseDisplayName, &TabView::SetCloseDisplayName>("closeDisplay")
            .PropAttribute("css", core::String(u8"close-display"));
        builder.AccessorProperty<&TabView::GetListDisplayName, &TabView::SetListDisplayName>("listDisplay")
            .PropAttribute("css", core::String(u8"list-display"));
        builder.AccessorProperty<&TabView::HasCloseAll, &TabView::SetCloseAll>("closeAll").PropAttribute("css", core::String(u8"close-all"));
        builder.AccessorProperty<&TabView::IsReorderable, &TabView::SetReorderable>("reorderable")
            .PropAttribute("css", core::String(u8"reorderable"));
        builder.AccessorProperty<&TabView::GetGroup, &TabView::SetGroup>("group").PropAttribute("css", core::String(u8"group"));
        builder.Method<&TabView::GetPageCount>("pageCount");
        builder.Method<&TabView::RemovePage>("removePage");
        builder.Method<&ElementOf<TabView>, TabView, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(SpinButton, "rtti::gui")
    {
    }

    REFLECT_MEMBERS(NumberField, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"spinbutton")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&NumberField::GetValue, &NumberField::SetValue>("value").PropAttribute("access", core::String(u8"value"))
            .PropAttribute("css", core::String(u8"value"))
            .PropAttribute("twoWay", true); // the user changes it: a binding may write it back
        builder.AccessorProperty<&NumberField::GetMin, &NumberField::SetMin>("min").PropAttribute("access", core::String(u8"min")).PropAttribute("css", core::String(u8"min"));
        builder.AccessorProperty<&NumberField::GetMax, &NumberField::SetMax>("max").PropAttribute("access", core::String(u8"max")).PropAttribute("css", core::String(u8"max"));
        builder.AccessorProperty<&NumberField::GetStep, &NumberField::SetStep>("step").PropAttribute("access", core::String(u8"step")).PropAttribute("css", core::String(u8"step"));
        builder.AccessorProperty<&NumberField::GetPage, &NumberField::SetPage>("page").PropAttribute("css", core::String(u8"page"));
        builder.AccessorProperty<&NumberField::IsInteger, &NumberField::SetInteger>("integer").PropAttribute("css", core::String(u8"integer"));
        builder.AccessorProperty<&NumberField::GetPrefix, &NumberField::SetPrefix>("prefix").PropAttribute("css", core::String(u8"prefix"));
        builder.AccessorProperty<&NumberField::GetSuffix, &NumberField::SetSuffix>("suffix").PropAttribute("css", core::String(u8"suffix"));
        builder.AccessorProperty<&NumberField::AllowsGreater, &NumberField::SetAllowGreater>("allowGreater")
            .PropAttribute("css", core::String(u8"allow-greater"));
        builder.AccessorProperty<&NumberField::AllowsLesser, &NumberField::SetAllowLesser>("allowLesser")
            .PropAttribute("css", core::String(u8"allow-lesser"));
        builder.Method<&ElementOf<NumberField>, NumberField, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Separator, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"separator")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Separator::GetThickness, &Separator::SetThickness>("thickness").PropAttribute("css", core::String(u8"thickness"));
        builder.Method<&ElementOf<Separator>, Separator, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Splitter, "rtti::gui")
    {
        builder.AccessorProperty<&Splitter::GetAxisName, &Splitter::SetAxisName>("axis").PropAttribute("css", core::String(u8"axis"));
        builder.AccessorProperty<&Splitter::GetWeightsText, &Splitter::SetWeightsText>("weights").PropAttribute("css", core::String(u8"weights"));
        builder.Method<&Splitter::ResetWeights>("resetWeights");
        builder.Method<&ElementOf<Splitter>, Splitter, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(SplitterHandle, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"separator")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&SplitterHandle::GetValue, &SplitterHandle::SetValue>("value").PropAttribute("access", core::String(u8"value"));
        builder.ComputedProperty<&SplitterHandle::GetMin>("min").PropAttribute("access", core::String(u8"min"));
        builder.ComputedProperty<&SplitterHandle::GetMax>("max").PropAttribute("access", core::String(u8"max"));
        builder.AccessorProperty<&SplitterHandle::GetThickness, &SplitterHandle::SetThickness>("thickness")
            .PropAttribute("css", core::String(u8"thickness"));
        builder.Method<&ElementOf<SplitterHandle>, SplitterHandle, Node>("of");
    }

    REFLECT_MEMBERS(Spacer, "rtti::gui")
    {
        builder.AccessorProperty<&Spacer::GetSpace, &Spacer::SetSpace>("size").PropAttribute("css", core::String(u8"size"));
        builder.Method<&ElementOf<Spacer>, Spacer, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Image, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"image")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Image::GetSource, &Image::SetSource>("src").PropAttribute("css", core::String(u8"src"));
        builder.AccessorProperty<&Image::GetFitName, &Image::SetFitName>("objectFit").PropAttribute("css", core::String(u8"object-fit"));
        builder.AccessorProperty<&Image::GetObjectPositionName, &Image::SetObjectPositionName>("objectPosition")
            .PropAttribute("css", core::String(u8"object-position"));
        builder.AccessorProperty<&Image::GetImageColor, &Image::SetImageColor>("imageColor").PropAttribute("css", core::String(u8"image-color"));
        builder.Method<&ElementOf<Image>, Image, Node>("of");
        builder.Creator();
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
        builder.AccessorProperty<&TreeItem::GetText, &TreeItem::SetText>("text");
        builder.AccessorProperty<&TreeItem::IsExpanded, &TreeItem::SetExpanded>("expanded").PropAttribute("css", core::String(u8"expanded"));
        builder.Creator();
    }

    REFLECT_MEMBERS(TreeView, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"tree")); // what a screen reader takes it for (E9d)
        builder.Method<&TreeView::ExpandItem>("expandItem");
        builder.Method<&TreeView::CollapseItem>("collapseItem");
        builder.Method<&ElementOf<TreeView>, TreeView, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(TableItem, "rtti::gui")
    {
        builder.AccessorProperty<&TableItem::GetCells, &TableItem::SetCells>("cells");
        builder.Creator();
    }

    REFLECT_MEMBERS(TableView, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"table")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&TableView::GetColumnsText, &TableView::SetColumnsText>("columns").PropAttribute("css", core::String(u8"columns"));
        builder.AccessorProperty<&TableView::GetColumnWidthsText, &TableView::SetColumnWidthsText>("columnWidths")
            .PropAttribute("css", core::String(u8"column-widths"));
        builder.AccessorProperty<&TableView::IsEditable, &TableView::SetEditable>("editable").PropAttribute("css", core::String(u8"editable"));
        builder.Method<&ElementOf<TableView>, TableView, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ScrollBar, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"scrollbar")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&ScrollBar::GetPage, &ScrollBar::SetPage>("page").PropAttribute("css", core::String(u8"page"));
        builder.AccessorProperty<&ScrollBar::GetOrientationName, &ScrollBar::SetOrientationName>("orientation")
            .PropAttribute("css", core::String(u8"orientation"));
        builder.Method<&ElementOf<ScrollBar>, ScrollBar, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(MessageBox, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"dialog")); // what a screen reader takes it for (E9d)
        builder.ComputedProperty<&MessageBox::GetResultName>("result");
        builder.Method<&MessageBox::Show>("show");
        builder.Method<&ElementOf<MessageBox>, MessageBox, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(MenuSeparator, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"separator")); // what a screen reader takes it for (E9d)
        builder.Creator();
    }

    REFLECT_MEMBERS(MenuItem, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"menuitem")); // what a screen reader takes it for (E9d)
        builder.Attribute("accessActivate", true); // a screen reader may press it
        builder.AccessorProperty<&MenuItem::GetTextString, &MenuItem::SetTextString>("text")
            .PropAttribute("access", core::String(u8"name"))
            .PropAttribute("translatable", true);
        builder.AccessorProperty<&MenuItem::IsCheckable, &MenuItem::SetCheckable>("checkable").PropAttribute("css", core::String(u8"checkable"));
        builder.AccessorProperty<&MenuItem::IsChecked, &MenuItem::SetChecked>("checked").PropAttribute("css", core::String(u8"checked"));
        builder.Method<&ElementOf<MenuItem>, MenuItem, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Menu, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"menu")); // what a screen reader takes it for (E9d)
        builder.Method<&Menu::Close>("close");
        builder.Method<&Menu::OpenAtPoint>("openAt"); // a script's own menus (E16)
        builder.Method<&Menu::OpenBelowNode, bool, Node>("openBelow");
        builder.Method<&Menu::IsOpen>("isOpen");
        builder.Method<&ElementOf<Menu>, Menu, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(MenuBar, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"menubar")); // what a screen reader takes it for (E9d)
        builder.Method<&ElementOf<MenuBar>, MenuBar, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ItemView, "rtti::gui")
    {
        builder.AccessorProperty<&ItemView::GetItemsText, &ItemView::SetItemsText>("items").PropAttribute("css", core::String(u8"items"));
        builder.Method<&ItemView::SetListModel>("setModel"); // a script's ListModel (E16)
        builder.AccessorProperty<&ItemView::GetRowHeight, &ItemView::SetRowHeight>("rowHeight").PropAttribute("css", core::String(u8"row-height"));
        builder.AccessorProperty<&ItemView::GetEstimatedRowHeight, &ItemView::SetEstimatedRowHeight>("estimatedRowHeight")
            .PropAttribute("css", core::String(u8"estimated-row-height"));
        builder.AccessorProperty<&ItemView::GetSelectedItem, &ItemView::SetSelectedItem>("selected")
            .PropAttribute("css", core::String(u8"selected"))
            .PropAttribute("twoWay", true); // the user selects: a binding may write it back
        builder.AccessorProperty<&ItemView::GetSelectionModeName, &ItemView::SetSelectionModeName>("selectionMode")
            .PropAttribute("css", core::String(u8"selection-mode"));
        builder.AccessorProperty<&ItemView::GetRowTypeColumn, &ItemView::SetRowTypeColumn>("rowTypeColumn")
            .PropAttribute("css", core::String(u8"row-type-column"));
        builder.AccessorProperty<&ItemView::GetLayoutModeName, &ItemView::SetLayoutModeName>("layout").PropAttribute("css", core::String(u8"layout"));
        builder.AccessorProperty<&ItemView::GetCellWidth, &ItemView::SetCellWidth>("cellWidth").PropAttribute("css", core::String(u8"cell-width"));
        builder.AccessorProperty<&ItemView::GetCellHeight, &ItemView::SetCellHeight>("cellHeight").PropAttribute("css", core::String(u8"cell-height"));
        builder.Method<&ItemView::BeginEdit>("beginEdit");
        builder.Method<&ItemView::SelectAll>("selectAll");
        builder.Method<&ItemView::ClearSelection>("clearSelection");
        builder.Method<&ElementOf<ItemView>, ItemView, Node>("of");
    }

    REFLECT_MEMBERS(ListView, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"list")); // what a screen reader takes it for (E9d)
        builder.Method<&ElementOf<ListView>, ListView, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ListBox, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"list")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&ListBox::GetItemsText, &ListBox::SetItemsText>("items").PropAttribute("css", core::String(u8"items"));
        builder.Method<&ElementOf<ListBox>, ListBox, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(ComboBox, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"combobox")); // what a screen reader takes it for (E9d)
        builder.Attribute("accessActivate", true); // a screen reader may press it
        builder.AccessorProperty<&ComboBox::GetItemsText, &ComboBox::SetItemsText>("items").PropAttribute("css", core::String(u8"items"));
        builder.AccessorProperty<&ComboBox::GetSelectedIndex, &ComboBox::SetSelectedIndex>("selected")
            .PropAttribute("css", core::String(u8"selected"))
            .PropAttribute("twoWay", true); // the user picks: a binding may write it back
        builder.AccessorProperty<&ComboBox::GetPlaceholder, &ComboBox::SetPlaceholder>("placeholder")
            .PropAttribute("css", core::String(u8"placeholder"))
            .PropAttribute("translatable", true);
        builder.Method<&ElementOf<ComboBox>, ComboBox, Node>("of");
        builder.Creator();
    }

    REFLECT_MEMBERS(Window, "rtti::gui")
    {
        builder.Attribute("accessRole", core::String(u8"window")); // what a screen reader takes it for (E9d)
        builder.AccessorProperty<&Window::GetTitle, &Window::SetTitle>("title").PropAttribute("access", core::String(u8"name")).PropAttribute("css", core::String(u8"title"));
        // A script's own windows (E16): opened where they are or modal, closed, listened to (`close`).
        builder.AccessorProperty<&Window::IsClosable, &Window::SetClosable>("closable").PropAttribute("css", core::String(u8"closable"));
        builder.AccessorProperty<&Window::IsResizable, &Window::SetResizable>("resizable").PropAttribute("css", core::String(u8"resizable"));
        builder.Method<&Window::OpenInPlace>("open");
        builder.Method<&Window::OpenModalOver>("openModal");
        builder.Method<&Window::Close>("close");
        builder.Method<&Window::IsOpen>("isOpen");
        builder.Method<&ElementOf<Window>, Window, Node>("of");
        builder.Creator();
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
