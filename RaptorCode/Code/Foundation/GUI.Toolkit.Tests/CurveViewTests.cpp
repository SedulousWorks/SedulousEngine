// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the curve view (T5 of Specs/gui-lab-evolution-3.md): a source's curves of Core's keys
// edited as gestures through it, one change each (a drag previewed and committed on release, or
// cancelled by Escape); keys selected by a click or a box, moved (sorted again as they pass, on
// frames, in a curve's range, Shift locking an axis), their tangents set by their handles and their
// modes, added by a double click on a curve, set and deleted from their menu; the wheel zooming and a
// middle drag panning.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
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

    core::CurveKey Key(f32 time, f32 value, core::CurveKeyInterpolation interp = core::CurveKeyInterpolation::Linear,
                       core::CurveTangentMode mode = core::CurveTangentMode::Broken)
    {
        core::CurveKey key;
        key.time = time;
        key.value = value;
        key.interpolation = interp;
        key.tangentMode = mode;
        return key;
    }

    // A 520 by 220 view over 0 to 1 s (500 px a second) and values -0.05 to 1.05 (200 px a unit): the
    // time t and value v at (500 t, 210 - 200 v), no key on its edge.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<TimeAxis> axis = core::MakeRef<TimeAxis>(core::DefaultAllocator());
        core::RefPtr<CurveView> view = core::MakeRef<CurveView>(core::DefaultAllocator());
        CurveSet curves;
        core::Array<CurveChange> commits{core::DefaultAllocator()};

        Bed()
        {
            root->SetSize(core::Float2{600.0f, 300.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            view->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(520.0f);
                s.Height = LayoutLength::Px(220.0f);
            });
            root->AddChild(view.Get());
            axis->SetDuration(1.0f);
            axis->SetPixelsPerSecond(500.0f);
            view->SetTimeAxis(axis);
            view->SetValueRange(-0.05f, 1.05f);
            view->SetSource(&curves);
            curves.SetOnCommit([this](const CurveChange& change) { commits.PushBack(change); });
            (void)root->UpdateLayout();
        }
        ~Bed() { view->SetSource(nullptr); }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        static core::Float2 At(f32 t, f32 v) { return core::Float2{500.0f * t, 210.0f - 200.0f * v}; }
        void Press(core::Float2 at, core::u32 modifiers = 0)
        {
            D().InjectMouseMove(at, modifiers);
            D().InjectMouseDown(at, MouseButton::Left, modifiers);
        }
        void Drag(core::Float2 from, core::Float2 to, core::u32 modifiers = 0)
        {
            Press(from, modifiers);
            D().InjectMouseMove(core::Float2{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f}, modifiers);
            D().InjectMouseMove(to, modifiers);
            D().InjectMouseUp(to, MouseButton::Left, modifiers);
        }
        void Click(core::Float2 at, core::u32 modifiers = 0)
        {
            Press(at, modifiers);
            D().InjectMouseUp(at, MouseButton::Left, modifiers);
        }
        void Pause() // a later press is not the second of a double
        {
            D().InjectMouseMove(core::Float2{590.0f, 290.0f});
            D().InjectMouseDown(core::Float2{590.0f, 290.0f}, MouseButton::Left);
            D().InjectMouseUp(core::Float2{590.0f, 290.0f}, MouseButton::Left);
        }
        [[nodiscard]] core::Span<const core::CurveKey> Keys(usize curve = 0) const { return curves.GetKeys(curve); }
    };

    void Activate(Menu& menu, core::StringView text)
    {
        for (usize i = 0; i < menu.ChildCount(); ++i)
            if (MenuItem* item = core::Cast<MenuItem>(menu.GetChildAt(i)); item != nullptr && item->GetText() == text)
            {
                (void)item->HandleActivate();
                return;
            }
        FAIL("no such item");
    }
    MenuItem* Item(Menu& menu, core::StringView text)
    {
        for (usize i = 0; i < menu.ChildCount(); ++i)
            if (MenuItem* item = core::Cast<MenuItem>(menu.GetChildAt(i)); item != nullptr && item->GetText() == text)
                return item;
        return nullptr;
    }
}

TEST_CASE("CurveSet: an edit previews live, commits once with each changed curve's keys before and after, or cancels")
{
    CurveSet set;
    const core::CurveKey a[] = {Key(0.0f, 0.0f), Key(1.0f, 1.0f)};
    set.AddCurve(CurveInfo{}, a);
    set.AddCurve(CurveInfo{}, a);
    core::Array<CurveChange> commits{core::DefaultAllocator()};
    set.SetOnCommit([&commits](const CurveChange& change) { commits.PushBack(change); });

    const core::CurveKey b[] = {Key(0.0f, 0.5f), Key(1.0f, 1.0f)};
    set.BeginKeysEdit();
    set.PreviewKeys(1, b);
    CHECK(set.GetKeys(1)[0].value == 0.5f);
    set.CancelKeysEdit();
    CHECK(set.GetKeys(1)[0].value == 0.0f);
    CHECK(commits.IsEmpty());

    set.BeginKeysEdit();
    set.PreviewKeys(1, b);
    set.PreviewKeys(1, b);
    set.CommitKeysEdit();
    REQUIRE(commits.Size() == 1);
    REQUIRE(commits[0].Curves.Size() == 1); // the untouched curve is not in it
    CHECK(commits[0].Curves[0].Curve == 1);
    CHECK(commits[0].Curves[0].Before[0].value == 0.0f);
    CHECK(commits[0].Curves[0].After[0].value == 0.5f);

    set.Apply(commits[0], true);
    CHECK(set.GetKeys(1)[0].value == 0.0f);
    set.Apply(commits[0], false);
    CHECK(set.GetKeys(1)[0].value == 0.5f);

    set.BeginKeysEdit(); // nothing changed: nothing told
    set.CommitKeysEdit();
    CHECK(commits.Size() == 1);
}

TEST_CASE("CurveView: keys and the curve between them are where the axis and the value range put them")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.2f, 0.25f), Key(0.8f, 0.75f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    CHECK(bed.view->KeyPoint(0.2f, 0.25f).x == doctest::Approx(100.0f));
    CHECK(bed.view->KeyPoint(0.2f, 0.25f).y == doctest::Approx(160.0f));
    CHECK(bed.view->TimeAtX(250.0f) == doctest::Approx(0.5f));
    CHECK(bed.view->ValueAtY(110.0f) == doctest::Approx(0.5f));

    CurveHit hit = bed.view->HitTest(Bed::At(0.8f, 0.75f) + core::Float2{3.0f, -2.0f});
    CHECK(hit.What == CurveHit::Kind::Key);
    CHECK(hit.Key == CurveKeyRef{0, 1});
    hit = bed.view->HitTest(Bed::At(0.5f, 0.5f) + core::Float2{0.0f, 4.0f}); // on the line between them
    CHECK(hit.What == CurveHit::Kind::Curve);
    hit = bed.view->HitTest(Bed::At(0.5f, 0.9f));
    CHECK(hit.What == CurveHit::Kind::None);

    bed.curves.Info(0).Locked = true; // a locked curve is drawn, not hit
    bed.curves.InfoChanged();
    CHECK(bed.view->HitTest(Bed::At(0.8f, 0.75f)).What == CurveHit::Kind::None);
}

TEST_CASE("CurveView: a click selects a key, Shift adds one, a click on nothing clears, a box selects")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.1f, 0.1f), Key(0.3f, 0.2f), Key(0.6f, 0.8f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.Click(Bed::At(0.1f, 0.1f));
    CHECK(bed.view->GetSelection().Size() == 1);
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 0}));
    bed.Pause();
    bed.Click(Bed::At(0.6f, 0.8f), KeyModShift);
    CHECK(bed.view->GetSelection().Size() == 2);
    bed.Pause();
    bed.Click(Bed::At(0.6f, 0.8f), KeyModShift); // again: taken away
    CHECK(bed.view->GetSelection().Size() == 1);
    bed.Pause();
    bed.Click(Bed::At(0.5f, 0.1f)); // nothing there
    CHECK(bed.view->GetSelection().IsEmpty());
    bed.Pause();

    bed.Drag(Bed::At(0.05f, 0.3f), Bed::At(0.35f, 0.0f)); // around the first two
    CHECK(bed.view->GetSelection().Size() == 2);
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 0}));
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 1}));
    CHECK(bed.commits.IsEmpty()); // selecting changes nothing
}

TEST_CASE("CurveView: a drag moves the selected keys as one change, sorted again as they pass, on frames, in range")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.1f, 0.1f), Key(0.3f, 0.2f), Key(0.6f, 0.8f)};
    CurveInfo info;
    info.HasRange = true;
    info.Min = 0.0f;
    info.Max = 1.0f;
    bed.curves.AddCurve(info, keys);

    bed.Drag(Bed::At(0.1f, 0.1f), Bed::At(0.4f, 0.3f)); // the first passes the second
    REQUIRE(bed.commits.Size() == 1);
    REQUIRE(bed.Keys().Size() == 3);
    CHECK(bed.Keys()[0].time == doctest::Approx(0.3f));
    CHECK(bed.Keys()[1].time == doctest::Approx(0.4f));
    CHECK(bed.Keys()[1].value == doctest::Approx(0.3f));
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 1})); // the selection followed it

    // On frames: the pressed key lands on one.
    bed.axis->SetFrameRate(10.0f);
    bed.Pause();
    bed.Drag(Bed::At(0.6f, 0.8f), Bed::At(0.73f, 0.8f));
    CHECK(bed.Keys()[2].time == doctest::Approx(0.7f));
    // In its range.
    bed.Pause();
    bed.Drag(Bed::At(0.7f, 0.8f), Bed::At(0.7f, 1.4f));
    CHECK(bed.Keys()[2].value == doctest::Approx(1.0f));
    CHECK(bed.commits.Size() == 3);
}

TEST_CASE("CurveView: Shift locks a drag to the axis it moved along most, and Escape gives it up")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.2f, 0.5f), Key(0.8f, 0.5f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.Drag(Bed::At(0.2f, 0.5f), Bed::At(0.4f, 0.55f), KeyModShift);
    CHECK(bed.Keys()[0].time == doctest::Approx(0.4f));
    CHECK(bed.Keys()[0].value == doctest::Approx(0.5f));

    bed.Pause();
    bed.Press(Bed::At(0.8f, 0.5f));
    bed.D().InjectMouseMove(Bed::At(0.7f, 0.2f));
    CHECK(bed.Keys()[1].value == doctest::Approx(0.2f)); // previewed
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.Keys()[1].value == doctest::Approx(0.5f));
    CHECK(bed.Keys()[1].time == doctest::Approx(0.8f));
    bed.D().InjectMouseUp(Bed::At(0.7f, 0.2f), MouseButton::Left);
    CHECK(bed.commits.Size() == 1);
}

TEST_CASE("CurveView: auto and smooth keys follow a move; a handle sets the tangent and makes an auto key smooth")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.0f, 0.0f, core::CurveKeyInterpolation::Cubic, core::CurveTangentMode::Auto),
                                   Key(0.5f, 0.5f, core::CurveKeyInterpolation::Cubic, core::CurveTangentMode::Auto),
                                   Key(1.0f, 0.0f, core::CurveKeyInterpolation::Cubic, core::CurveTangentMode::Auto)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    // Auto: each key's slope that between its neighbours, set by the move.
    bed.Drag(Bed::At(1.0f, 0.0f), Bed::At(1.0f, 1.0f));
    CHECK(bed.Keys()[1].tangentOut == doctest::Approx(1.0f)); // (1 - 0) / (1 - 0)
    CHECK(bed.Keys()[1].tangentMode == core::CurveTangentMode::Auto);

    // The middle key selected shows both handles; its out handle dragged flat.
    bed.Pause();
    bed.Click(Bed::At(0.5f, 0.5f));
    REQUIRE(bed.view->IsSelected(CurveKeyRef{0, 1}));
    const core::Float2 handle = bed.view->HandlePoint(bed.Keys()[1], true);
    CHECK(bed.view->HitTest(handle).What == CurveHit::Kind::TangentOut);
    bed.Pause();
    bed.Click(Bed::At(0.5f, 0.5f));
    bed.Drag(handle, Bed::At(0.7f, 0.5f));
    CHECK(bed.Keys()[1].tangentOut == doctest::Approx(0.0f));
    CHECK(bed.Keys()[1].tangentIn == doctest::Approx(0.0f)); // smooth: one slope through it
    CHECK(bed.Keys()[1].tangentMode == core::CurveTangentMode::Smooth);

    // Broken: the in handle alone.
    bed.view->SetTangentMode(core::CurveTangentMode::Broken);
    const core::Float2 in = bed.view->HandlePoint(bed.Keys()[1], false);
    bed.Pause();
    bed.Click(Bed::At(0.5f, 0.5f));
    bed.Drag(in, Bed::At(0.4f, 0.4f));
    CHECK(bed.Keys()[1].tangentIn == doctest::Approx(1.0f)); // (0.5 - 0.4) / (0.5 - 0.4)
    CHECK(bed.Keys()[1].tangentOut == doctest::Approx(0.0f));
}

TEST_CASE("CurveView: a handle shows only where a cubic segment meets its key")
{
    const core::CurveKey keys[] = {Key(0.0f, 0.0f, core::CurveKeyInterpolation::Linear), Key(0.5f, 0.5f, core::CurveKeyInterpolation::Cubic),
                                   Key(1.0f, 0.0f)};
    CHECK_FALSE(CurveView::HasHandle(keys, 0, true));
    CHECK_FALSE(CurveView::HasHandle(keys, 1, false)); // the linear segment arrives
    CHECK(CurveView::HasHandle(keys, 1, true));
    CHECK(CurveView::HasHandle(keys, 2, false));
    CHECK_FALSE(CurveView::HasHandle(keys, 2, true)); // the last key leaves nothing
}

TEST_CASE("CurveView: a double click on a curve adds a key on it, unless the curve is full")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.0f, 0.0f), Key(1.0f, 1.0f)};
    CurveInfo info;
    info.MaxKeys = 3;
    bed.curves.AddCurve(info, keys);
    bed.Click(Bed::At(0.5f, 0.5f));
    bed.Click(Bed::At(0.5f, 0.5f)); // the second press
    REQUIRE(bed.Keys().Size() == 3);
    CHECK(bed.Keys()[1].time == doctest::Approx(0.5f));
    CHECK(bed.Keys()[1].value == doctest::Approx(0.5f));
    CHECK(bed.Keys()[1].interpolation == core::CurveKeyInterpolation::Linear); // the segment's it split
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 1}));
    CHECK(bed.commits.Size() == 1);

    bed.Pause();
    bed.Click(Bed::At(0.25f, 0.25f));
    bed.Click(Bed::At(0.25f, 0.25f));
    CHECK(bed.Keys().Size() == 3); // full
    CHECK(bed.commits.Size() == 1);
}

TEST_CASE("CurveView: a key's menu sets the selected keys' interpolation and mode, checked where they agree, and deletes")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.1f, 0.1f), Key(0.5f, 0.5f), Key(0.9f, 0.1f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.Click(Bed::At(0.1f, 0.1f));
    bed.Pause();
    bed.Click(Bed::At(0.5f, 0.5f), KeyModShift);
    bed.D().InjectMouseMove(Bed::At(0.5f, 0.5f));
    bed.D().InjectMouseDown(Bed::At(0.5f, 0.5f), MouseButton::Right);
    bed.D().InjectMouseUp(Bed::At(0.5f, 0.5f), MouseButton::Right);
    Menu* menu = bed.view->GetKeyMenu();
    REQUIRE(menu != nullptr);
    CHECK(bed.view->GetSelection().Size() == 2); // a selected key keeps the selection
    CHECK(Item(*menu, SV(u8"Linear"))->IsChecked());
    CHECK(Item(*menu, SV(u8"Broken"))->IsChecked());
    Activate(*menu, SV(u8"Cubic"));
    CHECK(bed.Keys()[0].interpolation == core::CurveKeyInterpolation::Cubic);
    CHECK(bed.Keys()[1].interpolation == core::CurveKeyInterpolation::Cubic);
    CHECK(bed.Keys()[2].interpolation == core::CurveKeyInterpolation::Linear);
    CHECK(bed.commits.Size() == 1);

    bed.view->SetTangentMode(core::CurveTangentMode::Flat);
    CHECK(bed.commits.Size() == 2);
    bed.D().InjectMouseDown(Bed::At(0.5f, 0.5f), MouseButton::Right);
    bed.D().InjectMouseUp(Bed::At(0.5f, 0.5f), MouseButton::Right);
    menu = bed.view->GetKeyMenu();
    REQUIRE(menu != nullptr);
    CHECK(Item(*menu, SV(u8"Flat"))->IsChecked());
    Activate(*menu, SV(u8"Delete"));
    REQUIRE(bed.Keys().Size() == 1);
    CHECK(bed.Keys()[0].time == doctest::Approx(0.9f));
    CHECK(bed.view->GetSelection().IsEmpty());

    // Delete on the focused view.
    bed.Click(Bed::At(0.9f, 0.1f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.Keys().IsEmpty());
    CHECK(bed.commits.Size() == 4);
}

TEST_CASE("CurveView: the menu over nothing frames every curve or the selection")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.2f, 2.0f), Key(0.6f, 4.0f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.axis->SetDuration(10.0f);
    bed.D().InjectMouseMove(core::Float2{400.0f, 20.0f});
    bed.D().InjectMouseDown(core::Float2{400.0f, 20.0f}, MouseButton::Right);
    bed.D().InjectMouseUp(core::Float2{400.0f, 20.0f}, MouseButton::Right);
    Menu* menu = bed.view->GetKeyMenu();
    REQUIRE(menu != nullptr);
    CHECK_FALSE(Item(*menu, SV(u8"Frame selection"))->IsEnabled());
    Activate(*menu, SV(u8"Frame all"));
    // Both keys inside, with a margin.
    CHECK(bed.view->ValueLow() < 2.0f);
    CHECK(bed.view->ValueHigh() > 4.0f);
    CHECK(bed.view->ValueHigh() < 4.5f);
    const core::Float2 first = bed.view->KeyPoint(0.2f, 2.0f);
    const core::Float2 last = bed.view->KeyPoint(0.6f, 4.0f);
    CHECK(first.x > 0.0f);
    CHECK(last.x < 520.0f);
    CHECK(last.x - first.x > 400.0f);

    // The selection alone: its one key in the middle.
    const CurveKeyRef second[] = {CurveKeyRef{0, 1}};
    bed.view->SetSelection(second);
    bed.view->FrameSelection();
    CHECK(bed.view->KeyPoint(0.6f, 4.0f).x == doctest::Approx(260.0f).epsilon(0.02));
    CHECK(bed.view->KeyPoint(0.6f, 4.0f).y == doctest::Approx(110.0f).epsilon(0.02));
}

TEST_CASE("CurveView: the wheel zooms about the pointer, Ctrl only time and Shift only value; a middle drag pans")
{
    Bed bed;
    bed.axis->SetDuration(10.0f);
    bed.axis->SetScroll(0.0f);
    const core::Float2 at{250.0f, 110.0f}; // 0.5 s, 0.5
    bed.D().InjectMouseMove(at);
    bed.D().InjectMouseWheel(at, core::Float2{0.0f, 1.0f});
    CHECK(bed.axis->PixelsPerSecond() == doctest::Approx(600.0f));
    CHECK(bed.view->TimeAtX(250.0f) == doctest::Approx(0.5f));
    CHECK(bed.view->ValueAtY(110.0f) == doctest::Approx(0.5f));
    CHECK(bed.view->ValueHigh() - bed.view->ValueLow() == doctest::Approx(1.1f / 1.2f));

    bed.D().InjectMouseWheel(at, core::Float2{0.0f, -1.0f}, KeyModCtrl); // time only
    CHECK(bed.axis->PixelsPerSecond() == doctest::Approx(500.0f));
    CHECK(bed.view->ValueHigh() - bed.view->ValueLow() == doctest::Approx(1.1f / 1.2f));
    bed.D().InjectMouseWheel(at, core::Float2{0.0f, -1.0f}, KeyModShift); // value only
    CHECK(bed.axis->PixelsPerSecond() == doctest::Approx(500.0f));
    CHECK(bed.view->ValueHigh() - bed.view->ValueLow() == doctest::Approx(1.1f));

    const f32 low = bed.view->ValueLow();
    bed.axis->SetScroll(1.0f);
    bed.D().InjectMouseDown(at, MouseButton::Middle);
    bed.D().InjectMouseMove(at + core::Float2{-100.0f, 40.0f});
    bed.D().InjectMouseUp(at + core::Float2{-100.0f, 40.0f}, MouseButton::Middle);
    CHECK(bed.axis->Scroll() == doctest::Approx(1.2f));
    CHECK(bed.view->ValueLow() == doctest::Approx(low + 0.2f)); // dragged down 40 px: the values move up
}

TEST_CASE("CurveView: an undo that takes keys away takes them from the selection")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.0f, 0.0f), Key(1.0f, 1.0f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.Click(Bed::At(0.5f, 0.5f));
    bed.Click(Bed::At(0.5f, 0.5f));
    REQUIRE(bed.view->IsSelected(CurveKeyRef{0, 1}));
    bed.Pause();
    bed.Click(Bed::At(1.0f, 1.0f));
    REQUIRE(bed.view->IsSelected(CurveKeyRef{0, 2}));
    bed.curves.Apply(bed.commits[0], true);
    CHECK(bed.Keys().Size() == 2);
    CHECK(bed.view->GetSelection().IsEmpty());
}

TEST_CASE("CurveView: a Shift+click on a key just selected takes it away, though it comes as a double click")
{
    Bed bed;
    const core::CurveKey keys[] = {Key(0.2f, 0.2f), Key(0.8f, 0.8f)};
    bed.curves.AddCurve(CurveInfo{}, keys);
    bed.Click(Bed::At(0.2f, 0.2f));
    REQUIRE(bed.view->IsSelected(CurveKeyRef{0, 0}));
    bed.Click(Bed::At(0.2f, 0.2f), KeyModShift); // the second press, near in time and place
    CHECK_FALSE(bed.view->IsSelected(CurveKeyRef{0, 0}));
    bed.Click(Bed::At(0.2f, 0.2f), KeyModShift); // and back
    CHECK(bed.view->IsSelected(CurveKeyRef{0, 0}));
    CHECK(bed.Keys().Size() == 2); // nothing added
}
