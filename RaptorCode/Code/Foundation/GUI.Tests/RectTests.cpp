// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Rect tests. Derived from eepp Rectf behavior (Left/Top/Right/Bottom,
// contains/intersect), adapted to the x/y/w/h storage.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("rect: default is zero")
{
    Rect r;
    CHECK(r.x == 0.0f);
    CHECK(r.y == 0.0f);
    CHECK(r.width == 0.0f);
    CHECK(r.height == 0.0f);
    CHECK(r.IsEmpty());
}

TEST_CASE("rect: edges and accessors")
{
    Rect r{10.0f, 20.0f, 30.0f, 40.0f};
    CHECK(r.Left() == 10.0f);
    CHECK(r.Top() == 20.0f);
    CHECK(r.Right() == 40.0f);
    CHECK(r.Bottom() == 60.0f);
    CHECK(r.Position() == core::Float2{10.0f, 20.0f});
    CHECK(r.Size() == core::Float2{30.0f, 40.0f});
    CHECK(r.Center() == core::Float2{25.0f, 40.0f});
    CHECK_FALSE(r.IsEmpty());
}

TEST_CASE("rect: FromLTRB matches edges")
{
    Rect r = Rect::FromLTRB(10.0f, 20.0f, 40.0f, 60.0f);
    CHECK(r == Rect{10.0f, 20.0f, 30.0f, 40.0f});
}

TEST_CASE("rect: FromMinMax")
{
    Rect r = Rect::FromMinMax(core::Float2{1.0f, 2.0f}, core::Float2{5.0f, 8.0f});
    CHECK(r == Rect{1.0f, 2.0f, 4.0f, 6.0f});
}

TEST_CASE("rect: Contains point")
{
    Rect r{0.0f, 0.0f, 100.0f, 50.0f};
    CHECK(r.Contains(core::Float2{50.0f, 25.0f}));
    CHECK(r.Contains(core::Float2{0.0f, 0.0f}));    // edge inclusive
    CHECK(r.Contains(core::Float2{100.0f, 50.0f})); // edge inclusive
    CHECK_FALSE(r.Contains(core::Float2{101.0f, 25.0f}));
    CHECK_FALSE(r.Contains(core::Float2{50.0f, -1.0f}));
}

TEST_CASE("rect: Contains rect")
{
    Rect outer{0.0f, 0.0f, 100.0f, 100.0f};
    CHECK(outer.Contains(Rect{10.0f, 10.0f, 20.0f, 20.0f}));
    CHECK_FALSE(outer.Contains(Rect{90.0f, 90.0f, 20.0f, 20.0f}));
}

TEST_CASE("rect: Intersects")
{
    Rect a{0.0f, 0.0f, 50.0f, 50.0f};
    CHECK(a.Intersects(Rect{25.0f, 25.0f, 50.0f, 50.0f}));
    CHECK_FALSE(a.Intersects(Rect{60.0f, 0.0f, 10.0f, 10.0f}));
    CHECK_FALSE(a.Intersects(Rect{50.0f, 0.0f, 10.0f, 10.0f})); // touching, not overlapping
}

TEST_CASE("rect: Intersect overlap")
{
    Rect a{0.0f, 0.0f, 50.0f, 50.0f};
    Rect b{25.0f, 25.0f, 50.0f, 50.0f};
    CHECK(Rect::Intersect(a, b) == Rect{25.0f, 25.0f, 25.0f, 25.0f});
}

TEST_CASE("rect: Intersect disjoint is empty")
{
    Rect a{0.0f, 0.0f, 10.0f, 10.0f};
    Rect b{100.0f, 100.0f, 10.0f, 10.0f};
    CHECK(Rect::Intersect(a, b).IsEmpty());
}

TEST_CASE("rect: Merge union")
{
    Rect a{0.0f, 0.0f, 10.0f, 10.0f};
    Rect b{20.0f, 5.0f, 10.0f, 10.0f};
    CHECK(Rect::Merge(a, b) == Rect{0.0f, 0.0f, 30.0f, 15.0f});
}

TEST_CASE("rect: Rectangle round-trip")
{
    Rect r{3.0f, 4.0f, 5.0f, 6.0f};
    core::Rectangle cr = r.ToRectangle();
    CHECK(cr.x == 3.0f);
    CHECK(cr.width == 5.0f);
    CHECK(Rect::FromRectangle(cr) == r);
}
