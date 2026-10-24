// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUISandbox - the Toolkit page's reflected object (T3 of Specs/gui-lab-evolution-3.md): a camera
// rig declared with core reflection and nothing else, which the toolkit's ReflectedPropertySource
// shows: values with ranges and names, an enum, flags by attribute, a Float3, a Quaternion as Euler
// degrees, a Color, an HDR glow (a colour and an intensity in stops), a nested lens, a list of stops, a polymorphic list
// of effects added by type, a read-only serial, a field shown only for one projection, and a sky
// over the day (T5): Core's gradient stops in fixed arrays, which the page registers with the source
// as a gradient. Its text format is the engine's XmlSerializer.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module gui.sandbox.camera;

import foundation.core;
import foundation.xml;
import foundation.xml.serialization;
import foundation.gui.toolkit;

using namespace foundation::core;
namespace core = foundation::core;
namespace gui = foundation::gui;
namespace xml = foundation::xml;

export namespace sandbox
{
    enum class Projection : u8
    {
        Perspective,
        Orthographic,
    };
    enum class CameraLayers : u32
    {
        None = 0,
        World = 1,
        Characters = 2,
        Effects = 4,
        Interface = 8,
    };

    struct Lens
    {
        f32 focalLength = 35.0f;
        f32 aperture = 2.8f;
        bool autoFocus = true;
    };

    /// The sky's colour over a day, 0 midnight to 1 the next: Core's stops in fixed arrays, as a
    /// particle effect's colour over life keeps them; the page registers it as a gradient.
    struct SkyGradient
    {
        static constexpr i32 kMostStops = 6;
        GradientColorStop colors[kMostStops] = {
            {0.0f, Color{0.03f, 0.04f, 0.12f, 1.0f}},
            {0.25f, Color{0.95f, 0.55f, 0.3f, 1.0f}},
            {0.5f, Color{0.45f, 0.7f, 1.0f, 1.0f}},
            {0.75f, Color{0.9f, 0.4f, 0.35f, 1.0f}},
            {1.0f, Color{0.03f, 0.04f, 0.12f, 1.0f}},
        };
        i32 colorCount = 5;
        GradientAlphaStop alphas[kMostStops] = {{0.0f, 1.0f}};
        i32 alphaCount = 1;
        GradientInterpolation interpolation = GradientInterpolation::OkLab;
    };

    class CameraEffect : public Object
    {
        RTTI_OBJECT(CameraEffect, Object)
    public:
        f32 strength = 1.0f;
    };
    class BloomEffect : public CameraEffect
    {
        RTTI_OBJECT(BloomEffect, CameraEffect)
    public:
        f32 threshold = 0.8f;
    };
    class VignetteEffect : public CameraEffect
    {
        RTTI_OBJECT(VignetteEffect, CameraEffect)
    public:
        f32 radius = 0.75f;
        Color tint{0.0f, 0.0f, 0.0f, 1.0f};
    };

    class CameraRig : public Object
    {
        RTTI_OBJECT(CameraRig, Object)
    public:
        String name = String(u8"Camera");
        bool enabled = true;
        Projection projection = Projection::Perspective;
        f32 fieldOfView = 60.0f;
        f32 orthographicSize = 5.0f;
        f32 nearPlane = 0.1f;
        f32 farPlane = 500.0f;
        CameraLayers layers = static_cast<CameraLayers>(1 | 2 | 4 | 8);
        Float3 position{0.0f, 2.0f, -6.0f};
        Quaternion rotation = Quaternion::Identity;
        Color background{0.1f, 0.12f, 0.16f, 1.0f};
        Float4 glow{1.0f, 0.75f, 0.4f, 2.0f}; // an HDR colour: sRGB rgb, a linear intensity in w
        Lens lens;
        SkyGradient sky;
        Array<f32> exposureStops;
        Array<RefPtr<CameraEffect>> effects;
        u32 serial = 0;
        i32 priority = 0;
    };

    /// Registers the camera's reflection (once); an effect added by type is made from `allocator`
    /// (the sandbox's own).
    void RegisterCameraTypes(IAllocator& allocator);

    /// The engine's XmlSerializer as the reflected source's text format.
    class XmlTextFormat : public gui::IPropertyTextFormat
    {
    public:
        explicit XmlTextFormat(IAllocator& allocator) : m_allocator(allocator) {}
        String Write(Function<void(ISerializer&)> write) override
        {
            xml::XmlSerializer ar(m_allocator);
            write(ar);
            String text;
            ar.GetOutput(text);
            return ar.IsOk() ? text : String{};
        }
        bool Read(StringView text, Function<void(ISerializer&)> read) override
        {
            xml::XmlDocument doc(m_allocator);
            if (doc.Parse(text) != xml::XmlResult::Ok)
                return false;
            xml::XmlSerializer ar(doc);
            read(ar);
            return ar.IsOk();
        }

    private:
        IAllocator& m_allocator;
    };
}
