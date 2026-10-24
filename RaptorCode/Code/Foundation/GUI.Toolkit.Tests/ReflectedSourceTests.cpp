// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the reflected property source (T3 of Specs/gui-lab-evolution-3.md): a reflected type's
// properties as rows (values, enums and flags, Float2/3/4, a Quaternion as Euler degrees, value
// structs as groups, other types hinted with their names), the attributes the editor's inspector
// reads, writes through addresses and setters, and each commit told as one change the text format
// writes and Restore reads back.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"
#include <initializer_list>
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::f64;
using core::i32;
using core::i64;
using core::u8;
using core::u32;
using core::usize;

namespace reflected
{
    enum class LampKind : u8
    {
        Point,
        Spot,
        Area,
    };
    enum class LampLayers : u32
    {
        None = 0,
        Main = 1,
        Shadows = 2,
        Reflections = 4,
    };
    struct LampShape
    {
        f32 radius = 1.0f;
        f32 softness = 0.5f;
    };

    class TestEffect : public core::Object
    {
        RTTI_OBJECT(TestEffect, core::Object)
    public:
        f32 strength = 1.0f;
    };
    class TestFlicker : public TestEffect
    {
        RTTI_OBJECT(TestFlicker, TestEffect)
    public:
        f32 speed = 4.0f;
    };
    class TestPulse : public TestEffect
    {
        RTTI_OBJECT(TestPulse, TestEffect)
    public:
        f32 period = 2.0f;
    };

    class TestLamp : public core::Object
    {
        RTTI_OBJECT(TestLamp, core::Object)
    public:
        core::String name = core::String(u8"Lamp");
        bool enabled = true;
        u8 priority = 3;
        i32 bounces = 2;
        f32 intensity = 5.0f;
        f64 range = 10.0;
        LampKind kind = LampKind::Point;
        LampLayers layers = LampLayers::Main;
        f32 coneAngle = 45.0f;
        core::Float2 cone{20.0f, 35.0f};
        core::Float3 position{1.0f, 2.0f, 3.0f};
        core::Quaternion rotation = core::Quaternion::Identity;
        LampShape shape;
        core::Color tint{1.0f, 1.0f, 1.0f, 1.0f};
        core::Color edge{0.2f, 0.2f, 0.2f, 1.0f};
        core::Float4 glow{1.0f, 0.5f, 0.0f, 4.0f}; // sRGB rgb, a linear intensity in w
        i64 id = 101;
        core::Array<f32> weights;
        core::Array<core::RefPtr<TestEffect>> effects;
        f32 steps[3] = {1.0f, 2.0f, 0.0f};
        i32 stepCount = 2;

        [[nodiscard]] f32 GetExposure() const { return m_exposure; }
        void SetExposure(f32 exposure) { m_exposure = exposure; }

    private:
        f32 m_exposure = 0.0f;
    };

    REFLECT_ENUM(LampKind, "rtti::tests::reflected")
    {
        builder.Value("Point", LampKind::Point);
        builder.Value("Spot", LampKind::Spot);
        builder.Value("Area", LampKind::Area);
    }
    REFLECT_ENUM(LampLayers, "rtti::tests::reflected")
    {
        builder.Value("Main", LampLayers::Main);
        builder.Value("Shadows", LampLayers::Shadows);
        builder.Value("Reflections", LampLayers::Reflections);
    }
    REFLECT_VALUE(LampShape, "rtti::tests::reflected")
    {
        builder.Property<&LampShape::radius>("radius").Property<&LampShape::softness>("softness");
    }
    REFLECT_MEMBERS(TestEffect, "rtti::tests::reflected")
    {
        builder.Property<&TestEffect::strength>("strength");
    }
    REFLECT_MEMBERS(TestFlicker, "rtti::tests::reflected")
    {
        builder.Attribute("displayName", core::String(u8"Flicker"));
        builder.Property<&TestFlicker::speed>("speed");
        builder.Creator();
    }
    REFLECT_MEMBERS(TestPulse, "rtti::tests::reflected")
    {
        builder.Attribute("displayName", core::String(u8"Pulse"));
        builder.Property<&TestPulse::period>("period");
        builder.Creator();
    }
    REFLECT_MEMBERS(TestLamp, "rtti::tests::reflected")
    {
        builder.Property<&TestLamp::name>("name").PropAttribute("description", core::String(u8"What the scene calls it"));
        builder.Property<&TestLamp::enabled>("enabled");
        builder.Property<&TestLamp::priority>("priority");
        builder.Property<&TestLamp::bounces>("bounces");
        builder.Property<&TestLamp::intensity>("intensity").PropAttribute("range", core::Float4{0.0f, 100.0f, 0.5f, 0.0f});
        builder.Property<&TestLamp::range>("range").PropAttribute("displayName", core::String(u8"Reach"));
        builder.Property<&TestLamp::kind>("kind");
        builder.Property<&TestLamp::layers>("layers").PropAttribute("flags", true);
        builder.Property<&TestLamp::coneAngle>("coneAngle").PropAttribute("visibleWhen", core::String(u8"kind=1"));
        builder.Property<&TestLamp::cone>("cone");
        builder.Property<&TestLamp::position>("position");
        builder.Property<&TestLamp::rotation>("rotation");
        builder.Property<&TestLamp::shape>("shape");
        builder.Property<&TestLamp::tint>("tint");
        builder.Property<&TestLamp::edge>("edge").PropAttribute("noAlpha", true);
        builder.Property<&TestLamp::glow>("glow").PropAttribute("hdrColor", true);
        builder.Property<&TestLamp::id>("id", core::PropertyFlags::ReadOnly);
        builder.AccessorProperty<&TestLamp::GetExposure, &TestLamp::SetExposure>("exposure");
        builder.Nested<&TestLamp::weights>("weights");
        builder.Nested<&TestLamp::effects>("effects");
        builder.BoundedArray<&TestLamp::steps, &TestLamp::stepCount>("steps");
        builder.Creator();
    }

    // A curve and a gradient of an application's own (as a particle module's are): fixed arrays
    // of Core's keys and stops with their counts, registered with the source as one value each.
    struct TestCurve
    {
        core::CurveKey keys[4]{};
        i32 keyCount = 0;
    };
    struct TestGradient
    {
        core::GradientColorStop colors[3]{};
        i32 colorCount = 0;
        core::GradientAlphaStop alphas[3]{};
        i32 alphaCount = 0;
        core::GradientInterpolation interpolation = core::GradientInterpolation::Srgb;
    };
    class TestEmitter : public core::Object
    {
        RTTI_OBJECT(TestEmitter, core::Object)
    public:
        TestEmitter()
        {
            size.keys[0] = core::CurveKey{0.0f, 1.0f, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
            size.keys[1] = core::CurveKey{1.0f, 0.0f, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
            size.keyCount = 2;
            color.colors[0] = core::GradientColorStop{0.0f, core::Color{1.0f, 1.0f, 1.0f, 1.0f}};
            color.colorCount = 1;
            color.alphas[0] = core::GradientAlphaStop{0.0f, 1.0f};
            color.alphas[1] = core::GradientAlphaStop{1.0f, 0.0f};
            color.alphaCount = 2;
        }
        TestCurve size;
        TestGradient color;
        f32 rate = 10.0f;
    };
    REFLECT_VALUE(TestCurve, "rtti::tests::reflected")
    {
        builder.BoundedArray<&TestCurve::keys, &TestCurve::keyCount>("keys").Property<&TestCurve::keyCount>("keyCount");
    }
    REFLECT_VALUE(TestGradient, "rtti::tests::reflected")
    {
        builder.BoundedArray<&TestGradient::colors, &TestGradient::colorCount>("colors")
            .Property<&TestGradient::colorCount>("colorCount")
            .BoundedArray<&TestGradient::alphas, &TestGradient::alphaCount>("alphas")
            .Property<&TestGradient::alphaCount>("alphaCount")
            .Property<&TestGradient::interpolation>("interpolation");
    }
    REFLECT_MEMBERS(TestEmitter, "rtti::tests::reflected")
    {
        builder.Property<&TestEmitter::size>("size").PropAttribute("range", core::Float4{0.0f, 4.0f, 0.0f, 0.0f});
        builder.Property<&TestEmitter::color>("color");
        builder.Property<&TestEmitter::rate>("rate");
        builder.Creator();
    }

    core::RefPtr<TestEffect> CreateEffect(const core::TypeInfo& type)
    {
        core::RefPtr<core::Object> made = core::CreateObject(type, core::DefaultAllocator());
        return core::RefPtr<TestEffect>(core::Cast<TestEffect>(made.Get()));
    }
    bool CanCreateEffect(const core::TypeInfo& type) { return type.creator != nullptr; }

    void Register()
    {
        core::RegisterCoreTypes(); // as an application does: Color, Float3 and the rest named
        RttiRegisterEnum_LampKind();
        RttiRegisterEnum_LampLayers();
        RttiRegisterValue_LampShape();
        RttiRegisterValue_TestCurve();
        RttiRegisterValue_TestGradient();
        core::RegisterArrayType<f32>();
        core::RegisterPolymorphicArrayType<TestEffect>(&CreateEffect, &CanCreateEffect);
        static const bool once = []()
        {
            core::GlobalTypeRegistry().Register(TestEffect::StaticType());
            core::GlobalTypeRegistry().Register(TestFlicker::StaticType());
            core::GlobalTypeRegistry().Register(TestPulse::StaticType());
            return true;
        }();
        (void)once;
    }

    // A format of its own for the tests: Core's binary serializer, its bytes held as the text.
    class BlobFormat : public IPropertyTextFormat
    {
    public:
        core::String Write(core::Function<void(core::ISerializer&)> write) override
        {
            core::MemoryStream stream;
            core::BinarySerializer ar(stream, core::SerializeMode::Write);
            write(ar);
            const core::Span<const core::byte> bytes = stream.Bytes();
            return ar.IsOk() ? core::String(core::StringView(reinterpret_cast<const char8_t*>(bytes.Data()), bytes.Size())) : core::String{};
        }
        bool Read(core::StringView text, core::Function<void(core::ISerializer&)> read) override
        {
            core::MemoryStream stream;
            (void)stream.Write(text.Data(), text.Size());
            (void)stream.Seek(0, core::SeekOrigin::Begin);
            core::BinarySerializer ar(stream, core::SerializeMode::Read);
            read(ar);
            return ar.IsOk();
        }
    };
}

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<reflected::TestLamp> a = core::MakeRef<reflected::TestLamp>(core::DefaultAllocator());
        core::RefPtr<reflected::TestLamp> b = core::MakeRef<reflected::TestLamp>(core::DefaultAllocator());
        ReflectedPropertySource source{core::DefaultAllocator()};
        core::Array<ReflectedChange> changes{core::DefaultAllocator()};

        explicit Bed(bool both = false)
        {
            reflected::Register();
            core::Instance objects[] = {core::Instance(a.Get(), a->GetType()), core::Instance(b.Get(), b->GetType())}; // an Object's own type
            source.SetObjects(core::Span<const core::Instance>(objects, both ? 2u : 1u));
            source.SetOnChange([this](const ReflectedChange& change) { changes.PushBack(change); });
        }
        const PropertyInfo* Find(const core::Array<PropertyInfo>& infos, const char8_t* name)
        {
            for (const PropertyInfo& info : infos)
                if (info.Name == core::String(name))
                    return &info;
            return nullptr;
        }
        void Commit(const char8_t* path, const Variant& value)
        {
            source.BeginEdit(SV(path));
            source.CommitEdit(SV(path), PropertyWrite{value});
        }
    };
}

TEST_CASE("reflected source: a type's properties as rows, each of its kind, with the attributes the inspector reads")
{
    Bed bed;
    core::Array<PropertyInfo> rows(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8""), rows);
    REQUIRE(rows.Size() == 21u);
    CHECK(rows[0].Name == core::String(u8"name"));
    CHECK(rows[0].DisplayName == core::String(u8"Name"));
    CHECK(rows[0].Description == core::String(u8"What the scene calls it"));
    CHECK(rows[0].Kind == PropertyKind::String);
    CHECK(bed.Find(rows, u8"enabled")->Kind == PropertyKind::Bool);
    CHECK(bed.Find(rows, u8"priority")->Kind == PropertyKind::Integer); // a u8
    const PropertyInfo& intensity = *bed.Find(rows, u8"intensity");
    CHECK(intensity.Kind == PropertyKind::Float);
    CHECK(intensity.HasRange);
    CHECK(intensity.Max == doctest::Approx(100.0));
    CHECK(intensity.Step == doctest::Approx(0.5));
    CHECK(bed.Find(rows, u8"range")->DisplayName == core::String(u8"Reach"));
    const PropertyInfo& kind = *bed.Find(rows, u8"kind");
    CHECK(kind.Kind == PropertyKind::Enum);
    REQUIRE(kind.Choices.Size() == 3u);
    CHECK(kind.Choices[1].Name == core::String(u8"Spot"));
    CHECK(bed.Find(rows, u8"layers")->Kind == PropertyKind::Flags);
    CHECK(bed.Find(rows, u8"coneAngle")->DisplayName == core::String(u8"Cone Angle"));
    CHECK_FALSE(bed.Find(rows, u8"coneAngle")->Visible); // a point light: visibleWhen kind=1
    CHECK(bed.Find(rows, u8"cone")->Hint == core::String(u8"Float2"));
    CHECK(bed.Find(rows, u8"position")->Hint == core::String(u8"Float3"));
    CHECK(bed.Find(rows, u8"rotation")->Hint == core::String(u8"Float3")); // Euler degrees
    CHECK(bed.Find(rows, u8"shape")->Kind == PropertyKind::Group);
    CHECK(bed.Find(rows, u8"shape")->Hint == core::String(u8"LampShape")); // no editor takes it: its rows
    CHECK(bed.Find(rows, u8"tint")->Kind == PropertyKind::Color);
    CHECK(bed.Find(rows, u8"tint")->ShowsAlpha);
    CHECK_FALSE(bed.Find(rows, u8"edge")->ShowsAlpha);
    CHECK(bed.Find(rows, u8"glow")->Hint == core::String(u8"ColorHdr"));
    CHECK(bed.Find(rows, u8"id")->ReadOnly);
    CHECK(bed.Find(rows, u8"exposure")->Kind == PropertyKind::Float); // a setter's

    core::Array<PropertyInfo> parts(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8"rotation"), parts);
    REQUIRE(parts.Size() == 3u);
    CHECK(parts[0].Name == core::String(u8"pitch"));
    parts.Clear();
    bed.source.GetProperties(SV(u8"shape"), parts);
    REQUIRE(parts.Size() == 2u);
    CHECK(parts[1].DisplayName == core::String(u8"Softness"));

    bed.a->kind = reflected::LampKind::Spot;
    rows.Clear();
    bed.source.GetProperties(SV(u8""), rows);
    CHECK(bed.Find(rows, u8"coneAngle")->Visible);
}

TEST_CASE("reflected source: values read and written through addresses and setters, parts and Euler degrees")
{
    Bed bed;
    CHECK(bed.source.GetValue(SV(u8"name"), 0).AsString() == SV(u8"Lamp"));
    CHECK(bed.source.GetValue(SV(u8"priority"), 0).AsInt() == 3);
    CHECK(bed.source.GetValue(SV(u8"position.y"), 0).AsFloat() == doctest::Approx(2.0));
    CHECK(bed.source.GetValue(SV(u8"shape.softness"), 0).AsFloat() == doctest::Approx(0.5));
    CHECK(bed.source.GetValue(SV(u8"kind"), 0).AsInt() == 0);

    bed.Commit(u8"priority", Variant(i64{7}));
    CHECK(bed.a->priority == 7);
    bed.Commit(u8"range", Variant(2.5));
    CHECK(bed.a->range == doctest::Approx(2.5));
    bed.Commit(u8"kind", Variant(i64{2}));
    CHECK(bed.a->kind == reflected::LampKind::Area);
    bed.source.BeginEdit(SV(u8"layers"));
    bed.source.CommitEdit(SV(u8"layers"), PropertyWrite{Variant(i64{4}), 4}); // a flag alone
    CHECK(static_cast<u32>(bed.a->layers) == 5u);
    bed.Commit(u8"position.z", Variant(9.0));
    CHECK(bed.a->position.z == doctest::Approx(9.0f));
    bed.Commit(u8"shape.radius", Variant(4.0));
    CHECK(bed.a->shape.radius == doctest::Approx(4.0f));
    bed.Commit(u8"exposure", Variant(1.5)); // through its setter
    CHECK(bed.a->GetExposure() == doctest::Approx(1.5f));
    CHECK(bed.source.GetValue(SV(u8"exposure"), 0).AsFloat() == doctest::Approx(1.5));

    // A Quaternion's yaw in degrees.
    bed.Commit(u8"rotation.yaw", Variant(90.0));
    CHECK(bed.source.GetValue(SV(u8"rotation.yaw"), 0).AsFloat() == doctest::Approx(90.0).epsilon(0.001));
    f32 yaw = 0.0f, pitch = 0.0f, roll = 0.0f;
    core::ToYawPitchRoll(bed.a->rotation, yaw, pitch, roll);
    CHECK(core::RadiansToDegrees(yaw) == doctest::Approx(90.0f).epsilon(0.001));

    // Read only: refused.
    bed.Commit(u8"id", Variant(i64{5}));
    CHECK(bed.a->id == 101);
}

TEST_CASE("reflected source: several objects mixed, a preview on each, and a commit told as one change Restore reads back")
{
    Bed bed(true);
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    bed.b->intensity = 8.0f;
    CHECK(ReadPropertyValue(bed.source, SV(u8"intensity"), PropertyKind::Float).Mixed);
    CHECK_FALSE(ReadPropertyValue(bed.source, SV(u8"position.x"), PropertyKind::Float).Mixed);

    bed.source.BeginEdit(SV(u8"intensity"));
    bed.source.PreviewEdit(SV(u8"intensity"), PropertyWrite{Variant(20.0)});
    CHECK(bed.a->intensity == doctest::Approx(20.0f));
    CHECK(bed.b->intensity == doctest::Approx(20.0f));
    bed.source.CommitEdit(SV(u8"intensity"), PropertyWrite{Variant(30.0)});
    REQUIRE(bed.changes.Size() == 1u);
    const ReflectedChange& change = bed.changes[0];
    CHECK(change.Path == core::String(u8"intensity"));
    REQUIRE(change.Before.Size() == 2u);

    CHECK(bed.source.Restore(change, true)); // an undo: each its own value back
    CHECK(bed.a->intensity == doctest::Approx(5.0f));
    CHECK(bed.b->intensity == doctest::Approx(8.0f));
    CHECK(bed.source.Restore(change, false)); // a redo
    CHECK(bed.b->intensity == doctest::Approx(30.0f));

    // A group's change is the whole group, so a revert or a paste undoes in one.
    bed.Commit(u8"shape.radius", Variant(6.0));
    bed.a->shape.softness = 0.9f; // changed beside it, outside the source
    bed.source.Restore(bed.changes.Back(), true);
    CHECK(bed.a->shape.radius == doctest::Approx(1.0f));

    // Cancelled: each back.
    bed.source.BeginEdit(SV(u8"range"));
    bed.source.PreviewEdit(SV(u8"range"), PropertyWrite{Variant(99.0)});
    bed.source.CancelEdit(SV(u8"range"));
    CHECK(bed.a->range == doctest::Approx(10.0));
}

TEST_CASE("reflected source: the grid shows it")
{
    Bed bed;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 600.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto grid = core::MakeRef<PropertyGrid>(core::DefaultAllocator());
    grid->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Width = LayoutLength::Px(360.0f);
        s.Height = LayoutLength::Px(560.0f);
    });
    root->AddChild(grid.Get());
    grid->SetSource(&bed.source);
    (void)root->UpdateLayout();
    CHECK(core::Cast<FloatsPropertyEditor>(grid->FindEditor(SV(u8"position"))) != nullptr);
    CHECK(core::Cast<FloatsPropertyEditor>(grid->FindEditor(SV(u8"rotation"))) != nullptr);
    CHECK(core::Cast<ColorPropertyEditor>(grid->FindEditor(SV(u8"tint"))) != nullptr);
    CHECK(core::Cast<HdrColorPropertyEditor>(grid->FindEditor(SV(u8"glow"))) != nullptr);
    CHECK(grid->FindEditor(SV(u8"shape")) == nullptr); // a struct no editor takes: a group of its rows
    CHECK(grid->GetRow(grid->FindRow(SV(u8"shape")))->HasChildren);
    CHECK(core::Cast<EnumPropertyEditor>(grid->FindEditor(SV(u8"kind"))) != nullptr);
    CHECK(core::Cast<FlagsPropertyEditor>(grid->FindEditor(SV(u8"layers"))) != nullptr);
    CHECK(grid->FindRow(SV(u8"coneAngle")) < 0);
    grid->SetSource(nullptr);
}

TEST_CASE("reflected source: arrays and bounded arrays are lists, elements by index, changed in each object as one change")
{
    Bed bed(true);
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    bed.a->weights.PushBack(0.5f);
    bed.a->weights.PushBack(0.25f);
    bed.b->weights.PushBack(0.5f);
    bed.b->weights.PushBack(0.75f);
    bed.b->weights.PushBack(1.0f);
    core::Array<PropertyInfo> rows(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8""), rows);
    const PropertyInfo& weights = *bed.Find(rows, u8"weights");
    CHECK(weights.Kind == PropertyKind::List);
    CHECK(weights.ListOps == (PropertyListAdd | PropertyListRemove | PropertyListMove));
    CHECK(ReadPropertyValue(bed.source, SV(u8"weights"), PropertyKind::List).Mixed); // two and three
    core::Array<PropertyInfo> elements(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8"weights"), elements);
    REQUIRE(elements.Size() == 2u); // the fewest
    CHECK(elements[1].Kind == PropertyKind::Float);
    CHECK(elements[1].DisplayName == core::String(u8"Element 2"));
    CHECK(ReadPropertyValue(bed.source, SV(u8"weights.1"), PropertyKind::Float).Mixed);

    bed.Commit(u8"weights.1", Variant(2.0));
    CHECK(bed.b->weights[1] == doctest::Approx(2.0f));
    ListEdit move;
    move.Kind = ListEdit::Op::Move;
    move.Index = 1;
    move.To = 0;
    REQUIRE(bed.source.EditList(SV(u8"weights"), move));
    CHECK(bed.a->weights[0] == doctest::Approx(2.0f));
    CHECK(bed.b->weights[2] == doctest::Approx(1.0f)); // b's third stays
    ListEdit add;
    add.Kind = ListEdit::Op::Insert;
    add.Index = 99;
    REQUIRE(bed.source.EditList(SV(u8"weights"), add));
    CHECK(bed.a->weights.Size() == 3u);
    CHECK(bed.b->weights.Size() == 4u);

    // An undo of the add puts each object's list back as it was.
    CHECK(bed.source.Restore(bed.changes.Back(), true));
    CHECK(bed.a->weights.Size() == 2u);
    CHECK(bed.b->weights.Size() == 3u);
    CHECK(bed.b->weights[2] == doctest::Approx(1.0f));

    // A bounded array: its count, at most its capacity, which its row says; an Array has no most.
    core::Array<PropertyInfo> top(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8""), top);
    CHECK(bed.Find(top, u8"steps")->MaxCount == 3u);
    CHECK(bed.Find(top, u8"weights")->MaxCount == 0u);
    elements.Clear();
    bed.source.GetProperties(SV(u8"steps"), elements);
    CHECK(elements.Size() == 2u);
    REQUIRE(bed.source.EditList(SV(u8"steps"), add));
    CHECK(bed.a->stepCount == 3);
    CHECK_FALSE(bed.source.EditList(SV(u8"steps"), add)); // full
}

TEST_CASE("reflected source: a polymorphic list adds by type, its elements' own properties, and an undo rebuilds it")
{
    Bed bed;
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    core::Array<PropertyInfo> rows(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8""), rows);
    const PropertyInfo& effects = *bed.Find(rows, u8"effects");
    REQUIRE(effects.ElementTypes.Size() == 2u);
    CHECK(effects.ElementTypes[0] == core::String(u8"Flicker"));
    CHECK(effects.ElementTypes[1] == core::String(u8"Pulse"));

    ListEdit add;
    add.Kind = ListEdit::Op::Insert;
    add.ElementType = core::String(u8"Pulse");
    REQUIRE(bed.source.EditList(SV(u8"effects"), add));
    add.Index = 1;
    add.ElementType = core::String(u8"Flicker");
    REQUIRE(bed.source.EditList(SV(u8"effects"), add));
    REQUIRE(bed.a->effects.Size() == 2u);
    CHECK(core::Cast<reflected::TestPulse>(bed.a->effects[0].Get()) != nullptr);

    core::Array<PropertyInfo> elements(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8"effects"), elements);
    REQUIRE(elements.Size() == 2u);
    CHECK(elements[0].DisplayName == core::String(u8"Pulse 1"));
    core::Array<PropertyInfo> pulse(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8"effects.0"), pulse);
    REQUIRE(pulse.Size() == 2u); // its base's strength, then its period
    CHECK(pulse[1].Name == core::String(u8"period"));
    bed.Commit(u8"effects.0.period", Variant(5.0));
    CHECK(core::Cast<reflected::TestPulse>(bed.a->effects[0].Get())->period == doctest::Approx(5.0f));

    // Removing the pulse and undoing it makes a pulse again, with its period.
    const usize before = bed.changes.Size();
    ListEdit remove;
    remove.Kind = ListEdit::Op::Remove;
    remove.Index = 0;
    REQUIRE(bed.source.EditList(SV(u8"effects"), remove));
    REQUIRE(bed.changes.Size() == before + 1);
    CHECK(core::Cast<reflected::TestFlicker>(bed.a->effects[0].Get()) != nullptr);
    CHECK(bed.source.Restore(bed.changes.Back(), true));
    REQUIRE(bed.a->effects.Size() == 2u);
    reflected::TestPulse* back = core::Cast<reflected::TestPulse>(bed.a->effects[0].Get());
    REQUIRE(back != nullptr);
    CHECK(back->period == doctest::Approx(5.0f));
}

TEST_CASE("reflected source: the type's defaults from its creator, providers over them, and a revert of each object's own")
{
    Bed bed(true);
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    CHECK(bed.source.GetDefault(SV(u8"intensity"), 0).AsFloat() == doctest::Approx(5.0));
    CHECK(bed.source.GetDefault(SV(u8"position.z"), 1).AsFloat() == doctest::Approx(3.0));
    CHECK(bed.source.GetDefault(SV(u8"weights"), 0).AsInt() == 0);
    CHECK(bed.source.GetDefault(SV(u8"id"), 0).IsEmpty()); // read only: nothing to put back
    CHECK(bed.source.GetRevertText(SV(u8"intensity")) == core::String(u8"Revert to default"));

    // A prefab for the second object: its intensity 9.
    bed.source.PushDefaults([](core::StringView path, usize object) -> Variant
                            { return object == 1 && path == core::StringView(u8"intensity") ? Variant(9.0) : Variant{}; },
                            SV(u8"Revert to prefab"));
    CHECK(bed.source.GetDefault(SV(u8"intensity"), 1).AsFloat() == doctest::Approx(9.0));
    CHECK(bed.source.GetDefault(SV(u8"intensity"), 0).AsFloat() == doctest::Approx(5.0));
    CHECK(bed.source.GetRevertText(SV(u8"intensity")) == core::String(u8"Revert to prefab"));

    bed.a->intensity = 1.0f;
    bed.b->intensity = 1.0f;
    bed.a->shape.radius = 7.0f;
    bed.b->position.x = 8.0f;
    bed.a->weights.PushBack(0.5f);
    REQUIRE(bed.source.Revert(SV(u8"intensity")));
    CHECK(bed.a->intensity == doctest::Approx(5.0f));
    CHECK(bed.b->intensity == doctest::Approx(9.0f)); // each its own
    REQUIRE(bed.source.Revert(SV(u8"shape")));
    CHECK(bed.a->shape.radius == doctest::Approx(1.0f));
    REQUIRE(bed.source.Revert(SV(u8"position")));
    CHECK(bed.b->position.x == doctest::Approx(1.0f));
    REQUIRE(bed.source.Revert(SV(u8"weights")));
    CHECK(bed.a->weights.IsEmpty());
    CHECK_FALSE(bed.source.Revert(SV(u8"weights"))); // nothing left
    CHECK(bed.changes.Size() == 4u); // one change each

    // An undo of a revert puts the edit back.
    CHECK(bed.source.Restore(bed.changes[0], true));
    CHECK(bed.b->intensity == doctest::Approx(1.0f));
}

TEST_CASE("reflected source: copy and paste through the text format, one change, its like only")
{
    Bed bed(true);
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    bed.a->position = core::Float3{4.0f, 5.0f, 6.0f};
    const core::String position = bed.source.CopyValue(SV(u8"position"));
    REQUIRE(position.Size() != 0);

    // A Float3 onto a rotation's Euler degrees: each object turned the same.
    core::String reason;
    REQUIRE(bed.source.PasteValue(SV(u8"rotation"), position.AsView(), reason));
    CHECK(bed.source.GetValue(SV(u8"rotation.pitch"), 1).AsFloat() == doctest::Approx(4.0).epsilon(0.001));
    CHECK(bed.changes.Size() == 1u);
    // Onto a Float2: refused, saying why.
    CHECK_FALSE(bed.source.PasteValue(SV(u8"cone"), position.AsView(), reason));
    CHECK(reason == core::String(u8"A Float3 does not paste onto a Float2"));
    CHECK_FALSE(bed.source.PasteValue(SV(u8"id"), position.AsView(), reason));

    // A struct whole, and a list with its elements.
    bed.a->shape.radius = 3.0f;
    const core::String shape = bed.source.CopyValue(SV(u8"shape"));
    REQUIRE(bed.source.PasteValue(SV(u8"shape"), shape.AsView(), reason));
    CHECK(bed.b->shape.radius == doctest::Approx(3.0f));
    bed.a->weights.PushBack(0.1f);
    bed.a->weights.PushBack(0.2f);
    const core::String weights = bed.source.CopyValue(SV(u8"weights"));
    REQUIRE(bed.source.PasteValue(SV(u8"weights"), weights.AsView(), reason));
    REQUIRE(bed.b->weights.Size() == 2u);
    CHECK(bed.b->weights[1] == doctest::Approx(0.2f));

    // A paste undoes in one.
    CHECK(bed.source.Restore(bed.changes.Back(), true));
    CHECK(bed.b->weights.IsEmpty());
}

TEST_CASE("reflected source: a Color is a colour; an HDR colour its colour and its intensity, in stops on its row")
{
    Bed bed(true);
    reflected::BlobFormat format;
    bed.source.SetTextFormat(&format);
    CHECK(bed.source.GetValue(SV(u8"tint"), 0).AsColor().r == doctest::Approx(1.0f));
    bed.b->tint = core::Color{0.0f, 1.0f, 0.0f, 1.0f};
    CHECK(ReadPropertyValue(bed.source, SV(u8"tint"), PropertyKind::Color).Mixed);
    bed.Commit(u8"tint", Variant(core::Color{0.2f, 0.4f, 0.6f, 0.5f}));
    CHECK(bed.b->tint.g == doctest::Approx(0.4f));
    CHECK(bed.source.Restore(bed.changes.Back(), true));
    CHECK(bed.b->tint.g == doctest::Approx(1.0f));

    core::Array<PropertyInfo> parts(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8"glow"), parts);
    REQUIRE(parts.Size() == 2u);
    CHECK(parts[0].Kind == PropertyKind::Color);
    CHECK_FALSE(parts[0].ShowsAlpha);
    CHECK(parts[1].Hint == core::String(u8"stops"));
    CHECK(bed.source.GetValue(SV(u8"glow.color"), 0).AsColor().g == doctest::Approx(0.5f));
    CHECK(bed.source.GetValue(SV(u8"glow.intensity"), 0).AsFloat() == doctest::Approx(4.0));
    bed.Commit(u8"glow.color", Variant(core::Color{0.0f, 0.0f, 1.0f, 1.0f}));
    CHECK(bed.a->glow.z == doctest::Approx(1.0f));
    CHECK(bed.a->glow.w == doctest::Approx(4.0f)); // its intensity kept
    bed.Commit(u8"glow.intensity", Variant(8.0));
    CHECK(bed.b->glow.w == doctest::Approx(8.0f));
    CHECK(bed.b->glow.z == doctest::Approx(1.0f));

    // A colour copied pastes onto an HDR colour's colour part; reverted, the type's comes back.
    const core::String tint = bed.source.CopyValue(SV(u8"tint"));
    core::String reason;
    REQUIRE(bed.source.PasteValue(SV(u8"glow.color"), tint.AsView(), reason));
    CHECK(bed.a->glow.x == doctest::Approx(1.0f));
    REQUIRE(bed.source.Revert(SV(u8"glow")));
    CHECK(bed.a->glow.y == doctest::Approx(0.5f));
    CHECK(bed.b->glow.w == doctest::Approx(4.0f));
}

TEST_CASE("reflected source: the stops editor shows log2 of the intensity and writes 2 to its stops")
{
    Bed bed;
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 900.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto grid = core::MakeRef<PropertyGrid>(core::DefaultAllocator());
    grid->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Width = LayoutLength::Px(360.0f);
        s.Height = LayoutLength::Px(860.0f);
    });
    root->AddChild(grid.Get());
    grid->SetSource(&bed.source);
    (void)root->UpdateLayout();
    HdrColorPropertyEditor* glow = core::Cast<HdrColorPropertyEditor>(grid->FindEditor(SV(u8"glow")));
    REQUIRE(glow != nullptr);
    NumberField& stops = *glow->GetIntensityPart()->GetField();
    CHECK(stops.GetValue() == doctest::Approx(2.0)); // 4 is two stops
    stops.RequestFocus();
    for (int i = 0; i < 10; ++i)
        root->GetEventDispatcher()->InjectKeyDown(static_cast<core::u32>(KeyCode::Up)); // a stop more
    CHECK(bed.a->glow.w == doctest::Approx(8.0f).epsilon(0.01));
    grid->SetSource(nullptr);
}

namespace
{
    // Two emitters, their curve and gradient registered as the application would.
    struct EmitterBed
    {
        core::RefPtr<reflected::TestEmitter> a = core::MakeRef<reflected::TestEmitter>(core::DefaultAllocator());
        core::RefPtr<reflected::TestEmitter> b = core::MakeRef<reflected::TestEmitter>(core::DefaultAllocator());
        ReflectedPropertySource source{core::DefaultAllocator()};
        reflected::BlobFormat format;
        core::Array<ReflectedChange> changes{core::DefaultAllocator()};

        EmitterBed()
        {
            reflected::Register();
            source.RegisterCurveType(SV(u8"TestCurve"), ReflectedCurveParts{core::String(u8"keys")});
            source.RegisterGradientType(SV(u8"TestGradient"), ReflectedGradientParts{core::String(u8"colors"), core::String(u8"alphas"),
                                                                                    core::String(u8"interpolation")});
            core::Instance objects[] = {core::Instance(a.Get(), a->GetType()), core::Instance(b.Get(), b->GetType())};
            source.SetObjects(objects);
            source.SetTextFormat(&format);
            source.SetOnChange([this](const ReflectedChange& change) { changes.PushBack(change); });
        }
        [[nodiscard]] static core::Array<core::CurveKey> Keys(std::initializer_list<core::CurveKey> keys)
        {
            core::Array<core::CurveKey> out(core::DefaultAllocator());
            for (const core::CurveKey& key : keys)
                out.PushBack(key);
            return out;
        }
    };
    core::CurveKey K(f32 time, f32 value)
    {
        return core::CurveKey{time, value, 0.0f, 0.0f, core::CurveKeyInterpolation::Linear, core::CurveTangentMode::Broken};
    }
}

TEST_CASE("reflected source: a registered curve and gradient are one value each, of their kind, their most their lists' capacity")
{
    EmitterBed bed;
    core::Array<PropertyInfo> rows(core::DefaultAllocator());
    bed.source.GetProperties(SV(u8""), rows);
    REQUIRE(rows.Size() == 3u);
    CHECK(rows[0].Kind == PropertyKind::Curve);
    CHECK(rows[0].MaxCount == 4u);
    CHECK(rows[0].HasRange);
    CHECK(rows[0].Max == doctest::Approx(4.0));
    CHECK(rows[1].Kind == PropertyKind::Gradient);
    CHECK(rows[1].MaxCount == 3u);

    const Variant size = bed.source.GetValue(SV(u8"size"), 0);
    REQUIRE(size.GetType() == Variant::Type::Curve);
    REQUIRE(size.AsCurve().Size() == 2u);
    CHECK(size.AsCurve()[0].value == doctest::Approx(1.0f));
    const Variant color = bed.source.GetValue(SV(u8"color"), 1);
    REQUIRE(color.GetType() == Variant::Type::Gradient);
    CHECK(color.AsGradient().Colors.Size() == 1u);
    CHECK(color.AsGradient().Alphas.Size() == 2u);

    // Unregistered, the same type is a struct of its own rows.
    ReflectedPropertySource plain{core::DefaultAllocator()};
    core::Instance one[] = {core::Instance(bed.a.Get(), bed.a->GetType())};
    plain.SetObjects(one);
    rows.Clear();
    plain.GetProperties(SV(u8""), rows);
    CHECK(rows[0].Kind == PropertyKind::Group);
    CHECK(rows[0].Hint == core::String(u8"TestCurve"));
}

TEST_CASE("reflected source: a curve written whole on each object, previewed, committed as one change an undo reads back")
{
    EmitterBed bed;
    const core::Array<core::CurveKey> three = EmitterBed::Keys({K(0.0f, 0.0f), K(0.5f, 2.0f), K(1.0f, 1.0f)});
    bed.source.BeginEdit(SV(u8"size"));
    bed.source.PreviewEdit(SV(u8"size"), PropertyWrite{Variant::FromCurve(three.AsSpan())});
    CHECK(bed.a->size.keyCount == 3);
    CHECK(bed.b->size.keys[1].value == doctest::Approx(2.0f));
    bed.source.CommitEdit(SV(u8"size"), PropertyWrite{Variant::FromCurve(three.AsSpan())});
    REQUIRE(bed.changes.Size() == 1u);
    CHECK(bed.b->size.keyCount == 3);

    // Its most: five keys keep four.
    const core::Array<core::CurveKey> five = EmitterBed::Keys({K(0.0f, 0.0f), K(0.2f, 1.0f), K(0.4f, 0.0f), K(0.6f, 1.0f), K(0.8f, 0.0f)});
    bed.source.BeginEdit(SV(u8"size"));
    bed.source.CommitEdit(SV(u8"size"), PropertyWrite{Variant::FromCurve(five.AsSpan())});
    CHECK(bed.a->size.keyCount == 4);

    // A cancel puts each back.
    bed.source.BeginEdit(SV(u8"size"));
    bed.source.PreviewEdit(SV(u8"size"), PropertyWrite{Variant::FromCurve(three.AsSpan())});
    bed.source.CancelEdit(SV(u8"size"));
    CHECK(bed.a->size.keyCount == 4);

    // Undo the first: the two keys each had.
    REQUIRE(bed.source.Restore(bed.changes[0], true));
    CHECK(bed.a->size.keyCount == 2);
    CHECK(bed.b->size.keys[0].value == doctest::Approx(1.0f));
    REQUIRE(bed.source.Restore(bed.changes[0], false));
    CHECK(bed.b->size.keyCount == 3);
    CHECK(bed.b->size.keys[1].time == doctest::Approx(0.5f));
}

TEST_CASE("reflected source: a gradient written whole, its blend too; mixed, reverted, copied and pasted as one value")
{
    EmitterBed bed;
    ColorGradient gradient;
    gradient.Colors.PushBack(core::GradientColorStop{0.0f, core::Color{1.0f, 0.0f, 0.0f, 1.0f}});
    gradient.Colors.PushBack(core::GradientColorStop{1.0f, core::Color{0.0f, 0.0f, 1.0f, 1.0f}});
    gradient.Alphas.PushBack(core::GradientAlphaStop{0.0f, 0.5f});
    gradient.Interpolation = core::GradientInterpolation::OkLab;
    bed.source.BeginEdit(SV(u8"color"));
    bed.source.CommitEdit(SV(u8"color"), PropertyWrite{Variant(gradient)});
    CHECK(bed.a->color.colorCount == 2);
    CHECK(bed.b->color.alphaCount == 1);
    CHECK(bed.b->color.interpolation == core::GradientInterpolation::OkLab);
    CHECK(bed.source.GetValue(SV(u8"color"), 0).AsGradient() == gradient);

    // Mixed when one differs.
    bed.b->size.keys[0].value = 3.0f;
    CHECK(ReadPropertyValue(bed.source, SV(u8"size"), PropertyKind::Curve).Mixed);
    CHECK_FALSE(ReadPropertyValue(bed.source, SV(u8"color"), PropertyKind::Gradient).Mixed);

    // Reverted to the type's own.
    REQUIRE(bed.source.Revert(SV(u8"color")));
    CHECK(bed.a->color.colorCount == 1);
    CHECK(bed.b->color.interpolation == core::GradientInterpolation::Srgb);

    // Copied from the first, pasted onto both: its like only.
    bed.a->size.keys[1].value = 2.5f;
    const core::String copied = bed.source.CopyValue(SV(u8"size"));
    REQUIRE(copied.Size() != 0);
    core::String reason;
    REQUIRE(bed.source.PasteValue(SV(u8"size"), copied.AsView(), reason));
    CHECK(bed.b->size.keys[0].value == doctest::Approx(1.0f));
    CHECK(bed.b->size.keys[1].value == doctest::Approx(2.5f));
    CHECK_FALSE(bed.source.PasteValue(SV(u8"color"), copied.AsView(), reason));
    CHECK(reason == core::String(u8"A TestCurve does not paste onto a TestGradient"));
}
