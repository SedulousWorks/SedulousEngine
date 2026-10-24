// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the property grid's curve and gradient editors (T5 of Specs/gui-lab-evolution-3.md): a
// row's preview (hatched when mixed) opens the full view as a popup; every edit in it previews on the
// objects, the edit begun at the first; closing it commits once, Escape gives the whole of it up; a
// read-only row opens nothing. The grid chooses them by kind.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::u64;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // Records each call as text: "begin p", "preview p=v", "commit p=v", "cancel p".
    struct Host : IPropertyEditHost
    {
        core::Array<core::String> calls{core::DefaultAllocator()};
        void BeginPropertyEdit(core::StringView path) override { calls.PushBack(core::Format(u8"begin {}", path)); }
        void PreviewPropertyEdit(core::StringView path, const PropertyWrite& write) override
        {
            calls.PushBack(core::Format(u8"preview {}={}", path, write.Value.ToString().AsView()));
        }
        void CommitPropertyEdit(core::StringView path, const PropertyWrite& write) override
        {
            calls.PushBack(core::Format(u8"commit {}={}", path, write.Value.ToString().AsView()));
        }
        void CancelPropertyEdit(core::StringView path) override { calls.PushBack(core::Format(u8"cancel {}", path)); }
        bool EditPropertyList(core::StringView, const ListEdit&) override { return false; }
        void GetChildProperties(core::StringView, core::Array<PropertyInfo>&) const override {}
        [[nodiscard]] PropertyValue ReadPropertyValue(core::StringView, PropertyKind) const override { return {}; }
        [[nodiscard]] core::StringView Last() const { return calls.IsEmpty() ? core::StringView{} : calls.Back().AsView(); }
    };

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        Host host;

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
        }
        template <typename T>
        core::RefPtr<T> Editor(const PropertyInfo& info, const PropertyValue& value)
        {
            auto editor = core::MakeRef<T>(core::DefaultAllocator());
            editor->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(200.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
            root->AddChild(editor.Get());
            editor->Bind(host, SV(u8"p"), info, value);
            (void)root->UpdateLayout();
            return editor;
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Click(const Node& node)
        {
            const Rect r = node.GetScreenBounds();
            const core::Float2 at{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
            D().InjectMouseMove(at);
            D().InjectMouseDown(at, MouseButton::Left);
            D().InjectMouseUp(at, MouseButton::Left);
        }
    };

    PropertyValue CurveValue(bool mixed = false)
    {
        core::CurveKey keys[2]{};
        keys[0] = core::CurveKey{0.0f, 0.0f, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
        keys[1] = core::CurveKey{1.0f, 1.0f, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
        PropertyValue value;
        value.Value = Variant::FromCurve(keys);
        value.Mixed = mixed;
        return value;
    }
    PropertyValue AGradient()
    {
        ColorGradient gradient;
        gradient.Colors.PushBack(core::GradientColorStop{0.0f, core::Color{1.0f, 0.0f, 0.0f, 1.0f}});
        gradient.Colors.PushBack(core::GradientColorStop{1.0f, core::Color{0.0f, 0.0f, 1.0f, 1.0f}});
        gradient.Alphas.PushBack(core::GradientAlphaStop{0.0f, 1.0f});
        PropertyValue value;
        value.Value = Variant(gradient);
        return value;
    }
    PropertyInfo Info(PropertyKind kind)
    {
        PropertyInfo info;
        info.Name = core::String(u8"p");
        info.Kind = kind;
        return info;
    }
}

TEST_CASE("curve editors: chosen by kind")
{
    PropertyEditorRegistry registry(core::DefaultAllocator());
    RegisterDefaultPropertyEditors(registry);
    auto curve = registry.Create(registry.Choose(Info(PropertyKind::Curve)), core::DefaultAllocator());
    auto gradient = registry.Create(registry.Choose(Info(PropertyKind::Gradient)), core::DefaultAllocator());
    CHECK(core::Cast<CurvePropertyEditor>(curve.Get()) != nullptr);
    CHECK(core::Cast<GradientPropertyEditor>(gradient.Get()) != nullptr);
}

TEST_CASE("curve editors: a curve's preview opens its view; its edits preview, closing commits once")
{
    Bed bed;
    PropertyInfo info = Info(PropertyKind::Curve);
    info.MaxCount = 8;
    auto editor = bed.Editor<CurvePropertyEditor>(info, CurveValue());
    CHECK(editor->GetPreview()->GetValue().AsCurve().Size() == 2);
    CHECK_FALSE(editor->IsViewOpen());
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    CHECK(bed.host.calls.IsEmpty()); // opening is not editing
    CHECK(editor->GetTimeAxis()->Duration() == doctest::Approx(1.0f));
    REQUIRE(editor->GetView()->GetSource()->GetKeys(0).Size() == 2);

    // Two edits in the view: begun once, previewed each.
    REQUIRE(editor->GetView()->InsertKey(0, 0.5f));
    REQUIRE(editor->GetView()->InsertKey(0, 0.25f));
    REQUIRE(bed.host.calls.Size() == 3);
    CHECK(bed.host.calls[0] == core::String(u8"begin p"));
    CHECK(bed.host.calls[1] == core::String(u8"preview p=3 keys"));
    CHECK(bed.host.Last() == SV(u8"preview p=4 keys"));
    CHECK(editor->GetPreview()->GetValue().AsCurve().Size() == 4); // the row shows it as it goes

    bed.D().ClosePopup(*editor->GetView()->GetParent());
    CHECK(bed.host.Last() == SV(u8"commit p=4 keys"));
    CHECK(bed.host.calls.Size() == 4);
}

TEST_CASE("curve editors: Escape gives the whole of an open view up; closing it unchanged edits nothing")
{
    Bed bed;
    auto editor = bed.Editor<CurvePropertyEditor>(Info(PropertyKind::Curve), CurveValue());
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    REQUIRE(editor->GetView()->InsertKey(0, 0.5f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(editor->IsViewOpen());
    CHECK(bed.host.Last() == SV(u8"cancel p"));

    bed.host.calls.Clear();
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    CHECK(editor->GetView()->GetSource()->GetKeys(0).Size() == 2); // the value bound, not the given-up edit
    bed.D().ClosePopup(*editor->GetView()->GetParent());
    CHECK(bed.host.calls.IsEmpty());
}

TEST_CASE("curve editors: mixed is hatched; read only opens nothing")
{
    Bed bed;
    auto editor = bed.Editor<CurvePropertyEditor>(Info(PropertyKind::Curve), CurveValue(true));
    CHECK(editor->GetPreview()->IsMixed());
    PropertyInfo info = Info(PropertyKind::Curve);
    info.ReadOnly = true;
    editor->Bind(bed.host, SV(u8"p"), info, CurveValue());
    CHECK_FALSE(editor->GetPreview()->IsMixed());
    bed.Click(*editor->GetPreview());
    CHECK_FALSE(editor->IsViewOpen());
}

TEST_CASE("curve editors: a gradient's bar opens its view; its edits preview, closing commits once, Escape gives up")
{
    Bed bed;
    PropertyInfo info = Info(PropertyKind::Gradient);
    info.MaxCount = 3;
    auto editor = bed.Editor<GradientPropertyEditor>(info, AGradient());
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    CHECK(bed.host.calls.IsEmpty());
    REQUIRE(editor->GetView()->AddStop(false, 0.5f));
    CHECK_FALSE(editor->GetView()->AddStop(false, 0.25f)); // its most: three
    REQUIRE(bed.host.calls.Size() == 2);
    CHECK(bed.host.calls[0] == core::String(u8"begin p"));
    CHECK(bed.host.Last() == SV(u8"preview p=3 colours, 1 alphas"));
    bed.D().ClosePopup(*editor->GetView()->GetParent());
    CHECK(bed.host.Last() == SV(u8"commit p=3 colours, 1 alphas"));

    bed.host.calls.Clear();
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    REQUIRE(editor->GetView()->AddStop(true, 0.5f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(editor->IsViewOpen());
    CHECK(bed.host.Last() == SV(u8"cancel p"));
}

TEST_CASE("curve editors: a row's curve stays in its box, a steep tangent's overshoot clipped or framed")
{
    Bed bed;
    core::CurveKey keys[2]{};
    keys[0] = core::CurveKey{0.0f, 0.0f, 0.0f, 40.0f, core::CurveKeyInterpolation::Cubic, core::CurveTangentMode::Broken};
    keys[1] = core::CurveKey{1.0f, 1.0f, -40.0f, 0.0f, core::CurveKeyInterpolation::Cubic, core::CurveTangentMode::Broken};
    PropertyInfo info = Info(PropertyKind::Curve);
    info.HasRange = true; // a range the curve leaves by far
    info.Min = 0.0;
    info.Max = 1.0;
    PropertyValue value;
    value.Value = Variant::FromCurve(keys);
    auto editor = bed.Editor<CurvePropertyEditor>(info, value);
    const Rect box = editor->GetPreview()->GetScreenBounds();
    REQUIRE(box.width > 0.0f);

    // The preview alone: what it draws, less what a clip cuts away, spans no more than its box.
    foundation::vg::VGContext vg;
    DrawContext ctx{vg};
    editor->GetPreview()->Draw(ctx);
    const foundation::vg::VGBatch& batch = vg.GetBatch();
    f32 low = 1e9f, high = -1e9f;
    for (const foundation::vg::VGCommand& command : batch.commands)
        for (core::i32 k = 0; k < command.indexCount; ++k)
        {
            const foundation::vg::VGVertex& v = batch.vertices[batch.indices[static_cast<core::usize>(command.startIndex + k)]];
            f32 y = v.position.y;
            if (command.scissored || command.clipMode == foundation::vg::VGClipMode::Scissor)
                y = core::Clamp(y, command.clipRect.y, command.clipRect.y + command.clipRect.height);
            low = core::Min(low, y);
            high = core::Max(high, y);
        }
    REQUIRE(high > low);
    CHECK(high - low <= box.height + 2.0f);
}

TEST_CASE("curve editors: in the popup, a gradient's stop pulled off the strip goes")
{
    Bed bed;
    PropertyInfo info = Info(PropertyKind::Gradient);
    info.MaxCount = 6;
    auto editor = bed.Editor<GradientPropertyEditor>(info, AGradient());
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    (void)bed.root->UpdateLayout();
    GradientStrip* strip = editor->GetView()->GetStrip();
    const Rect r = strip->GetScreenBounds();
    const core::Float2 stop{r.Right() - 2.0f, r.Bottom() - 4.0f}; // the last colour stop
    bed.D().InjectMouseMove(stop);
    bed.D().InjectMouseDown(stop, MouseButton::Left);
    bed.D().InjectMouseMove(stop + core::Float2{0.0f, 10.0f});
    bed.D().InjectMouseMove(stop + core::Float2{0.0f, 40.0f});
    bed.D().InjectMouseMove(stop + core::Float2{0.0f, 80.0f});
    CHECK(editor->GetView()->GetValue().Colors.Size() == 1);
    bed.D().InjectMouseUp(stop + core::Float2{0.0f, 80.0f}, MouseButton::Left);
    CHECK(editor->GetView()->GetValue().Colors.Size() == 1);
    CHECK(bed.host.Last() == SV(u8"preview p=1 colours, 1 alphas"));
}

TEST_CASE("curve editors: in the popup, Shift+click adds a key to the selection")
{
    Bed bed;
    PropertyInfo info = Info(PropertyKind::Curve);
    info.MaxCount = 8;
    auto editor = bed.Editor<CurvePropertyEditor>(info, CurveValue());
    bed.Click(*editor->GetPreview());
    REQUIRE(editor->IsViewOpen());
    (void)bed.root->UpdateLayout();
    CurveView* view = editor->GetView();
    const Rect r = view->GetScreenBounds();
    const auto at = [&](core::f32 t, core::f32 v)
    {
        const core::Float2 local = view->KeyPoint(t, v);
        return core::Float2{r.x + local.x, r.y + local.y};
    };
    bed.D().InjectMouseMove(at(0.0f, 0.0f));
    bed.D().InjectMouseDown(at(0.0f, 0.0f), MouseButton::Left);
    bed.D().InjectMouseUp(at(0.0f, 0.0f), MouseButton::Left);
    CHECK(view->GetSelection().Size() == 1);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::LeftShift), KeyModShift);
    bed.D().InjectMouseMove(at(1.0f, 1.0f), KeyModShift);
    bed.D().InjectMouseDown(at(1.0f, 1.0f), MouseButton::Left, KeyModShift);
    bed.D().InjectMouseUp(at(1.0f, 1.0f), MouseButton::Left, KeyModShift);
    bed.D().InjectKeyUp(static_cast<core::u32>(KeyCode::LeftShift), 0);
    CHECK(view->GetSelection().Size() == 2);
    CHECK(editor->IsViewOpen());
}
