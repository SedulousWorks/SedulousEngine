// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :tool_bar partition
//
// The tool bar (T0 of Specs/gui-lab-evolution-3.md). Its buttons name commands (the core's
// command model, as menus and shortcuts do): a command's label, icon, checked state and
// availability reach them, so one command greys its button, its menu item and its keys at once
// (ezEngine, Lumix and Zero feed all three from one registry). A tool button shows its icon (its
// text too when asked, or when it has no icon); its tooltip is its label, the keys that run it
// here, and, while its command is disabled, why.
//
// The bar lays its items out in a row (or a column) itself, so it knows what each wants whether
// or not it shows: what does not fit goes into an overflow menu at the end, the items of lowest
// overflow priority first, then from the end (zed shrinks its bars and clips their start, which
// the survey counts against it). An item that cannot be a menu row (a field, a combo) never goes;
// a separator shows only between items that show. A spacer (any item that grows) takes what is
// left. The bar is one focus group: Tab enters it once, the arrows move along it. It shows and hides
// its items itself (visibility); an application takes one out with SetDisplayed(false).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:tool_bar;

import foundation.core;
import foundation.vg; // PathBuilder, StrokeStyle
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A tool button: an icon (and its text where asked) for a command or a click.
    class ToolButton : public Button
    {
        RTTI_OBJECT(ToolButton, Button)
    public:
        ToolButton() { SetTag(core::StringView(u8"toolbutton")); }

        /// Whether its text shows beside its icon (`shows-text`); without an icon it always does.
        void SetShowsText(bool shows)
        {
            m_showsText = shows;
            UpdateParts();
        }
        [[nodiscard]] bool ShowsText() const noexcept { return m_showsText; }
        /// Which items leave a full bar first (`overflow-priority`): the lowest, then the last.
        void SetOverflowPriority(i32 priority)
        {
            m_priority = priority;
            if (Node* parent = GetParent())
                parent->RequestLayout();
        }
        [[nodiscard]] i32 GetOverflowPriority() const noexcept { return m_priority; }

        /// What it is called: its text, else its command's label (its tooltip's first line, and
        /// its row in the overflow menu).
        [[nodiscard]] core::StringView GetLabel() const { return GetText(); }
        /// The keys that run its command where it is ("Ctrl+S"); empty with none.
        [[nodiscard]] core::StringView GetShortcut() const noexcept { return m_shortcut.AsView(); }
        /// Why its command is disabled, while it is; empty otherwise.
        [[nodiscard]] core::StringView GetDisabledReason() const noexcept { return m_reason.AsView(); }

        /// Its own tooltip where it has one; else its label, its keys and why it is disabled.
        [[nodiscard]] core::StringView GetTooltipText() const override
        {
            const core::StringView own = Button::GetTooltipText();
            if (own.Size() != 0)
                return own;
            m_tip = BuildTip(); // its label as it is now
            return m_tip.AsView();
        }

        void OnBoundCommandText(core::StringView label, core::StringView icon, core::StringView shortcut) override
        {
            Button::OnBoundCommandText(label, icon, shortcut);
            m_shortcut = core::String(shortcut);
            // Its command's icon where it has none of its own.
            if (icon.Size() != 0 && (GetIconPart() == nullptr || m_iconFromCommand))
            {
                SetIconSource(core::String(icon));
                m_iconFromCommand = true;
                UpdateParts();
            }
        }
        void OnBoundCommandState(const BoundCommandState& state) override
        {
            Button::OnBoundCommandState(state);
            m_reason = core::String(state.Reason);
        }

    protected:
        // A part came or went (its icon, its text): whether its text shows follows.
        void OnChildrenChanged() override
        {
            Button::OnChildrenChanged();
            UpdateParts();
        }

    private:
        void UpdateParts()
        {
            if (Label* text = GetTextPart())
                text->SetDisplayed(m_showsText || GetIconPart() == nullptr);
        }
        [[nodiscard]] core::String BuildTip() const
        {
            core::String tip(GetLabel());
            if (m_shortcut.Size() != 0)
            {
                tip.Append(core::StringView(u8" ("));
                tip.Append(m_shortcut.AsView());
                tip.Append(core::StringView(u8")"));
            }
            if (m_reason.Size() != 0)
            {
                tip.Append(core::StringView(u8"\n"));
                tip.Append(m_reason.AsView());
            }
            return tip;
        }

        core::String m_shortcut;
        core::String m_reason;
        mutable core::String m_tip; // what GetTooltipText last built
        i32 m_priority = 0;
        bool m_showsText = false;
        bool m_iconFromCommand = false;
    };

    /// The arrow a menu button draws at its end: a part (`arrow`), hit as its button.
    class ToolMenuArrow : public UIWidget
    {
        RTTI_OBJECT(ToolMenuArrow, UIWidget)
    public:
        ToolMenuArrow()
        {
            SetTag(core::StringView(u8"arrow"));
            SetHitTestVisible(false);
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s) { s.Shrink = 0.0f; });
        }
        /// Whether a line sets it apart (a split button's: the arrow is a button of its own).
        void SetDivided(bool divided)
        {
            m_divided = divided;
            Invalidate();
        }
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override { return core::Float2{m_divided ? 14.0f : 10.0f, 10.0f}; }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            const Color color = GetTextColor();
            const f32 cx = localBounds.x + localBounds.width * (m_divided ? 0.6f : 0.5f);
            const f32 cy = localBounds.y + localBounds.height * 0.5f;
            vg::PathBuilder arrow;
            arrow.MoveTo(cx - 3.5f, cy - 1.5f);
            arrow.LineTo(cx + 3.5f, cy - 1.5f);
            arrow.LineTo(cx, cy + 2.5f);
            arrow.Close();
            ctx.VG().FillPath(arrow.ToPath(), color);
            if (m_divided)
            {
                Color line = color;
                line.a *= 0.4f;
                const f32 x = IsRightToLeft() ? localBounds.x + localBounds.width - 1.0f : localBounds.x;
                ctx.VG().FillRect(Rect{x, localBounds.y + 2.0f, 1.0f, core::Max(0.0f, localBounds.height - 4.0f)}.ToRectangle(), line);
            }
        }

    private:
        bool m_divided = false;
    };

    /// A tool button with a menu: a drop-down (a click opens its menu) or, split, a button whose
    /// arrow opens its menu while the rest runs its command. Markup's children are its menu's.
    class ToolMenuButton : public ToolButton
    {
        RTTI_OBJECT(ToolMenuButton, ToolButton)
    public:
        ToolMenuButton()
        {
            SetTag(core::StringView(u8"toolmenubutton"));
            m_arrow = core::MakeRef<ToolMenuArrow>(MemoryAllocator());
            AddChild(m_arrow.Get());
        }

        /// Split (`split`): the arrow opens the menu and the rest runs the button's command or click.
        void SetSplit(bool split)
        {
            m_split = split;
            m_arrow->SetDivided(split);
        }
        [[nodiscard]] bool IsSplit() const noexcept { return m_split; }
        /// Its menu (made when first asked for).
        [[nodiscard]] Menu& GetMenu()
        {
            if (!m_menu)
            {
                m_menu = core::MakeRef<Menu>(MemoryAllocator());
                m_menu->SetAutoWidth(true);
            }
            return *m_menu;
        }
        [[nodiscard]] Menu* GetOpenMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }
        [[nodiscard]] Node* GetArrowPart() const noexcept { return m_arrow.Get(); }
        /// Opens its menu below `anchor` (itself, or the overflow button it went into).
        void OpenMenu(Node& anchor)
        {
            Menu& menu = GetMenu();
            ShareTextStyle(menu, false);
            menu.OpenBelow(*this, anchor);
        }
        void OpenMenu() { OpenMenu(*this); }
        [[nodiscard]] Node* GetChildHost() override { return GetMenu().GetChildHost(); }

    protected:
        void OnMouseClick(const MouseEvent& event) override
        {
            if (!m_split || OnArrow(event.Position))
            {
                event.Handled = true;
                OpenMenu();
                return;
            }
            ToolButton::OnMouseClick(event);
        }
        // Return, Space, South: a drop-down opens; a split button runs, and Down opens it.
        bool OnActivate() override
        {
            if (!m_split)
            {
                OpenMenu();
                return true;
            }
            return ToolButton::OnActivate();
        }
        void OnKeyDown(const KeyEvent& event) override
        {
            if (event.Modifiers == 0 && static_cast<KeyCode>(event.KeyCode) == KeyCode::Down)
            {
                OpenMenu();
                event.Handled = true;
                return;
            }
            ToolButton::OnKeyDown(event);
        }

    private:
        [[nodiscard]] bool OnArrow(core::Float2 world) const
        {
            const core::Float2 p = m_arrow->ConvertToNodeSpace(world);
            const core::Float2 size = m_arrow->GetSize();
            // The arrow's whole end of the button, padding and all.
            const f32 slack = 4.0f;
            return p.x >= -slack && p.x <= size.x + slack;
        }

        core::RefPtr<ToolMenuArrow> m_arrow;
        core::RefPtr<Menu> m_menu;
        bool m_split = false;
    };

    /// The button at a full bar's end listing what did not fit (`overflow`).
    class ToolBarOverflow : public Button
    {
        RTTI_OBJECT(ToolBarOverflow, Button)
    public:
        ToolBarOverflow()
        {
            SetTag(core::StringView(u8"overflow"));
            SetTabFocusable(true);
        }
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override { return core::Float2{12.0f, 12.0f}; }

    protected:
        // Two chevrons toward the bar's end (down in a column).
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            Button::OnDraw(ctx, localBounds);
            const Rect c = GetContentBounds();
            const Color color = GetTextColor();
            const f32 cx = c.x + c.width * 0.5f;
            const f32 cy = c.y + c.height * 0.5f;
            const bool column = m_vertical;
            const f32 dir = column ? 1.0f : (IsRightToLeft() ? -1.0f : 1.0f);
            vg::PathBuilder chevrons;
            for (i32 i = 0; i < 2; ++i)
            {
                const f32 o = (static_cast<f32>(i) * 4.0f - 2.0f) * dir;
                if (column)
                {
                    chevrons.MoveTo(cx - 3.5f, cy + o - 1.5f);
                    chevrons.LineTo(cx, cy + o + 1.5f);
                    chevrons.LineTo(cx + 3.5f, cy + o - 1.5f);
                }
                else
                {
                    chevrons.MoveTo(cx + o - 1.5f * dir, cy - 3.5f);
                    chevrons.LineTo(cx + o + 1.5f * dir, cy);
                    chevrons.LineTo(cx + o - 1.5f * dir, cy + 3.5f);
                }
            }
            ctx.VG().StrokePath(chevrons.ToPath(), color, vg::StrokeStyle(1.25f, vg::VGLineCap::Round, vg::VGLineJoin::Round));
        }

    private:
        friend class ToolBar;
        bool m_vertical = false;
    };

    /// A bar of tool buttons, menu buttons, separators, spacers and any other widget.
    class ToolBar : public UIWidget
    {
        RTTI_OBJECT(ToolBar, UIWidget)
    public:
        ToolBar()
        {
            SetTag(core::StringView(u8"toolbar"));
            SetFocusGroup(true);
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Row; // its separators stand up
                    s.ColumnGap = 2.0f;
                    s.RowGap = 2.0f;
                    s.AlignItems = Align::Center;
                    // Never held at its items' length: what does not fit overflows (across, its
                    // content's minimum holds).
                    s.MinWidth = LayoutLength::Px(0.0f);
                });
                SetPadding(Thickness{4.0f, 2.0f, 4.0f, 2.0f});
            }
            m_overflow = core::MakeRef<ToolBarOverflow>(MemoryAllocator());
            m_overflow->SetVisible(false);
            ToolBar* self = this;
            m_overflow->SetOnClick([self]() { self->OpenOverflow(); });
            AddChild(m_overflow.Get());
        }

        /// Its items run down (`orientation: vertical`) rather than along.
        void SetVertical(bool vertical)
        {
            m_vertical = vertical;
            m_overflow->m_vertical = vertical;
            KeepDirection();
            RequestLayout();
        }
        [[nodiscard]] bool IsVertical() const noexcept { return m_vertical; }
        void SetOrientationName(const core::String& name) { SetVertical(core::Trim(name.AsView()) == core::StringView(u8"vertical")); }
        [[nodiscard]] core::String GetOrientationName() const
        {
            return core::String(IsVertical() ? core::StringView(u8"vertical") : core::StringView(u8"horizontal"));
        }

        /// The items that did not fit, in bar order (what the overflow menu lists).
        [[nodiscard]] const core::Array<Node*>& GetOverflowed() const noexcept { return m_hidden; }
        [[nodiscard]] Node* GetOverflowButton() const noexcept { return m_overflow.Get(); }
        /// The overflow menu, while it is open.
        [[nodiscard]] Menu* GetOverflowMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }

        /// Lists what did not fit in a menu below the overflow button: a command's item for a
        /// button bound to one (its checked state too), a click's for one with a click, a menu
        /// button's opening its menu there; separators between the groups.
        void OpenOverflow()
        {
            m_menu = core::MakeRef<Menu>(MemoryAllocator());
            ShareTextStyle(*m_menu, false);
            m_menu->SetAutoWidth(true);
            bool pendingSeparator = false;
            bool any = false;
            for (Node* node : m_hidden)
            {
                if (IsSeparator(*node))
                {
                    pendingSeparator = any;
                    continue;
                }
                if (pendingSeparator)
                    m_menu->AddSeparator();
                pendingSeparator = false;
                any = true;
                AddOverflowRow(*node);
            }
            m_menu->OpenBelow(*this, *m_overflow);
        }

        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            // Along: every item that shows now (what it asks while it fits); across: the tallest.
            const bool column = IsVertical();
            const f32 gap = column ? GetLayoutStyle().RowGap : GetLayoutStyle().ColumnGap;
            f32 along = 0.0f;
            f32 across = 0.0f;
            usize count = 0;
            for (usize i = 0; i < ChildCount(); ++i)
            {
                Node* child = GetChildAt(i);
                if (!IsItem(*child))
                    continue;
                // Each as it would be with nothing in its way: a bar is never narrower across than
                // its widest item, whatever its container offers (a flex row's minimum asks).
                const core::Float2 size = Natural(*child, core::Float2{kUnbounded, kUnbounded});
                along += column ? size.y : size.x;
                across = core::Max(across, column ? size.x : size.y);
                ++count;
            }
            if (count > 1)
                along += gap * static_cast<f32>(count - 1);
            return column ? core::Float2{across, along} : core::Float2{along, across};
        }

    protected:
        // Its items, laid out by itself: what fits shows, the rest goes to the overflow menu.
        void OnLayout() override
        {
            KeepDirection();
            const Rect content = GetContentBounds();
            const bool column = IsVertical();
            const f32 room = column ? content.height : content.width;
            const f32 gap = column ? GetLayoutStyle().RowGap : GetLayoutStyle().ColumnGap;
            const core::Float2 avail{column ? content.width : kUnbounded, column ? kUnbounded : content.height};

            struct Item
            {
                Node* node;
                core::Float2 size;
                bool shown;
            };
            core::Array<Item> items(MemoryAllocator());
            for (usize i = 0; i < ChildCount(); ++i)
            {
                Node* child = GetChildAt(i);
                if (!IsItem(*child))
                    continue;
                items.PushBack(Item{child, Natural(*child, avail), true});
            }
            const auto along = [column](core::Float2 s) { return column ? s.y : s.x; };
            // What the shown items take, separators only between shown items.
            const auto used = [&](bool withOverflow)
            {
                f32 total = 0.0f;
                usize count = 0;
                for (usize i = 0; i < items.Size(); ++i)
                    if (items[i].shown && (!IsSeparator(*items[i].node) || SeparatorShows(items, i)))
                    {
                        total += along(items[i].size);
                        ++count;
                    }
                if (withOverflow)
                {
                    total += along(Natural(*m_overflow, avail));
                    ++count;
                }
                return count > 1 ? total + gap * static_cast<f32>(count - 1) : total;
            };
            // Hide the lowest priority first, the last of a priority first, until what shows fits.
            bool hiding = used(false) > room + 0.5f;
            while (hiding && used(true) > room + 0.5f)
            {
                i32 pick = -1;
                for (usize i = 0; i < items.Size(); ++i)
                {
                    if (!items[i].shown || !CanOverflow(*items[i].node))
                        continue;
                    if (pick < 0 || Priority(*items[i].node) <= Priority(*items[static_cast<usize>(pick)].node))
                        pick = static_cast<i32>(i);
                }
                if (pick < 0)
                    break; // what is left cannot go
                items[static_cast<usize>(pick)].shown = false;
            }

            // A separator shows only between shown items; one left out is a break between groups
            // in the overflow menu.
            core::Array<bool> shows(MemoryAllocator());
            for (usize i = 0; i < items.Size(); ++i)
                shows.PushBack(items[i].shown && (!IsSeparator(*items[i].node) || SeparatorShows(items, i)));
            m_hidden.Clear();
            for (usize i = 0; i < items.Size(); ++i)
            {
                items[i].shown = shows[i];
                if (!shows[i])
                    m_hidden.PushBack(items[i].node);
            }
            const bool overflowing = HasHiddenItem();

            // Spacers share what is left.
            f32 grow = 0.0f;
            for (const Item& item : items)
                if (item.shown)
                    grow += item.node->GetLayoutStyle().Grow;
            const f32 left = core::Max(0.0f, room - used(overflowing));

            const bool reverse = !column && IsRightToLeft();
            f32 at = 0.0f;
            const auto place = [&](Node& node, core::Float2 size, f32 extent)
            {
                const LayoutStyle& s = node.GetLayoutStyle();
                const f32 crossRoom = column ? content.width : content.height;
                const bool stretch = s.AlignSelf == Align::Stretch;
                f32 cross = stretch ? crossRoom : core::Min(column ? size.x : size.y, crossRoom);
                const f32 crossAt = (crossRoom - cross) * 0.5f;
                Rect r;
                if (column)
                    r = Rect{content.x + crossAt, content.y + at, cross, extent};
                else
                {
                    const f32 x = reverse ? content.x + content.width - at - extent : content.x + at;
                    r = Rect{x, content.y + crossAt, extent, cross};
                }
                node.Arrange(r);
                at += extent + gap;
            };
            for (const Item& item : items)
            {
                item.node->SetVisible(item.shown);
                if (!item.shown)
                {
                    item.node->Arrange(Rect{content.x, content.y, 0.0f, 0.0f});
                    continue;
                }
                f32 extent = along(item.size);
                if (grow > 0.0f && item.node->GetLayoutStyle().Grow > 0.0f)
                    extent += left * item.node->GetLayoutStyle().Grow / grow;
                place(*item.node, item.size, extent);
            }
            m_overflow->SetVisible(overflowing);
            if (overflowing)
            {
                // At the bar's end, whatever is left before it.
                const core::Float2 size = Natural(*m_overflow, avail);
                at = room - along(size);
                place(*m_overflow, size, along(size));
            }
            else
                m_overflow->Arrange(Rect{content.x, content.y, 0.0f, 0.0f});
        }

    private:
        template <typename Items>
        [[nodiscard]] bool SeparatorShows(const Items& items, usize at) const
        {
            // Only between two shown items that are not separators, and not after another shown one.
            bool before = false;
            for (usize i = at; i-- > 0;)
            {
                if (!items[i].shown)
                    continue;
                if (IsSeparator(*items[i].node))
                    return false; // the one before shows (or is itself left out): one break is enough
                before = true;
                break;
            }
            if (!before)
                return false;
            for (usize i = at + 1; i < items.Size(); ++i)
                if (items[i].shown && !IsSeparator(*items[i].node))
                    return true;
            return false;
        }
        // One of its items: displayed and in its flow. Not its overflow button, nor a popup it
        // opened (the overflow menu is its child while open, in the top layer), nor what stands out
        // of the flow.
        [[nodiscard]] bool IsItem(const Node& node) const
        {
            return &node != m_overflow.Get() && node.IsDisplayed() && !node.IsInTopLayer() &&
                   node.GetLayoutStyle().Placement != Position::Absolute;
        }
        [[nodiscard]] bool HasHiddenItem() const
        {
            for (Node* node : m_hidden)
                if (!IsSeparator(*node))
                    return true;
            return false;
        }
        [[nodiscard]] static bool IsSeparator(const Node& node) { return Cast<Separator>(const_cast<Node*>(&node)) != nullptr; }
        // A row of a menu can stand for it: a tool button (a menu button among them) or a separator.
        [[nodiscard]] static bool CanOverflow(const Node& node)
        {
            return Cast<ToolButton>(const_cast<Node*>(&node)) != nullptr || IsSeparator(node);
        }
        [[nodiscard]] static i32 Priority(const Node& node)
        {
            const ToolButton* button = Cast<ToolButton>(const_cast<Node*>(&node));
            return button != nullptr ? button->GetOverflowPriority() : 0;
        }
        // Its border box with its margins, as it would be with nothing in its way.
        [[nodiscard]] static core::Float2 Natural(Node& node, core::Float2 available)
        {
            LayoutConstraints constraints;
            constraints.Max = available;
            const core::Float2 size = node.Measure(constraints);
            const Thickness m = node.GetLayoutStyle().Margin;
            return core::Float2{size.x + m.TotalHorizontal(), size.y + m.TotalVertical()};
        }

        void AddOverflowRow(Node& node)
        {
            ToolButton* button = Cast<ToolButton>(&node);
            if (button == nullptr)
                return;
            if (ToolMenuButton* menuButton = Cast<ToolMenuButton>(button); menuButton != nullptr && !menuButton->IsSplit())
            {
                // Its menu opens where it went: below the overflow button.
                ToolBar* self = this;
                core::RefPtr<ToolMenuButton> held(menuButton);
                MenuItem* row = m_menu->AddItem(button->GetLabel(), [self, held]() { held->OpenMenu(*self->m_overflow); });
                row->SetEnabled(button->IsTreeEnabled());
                return;
            }
            if (button->HasCommand())
            {
                auto row = core::MakeRef<MenuItem>(MemoryAllocator());
                row->SetCheckable(button->IsToggle());
                row->SetCommand(button->GetCommand()); // its label, keys, state: the command's
                if (core::StringView own = button->GetText(); own.Size() != 0)
                    row->SetText(own);
                m_menu->AdoptItem(*row);
                return;
            }
            core::RefPtr<ToolButton> held(button);
            MenuItem* row = m_menu->AddItem(button->GetLabel(), [held]() { held->HandleActivate(); });
            row->SetEnabled(button->IsTreeEnabled());
        }

        // Its flex direction follows its orientation, pinned as code's: its separators read it to
        // stand up or lie across. Its orientation is the truth, since a restyle (its `orientation`
        // set from markup under the sheet's hand) returns an unpinned direction to its default.
        void KeepDirection()
        {
            const FlexDirection wanted = m_vertical ? FlexDirection::Column : FlexDirection::Row;
            if (GetLayoutStyle().Direction == wanted)
                return;
            LayoutStyle style = GetLayoutStyle();
            style.Direction = wanted;
            // Along, it gives way (what does not fit overflows); across, its content's minimum holds.
            style.MinWidth = m_vertical ? LayoutLength{} : LayoutLength::Px(0.0f);
            style.MinHeight = m_vertical ? LayoutLength::Px(0.0f) : LayoutLength{};
            SetLayoutStyle(style);
            for (usize i = 0; i < ChildCount(); ++i)
                if (IsSeparator(*GetChildAt(i)))
                    GetChildAt(i)->RequestLayout(); // its thickness lies along the other axis now
        }

        core::RefPtr<ToolBarOverflow> m_overflow;
        core::RefPtr<Menu> m_menu;
        core::Array<Node*> m_hidden;
        bool m_vertical = false;
    };
}
