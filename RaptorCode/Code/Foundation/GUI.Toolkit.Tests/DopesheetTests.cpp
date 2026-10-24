// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the dopesheet (T5 of Specs/gui-lab-evolution-3.md): a timeline source's channels as rows
// folded by their paths' segments, a parent row showing the keys under it; keys selected by a click
// (a parent's selecting all under it at that time) or a box, moved in time through the source (on
// frames, kept in the clip, the selection following where the source put them, Escape giving it
// up), deleted, inserted by a double click; a CurveSet feeding a dopesheet and a curve view at once.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <initializer_list>
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::CurveKey Key(f32 time, f32 value)
    {
        return core::CurveKey{time, value, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
    }

    // A 660 by 200 dopesheet, names 160 wide, over 0 to 2 s at 250 px a second: time t on row r at
    // (160 + 250 t, 10 + 20 r). Its rows: Lamp, color, r, g, intensity, Camera, fov.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<TimeAxis> axis = core::MakeRef<TimeAxis>(core::DefaultAllocator());
        core::RefPtr<Dopesheet> sheet = core::MakeRef<Dopesheet>(core::DefaultAllocator());
        CurveSet clip;
        core::Array<CurveChange> commits{core::DefaultAllocator()};

        Bed()
        {
            root->SetSize(core::Float2{700.0f, 300.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            sheet->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(660.0f);
                s.Height = LayoutLength::Px(200.0f);
            });
            root->AddChild(sheet.Get());
            axis->SetDuration(2.0f);
            axis->SetPixelsPerSecond(250.0f);
            sheet->SetTimeAxis(axis);
            Add(u8"Lamp.color.r", {Key(0.2f, 1.0f), Key(1.0f, 0.0f)});
            Add(u8"Lamp.color.g", {Key(0.2f, 0.5f), Key(1.4f, 0.5f)});
            Add(u8"Lamp.intensity", {Key(0.6f, 3.0f)});
            Add(u8"Camera.fov", {Key(1.0f, 60.0f)});
            sheet->SetSource(&clip);
            clip.SetOnCommit([this](const CurveChange& change) { commits.PushBack(change); });
            (void)root->UpdateLayout();
        }
        ~Bed() { sheet->SetSource(nullptr); }
        void Add(const char8_t* path, std::initializer_list<core::CurveKey> keys)
        {
            CurveInfo info;
            info.Name = core::String(path);
            core::Array<core::CurveKey> list(core::DefaultAllocator());
            for (const core::CurveKey& key : keys)
                list.PushBack(key);
            clip.AddCurve(info, list.AsSpan());
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        static core::Float2 At(usize row, f32 t) { return core::Float2{160.0f + 250.0f * t, 10.0f + 20.0f * static_cast<f32>(row)}; }
        void Press(core::Float2 at, core::u32 modifiers = 0)
        {
            D().InjectMouseMove(at, modifiers);
            D().InjectMouseDown(at, MouseButton::Left, modifiers);
        }
        void Click(core::Float2 at, core::u32 modifiers = 0)
        {
            Press(at, modifiers);
            D().InjectMouseUp(at, MouseButton::Left, modifiers);
        }
        void Drag(core::Float2 from, core::Float2 to, core::u32 modifiers = 0)
        {
            Press(from, modifiers);
            D().InjectMouseMove(core::Float2{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f}, modifiers);
            D().InjectMouseMove(to, modifiers);
            D().InjectMouseUp(to, MouseButton::Left, modifiers);
        }
        void Pause()
        {
            D().InjectMouseMove(core::Float2{690.0f, 290.0f});
            D().InjectMouseDown(core::Float2{690.0f, 290.0f}, MouseButton::Left);
            D().InjectMouseUp(core::Float2{690.0f, 290.0f}, MouseButton::Left);
        }
        [[nodiscard]] f32 Time(usize channel, usize index) const { return clip.GetKeys(channel)[index].time; }
    };
}

TEST_CASE("Dopesheet: channels fold into rows by their paths' segments; a click on a name folds or opens it")
{
    Bed bed;
    const core::Array<DopesheetRow>& rows = bed.sheet->GetRows();
    REQUIRE(rows.Size() == 7);
    CHECK(rows[0].Path == core::String(u8"Lamp"));
    CHECK(rows[0].HasChildren);
    CHECK(rows[0].Channel == -1);
    CHECK(rows[1].Name == core::String(u8"color"));
    CHECK(rows[1].Depth == 1);
    CHECK(rows[2].Name == core::String(u8"r"));
    CHECK(rows[2].Channel == 0);
    CHECK(rows[4].Path == core::String(u8"Lamp.intensity"));
    CHECK(rows[4].Channel == 2);
    CHECK(rows[6].Path == core::String(u8"Camera.fov"));
    CHECK(bed.sheet->FindRow(SV(u8"Camera")) == 5);

    bed.Click(core::Float2{40.0f, 30.0f}); // "color"'s name
    CHECK(bed.sheet->IsFolded(SV(u8"Lamp.color")));
    CHECK(bed.sheet->GetRows().Size() == 5);
    CHECK(bed.sheet->GetRows()[2].Path == core::String(u8"Lamp.intensity"));
    bed.Pause();
    bed.Click(core::Float2{40.0f, 30.0f});
    CHECK(bed.sheet->GetRows().Size() == 7);
}

TEST_CASE("Dopesheet: a parent row shows every key under it, keys at one time as one")
{
    Bed bed;
    core::Array<f32> times(core::DefaultAllocator());
    core::Array<core::Array<TimelineKeyRef>> keys(core::DefaultAllocator());
    bed.sheet->GetRowKeys(0, times, keys); // Lamp
    REQUIRE(times.Size() == 4);
    CHECK(times[0] == doctest::Approx(0.2f));
    CHECK(keys[0].Size() == 2); // r's and g's
    CHECK(times[1] == doctest::Approx(0.6f));
    CHECK(times[3] == doctest::Approx(1.4f));
    bed.sheet->GetRowKeys(2, times, keys); // r
    CHECK(times.Size() == 2);
    CHECK(bed.sheet->KeyPoint(2, 1.0f).x == doctest::Approx(410.0f));
    CHECK(bed.sheet->KeyPoint(2, 1.0f).y == doctest::Approx(50.0f));
}

TEST_CASE("Dopesheet: a click selects a key, a parent's every key under it at that time; Shift adds; a box selects")
{
    Bed bed;
    bed.Click(Bed::At(2, 1.0f)); // r's second
    REQUIRE(bed.sheet->GetSelection().Size() == 1);
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{0, 1}));
    bed.Pause();
    bed.Click(Bed::At(0, 0.2f)); // Lamp at 0.2: r's and g's first
    CHECK(bed.sheet->GetSelection().Size() == 2);
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{0, 0}));
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{1, 0}));
    bed.Pause();
    bed.Click(Bed::At(6, 1.0f), KeyModShift); // fov's, added
    CHECK(bed.sheet->GetSelection().Size() == 3);
    bed.Pause();
    bed.Click(Bed::At(6, 1.0f), KeyModShift); // and taken away
    CHECK(bed.sheet->GetSelection().Size() == 2);

    bed.Pause();
    bed.Drag(Bed::At(2, 0.8f) + core::Float2{0.0f, -8.0f}, Bed::At(4, 1.2f) + core::Float2{0.0f, 8.0f}); // r..intensity, 0.8 to 1.2 s
    REQUIRE(bed.sheet->GetSelection().Size() == 1);
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{0, 1}));
    CHECK(bed.commits.IsEmpty());
}

TEST_CASE("Dopesheet: a drag moves the selected keys in time as one change, on frames, kept in the clip; the selection follows")
{
    Bed bed;
    bed.Click(Bed::At(0, 0.2f)); // r's and g's first
    bed.Pause();
    bed.Drag(Bed::At(0, 0.2f), Bed::At(0, 1.2f) + core::Float2{0.0f, 15.0f}); // past r's second
    REQUIRE(bed.commits.Size() == 1);
    CHECK(bed.Time(0, 0) == doctest::Approx(1.0f)); // r: the moved key passed its second, now 1.0 then 1.2
    CHECK(bed.Time(0, 1) == doctest::Approx(1.2f));
    CHECK(bed.Time(1, 0) == doctest::Approx(1.2f)); // g: 1.2 then 1.4
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{0, 1})); // r's moved key, now second
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{1, 0}));

    // On frames, and never past the clip's end.
    bed.axis->SetFrameRate(10.0f);
    bed.Pause();
    bed.Drag(Bed::At(3, 1.2f), Bed::At(3, 1.33f));
    CHECK(bed.Time(1, 0) == doctest::Approx(1.3f));
    CHECK(bed.Time(0, 1) == doctest::Approx(1.3f));
    bed.Pause();
    bed.Drag(Bed::At(3, 1.3f), core::Float2{690.0f, 70.0f}); // far right: the selected keys stop at 2 s
    CHECK(bed.Time(1, 1) <= 2.0f + 1e-4f);
    CHECK(bed.Time(1, 1) == doctest::Approx(2.0f));
    CHECK(bed.commits.Size() == 3);
}

TEST_CASE("Dopesheet: Escape gives a move up; Delete removes; a double click on a channel's row inserts a key there")
{
    Bed bed;
    bed.Press(Bed::At(4, 0.6f)); // intensity's
    bed.D().InjectMouseMove(Bed::At(4, 0.9f));
    CHECK(bed.Time(2, 0) == doctest::Approx(0.9f)); // previewed
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.Time(2, 0) == doctest::Approx(0.6f));
    bed.D().InjectMouseUp(Bed::At(4, 0.9f), MouseButton::Left);
    CHECK(bed.commits.IsEmpty());
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{2, 0}));

    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.clip.GetKeys(2).IsEmpty());
    CHECK(bed.commits.Size() == 1);

    bed.Pause();
    bed.Click(Bed::At(2, 0.6f));
    bed.Click(Bed::At(2, 0.6f)); // r at 0.6: on the line from 1 to 0
    REQUIRE(bed.clip.GetKeys(0).Size() == 3);
    CHECK(bed.clip.GetKeys(0)[1].time == doctest::Approx(0.6f));
    CHECK(bed.clip.GetKeys(0)[1].value == doctest::Approx(0.5f));
    CHECK(bed.sheet->IsSelected(TimelineKeyRef{0, 1}));
    CHECK(bed.commits.Size() == 2);

    bed.Pause();
    bed.Click(Bed::At(0, 1.7f)); // a parent's row inserts nothing
    bed.Click(Bed::At(0, 1.7f));
    CHECK(bed.commits.Size() == 2);
}

TEST_CASE("Dopesheet: the wheel over the names scrolls the rows, over the keys zooms; a curve view on the same clip follows")
{
    Bed bed;
    for (int i = 0; i < 10; ++i)
        bed.Add(u8"Extra.value", {Key(0.5f, 0.0f)});
    // Ten more channels, renamed apart: a row each under Extra.
    bed.clip.Info(4).Name = core::String(u8"Extra.a");
    for (usize c = 5; c < 14; ++c)
        bed.clip.Info(c).Name = core::Format(u8"Extra.v{}", c);
    bed.clip.InfoChanged();
    REQUIRE(bed.sheet->GetRows().Size() > 10);
    bed.D().InjectMouseMove(core::Float2{50.0f, 100.0f});
    bed.D().InjectMouseWheel(core::Float2{50.0f, 100.0f}, core::Float2{0.0f, -1.0f});
    CHECK(bed.sheet->GetRowScroll() == doctest::Approx(60.0f));
    bed.D().InjectMouseWheel(core::Float2{50.0f, 100.0f}, core::Float2{0.0f, 5.0f});
    CHECK(bed.sheet->GetRowScroll() == 0.0f);

    bed.D().InjectMouseWheel(Bed::At(0, 1.0f), core::Float2{0.0f, 1.0f});
    CHECK(bed.axis->PixelsPerSecond() == doctest::Approx(300.0f));
    CHECK(bed.sheet->TimeAtX(410.0f) == doctest::Approx(1.0f));

    // A curve view over the same clip: a move in the dopesheet is a move it shows.
    auto view = core::MakeRef<CurveView>(core::DefaultAllocator());
    view->SetTimeAxis(bed.axis);
    view->SetSource(&bed.clip);
    bed.axis->SetPixelsPerSecond(250.0f);
    bed.axis->SetScroll(0.0f);
    bed.Click(Bed::At(6, 1.0f)); // fov's
    bed.Pause();
    bed.Drag(Bed::At(6, 1.0f), Bed::At(6, 0.5f));
    CHECK(view->GetSource()->GetKeys(3)[0].time == doctest::Approx(0.5f));
    view->SetSource(nullptr);
}

TEST_CASE("Dopesheet: the timeline views are elements markup places, a dopesheet's names column set there")
{
    RegisterGuiElements();
    RegisterToolkitElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> made = loader.LoadFromString(SV(u8R"(<Panel><TimeRuler/><Dopesheet label-width="120"/><CurveView/><GradientView/></Panel>)"));
    REQUIRE(made);
    REQUIRE(made->ChildCount() == 4);
    CHECK(core::Cast<TimeRuler>(made->GetChildAt(0)) != nullptr);
    Dopesheet* sheet = core::Cast<Dopesheet>(made->GetChildAt(1));
    REQUIRE(sheet != nullptr);
    CHECK(sheet->GetLabelWidth() == doctest::Approx(120.0f));
    CHECK(core::Cast<CurveView>(made->GetChildAt(2)) != nullptr);
    CHECK(core::Cast<GradientView>(made->GetChildAt(3)) != nullptr);
}

TEST_CASE("Dopesheet: right to left, its names are at the right and its keys start at the left, time still left to right")
{
    Bed bed;
    bed.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    (void)bed.root->UpdateLayout();
    const Rect names = bed.sheet->NamesBounds();
    const Rect box = bed.sheet->GetContentBounds();
    CHECK(names.Right() == doctest::Approx(box.Right()));
    CHECK(names.width == doctest::Approx(160.0f));
    CHECK(bed.sheet->KeysLeft() == doctest::Approx(box.x));
    CHECK(bed.sheet->KeyPoint(2, 1.0f).x == doctest::Approx(box.x + 250.0f));
    CHECK(bed.sheet->TimeAtX(box.x + 250.0f) == doctest::Approx(1.0f));

    // A click on a name at the right folds its row.
    const Rect at = bed.sheet->GetScreenBounds();
    bed.Click(core::Float2{at.Right() - 40.0f, at.y + 30.0f}); // "color"
    CHECK(bed.sheet->IsFolded(SV(u8"Lamp.color")));
}
