// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - toasts (T7 of Specs/gui-lab-evolution-3.md): a host's cards, by severity, staying their
// time on the GUI's clock (an error until closed), paused while hovered; a key replacing and
// counting; four shown and the rest waiting; a widget's content, or bare; actions; posts from
// another thread waiting for the host's frame; each shown toast announced.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <thread>
import foundation.core;
import foundation.fonts;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    namespace fonts = foundation::fonts;

    // A mock font: 6px a byte, 12px a line.
    class SixFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return SV(u8"six"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return 10.0f; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView text) const override { return static_cast<core::f32>(text.Size()) * 6.0f; }
        core::f32 MeasureString(core::StringView text, core::Array<fonts::GlyphPosition>&) const override { return MeasureString(text); }
    };

    class Narrator : public IAccessibilityBridge
    {
    public:
        [[nodiscard]] bool IsListening() const override { return true; }
        void Update(const AccessTreeUpdate&) override {}
        void Announce(core::StringView text, AnnouncePriority priority) override
        {
            said.PushBack(core::String(text));
            priorities.PushBack(priority);
        }
        core::Array<core::String> said{core::DefaultAllocator()};
        core::Array<AnnouncePriority> priorities{core::DefaultAllocator()};
    };

    // A host over an 800 by 600 root.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ToastHost> host = core::MakeRef<ToastHost>(core::DefaultAllocator());
        Narrator narrator;

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->AddChild(host.Get());
            root->GetContext().SetAccessibilityBridge(&narrator);
            Frame(0.0f);
        }
        ~Bed() { root->GetContext().SetAccessibilityBridge(nullptr); }
        void Frame(f32 seconds = 0.016f)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            (void)root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        static ToastRequest Text(const char8_t* message, ToastSeverity severity = ToastSeverity::Info, const char8_t* title = u8"")
        {
            ToastRequest request;
            request.Message = core::String(message);
            request.Title = core::String(title);
            request.Severity = severity;
            return request;
        }
        [[nodiscard]] core::Float2 Middle(const Node& node) const
        {
            const Rect r = node.GetScreenBounds();
            return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
        }
    };
}

TEST_CASE("toast: a card with its title, message and severity, at the bottom end, announced; its close button takes it away")
{
    Bed bed;
    core::Array<ToastId> posted{core::DefaultAllocator()};
    core::Array<core::String> gone{core::DefaultAllocator()};
    bed.host->SetOnPosted([&posted](ToastId id, const ToastCard&) { posted.PushBack(id); });
    bed.host->SetOnDismissed([&gone](ToastId id, bool byUser) { gone.PushBack(core::Format(u8"{} {}", id, byUser ? u8"user" : u8"time")); });
    const ToastId id = bed.host->Post(Bed::Text(u8"Saved the scene", ToastSeverity::Success, u8"Saved"));
    bed.Frame();
    ToastCard* card = bed.host->GetCard(id);
    REQUIRE(card != nullptr);
    CHECK(card->HasClass(SV(u8"success")));
    REQUIRE(card->GetTitlePart() != nullptr);
    CHECK(card->GetTitlePart()->GetText() == SV(u8"Saved"));
    CHECK(card->GetMessagePart()->GetText() == SV(u8"Saved the scene"));
    CHECK(card->GetCountPart() == nullptr);
    REQUIRE(posted.Size() == 1);
    CHECK(posted[0] == id);
    REQUIRE(bed.narrator.said.Size() == 1);
    CHECK(bed.narrator.said[0] == core::String(u8"Saved: Saved the scene"));
    CHECK(bed.narrator.priorities[0] == AnnouncePriority::Polite);
    // At the bottom end, inside its padding; the host itself lets the pointer through.
    const Rect at = card->GetScreenBounds();
    CHECK(at.Right() == doctest::Approx(800.0f - 16.0f));
    CHECK(at.Bottom() == doctest::Approx(600.0f - 16.0f));
    CHECK_FALSE(bed.host->IsHitTestVisible());

    REQUIRE(card->GetCloseButton() != nullptr);
    const core::Float2 close = bed.Middle(*card->GetCloseButton());
    bed.D().InjectMouseMove(close);
    bed.D().InjectMouseDown(close, MouseButton::Left);
    bed.D().InjectMouseUp(close, MouseButton::Left);
    CHECK_FALSE(bed.host->IsShown(id));
    REQUIRE(gone.Size() == 1);
    CHECK(gone[0] == core::Format(u8"{} user", id));
    CHECK(card->IsLeaving()); // still a child, never taken off inside the click that closed it
    CHECK(card->GetParent() == bed.host.Get());
    bed.Frame(0.2f);
    CHECK(card->GetParent() == nullptr);
}

TEST_CASE("toast: each severity stays its time on the GUI's clock, an error until closed; hovering a toast pauses them")
{
    Bed bed;
    const ToastId info = bed.host->Post(Bed::Text(u8"Info"));
    const ToastId warning = bed.host->Post(Bed::Text(u8"Careful", ToastSeverity::Warning));
    const ToastId error = bed.host->Post(Bed::Text(u8"Broken", ToastSeverity::Error));
    ToastRequest rich = Bed::Text(u8"the [b]fur[/b] material", ToastSeverity::Info, u8"Missing");
    rich.Rich = true;
    const ToastId richId = bed.host->Post(core::Move(rich));
    CHECK(bed.narrator.said.Back() == core::String(u8"Missing: the fur material")); // said without its markup
    CHECK(bed.host->GetCard(richId)->GetMessagePart()->IsRich());
    ToastRequest brief = Bed::Text(u8"Brief");
    brief.Duration = 2.0f;
    const ToastId shortOne = bed.host->Post(core::Move(brief));
    CHECK(bed.narrator.priorities.Back() == AnnouncePriority::Polite);
    CHECK(bed.narrator.priorities[2] == AnnouncePriority::Assertive); // the error interrupts
    bed.Frame(2.5f);
    CHECK_FALSE(bed.host->IsShown(shortOne));
    bed.Frame(2.6f); // 5.1 s
    CHECK_FALSE(bed.host->IsShown(info));
    CHECK(bed.host->IsShown(warning));
    bed.Frame(3.0f); // 8.1 s
    CHECK_FALSE(bed.host->IsShown(warning));
    bed.Frame(100.0f);
    CHECK(bed.host->IsShown(error));
    CHECK(bed.narrator.said[2] == core::String(u8"Broken"));

    // The pointer on a toast: none of them counts down.
    bed.host->SetDefaultDuration(ToastSeverity::Info, 1.0f);
    CHECK(bed.host->GetDefaultDuration(ToastSeverity::Info) == doctest::Approx(1.0f));
    const ToastId next = bed.host->Post(Bed::Text(u8"Next"));
    bed.Frame();
    bed.D().InjectMouseMove(bed.Middle(*bed.host->GetCard(error)));
    CHECK(bed.host->IsPaused());
    bed.Frame(5.0f);
    CHECK(bed.host->IsShown(next));
    bed.D().InjectMouseMove(core::Float2{10.0f, 10.0f});
    CHECK_FALSE(bed.host->IsPaused());
    bed.Frame(1.5f);
    CHECK_FALSE(bed.host->IsShown(next));
}

TEST_CASE("toast: a post with the key of one shown replaces it and counts it, its time again")
{
    Bed bed;
    ToastRequest first = Bed::Text(u8"Cooking 10%");
    first.Key = core::String(u8"cook");
    const ToastId id = bed.host->Post(core::Move(first));
    bed.Frame(4.0f);
    ToastRequest again = Bed::Text(u8"Cooking 60%");
    again.Key = core::String(u8"cook");
    const ToastId second = bed.host->Post(core::Move(again));
    CHECK(second != id);
    bed.Frame();
    CHECK(bed.host->ShownCount() == 1);
    ToastCard* card = bed.host->GetCard(id);
    REQUIRE(card != nullptr);
    CHECK(card->GetCount() == 2u);
    CHECK(card->GetMessagePart()->GetText() == SV(u8"Cooking 60%"));
    REQUIRE(card->GetCountPart() != nullptr);
    CHECK(card->GetCountPart()->GetText() == SV(u8"×2"));
    bed.Frame(4.0f); // 4 s after the replacement: still there
    CHECK(bed.host->IsShown(id));
}

TEST_CASE("toast: four shown at once, the rest waiting their turn (a waiting one replaced by its key too)")
{
    Bed bed;
    bed.host->SetMaxShown(2);
    const ToastId a = bed.host->Post(Bed::Text(u8"a", ToastSeverity::Error));
    const ToastId b = bed.host->Post(Bed::Text(u8"b", ToastSeverity::Error));
    ToastRequest c1 = Bed::Text(u8"c1", ToastSeverity::Error);
    c1.Key = core::String(u8"c");
    const ToastId c = bed.host->Post(core::Move(c1));
    ToastRequest c2 = Bed::Text(u8"c2", ToastSeverity::Error);
    c2.Key = core::String(u8"c");
    (void)bed.host->Post(core::Move(c2));
    CHECK(bed.host->ShownCount() == 2);
    CHECK(bed.host->WaitingCount() == 1);
    CHECK(bed.host->IsWaiting(c));
    CHECK(bed.narrator.said.Size() == 2); // the waiting one is said when it shows
    CHECK(bed.host->Dismiss(a));
    bed.Frame();
    CHECK(bed.host->IsShown(b));
    ToastCard* card = bed.host->GetCard(c);
    REQUIRE(card != nullptr);
    CHECK(card->GetMessagePart()->GetText() == SV(u8"c2"));
    CHECK(card->GetCount() == 2u);
    CHECK(bed.host->WaitingCount() == 0);
    // Newest at the bottom.
    CHECK(card->GetScreenBounds().y > bed.host->GetCard(b)->GetScreenBounds().y);
    CHECK_FALSE(bed.host->Dismiss(a));
    bed.host->DismissAll();
    CHECK(bed.host->ShownCount() == 0);
}

TEST_CASE("toast: a widget for its content in the card, or bare; actions run and close it, two at most")
{
    Bed bed;
    core::RefPtr<Label> content = core::MakeRef<Label>(core::DefaultAllocator());
    content->SetText(SV(u8"rich"));
    content->SetAccessLabel(core::String(u8"Export finished"));
    ToastRequest rich;
    rich.Content = content;
    const ToastId withContent = bed.host->Post(core::Move(rich));
    ToastCard* card = bed.host->GetCard(withContent);
    REQUIRE(card != nullptr);
    CHECK(card->GetContent() == content.Get());
    CHECK(card->GetMessagePart() == nullptr);
    CHECK(card->GetCloseButton() != nullptr);
    CHECK(card->GetAnnouncement() == SV(u8"Export finished"));

    core::RefPtr<Label> banner = core::MakeRef<Label>(core::DefaultAllocator());
    ToastRequest bare;
    bare.Content = banner;
    bare.Bare = true;
    bare.Announcement = core::String(u8"Achievement: first steps");
    const ToastId bareId = bed.host->Post(core::Move(bare));
    card = bed.host->GetCard(bareId);
    REQUIRE(card != nullptr);
    CHECK(card->HasClass(SV(u8"bare")));
    CHECK(card->GetCloseButton() == nullptr);
    CHECK(card->ChildCount() == 1u);
    CHECK(bed.narrator.said.Back() == core::String(u8"Achievement: first steps"));

    core::Array<core::String> pressed{core::DefaultAllocator()};
    ToastRequest withActions = Bed::Text(u8"Exported", ToastSeverity::Success);
    withActions.Actions.PushBack(ToastAction{core::String(u8"reveal"), core::String(u8"Reveal"), {}});
    withActions.Actions.PushBack(ToastAction{core::String(u8"open"), core::String(u8"Open"), {}});
    withActions.Actions.PushBack(ToastAction{core::String(u8"third"), core::String(u8"Third"), {}});
    const ToastId acted = bed.host->Post(core::Move(withActions), [&pressed](const ToastAction& action) { pressed.PushBack(action.Id); });
    // A script's `activate`, bubbling from the action's button with its id.
    core::Array<core::String> activated{core::DefaultAllocator()};
    (void)bed.host->AddEventListener(EventType::ItemActivate, [&activated](const Event& e)
    {
        if (const UIWidget* from = core::Cast<UIWidget>(e.Target))
            activated.PushBack(core::String(from->GetId()));
    });
    card = bed.host->GetCard(acted);
    REQUIRE(card != nullptr);
    REQUIRE(card->ActionCount() == 2u);
    CHECK(card->ActionAt(0).GetText() == SV(u8"Reveal"));
    bool byUser = false;
    bed.host->SetOnDismissed([&byUser](ToastId, bool user) { byUser = user; });
    CHECK(card->ActionAt(0).GetId() == SV(u8"reveal"));
    (void)card->ActionAt(0).HandleActivate();
    REQUIRE(pressed.Size() == 1);
    CHECK(pressed[0] == core::String(u8"reveal"));
    REQUIRE(activated.Size() == 1);
    CHECK(activated[0] == core::String(u8"reveal"));
    CHECK_FALSE(bed.host->IsShown(acted));
    CHECK(byUser);
}

TEST_CASE("toast: posted from another thread, it waits for the host's frame, its widget made on the GUI's thread")
{
    Bed bed;
    const std::thread::id gui = std::this_thread::get_id();
    std::thread::id madeOn{};
    ToastId id = 0;
    std::thread worker([&]()
    {
        ToastRequest request;
        request.Severity = ToastSeverity::Warning;
        request.Announcement = core::String(u8"Cook finished with warnings");
        id = bed.host->PostFromAnyThread(core::Move(request), [&madeOn]()
        {
            madeOn = std::this_thread::get_id();
            return core::RefPtr<UIWidget>(core::MakeRef<Label>(core::DefaultAllocator()));
        });
    });
    worker.join();
    CHECK(id != 0);
    CHECK_FALSE(bed.host->IsShown(id));
    CHECK(madeOn == std::thread::id{});
    bed.Frame();
    ToastCard* card = bed.host->GetCard(id);
    REQUIRE(card != nullptr);
    CHECK(card->GetContent() != nullptr);
    CHECK(madeOn == gui);
    CHECK(card->HasClass(SV(u8"warning")));
}

TEST_CASE("toast: under the theme, its text wraps at the card's width, a path longer than a line broken inside it")
{
    Bed bed;
    fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
    const ToastId id = bed.host->Post(Bed::Text(u8"Content/Models/Characters/Fox/Hoooooooooooooooooooo is not in the asset tree, so the bar stays where it was.",
                                                ToastSeverity::Warning, u8"No such folder"));
    ToastCard* card = bed.host->GetCard(id);
    REQUIRE(card != nullptr);
    StyleManager styles; // the theme says how a toast's text wraps
    styles.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
    styles.ApplyTree(*bed.root);
    card->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(240.0f); });
    card->GetMessagePart()->SetFont(&font);
    card->GetTitlePart()->SetFont(&font);
    bed.Frame();
    const Label& message = *card->GetMessagePart();
    CHECK(message.GetScreenBounds().Right() <= card->GetScreenBounds().Right() + 0.5f);
    CHECK(message.GetSize().y >= 36.0f); // three lines and more, not one running past the card
    card->GetMessagePart()->SetFont(nullptr);
    card->GetTitlePart()->SetFont(nullptr);
}

TEST_CASE("toast: it enters `:entering` and fades in through the sheet's transition; a request's class chooses how")
{
    Bed bed;
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
    styles.ApplyTree(*bed.root); // a style pass runs over this GUI: a toast plays its entrance
    ToastRequest request = Bed::Text(u8"Hello");
    request.Classes = core::String(u8"pop celebrate");
    request.Key = core::String(u8"hello");
    const ToastId id = bed.host->Post(core::Move(request));
    ToastCard* card = bed.host->GetCard(id);
    REQUIRE(card != nullptr);
    CHECK(card->HasClass(SV(u8"pop")));
    CHECK(card->HasClass(SV(u8"celebrate")));
    CHECK(card->IsEntering());
    // Styled so by the theme: unseen, its transition's start.
    styles.ApplyTree(*bed.root);
    CHECK(card->GetAlpha() == doctest::Approx(0.0f));
    bed.root->GetContext().Update(core::Duration{}); // its first style shown: :entering goes
    CHECK_FALSE(card->IsEntering());
    // Restyled, it fades in over the theme's 0.15 s, from where it was.
    styles.ApplyTree(*bed.root);
    CHECK(card->GetAlpha() == doctest::Approx(0.0f));
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.07f));
    CHECK(card->GetAlpha() > 0.05f);
    CHECK(card->GetAlpha() < 0.95f);
    bed.root->GetContext().Update(core::Duration::FromSeconds(0.2f));
    CHECK(card->GetAlpha() == doctest::Approx(1.0f));

    // Replaced by its key with another class: the old ones go.
    ToastRequest again = Bed::Text(u8"Hello again");
    again.Key = core::String(u8"hello");
    again.Classes = core::String(u8"still");
    (void)bed.host->Post(core::Move(again));
    CHECK(card->HasClass(SV(u8"still")));
    CHECK_FALSE(card->HasClass(SV(u8"pop")));
    CHECK_FALSE(card->HasClass(SV(u8"celebrate")));
}

TEST_CASE("toast: a host markup places")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<foundation::gui::Node> made = loader.LoadFromString(SV(u8R"(<Panel><ToastHost/></Panel>)"));
    REQUIRE(made);
    REQUIRE(made->ChildCount() == 1);
    CHECK(core::Cast<ToastHost>(made->GetChildAt(0)) != nullptr);
}

TEST_CASE("toast: dismissed, it fades out through the sheet's transition and goes when that ends; a `still` one at the next update")
{
    Bed bed;
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(DefaultThemeCSS()));
    styles.ApplyTree(*bed.root);
    const auto frame = [&](float seconds)
    {
        bed.root->GetContext().Update(core::Duration::FromSeconds(seconds));
        styles.ApplyTree(*bed.root);
    };
    const ToastId id = bed.host->Post(Bed::Text(u8"Fading"));
    core::RefPtr<ToastCard> card(bed.host->GetCard(id)); // held: the host lets it go when it has left
    REQUIRE(card);
    for (int i = 0; i < 4; ++i)
        frame(0.1f); // in, and settled
    REQUIRE(card->GetAlpha() == doctest::Approx(1.0f));
    CHECK(bed.host->Dismiss(id));
    CHECK(card->IsLeaving());
    CHECK(bed.host->ShownCount() == 0);
    frame(0.0f); // :leaving shown: the fade starts
    frame(0.07f);
    CHECK(card->GetParent() == bed.host.Get()); // still fading
    CHECK(card->GetAlpha() < 0.95f);
    frame(0.2f);
    CHECK(card->GetParent() == nullptr);

    ToastRequest still = Bed::Text(u8"Still");
    still.Classes = core::String(u8"still");
    const ToastId quiet = bed.host->Post(core::Move(still));
    core::RefPtr<ToastCard> quietCard(bed.host->GetCard(quiet));
    REQUIRE(quietCard);
    frame(0.0f);
    frame(0.0f);
    CHECK(bed.host->Dismiss(quiet));
    frame(0.0f); // nothing moves it: the style pass lets it go
    frame(0.0f);
    CHECK(quietCard->GetParent() == nullptr);
}
