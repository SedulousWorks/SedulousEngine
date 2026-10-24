// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - MarkupLoader tests: inflate a widget tree from XML - element -> widget,
// nesting -> children, id/class -> identity, claimed attributes (text/orientation) structural,
// and everything else applied as inline CSS through the StyleApplier.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<Node> Load(const char8_t* markup)
    {
        RegisterGuiElements();
        static const ElementSet elements = ElementSet::All();
        MarkupLoader loader(elements, foundation::core::DefaultAllocator());
        return loader.LoadFromString(core::StringView(markup));
    }
}

TEST_CASE("markup: inflates a nested tree with identity + structural attributes")
{
    auto root = Load(u8R"(
        <Panel flex-direction="row" gap="6" id="root">
            <Label text="Title" text-align="center"/>
            <Button text="OK" class="accent primary"/>
        </Panel>
    )");
    REQUIRE(root.Get() != nullptr);

    auto* layout = core::Cast<Panel>(root.Get());
    REQUIRE(layout != nullptr);
    CHECK(layout->GetId() == SV(u8"root"));
    CHECK(layout->GetLayoutStyle().Direction == FlexDirection::Row);
    CHECK(layout->GetLayoutStyle().ColumnGap == doctest::Approx(6.0f));
    REQUIRE(layout->ChildCount() == 2);

    auto* title = core::Cast<Label>(layout->GetChildAt(0));
    REQUIRE(title != nullptr);
    CHECK(title->GetText() == SV(u8"Title"));
    CHECK(title->GetTextAlignH() == TextHAlign::Center);

    auto* button = core::Cast<Button>(layout->GetChildAt(1));
    REQUIRE(button != nullptr);
    CHECK(button->GetText() == SV(u8"OK"));
    CHECK(button->HasClass(SV(u8"accent")));
    CHECK(button->HasClass(SV(u8"primary")));
}

TEST_CASE("markup: unclaimed attributes are applied as inline CSS")
{
    auto root = Load(
        u8R"(<Label text="Hi" width="120" height="30" background-color="#ff0000" padding="4"/>)");
    REQUIRE(root.Get() != nullptr);
    auto* label = core::Cast<Label>(root.Get());
    REQUIRE(label != nullptr);
    (void)label->UpdateLayout();

    CHECK(label->GetSize().x == doctest::Approx(120.0f));
    CHECK(label->GetSize().y == doctest::Approx(30.0f));
    CHECK(label->GetPadding().Left == doctest::Approx(4.0f));
    CHECK(label->GetBox().BackgroundColor.r == doctest::Approx(1.0f));
}

TEST_CASE("markup: CSS length units work in markup (via the applier)")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    LengthContext ctx;
    ctx.RootFontSize = 10.0f; // 2rem -> 20
    MarkupLoader loader(elements, foundation::core::DefaultAllocator(), nullptr, nullptr, ctx);
    auto root = loader.LoadFromString(SV(u8R"(<Button width="2rem"/>)"));
    REQUIRE(root.Get() != nullptr);
    (void)root->UpdateLayout();
    CHECK(core::Cast<Button>(root.Get())->GetSize().x == doctest::Approx(20.0f));
}

TEST_CASE("markup: an unknown root element yields null; unknown children are skipped")
{
    CHECK(Load(u8R"(<NotAWidget/>)").Get() == nullptr);

    auto root =
        Load(u8R"(<Panel><Label text="a"/><Bogus/><Label text="b"/></Panel>)");
    REQUIRE(root.Get() != nullptr);
    CHECK(root->ChildCount() == 2); // the <Bogus/> child was skipped
}

TEST_CASE("markup: a parse error yields null")
{
    CHECK(Load(u8R"(<Panel><Label text="x")").Get() == nullptr); // unterminated
}

TEST_CASE("markup: {{name}} binds to the GUI's data model, two-way where the user changes it")
{
    RegisterGuiElements();
    auto scene = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    DataModel& data = scene->GetContext().GetData();
    data.Set(SV(u8"score"), core::Variant::From<core::i32>(7));
    data.Set(SV(u8"volume"), core::Variant::From<core::f64>(0.5));
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    loader.SetDataModel(scene->GetContext().GetDataRef());
    auto tree = loader.LoadFromString(SV(u8R"(
        <Panel>
            <Label text="Score: {{ score }} of {{max}}"/>
            <Slider value="{{volume}}"/>
            <Label text="{{volume}}"/>
            <Label text="{{unclosed"/>
        </Panel>
    )"));
    REQUIRE(tree.Get() != nullptr);
    scene->AddChild(tree.Get());
    auto* score = core::Cast<Label>(tree->GetChildAt(0));
    auto* slider = core::Cast<Slider>(tree->GetChildAt(1));
    auto* volume = core::Cast<Label>(tree->GetChildAt(2));
    auto* literal = core::Cast<Label>(tree->GetChildAt(3));
    REQUIRE((score != nullptr && slider != nullptr && volume != nullptr && literal != nullptr));
    CHECK(score->GetText() == SV(u8"Score: 7 of ")); // max unset: empty, and followed
    CHECK(slider->GetValue() == doctest::Approx(0.5f));
    CHECK(volume->GetText() == SV(u8"0.5"));
    CHECK(literal->GetText() == SV(u8"{{unclosed")); // malformed: as written
    CHECK(volume->BindingCount() == 1u); // a label's text does not write back

    data.Set(SV(u8"max"), core::Variant::From<core::i32>(10));
    slider->SetValue(0.25f); // the user drags it
    scene->GetContext().Update(core::Duration::FromSeconds(0.016)); // the write-back's followers run in the same flush
    CHECK(score->GetText() == SV(u8"Score: 7 of 10"));
    CHECK(volume->GetText() == SV(u8"0.25"));
}

TEST_CASE("markup: widget properties reflected with CSS names are markup attributes")
{
    auto tree = Load(u8R"(
        <Panel>
            <TextField placeholder="Your name" max-length="12" tooltip="Who are you?"/>
            <Panel display="grid" grid-template-columns="1fr 1fr 1fr" gap="6"/>
            <ScrollView/>
            <ComboBox items="Apple | Banana|Cherry"/>
            <ListBox items="One|Two"/>
            <Window title="Tools"/>
        </Panel>
    )");
    REQUIRE(tree.Get() != nullptr);
    REQUIRE(tree->ChildCount() == 6u);
    auto* field = core::Cast<TextField>(tree->GetChildAt(0));
    REQUIRE(field != nullptr);
    CHECK(field->GetPlaceholder() == SV(u8"Your name"));
    CHECK(field->GetMaxLength() == 12u); // a whole number, converted from the attribute's text
    CHECK(field->GetTooltipText() == SV(u8"Who are you?"));
    auto* grid = core::Cast<Panel>(tree->GetChildAt(1)); // layout attributes are inline CSS
    REQUIRE(grid != nullptr);
    CHECK(grid->GetLayoutStyle().Kind == Display::Grid);
    CHECK(grid->GetLayoutStyle().Columns.Size() == 3u);
    CHECK(grid->GetLayoutStyle().RowGap == doctest::Approx(6.0f));
    CHECK(core::Cast<ScrollView>(tree->GetChildAt(2))->IsScrollContainer());
    auto* combo = core::Cast<ComboBox>(tree->GetChildAt(3)); // creatable by tag now
    REQUIRE(combo != nullptr);
    REQUIRE(combo->ItemCount() == 3u);
    CHECK(combo->GetItemsText() == core::String(u8"Apple|Banana|Cherry"));
    CHECK(core::Cast<ListBox>(tree->GetChildAt(4))->GetItem(1) == SV(u8"Two"));
    CHECK(core::Cast<Window>(tree->GetChildAt(5))->GetTitle() == SV(u8"Tools"));
}

TEST_CASE("markup: a scroller's and a window's children are their content")
{
    auto tree = Load(u8R"(
        <Panel>
            <ScrollView><Label text="scrolled"/></ScrollView>
            <Window><Label text="inside"/></Window>
        </Panel>
    )");
    REQUIRE(tree.Get() != nullptr);
    auto* scroll = core::Cast<ScrollView>(tree->GetChildAt(0));
    auto* window = core::Cast<Window>(tree->GetChildAt(1));
    REQUIRE((scroll != nullptr && window != nullptr));
    REQUIRE(scroll->ChildCount() == 1u);
    CHECK(core::Cast<Label>(scroll->GetChildAt(0))->GetText() == SV(u8"scrolled"));
    REQUIRE(window->GetContent()->ChildCount() == 1u);
}

TEST_CASE("markup: the text widgets' password, filter, length and rows are attributes, and rich text an element")
{
    auto tree = Load(u8R"(
        <Panel>
            <TextField password="true" input-filter="digits" max-length="4"/>
            <TextArea rows="6" read-only="true"/>
            <RichText text="[b]bold[/b]"/>
        </Panel>
    )");
    REQUIRE(tree.Get() != nullptr);
    auto* field = core::Cast<TextField>(tree->GetChildAt(0));
    REQUIRE(field != nullptr);
    CHECK(field->IsPassword());
    CHECK(field->GetInputFilterName() == SV(u8"digits"));
    CHECK(field->GetMaxLength() == 4u);
    auto* area = core::Cast<TextArea>(tree->GetChildAt(1));
    REQUIRE(area != nullptr);
    CHECK(area->GetRows() == 6);
    CHECK(area->IsReadOnly());
    auto* rich = core::Cast<RichText>(tree->GetChildAt(2));
    REQUIRE(rich != nullptr);
    CHECK(rich->IsRich());
    CHECK(rich->GetTextLayout().Document().Runs[0].Bold);
}

TEST_CASE("markup: a scroller may stick to its end")
{
    auto root = Load(u8R"(<ScrollView stick-to-end="true"/>)");
    REQUIRE(root.Get() != nullptr);
    CHECK(root->IsStickToEnd());
}

namespace
{
    // The GUI's warnings, kept for a test to read.
    struct WarningSink final : core::ILogSink
    {
        core::Array<core::String> Lines;
        void Write(core::LogLevel level, core::StringView category, core::StringView message) noexcept override
        {
            if (level == core::LogLevel::Warning && category == core::StringView(u8"GUI"))
                Lines.PushBack(core::String(message));
        }
    };
}

TEST_CASE("markup: an element or an attribute nothing takes is said, not dropped in silence")
{
    WarningSink sink;
    core::GlobalLogger().AddSink(&sink);
    RegisterGuiElements();
    const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> page = loader.LoadFromString(core::StringView(
        u8R"(<Panel padding="4" border="1px solid #fff" auto-translate="off" colour="red"><Lable text="x"/></Panel>)"));
    core::GlobalLogger().RemoveSink(&sink);
    REQUIRE(page);
    REQUIRE(sink.Lines.Size() == 2u); // colour, and <Lable>; the style property, the shorthand and the
                                      // reflected one pass
    bool colour = false, lable = false;
    for (const core::String& line : sink.Lines)
    {
        colour = colour || MarkupLoader::FindFrom(line.AsView(), core::StringView(u8"colour"), 0) < line.Size();
        lable = lable || MarkupLoader::FindFrom(line.AsView(), core::StringView(u8"Lable"), 0) < line.Size();
    }
    CHECK(colour);
    CHECK(lable);
}
