// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :window partition
//
// Window: a movable panel with a title bar and a content area. Modeled on eepp's UIWindow (role
// only). Dragging the title bar moves the window (or, handed over, starts a drag source's drag);
// with `resizable`, dragging the bottom-right grip resizes it (clamped to a minimum); either
// reported once the press lets go; with `closable`, a close button in the title bar
// closes it. Pressing anywhere on the title raises the window to the front. It arranges its
// parts itself (title bar, content, grip), its look the theme's (window::title, ::grip,
// `window titlebar > close`). Movement uses incremental world-space cursor deltas via an internal DragHandle
// that follows the Slider/ScrollBar capture discipline (own m_dragging flag, so a drag that
// leaves the handle keeps tracking). Nested parent transforms are not accounted for (deltas
// are treated as parent-local) - fine for top-level windows under an untransformed root.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:window;

import foundation.core;  // RefPtr, MakeRef, Function, Move, Max, Float2
import foundation.fonts; // CachedFont
import :rect;
import :event;
import :drawable;
import :node;
import :label;
import :ui_widget;
import :event_dispatcher;
import :button_base;
import :draw_context;
import :layout_style;
import :commands; // CommandEvent
import :keymap;   // kBackCommand
import foundation.vg; // PathBuilder, StrokeStyle (the close cross, the grip's lines)

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    // A widget that reports incremental world-space cursor deltas while dragged. Internal to
    // Window (title bar + resize grip), but generally reusable.
    class DragHandle : public UIWidget
    {
        RTTI_OBJECT(DragHandle, UIWidget)
    public:
        core::Function<void(core::Float2)> OnDrag; // incremental cursor delta
        core::Function<void()> OnPressed;
        core::Function<void()> OnReleased; // the press that dragged it let go (after OnDrag moved something)
        /// Whether its press drags it (the default); off, its press is a drag source's (its own,
        /// SetDragSource, or an ancestor's): what a floating dock window's title bar does (D5).
        void SetDragsItself(bool drags) noexcept { m_dragsItself = drags; }
        [[nodiscard]] bool DragsItself() const noexcept { return m_dragsItself; }

    protected:
        // A press moves or resizes the window (E7): a drag from what holds it is not offered.
        [[nodiscard]] bool OwnsPressDrag(core::Float2) const override { return m_dragsItself; }
        void OnMouseDown(const MouseEvent& event) override
        {
            event.Handled = true;
            if (OnPressed)
                OnPressed(); // raise on any button
            if (event.Button != MouseButton::Left || !m_dragsItself)
                return; // but only the left button drags
            m_dragging = true;
            m_moved = false;
            m_last = event.Position;
        }
        void OnMouseMove(const MouseEvent& event) override
        {
            if (!m_dragging)
                return;
            const core::Float2 delta{event.Position.x - m_last.x, event.Position.y - m_last.y};
            m_last = event.Position;
            m_moved = m_moved || delta.x != 0.0f || delta.y != 0.0f;
            if (OnDrag)
                OnDrag(delta);
        }
        void OnMouseUp(const MouseEvent& event) override
        {
            (void)event;
            LetGo();
        }
        void OnPointerCancel(const MouseEvent&) override { LetGo(); }

    private:
        void LetGo()
        {
            const bool moved = m_dragging && m_moved;
            m_dragging = false;
            m_moved = false;
            if (moved && OnReleased)
                OnReleased();
        }
        bool m_dragging = false;
        bool m_moved = false;
        bool m_dragsItself = true;
        core::Float2 m_last{0.0f, 0.0f};
    };

    // A window's close button (`window titlebar > close`): a cross in its text colour.
    class WindowCloseButton : public ButtonBase
    {
        RTTI_OBJECT(WindowCloseButton, ButtonBase)
    public:
        WindowCloseButton()
        {
            SetTag(core::StringView(u8"close"));
            SetTabFocusable(false); // Escape closes from the keys
        }
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override { return core::Float2{10.0f, 10.0f}; }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            ButtonBase::OnDraw(ctx, localBounds);
            const Rect box = GetContentBounds();
            const f32 r = core::Min(box.width, box.height) * 0.5f;
            const f32 cx = box.x + box.width * 0.5f;
            const f32 cy = box.y + box.height * 0.5f;
            vg::PathBuilder cross;
            cross.MoveTo(cx - r, cy - r);
            cross.LineTo(cx + r, cy + r);
            cross.MoveTo(cx + r, cy - r);
            cross.LineTo(cx - r, cy + r);
            ctx.VG().StrokePath(cross.ToPath(), GetTextColor(), vg::StrokeStyle(1.5f, vg::VGLineCap::Round, vg::VGLineJoin::Round));
        }
        // Its press is its own: the title bar under it does not start a move.
        void OnMouseDown(const MouseEvent& event) override
        {
            if (event.Button == MouseButton::Left)
                event.Handled = true;
        }
    };

    // A window's resize grip: diagonal lines in the corner, in window::grip's colour.
    class WindowGrip : public DragHandle
    {
        RTTI_OBJECT(WindowGrip, DragHandle)
    public:
        WindowGrip() { SetTag(core::StringView(u8"grip")); }
        void SetLineColor(Color color)
        {
            m_color = color;
            Invalidate();
        }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            DragHandle::OnDraw(ctx, localBounds);
            // Its lines in the corner it sits in: bottom right, bottom left in right to left.
            const Rect b = GetLocalBounds();
            const bool rtl = IsRightToLeft();
            vg::PathBuilder lines;
            for (f32 k = 4.0f; k <= 12.0f; k += 4.0f)
            {
                lines.MoveTo(MirroredX(b.x + b.width - 3.0f, b, rtl), b.y + b.height - 3.0f - k);
                lines.LineTo(MirroredX(b.x + b.width - 3.0f - k, b, rtl), b.y + b.height - 3.0f);
            }
            ctx.VG().StrokePath(lines.ToPath(), m_color, vg::StrokeStyle(1.2f, vg::VGLineCap::Round, vg::VGLineJoin::Round));
        }

    private:
        Color m_color{0.55f, 0.59f, 0.66f, 1.0f};
    };

    class Window : public UIWidget
    {
        RTTI_OBJECT(Window, UIWidget)
    public:
        Window()
        {
            SetTag(core::StringView(u8"window"));
            SetClipChildren(true);
            SetBox(FilledBox(m_bodyColor)); // its own box, which a sheet's (rounded, bordered, shadowed) replaces

            m_titleBar = core::MakeRef<DragHandle>(MemoryAllocator());
            m_titleBar->SetTag(core::StringView(u8"titlebar"));
            {
                StyleWriteScope barDefaults(*m_titleBar);
                m_titleBar->EditLayoutStyle([](LayoutStyle& st)
                {
                    st.Direction = FlexDirection::Row;
                    st.AlignItems = Align::Center;
                    st.ColumnGap = 6.0f;
                });
                // The same at both ends: right to left, the bar is the mirror of left to right.
                m_titleBar->SetPadding(Thickness{8.0f, 0.0f, 8.0f, 0.0f});
            }
            Window* self = this;
            m_titleBar->OnDrag = [self](core::Float2 d)
            {
                self->SetPosition(
                    core::Float2{self->GetPosition().x + d.x, self->GetPosition().y + d.y});
            };
            m_titleBar->OnPressed = [self]() { self->ToFront(); };
            m_titleBar->OnReleased = [self]() { self->UserArranged(); };
            AddChild(m_titleBar.Get());

            m_title = core::MakeRef<Label>(MemoryAllocator());
            StyleWriteScope defaults(*m_title); // its own values, which a sheet returns to
            m_title->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            m_title->SetHitTestVisible(false); // clicks fall through to the draggable title bar
            m_title->EditLayoutStyle([](LayoutStyle& st) { st.Grow = 1.0f; });
            m_titleBar->AddChild(m_title.Get());
            m_closeButton = core::MakeRef<WindowCloseButton>(MemoryAllocator());
            m_closeButton->SetOnClick([self]() { self->RequestClose(); });
            m_titleBar->AddChild(m_closeButton.Get());

            m_contentHost = core::MakeRef<UIWidget>(MemoryAllocator());
            m_contentHost->SetClipChildren(true);
            AddChild(m_contentHost.Get());

            m_resizeGrip = core::MakeRef<WindowGrip>(MemoryAllocator());
            m_resizeGrip->OnDrag = [self](core::Float2 d) { self->ResizeBy(d); };
            m_resizeGrip->OnPressed = [self]() { self->ToFront(); };
            m_resizeGrip->OnReleased = [self]() { self->UserArranged(); };
            m_resizeGrip->SetCursor(Cursor::NwseResize);
            AddChild(m_resizeGrip.Get());
            RefreshPartNodes();
        }

        // The area for window content (add your widgets here).
        [[nodiscard]] Node* GetContent() const noexcept { return m_contentHost.Get(); }
        [[nodiscard]] Node* GetChildHost() override { return m_contentHost.Get(); } // markup's children are its content

        void SetTitle(core::StringView text) { m_title->SetText(text); }
        [[nodiscard]] core::StringView GetTitle() const { return m_title->GetText(); }
        void SetMinSize(core::Float2 size) { m_minSize = size; }
        /// Its close button shows (a click on it, like Escape on a dialog, closes it).
        void SetClosable(bool closable)
        {
            m_closable = closable;
            m_closeButton->SetDisplayed(closable);
        }
        [[nodiscard]] bool IsClosable() const noexcept { return m_closable; }
        /// Its grip shows and resizes it.
        void SetResizable(bool resizable)
        {
            m_resizable = resizable;
            m_resizeGrip->SetDisplayed(resizable);
        }
        [[nodiscard]] bool IsResizable() const noexcept { return m_resizable; }
        /// Asked to close (its close button, or `back` while it is open modal): a window closes; a
        /// dialog answers as its cancel does.
        virtual void RequestClose() { Close(); }
        /// Whether `back` (Escape, the pad's East) asks it to close while it is open modal (K1):
        /// when it may be closed.
        [[nodiscard]] virtual bool AnswersBack() const { return m_closable; }
        [[nodiscard]] f32 GetTitleBarHeight() const noexcept { return m_titleBarHeight; }
        void SetTitleBarHeight(f32 height)
        {
            m_titleBarHeight = core::Max(1.0f, height);
            Relayout();
        }

        void SetBodyColor(Color color)
        {
            m_bodyColor = color;
            if (!IsBoxFromStyle())
                SetBox(FilledBox(color));
        }
        void SetTitleColor(Color color)
        {
            m_titleColor = color;
            RefreshPartNodes();
        }

        // Fired when the window is closed via Close().
        void SetOnClose(core::Function<void()> callback) { m_onClose = core::Move(callback); }
        /// The user moved it by its title bar or resized it by its grip: called once the press lets
        /// go (not each move), with its place and size as they are then.
        void SetOnUserArranged(core::Function<void()> callback) { m_onUserArranged = core::Move(callback); }
        /// Its title bar (what dragging it moves the window; DragHandle::SetDragsItself hands the
        /// press to a drag source instead).
        [[nodiscard]] DragHandle* GetTitleBar() const noexcept { return m_titleBar.Get(); }

        // Show centered in `owner` as a MODAL window (E5): a manual, modal popup of `owner`, so
        // everything below it is inert (pointer, keys, bindings) until Close(), its `::backdrop`
        // part dims the root behind it, Tab stays within, focus moves to its first focusable child
        // and comes back when it closes. Popups opened inside it (a combo box's list) stack above it.
        void OpenModal(Node& owner) { OpenInternal(owner, /*modal*/ true); }

        // Show centered in `root` as a normal (non-blocking) top-level window.
        void Open(Node& root) { OpenInternal(root, /*modal*/ false); }

        // Remove the window (a modal one through the popup stack, which gives focus back), and fire
        // the close callback. A window placed in a tree as a child, never opened, closes the same
        // way: its close button works however it came to be shown.
        void Close()
        {
            if (!m_open && GetParent() == nullptr)
                return;
            EventDispatcher* dispatcher = GetEventDispatcher();
            if (m_modal && dispatcher != nullptr && dispatcher->IsPopupOpen(*this))
            {
                (void)dispatcher->ClosePopup(*this); // its OnClosed finishes
                return;
            }
            const core::RefPtr<Node> keep(this); // the tree may hold its only reference (a script's window)
            RemoveFromParent();
            Closed();
        }

        [[nodiscard]] bool IsOpen() const noexcept { return m_open; }

        // === The script surface (E16; reflected in GUIReflectionImpl.cpp) ===
        /// Opens it where it is, over what holds it (a window a script added to a page); false in none.
        bool OpenInPlace()
        {
            Node* parent = GetParent();
            if (parent == nullptr)
                return false;
            SetDisplayed(true); // one kept out of the layout until opened
            Open(*parent);
            return true;
        }
        /// Opens it as a modal window over the GUI it is in; false in none.
        bool OpenModalOver()
        {
            Node* root = GetRootNode();
            if (root == nullptr || root == this)
                return false;
            OpenModal(*root);
            return true;
        }
        [[nodiscard]] bool IsModal() const noexcept { return m_modal; }

        // Theming parts: window::title (header bar) / ::grip (resize handle).
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"title"));
            out.PushBack(core::StringView(u8"grip"));
        }
        // Its title bar and grip are nodes of their own: window::title and ::grip give them
        // their boxes, over their own colours.
        void OnPartStyleChange(core::StringView part) override
        {
            if (part == core::StringView(u8"title") || part == core::StringView(u8"grip"))
                RefreshPartNodes();
        }

    protected:
        /// It closed (a dialog written in a page goes back there).
        virtual void OnWindowClosed() {}
        void OnSizeChange() override { Relayout(); }
        // Its parts at their places: the title bar across the top, the content under it, the
        // grip in the corner.
        void OnLayout() override { Relayout(); }
        // Its title takes its font (a sheet's inheritance gives the same).
        void OnTextStyleChange() override { ShareTextStyle(*m_title, false); }

    private:
        // The title bar's and the grip's boxes: their colours with window::title's and ::grip's over them.
        void RefreshPartNodes()
        {
            const PartStyle& title = GetPartStyle(u8"title");
            const PartStyle& grip = GetPartStyle(u8"grip");
            m_titleBar->SetBox(title.Over(FilledBox(m_titleColor)), false);
            m_resizeGrip->SetLineColor(grip.HasBackground ? grip.Box.BackgroundColor : m_gripColor); // drawn as lines
            StyleWriteScope titleWrite(*m_titleBar);
            m_titleBar->SetAlpha(title.Opacity);
            StyleWriteScope gripWrite(*m_resizeGrip);
            m_resizeGrip->SetAlpha(grip.Opacity);
        }
        void OpenInternal(Node& owner, bool modal)
        {
            // Not inside itself or what it holds: the tree would loop.
            for (const Node* n = &owner; n != nullptr; n = n->GetParent())
                if (n == this)
                    return;
            if (m_open)
                return;
            EventDispatcher* dispatcher = owner.GetEventDispatcher();
            if (modal && dispatcher != nullptr)
            {
                m_modal = true;
                m_open = true;
                CenterIn(owner.GetRootNode() != nullptr ? *owner.GetRootNode() : owner); // in the root's space
                PopupOptions options;
                options.Kind = PopupKind::Manual;
                options.Modal = true;
                options.TakesFocus = true;
                Window* self = this;
                options.OnClosed = [self](PopupCloseReason) { self->Closed(); };
                // Back asks it to close, while it is open (under it is inert, so nothing else would hear it).
                if (AnswersBack())
                    m_backHandler = OnCommand(core::StringView(kBackCommand), [self](CommandEvent&) { self->RequestClose(); });
                dispatcher->OpenPopup(owner, *this, core::Move(options));
                return;
            }
            m_modal = false;
            owner.AddChild(this);
            CenterIn(owner);
            ToFront();
            m_open = true;
        }
        void UserArranged()
        {
            if (m_onUserArranged)
                m_onUserArranged();
        }
        void Closed()
        {
            m_open = false;
            m_modal = false;
            if (m_backHandler != 0)
                (void)RemoveCommandHandler(m_backHandler);
            m_backHandler = 0;
            OnWindowClosed();
            if (m_onClose)
                m_onClose();
            SendEvent(Event(EventType::Close, this)); // a script's on("close")
        }

        void CenterIn(Node& root)
        {
            const core::Float2 r = root.GetSize();
            const core::Float2 s = GetSize();
            SetPosition(core::Float2{(r.x - s.x) * 0.5f, (r.y - s.y) * 0.5f});
        }

        // From its grip's corner: in right to left the grip is at its bottom left, so the left edge
        // follows the pointer and the right stays.
        void ResizeBy(core::Float2 delta)
        {
            const core::Float2 s = GetSize();
            const bool rtl = IsRightToLeft();
            const f32 width = core::Max(m_minSize.x, s.x + (rtl ? -delta.x : delta.x));
            if (rtl && width != s.x)
                SetPosition(core::Float2{GetPosition().x + s.x - width, GetPosition().y});
            SetSize(core::Float2{width, core::Max(m_minSize.y, s.y + delta.y)});
        }

        void Relayout()
        {
            const core::Float2 s = GetSize();
            m_titleBar->Arrange(Rect{0.0f, 0.0f, s.x, m_titleBarHeight});
            m_contentHost->Arrange(Rect{0.0f, m_titleBarHeight, s.x, core::Max(0.0f, s.y - m_titleBarHeight)});
            const bool rtl = IsRightToLeft();
            m_resizeGrip->Arrange(MirroredIn(Rect{s.x - m_gripSize, s.y - m_gripSize, m_gripSize, m_gripSize},
                                             Rect{0.0f, 0.0f, s.x, s.y}, rtl));
            // Its cursor the way its corner resizes: bottom right, or bottom left right to left.
            m_resizeGrip->SetCursor(rtl ? Cursor::NeswResize : Cursor::NwseResize);
            if (GetChildIndex(m_resizeGrip.Get()) + 1 != ChildCount())
                m_resizeGrip->ToFront(); // over the content
        }

        RefPtr<DragHandle> m_titleBar;
        RefPtr<Label> m_title;
        RefPtr<WindowCloseButton> m_closeButton;
        bool m_closable = true;
        bool m_resizable = true;
        RefPtr<UIWidget> m_contentHost;
        RefPtr<WindowGrip> m_resizeGrip;
        core::Function<void()> m_onClose;
        core::Function<void()> m_onUserArranged;
        bool m_open = false;
        bool m_modal = false;
        u32 m_backHandler = 0; // its `back` handler while open modal
        core::Float2 m_minSize{120.0f, 60.0f};
        f32 m_titleBarHeight = 28.0f;
        f32 m_gripSize = 14.0f;
        Color m_bodyColor{0.16f, 0.17f, 0.21f, 1.0f};
        Color m_titleColor{0.24f, 0.28f, 0.36f, 1.0f};
        Color m_gripColor{0.40f, 0.44f, 0.52f, 1.0f};
    };

    RTTI_DEFINE_OBJECT(DragHandle, "rtti::gui")
    RTTI_DEFINE_OBJECT(WindowCloseButton, "rtti::gui")
    RTTI_DEFINE_OBJECT(WindowGrip, "rtti::gui")
}
