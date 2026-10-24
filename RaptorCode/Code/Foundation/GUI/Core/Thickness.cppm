// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :thickness partition
//
// Thickness: four edge insets (padding / margin / border / layer inset). Adapts eepp,
// which overloads Rectf's Left/Top/Right/Bottom for this; a dedicated type is clearer.

module;
#include "Core/Prelude.h"

export module foundation.gui:thickness;

import foundation.core;

using namespace foundation::core;

export namespace foundation::gui
{
    struct Thickness
    {
        f32 Left = 0.0f;
        f32 Top = 0.0f;
        f32 Right = 0.0f;
        f32 Bottom = 0.0f;

        constexpr Thickness() noexcept = default;
        explicit constexpr Thickness(f32 all) noexcept
            : Left(all), Top(all), Right(all), Bottom(all)
        {
        }
        constexpr Thickness(f32 horizontal, f32 vertical) noexcept
            : Left(horizontal), Top(vertical), Right(horizontal), Bottom(vertical)
        {
        }
        constexpr Thickness(f32 left, f32 top, f32 right, f32 bottom) noexcept
            : Left(left), Top(top), Right(right), Bottom(bottom)
        {
        }

        [[nodiscard]] constexpr f32 TotalHorizontal() const noexcept { return Left + Right; }
        [[nodiscard]] constexpr f32 TotalVertical() const noexcept { return Top + Bottom; }
        [[nodiscard]] constexpr bool IsZero() const noexcept
        {
            return Left == 0.0f && Top == 0.0f && Right == 0.0f && Bottom == 0.0f;
        }
    };

    [[nodiscard]] constexpr bool operator==(const Thickness& a, const Thickness& b) noexcept
    {
        return a.Left == b.Left && a.Top == b.Top && a.Right == b.Right && a.Bottom == b.Bottom;
    }
}
