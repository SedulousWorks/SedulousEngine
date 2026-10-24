// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Transformable tests. Derived from eepp Transformable behavior
// (position/rotation/scale composed into a lazily-cached transform).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    constexpr float kHalfPi = 1.57079632679489662f;

    void CheckPoint(core::Float2 got, float x, float y)
    {
        CHECK(got.x == doctest::Approx(x));
        CHECK(got.y == doctest::Approx(y));
    }
}

TEST_CASE("transformable: defaults are identity")
{
    Transformable t;
    CHECK(t.GetPosition() == core::Float2{0.0f, 0.0f});
    CHECK(t.GetScale() == core::Float2{1.0f, 1.0f});
    CHECK(t.GetRotation() == 0.0f);
    CHECK(t.GetTransform().IsIdentity());
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{3.0f, 4.0f}), 3.0f, 4.0f);
}

TEST_CASE("transformable: position translates points")
{
    Transformable t;
    t.SetPosition(core::Float2{10.0f, 20.0f});
    CHECK(t.GetPosition() == core::Float2{10.0f, 20.0f});
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{0.0f, 0.0f}), 10.0f, 20.0f);
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{5.0f, 5.0f}), 15.0f, 25.0f);
}

TEST_CASE("transformable: scale about origin")
{
    Transformable t;
    t.SetScaleOrigin(core::Float2{10.0f, 10.0f});
    t.SetScale(core::Float2{2.0f, 2.0f});
    // The scale origin stays fixed.
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{10.0f, 10.0f}), 10.0f, 10.0f);
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{11.0f, 10.0f}), 12.0f, 10.0f);
}

TEST_CASE("transformable: rotation about origin")
{
    Transformable t;
    t.SetRotationOrigin(core::Float2{5.0f, 5.0f});
    t.SetRotation(kHalfPi);
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{5.0f, 5.0f}), 5.0f,
               5.0f); // pivot fixed
}

TEST_CASE("transformable: relative move/rotate/scale")
{
    Transformable t;
    t.Move(core::Float2{1.0f, 2.0f});
    t.Move(core::Float2{3.0f, 4.0f});
    CHECK(t.GetPosition() == core::Float2{4.0f, 6.0f});

    t.Scale(core::Float2{2.0f, 3.0f});
    t.Scale(core::Float2{2.0f, 1.0f});
    CHECK(t.GetScale() == core::Float2{4.0f, 3.0f});

    t.Rotate(0.5f);
    t.Rotate(0.25f);
    CHECK(t.GetRotation() == doctest::Approx(0.75f));
}

TEST_CASE("transformable: inverse round-trips")
{
    Transformable t;
    t.SetPosition(core::Float2{10.0f, -5.0f});
    t.SetScale(core::Float2{2.0f, 4.0f});
    const core::Float2 p{3.0f, 7.0f};
    const core::Float2 mapped = t.GetTransform().TransformPoint(p);
    CheckPoint(t.GetInverseTransform().TransformPoint(mapped), p.x, p.y);
}

TEST_CASE("transformable: transform recomputes after change")
{
    Transformable t;
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{0.0f, 0.0f}), 0.0f, 0.0f);
    t.SetPosition(core::Float2{100.0f, 0.0f});
    CheckPoint(t.GetTransform().TransformPoint(core::Float2{0.0f, 0.0f}), 100.0f, 0.0f);
}
