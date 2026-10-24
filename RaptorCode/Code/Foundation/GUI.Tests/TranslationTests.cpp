// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - translation (E9a of Specs/gui-lab-evolution.md): markup's @key resolves through the
// context's Localization (foundation.i18n), follows a language change, takes a plural count and
// arguments from the GUI's data, waits for a node to join a GUI, stops under auto-translate off;
// :lang() matches a node's language.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.i18n;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace i18n = foundation::i18n;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Frame() { return core::Duration::FromSeconds(1.0 / 60.0); }

    // English and Portuguese texts, with English's plural rule.
    struct Texts
    {
        i18n::StringTable table;
        i18n::Localization loc;
        Texts()
        {
            REQUIRE(table.Set(SV(u8"menu.play"), SV(u8"en"), SV(u8"Play")));
            REQUIRE(table.Set(SV(u8"menu.play"), SV(u8"pt"), SV(u8"Jogar")));
            REQUIRE(table.Set(SV(u8"menu.tip"), SV(u8"en"), SV(u8"Start the game")));
            REQUIRE(table.Set(SV(u8"field.hint"), SV(u8"en"), SV(u8"Your name")));
            REQUIRE(table.Set(SV(u8"greet"), SV(u8"en"), SV(u8"Hello, {0}")));
            REQUIRE(table.SetPluralRule(SV(u8"en"), SV(u8"one: n = 1")));
            REQUIRE(table.SetPlural(SV(u8"lives"), SV(u8"en"), i18n::PluralCategory::One, SV(u8"{0} life")));
            REQUIRE(table.SetPlural(SV(u8"lives"), SV(u8"en"), i18n::PluralCategory::Other, SV(u8"{0} lives")));
            loc.AddTable(&table);
        }
    };

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Node> Load(const char8_t* markup)
        {
            RegisterGuiElements();
            static const ElementSet elements = ElementSet::All();
            MarkupLoader loader(elements, core::DefaultAllocator());
            loader.SetDataModel(root->GetContext().GetDataRef());
            core::RefPtr<Node> node = loader.LoadFromString(core::StringView(markup));
            return node;
        }
        void Step() { root->GetContext().Update(Frame()); }
    };
    Node* Find(Node& node, core::StringView id)
    {
        if (const UIWidget* w = core::Cast<UIWidget>(&node); w != nullptr && w->GetId() == id)
            return &node;
        for (core::usize i = 0; i < node.ChildCount(); ++i)
            if (Node* found = Find(*node.GetChildAt(i), id))
                return found;
        return nullptr;
    }
}

TEST_CASE("translation: markup's @key resolves through the context's Localization and follows a language change")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    core::RefPtr<Node> page = bed.Load(u8R"(
        <Panel>
            <Label id="title" text="@menu.play"/>
            <Button id="go" text="@menu.play" tooltip="@menu.tip"/>
            <TextField id="name" placeholder="@field.hint"/>
            <Label id="literal" text="@@home"/>
            <Label id="plain" text="Plain words"/>
        </Panel>)");
    REQUIRE(page);
    bed.root->AddChild(page.Get());
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"title")))->GetText() == SV(u8"Play"));
    CHECK(core::Cast<Button>(Find(*page, SV(u8"go")))->GetText() == SV(u8"Play"));
    CHECK(core::Cast<UIWidget>(Find(*page, SV(u8"go")))->GetTooltipText() == core::String(u8"Start the game"));
    CHECK(core::Cast<TextField>(Find(*page, SV(u8"name")))->GetPlaceholder() == core::String(u8"Your name"));
    CHECK(core::Cast<Label>(Find(*page, SV(u8"literal")))->GetText() == SV(u8"@home")); // @@ is a literal @
    CHECK(core::Cast<Label>(Find(*page, SV(u8"plain")))->GetText() == SV(u8"Plain words"));
    CHECK(Find(*page, SV(u8"title"))->TranslationKey(SV(u8"text")) != nullptr);

    texts.loc.SetLanguage(SV(u8"pt"));
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"title")))->GetText() == SV(u8"Jogar"));
    CHECK(core::Cast<UIWidget>(Find(*page, SV(u8"go")))->GetTooltipText() == core::String(u8"Start the game")); // English's, the fallback

    bed.root->GetContext().SetLocalization(nullptr); // none: a key shows as itself
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"title")))->GetText() == SV(u8"menu.play"));
}

TEST_CASE("translation: a count and arguments from the GUI's data pick the plural form and fill it")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    DataModel& data = bed.root->GetContext().GetData();
    data.Set(SV(u8"lives"), core::Variant::From<core::i32>(1));
    data.Set(SV(u8"player"), core::Variant::From<core::String>(core::String(u8"Ana")));
    core::RefPtr<Node> page = bed.Load(u8R"(
        <Panel>
            <Label id="lives" text="@lives" text-count="{{lives}}"/>
            <Label id="greet" text="@greet" text-args="{{player}}"/>
        </Panel>)");
    bed.root->AddChild(page.Get());
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"lives")))->GetText() == SV(u8"1 life"));
    CHECK(core::Cast<Label>(Find(*page, SV(u8"greet")))->GetText() == SV(u8"Hello, Ana"));
    data.Set(SV(u8"lives"), core::Variant::From<core::i32>(3));
    data.Set(SV(u8"player"), core::Variant::From<core::String>(core::String(u8"Rui")));
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"lives")))->GetText() == SV(u8"3 lives"));
    CHECK(core::Cast<Label>(Find(*page, SV(u8"greet")))->GetText() == SV(u8"Hello, Rui"));
}

TEST_CASE("translation: a node made before it joins a GUI resolves when it joins; auto-translate off keeps keys")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    core::RefPtr<Node> page = bed.Load(u8R"(
        <Panel>
            <Label id="title" text="@menu.play"/>
            <Panel id="raw" auto-translate="off">
                <Label id="inside" text="@menu.play"/>
            </Panel>
        </Panel>)");
    CHECK(core::Cast<Label>(Find(*page, SV(u8"title")))->GetText() == SV(u8"menu.play")); // in no GUI yet
    bed.root->AddChild(page.Get());
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"title")))->GetText() == SV(u8"Play"));
    // auto-translate is set by the style pass (an inline style); set it here as that pass would.
    Find(*page, SV(u8"raw"))->SetAutoTranslate(Node::AutoTranslate::Off);
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"inside")))->GetText() == SV(u8"menu.play"));
    Find(*page, SV(u8"raw"))->SetAutoTranslate(Node::AutoTranslate::Inherit);
    bed.Step();
    CHECK(core::Cast<Label>(Find(*page, SV(u8"inside")))->GetText() == SV(u8"Play"));
}

TEST_CASE("translation: a property not marked translatable takes @ literally")
{
    Bed bed;
    core::RefPtr<Node> page = bed.Load(u8R"(<Panel id="@not-a-key"/>)");
    CHECK(core::Cast<UIWidget>(page.Get())->GetId() == SV(u8"@not-a-key"));
}

TEST_CASE("translation: :lang() matches a node's language, its own or the GUI's, and a language change restyles")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    auto page = core::MakeRef<Panel>(core::DefaultAllocator());
    bed.root->AddChild(page.Get());
    auto arabic = core::MakeRef<Panel>(core::DefaultAllocator());
    arabic->SetLang(core::String(u8"ar-EG"));
    page->AddChild(arabic.Get());
    auto inside = core::MakeRef<Panel>(core::DefaultAllocator());
    arabic->AddChild(inside.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"panel { opacity: 1; } panel:lang(pt) { opacity: 0.5; } panel:lang(ar) { opacity: 0.25; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(page->GetAlpha() == doctest::Approx(1.0f)); // English
    CHECK(arabic->GetAlpha() == doctest::Approx(0.25f));
    CHECK(inside->GetAlpha() == doctest::Approx(0.25f)); // inherited
    CHECK(inside->Language() == core::String(u8"ar-EG"));
    texts.loc.SetLanguage(SV(u8"pt-BR"));
    styles.ApplyTree(*bed.root.Get());
    CHECK(page->GetAlpha() == doctest::Approx(0.5f)); // pt-BR under :lang(pt)
    CHECK(arabic->GetAlpha() == doctest::Approx(0.25f));
}

TEST_CASE("translation: an attribute ending in -count or -args is the widget's own unless its property is an @key")
{
    Bed bed;
    core::RefPtr<Node> page = bed.Load(u8R"(<Panel id="box" animation-iteration-count="3" tooltip-args="kept"/>)");
    REQUIRE(page);
    const UINode* node = core::Cast<UINode>(page.Get());
    bool count = false, args = false;
    for (const InlineStyleDeclaration& d : node->GetInlineStyle())
    {
        count = count || d.Name == core::String(u8"animation-iteration-count");
        args = args || d.Name == core::String(u8"tooltip-args");
    }
    CHECK(count); // not taken for a translation's count
    CHECK(args);  // tooltip is no @key here
}

TEST_CASE("translation: a property markup names by its CSS name takes @key and {{}} by that name")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    bed.root->GetContext().GetData().Set(SV(u8"who"), core::Variant::From<core::String>(core::String(u8"Ana")));
    core::RefPtr<Node> page = bed.Load(u8R"(
        <Panel>
            <Button id="go" aria-label="@menu.play"/>
            <Button id="named" aria-label="{{who}}"/>
        </Panel>)");
    bed.root->AddChild(page.Get());
    bed.Step();
    CHECK(core::Cast<UIWidget>(Find(*page, SV(u8"go")))->GetAccessLabel() == core::String(u8"Play"));
    CHECK(core::Cast<UIWidget>(Find(*page, SV(u8"named")))->GetAccessLabel() == core::String(u8"Ana"));
    CHECK(Find(*page, SV(u8"go"))->TranslationKey(SV(u8"ariaLabel")) != nullptr); // recorded by its own name
}

TEST_CASE("translation: binding a property again replaces its binding, a translation's included")
{
    Texts texts;
    Bed bed;
    bed.root->GetContext().SetLocalization(&texts.loc);
    DataModel& data = bed.root->GetContext().GetData();
    data.Set(SV(u8"a"), core::Variant::From<core::String>(core::String(u8"first")));
    data.Set(SV(u8"b"), core::Variant::From<core::String>(core::String(u8"second")));
    auto label = core::MakeRef<Label>(core::DefaultAllocator());
    bed.root->AddChild(label.Get());
    REQUIRE(label->BindTranslation(SV(u8"text"), SV(u8"menu.play"), bed.root->GetContext().GetDataRef(), {}, {}));
    const core::usize bindings = label->BindingCount();
    REQUIRE(label->BindData(SV(u8"text"), bed.root->GetContext().GetDataRef(), SV(u8"a")));
    REQUIRE(label->BindData(SV(u8"text"), bed.root->GetContext().GetDataRef(), SV(u8"b")));
    bed.Step();
    CHECK(label->GetText() == SV(u8"second"));
    CHECK(label->TranslationKey(SV(u8"text")) == nullptr); // no longer translated
    data.Set(SV(u8"a"), core::Variant::From<core::String>(core::String(u8"changed")));
    texts.loc.SetLanguage(SV(u8"pt"));
    bed.Step();
    CHECK(label->GetText() == SV(u8"second")); // neither the old data binding nor the translation runs
    CHECK(label->BindingCount() <= bindings + 1); // the data binding, and its write-back at most
}
