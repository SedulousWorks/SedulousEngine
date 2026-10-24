// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUISandbox - the camera rig's reflection: what the Toolkit page's reflected grid shows of it.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

module gui.sandbox.camera;

import foundation.core;

using namespace foundation::core;
namespace core = foundation::core;

namespace sandbox
{
    REFLECT_ENUM(Projection, "rtti::sandbox")
    {
        builder.Value("Perspective", Projection::Perspective);
        builder.Value("Orthographic", Projection::Orthographic);
    }
    REFLECT_ENUM(CameraLayers, "rtti::sandbox")
    {
        builder.Value("World", CameraLayers::World);
        builder.Value("Characters", CameraLayers::Characters);
        builder.Value("Effects", CameraLayers::Effects);
        builder.Value("Interface", CameraLayers::Interface);
    }
    REFLECT_VALUE(Lens, "rtti::sandbox")
    {
        builder.Property<&Lens::focalLength>("focalLength").PropAttribute("range", Float4{8.0f, 300.0f, 1.0f, 0.0f});
        builder.Property<&Lens::aperture>("aperture").PropAttribute("range", Float4{1.0f, 22.0f, 0.1f, 0.0f});
        builder.Property<&Lens::autoFocus>("autoFocus");
    }

    REFLECT_VALUE(SkyGradient, "rtti::sandbox")
    {
        builder.BoundedArray<&SkyGradient::colors, &SkyGradient::colorCount>("colors")
            .Property<&SkyGradient::colorCount>("colorCount")
            .BoundedArray<&SkyGradient::alphas, &SkyGradient::alphaCount>("alphas")
            .Property<&SkyGradient::alphaCount>("alphaCount")
            .Property<&SkyGradient::interpolation>("interpolation");
    }

    REFLECT_MEMBERS(CameraEffect, "rtti::sandbox")
    {
        builder.Property<&CameraEffect::strength>("strength").PropAttribute("range", Float4{0.0f, 1.0f, 0.05f, 0.0f});
    }
    REFLECT_MEMBERS(BloomEffect, "rtti::sandbox")
    {
        builder.Attribute("displayName", String(u8"Bloom"));
        builder.Property<&BloomEffect::threshold>("threshold");
        builder.Creator();
    }
    REFLECT_MEMBERS(VignetteEffect, "rtti::sandbox")
    {
        builder.Attribute("displayName", String(u8"Vignette"));
        builder.Property<&VignetteEffect::radius>("radius");
        builder.Property<&VignetteEffect::tint>("tint").PropAttribute("noAlpha", true);
        builder.Creator();
    }

    REFLECT_MEMBERS(CameraRig, "rtti::sandbox")
    {
        builder.Property<&CameraRig::name>("name").PropAttribute("description", String(u8"What the scene calls it"));
        builder.Property<&CameraRig::enabled>("enabled");
        builder.Property<&CameraRig::projection>("projection");
        builder.Property<&CameraRig::fieldOfView>("fieldOfView")
            .PropAttribute("range", Float4{10.0f, 120.0f, 0.5f, 0.0f})
            .PropAttribute("visibleWhen", String(u8"projection=0"));
        builder.Property<&CameraRig::orthographicSize>("orthographicSize").PropAttribute("visibleWhen", String(u8"projection=1"));
        builder.Property<&CameraRig::nearPlane>("nearPlane").PropAttribute("displayName", String(u8"Near"));
        builder.Property<&CameraRig::farPlane>("farPlane").PropAttribute("displayName", String(u8"Far"));
        builder.Property<&CameraRig::layers>("layers").PropAttribute("flags", true).PropAttribute("description", String(u8"What it draws"));
        builder.Property<&CameraRig::position>("position");
        builder.Property<&CameraRig::rotation>("rotation").PropAttribute("description", String(u8"A Quaternion, shown in Euler degrees"));
        builder.Property<&CameraRig::background>("background").PropAttribute("description", String(u8"A Color, its sRGB values"));
        builder.Property<&CameraRig::glow>("glow")
            .PropAttribute("hdrColor", true)
            .PropAttribute("description", String(u8"An HDR colour: its colour, and its intensity in exposure stops"));
        builder.Property<&CameraRig::lens>("lens");
        builder.Property<&CameraRig::sky>("sky").PropAttribute("description", String(u8"Its colour over a day: click for the gradient"));
        builder.Nested<&CameraRig::exposureStops>("exposureStops");
        builder.Nested<&CameraRig::effects>("effects");
        builder.Property<&CameraRig::serial>("serial", PropertyFlags::ReadOnly).PropAttribute("description", String(u8"Given by the scene: read only"));
        builder.Property<&CameraRig::priority>("priority");
        builder.Creator();
    }

    namespace
    {
        IAllocator* g_effectAllocator = nullptr; // the sandbox's, given at registration

        RefPtr<CameraEffect> CreateEffect(const TypeInfo& type)
        {
            if (g_effectAllocator == nullptr)
                return {};
            RefPtr<Object> made = CreateObject(type, *g_effectAllocator);
            return RefPtr<CameraEffect>(Cast<CameraEffect>(made.Get()));
        }
        bool CanCreateEffect(const TypeInfo& type) { return type.creator != nullptr; }
    }

    void RegisterCameraTypes(IAllocator& allocator)
    {
        g_effectAllocator = &allocator;
        static const bool once = []()
        {
            RttiRegisterEnum_Projection();
            RttiRegisterEnum_CameraLayers();
            RttiRegisterValue_Lens();
            RttiRegisterValue_SkyGradient();
            RegisterArrayType<f32>();
            RegisterPolymorphicArrayType<CameraEffect>(&CreateEffect, &CanCreateEffect);
            GlobalTypeRegistry().Register(CameraEffect::StaticType());
            GlobalTypeRegistry().Register(BloomEffect::StaticType());
            GlobalTypeRegistry().Register(VignetteEffect::StaticType());
            return true;
        }();
        (void)once;
    }
}
