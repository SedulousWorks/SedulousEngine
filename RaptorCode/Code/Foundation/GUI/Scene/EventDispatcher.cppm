// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :event_dispatcher partition
//
// EventDispatcher: routes abstract input into the node tree. Ported from eepp's
// Scene::EventDispatcher, but the core is platform-agnostic: instead of hooking a window's
// Input, it exposes an Inject* API that a gui.shell bridge feeds with already-abstracted
// events (from InputSurface/InputRouter). It hit-tests via the root's OverFind, keeps the hover
// and press paths, the focus and the pointer capture, and starts each input event's route
// (Node::RouteEvent: capture, target, bubble). Its refs are non-owning Node*, dropped when a
// subtree leaves the tree (NotifySubtreeRemoved).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:event_dispatcher;

import foundation.core; // Float2, StringView
import :node;
import :rect;
import :event;
import :clipboard;
import :navigation; // directional focus (G7)
import :popup_placement;
import :keymap;     // Keystroke, PadButton
import :reactive;   // Observable (focus, for commands)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// How a popup closes (E5, after the web's popover kinds): `Auto` on a press outside it and on
    /// `back` (Escape, the pad's East: K1), and when another auto popup that it does not hold opens; `Manual` only from code (a
    /// dialog); `Hint` (a tooltip) on any press or key, never closing the others, never taking focus
    /// or the pointer.
    enum class PopupKind : u8
    {
        Auto,
        Manual,
        Hint,
    };

    struct PopupOptions
    {
        PopupKind Kind = PopupKind::Auto;
        /// Everything below it is inert while it is open: no pointer, no keys, no bindings.
        bool Modal = false;
        /// Focus moves into it (its first focusable node, else itself if focusable) and comes back
        /// when it closes; it is a containing navigation scope meanwhile.
        bool TakesFocus = false;
        /// What it is placed against, again every layout pass: a node, else a rectangle in the
        /// root's space (a point for a context menu), else nothing (it keeps its own position).
        Node* Anchor = nullptr;
        Rect AnchorRect{};
        bool HasAnchorRect = false;
        PopupPlacement Placement{};
        /// Sized by what it holds, measured again every layout pass (a tooltip, whose font a sheet
        /// gives it after it opens); else its own size when it opened.
        bool FitContent = false;
        /// The pointer passes through it to what is below (a drag's preview).
        bool PassesPointer = false;
        /// Closed, it goes back where it stood before it opened, rather than leaving the tree (a
        /// script's own popup or menu: nothing else keeps it, so leaving would free it). E16.
        bool ReturnHome = false;
        /// Told when it closes, and why (after the `toggle` event).
        core::Function<void(PopupCloseReason)> OnClosed;
    };

    // A drag's layer in the top layer (E7): the root's size, passing the pointer through, its
    // children (the preview, the hint) each at the point the dispatcher gives it, at its own size.
    class DragLayer : public Node
    {
        RTTI_OBJECT(DragLayer, Node)
    public:
        void Place(Node& child, core::Float2 at)
        {
            for (Placed& p : m_placed)
                if (p.Child == &child)
                {
                    p.At = at;
                    RequestLayout();
                    return;
                }
            m_placed.PushBack(Placed{&child, at});
            RequestLayout();
        }

        // A child gone (a hint replaced) is forgotten, matched by identity, never followed.
        void OnChildrenChanged() override
        {
            for (usize i = m_placed.Size(); i-- > 0;)
                if (GetChildIndex(m_placed[i].Child) == kInvalidIndex)
                    m_placed.RemoveAt(i);
        }

    protected:
        void OnLayout() override
        {
            for (const Placed& p : m_placed)
                if (GetChildIndex(p.Child) != kInvalidIndex)
                {
                    const core::Float2 size = p.Child->Measure(LayoutConstraints{});
                    p.Child->Arrange(Rect{p.At.x, p.At.y, size.x, size.y});
                }
        }

    private:
        struct Placed
        {
            Node* Child; // its child
            core::Float2 At;
        };
        core::Array<Placed> m_placed;
    };

    class EventDispatcher;

    /// Where a GUI's roots are on the screen, told by a host that places its windows (D6): a drag
    /// goes on over another root of the GUI, and one let go over no root ends outside, at a screen
    /// point. Points are each root's pointer units (as input arrives).
    class IRootPlaces
    {
    public:
        virtual ~IRootPlaces() = default;
        /// The dispatcher of the root under `screen`, and the point in it; null over none.
        virtual EventDispatcher* DispatcherAt(core::Float2 screen, core::Float2& local) = 0;
        /// Where `local` in `dispatcher`'s root is on the screen; false when that is not known.
        virtual bool ToScreen(const EventDispatcher& dispatcher, core::Float2 local, core::Float2& screen) = 0;
    };

    class EventDispatcher
    {
    public:
        explicit EventDispatcher(Node* root) noexcept : m_root(root) {}

        [[nodiscard]] Node* GetRoot() const noexcept { return m_root; }

        // The system-clipboard adapter (non-owning; supplied by the gui.shell bridge / app).
        // Widgets reach it via GetEventDispatcher()->GetClipboard(); null = no clipboard, so
        // cut/copy/paste become no-ops.
        void SetClipboard(IClipboard* clipboard) noexcept { m_clipboard = clipboard; }
        [[nodiscard]] IClipboard* GetClipboard() const noexcept { return m_clipboard; }


        [[nodiscard]] Node* GetOverNode() const noexcept { return m_overNode; }
        /// Whether the keyboard or the pad drives it now (the last input was a key, a pad button or
        /// a direction, not the pointer): a menu opened then lights its first item.
        [[nodiscard]] bool IsUsingKeyboard() const noexcept { return m_inputKind != InputKind::Pointer; }

        // === The input kind (K2b of Specs/gui-lab-evolution-3.md) ===
        /// What drives the GUI now: the pointer, the keyboard or a pad. The focus ring follows it
        /// (shown for the keys and the pad, hidden for the pointer, as Godot's does), a pad hides
        /// the cursor, a sheet reads it as `@media (input: ...)`, and the root hears `inputkind`.
        [[nodiscard]] InputKind GetInputKind() const noexcept { return m_inputKind; }
        /// The input kind, read as a binding's dependency (a button prompt follows it).
        [[nodiscard]] InputKind ObserveInputKind() const
        {
            m_inputKindChanged.Track();
            return m_inputKind;
        }
        /// Sets the kind: a host's tracker saw another kind of input (foundation.input's, which
        /// GUI.Shell's bridge passes on as it changes: a mouse moved, a stick pushed, which reach
        /// no widget). The dispatcher also follows what it is given (a press, a key, a pad button
        /// or direction), so a host without a tracker, or a test, still drives it.
        void SetInputKind(InputKind kind) { ApplyInputKind(kind); }

        // === Tooltips (E5) ===
        // The nearest tooltip text up the parent chain from the hovered node shows as a hint popup
        // after the delay, on this dispatcher's clock (the GUI's update ticks it); just after one
        // hid, the next shows at once. Any press or key hides it until the pointer moves to another.
        // A finger shows one by a long press on a node with no context menu.
        void SetTooltipDelay(f32 seconds) noexcept { m_tipDelay = core::Max(0.0f, seconds); }
        /// While the keys move the focus, the focused control's tooltip shows after the delay, below
        /// it (E16; on by default). The pointer's tooltip goes first.
        void SetKeyboardTooltips(bool on) noexcept { m_keyboardTooltips = on; }
        [[nodiscard]] bool HasKeyboardTooltips() const noexcept { return m_keyboardTooltips; }
        [[nodiscard]] f32 GetTooltipDelay() const noexcept { return m_tipDelay; }
        /// The tooltip shown now, or null.
        [[nodiscard]] Node* GetShownTooltip() const { return m_tip && IsPopupOpen(*m_tip) ? m_tip.Get() : nullptr; }

        /// Asks for the focused node's context menu, at its bottom-left (Shift+F10, the Menu key):
        /// a `contextmenu` event there. True when something opened one.
        bool InjectContextMenu()
        {
            Node* target = KeyTarget();
            if (target == nullptr)
                return false;
            UseKeyboard();
            MouseEvent event(EventType::ContextMenu, target, target->ConvertToWorldSpace(core::Float2{0.0f, target->GetSize().y}));
            return target->RouteEvent(event);
        }
        [[nodiscard]] Node* GetFocusNode() const noexcept { return m_focusNode; }
        /// What the last arrow, d-pad or stick move weighed (E8c).
        [[nodiscard]] const NavTrace& GetLastNavigation() const noexcept { return m_lastNavigation; }
        /// The focused node, read as a binding's dependency (a command's availability follows it).
        [[nodiscard]] Node* ObserveFocus() const
        {
            m_focusChanged.Track();
            return m_focusNode;
        }
        [[nodiscard]] core::Float2 GetMousePosition() const noexcept { return m_mousePos; }

        // True if the currently focused node wants platform text input (the gui.shell bridge
        // reconciles the window's IME state against this each frame).
        [[nodiscard]] bool WantsTextInput() const
        {
            return m_focusNode != nullptr && m_focusNode->WantsTextInput();
        }
        /// Whether the focused node's text input is secret (a password).
        [[nodiscard]] bool IsTextInputSecret() const { return m_focusNode != nullptr && m_focusNode->IsTextInputSecret(); }

        // === Injection API (fed by the shell bridge) ===
        // Each returns whether the GUI used the input: a handler took it, or the pointer is over a
        // node that takes it (IsPointerOver), so a game host knows a click was the UI's.
        /// `modifiers` held during the move (a drag that scrubs finer with Shift).
        bool InjectMouseMove(core::Float2 position, u32 modifiers = 0) { return PointerMove(position, PointerType::Mouse, 0, modifiers); }
        bool InjectMouseDown(core::Float2 position, MouseButton button, u32 modifiers = 0)
        {
            return PointerDown(position, button, modifiers, PointerType::Mouse, 0);
        }
        bool InjectMouseUp(core::Float2 position, MouseButton button, u32 modifiers = 0)
        {
            return PointerUp(position, button, modifiers, PointerType::Mouse, 0);
        }

        // === Touch === The first finger down drives the pointer as the mouse does (a press,
        // moves, a release, a click), its events marked as touch; every finger down is followed,
        // where it went down and where it is (E17c: two make a gesture), but no other drives the
        // pointer. A finger hovers only while it is down, so nothing stays hovered after a tap.
        //
        // A finger is a tap or a pan (gpui-ce's machine): once it moves past kPanSlop the nearest
        // scroller under where it went down that can move that way takes it, the press is
        // cancelled (the row under the finger is not clicked), and the content follows the
        // finger; let go moving, the scroller flings. A finger that lands on a flinging scroller
        // catches it: the fling stops and that touch clicks nothing.
        bool InjectTouchDown(u64 finger, core::Float2 position)
        {
            if (FindFinger(finger) < 0)
                m_fingers.PushBack(Finger{finger, position, position});
            if (BeginGesture())
                return true; // a second finger over a node that takes gestures
            if (m_touchActive)
                return false; // a second finger: followed, not the pointer
            m_touchActive = true;
            m_touchFinger = finger;
            m_panning = false;
            m_panScroller = nullptr;
            m_panSampleCount = 0;
            bool caught = false;
            for (Node* n = HitTest(position); n != nullptr; n = n->GetParent())
                if (n->IsFlinging())
                {
                    n->StopFling();
                    caught = true;
                }
            const bool used = PointerDown(position, MouseButton::Left, 0, PointerType::Touch, finger);
            AddPanSample(position);
            if (caught)
            {
                CancelPointer(); // a catch, not a tap
                m_longPressArmed = false;
                return true;
            }
            return used;
        }
        bool InjectTouchMove(u64 finger, core::Float2 position)
        {
            if (const i32 at = FindFinger(finger); at >= 0)
                m_fingers[static_cast<usize>(at)].Now = position;
            if (m_gesturing && IsGestureFinger(finger))
            {
                MoveGesture();
                return true;
            }
            if (!m_touchActive || finger != m_touchFinger)
                return false;
            AddPanSample(position);
            if (!m_panning && !m_dragActive && !m_touchDragArmed)
            {
                const core::Float2 moved{position.x - m_pressAt.x, position.y - m_pressAt.y};
                // Panned only along an axis the touch-action where it went down leaves to the GUI;
                // along another, the finger goes on as the pointer (the node's own drag).
                const Node* under = HitTest(m_pressAt);
                const u8 allowed = under != nullptr ? under->EffectiveTouchActions() : kTouchAuto;
                const u8 axis = core::Abs(moved.x) > core::Abs(moved.y) ? kTouchPanX : kTouchPanY;
                if ((core::Abs(moved.x) > Dips(kPanSlop) || core::Abs(moved.y) > Dips(kPanSlop)) && (allowed & axis) != 0)
                    if (Node* scroller = PanScrollerFor(moved))
                    {
                        m_panning = true;
                        m_panScroller = scroller;
                        m_panLast = m_pressAt; // the content keeps to the finger from where it went down
                        CancelPointer();
                        m_longPressArmed = false;
                    }
            }
            if (m_panning)
            {
                if (m_panScroller != nullptr)
                    m_panScroller->ScrollBy(InNodeUnits(*m_panScroller, m_panLast, core::Float2{m_panLast.x - position.x, m_panLast.y - position.y}));
                m_panLast = position;
                m_mousePos = position;
                return true;
            }
            return PointerMove(position, PointerType::Touch, finger);
        }
        bool InjectTouchUp(u64 finger, core::Float2 position)
        {
            if (const i32 at = FindFinger(finger); at >= 0)
                m_fingers.RemoveAt(static_cast<usize>(at));
            if (m_gesturing && IsGestureFinger(finger))
            {
                EndGesture(EventType::GestureEnd); // the other finger, still down, does nothing more
                return true;
            }
            if (!m_touchActive || finger != m_touchFinger)
                return false;
            m_touchActive = false;
            if (m_panning)
            {
                AddPanSample(position);
                m_panning = false;
                const core::Float2 v = PanVelocity();
                if (m_panScroller != nullptr && core::Abs(v.x) + core::Abs(v.y) > Dips(kFlingMinSpeed))
                    m_panScroller->Fling(InNodeUnits(*m_panScroller, position, core::Float2{-v.x, -v.y}));
                m_panScroller = nullptr;
                UpdateHoverPath(nullptr, position);
                return true;
            }
            if (m_touchDragArmed && !m_dragActive)
                CancelPointer(); // held to drag and let go still: neither a drag nor a tap
            m_touchDragArmed = false;
            const bool used = PointerUp(position, MouseButton::Left, 0, PointerType::Touch, finger);
            UpdateHoverPath(nullptr, position); // the finger lifted: nothing is under it
            return used;
        }
        /// A finger down: its id, where it went down and where it is now (device pixels).
        struct Finger
        {
            u64 Id = 0;
            core::Float2 Start{};
            core::Float2 Now{};
        };
        /// The fingers down, in the order they went down.
        [[nodiscard]] core::Span<const Finger> GetFingers() const noexcept { return core::Span<const Finger>(m_fingers.Data(), m_fingers.Size()); }
        /// A finger the platform took back (a system gesture): no release follows. Its gesture is
        /// cancelled, its press cancelled, its pan ended where it is.
        bool InjectTouchCancel(u64 finger)
        {
            if (const i32 at = FindFinger(finger); at >= 0)
                m_fingers.RemoveAt(static_cast<usize>(at));
            if (m_gesturing && IsGestureFinger(finger))
            {
                EndGesture(EventType::GestureCancel);
                return true;
            }
            if (!m_touchActive || finger != m_touchFinger)
                return false;
            if (!m_panning)
                CancelPointer();
            m_touchActive = false;
            m_panning = false;
            m_panScroller = nullptr;
            m_longPressArmed = false;
            m_touchDragArmed = false;
            UpdateHoverPath(nullptr, m_mousePos);
            return true;
        }
        /// A trackpad's pinch at the pointer (the platform's gesture, its fingers never touches):
        /// begun, updated by `scaleDelta` (above 1 spreading), ended. The same gesture events as
        /// two fingers make, for a node whose touch-action leaves pinch-zoom out, marked as the
        /// mouse's; no rotation and no translation.
        bool InjectPinch(EventType phase, f32 scaleDelta)
        {
            if (phase == EventType::GestureStart)
            {
                if (m_gesturing)
                    return false;
                Node* target = HitTest(m_mousePos);
                if (target == nullptr || (target->EffectiveTouchActions() & kTouchPinchZoom) != 0)
                    return false;
                m_gestureIds[0] = m_gestureIds[1] = kNoFinger;
                m_gestureFocus0 = m_mousePos;
                m_gestureScale = 1.0f;
                m_gestureRotation = 0.0f;
                m_gestureTranslation = core::Float2{0.0f, 0.0f};
                m_gesturePointer = PointerType::Mouse;
                m_gestureTarget = core::RefPtr<Node>(target);
                m_gesturing = true;
                RouteGesture(EventType::GestureStart, 1.0f, 0.0f, core::Float2{0.0f, 0.0f});
                return true;
            }
            if (!m_gesturing || m_gesturePointer != PointerType::Mouse)
                return false;
            if (phase == EventType::GestureChange)
            {
                if (m_gestureTarget->GetRootNode() != m_root)
                {
                    EndGesture(EventType::GestureCancel);
                    return true;
                }
                m_gestureScale *= scaleDelta;
                RouteGesture(EventType::GestureChange, scaleDelta, 0.0f, core::Float2{0.0f, 0.0f});
                return true;
            }
            EndGesture(phase == EventType::GestureCancel ? EventType::GestureCancel : EventType::GestureEnd);
            return true;
        }
        /// Two fingers are making a gesture (E17c).
        [[nodiscard]] bool IsGesturing() const noexcept { return m_gesturing; }
        /// Ends the gesture in progress as cancelled (a finger the platform took back): its target
        /// hears `gesturecancel`.
        void CancelGesture()
        {
            if (m_gesturing)
                EndGesture(EventType::GestureCancel);
        }
        /// A finger is panning a scroller (its press was cancelled).
        [[nodiscard]] bool IsPanning() const noexcept { return m_panning; }
        [[nodiscard]] bool IsTouchActive() const noexcept { return m_touchActive; }
        [[nodiscard]] i32 FindFinger(u64 id) const noexcept
        {
            for (usize i = 0; i < m_fingers.Size(); ++i)
                if (m_fingers[i].Id == id)
                    return static_cast<i32>(i);
            return -1;
        }

        /// Cancels the press in progress: the pressed node hears PointerCancel (a widget drops its
        /// drag), no release or click follows, and the press path and any capture clear. A
        /// scroller that starts panning under a finger calls it, so the row under the finger is
        /// not clicked at the end of the scroll.
        void CancelPointer()
        {
            Node* pressed = m_downNode;
            const core::RefPtr<Node> pin{pressed};
            m_downNode = nullptr;
            ClearPressPath();
            if (pressed != nullptr && pressed->IsTreeEnabled())
            {
                MouseEvent event(EventType::PointerCancel, pressed, m_mousePos);
                event.Pointer = m_touchActive ? PointerType::Touch : PointerType::Mouse;
                event.PointerId = m_touchActive ? m_touchFinger : 0;
                (void)pressed->RouteEvent(event);
            }
            if (m_captureNode != nullptr)
                ReleasePointer(*m_captureNode);
        }

        bool InjectMouseWheel(core::Float2 position, core::Float2 delta, u32 modifiers = 0)
        {
            Node* hit = HitTest(position);
            // Up from the node under the pointer: a scroller takes it, one at its end leaves it to
            // the one around it.
            bool used = false;
            if (hit != nullptr && hit->IsTreeEnabled())
            {
                WheelEvent event(hit, position, delta, modifiers);
                used = hit->RouteEvent(event);
            }
            return used || IsPointerTaken(hit);
        }

        // === Capturing the next key (E12 of Specs/gui-lab-evolution-2.md) ===
        /// The next key or pad button goes to `onKey` before the keymap, navigation or any widget
        /// sees it (a rebinding screen). A modifier pressed alone is taken as it is released (so
        /// Ctrl then S is Ctrl+S); the text a taken key types is dropped. Escape calls `onCancel`
        /// instead, unless `takeEscape`. A capture asked for while one waits replaces it (its
        /// cancel is called).
        void CaptureNextKey(core::Function<void(const Keystroke&)> onKey, core::Function<void()> onCancel = {}, bool takeEscape = false)
        {
            CancelKeyCapture();
            m_capture.OnKey = core::Move(onKey);
            m_capture.OnCancel = core::Move(onCancel);
            m_capture.TakeEscape = takeEscape;
            m_capture.Waiting = true;
            m_capture.PendingModifier = 0;
        }
        /// Stops a capture waiting, calling its cancel.
        void CancelKeyCapture()
        {
            if (!m_capture.Waiting)
                return;
            m_capture.Waiting = false;
            core::Function<void()> cancel = core::Move(m_capture.OnCancel);
            m_capture.OnKey = {};
            if (cancel)
                cancel();
        }
        [[nodiscard]] bool IsCapturingKey() const noexcept { return m_capture.Waiting; }

        // === Access keys (E12) ===
        /// Whether access keys are underlined now: while Alt is held, or always.
        [[nodiscard]] bool AreMnemonicsShown() const noexcept { return m_mnemonicsAlways || m_altHeld; }
        /// Underlines access keys always, not only while Alt is held (a platform that does).
        void SetMnemonicsAlwaysShown(bool always)
        {
            if (always == m_mnemonicsAlways)
                return;
            const bool was = AreMnemonicsShown();
            m_mnemonicsAlways = always;
            if (was != AreMnemonicsShown())
                RedrawMnemonics();
        }

        bool InjectKeyDown(u32 keyCode, u32 modifiers = 0) { return KeyDownFrom(InputKind::Keyboard, keyCode, modifiers); }
        // A key down, from the keyboard or standing in for a pad's button (its East as Escape).
        bool KeyDownFrom(InputKind from, u32 keyCode, u32 modifiers)
        {
            NoteInput();
            DropHiddenFocus();
            ApplyInputKind(from);
            m_capture.DropText = false;
            if (keyCode == static_cast<u32>(KeyCode::LeftAlt) || keyCode == static_cast<u32>(KeyCode::RightAlt))
                SetAltHeld(true);
            if (m_capture.Waiting)
            {
                const KeyCode key = static_cast<KeyCode>(keyCode);
                if (key == KeyCode::Escape && modifiers == 0 && !m_capture.TakeEscape)
                {
                    CancelKeyCapture();
                    return true;
                }
                if (ModifierOfKey(key) != 0)
                {
                    m_capture.PendingModifier = keyCode; // alone if it is released before another key
                    return true;
                }
                m_capture.DropText = true; // what it types is not text now
                TakeCapturedKey(Keystroke{keyCode, modifiers, false});
                return true;
            }
            // A keyboard drag: Escape (a pad's East) cancels, Return or Space drops at the focus,
            // the rest move the focus as ever, and the focus is asked again.
            if (m_dragActive && m_dragFromKeyboard)
            {
                if (keyCode == static_cast<u32>(KeyCode::Escape))
                {
                    CancelDrag();
                    return true;
                }
                if ((keyCode == static_cast<u32>(KeyCode::Return) || keyCode == static_cast<u32>(KeyCode::Space)) && modifiers == 0)
                {
                    QueryAtFocus();
                    Drop();
                    return true;
                }
            }
            // A pointer drag takes the keys: Escape (a pad's East) cancels it, a modifier asks again.
            if (m_dragActive && !m_dragFromKeyboard)
            {
                if (keyCode == static_cast<u32>(KeyCode::Escape))
                    CancelDrag();
                else if (modifiers != m_dragModifiers)
                {
                    m_dragModifiers = modifiers;
                    QueryDrop(m_mousePos);
                }
                return true;
            }
            // A key hides a tooltip, and keeps it hidden until the pointer moves on (as a press does).
            if (m_tipProvider != nullptr)
                m_tipSuppressed = true;
            ClosePopupsOfKind(PopupKind::Hint, PopupCloseReason::Code);
            // The focused widget, and its ancestors (capture, then bubble from the focus), first.
            if (RouteKey(EventType::KeyDown, keyCode, modifiers))
            {
                if (m_dragActive && m_dragFromKeyboard)
                    QueryAtFocus(); // the focus's own key (a list's arrows) moved where it would drop
                return true;
            }
            // Tab and Shift+Tab traverse focus when nothing took them; from a widget that captures
            // Tab (E12) they are its keys, and Ctrl+Tab and Ctrl+Shift+Tab traverse instead.
            if (keyCode == static_cast<u32>(KeyCode::Tab))
            {
                const bool captured = m_focusNode != nullptr && m_focusNode->GetTabCaptures();
                const u32 traverse = captured ? static_cast<u32>(KeyModCtrl) : 0u;
                if ((modifiers & ~static_cast<u32>(KeyModShift)) == traverse)
                    return (modifiers & KeyModShift) != 0 ? FocusPrevious() : FocusNext();
                if (captured && (modifiers & ~static_cast<u32>(KeyModShift)) == 0)
                    return true; // the widget's own key, though it did nothing with it
            }
            // Then the bindings (a keystroke bound to a command where the focus path's contexts allow).
            const u32 strokeModifiers = modifiers & ~ModifierOfKey(static_cast<KeyCode>(keyCode)); // Left Shift alone is "leftshift"
            if (m_keystrokes && m_keystrokes(Keystroke{keyCode, strokeModifiers, false}))
                return true;
            // Alt and an access key no binding took (E12): the widget it marks, in the open menu or
            // the focus scope, takes focus and acts.
            if (modifiers == KeyModAlt && ActivateMnemonic(MnemonicOfKey(static_cast<KeyCode>(keyCode))))
                return true;
            if (modifiers != 0)
                return false;
            // What is left is navigation's: an arrow moves focus, Return or Space activates (G7).
            switch (static_cast<KeyCode>(keyCode))
            {
            case KeyCode::Up: return MoveFocus(NavDirection::Up);
            case KeyCode::Down: return MoveFocus(NavDirection::Down);
            case KeyCode::Left: return MoveFocus(NavDirection::Left);
            case KeyCode::Right: return MoveFocus(NavDirection::Right);
            case KeyCode::Return:
            case KeyCode::Space: return Activate();
            default: return false;
            }
        }

        /// What Tab steps through now, in order: the tab-focusable widgets shown and enabled, inside
        /// a modal while one is open, or inside the dialog focus is in (the debug overlay numbers them).
        [[nodiscard]] core::Array<Node*> TabStops() const
        {
            core::Array<Node*> stops;
            Node* within = FocusScopeRoot();
            if (Node* contain = ContainingScopeOf(m_focusNode); contain != nullptr && IsInSubtree(contain, within))
                within = contain;
            CollectTabStops(within, stops);
            // A focus group (E12) is one stop, where its first member stood: the member focused
            // now, else its entry (remembered, default, current, first).
            for (usize i = 0; i < stops.Size(); ++i)
            {
                Node* group = OutermostFocusGroup(stops[i], within);
                if (group == nullptr)
                    continue;
                Node* stop = m_focusNode != nullptr && IsInSubtree(m_focusNode, group) && m_focusNode->IsTabFocusable()
                                 ? m_focusNode
                                 : EntryInto(*group, stops[i]);
                stops[i] = stop;
                for (usize j = stops.Size(); j-- > i + 1;)
                    if (OutermostFocusGroup(stops[j], within) == group)
                        stops.RemoveAt(j);
            }
            // tab-index (E12): a negative one is skipped; positive ones first, lowest first, a tie
            // and the zeros in tree order (insertion sort keeps it: the stops are few).
            usize kept = 0;
            for (usize i = 0; i < stops.Size(); ++i)
                if (stops[i]->GetTabIndex() >= 0)
                    stops[kept++] = stops[i];
            stops.Resize(kept);
            const auto before = [](const Node* a, const Node* b)
            {
                const i32 x = a->GetTabIndex(), y = b->GetTabIndex();
                return x > 0 && (y == 0 || x < y);
            };
            for (usize i = 1; i < stops.Size(); ++i)
                for (usize j = i; j > 0 && before(stops[j], stops[j - 1]); --j)
                    Swap(stops[j], stops[j - 1]);
            return stops;
        }

        /// Moves focus to the best widget in `direction` (inside a modal while one is open, within
        /// focus scopes); with nothing focused, to the GUI's entry. True when focus moved. The
        /// gamepad's d-pad and stick arrive here as the arrows do.
        bool MoveFocus(NavDirection direction)
        {
            UseKeyboard();
            Node* root = FocusScopeRoot();
            if (root == nullptr)
                return false;
            (void)HitTest(core::Float2{}); // the layout as it is now (a pending pass runs first)
            Node* target = NavigateFrom(*root, m_focusNode, direction, &m_lastNavigation);
            if (target == nullptr || target == m_focusNode)
                return false;
            SetFocusNode(target);
            return true;
        }
        /// A gamepad button (the d-pad goes to PressDirection): the bindings first (East is `back`'s
        /// by default); left to it, South activates and East is Escape, for a widget's own Escape
        /// (an edit cancelled).
        void InjectPadButton(PadButton button)
        {
            NoteInput();
            DropHiddenFocus();
            ApplyInputKind(InputKind::Pad);
            UseKeyboard();
            if (m_capture.Waiting)
            {
                TakeCapturedKey(Keystroke{static_cast<u32>(button), 0, true});
                return;
            }
            if (m_keystrokes && m_keystrokes(Keystroke{static_cast<u32>(button), 0, true}))
                return;
            if (button == PadButton::South)
                (void)Activate();
            else if (button == PadButton::East)
                (void)KeyDownFrom(InputKind::Pad, static_cast<u32>(KeyCode::Escape), 0); // not taken as `back`: a widget's own Escape
        }
        /// Told on input a user gave this root (a press, a key, the gamepad): its GUI makes it the
        /// active root.
        void SetOnInput(core::Function<void()> onInput) { m_onInput = core::Move(onInput); }
        /// Where unhandled keystrokes go: the SceneRoot's keymap (true when it took one).
        void SetKeystrokeRouter(core::Function<bool(const Keystroke&)> router) { m_keystrokes = core::Move(router); }

        /// Activates the focused widget (Return, Space, a gamepad's South): what a click does.
        /// The press in progress already activated what it pressed (a button acting on the press,
        /// a repeating one): its release makes no click.
        void SuppressClick() noexcept { m_clickSuppressed = true; }
        bool Activate()
        {
            if (m_dragActive && m_dragFromKeyboard)
            {
                // The pad's South while dragging from the keys: dropped at the focus.
                QueryAtFocus();
                Drop();
                return true;
            }
            return m_focusNode != nullptr && m_focusNode->IsTreeEnabled() && m_focusNode->HandleActivate();
        }
        bool InjectKeyUp(u32 keyCode, u32 modifiers = 0)
        {
            if (keyCode == static_cast<u32>(KeyCode::LeftAlt) || keyCode == static_cast<u32>(KeyCode::RightAlt))
                SetAltHeld(false);
            if (m_capture.Waiting)
            {
                // A modifier released with nothing pressed after it: the modifier key itself.
                if (m_capture.PendingModifier == keyCode)
                    TakeCapturedKey(Keystroke{keyCode, modifiers & ~ModifierOfKey(static_cast<KeyCode>(keyCode)), false});
                return true;
            }
            if (m_dragActive && !m_dragFromKeyboard)
            {
                if (modifiers != m_dragModifiers)
                {
                    m_dragModifiers = modifiers;
                    QueryDrop(m_mousePos);
                }
                return true;
            }
            return RouteKey(EventType::KeyUp, keyCode, modifiers);
        }
        bool InjectText(core::StringView text)
        {
            if (m_capture.Waiting || m_capture.DropText)
            {
                m_capture.DropText = false; // a captured key's text
                return true;
            }
            Node* target = KeyTarget();
            if (target == nullptr)
                return false;
            TextInputEvent event(target, text);
            return target->RouteEvent(event);
        }
        /// An IME's composition so far (empty: it ended), to the focused node, which shows it in
        /// place; the committed text follows as InjectText. `cursor` is in characters.
        bool InjectComposition(core::StringView text, i32 cursor = 0)
        {
            Node* target = KeyTarget();
            if (target == nullptr)
                return false;
            CompositionEvent event(target, text, cursor);
            return target->RouteEvent(event);
        }
        /// Where the focused node has text typed, in input space (as positions are injected), and
        /// the caret's x there: where a host's IME shows its candidates. False when it types none.
        [[nodiscard]] bool GetTextInputArea(Rect& area, f32& caretX) const
        {
            if (m_focusNode == nullptr || !m_focusNode->WantsTextInput())
                return false;
            Rect local{};
            f32 localCaret = 0.0f;
            if (!m_focusNode->GetTextInputArea(local, localCaret))
                return false;
            const core::Float2 a = m_focusNode->ConvertToWorldSpace(core::Float2{local.x, local.y});
            const core::Float2 b = m_focusNode->ConvertToWorldSpace(core::Float2{local.x + local.width, local.y + local.height});
            const core::Float2 c = m_focusNode->ConvertToWorldSpace(core::Float2{localCaret, local.y});
            area = Rect{core::Min(a.x, b.x), core::Min(a.y, b.y), core::Abs(b.x - a.x), core::Abs(b.y - a.y)};
            caretX = c.x - area.x;
            return true;
        }

        // === Pointer capture ===
        /// Sends the pointer's moves and its release to `node` wherever the pointer goes, until
        /// released or the press ends (a press captures the pressed node on its own). A node that
        /// loses the capture (released, taken by another, or leaving the tree) is told
        /// (PointerCaptureLost).
        void CapturePointer(Node& node)
        {
            if (m_captureNode == &node)
                return;
            Node* previous = m_captureNode;
            m_captureNode = &node;
            if (previous != nullptr)
                SendCaptureLost(*previous);
        }
        void ReleasePointer(Node& node)
        {
            if (m_captureNode != &node)
                return;
            m_captureNode = nullptr;
            SendCaptureLost(node);
        }
        [[nodiscard]] Node* GetPointerCapture() const noexcept { return m_captureNode; }
        /// Seconds of its clock (Tick advances it): what click counting and type-ahead read.
        [[nodiscard]] f32 GetTime() const noexcept { return m_time; }

        /// The pointer's look now: the nearest set `cursor` up from the node under the pointer
        /// (from the captured node while one holds the pointer, so a drag keeps its look), else
        /// Default. The host shows it (the shell bridge does).
        [[nodiscard]] Cursor GetCursor() const
        {
            if (m_dragActive) // a drag shows what a drop would do
                return m_dropEffect == DropEffect::Copy ? Cursor::Copy : m_dropEffect == DropEffect::Link ? Cursor::Alias
                       : m_dropEffect == DropEffect::Move ? Cursor::Move : Cursor::NoDrop;
            if (m_inputKind == InputKind::Pad)
                return Cursor::None; // a pad in use: the pointer is not (K2b)
            Node* from = m_captureNode != nullptr ? m_captureNode : m_downNode != nullptr ? m_downNode : m_overNode;
            for (Node* n = from; n != nullptr; n = n->GetParent())
                if (const Cursor cursor = n->GetCursorNow(); cursor != Cursor::Auto)
                    return cursor;
            return Cursor::Default;
        }

        /// Whether a pointer at `position` (device pixels) is over the GUI: over a node that takes
        /// the pointer (Node::TakesPointer), not only over a layout container. A game host asks
        /// before treating a click as its own.
        [[nodiscard]] bool IsPointerOver(core::Float2 position) const { return IsPointerTaken(HitTest(position)); }

        // === Focus ===
        /// A focused node no longer shown (it or a node above it hidden, or out of the layout) gives
        /// the focus up, as a removed one does: the keys go to its scope then, never to what cannot
        /// be seen (a screen's button left focused as the screen hides is not pressed by Return).
        /// Run each tick and before a key or a pad button.
        void DropHiddenFocus()
        {
            if (m_focusNode != nullptr && !m_focusNode->IsTreeVisible())
                SetFocusNode(nullptr);
        }
        void SetFocusNode(Node* node)
        {
            if (node == m_focusNode || (node != nullptr && node->IsTreeInert())) // what leaves or is inert takes no focus (K0, K4)
                return;
            Node* previous = m_focusNode;
            m_focusNode = node;
            m_focusChanged.Notify(); // the focus path: which commands are available
            if (previous)
                previous->HandleFocusLost();
            if (m_focusNode)
            {
                RememberInScopes(*m_focusNode); // coming back to a scope returns here
                m_focusNode->SetFocusVisible(m_inputKind != InputKind::Pointer);
                m_focusNode->HandleFocusGained();
                // Scrollers around it bring it into view: those inside the popup it is in, not the
                // ones its owner sits in (a popup is placed in the root's space, not scrolled with
                // them: a page scrolled to a menu opened in it, a little further each time it opened).
                for (Node* n = m_focusNode; n != nullptr && !n->IsInTopLayer(); n = n->GetParent())
                    if (Node* p = n->GetParent())
                        p->OnDescendantFocused(*m_focusNode);
            }
            if (m_dragActive && m_dragFromKeyboard)
                QueryAtFocus(); // a keyboard drag asks where the focus went
        }

        // === Drag and drop (E7) ===
        // A left press (a finger's after a long press) that moves past the threshold offers a drag
        // up from the pressed node (DragRequest); the first source that fills it starts it, a node
        // owning its press ends the walk. While it goes, each move, modifier change and scroll asks
        // the node under the pointer and up its ancestors what a drop would do (DropQuery): the
        // first that takes it is the target, the cursor and the preview show the effect, and a
        // reason shows by the pointer. A release over the target drops; Escape, a right press, the
        // pad's East or the source leaving the tree cancels; the source is told how it ended.

        /// How far a press moves before it drags, in DIPs (scaled by the display; Godot's is 10, Zero's 6).
        void SetDragThreshold(f32 distance) noexcept { m_dragThreshold = core::Max(0.0f, distance); }
        [[nodiscard]] f32 GetDragThreshold() const noexcept { return m_dragThreshold; }
        /// Starts a drag from code (Godot's force_drag): `source` gives no request itself.
        void StartDrag(Node& source, DragRequest request) { BeginDrag(source, core::Move(request), m_mousePos); }
        [[nodiscard]] bool IsDragging() const noexcept { return m_dragActive; }
        /// Where the GUI's roots are on the screen (its GUIContext's, set by the host); null: this
        /// root alone, a drag past its edge outside.
        void SetRootPlaces(IRootPlaces* places) noexcept { m_rootPlaces = places; }
        /// The dispatcher whose root a drag from here is over now (its own, or another root's of the
        /// GUI); null while it is over none (outside every root) or no drag goes.
        [[nodiscard]] EventDispatcher* GetDragOver() const noexcept { return m_dragActive && !m_dragOutside ? m_dragOver : nullptr; }
        /// Another root of the GUI goes: a drag from here over it is over none until it moves, and
        /// forgets the target and the layer it had there.
        void ForgetRoot(const EventDispatcher& gone) noexcept
        {
            if (&gone == this)
                return;
            if (m_dragOver == &gone)
            {
                m_dragOver = this;
                m_dragOutside = true;
                if (m_dropTarget != nullptr && m_dropTarget->GetRootNode() == gone.m_root)
                    m_dropTarget = nullptr; // its tree goes with it: nothing to tell
            }
            if (m_dragLayerIn == &gone)
                m_dragLayerIn = nullptr;
        }
        [[nodiscard]] const DragPayload& GetDragPayload() const noexcept { return m_dragPayload; }
        [[nodiscard]] Node* GetDragSource() const noexcept { return m_dragSource; }
        [[nodiscard]] Node* GetDropTarget() const noexcept { return m_dropTarget; }
        /// The effect a drop would have now, and the target's reason (or a refusal's).
        [[nodiscard]] DropEffect GetDropEffect() const noexcept { return m_dropEffect; }
        [[nodiscard]] core::StringView GetDropReason() const noexcept { return m_dropReason.AsView(); }
        /// The preview following the pointer, and the hint beside it (null while none shows).
        [[nodiscard]] Node* GetDragPreview() const noexcept { return m_dragPreview.Get(); }
        [[nodiscard]] Node* GetDropHint() const noexcept { return m_dropHint.Get(); }
        void CancelDrag()
        {
            if (m_dragActive)
                FinishDrag(DropEffect::None, nullptr, true);
        }
        /// How deep the band at a scroller's edge is that scrolls it while a drag is near it, and
        /// how fast it scrolls at its edge (it ramps up with depth).
        void SetDragScrollBand(f32 band, f32 speed = 900.0f) noexcept
        {
            m_dragScrollBand = core::Max(1.0f, band);
            m_dragScrollSpeed = core::Max(0.0f, speed);
        }
        /// How long a drag rests on a node before it opens (a tree node, an expander, a tab).
        void SetDragHoverOpenDelay(f32 seconds) noexcept { m_dragHoverOpenDelay = core::Max(0.0f, seconds); }
        /// Files the OS dropped at `position` (E7, the same path as a drag): a `files` payload
        /// (its value the paths, copied) asked of the node there and up, and dropped on the one
        /// that takes it; none taking it, the GUI's own handler has them. True when something
        /// took them. (The OS gives no hover: nothing shows while a file is dragged over.)
        bool InjectFileDrop(core::Float2 position, const core::Array<core::String>& paths)
        {
            if (paths.IsEmpty())
                return false;
            if (m_dragActive)
                CancelDrag();
            NoteInput();
            core::Array<core::Variant> list;
            for (const core::String& path : paths)
                list.PushBack(core::Variant::From<core::String>(path));
            m_dragPayload = DragPayload{};
            m_dragPayload.Type = core::String(u8"files");
            m_dragPayload.Value = core::Variant::From<core::Array<core::Variant>>(core::Move(list));
            m_dragPayload.Label = paths.Size() == 1 ? paths[0] : core::Format(u8"{} files", paths.Size());
            m_dragPayload.Allowed = DropEffectsCopy;
            m_dragActive = true;
            m_dragSource = nullptr;
            m_dragModifiers = 0;
            QueryDrop(position);
            const bool taken = m_dropTarget != nullptr && m_dropEffect != DropEffect::None;
            Drop();
            if (!taken && m_onFileDrop)
                return m_onFileDrop(paths, RootPoint(position));
            return taken;
        }
        /// What has the files no node takes (the GUI's own handler: an import, an open).
        void SetOnFileDrop(core::Function<bool(const core::Array<core::String>&, core::Float2)> handler)
        {
            m_onFileDrop = core::Move(handler);
        }

        /// `drag.pick` (E7, Godot's accessibility drag): the focused node, or one above it, starts
        /// a drag of what it would drag; the focus then moves as ever (the arrows, Tab, the pad),
        /// each node it reaches asked as the pointer would ask it, and `drag.drop` (Return, Space,
        /// the pad's South) drops at the focus; Escape (East) cancels.
        bool PickDrag()
        {
            if (m_dragActive)
                CancelDrag();
            for (Node* n = m_focusNode; n != nullptr; n = n->GetParent())
            {
                if (!n->IsTreeEnabled())
                    return false;
                DragRequest request;
                request.Press = core::Float2{n->GetSize().x * 0.5f, n->GetSize().y * 0.5f};
                request.FromKeyboard = true;
                if (n->HandleDragRequested(request))
                {
                    request.FromKeyboard = true;
                    UseKeyboard();
                    m_dragModifiers = 0;
                    BeginDrag(*n, core::Move(request), FocusPoint());
                    return true;
                }
            }
            return false;
        }
        /// A drag from the keys or the pad is going (the focus is what is asked).
        [[nodiscard]] bool IsKeyboardDrag() const noexcept { return m_dragActive && m_dragFromKeyboard; }
        /// Asks the target again where the pointer is (the content moved under a still pointer).
        void RequeryDrag()
        {
            if (m_dragFromKeyboard)
                QueryAtFocus();
            else if (m_dragActive)
                QueryDrop(m_mousePos);
        }

        // === Popups: the top layer (E5) ===
        // A popup stays in its owner's subtree (its styles, its events' route) and is promoted into
        // this root's top layer while open: drawn after the whole tree in opening order, unclipped,
        // hit-tested first, placed against its anchor every layout pass. Opening an auto popup
        // closes the open ones that do not hold its owner (nesting comes from the tree); closing one
        // closes those it holds. A closed popup leaves the tree (its owner keeps it).

        /// Opens `popup` as a child of `owner` (attached there if it is not yet).
        void OpenPopup(Node& owner, Node& popup, PopupOptions options)
        {
            if (FindPopup(popup) >= 0)
                return;
            if (options.Kind != PopupKind::Manual)
            {
                // An auto popup closes the popups that do not hold its owner (a hint, the other hints).
                for (usize i = m_popups.Size(); i-- > 0;)
                {
                    const PopupEntry& e = m_popups[i];
                    if (e.Options.Modal || e.Options.Kind == PopupKind::Manual)
                        break; // what is below a dialog stays as it is
                    const bool closes = options.Kind == PopupKind::Hint ? e.Options.Kind == PopupKind::Hint
                                                                        : !IsInSubtree(&owner, e.Popup.Get());
                    if (closes && i < m_popups.Size())
                        ClosePopupAt(i, PopupCloseReason::Replaced);
                }
            }
            PopupEntry entry;
            if (options.ReturnHome && popup.GetParent() != nullptr)
            {
                entry.Home = popup.GetParent()->TakeElementRef();
                entry.HomeIndex = popup.GetParent()->GetChildIndex(&popup);
            }
            if (popup.GetParent() != &owner)
            {
                // Held across the move: its old parent may hold the only reference (a dialog
                // written in a page).
                const core::RefPtr<Node> keep(&popup);
                popup.RemoveFromParent();
                owner.AddChild(&popup);
            }
            entry.Popup = core::RefPtr<Node>(&popup);
            entry.Size = popup.GetSize();
            const bool focusing = (options.TakesFocus || options.Modal) && options.Kind != PopupKind::Hint;
            if (focusing)
            {
                // The focus it takes, and the nodes holding it: given back on close to the first
                // that is still there.
                for (Node* n = m_focusNode; n != nullptr; n = n->GetParent())
                    entry.SavedFocus.PushBack(n->TakeElementRef());
                entry.ScopeBefore = popup.GetNavScope();
                if (popup.GetNavScope() == NavScope::None)
                    popup.SetNavScope(NavScope::Contain);
            }
            entry.Options = core::Move(options);
            popup.SetInTopLayer(true);
            popup.SetRouteStop(entry.Options.Modal);
            m_popups.PushBack(core::Move(entry));
            PlacePopups();
            if (focusing)
            {
                core::Array<Node*> stops;
                CollectTabStops(&popup, stops);
                SetFocusNode(!stops.IsEmpty() ? stops[0] : (popup.IsTabFocusable() ? &popup : nullptr));
            }
            // Told after focus moved in, so a listener may move it on (a dialog's default button).
            ToggleEvent opened(&popup, true, PopupCloseReason::Code);
            (void)popup.RouteEvent(opened);
        }
        /// Closes `popup` and the popups it holds. False when it is not open.
        bool ClosePopup(Node& popup, PopupCloseReason reason = PopupCloseReason::Code)
        {
            const i32 index = FindPopup(popup);
            if (index < 0)
                return false;
            ClosePopupAt(static_cast<usize>(index), reason);
            return true;
        }
        void CloseAllPopups(PopupCloseReason reason = PopupCloseReason::Code)
        {
            while (!m_popups.IsEmpty())
                ClosePopupAt(0, reason);
        }
        /// Input went to another root of the GUI (another window): its auto popups and hints close,
        /// as a press outside them would close them (what is below a dialog stays).
        void CloseLightPopups(PopupCloseReason reason = PopupCloseReason::OutsidePress)
        {
            for (usize i = m_popups.Size(); i-- > 0;)
            {
                if (i >= m_popups.Size())
                    continue;
                if (m_popups[i].Options.Kind == PopupKind::Manual)
                    break;
                ClosePopupAt(i, reason);
            }
        }
        [[nodiscard]] bool IsPopupOpen(const Node& popup) const { return FindPopup(popup) >= 0; }
        /// Closes the topmost auto popup, not past a dialog (a manual popup answers for itself);
        /// false when none is open there. The `back` command's first answer (K1).
        bool CloseTopAutoPopup(PopupCloseReason reason)
        {
            const i32 top = TopAutoPopup();
            if (top < 0)
                return false;
            ClosePopupAt(static_cast<usize>(top), reason);
            return true;
        }
        [[nodiscard]] bool HasTopAutoPopup() const { return TopAutoPopup() >= 0; }
        [[nodiscard]] usize PopupCount() const noexcept { return m_popups.Size(); }
        /// The open popups, bottom first.
        [[nodiscard]] Node* PopupAt(usize index) const { return index < m_popups.Size() ? m_popups[index].Popup.Get() : nullptr; }
        [[nodiscard]] const PopupOptions* PopupOptionsAt(usize index) const
        {
            return index < m_popups.Size() ? &m_popups[index].Options : nullptr;
        }
        [[nodiscard]] Node* TopPopup() const { return m_popups.IsEmpty() ? nullptr : m_popups.Back().Popup.Get(); }

        /// Places every anchored popup against its anchor within the root: on its side, flipped,
        /// shrunk and clamped (PlacePopup). Run every layout pass and before drawing, so a popup
        /// follows its anchor.
        void PlacePopups() const
        {
            if (m_root == nullptr)
                return;
            const Rect bounds{0.0f, 0.0f, m_root->GetSize().x, m_root->GetSize().y};
            for (const PopupEntry& e : m_popups)
            {
                Rect anchor{};
                if (e.Options.Anchor != nullptr)
                {
                    const Node& a = *e.Options.Anchor;
                    const core::Float2 p0 = a.ConvertToRootSpace(core::Float2{0.0f, 0.0f});
                    const core::Float2 p1 = a.ConvertToRootSpace(a.GetSize());
                    anchor = Rect{core::Min(p0.x, p1.x), core::Min(p0.y, p1.y), core::Abs(p1.x - p0.x), core::Abs(p1.y - p0.y)};
                }
                else if (e.Options.HasAnchorRect)
                    anchor = e.Options.AnchorRect;
                else
                    continue;
                Node& popup = *e.Popup;
                if (e.Options.FitContent)
                    e.Size = popup.Measure(LayoutConstraints{});
                // Its sides and alignment in the anchor's direction, else its own (its owner's).
                const bool rightToLeft = e.Options.Anchor != nullptr ? e.Options.Anchor->IsRightToLeft()
                                                                     : popup.IsRightToLeft();
                PlacedPopup placed = PlacePopup(anchor, e.Size, bounds, e.Options.Placement, rightToLeft);
                // On the device grid, as its arrange puts it, so the two agree.
                const f32 scale = core::Max(popup.GetPixelScale(), 0.01f);
                const auto snap = [scale](f32 v) { return core::Round(v * scale) / scale; };
                placed.Size = core::Float2{snap(placed.Position.x + placed.Size.x) - snap(placed.Position.x),
                                           snap(placed.Position.y + placed.Size.y) - snap(placed.Position.y)};
                placed.Position = core::Float2{snap(placed.Position.x), snap(placed.Position.y)};
                if (e.Options.FitContent)
                {
                    // Sized by what it holds: arranged, its style left auto, so the next measure
                    // follows its content (a tooltip whose font arrives after it opened).
                    popup.Arrange(Rect{placed.Position.x, placed.Position.y, placed.Size.x, placed.Size.y});
                    continue;
                }
                Node::StyleWriteScope writing(popup); // the layer's, not code's: no pins
                if (placed.Position.x != popup.GetPosition().x || placed.Position.y != popup.GetPosition().y)
                    popup.SetPosition(placed.Position);
                if (placed.Size.x != popup.GetSize().x || placed.Size.y != popup.GetSize().y)
                    popup.SetSize(placed.Size);
            }
        }
        /// A popup's size changed from code while it is open (a list grew): placed from it again.
        void SetPopupSize(Node& popup, core::Float2 size)
        {
            const i32 index = FindPopup(popup);
            if (index < 0)
            {
                popup.SetSize(size);
                return;
            }
            m_popups[static_cast<usize>(index)].Size = size;
            popup.SetSize(size);
            PlacePopups();
        }
        /// The rectangle (root space) an open popup is placed against moved (a code editor's caret,
        /// scrolled or typed on): placed against it from now on. False when it is not open.
        bool SetPopupAnchorRect(const Node& popup, Rect anchor)
        {
            const i32 index = FindPopup(popup);
            if (index < 0)
                return false;
            PopupOptions& options = m_popups[static_cast<usize>(index)].Options;
            options.Anchor = nullptr;
            options.AnchorRect = anchor;
            options.HasAnchorRect = true;
            PlacePopups();
            return true;
        }

        /// Draws the top layer (the root's draw does, after its tree): each popup in opening order,
        /// a modal one over its backdrop (its `::backdrop` part, over a dim of the whole root).
        void DrawPopups(DrawContext& ctx)
        {
            PlacePopups();
            for (usize i = 0; i < m_popups.Size(); ++i)
            {
                const core::RefPtr<Node> popup = m_popups[i].Popup; // held: drawing changes nothing, but be sure
                if (m_popups[i].Options.Modal && m_root != nullptr)
                {
                    const Rect all{0.0f, 0.0f, m_root->GetSize().x, m_root->GetSize().y};
                    popup->DrawBackdrop(ctx, all);
                }
                popup->Draw(ctx);
            }
        }
        /// Whether `node` takes input now: everything while no modal popup is open, else what is
        /// in the topmost modal one or above it.
        [[nodiscard]] bool IsInputLive(const Node* node) const { return IsLive(node); }
        /// Where focus, Tab and the arrows stay: the topmost popup taking focus, else the root.
        [[nodiscard]] Node* GetFocusScopeRoot() const { return FocusScopeRoot(); }

        /// The topmost popup under a world point, and in it the node there (hints pass the pointer
        /// through); null when the point is in none.
        [[nodiscard]] Node* FindInPopups(core::Float2 worldPoint) const
        {
            for (usize i = m_popups.Size(); i-- > 0;)
                if (m_popups[i].Options.Kind != PopupKind::Hint && !m_popups[i].Options.PassesPointer)
                    if (Node* hit = m_popups[i].Popup->OverFind(worldPoint))
                        return hit;
            return nullptr;
        }

        // === Tab navigation ===
        // Move focus to the next / previous tab-focusable node in tree pre-order (visible +
        // enabled), wrapping around. Returns true if focus moved. With nothing focused, Next
        // targets the first stop and Previous the last.
        bool FocusNext()
        {
            UseKeyboard();
            return MoveTabFocus(+1);
        }
        bool FocusPrevious()
        {
            UseKeyboard();
            return MoveTabFocus(-1);
        }

        // === A held direction (G7) ===
        // A gamepad's d-pad or stick held in a direction: a step at once, then, after a delay,
        // again and again, faster the longer it is held. Each step reaches the focused widget as an
        // arrow key does, so a slider moves its value and a list its selection, and only what it
        // leaves moves focus. (A keyboard's held arrow repeats by the
        // system's own key repeat.) The GUI's update (GUIContext::Update) ticks it.
        void PressDirection(NavDirection direction)
        {
            NoteInput();
            ApplyInputKind(InputKind::Pad);
            m_holding = true;
            m_heldDirection = direction;
            m_heldFor = 0.0f;
            m_nextRepeatAt = kRepeatDelay;
            StepDirection(direction);
        }
        void ReleaseDirection(NavDirection direction)
        {
            if (m_holding && m_heldDirection == direction)
                m_holding = false;
        }
        [[nodiscard]] bool IsHoldingDirection() const noexcept { return m_holding; }
        /// A pad's right stick, each axis -1 to 1 (down and right positive): while it is pushed
        /// past its dead zone, Tick scrolls the nearest scroller around the focus (or, with no
        /// focus, under the pointer), faster the further it is pushed.
        void SetScrollStick(core::Float2 value) noexcept { m_scrollStick = value; }
        [[nodiscard]] core::Float2 GetScrollStick() const noexcept { return m_scrollStick; }
        void Tick(f32 seconds)
        {
            m_time += seconds; // the clock click counting, tooltips and long presses read
            DropHiddenFocus();
            if (m_dragActive)
                TickDrag(seconds);
            UpdateTooltip(seconds);
            ScrollByStick(seconds);
            if (m_longPressArmed && m_touchActive)
            {
                m_pressHeld += seconds;
                if (m_pressHeld >= kLongPress)
                    LongPress();
            }
            if (!m_holding)
                return;
            m_heldFor += seconds;
            for (i32 guard = 0; guard < 8 && m_heldFor >= m_nextRepeatAt; ++guard)
            {
                StepDirection(m_heldDirection);
                // From the first interval down to the fastest, over the time held past the delay.
                const f32 ramp = core::Min(1.0f, (m_heldFor - kRepeatDelay) / kRepeatRampTime);
                m_nextRepeatAt += kRepeatSlowest + (kRepeatFastest - kRepeatSlowest) * ramp;
            }
        }
        static constexpr f32 kRepeatDelay = 0.4f;    // before the first repeat
        static constexpr f32 kRepeatSlowest = 0.16f; // the first repeats' interval
        static constexpr f32 kRepeatFastest = 0.05f; // once held long
        static constexpr f32 kRepeatRampTime = 1.2f; // from slowest to fastest

        // One step of a held direction, as an arrow key takes it: the focused widget first (a
        // slider steps its value, a list its selection), navigation with what it leaves.
        void StepDirection(NavDirection direction)
        {
            UseKeyboard();
            const KeyCode key = direction == NavDirection::Up     ? KeyCode::Up
                                : direction == NavDirection::Down ? KeyCode::Down
                                : direction == NavDirection::Left ? KeyCode::Left
                                                                  : KeyCode::Right;
            if (!RouteKey(EventType::KeyDown, static_cast<u32>(key), 0))
                (void)MoveFocus(direction);
        }


        // A subtree is leaving the tree (Node::RemoveChild tells the dispatcher before it
        // detaches): every ref into it is dropped, since the tree no longer keeps those nodes
        // alive. A sort that rebuilds a table's header frees the hovered header cell, and the next
        // mouse move would otherwise leave a freed node. A popup inside it is simply gone; a popup
        // whose opener leaves is dismissed while the opener still lives.
        void NotifySubtreeRemoved(Node& removed)
        {
            // Popups leaving with the subtree (their owner went): dropped, topmost first, focus
            // given back to what they took it from when that stays.
            for (usize i = m_popups.Size(); i-- > 0;)
                if (i < m_popups.Size() && IsInSubtree(m_popups[i].Popup.Get(), &removed))
                    DropPopupAt(i, PopupCloseReason::OwnerRemoved, &removed);
            if (IsInSubtree(m_tipProvider, &removed))
                m_tipProvider = nullptr;
            PrunePath(m_hoverPath, removed, /*hover*/ true);
            m_overNode = m_hoverPath.IsEmpty() ? nullptr : m_hoverPath[m_hoverPath.Size() - 1];
            PrunePath(m_pressPath, removed, /*hover*/ false);
            if (IsInSubtree(m_downNode, &removed))
                m_downNode = nullptr;
            if (IsInSubtree(m_panScroller, &removed))
                m_panScroller = nullptr; // the finger pans nothing now
            if (IsInSubtree(m_captureNode, &removed))
            {
                Node* lost = m_captureNode;
                m_captureNode = nullptr;
                SendCaptureLost(*lost); // told while it still lives
            }
            if (IsInSubtree(m_focusNode, &removed))
                SetFocusNode(nullptr);
            if (IsInSubtree(m_dropTarget, &removed))
                m_dropTarget = nullptr;
            if (IsInSubtree(m_dragSource, &removed))
            {
                m_dragSource = nullptr; // gone: it is told nothing
                CancelDrag();
            }
        }

    private:
        [[nodiscard]] Node* HitTest(core::Float2 position) const
        {
            // Input sees the layout as it is now: a layout still waiting for the frame's pass runs
            // first (nothing to do when none waits).
            for (i32 round = 0; m_root != nullptr && round < 8 && (m_root->IsLayoutDirty() || m_root->HasLayoutDirtyDescendant());
                 ++round)
                m_root->ArrangeAgain();
            PlacePopups();
            Node* hit = FindInPopups(position);
            if (hit == nullptr && m_root != nullptr)
                hit = m_root->OverFind(position);
            // Below the topmost modal popup everything is inert: a hit there is swallowed.
            if (!IsLive(hit))
                return nullptr;
            return hit;
        }

        bool PointerMove(core::Float2 position, PointerType pointer, u64 id, u32 modifiers = 0)
        {
            m_mousePos = position;
            if (m_longPressArmed && core::Abs(position.x - m_pressAt.x) + core::Abs(position.y - m_pressAt.y) > Dips(kTapSlop))
                m_longPressArmed = false; // the finger moved: a drag or a scroll, not a long press
            // A drag in progress: the pointer only asks where a drop would land.
            if (m_dragActive)
            {
                m_dragModifiers = modifiers;
                QueryDrop(position);
                return true;
            }
            // A press moved past the threshold: a drag, if a source up from the pressed node gives one.
            if (m_downNode != nullptr && !m_dragTried && (pointer == PointerType::Mouse || m_touchDragArmed) &&
                core::Abs(position.x - m_pressAt.x) + core::Abs(position.y - m_pressAt.y) > Dips(m_dragThreshold))
                if (TryDrag(position, modifiers, pointer))
                    return true;
            Node* hit = HitTest(position);
            UpdateHoverPath(hit, position);
            // The captured node (explicitly, or the pressed one while a button is held) keeps the
            // moves, so a drag goes on when the pointer leaves it; otherwise the hovered node.
            Node* target = PointerTarget(hit);
            bool used = false;
            if (target != nullptr && target->IsTreeEnabled())
            {
                MouseEvent event(EventType::MouseMove, target, position, MouseButton::Left, modifiers);
                event.Pointer = pointer;
                event.PointerId = id;
                used = target->RouteEvent(event);
            }
            return used || IsPointerTaken(hit);
        }

        bool PointerDown(core::Float2 position, MouseButton button, u32 modifiers, PointerType pointer, u64 id)
        {
            NoteInput();
            // A pointer in use: the focus ring hides (shown again by the next key or d-pad move).
            ApplyInputKind(InputKind::Pointer);
            m_keysMovedFocus = false; // the focus's tooltip waits for the keys again (E16)
            m_mousePos = position;
            if (m_dragActive)
            {
                // A second press while dragging (a right one, as Godot): cancelled, the press eaten.
                CancelDrag();
                m_swallowing = true;
                return true;
            }
            m_dragTried = button != MouseButton::Left; // only a left press (a finger's) drags
            m_touchDragArmed = false;
            Node* hit = HitTest(position);
            UpdateHoverPath(hit, position);
            // Any press hides a tooltip. A press closes the auto popups above the one it is in; one in
            // no popup is consumed with the rest of its gesture: closing a menu never acts on what
            // lies under it, and the opener pressed again closes without reopening (E5).
            ClosePopupsOfKind(PopupKind::Hint, PopupCloseReason::OutsidePress);
            if (DismissOutside(hit))
            {
                m_swallowing = true;
                m_downNode = nullptr;
                return true;
            }
            CountClick(position, button, pointer);
            m_longPressArmed = pointer == PointerType::Touch && hit != nullptr;
            m_pressHeld = 0.0f;
            m_pressAt = position;
            m_downNode = hit;
            m_clickSuppressed = false;
            SetPressPath(hit);
            // Click-to-focus: the nearest widget that takes focus, at or above what was hit; none
            // (a click on a backdrop or a label) clears focus, as browsers do, so navigation
            // starts again from the GUI's entry rather than from the backdrop. A node that keeps
            // the focus, met first, leaves it where it is (a completion list's row).
            Node* focusable = hit;
            bool keep = false;
            while (focusable != nullptr && !(focusable->IsTabFocusable() && focusable->IsTreeEnabled()))
            {
                if (focusable->GetKeepsFocus())
                {
                    keep = true;
                    break;
                }
                focusable = focusable->GetParent();
            }
            if (!keep)
                SetFocusNode(focusable);
            // A disabled widget still takes the press (nothing behind it does) but is not told.
            bool used = false;
            if (hit != nullptr && hit->IsTreeEnabled())
            {
                MouseEvent event(EventType::MouseDown, hit, position, button, modifiers);
                event.ClickCount = m_clickCount;
                event.Pointer = pointer;
                event.PointerId = id;
                used = hit->RouteEvent(event);
            }
            return used || IsPointerTaken(hit);
        }

        bool PointerUp(core::Float2 position, MouseButton button, u32 modifiers, PointerType pointer, u64 id)
        {
            m_mousePos = position;
            m_longPressArmed = false;
            if (m_swallowing)
            {
                m_swallowing = false; // the end of a press that closed a popup: nothing more of it
                return true;
            }
            // A release while dragging drops on the target, if one takes it (asked once more
            // where it is), and ends the drag; the press was cancelled when it began.
            if (m_dragActive)
            {
                m_dragModifiers = modifiers;
                QueryDrop(position);
                Drop();
                return true;
            }
            Node* hit = HitTest(position);
            // Both nodes are pinned for the rest of this call: a handler may mutate the tree
            // (e.g. a header click re-sorts a model and the view rebuilds its header cells),
            // dropping the last owning reference to the very node still on the call stack.
            const core::RefPtr<Node> hitPin{hit};
            Node* target = PointerTarget(hit); // the captured or pressed node gets the release
            const core::RefPtr<Node> targetPin{target};
            const core::RefPtr<Node> downPin{m_downNode};
            bool used = false;
            if (target != nullptr && target->IsTreeEnabled())
            {
                MouseEvent event(EventType::MouseUp, target, position, button, modifiers);
                event.ClickCount = m_clickCount;
                event.Pointer = pointer;
                event.PointerId = id;
                used = target->RouteEvent(event);
            }
            // A right release asks for a context menu where it was, from the node there up.
            if (button == MouseButton::Right && hit != nullptr && hit->IsTreeEnabled() && IsInSubtree(hit, m_root))
            {
                MouseEvent menu(EventType::ContextMenu, hit, position, button, modifiers);
                menu.Pointer = pointer;
                used = hit->RouteEvent(menu) || used;
            }
            // A click (activation) for the left button only, on the nearest node holding both the
            // pressed node and the one released over (a press dragged onto a sibling clicks their
            // container, not either), as the DOM does. Right and middle presses still deliver
            // down and up (a context menu) but never activate a control. A cancelled press has no
            // pressed node, so no click.
            if (button == MouseButton::Left && m_downNode != nullptr && hit != nullptr && !m_clickSuppressed)
                if (Node* clicked = CommonAncestor(m_downNode, hit); clicked != nullptr && clicked->IsTreeEnabled())
                {
                    MouseEvent event(EventType::MouseClick, clicked, position, button, modifiers);
                    event.ClickCount = m_clickCount;
                    event.Pointer = pointer;
                    event.PointerId = id;
                    used = clicked->RouteEvent(event) || used;
                }
            m_downNode = nullptr;
            ClearPressPath();
            if (m_captureNode != nullptr)
                ReleasePointer(*m_captureNode); // a capture ends with the press, as the DOM's does
            return used || IsPointerTaken(hit);
        }

        // The node a pointer move or release goes to: the captured node, else the pressed one
        // while a button is held, else the one under the pointer.
        [[nodiscard]] Node* PointerTarget(Node* hit) const
        {
            return m_captureNode != nullptr ? m_captureNode : m_downNode != nullptr ? m_downNode : hit;
        }
        // Whether `hit`, or a node above it short of the root, takes the pointer.
        [[nodiscard]] bool IsPointerTaken(Node* hit) const
        {
            for (Node* n = hit; n != nullptr && n != m_root; n = n->GetParent())
                if (n->TakesPointer())
                    return true;
            return false;
        }
        // Keys go to the focused widget, or, with nothing focused, to the root (its capture and
        // bubble listeners still hear them); a disabled one hears nothing.
        [[nodiscard]] Node* KeyTarget() const
        {
            Node* target = m_focusNode != nullptr ? m_focusNode : m_root;
            if (!IsLive(target))
                target = FocusScopeRoot(); // below a modal: the keys are the modal's
            return target != nullptr && target->IsTreeEnabled() ? target : nullptr;
        }
        bool RouteKey(EventType type, u32 keyCode, u32 modifiers)
        {
            (void)HitTest(core::Float2{}); // keys see the layout as it is now, as the pointer does
            Node* target = KeyTarget();
            if (target == nullptr)
                return false;
            KeyEvent event(type, target, keyCode, modifiers);
            return target->RouteEvent(event);
        }
        // The nearest node holding both (each counting as holding itself); null in different trees.
        [[nodiscard]] static Node* CommonAncestor(Node* a, Node* b)
        {
            for (Node* n = a; n != nullptr; n = n->GetParent())
                if (IsInSubtree(b, n))
                    return n;
            return nullptr;
        }
        // The hover path follows the node under the pointer: the nodes that leave it are told
        // (deepest first) and the nodes that join it (outermost first), each one on its own, and
        // every node on it reads as hovered, so `:hover` holds for a card while a button inside
        // it is under the pointer, as CSS has it.
        void UpdateHoverPath(Node* hit, core::Float2 position)
        {
            Array<Node*> path;
            for (Node* n = hit; n != nullptr; n = n->GetParent())
                path.PushBack(n);
            for (usize i = 0, j = path.Size(); i + 1 < j; ++i, --j)
                core::Swap(path[i], path[j - 1]); // root first
            usize common = 0;
            while (common < m_hoverPath.Size() && common < path.Size() && m_hoverPath[common] == path[common])
                ++common;
            if (common == m_hoverPath.Size() && common == path.Size())
                return;
            // Held while their handlers run: an enter or a leave may change the tree.
            Array<core::RefPtr<Node>> leaving;
            for (usize i = m_hoverPath.Size(); i-- > common;)
                leaving.PushBack(core::RefPtr<Node>(m_hoverPath[i]));
            Array<core::RefPtr<Node>> joining;
            for (usize i = common; i < path.Size(); ++i)
                joining.PushBack(core::RefPtr<Node>(path[i]));
            m_hoverPath = core::Move(path);
            m_overNode = hit;
            for (const core::RefPtr<Node>& node : leaving)
            {
                node->SetHovered(false);
                MouseEvent event(EventType::MouseLeave, node.Get(), position);
                node->DeliverRouted(event);
            }
            for (const core::RefPtr<Node>& node : joining)
            {
                node->SetHovered(true);
                MouseEvent event(EventType::MouseEnter, node.Get(), position);
                node->DeliverRouted(event);
            }
        }
        // The press path: the pressed node and the nodes holding it read as pressed (`:active`)
        // until the release.
        void SetPressPath(Node* hit)
        {
            ClearPressPath();
            if (hit == nullptr || !hit->IsTreeEnabled())
                return;
            for (Node* n = hit; n != nullptr; n = n->GetParent())
            {
                n->SetPressed(true);
                m_pressPath.PushBack(n);
            }
        }
        void ClearPressPath()
        {
            Array<Node*> path = core::Move(m_pressPath);
            m_pressPath = Array<Node*>{};
            for (Node* n : path)
                n->SetPressed(false);
        }
        // Drops the part of a hover or press path inside a subtree that is leaving the tree.
        static void PrunePath(Array<Node*>& path, Node& removed, bool hover)
        {
            for (usize i = 0; i < path.Size(); ++i)
                if (IsInSubtree(path[i], &removed))
                {
                    for (usize j = i; j < path.Size(); ++j)
                        hover ? path[j]->SetHovered(false) : path[j]->SetPressed(false);
                    while (path.Size() > i)
                        path.PopBack();
                    return;
                }
        }
        void SendCaptureLost(Node& node)
        {
            const core::RefPtr<Node> pin{&node};
            Event event(EventType::PointerCaptureLost, &node);
            node.DeliverRouted(event);
        }
        // A second press of the same button near in time and place is a double click, a third a
        // triple (positions in device pixels).
        // === Gestures (E17c) === Two fingers down over a node whose touch-action leaves pinch-zoom
        // out (the node, or what holds both fingers' nodes) make one gesture from the moment the
        // second lands: the first finger's press is cancelled, and the node hears gesturestart,
        // gesturechange as the fingers move (scale, rotation and translation together, as Safari's
        // and aui's), and gestureend when one lifts. Over a node that leaves pinch-zoom to the GUI,
        // a second finger does nothing, as before.
        bool BeginGesture()
        {
            if (m_gesturing || m_fingers.Size() != 2)
                return false;
            Node* target = CommonAncestor(HitTest(m_fingers[0].Now), HitTest(m_fingers[1].Now));
            if (target == nullptr || (target->EffectiveTouchActions() & kTouchPinchZoom) != 0)
                return false;
            if (m_touchActive)
            {
                CancelPointer(); // the first finger's press: a gesture, not a tap
                m_longPressArmed = false;
                m_touchDragArmed = false;
                m_panning = false;
                m_panScroller = nullptr;
                m_touchActive = false;
                UpdateHoverPath(nullptr, m_fingers[0].Now);
            }
            m_gestureIds[0] = m_fingers[0].Id;
            m_gestureIds[1] = m_fingers[1].Id;
            const core::Float2 a = m_fingers[0].Now, b = m_fingers[1].Now;
            m_gestureSpan0 = core::Max(core::Length(core::Float2{b.x - a.x, b.y - a.y}), 1.0f);
            m_gestureAngle = core::Atan2(b.y - a.y, b.x - a.x);
            m_gestureFocus0 = core::Float2{(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f};
            m_gestureScale = 1.0f;
            m_gestureRotation = 0.0f;
            m_gestureTranslation = core::Float2{0.0f, 0.0f};
            m_gesturePointer = PointerType::Touch;
            m_gestureTarget = core::RefPtr<Node>(target);
            m_gesturing = true;
            RouteGesture(EventType::GestureStart, 1.0f, 0.0f, core::Float2{0.0f, 0.0f});
            return true;
        }
        [[nodiscard]] bool IsGestureFinger(u64 id) const noexcept
        {
            return m_gesturePointer == PointerType::Touch && (id == m_gestureIds[0] || id == m_gestureIds[1]);
        }
        void MoveGesture()
        {
            const i32 ia = FindFinger(m_gestureIds[0]), ib = FindFinger(m_gestureIds[1]);
            if (ia < 0 || ib < 0)
                return;
            if (m_gestureTarget->GetRootNode() != m_root)
            {
                EndGesture(EventType::GestureCancel); // its node left the tree
                return;
            }
            const core::Float2 a = m_fingers[static_cast<usize>(ia)].Now, b = m_fingers[static_cast<usize>(ib)].Now;
            const f32 scale = core::Max(core::Length(core::Float2{b.x - a.x, b.y - a.y}), 1.0f) / m_gestureSpan0;
            const f32 angle = core::Atan2(b.y - a.y, b.x - a.x);
            f32 turned = angle - m_gestureAngle; // the shorter way round: past a half turn it wraps
            if (turned > core::kPi)
                turned -= 2.0f * core::kPi;
            else if (turned < -core::kPi)
                turned += 2.0f * core::kPi;
            m_gestureAngle = angle;
            const core::Float2 focus{(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f};
            // In the GUI's units, as positions are: not the node's own, which its gesture may turn.
            const core::Float2 translation = InNodeUnits(*m_root, m_gestureFocus0,
                                                         core::Float2{focus.x - m_gestureFocus0.x, focus.y - m_gestureFocus0.y});
            const f32 scaleDelta = scale / m_gestureScale;
            const core::Float2 translationDelta{translation.x - m_gestureTranslation.x, translation.y - m_gestureTranslation.y};
            m_gestureScale = scale;
            m_gestureRotation += turned;
            m_gestureTranslation = translation;
            RouteGesture(EventType::GestureChange, scaleDelta, turned, translationDelta);
        }
        void EndGesture(EventType type)
        {
            m_gesturing = false;
            const core::RefPtr<Node> target = core::Move(m_gestureTarget);
            if (target && target->GetRootNode() == m_root)
            {
                GestureEvent event(type, target.Get());
                event.Pointer = m_gesturePointer;
                event.Focus = GestureFocus();
                event.Scale = m_gestureScale;
                event.Rotation = m_gestureRotation;
                event.Translation = m_gestureTranslation;
                (void)target->RouteEvent(event);
            }
        }
        [[nodiscard]] core::Float2 GestureFocus() const
        {
            const i32 ia = FindFinger(m_gestureIds[0]), ib = FindFinger(m_gestureIds[1]);
            if (ia < 0 || ib < 0)
                return m_gestureFocus0;
            const core::Float2 a = m_fingers[static_cast<usize>(ia)].Now, b = m_fingers[static_cast<usize>(ib)].Now;
            return core::Float2{(a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f};
        }
        void RouteGesture(EventType type, f32 scaleDelta, f32 rotationDelta, core::Float2 translationDelta)
        {
            GestureEvent event(type, m_gestureTarget.Get());
            event.Pointer = m_gesturePointer;
            event.Focus = GestureFocus();
            event.Scale = m_gestureScale;
            event.Rotation = m_gestureRotation;
            event.Translation = m_gestureTranslation;
            event.ScaleDelta = scaleDelta;
            event.RotationDelta = rotationDelta;
            event.TranslationDelta = translationDelta;
            (void)m_gestureTarget->RouteEvent(event);
        }

        /// `dips` in the device pixels positions come in: the root's display scale times it.
        [[nodiscard]] f32 Dips(f32 dips) const noexcept { return dips * (m_root != nullptr ? m_root->GetPixelScale() : 1.0f); }
        void CountClick(core::Float2 position, MouseButton button, PointerType pointer)
        {
            const f32 dx = position.x - m_lastPressAt.x;
            const f32 dy = position.y - m_lastPressAt.y;
            const f32 slop = Dips(pointer == PointerType::Touch ? kTapSlop : kClickSlop); // a finger wobbles more
            const bool near = dx * dx + dy * dy <= slop * slop;
            const bool soon = m_time - m_lastPressTime <= kClickInterval;
            m_clickCount = (button == m_lastPressButton && near && soon && m_clickCount > 0) ? m_clickCount + 1 : 1;
            m_lastPressTime = m_time;
            m_lastPressAt = position;
            m_lastPressButton = button;
        }
        static constexpr f32 kClickInterval = 0.45f; // seconds between the presses of a double click
        // Lengths in DIPs, as a person's hand measures them: scaled by the display (Dips) to the
        // device pixels positions come in (E17c; Android's touch slop is 8dp, scaled the same way).
        static constexpr f32 kClickSlop = 6.0f;      // between the presses of a double click
        static constexpr f32 kTapSlop = 24.0f;       // between two taps
        static constexpr f32 kStickDeadZone = 0.2f;  // a stick at rest wobbles within this
        static constexpr f32 kStickSpeed = 1400.0f;  // pixels a second, pushed all the way

        // The right stick: past its dead zone, rescaled from there and squared (fine near the
        // centre, fast at the rim), each axis moving the nearest scroller that scrolls that way.
        void ScrollByStick(f32 seconds)
        {
            const auto shape = [](f32 v)
            {
                const f32 a = core::Abs(v);
                if (a <= kStickDeadZone)
                    return 0.0f;
                const f32 t = core::Min(1.0f, (a - kStickDeadZone) / (1.0f - kStickDeadZone));
                return (v < 0.0f ? -t : t) * t;
            };
            const core::Float2 push{shape(m_scrollStick.x), shape(m_scrollStick.y)};
            if (push.x == 0.0f && push.y == 0.0f)
                return;
            Node* from = m_focusNode != nullptr ? m_focusNode : (m_hoverPath.IsEmpty() ? nullptr : m_hoverPath[m_hoverPath.Size() - 1]);
            for (u32 axis = 0; axis < 2; ++axis)
            {
                const f32 p = axis == 0 ? push.x : push.y;
                if (p == 0.0f)
                    continue;
                for (Node* n = from; n != nullptr; n = n->GetParent())
                {
                    if (!n->IsScrollContainer() || (axis == 0 ? n->GetScrollRange().x : n->GetScrollRange().y) <= 0.0f)
                        continue;
                    const f32 by = p * kStickSpeed * seconds;
                    n->ScrollBy(axis == 0 ? core::Float2{by, 0.0f} : core::Float2{0.0f, by});
                    break;
                }
            }
        }
        static constexpr f32 kPanSlop = 8.0f;        // DIPs a finger moved: panning, not tapping
        static constexpr f32 kFlingMinSpeed = 60.0f; // DIPs a second: slower let go just stops
        static constexpr f32 kPanWindow = 0.1f;      // seconds of the finger's path its speed is read over

        // The nearest scroller at or above where the finger went down that can move along the
        // way it moved (its larger axis).
        // A move of `delta` at world point `at`, in `node`'s own units (a finger moves in the
        // window's pixels; a scroller scrolls in its logical units, which a display scale or a
        // transform makes differ).
        [[nodiscard]] static core::Float2 InNodeUnits(const Node& node, core::Float2 at, core::Float2 delta)
        {
            const core::Float2 from = node.ConvertToNodeSpace(at);
            const core::Float2 to = node.ConvertToNodeSpace(core::Float2{at.x + delta.x, at.y + delta.y});
            return core::Float2{to.x - from.x, to.y - from.y};
        }
        [[nodiscard]] Node* PanScrollerFor(core::Float2 moved) const
        {
            const bool across = core::Abs(moved.x) > core::Abs(moved.y);
            for (Node* n = HitTest(m_pressAt); n != nullptr; n = n->GetParent())
            {
                if (!n->IsScrollContainer())
                    continue;
                const core::Float2 range = n->GetScrollRange();
                if ((across ? range.x : range.y) > 0.0f)
                    return n;
            }
            return nullptr;
        }
        void AddPanSample(core::Float2 position)
        {
            // A ring of the last few points on the dispatcher's clock.
            m_panSamples[m_panSampleCount % kPanSamples] = PanSample{m_time, position};
            ++m_panSampleCount;
        }
        // The finger's speed over its last kPanWindow: from the oldest sample within it to the latest.
        [[nodiscard]] core::Float2 PanVelocity() const
        {
            if (m_panSampleCount < 2)
                return core::Float2{0.0f, 0.0f};
            const PanSample& last = m_panSamples[(m_panSampleCount - 1) % kPanSamples];
            const PanSample* first = &last;
            const usize kept = core::Min<usize>(m_panSampleCount, kPanSamples);
            for (usize i = 1; i < kept; ++i)
            {
                const PanSample& s = m_panSamples[(m_panSampleCount - 1 - i) % kPanSamples];
                if (last.Time - s.Time > kPanWindow)
                    break;
                first = &s;
            }
            const f32 dt = last.Time - first->Time;
            if (dt <= 0.004f)
                return core::Float2{0.0f, 0.0f};
            return core::Float2{(last.Position.x - first->Position.x) / dt, (last.Position.y - first->Position.y) / dt};
        }

        // True if `node` is `ancestor` or a descendant of it.
        [[nodiscard]] static bool IsInSubtree(const Node* node, const Node* ancestor)
        {
            if (ancestor == nullptr)
                return false;
            for (const Node* n = node; n != nullptr; n = n->GetParent())
                if (n == ancestor)
                    return true;
            return false;
        }

        // === Drag and drop's own ===
        // The modifiers' choice among the effects the source allows (Ctrl copy, Shift move, both
        // link), else move, copy or link, whichever it allows first.
        [[nodiscard]] DropEffect PreferredEffect() const
        {
            const bool ctrl = (m_dragModifiers & KeyModCtrl) != 0;
            const bool shift = (m_dragModifiers & KeyModShift) != 0;
            const DropEffect asked = ctrl && shift ? DropEffect::Link : ctrl ? DropEffect::Copy : shift ? DropEffect::Move : DropEffect::None;
            if (asked != DropEffect::None && (m_dragPayload.Allowed & DropEffectFlag(asked)) != 0)
                return asked;
            const DropEffect order[] = {DropEffect::Move, DropEffect::Copy, DropEffect::Link};
            for (DropEffect e : order)
                if ((m_dragPayload.Allowed & DropEffectFlag(e)) != 0)
                    return e;
            return DropEffect::None;
        }

        // Whether a press on `node` would offer a drag that something takes (asked without
        // starting it: a source's answer must not change anything).
        [[nodiscard]] bool HasDragSource(Node* node) const
        {
            for (Node* n = node; n != nullptr; n = n->GetParent())
            {
                const core::Float2 local = n->ConvertToNodeSpace(m_pressAt);
                if (n->OwnsPressDrag(local))
                    return false;
                DragRequest request;
                request.Press = local;
                request.Pointer = PointerType::Touch;
                if (n->HandleDragRequested(request))
                    return true;
            }
            return false;
        }

        // A press past the threshold: the drag offered up from the pressed node.
        bool TryDrag(core::Float2 position, u32 modifiers, PointerType pointer)
        {
            m_dragTried = true;
            for (Node* n = m_downNode; n != nullptr; n = n->GetParent())
            {
                if (!n->IsTreeEnabled())
                    return false;
                const core::Float2 local = n->ConvertToNodeSpace(m_pressAt);
                if (n->OwnsPressDrag(local))
                    return false; // its press is its own (a slider, a scroll bar, a field)
                DragRequest request;
                request.Press = local;
                request.Modifiers = modifiers;
                request.Pointer = pointer;
                if (n->HandleDragRequested(request))
                {
                    m_dragModifiers = modifiers;
                    BeginDrag(*n, core::Move(request), position);
                    return true;
                }
            }
            return false;
        }

        void BeginDrag(Node& source, DragRequest request, core::Float2 at)
        {
            if (m_dragActive)
                CancelDrag();
            const core::RefPtr<Node> pin{&source};
            CancelPointer(); // the press is the drag's now: no release or click follows
            HideTooltip();
            m_dragActive = true;
            m_dragSource = &source;
            m_dragFromKeyboard = request.FromKeyboard;
            m_dragPayload = core::Move(request.Payload);
            if (m_dragPayload.Label.IsEmpty())
                m_dragPayload.Label = m_dragPayload.Type;
            source.SetDragSourceState(true);

            // The preview, held where the press was on the source (GPUI), or beside the pointer.
            m_dragPreview = request.Preview;
            if (request.HasGrabOffset)
                m_grabOffset = request.GrabOffset;
            else if (m_dragPreview)
                m_grabOffset = request.Press;
            else
                m_grabOffset = core::Float2{-14.0f, -12.0f};
            m_dragFollow = core::Move(request.Follow);
            if (!m_dragPreview && !m_dragFollow)
                m_dragPreview = source.CreateDragPreview(m_dragPayload);
            if (m_root != nullptr)
            {
                m_dragLayer = core::MakeRef<DragLayer>(m_root->MemoryAllocator());
                m_dragLayer->SetPosition(core::Float2{0.0f, 0.0f});
                m_dragLayer->SetSize(m_root->GetSize());
                if (m_dragPreview)
                {
                    m_dragPreview->SetHitTestVisible(false);
                    m_dragLayer->AddChild(m_dragPreview.Get());
                }
                PopupOptions options;
                options.Kind = PopupKind::Manual;
                options.PassesPointer = true;
                OpenPopup(*m_root, *m_dragLayer, core::Move(options));
                m_dragLayerIn = this;
            }
            m_dragOver = this;
            m_dragOutside = false;

            DragEvent started(EventType::DragStart, &source, m_dragPayload);
            started.Position = RootPoint(at);
            started.Modifiers = m_dragModifiers;
            source.SendEvent(started);
            QueryDrop(at);
        }

        // Where a drag's pointer is: over this root, over another root of the GUI (a window of its
        // own), or outside every root. Where the roots' places are not known (Wayland, no host),
        // past its own root's edge is outside (a drop nothing there takes ends outside).
        void LocateDrag(core::Float2 at)
        {
            m_dragOver = this;
            m_dragOverAt = at;
            m_dragOutside = false;
            m_dragScreenKnown = false;
            if (m_dragFromKeyboard)
                return; // the focus is what is asked
            core::Float2 screen;
            if (m_rootPlaces != nullptr && m_rootPlaces->ToScreen(*this, at, screen))
            {
                m_dragScreenKnown = true;
                m_dragScreen = screen;
                core::Float2 local;
                if (EventDispatcher* over = m_rootPlaces->DispatcherAt(screen, local))
                {
                    m_dragOver = over;
                    m_dragOverAt = local;
                }
                else
                    m_dragOutside = true;
                return;
            }
            if (m_root != nullptr)
            {
                const core::Float2 p = RootPoint(at);
                const core::Float2 size = m_root->GetSize();
                m_dragOutside = p.x < 0.0f || p.y < 0.0f || p.x >= size.x || p.y >= size.y;
            }
        }
        // The drag's layer (its preview and hint) in the root the pointer is over, a popup there.
        void MoveDragLayerTo(EventDispatcher& over)
        {
            if (!m_dragLayer || m_dragLayerIn == &over || over.m_root == nullptr)
                return;
            if (m_dragLayerIn != nullptr && m_dragLayerIn->IsPopupOpen(*m_dragLayer))
                (void)m_dragLayerIn->ClosePopup(*m_dragLayer, PopupCloseReason::Code);
            m_dragLayer->SetSize(over.m_root->GetSize());
            PopupOptions options;
            options.Kind = PopupKind::Manual;
            options.PassesPointer = true;
            over.OpenPopup(*over.m_root, *m_dragLayer, core::Move(options));
            m_dragLayerIn = &over;
        }

        // What a drop at `at` would do: asked of the node there and up its ancestors (in the root
        // the pointer is over, which may be another root's of the GUI).
        void QueryDrop(core::Float2 at)
        {
            m_mousePos = at;
            if (m_dragFollow)
                m_dragFollow(RootPoint(at)); // the source moves first: what it leaves is asked
            LocateDrag(at);
            if (!m_dragOutside)
                MoveDragLayerTo(*m_dragOver);
            const core::Float2 overAt = m_dragOverAt;
            // Over no root of the placed ones: nothing to ask. Past its own root's edge where the
            // places are not known, what lies there is still asked (a node may reach past it).
            Node* hit = m_dragOutside && m_dragScreenKnown ? nullptr : m_dragOver->HitTest(overAt);
            NoteDragRest(hit);
            DropQuery query{m_dragPayload, core::Float2{0.0f, 0.0f}, 0, DropEffect::Move, false, DropEffect::None, core::String{}, false, 0};
            query.Modifiers = m_dragModifiers;
            query.Preferred = PreferredEffect();
            Node* target = nullptr;
            for (Node* n = hit; n != nullptr; n = n->GetParent())
            {
                if (!n->IsTreeEnabled())
                    break;
                query.Local = n->ConvertToNodeSpace(overAt);
                query.Effect = DropEffect::None;
                n->HandleDragQuery(query);
                if (query.Effect != DropEffect::None)
                {
                    target = n;
                    break;
                }
                if (query.Refused)
                    break; // refused with a reason: the walk ends, the reason shows
            }
            SetDropTarget(target, query, at);
        }

        void SetDropTarget(Node* target, const DropQuery& query, core::Float2 at)
        {
            (void)at;
            const core::Float2 rootAt = DragRootPoint();
            const auto event = [&](EventType type, Node* node)
            {
                DragEvent e(type, node, m_dragPayload);
                e.Effect = query.Effect;
                e.Position = rootAt;
                e.Modifiers = m_dragModifiers;
                e.Place = query.Place;
                return e;
            };
            if (target != m_dropTarget)
            {
                if (Node* left = m_dropTarget)
                {
                    m_dropTarget = nullptr;
                    left->SetDropTargetState(false);
                    left->HandleDragEvent(event(EventType::DragLeave, left));
                }
                m_dropTarget = target;
                if (target != nullptr)
                {
                    target->SetDropTargetState(true);
                    target->HandleDragEvent(event(EventType::DragEnter, target));
                }
            }
            if (m_dropTarget != nullptr)
                m_dropTarget->HandleDragEvent(event(EventType::DragOver, m_dropTarget));
            m_dropEffect = target != nullptr ? query.Effect : DropEffect::None;
            m_dropPlace = query.Place;
            ShowDropState(query.Reason.AsView(), query.Refused, rootAt);
        }

        // The preview at the pointer with the effect shown, and the reason's hint beside it.
        void ShowDropState(core::StringView reason, bool refused, core::Float2 rootAt)
        {
            if (!m_dragLayer)
                return;
            if (m_dragPreview)
            {
                m_dragPreview->OnDragPreviewEffect(m_dropEffect);
                m_dragLayer->Place(*m_dragPreview, core::Float2{rootAt.x - m_grabOffset.x, rootAt.y - m_grabOffset.y});
            }
            const bool showHint = reason.Size() != 0;
            if (showHint && (m_dropReason.AsView() != reason || m_dropRefused != refused || !m_dropHint))
            {
                if (m_dropHint)
                    m_dropHint->RemoveFromParent();
                m_dropHint = m_dragSource != nullptr ? m_dragSource->CreateDropHint(reason, refused) : core::RefPtr<Node>{};
                if (m_dropHint)
                {
                    m_dropHint->SetHitTestVisible(false);
                    m_dragLayer->AddChild(m_dropHint.Get());
                }
            }
            else if (!showHint && m_dropHint)
            {
                m_dropHint->RemoveFromParent();
                m_dropHint = core::RefPtr<Node>{};
            }
            m_dropReason = core::String(reason);
            m_dropRefused = refused;
            if (m_dropHint)
            {
                // Below the preview (beside the pointer when it has none), never over it.
                core::Float2 at{rootAt.x + 16.0f, rootAt.y + 22.0f};
                if (m_dragPreview)
                {
                    const core::Float2 size = m_dragPreview->Measure(LayoutConstraints{});
                    at = core::Float2{rootAt.x - m_grabOffset.x, rootAt.y - m_grabOffset.y + size.y + 4.0f};
                }
                m_dragLayer->Place(*m_dropHint, at);
            }
        }

        void Drop()
        {
            Node* target = m_dropTarget;
            const DropEffect effect = m_dropEffect;
            if (target == nullptr || effect == DropEffect::None)
            {
                FinishDrag(DropEffect::None, nullptr, false);
                return;
            }
            const core::RefPtr<Node> pin{target};
            DragEvent dropped(EventType::Drop, target, m_dragPayload);
            dropped.Effect = effect;
            dropped.Position = DragRootPoint();
            dropped.Modifiers = m_dragModifiers;
            dropped.Place = m_dropPlace;
            target->HandleDragEvent(dropped);
            FinishDrag(effect, target, false);
        }

        // The drag ends: the layer goes, the states clear, the source is told.
        void FinishDrag(DropEffect effect, Node* target, bool cancelled)
        {
            if (!m_dragActive)
                return;
            m_dragActive = false;
            const core::RefPtr<Node> source{m_dragSource};
            const DragPayload payload = core::Move(m_dragPayload);
            if (Node* left = m_dropTarget)
            {
                m_dropTarget = nullptr;
                left->SetDropTargetState(false);
                if (target == nullptr)
                {
                    DragEvent leave(EventType::DragLeave, left, payload);
                    leave.Position = DragRootPoint();
                    left->HandleDragEvent(leave);
                }
            }
            if (m_dragLayer && m_dragLayerIn != nullptr && m_dragLayerIn->IsPopupOpen(*m_dragLayer))
                (void)m_dragLayerIn->ClosePopup(*m_dragLayer, PopupCloseReason::Code);
            m_dragLayer = core::RefPtr<DragLayer>{};
            m_dragLayerIn = nullptr;
            const bool outside = m_dragOutside && target == nullptr && !cancelled;
            const bool screenKnown = m_dragScreenKnown;
            const core::Float2 screen = m_dragScreen;
            m_dragOver = nullptr;
            m_dragOutside = false;
            m_dragPreview = core::RefPtr<Node>{};
            m_dragFollow = {};
            m_dropHint = core::RefPtr<Node>{};
            m_dragSource = nullptr;
            m_dropEffect = DropEffect::None;
            m_dropReason = core::String{};
            m_dropRefused = false;
            m_dragFromKeyboard = false;
            m_dragRestNode = nullptr;
            if (source)
            {
                source->SetDragSourceState(false);
                DragResult result{effect, target, cancelled, outside, screenKnown, screen};
                DragEvent ended(EventType::DragEnd, source.Get(), payload);
                ended.Effect = effect;
                ended.Position = RootPoint(m_mousePos);
                source->HandleDragEnd(result, ended);
            }
        }

        // A drag's tick: the scroller under the pointer near its edge scrolls (the innermost that
        // can move that way), and a drag resting on a node a moment opens it.
        void TickDrag(f32 seconds)
        {
            if (m_dragOver != this || m_dragOutside)
                return; // over another root (whose own content it does not scroll) or none
            Node* hit = HitTest(m_mousePos);
            bool moved = false;
            for (Node* n = hit; n != nullptr && !moved; n = n->GetParent())
            {
                if (!n->IsScrollContainer())
                    continue;
                const core::Float2 p = n->ConvertToNodeSpace(m_mousePos);
                const core::Float2 size = n->GetSize();
                const core::Float2 range = n->GetScrollRange();
                const core::Float2 offset = n->GetScrollOffset();
                const core::Float2 low = n->GetScrollMin(), high = n->GetScrollMax();
                const auto speed = [&](f32 at, f32 length, f32 now, f32 min, f32 max) -> f32
                {
                    if (at < m_dragScrollBand && now > min)
                        return -m_dragScrollSpeed * (1.0f - core::Max(0.0f, at) / m_dragScrollBand);
                    if (at > length - m_dragScrollBand && now < max)
                        return m_dragScrollSpeed * (1.0f - core::Max(0.0f, length - at) / m_dragScrollBand);
                    return 0.0f;
                };
                const core::Float2 v{range.x > 0.0f ? speed(p.x, size.x, offset.x, low.x, high.x) : 0.0f,
                                     range.y > 0.0f ? speed(p.y, size.y, offset.y, low.y, high.y) : 0.0f};
                if (v.x != 0.0f || v.y != 0.0f)
                {
                    n->ScrollBy(core::Float2{v.x * seconds, v.y * seconds});
                    moved = true;
                }
            }
            // Resting: the same node under the pointer since it arrived there.
            NoteDragRest(hit);
            if (!moved && !m_dragRestOpened)
            {
                m_dragRest += seconds;
                if (m_dragRest >= m_dragHoverOpenDelay)
                {
                    m_dragRestOpened = true;
                    for (Node* n = hit; n != nullptr; n = n->GetParent())
                        if (n->HandleDragHoverOpen(n->ConvertToNodeSpace(m_mousePos)))
                        {
                            moved = true;
                            break;
                        }
                }
            }
            if (moved)
                QueryDrop(m_mousePos); // the content moved under the pointer
        }

        // A keyboard drag's point: the focus's centre (in device pixels, as input arrives).
        [[nodiscard]] core::Float2 FocusPoint() const
        {
            if (m_focusNode == nullptr)
                return m_mousePos;
            return m_focusNode->ConvertToWorldSpace(core::Float2{m_focusNode->GetSize().x * 0.5f, m_focusNode->GetSize().y * 0.5f});
        }
        // A keyboard drag asks the focus and up its ancestors (not what lies under a point).
        void QueryAtFocus()
        {
            if (!m_dragActive)
                return;
            const core::Float2 at = FocusPoint();
            m_mousePos = at;
            DropQuery query{m_dragPayload, core::Float2{0.0f, 0.0f}, 0, PreferredEffect(), true, DropEffect::None, core::String{}, false, 0};
            Node* target = nullptr;
            for (Node* n = m_focusNode; n != nullptr; n = n->GetParent())
            {
                if (!n->IsTreeEnabled())
                    break;
                query.Local = n->ConvertToNodeSpace(at);
                query.Effect = DropEffect::None;
                n->HandleDragQuery(query);
                if (query.Effect != DropEffect::None)
                {
                    target = n;
                    break;
                }
                if (query.Refused)
                    break;
            }
            SetDropTarget(target, query, at);
        }

        // The node a drag rests on: another one starts the clock again.
        void NoteDragRest(Node* hit)
        {
            if (hit == m_dragRestNode)
                return;
            m_dragRestNode = hit;
            m_dragRest = 0.0f;
            m_dragRestOpened = false;
        }

        // A point in the root's space (what hit-tests and places the preview), from the device
        // pixels input arrives in.
        [[nodiscard]] core::Float2 RootPoint(core::Float2 at) const
        {
            return m_root != nullptr ? m_root->ConvertToNodeSpace(at) : at;
        }
        // The drag's pointer in the root it is over (this root's when outside every root).
        [[nodiscard]] core::Float2 DragRootPoint() const
        {
            if (m_dragOver != nullptr && m_dragOver != this && !m_dragOutside)
                return m_dragOver->RootPoint(m_dragOverAt);
            return RootPoint(m_mousePos);
        }

        struct PopupEntry
        {
            core::RefPtr<Node> Popup;
            PopupOptions Options;
            mutable core::Float2 Size{0.0f, 0.0f}; // its own size, which placement shrinks from
            Array<Node::ElementRef> SavedFocus;  // the focus it took, then the nodes holding it
            NavScope ScopeBefore = NavScope::None;
            // Where it goes back to when it closes (ReturnHome): weak, since it may be this root
            // itself, which owns this dispatcher (a strong reference would keep the root alive).
            Node::ElementRef Home{};
            usize HomeIndex = 0;
        };
        Array<PopupEntry> m_popups; // the top layer, bottom first
        bool m_swallowing = false;  // a press that closed a popup: its release is consumed too
        // Tooltips: the node whose text shows or waits, the content shown, the clock.
        Node* m_tipProvider = nullptr;
        core::RefPtr<Node> m_tip;
        core::String m_tipText; // what the shown one says, to see its provider's change
        f32 m_tipTimer = 0.0f;
        f32 m_tipDelay = 0.5f;
        f32 m_tipHiddenAt = -1000.0f;
        bool m_tipSuppressed = false;
        static constexpr f32 kTooltipWarm = 0.6f; // seconds after one hid that the next shows at once
        static constexpr f32 kTooltipGrace = 0.3f; // seconds an interactive one waits for the pointer
        bool m_tipInteractive = false;  // the one shown takes the pointer (E16)
        f32 m_tipGrace = 0.0f;
        bool m_keyboardTooltips = true;
        bool m_keysMovedFocus = false;  // keys moved the focus since the pointer was last used
        // A long press: armed by a finger's press, disarmed by moving or lifting it.
        bool m_longPressArmed = false;
        f32 m_pressHeld = 0.0f;
        core::Float2 m_pressAt{0.0f, 0.0f};
        static constexpr f32 kLongPress = 0.5f;
        // === Tooltips and long presses ===
        [[nodiscard]] static Node* TooltipProvider(Node* node)
        {
            for (Node* n = node; n != nullptr; n = n->GetParent())
                if (n->GetTooltipText().Size() != 0)
                    return n;
            return nullptr;
        }
        void UpdateTooltip(f32 seconds)
        {
            if (m_dragActive)
                return; // no tooltips while dragging (the hint says what a drop would do)
            Node* provider = m_touchActive ? m_tipProvider : TooltipProvider(m_overNode);
            // While the keys move the focus, the focused control's (E16); the pointer's first.
            bool fromFocus = false;
            if (provider == nullptr && !m_touchActive && m_keyboardTooltips && m_inputKind != InputKind::Pointer && m_keysMovedFocus && m_focusNode != nullptr)
            {
                provider = TooltipProvider(m_focusNode);
                fromFocus = provider != nullptr;
            }
            // An interactive tooltip holds while the pointer is in it, and a moment after the pointer
            // leaves both it and its control, so the pointer can cross the gap into it (E16).
            if (Node* shown = GetShownTooltip(); shown != nullptr && m_tipInteractive && provider != m_tipProvider)
            {
                if (m_overNode != nullptr && IsInSubtree(m_overNode, shown))
                {
                    m_tipGrace = 0.0f;
                    return;
                }
                m_tipGrace += seconds;
                if (m_tipGrace < kTooltipGrace)
                    return;
            }
            m_tipGrace = 0.0f;
            if (provider != m_tipProvider)
            {
                HideTooltip();
                m_tipProvider = provider;
                m_tipTimer = 0.0f;
                m_tipSuppressed = false;
            }
            // The same provider with other text (a code editor's word under the pointer): hidden,
            // so the new text shows at once, warm, by the pointer where it is now.
            if (provider != nullptr && !m_tipInteractive && GetShownTooltip() != nullptr && provider->GetTooltipText() != m_tipText.AsView())
                HideTooltip();
            if (provider == nullptr || m_tipSuppressed || m_touchActive || GetShownTooltip() != nullptr)
                return;
            m_tipTimer += seconds;
            const bool warm = m_time - m_tipHiddenAt <= kTooltipWarm; // one just hid: the next at once
            if (m_tipTimer >= (warm ? 0.0f : m_tipDelay))
                ShowTooltip(*provider, m_mousePos, fromFocus);
        }
        void ShowTooltip(Node& provider, core::Float2 at, bool belowProvider = false)
        {
            if (m_root == nullptr)
                return;
            core::RefPtr<Node> content = provider.CreateTooltipContent(provider.GetTooltipText());
            if (!content)
                return;
            m_tipText = core::String(provider.GetTooltipText());
            // The root holds it, but it reads and opens as its provider runs.
            const bool rightToLeft = provider.IsRightToLeft();
            content->SetLayoutDirection(rightToLeft ? Node::LayoutDirection::RightToLeft : Node::LayoutDirection::LeftToRight);
            PopupOptions options;
            // Interactive (E16): a popup the pointer may enter and press in, which a press outside
            // or Escape closes, rather than a hint any press or key hides.
            m_tipInteractive = provider.IsTooltipInteractive();
            options.Kind = m_tipInteractive ? PopupKind::Auto : PopupKind::Hint;
            if (m_tipInteractive)
                content->SetHitTestVisible(true);
            options.HasAnchorRect = true;
            if (belowProvider)
            {
                // The focused control's: below it, where the pointer is not.
                const core::Float2 p0 = provider.ConvertToRootSpace(core::Float2{0.0f, 0.0f});
                const core::Float2 p1 = provider.ConvertToRootSpace(provider.GetSize());
                options.AnchorRect = Rect{core::Min(p0.x, p1.x), core::Min(p0.y, p1.y), core::Abs(p1.x - p0.x), core::Abs(p1.y - p0.y)};
                options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 4.0f, false};
            }
            else
            {
                const core::Float2 p = m_root->ConvertToNodeSpace(at);
                // Clear of the pointer toward the inline end.
                options.AnchorRect = Rect{rightToLeft ? p.x - 12.0f : p.x + 12.0f, p.y, 0.0f, 0.0f};
                options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 18.0f, false};
            }
            options.FitContent = true; // as its text measures, once its sheet styles it
            options.OnClosed = [this](PopupCloseReason reason)
            {
                m_tipHiddenAt = m_time;
                if (reason != PopupCloseReason::Code)
                    m_tipSuppressed = true; // a press or a key: not again until the pointer moves on
            };
            HideTooltip();
            m_tip = core::Move(content);
            m_tipProvider = &provider;
            OpenPopup(*m_root, *m_tip, core::Move(options));
        }
        void HideTooltip()
        {
            if (m_tip && IsPopupOpen(*m_tip))
                (void)ClosePopup(*m_tip, PopupCloseReason::Code);
        }
        // A finger held still: a context menu at the pressed node; none taken, its tooltip.
        void LongPress()
        {
            m_longPressArmed = false;
            const core::RefPtr<Node> target{m_downNode};
            if (!target || !target->IsTreeEnabled())
                return;
            // Over a drag source, a finger held still arms its drag (a finger's move pans a
            // scroller first): the next move past the threshold drags, and no context menu opens.
            if (HasDragSource(target.Get()))
            {
                m_touchDragArmed = true;
                return;
            }
            MouseEvent event(EventType::ContextMenu, target.Get(), m_pressAt);
            event.Pointer = PointerType::Touch;
            event.PointerId = m_touchFinger;
            const bool taken = target->RouteEvent(event);
            CancelPointer(); // no release or click follows the long press
            if (!taken)
                if (Node* provider = TooltipProvider(target.Get()))
                    ShowTooltip(*provider, m_pressAt);
        }

        // === The top layer's own ===
        [[nodiscard]] i32 FindPopup(const Node& popup) const
        {
            for (usize i = 0; i < m_popups.Size(); ++i)
                if (m_popups[i].Popup.Get() == &popup)
                    return static_cast<i32>(i);
            return -1;
        }
        // The topmost auto popup's index (a hint skipped, none past a manual one), or -1.
        [[nodiscard]] i32 TopAutoPopup() const
        {
            for (usize i = m_popups.Size(); i-- > 0;)
            {
                if (m_popups[i].Options.Kind == PopupKind::Hint)
                    continue;
                return m_popups[i].Options.Kind == PopupKind::Auto ? static_cast<i32>(i) : -1;
            }
            return -1;
        }
        // The topmost modal popup's index, or -1.
        [[nodiscard]] i32 TopModal() const
        {
            for (usize i = m_popups.Size(); i-- > 0;)
                if (m_popups[i].Options.Modal)
                    return static_cast<i32>(i);
            return -1;
        }
        // Whether `node` takes input: anything while no modal is open; else what is in the topmost
        // modal popup or in a popup above it. Never what is leaving or inert (K0, K4).
        [[nodiscard]] bool IsLive(const Node* node) const
        {
            if (node != nullptr && node->IsTreeInert())
                return false;
            const i32 modal = TopModal();
            if (modal < 0 || node == nullptr)
                return true;
            for (usize i = static_cast<usize>(modal); i < m_popups.Size(); ++i)
                if (IsInSubtree(node, m_popups[i].Popup.Get()))
                    return true;
            return false;
        }
        // Where focus moves and Tab and the arrows stay: the topmost popup taking focus, else the root.
        [[nodiscard]] Node* FocusScopeRoot() const
        {
            for (usize i = m_popups.Size(); i-- > 0;)
                if ((m_popups[i].Options.TakesFocus || m_popups[i].Options.Modal) && m_popups[i].Options.Kind != PopupKind::Hint)
                    return m_popups[i].Popup.Get();
            return m_root;
        }
        // Closes the auto popups above the one `hit` is in (all of them when it is in none), not
        // past a modal one. True when the press is to be consumed: it closed some and lands in no
        // popup that stays (a press in a parent menu closing its submenu goes on to the parent).
        bool DismissOutside(Node* hit)
        {
            i32 inside = -1;
            for (usize i = m_popups.Size(); i-- > 0;)
                if (IsInSubtree(hit, m_popups[i].Popup.Get()))
                {
                    inside = static_cast<i32>(i);
                    break;
                }
            bool closed = false;
            for (usize i = m_popups.Size(); i-- > 0 && static_cast<i32>(i) > inside;)
            {
                if (i >= m_popups.Size())
                    continue; // closed with the one holding it
                const PopupOptions& o = m_popups[i].Options;
                if (o.Modal && o.Kind != PopupKind::Auto)
                    break;
                if (o.Kind != PopupKind::Auto)
                    continue;
                ClosePopupAt(i, PopupCloseReason::OutsidePress);
                closed = true;
            }
            return closed && inside < 0;
        }
        void ClosePopupsOfKind(PopupKind kind, PopupCloseReason reason)
        {
            for (usize i = m_popups.Size(); i-- > 0;)
                if (i < m_popups.Size() && m_popups[i].Options.Kind == kind)
                    ClosePopupAt(i, reason);
        }
        // Closes the popup at `index`: the popups it holds first, then it (told, out of the top
        // layer, out of the tree), focus given back while it was inside.
        void ClosePopupAt(usize index, PopupCloseReason reason)
        {
            Node* const closing = m_popups[index].Popup.Get();
            for (usize i = m_popups.Size(); i-- > index + 1;)
                if (i < m_popups.Size() && IsInSubtree(m_popups[i].Popup.Get(), closing))
                    ClosePopupAt(i, reason);
            const i32 at = FindPopup(*closing);
            if (at < 0)
                return; // closed meanwhile (a handler closed it)
            const core::RefPtr<Node> popup = m_popups[static_cast<usize>(at)].Popup;
            ToggleEvent closed(popup.Get(), false, reason);
            (void)popup->RouteEvent(closed);
            const i32 still = FindPopup(*popup);
            if (still < 0)
                return;
            PopupEntry entry = core::Move(m_popups[static_cast<usize>(still)]);
            m_popups.RemoveAt(static_cast<usize>(still));
            const bool focusInside = m_focusNode == nullptr || IsInSubtree(m_focusNode, popup.Get());
            Demote(*popup, entry);
            popup->RemoveFromParent(); // a closed popup leaves the tree; its owner keeps it
            // Or it goes back where it stood (ReturnHome), while that is still there.
            if (Node* home = entry.Home.table != nullptr ? entry.Home.table->Resolve(entry.Home.slot, entry.Home.generation) : nullptr)
                (void)home->AddChildAt(popup.Get(), core::Min(entry.HomeIndex, home->ChildCount()));
            if (focusInside && !entry.SavedFocus.IsEmpty())
                RestoreFocus(entry, nullptr);
            if (entry.Options.OnClosed)
                entry.Options.OnClosed(reason);
        }
        // A popup leaving with a subtree: out of the stack, told, focus given back when it can be.
        void DropPopupAt(usize index, PopupCloseReason reason, const Node* leaving)
        {
            PopupEntry entry = core::Move(m_popups[index]);
            m_popups.RemoveAt(index);
            const bool focusInside = m_focusNode == nullptr || IsInSubtree(m_focusNode, entry.Popup.Get());
            Demote(*entry.Popup, entry);
            if (focusInside && !entry.SavedFocus.IsEmpty())
                RestoreFocus(entry, leaving);
            if (entry.Options.OnClosed)
                entry.Options.OnClosed(reason);
        }
        static void Demote(Node& popup, const PopupEntry& entry)
        {
            popup.SetInTopLayer(false);
            popup.SetRouteStop(false);
            if (!entry.SavedFocus.IsEmpty() || entry.Options.TakesFocus || entry.Options.Modal)
                popup.SetNavScope(entry.ScopeBefore);
        }
        // Focus back to what the popup took it from, else the nearest holder of that still here,
        // enabled and focusable; none: no focus.
        void RestoreFocus(const PopupEntry& entry, const Node* leaving)
        {
            for (const Node::ElementRef& ref : entry.SavedFocus)
            {
                Node* n = ref.table != nullptr ? ref.table->Resolve(ref.slot, ref.generation) : nullptr;
                if (n == nullptr || n->GetRootNode() != m_root || (leaving != nullptr && IsInSubtree(n, leaving)))
                    continue;
                if (n->IsTabFocusable() && n->IsTreeEnabled() && n->IsTreeVisible() && IsLive(n))
                {
                    SetFocusNode(n);
                    return;
                }
            }
            SetFocusNode(nullptr);
        }

        // The outermost focus group holding `node` below `within` (null when none).
        [[nodiscard]] static Node* OutermostFocusGroup(Node* node, Node* within)
        {
            Node* group = nullptr;
            for (Node* n = node != nullptr ? node->GetParent() : nullptr; n != nullptr && n != within; n = n->GetParent())
                if (n->IsFocusGroup())
                    group = n;
            return group;
        }

        // Gather tab-focusable nodes under `node` in pre-order (skipping hidden subtrees, those
        // out of the layout too, and disabled nodes).
        static void CollectTabStops(Node* node, core::Array<Node*>& out)
        {
            if (node == nullptr || !node->IsVisible() || !node->IsDisplayed())
                return;
            if (node->IsTabFocusable() && node->IsTreeEnabled())
                out.PushBack(node);
            for (usize i = 0; i < node->ChildCount(); ++i)
                CollectTabStops(node->GetChildAt(i), out);
        }

        bool MoveTabFocus(i32 direction)
        {
            // nav-next / nav-prev first (G7).
            if (m_focusNode != nullptr)
            {
                Node* root = FocusScopeRoot();
                bool stop = false;
                Node* overridden = root != nullptr ? FollowOverride(*root, *m_focusNode,
                                                                    direction > 0 ? Node::NavOverrideNext : Node::NavOverridePrevious,
                                                                    stop)
                                                   : nullptr;
                if (overridden != nullptr)
                {
                    SetFocusNode(overridden);
                    return true;
                }
                if (stop)
                    return false;
            }
            const core::Array<Node*> stops = TabStops();
            const usize count = stops.Size();
            if (count == 0)
                return false;

            // Find the current focus among the stops.
            usize current = count; // sentinel: "not in the list"
            for (usize i = 0; i < count; ++i)
                if (stops[i] == m_focusNode)
                {
                    current = i;
                    break;
                }

            usize next;
            if (current == count)
                next = (direction > 0) ? 0 : count - 1; // nothing focused -> first / last
            else
                next = (direction > 0) ? ((current + 1) % count) : ((current + count - 1) % count);

            SetFocusNode(stops[next]);
            return true;
        }

        Node* m_root;                      // non-owning (the SceneRoot owns this dispatcher)
        core::Array<Finger> m_fingers;     // every finger down (the first, when active, is the pointer)
        // The gesture in progress (E17c): its node, its two fingers, and its totals so far.
        bool m_gesturing = false;
        core::RefPtr<Node> m_gestureTarget;
        u64 m_gestureIds[2]{};
        PointerType m_gesturePointer = PointerType::Touch; // two fingers, or a trackpad's pinch
        static constexpr u64 kNoFinger = ~u64{0};
        f32 m_gestureSpan0 = 1.0f;
        f32 m_gestureAngle = 0.0f; // the fingers' line, as last seen
        core::Float2 m_gestureFocus0{0.0f, 0.0f};
        f32 m_gestureScale = 1.0f;
        f32 m_gestureRotation = 0.0f;
        core::Float2 m_gestureTranslation{0.0f, 0.0f};
        IClipboard* m_clipboard = nullptr; // non-owning system-clipboard adapter (optional)
        Node* m_overNode = nullptr;        // non-owning: the deepest node of the hover path
        NavTrace m_lastNavigation;         // what the last directional move weighed
        Array<Node*> m_hoverPath;          // non-owning, root first: every node under the pointer
        Array<Node*> m_pressPath;          // non-owning: the pressed node and the nodes holding it
        Node* m_captureNode = nullptr;     // non-owning: explicit pointer capture (CapturePointer)
        f32 m_time = 0.0f;                 // seconds, advanced by Tick (click counting)
        f32 m_lastPressTime = -1000.0f;
        core::Float2 m_lastPressAt{0.0f, 0.0f};
        MouseButton m_lastPressButton = MouseButton::Left;
        u32 m_clickCount = 0;
        bool m_touchActive = false; // the first finger is down (it drives the pointer)
        u64 m_touchFinger = 0;
        Node* m_downNode = nullptr;        // non-owning
        struct PanSample
        {
            f32 Time;
            core::Float2 Position;
        };
        static constexpr usize kPanSamples = 8;
        PanSample m_panSamples[kPanSamples]{};
        usize m_panSampleCount = 0;
        core::Float2 m_scrollStick{0.0f, 0.0f}; // a pad's right stick (ScrollByStick)
        bool m_panning = false;            // the finger pans m_panScroller
        Node* m_panScroller = nullptr;     // non-owning (cleared when its subtree leaves)
        core::Float2 m_panLast{0.0f, 0.0f}; // where the finger was at the last pan step
        bool m_clickSuppressed = false;    // the press activated already (SuppressClick)
        Node* m_focusNode = nullptr;       // non-owning
        bool m_dragActive = false;                   // drag-and-drop in progress
        bool m_dragTried = true;                     // this press offered its drag already
        bool m_touchDragArmed = false;               // a finger held long enough over a source
        bool m_dragFromKeyboard = false;
        f32 m_dragThreshold = 6.0f;
        u32 m_dragModifiers = 0;
        DropEffect m_dropEffect = DropEffect::None;
        i32 m_dropPlace = 0;
        core::String m_dropReason;
        bool m_dropRefused = false;
        core::Float2 m_grabOffset{0.0f, 0.0f};
        core::RefPtr<DragLayer> m_dragLayer;
        core::RefPtr<Node> m_dragPreview;
        core::Function<void(core::Float2)> m_dragFollow; // a source that shows itself where the drag is
        core::RefPtr<Node> m_dropHint;
        core::Function<bool(const core::Array<core::String>&, core::Float2)> m_onFileDrop;
        f32 m_dragScrollBand = 24.0f;
        f32 m_dragScrollSpeed = 900.0f;
        f32 m_dragHoverOpenDelay = 0.6f;
        Node* m_dragRestNode = nullptr; // non-owning: compared, never followed
        IRootPlaces* m_rootPlaces = nullptr;   // the GUI's (its host's); not owned
        EventDispatcher* m_dragOver = nullptr; // the root's a drag is over (this, or another root's)
        core::Float2 m_dragOverAt{};           // the pointer in that root
        bool m_dragOutside = false;            // over no root
        bool m_dragScreenKnown = false;        // where on the screen is known (a host placed the roots)
        core::Float2 m_dragScreen{};
        EventDispatcher* m_dragLayerIn = nullptr; // where the drag's layer is a popup
        f32 m_dragRest = 0.0f;
        bool m_dragRestOpened = false;
        Node* m_dragSource = nullptr;                // non-owning
        Node* m_dropTarget = nullptr;                // non-owning current target
        DragPayload m_dragPayload;
        core::Float2 m_mousePos{0.0f, 0.0f};
        Observable m_focusChanged;   // told when focus moves
        core::Function<bool(const Keystroke&)> m_keystrokes; // the keymap (SceneRoot)
        bool m_altHeld = false;         // access keys show while it is
        bool m_mnemonicsAlways = false; // access keys always show
        void SetAltHeld(bool held)
        {
            if (held == m_altHeld)
                return;
            const bool was = AreMnemonicsShown();
            m_altHeld = held;
            if (was != AreMnemonicsShown())
                RedrawMnemonics();
        }
        // What draws an access key draws again (it and its parts), in the tree and its popups.
        void RedrawMnemonics()
        {
            const auto visit = [](auto& self, Node* node, bool marked) -> void
            {
                if (node == nullptr)
                    return;
                const bool here = marked || node->GetMnemonic() != 0;
                if (here)
                    node->Invalidate();
                for (usize i = 0; i < node->ChildCount(); ++i)
                    self(self, node->GetChildAt(i), here);
            };
            visit(visit, m_root, false);
            for (const PopupEntry& entry : m_popups)
                visit(visit, entry.Popup.Get(), false);
        }
        // The character a key types for an access key: its letter (lower case) or digit, else 0.
        [[nodiscard]] static char32_t MnemonicOfKey(KeyCode key) noexcept
        {
            for (usize i = 0; i < 26; ++i)
                if (kLetterKeys[i] == key)
                    return static_cast<char32_t>(U'a' + i);
            if (key >= KeyCode::Num0 && key <= KeyCode::Num9)
                return static_cast<char32_t>(U'0' + (static_cast<u32>(key) - static_cast<u32>(KeyCode::Num0)));
            return 0;
        }
        // The first shown, enabled widget marked `key` in the open menu (else the focus scope)
        // takes focus where it can and acts. False when none is marked so.
        bool ActivateMnemonic(char32_t key)
        {
            if (key == 0)
                return false;
            Node* within = FocusScopeRoot();
            for (usize i = m_popups.Size(); i-- > 0;)
                if (m_popups[i].Options.Kind != PopupKind::Hint) // a tooltip is never where keys go
                {
                    within = m_popups[i].Popup.Get();
                    break;
                }
            Node* found = nullptr;
            const auto find = [&](auto& self, Node* node) -> void
            {
                if (node == nullptr || found != nullptr || !node->IsVisible() || !node->IsDisplayed() || !node->IsTreeEnabled())
                    return;
                if (node->GetMnemonic() == key)
                {
                    found = node;
                    return;
                }
                for (usize i = 0; i < node->ChildCount(); ++i)
                    self(self, node->GetChildAt(i));
            };
            find(find, within);
            if (found == nullptr)
                return false;
            UseKeyboard();
            if (found->IsTabFocusable())
                SetFocusNode(found);
            (void)found->HandleActivate();
            return true;
        }
        // CaptureNextKey's wait (E12).
        struct KeyCapture
        {
            core::Function<void(const Keystroke&)> OnKey;
            core::Function<void()> OnCancel;
            bool TakeEscape = false;
            bool Waiting = false;
            bool DropText = false;    // the key it took types text next: dropped
            u32 PendingModifier = 0;  // a modifier key down, taken alone if released first
        };
        KeyCapture m_capture;
        void TakeCapturedKey(const Keystroke& stroke)
        {
            m_capture.Waiting = false;
            core::Function<void(const Keystroke&)> onKey = core::Move(m_capture.OnKey);
            m_capture.OnCancel = {};
            if (onKey)
                onKey(stroke);
        }
        core::Function<void()> m_onInput;                    // this root took input (GUIContext)
        void NoteInput()
        {
            if (m_onInput)
                m_onInput();
        }
        // What drives the GUI (K2b): the keys until the pointer is used, so a menu opening with
        // focus on its first button shows it (as games do).
        InputKind m_inputKind = InputKind::Keyboard;
        Observable m_inputKindChanged;
        bool m_holding = false;      // a direction held (PressDirection)
        NavDirection m_heldDirection = NavDirection::Down;
        f32 m_heldFor = 0.0f;
        f32 m_nextRepeatAt = 0.0f;

        // A key or d-pad move (a navigation): the focus ring shows; the pointer's kind gives way
        // to the keys'.
        void UseKeyboard()
        {
            if (m_inputKind == InputKind::Pointer)
                ApplyInputKind(InputKind::Keyboard);
            m_keysMovedFocus = true;
            if (m_focusNode != nullptr)
                m_focusNode->SetFocusVisible(true);
        }
        void ApplyInputKind(InputKind kind)
        {
            if (kind == m_inputKind)
                return;
            m_inputKind = kind;
            if (kind == InputKind::Pointer)
                m_keysMovedFocus = false;
            if (m_focusNode != nullptr)
                m_focusNode->SetFocusVisible(kind != InputKind::Pointer);
            m_inputKindChanged.Notify();
            if (m_root != nullptr)
            {
                m_root->Invalidate(); // the cursor, and what a sheet shows for it
                m_root->SendEvent(Event(EventType::InputKindChanged, m_root));
            }
        }
    };
}
