// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :toast partition
//
// Toasts (T7 of Specs/gui-lab-evolution-3.md): short notices that leave by themselves, one host for
// a game and an editor alike (foundation.ui wrote the same toast twice, its toolkit's and a copy in
// its gamekit, for a module rule; no reference keeps them apart). A ToastHost is a widget the
// application places over a window: only its cards take the pointer, and a toast never takes the
// focus. A request is a message (and a title), or a widget for its content in the host's card, or
// `Bare`, the application's card alone; a severity (info, success, warning, error: colour and icon
// the sheet's), up to two actions, a duration and a key. Info and success stay 5 s, a warning 8 s,
// an error until closed, each the host's to change; hovering or focusing a toast pauses them all.
// A post with the key of one shown replaces it and counts it ("×12": a burst of one error, or a
// progress toast updated), four show at once and the rest wait. Posts may come from any thread:
// they wait in the host until its next frame (Godot, zed, Zero), a widget made there by a function,
// since widgets do not cross threads. A card enters and leaves through the core's Enter and Leave
// (`:entering`, `:leaving`), so the sheet's transitions play and a dismissed card goes once its
// exit has ended; a request's classes choose how (the theme's slide, `pop`, `still`, a game's own;
// reduced motion only fades). Each shown toast is announced, an error interrupting. The
// host keeps no history: it tells the application each toast posted and gone, for a log or a bell.
// A request is a value (no callbacks in it), so a script fills one in as code does and posts it; an
// action's button sends `activate` with the action's id, as a menu item does, beside the callback
// code may pass with the post.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:toast;

import foundation.core; // RefPtr, MakeRef, Array, String, Function, Mutex, ScopedLock, Move, Max
import :rect;
import :event;
import :node;
import :ui_widget;
import :layout_style;
import :label;
import :button;
import :model_index; // ModelIndex (an action's `activate`)
import :actions;       // TickAction (the GUI's clock)
import :accessibility; // AnnouncePriority
import :scene_root;    // GUIContext::Announce

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class ToastSeverity : u8
    {
        Info,
        Success,
        Warning,
        Error,
    };
    [[nodiscard]] inline core::StringView ToastSeverityName(ToastSeverity severity) noexcept
    {
        switch (severity)
        {
        case ToastSeverity::Success: return core::StringView(u8"success");
        case ToastSeverity::Warning: return core::StringView(u8"warning");
        case ToastSeverity::Error: return core::StringView(u8"error");
        case ToastSeverity::Info:
        default: return core::StringView(u8"info");
        }
    }

    /// A button on a toast. Pressed, it closes the toast, runs its command (if it names one), calls
    /// the post's callback with it, and sends `activate` with its id from its button (a script's).
    struct ToastAction
    {
        core::String Id;
        core::String Text;
        core::String Command;
    };

    using ToastId = u64;

    /// What a toast shows and how long.
    struct ToastRequest
    {
        core::String Title;
        core::String Message;
        bool Rich = false; ///< the message is the core's rich text
        /// Its content instead of the title and message, in the host's card (the GUI's thread only; a
        /// post from another thread passes a function that makes it).
        core::RefPtr<UIWidget> Content;
        /// No card: the content alone, its lifetime and place still the host's (a game's banner).
        bool Bare = false;
        /// Said to a screen reader; empty: the title and message, else the content's name.
        core::String Announcement;
        ToastSeverity Severity = ToastSeverity::Info;
        core::Array<ToastAction> Actions; ///< two at most (the rest are not shown)
        /// Seconds it stays; below 0: its severity's default; 0: until closed.
        f32 Duration = -1.0f;
        /// A post with the key of one shown or waiting replaces it and counts it; empty: none.
        core::String Key;
        /// Classes on its card (space-separated): how it comes and goes, as the sheet says (the
        /// theme's `pop` and `still`, a game's own), or any look the sheet gives them.
        core::String Classes;

        /// Adds an action (a script's way: a list's element added there is a copy). An empty
        /// command: none.
        void AddAction(core::String id, core::String text, core::String command)
        {
            Actions.PushBack(ToastAction{core::Move(id), core::Move(text), core::Move(command)});
        }
    };
    /// Told the action pressed on a toast.
    using ToastActionCallback = core::Function<void(const ToastAction&)>;
    /// Makes a toast's content, on the GUI's thread.
    using ToastContentMaker = core::Function<core::RefPtr<UIWidget>()>;

    class ToastHost;

    /// One toast (`toast`, with its severity's class): a card holding its parts, or bare.
    class ToastCard : public UIWidget
    {
        RTTI_OBJECT(ToastCard, UIWidget)
    public:
        ToastCard()
        {
            SetTag(core::StringView(u8"toast"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.AlignItems = Align::Start;
                s.ColumnGap = 8.0f;
                s.Shrink = 0.0f;
            });
        }
        [[nodiscard]] ToastId GetToastId() const noexcept { return m_id; }
        [[nodiscard]] ToastSeverity GetSeverity() const noexcept { return m_severity; }
        [[nodiscard]] core::StringView GetKey() const noexcept { return m_key.AsView(); }
        /// How many posts it stands for (1, then each one its key replaced).
        [[nodiscard]] u32 GetCount() const noexcept { return m_count; }
        /// Seconds left (0 or less with a duration: going; below 0 when it stays until closed).
        [[nodiscard]] f32 GetRemaining() const noexcept { return m_remaining; }
        [[nodiscard]] Label* GetTitlePart() const noexcept { return m_title.Get(); }
        [[nodiscard]] Label* GetMessagePart() const noexcept { return m_message.Get(); }
        [[nodiscard]] Label* GetCountPart() const noexcept { return m_countPart.Get(); }
        [[nodiscard]] UIWidget* GetContent() const noexcept { return m_content.Get(); }
        [[nodiscard]] Button* GetCloseButton() const noexcept { return m_close.Get(); }
        [[nodiscard]] usize ActionCount() const noexcept { return m_actions.Size(); }
        [[nodiscard]] Button& ActionAt(usize index) const noexcept { return *m_actions[index]; }
        /// What it says to a screen reader.
        [[nodiscard]] core::StringView GetAnnouncement() const noexcept { return m_announcement.AsView(); }

    private:
        friend class ToastHost;

        ToastId m_id = 0;
        ToastSeverity m_severity = ToastSeverity::Info;
        core::String m_key;
        core::String m_announcement;
        u32 m_count = 1;
        f32 m_remaining = 0.0f;
        bool m_dismissed = false; // taken off the stack: leaving (the core's Leave), gone once its exit ends
        core::String m_classes; // its request's
        core::RefPtr<UIWidget> m_body;
        core::RefPtr<Label> m_title;
        core::RefPtr<Label> m_message;
        core::RefPtr<Label> m_countPart;
        core::RefPtr<UIWidget> m_content;
        core::RefPtr<UIWidget> m_actionRow;
        core::Array<core::RefPtr<Button>> m_actions;
        core::Array<ToastAction> m_actionItems;
        ToastActionCallback m_onAction;
        core::RefPtr<Button> m_close;
    };

    class ToastHost : public UIWidget
    {
        RTTI_OBJECT(ToastHost, UIWidget)
    public:
        static constexpr usize kMaxActions = 2;

        ToastHost()
        {
            SetTag(core::StringView(u8"toasthost"));
            SetHitTestVisible(false); // only its cards take the pointer
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    // Over what holds it, its toasts at the bottom end.
                    s.Placement = Position::Absolute;
                    s.Left = LayoutLength::Px(0.0f);
                    s.Top = LayoutLength::Px(0.0f);
                    s.Right = LayoutLength::Px(0.0f);
                    s.Bottom = LayoutLength::Px(0.0f);
                    s.Direction = FlexDirection::Column;
                    s.JustifyContent = Justify::End;
                    s.AlignItems = Align::End;
                    s.RowGap = 8.0f;
                    s.ZIndex = 1000;
                });
                SetPadding(Thickness{16.0f, 16.0f, 16.0f, 16.0f});
            }
            m_defaults[static_cast<usize>(ToastSeverity::Info)] = 5.0f;
            m_defaults[static_cast<usize>(ToastSeverity::Success)] = 5.0f;
            m_defaults[static_cast<usize>(ToastSeverity::Warning)] = 8.0f;
            m_defaults[static_cast<usize>(ToastSeverity::Error)] = 0.0f;
        }

        /// Shows a toast, or queues it while as many as it shows already do; the GUI's thread.
        /// `onAction` hears the action pressed.
        ToastId Post(ToastRequest request, ToastActionCallback onAction = {})
        {
            ToastId id = 0;
            {
                core::ScopedLock<core::Mutex> lock(m_lock);
                id = ++m_lastId;
            }
            KeepTicking();
            Place(id, core::Move(request), core::Move(onAction));
            return id;
        }
        /// Posts from any thread: it waits until the host's next frame. Its content, if any, comes
        /// from `makeContent`, called then on the GUI's thread (the request's `Content` is not taken).
        ToastId PostFromAnyThread(ToastRequest request, ToastContentMaker makeContent = {}, ToastActionCallback onAction = {})
        {
            request.Content = core::RefPtr<UIWidget>{};
            core::ScopedLock<core::Mutex> lock(m_lock);
            const ToastId id = ++m_lastId;
            m_incoming.PushBack(Incoming{id, core::Move(request), core::Move(makeContent), core::Move(onAction)});
            return id;
        }
        /// Takes a toast away (shown or waiting); false when it is not there.
        bool Dismiss(ToastId id) { return Remove(id, false); }
        /// Takes every toast away.
        void DismissAll()
        {
            while (!m_waiting.IsEmpty())
                (void)Remove(m_waiting[0].Id, false);
            for (usize i = m_cards.Size(); i-- > 0;)
                if (!m_cards[i]->m_dismissed)
                    (void)Remove(m_cards[i]->m_id, false);
        }

        // A script's (reflected): `host.post(request)`, `host.postContent(request, widget)`.
        ToastId PostScript(ToastRequest request) { return Post(core::Move(request)); }
        ToastId PostContentScript(ToastRequest request, core::Variant content)
        {
            Node* node = Node::FromHandle(content);
            request.Content = core::RefPtr<UIWidget>(node != nullptr ? Cast<UIWidget>(node) : nullptr);
            return Post(core::Move(request));
        }
        [[nodiscard]] i32 GetShownCountScript() const noexcept { return static_cast<i32>(ShownCount()); }
        [[nodiscard]] i32 GetWaitingCountScript() const noexcept { return static_cast<i32>(WaitingCount()); }
        [[nodiscard]] i32 GetMaxShownScript() const noexcept { return static_cast<i32>(m_maxShown); }
        void SetMaxShownScript(i32 count) noexcept { SetMaxShown(static_cast<usize>(core::Max(1, count))); }

        /// The toasts shown now, oldest first (one leaving not among them), and waiting.
        [[nodiscard]] usize ShownCount() const noexcept
        {
            usize count = 0;
            for (const core::RefPtr<ToastCard>& card : m_cards)
                count += !card->m_dismissed ? 1 : 0;
            return count;
        }
        [[nodiscard]] usize WaitingCount() const noexcept { return m_waiting.Size(); }
        /// A shown toast's card (null when it is not shown).
        [[nodiscard]] ToastCard* GetCard(ToastId id) const noexcept
        {
            for (const core::RefPtr<ToastCard>& card : m_cards)
                if (card->m_id == id && !card->m_dismissed)
                    return card.Get();
            return nullptr;
        }
        [[nodiscard]] bool IsShown(ToastId id) const noexcept { return GetCard(id) != nullptr; }
        [[nodiscard]] bool IsWaiting(ToastId id) const noexcept
        {
            for (const Waiting& waiting : m_waiting)
                if (waiting.Id == id)
                    return true;
            return false;
        }
        /// Whether their timers stand still now (the pointer or the focus on a toast).
        [[nodiscard]] bool IsPaused() const
        {
            for (const core::RefPtr<ToastCard>& card : m_cards)
                if (card->IsHovered() || card->IsFocusWithin())
                    return true;
            return false;
        }

        /// How many it shows at once (4); the rest wait.
        void SetMaxShown(usize count) noexcept { m_maxShown = core::Max<usize>(1, count); }
        [[nodiscard]] usize GetMaxShown() const noexcept { return m_maxShown; }
        /// Seconds a severity's toasts stay when a request does not say (0: until closed).
        void SetDefaultDuration(ToastSeverity severity, f32 seconds) noexcept { m_defaults[static_cast<usize>(severity)] = core::Max(0.0f, seconds); }
        [[nodiscard]] f32 GetDefaultDuration(ToastSeverity severity) const noexcept { return m_defaults[static_cast<usize>(severity)]; }

        /// Told each toast posted (once shown or queued; a replacement too), for a log.
        void SetOnPosted(core::Function<void(ToastId, const ToastCard&)> callback) { m_onPosted = core::Move(callback); }
        /// Told each toast gone: closed by the user (its close button or an action), or not.
        void SetOnDismissed(core::Function<void(ToastId, bool byUser)> callback) { m_onDismissed = core::Move(callback); }

        /// Advances its toasts by `seconds` (the host's frame: the GUI's clock calls it).
        void Tick(f32 seconds)
        {
            // What other threads posted, here on the GUI's thread.
            core::Array<Incoming> incoming(MemoryAllocator());
            {
                core::ScopedLock<core::Mutex> lock(m_lock);
                incoming = core::Move(m_incoming);
                m_incoming = core::Array<Incoming>(MemoryAllocator());
            }
            for (Incoming& post : incoming)
            {
                if (post.MakeContent)
                    post.Request.Content = post.MakeContent();
                Place(post.Id, core::Move(post.Request), core::Move(post.OnAction));
            }
            const bool paused = IsPaused();
            for (usize i = m_cards.Size(); i-- > 0;)
            {
                ToastCard& card = *m_cards[i];
                if (card.m_dismissed)
                {
                    if (card.GetParent() != this) // its exit ended: the core's Leave took it off
                        m_cards.RemoveAt(i);
                    continue;
                }
                if (paused || card.m_remaining < 0.0f)
                    continue;
                card.m_remaining -= seconds;
                if (card.m_remaining <= 0.0f)
                    (void)Remove(card.m_id, false);
            }
            ShowWaiting();
        }

    protected:
        // Laid out once it is in a GUI: its clock starts there (an action runs only under a root).
        void OnLayout() override
        {
            UIWidget::OnLayout();
            KeepTicking();
        }

    private:
        void KeepTicking()
        {
            if (m_ticking || GetActionManager() == nullptr)
                return;
            m_ticking = true;
            ToastHost* self = this;
            RunAction(core::MakeRef<TickAction>(MemoryAllocator(), [self](core::Duration elapsed)
                                                {
                                                    self->Tick(static_cast<f32>(elapsed.AsSeconds()));
                                                    return true;
                                                }));
        }
        struct Incoming
        {
            ToastId Id = 0;
            ToastRequest Request;
            ToastContentMaker MakeContent;
            ToastActionCallback OnAction;
        };
        struct Waiting
        {
            ToastId Id = 0;
            ToastRequest Request;
            u32 Count = 1;
            ToastActionCallback OnAction;
        };

        [[nodiscard]] f32 DurationOf(const ToastRequest& request) const
        {
            const f32 seconds = request.Duration < 0.0f ? m_defaults[static_cast<usize>(request.Severity)] : request.Duration;
            return seconds > 0.0f ? seconds : -1.0f; // below 0: until closed
        }
        // Shows it, replaces the one with its key, or queues it.
        void Place(ToastId id, ToastRequest request, ToastActionCallback onAction)
        {
            if (!request.Key.IsEmpty())
            {
                for (const core::RefPtr<ToastCard>& card : m_cards)
                    if (!card->m_dismissed && card->m_key == request.Key)
                    {
                        const u32 count = card->m_count + 1;
                        Fill(*card, card->m_id, core::Move(request), count, core::Move(onAction));
                        if (m_onPosted)
                            m_onPosted(card->m_id, *card);
                        Announce(*card);
                        return;
                    }
                for (Waiting& waiting : m_waiting)
                    if (waiting.Request.Key == request.Key)
                    {
                        waiting.Request = core::Move(request);
                        waiting.OnAction = core::Move(onAction);
                        ++waiting.Count;
                        return;
                    }
            }
            if (ShownCount() >= m_maxShown)
            {
                m_waiting.PushBack(Waiting{id, core::Move(request), 1, core::Move(onAction)});
                return;
            }
            Show(id, core::Move(request), 1, core::Move(onAction));
        }
        void Show(ToastId id, ToastRequest request, u32 count, ToastActionCallback onAction)
        {
            core::RefPtr<ToastCard> card = core::MakeRef<ToastCard>(MemoryAllocator());
            Fill(*card, id, core::Move(request), count, core::Move(onAction));
            AddChild(card.Get());
            card->Enter(); // `:entering` for the sheet's entrance
            m_cards.PushBack(card);
            if (m_onPosted)
                m_onPosted(id, *card);
            Announce(*card);
        }
        void ShowWaiting()
        {
            while (!m_waiting.IsEmpty() && ShownCount() < m_maxShown)
            {
                Waiting next = core::Move(m_waiting[0]);
                m_waiting.RemoveAt(0);
                Show(next.Id, core::Move(next.Request), next.Count, core::Move(next.OnAction));
            }
        }
        // Its parts from the request (a replacement's too, counted).
        void Fill(ToastCard& card, ToastId id, ToastRequest request, u32 count, ToastActionCallback onAction)
        {
            card.m_id = id;
            card.m_count = count;
            card.m_key = request.Key;
            card.m_remaining = DurationOf(request);
            card.RemoveClass(ToastSeverityName(card.m_severity));
            card.m_severity = request.Severity;
            card.AddClass(ToastSeverityName(card.m_severity));
            EachClass(card.m_classes.AsView(), [&card](core::StringView name) { card.RemoveClass(name); });
            card.m_classes = request.Classes;
            EachClass(card.m_classes.AsView(), [&card](core::StringView name) { card.AddClass(name); });
            if (request.Bare)
                card.AddClass(core::StringView(u8"bare"));
            else
                card.RemoveClass(core::StringView(u8"bare"));
            while (card.ChildCount() != 0)
                card.RemoveChild(card.GetChildAt(card.ChildCount() - 1));
            card.m_title = core::RefPtr<Label>{};
            card.m_message = core::RefPtr<Label>{};
            card.m_countPart = core::RefPtr<Label>{};
            card.m_close = core::RefPtr<Button>{};
            card.m_actions.Clear();
            card.m_actionItems.Clear();
            card.m_onAction = core::Move(onAction);
            card.m_content = request.Content;
            if (request.Bare && card.m_content)
            {
                card.AddChild(card.m_content.Get());
                card.m_announcement = request.Announcement.IsEmpty() ? card.m_content->GetAccessLabel() : request.Announcement;
                return;
            }
            // The card: its mark (the sheet's colour and icon), its body, its count and close.
            auto mark = core::MakeRef<UIWidget>(MemoryAllocator());
            mark->SetTag(core::StringView(u8"toastmark"));
            mark->SetHitTestVisible(false);
            card.AddChild(mark.Get());
            card.m_body = core::MakeRef<UIWidget>(MemoryAllocator());
            card.m_body->AddClass(core::StringView(u8"body"));
            card.m_body->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.RowGap = 4.0f;
                s.Grow = 1.0f;
                s.Shrink = 1.0f;
                s.MinWidth = LayoutLength::Px(0.0f);
            });
            card.AddChild(card.m_body.Get());
            core::String said;
            if (card.m_content)
                card.m_body->AddChild(card.m_content.Get());
            else
            {
                if (!request.Title.IsEmpty())
                {
                    card.m_title = core::MakeRef<Label>(MemoryAllocator());
                    card.m_title->AddClass(core::StringView(u8"title"));
                    card.m_title->SetText(request.Title.AsView());
                    card.m_body->AddChild(card.m_title.Get());
                    said = request.Title;
                }
                card.m_message = core::MakeRef<Label>(MemoryAllocator());
                card.m_message->AddClass(core::StringView(u8"message"));
                card.m_message->SetRich(request.Rich);
                card.m_message->SetText(request.Message.AsView());
                card.m_body->AddChild(card.m_message.Get());
                if (!said.IsEmpty() && !request.Message.IsEmpty())
                    said.Append(core::StringView(u8": "));
                said.Append(card.m_message->GetTextLayout().PlainText()); // a rich message without its markup
            }
            card.m_announcement = !request.Announcement.IsEmpty() ? request.Announcement
                                  : card.m_content                ? card.m_content->GetAccessLabel()
                                                                  : said;
            ToastHost* self = this;
            const usize actions = core::Min(request.Actions.Size(), kMaxActions);
            if (actions > 0)
            {
                card.m_actionRow = core::MakeRef<UIWidget>(MemoryAllocator());
                card.m_actionRow->AddClass(core::StringView(u8"actions"));
                card.m_actionRow->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Row;
                    s.ColumnGap = 6.0f;
                });
                card.m_body->AddChild(card.m_actionRow.Get());
                for (usize i = 0; i < actions; ++i)
                {
                    const ToastAction& action = request.Actions[i];
                    core::RefPtr<Button> button = core::MakeRef<Button>(MemoryAllocator());
                    button->AddClass(core::StringView(u8"action"));
                    button->SetText(action.Text.AsView());
                    button->SetId(action.Id.AsView()); // what its `activate` says
                    card.m_actionItems.PushBack(action);
                    if (!action.Command.IsEmpty())
                        button->SetCommand(action.Command.AsView());
                    ToastCard* held = &card;
                    button->SetOnClick([self, held, i]()
                    {
                        const ToastId toast = held->m_id;
                        if (i >= held->m_actionItems.Size())
                            return;
                        const ToastAction pressed = held->m_actionItems[i];
                        core::RefPtr<Button> from = held->m_actions[i];
                        if (held->m_onAction)
                            held->m_onAction(pressed);
                        // A script's `activate`, as a menu item's: it bubbles, its id the action's.
                        ItemEvent activated(EventType::ItemActivate, from.Get(), static_cast<i32>(i), ModelIndex{});
                        (void)from->RouteEvent(activated);
                        (void)self->Remove(toast, true);
                    });
                    card.m_actionRow->AddChild(button.Get());
                    card.m_actions.PushBack(core::Move(button));
                }
            }
            if (count > 1)
            {
                card.m_countPart = core::MakeRef<Label>(MemoryAllocator());
                card.m_countPart->AddClass(core::StringView(u8"count"));
                card.m_countPart->SetText(core::Format(u8"×{}", count).AsView());
                card.AddChild(card.m_countPart.Get());
            }
            card.m_close = core::MakeRef<Button>(MemoryAllocator());
            card.m_close->AddClass(core::StringView(u8"close"));
            card.m_close->SetText(core::StringView(u8"×"));
            card.m_close->SetAccessLabel(core::String(core::StringView(u8"Close")));
            ToastCard* held = &card;
            card.m_close->SetOnClick([self, held]() { (void)self->Remove(held->m_id, true); });
            card.AddChild(card.m_close.Get());
        }
        template <typename Fn>
        static void EachClass(core::StringView classes, Fn&& each)
        {
            core::StringView rest = core::Trim(classes);
            while (rest.Size() != 0)
            {
                usize end = 0;
                while (end < rest.Size() && rest[end] != u8' ')
                    ++end;
                each(rest.SubStr(0, end));
                rest = core::Trim(rest.SubStr(end, rest.Size() - end));
            }
        }
        void Announce(const ToastCard& card)
        {
            if (card.m_announcement.IsEmpty())
                return;
            if (SceneRoot* scene = GetSceneRoot())
                scene->GetContext().Announce(card.m_announcement.AsView(),
                                             card.m_severity == ToastSeverity::Error ? AnnouncePriority::Assertive : AnnouncePriority::Polite);
        }
        // Off the stack: a shown one leaves through the core's Leave (out of the pointer at once, a
        // child until its exit has ended, never inside the event that closed it), a waiting one at once.
        bool Remove(ToastId id, bool byUser)
        {
            for (usize i = 0; i < m_waiting.Size(); ++i)
                if (m_waiting[i].Id == id)
                {
                    m_waiting.RemoveAt(i);
                    if (m_onDismissed)
                        m_onDismissed(id, byUser);
                    return true;
                }
            for (const core::RefPtr<ToastCard>& card : m_cards)
                if (card->m_id == id && !card->m_dismissed)
                {
                    card->m_dismissed = true;
                    card->Leave();
                    if (m_onDismissed)
                        m_onDismissed(id, byUser);
                    return true;
                }
            return false;
        }

        core::Array<core::RefPtr<ToastCard>> m_cards; // shown, oldest first (leaving ones among them)
        core::Array<Waiting> m_waiting;
        core::Array<Incoming> m_incoming; // posted from other threads, under m_lock
        core::Mutex m_lock;               // guards m_incoming and m_lastId
        ToastId m_lastId = 0;
        usize m_maxShown = 4;
        f32 m_defaults[4] = {};
        bool m_ticking = false; // its clock's action runs
        core::Function<void(ToastId, const ToastCard&)> m_onPosted;
        core::Function<void(ToastId, bool)> m_onDismissed;
    };
}
