// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Transform2D tests. Derived from eepp Transform behavior (translate/
// rotate/scale/combine/inverse/transformPoint), plus a check that ToMatrix() feeds
// core::TransformPoint2D (the VG DrawContext convention) identically.
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

TEST_CASE("transform2d: default is identity")
{
    Transform2D t;
    CHECK(t.IsIdentity());
    CheckPoint(t.TransformPoint(core::Float2{7.0f, 9.0f}), 7.0f, 9.0f);
}

TEST_CASE("transform2d: translate")
{
    Transform2D t;
    t.Translate(10.0f, 20.0f);
    CHECK_FALSE(t.IsIdentity());
    CheckPoint(t.TransformPoint(core::Float2{0.0f, 0.0f}), 10.0f, 20.0f);
    CheckPoint(t.TransformPoint(core::Float2{5.0f, 5.0f}), 15.0f, 25.0f);
}

TEST_CASE("transform2d: scale")
{
    Transform2D t;
    t.Scale(2.0f, 3.0f);
    CheckPoint(t.TransformPoint(core::Float2{4.0f, 5.0f}), 8.0f, 15.0f);
}

TEST_CASE("transform2d: rotate 90 degrees")
{
    Transform2D t;
    t.Rotate(kHalfPi);
    CheckPoint(t.TransformPoint(core::Float2{1.0f, 0.0f}), 0.0f, 1.0f);
    CheckPoint(t.TransformPoint(core::Float2{0.0f, 1.0f}), -1.0f, 0.0f);
}

TEST_CASE("transform2d: rotate about center leaves center fixed")
{
    Transform2D t;
    t.Rotate(kHalfPi, core::Float2{5.0f, 5.0f});
    CheckPoint(t.TransformPoint(core::Float2{5.0f, 5.0f}), 5.0f, 5.0f);
}

TEST_CASE("transform2d: combine applies right-hand first")
{
    // Translate(10,0) then Scale(2,2): a point is scaled first, then translated.
    Transform2D t;
    t.Translate(10.0f, 0.0f).Scale(2.0f, 2.0f);
    CheckPoint(t.TransformPoint(core::Float2{1.0f, 1.0f}), 12.0f, 2.0f);
}

TEST_CASE("transform2d: operator* matches Combine")
{
    Transform2D a;
    a.Translate(3.0f, 4.0f);
    Transform2D b;
    b.Scale(2.0f, 5.0f);
    Transform2D combined = a;
    combined.Combine(b);
    Transform2D product = a * b;
    CHECK(NearlyEqual(combined, product));
}

TEST_CASE("transform2d: inverse round-trips")
{
    Transform2D t;
    t.Translate(10.0f, -3.0f).Scale(2.0f, 4.0f).Rotate(0.7f);
    Transform2D inv = t.GetInverse();

    const core::Float2 p{6.0f, -2.0f};
    const core::Float2 mapped = t.TransformPoint(p);
    CheckPoint(inv.TransformPoint(mapped), p.x, p.y);

    // t * inv == identity
    CHECK(NearlyEqual(t * inv, Transform2D::Identity()));
}

TEST_CASE("transform2d: singular inverse falls back to identity")
{
    Transform2D degenerate{0.0f, 0.0f, 0.0f, 0.0f, 5.0f, 5.0f}; // det 0
    CHECK(degenerate.GetInverse().IsIdentity());
}

TEST_CASE("transform2d: TransformRect is AABB of corners")
{
    Transform2D t;
    t.Rotate(kHalfPi); // (x,y) -> (-y, x)
    Rect out = t.TransformRect(Rect{0.0f, 0.0f, 10.0f, 20.0f});
    CHECK(out.x == doctest::Approx(-20.0f));
    CHECK(out.y == doctest::Approx(0.0f));
    CHECK(out.width == doctest::Approx(20.0f));
    CHECK(out.height == doctest::Approx(10.0f));
}

TEST_CASE("transform2d: ToMatrix feeds core TransformPoint2D identically (VG convention)")
{
    Transform2D t;
    t.Translate(12.0f, -7.0f).Rotate(0.9f).Scale(1.5f, 2.0f);
    const core::Float4x4 m = t.ToMatrix();

    const core::Float2 probes[] = {
        core::Float2{0.0f, 0.0f},
        core::Float2{1.0f, 0.0f},
        core::Float2{0.0f, 1.0f},
        core::Float2{-3.5f, 8.25f},
    };
    for (const core::Float2& p : probes)
    {
        const core::Float2 viaTransform = t.TransformPoint(p);
        const core::Float2 viaMatrix = core::TransformPoint2D(p, m);
        CHECK(viaMatrix.x == doctest::Approx(viaTransform.x));
        CHECK(viaMatrix.y == doctest::Approx(viaTransform.y));
    }
}
