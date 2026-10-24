// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Thickness tests (a box's padding, margins and borders, per side).
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

// === Thickness ===

TEST_CASE("thickness: defaults and constructors")
{
    Thickness zero;
    CHECK(zero.IsZero());

    Thickness all{4.0f};
    CHECK(all.Left == 4.0f);
    CHECK(all.Bottom == 4.0f);
    CHECK(all.TotalHorizontal() == doctest::Approx(8.0f));
    CHECK(all.TotalVertical() == doctest::Approx(8.0f));

    Thickness hv{2.0f, 6.0f};
    CHECK(hv.Left == 2.0f);
    CHECK(hv.Right == 2.0f);
    CHECK(hv.Top == 6.0f);
    CHECK(hv.Bottom == 6.0f);

    Thickness each{1.0f, 2.0f, 3.0f, 4.0f};
    CHECK(each.Left == 1.0f);
    CHECK(each.Top == 2.0f);
    CHECK(each.Right == 3.0f);
    CHECK(each.Bottom == 4.0f);
    CHECK_FALSE(each.IsZero());
    CHECK(each == Thickness{1.0f, 2.0f, 3.0f, 4.0f});
}
