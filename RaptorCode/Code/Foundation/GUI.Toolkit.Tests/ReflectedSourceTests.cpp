// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the reflected property source's tests, what is left of them after the GUI.Toolkit
// port: those of what the GUI's reflection table cannot carry (lists and their elements, a
// polymorphic list's types, the HDR colour's stops editor, the types registered as a curve or a
// gradient). Of the cases ported, these checks stayed here: a property's attributes
// (displayName, description, range, visibleWhen, noAlpha, hdrColor), an enum's choices and flags,
// a value struct as a group (LampShape is a node there), the lists' default, revert and paste, the
// HDR colour's parts, a registered curve's most keys and range, and the reasons naming registered
// types. The rest is Code/Foundation/Sedulous.GUI.Toolkit.Tests/src/ReflectedSourceTests.bf.
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
