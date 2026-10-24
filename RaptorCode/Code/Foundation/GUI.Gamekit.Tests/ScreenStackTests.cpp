// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Gamekit - the screen stack (K4 of Specs/gui-lab-evolution-3.md): push, pop, replace and
// clear; covering, blocking and pausing; focus per screen; `back` from the keys and the pad; the
// lifecycle events; screens from markup and documents. Its script surface is Integration.ScriptFacades'.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.image;
import foundation.vg;
import foundation.vg.svg;
import foundation.gui;
import foundation.gui.gamekit;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ScreenStack> stack = core::MakeRef<ScreenStack>(core::DefaultAllocator());

        Bed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            stack->SetSize(core::Float2{400.0f, 300.0f});
            root->AddChild(stack.Get());
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        void Layout() { (void)root->UpdateLayout(); }
        void Frame() { root->GetContext().Update(core::Duration{}); }
        void Escape() { (void)d().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape)); }
        // A screen with a button `id` 80 x 30 at (x, 10).
        core::RefPtr<Screen> MakeScreen(const char8_t* id, float x = 10.0f)
        {
            auto screen = core::MakeRef<Screen>(core::DefaultAllocator());
            auto button = core::MakeRef<Button>(core::DefaultAllocator());
            button->SetId(SV(id));
            button->SetPosition(core::Float2{x, 10.0f});
            button->SetSize(core::Float2{80.0f, 30.0f});
            screen->AddChild(button.Get());
            return screen;
        }
        [[nodiscard]] core::StringView Focused()
        {
            const UIWidget* focus = core::Cast<UIWidget>(d().GetFocusNode());
            return focus != nullptr ? focus->GetId() : SV(u8"");
        }
    };

    // Records the named events a node is told, as "name" or "name:detail".
    struct Log
    {
        core::Array<core::String> Heard;
        void Watch(Node& node, const char8_t* name)
        {
            (void)node.AddNamedListener(SV(name), [this](const Event& e)
                                            {
                                                const NamedEvent& named = static_cast<const NamedEvent&>(e);
                                                core::String line(named.Name);
                                                if (named.Detail.Size() != 0)
                                                {
                                                    line.Append(u8":");
                                                    line.Append(named.Detail);
                                                }
                                                Heard.PushBack(core::Move(line));
                                            });
        }
        template <typename... Names>
        void Watch(Node& node, const char8_t* first, Names... rest)
        {
            Watch(node, first);
            (Watch(node, rest), ...);
        }
    };
}

TEST_CASE("screens: a push shows on top and takes the focus; a blocking top makes those under it inert")
{
    Bed bed;
    auto title = bed.MakeScreen(u8"play");
    auto pause = bed.MakeScreen(u8"resume", 200.0f);
    CHECK(bed.stack->Push(*title) == title.Get());
    CHECK(bed.Focused() == SV(u8"play"));
    CHECK(bed.stack->Push(*pause) == pause.Get());
    CHECK(bed.stack->Count() == 2u);
    CHECK(bed.stack->Top() == pause.Get());
    CHECK(bed.Focused() == SV(u8"resume"));
    CHECK(title->IsInert());
    CHECK_FALSE(pause->IsInert());
    CHECK(title->IsVisible()); // blocked, not covered: it still shows
    bed.Layout();
    int clicks = 0;
    core::Cast<Button>(title->GetChildAt(0))->SetOnClick([&clicks]() { ++clicks; });
    bed.d().InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    bed.d().InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(clicks == 0);
    CHECK(bed.stack->Push(*pause) == nullptr); // on the stack already
}

TEST_CASE("screens: a pop refocuses the screen under it where its focus was; a covering screen hides those under it")
{
    Bed bed;
    auto menu = bed.MakeScreen(u8"first");
    auto second = core::MakeRef<Button>(core::DefaultAllocator());
    second->SetId(SV(u8"second"));
    second->SetPosition(core::Float2{10.0f, 60.0f});
    second->SetSize(core::Float2{80.0f, 30.0f});
    menu->AddChild(second.Get());
    Log log;
    log.Watch(*menu, u8"screenhidden", u8"screenrevealed");
    (void)bed.stack->Push(*menu);
    bed.Layout();
    (void)bed.d().MoveFocus(NavDirection::Down);
    CHECK(bed.Focused() == SV(u8"second"));
    auto options = bed.MakeScreen(u8"volume");
    options->SetCovers(true);
    (void)bed.stack->Push(*options);
    CHECK_FALSE(menu->IsVisible());
    CHECK(menu->IsCovered());
    CHECK(bed.stack->Pop());
    CHECK(menu->IsVisible());
    CHECK(bed.Focused() == SV(u8"second")); // where it was, not its first
    REQUIRE(log.Heard.Size() == 2u);
    CHECK(log.Heard[0] == SV(u8"screenhidden"));
    CHECK(log.Heard[1] == SV(u8"screenrevealed"));
}

TEST_CASE("screens: a HUD that does not block leaves the game screen under it live")
{
    Bed bed;
    auto game = bed.MakeScreen(u8"world");
    auto hud = core::MakeRef<Screen>(core::DefaultAllocator());
    hud->SetBlocks(false);
    (void)bed.stack->Push(*game);
    (void)bed.stack->Push(*hud);
    CHECK_FALSE(game->IsInert());
    CHECK(bed.stack->WantsGameInput(core::Float2{350.0f, 250.0f}));
    auto pause = bed.MakeScreen(u8"resume");
    (void)bed.stack->Push(*pause);
    CHECK(game->IsInert());
    CHECK(hud->IsInert());
    CHECK_FALSE(bed.stack->WantsGameInput(core::Float2{350.0f, 250.0f}));
}

TEST_CASE("screens: back pops the top, never the last, not one that keeps it, not in the frame that pushed it")
{
    Bed bed;
    auto title = bed.MakeScreen(u8"play");
    auto options = bed.MakeScreen(u8"volume");
    (void)bed.stack->Push(*title);
    bed.Frame();
    bed.Escape();
    CHECK(bed.stack->Count() == 1u); // the last stays
    (void)bed.stack->Push(*options);
    bed.Escape(); // the frame that pushed it
    CHECK(bed.stack->Count() == 2u);
    bed.Frame();
    bed.d().InjectPadButton(PadButton::East);
    CHECK(bed.stack->Count() == 1u);
    CHECK(bed.Focused() == SV(u8"play"));

    auto keeps = bed.MakeScreen(u8"stay");
    keeps->SetBack(core::String(u8"none"));
    (void)bed.stack->Push(*keeps);
    bed.Frame();
    bed.Escape();
    CHECK(bed.stack->Top() == keeps.Get());
}

TEST_CASE("screens: the top screen's own back handler takes it before the stack")
{
    Bed bed;
    auto game = bed.MakeScreen(u8"world");
    auto pause = bed.MakeScreen(u8"resume");
    (void)bed.stack->Push(*game);
    bed.Frame();
    // The game screen's Escape opens the pause screen, rather than popping anything.
    (void)game->OnCommand(SV(kBackCommand), [&](CommandEvent&) { (void)bed.stack->Push(*pause); });
    bed.Escape();
    CHECK(bed.stack->Top() == pause.Get());
    CHECK(bed.stack->Count() == 2u);
    bed.Frame();
    bed.Escape(); // the pause screen has no handler: the stack pops it
    CHECK(bed.stack->Top() == game.Get());
}

TEST_CASE("screens: a screen with nothing focusable takes the focus itself, so back and its commands start there")
{
    Bed bed;
    auto title = bed.MakeScreen(u8"play");
    auto hud = core::MakeRef<Screen>(core::DefaultAllocator()); // nothing focusable on it
    (void)bed.stack->Push(*title);
    (void)bed.stack->Push(*hud);
    CHECK(bed.d().GetFocusNode() == hud.Get());
    int paused = 0;
    (void)hud->OnCommand(SV(kBackCommand), [&paused](CommandEvent&) { ++paused; });
    bed.Frame();
    bed.Escape();
    CHECK(paused == 1); // the HUD's own back: it opens a pause screen in a game
    CHECK(bed.stack->Top() == hud.Get());
}

TEST_CASE("screens: a press on a screen's empty area keeps the focus, so back still reaches it")
{
    Bed bed;
    auto title = bed.MakeScreen(u8"play");
    auto options = bed.MakeScreen(u8"volume");
    (void)bed.stack->Push(*title);
    (void)bed.stack->Push(*options);
    bed.Frame();
    bed.Layout();
    bed.d().InjectMouseDown(core::Float2{300.0f, 250.0f}, MouseButton::Left);
    bed.d().InjectMouseUp(core::Float2{300.0f, 250.0f}, MouseButton::Left);
    CHECK(bed.Focused() == SV(u8"volume"));
    bed.Escape();
    CHECK(bed.stack->Top() == title.Get());
}

TEST_CASE("screens: the stack reports the pause; the game decides what it means")
{
    Bed bed;
    core::Array<bool> told;
    bed.stack->SetOnPausedChanged([&told](bool paused) { told.PushBack(paused); });
    Log log;
    log.Watch(*bed.stack, u8"pausechange");
    auto game = bed.MakeScreen(u8"world");
    auto pause = bed.MakeScreen(u8"resume");
    pause->SetPauses(true);
    (void)bed.stack->Push(*game);
    CHECK_FALSE(bed.stack->IsPaused());
    (void)bed.stack->Push(*pause);
    CHECK(bed.stack->IsPaused());
    (void)bed.stack->Pop();
    CHECK_FALSE(bed.stack->IsPaused());
    REQUIRE(told.Size() == 2u);
    CHECK(told[0]);
    CHECK_FALSE(told[1]);
    REQUIRE(log.Heard.Size() == 2u);
    CHECK(log.Heard[0] == SV(u8"pausechange:paused"));
    CHECK(log.Heard[1] == SV(u8"pausechange:running"));
}

TEST_CASE("screens: lifecycle events, replace and clear")
{
    Bed bed;
    auto a = bed.MakeScreen(u8"a");
    auto b = bed.MakeScreen(u8"b");
    auto c = bed.MakeScreen(u8"c");
    Log log;
    log.Watch(*a, u8"screenenter", u8"screenshown", u8"screenleave");
    log.Watch(*b, u8"screenenter", u8"screenleave");
    (void)bed.stack->Push(*a);
    (void)bed.stack->Replace(*b);
    CHECK(bed.stack->Count() == 1u);
    CHECK(bed.stack->Top() == b.Get());
    CHECK(a->GetStack() == nullptr);
    CHECK(a->IsLeaving()); // no style pass here: it goes at the next update
    bed.Frame();
    CHECK(a->GetParent() == nullptr);
    (void)bed.stack->Push(*c);
    bed.stack->Clear();
    CHECK(bed.stack->Count() == 0u);
    CHECK(bed.stack->Top() == nullptr);
    CHECK_FALSE(bed.stack->Pop());
    REQUIRE(log.Heard.Size() == 5u);
    CHECK(log.Heard[0] == SV(u8"screenenter"));
    CHECK(log.Heard[1] == SV(u8"screenshown"));
    CHECK(log.Heard[2] == SV(u8"screenleave"));
    CHECK(log.Heard[3] == SV(u8"screenenter"));
    CHECK(log.Heard[4] == SV(u8"screenleave"));
}

TEST_CASE("screens: content that is not a screen is pushed in one; a popped screen with an exit still draws, off the stack")
{
    Bed bed;
    StyleManager styles(CSSParser::Parse(SV(u8"screen { opacity: 1; transition: opacity 0.5s linear; } screen:leaving { opacity: 0; }")));
    styles.ApplyTree(*bed.root);
    auto first = bed.MakeScreen(u8"first");
    (void)bed.stack->Push(*first);
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    Screen* wrapped = bed.stack->Push(*label);
    REQUIRE(wrapped != nullptr);
    CHECK(label->GetParent() == wrapped);
    styles.ApplyTree(*bed.root);
    CHECK(bed.stack->Pop());
    CHECK(bed.stack->Count() == 1u);
    CHECK(wrapped->GetParent() == bed.stack.Get()); // leaving: it still draws
    CHECK(wrapped->IsLeaving());
    CHECK(bed.Focused() == SV(u8"first"));
    styles.ApplyTree(*bed.root);
    for (int i = 0; i < 3; ++i)
    {
        bed.root->GetContext().Update(core::Duration::FromSeconds(0.25));
        styles.ApplyTree(*bed.root);
    }
    CHECK(wrapped->GetParent() == nullptr);
}

namespace
{
    // Documents by path, for PushDocument.
    class Documents final : public IResourceProvider
    {
    public:
        Documents() : IResourceProvider(core::DefaultAllocator()) {}
        const foundation::image::ImageData* LoadImage(core::StringView) override { return nullptr; }
        bool LoadText(core::StringView path, core::String& out) override
        {
            if (path != SV(u8"pause.xml"))
                return false;
            out = core::String(u8"<Screen pauses=\"true\" covers=\"true\"><Button id=\"resume\"/><Label id=\"who\" text=\"{{name}}\"/></Screen>");
            return true;
        }
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView) override { return nullptr; }
    };
}

TEST_CASE("screens: from markup, the screens a stack holds are pushed in order; a document is loaded fresh, bound to the data")
{
    RegisterGuiElements();
    RegisterGamekitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(
        SV(u8"<Screens><Screen id=\"game\" blocks=\"false\"/><Screen id=\"menu\" covers=\"true\" back=\"none\"/></Screens>"));
    ScreenStack* stack = core::Cast<ScreenStack>(made.Get());
    REQUIRE(stack != nullptr);
    REQUIRE(stack->Count() == 2u);
    CHECK(stack->At(0)->GetId() == SV(u8"game"));
    CHECK_FALSE(stack->At(0)->GetBlocks());
    CHECK(stack->Top()->GetId() == SV(u8"menu"));
    CHECK(stack->Top()->GetCovers());
    CHECK_FALSE(stack->Top()->PopsOnBack());
    CHECK(stack->At(0)->IsCovered());

    Bed bed;
    Documents documents;
    bed.root->GetContext().SetResourceProvider(&documents);
    bed.root->GetContext().GetData().Set(SV(u8"name"), core::Variant::From(core::String(u8"Ada")));
    Screen* first = bed.stack->PushDocument(SV(u8"pause.xml"));
    Screen* second = bed.stack->PushDocument(SV(u8"pause.xml"));
    REQUIRE(first != nullptr);
    REQUIRE(second != nullptr);
    CHECK(first != second); // fresh each time
    CHECK(second->GetPauses());
    CHECK(bed.stack->IsPaused());
    CHECK(bed.Focused() == SV(u8"resume"));
    bed.Frame();
    CHECK(core::Cast<Label>(core::Cast<UIWidget>(second)->GetChildAt(1))->GetText() == SV(u8"Ada"));
    CHECK(bed.stack->PushDocument(SV(u8"missing.xml")) == nullptr);
}

namespace
{
    // A stack under a sheet: screens enter from transparent and leave to it, over 0.4 s.
    struct StyledBed : Bed
    {
        StyleManager styles{CSSParser::Parse(SV(u8"screen { opacity: 1; transition: opacity 0.4s linear; }"
                                                 u8"screen:entering { opacity: 0; } screen:leaving { opacity: 0; }"))};
        StyledBed() { styles.ApplyTree(*root); }
        void Frame(double seconds)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            styles.ApplyTree(*root);
        }
    };
}

TEST_CASE("screens: a pushed screen is :entering while its sheet's entrance plays, and shown once it has")
{
    StyledBed bed;
    auto title = bed.MakeScreen(u8"play");
    Log log;
    log.Watch(*title, u8"screenenter", u8"screenshown");
    (void)bed.stack->Push(*title);
    CHECK(title->IsEntering());
    CHECK(bed.Focused() == SV(u8"play")); // it takes the focus at once, entrance or not
    bed.Frame(0.0);
    CHECK(title->GetAlpha() == doctest::Approx(0.0f));
    bed.Frame(0.0);
    bed.Frame(0.2);
    CHECK(title->GetAlpha() == doctest::Approx(0.5f));
    REQUIRE(log.Heard.Size() == 1u);
    bed.Frame(0.2);
    CHECK(title->GetAlpha() == doctest::Approx(1.0f));
    REQUIRE(log.Heard.Size() == 2u);
    CHECK(log.Heard[1] == SV(u8"screenshown"));
}

TEST_CASE("screens: a pop during an entrance leaves from where it is; the screen under it shows and takes the focus at once")
{
    StyledBed bed;
    auto title = bed.MakeScreen(u8"play");
    (void)bed.stack->Push(*title);
    for (int i = 0; i < 4; ++i)
        bed.Frame(0.2);
    auto options = bed.MakeScreen(u8"volume");
    options->SetCovers(true);
    Log log;
    log.Watch(*options, u8"screenshown");
    (void)bed.stack->Push(*options);
    CHECK_FALSE(title->IsVisible());
    bed.Frame(0.0);
    bed.Frame(0.0);
    bed.Frame(0.2); // half in
    REQUIRE(options->GetAlpha() == doctest::Approx(0.5f));
    CHECK(bed.stack->Pop());
    CHECK(title->IsVisible()); // shown as the cover starts leaving
    CHECK(bed.Focused() == SV(u8"play"));
    bed.Frame(0.0);
    bed.Frame(0.2);
    CHECK(options->GetAlpha() == doctest::Approx(0.25f)); // from 0.5, not from 1
    bed.Frame(0.2);
    CHECK(options->GetParent() == nullptr);
    CHECK(log.Heard.IsEmpty());
}
