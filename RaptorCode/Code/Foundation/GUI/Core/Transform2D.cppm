// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :transform2d partition
//
// Transform2D: a 2D affine transform, the primitive Transformable (Phase 1) composes
// and hands to the VG-backed DrawContext. Stored as 6 floats in column-vector affine
// form (eepp/SFML style):
//
//     | a  c  tx |          x' = a*x + c*y + tx
//     | b  d  ty |          y' = b*x + d*y + ty
//     | 0  0  1  |
//
// ToMatrix() lays those into a core::Float4x4 in the exact convention VG's
// TransformPoint2D reads (row-vector, translation in row 3), so a subtree transform
// feeds DrawContext losslessly and rotation matches Float4x4::RotationZ.
//
// Derived from eepp include/eepp/math/transform.hpp; angles are RADIANS (VG
// convention, not eepp's degrees); camelCase -> PascalCase.

module;
#include "Core/Prelude.h"

export module foundation.gui:transform2d;

import foundation.core; // Float2, Float4x4, Cos/Sin, NearlyEqual

import :rect;

using namespace foundation::core;
namespace core = foundation::core;

namespace foundation::gui
{
    [[nodiscard]] constexpr f32 Min4(f32 w, f32 x, f32 y, f32 z) noexcept
    {
        const f32 a = w < x ? w : x;
        const f32 b = y < z ? y : z;
        return a < b ? a : b;
    }
    [[nodiscard]] constexpr f32 Max4(f32 w, f32 x, f32 y, f32 z) noexcept
    {
        const f32 a = w > x ? w : x;
        const f32 b = y > z ? y : z;
        return a > b ? a : b;
    }
}

export namespace foundation::gui
{
    struct Transform2D
    {
        // Column-vector affine coefficients (see file header).
        f32 a = 1.0f, b = 0.0f;
        f32 c = 0.0f, d = 1.0f;
        f32 tx = 0.0f, ty = 0.0f;

        constexpr Transform2D() noexcept = default;
        constexpr Transform2D(f32 inA, f32 inB, f32 inC, f32 inD, f32 inTx, f32 inTy) noexcept
            : a(inA), b(inB), c(inC), d(inD), tx(inTx), ty(inTy)
        {
        }

        [[nodiscard]] static constexpr Transform2D Identity() noexcept { return Transform2D{}; }

        [[nodiscard]] constexpr bool IsIdentity() const noexcept
        {
            return a == 1.0f && b == 0.0f && c == 0.0f && d == 1.0f && tx == 0.0f && ty == 0.0f;
        }

        // === Point / rect application ===
        [[nodiscard]] constexpr core::Float2 TransformPoint(core::Float2 p) const noexcept
        {
            return core::Float2{a * p.x + c * p.y + tx, b * p.x + d * p.y + ty};
        }
        [[nodiscard]] constexpr core::Float2 TransformPoint(f32 px, f32 py) const noexcept
        {
            return core::Float2{a * px + c * py + tx, b * px + d * py + ty};
        }

        // Axis-aligned bounding box of the four transformed corners.
        [[nodiscard]] constexpr Rect TransformRect(const Rect& r) const noexcept
        {
            const core::Float2 p0 = TransformPoint(r.Left(), r.Top());
            const core::Float2 p1 = TransformPoint(r.Right(), r.Top());
            const core::Float2 p2 = TransformPoint(r.Left(), r.Bottom());
            const core::Float2 p3 = TransformPoint(r.Right(), r.Bottom());
            const f32 minX = Min4(p0.x, p1.x, p2.x, p3.x);
            const f32 maxX = Max4(p0.x, p1.x, p2.x, p3.x);
            const f32 minY = Min4(p0.y, p1.y, p2.y, p3.y);
            const f32 maxY = Max4(p0.y, p1.y, p2.y, p3.y);
            return Rect{minX, minY, maxX - minX, maxY - minY};
        }

        // === Composition ===
        // this = this * rhs (post-multiply, eepp Transform::combine): applying the
        // result to p equals this.TransformPoint(rhs.TransformPoint(p)).
        constexpr Transform2D& Combine(const Transform2D& r) noexcept
        {
            *this = Multiply(*this, r);
            return *this;
        }

        constexpr Transform2D& Translate(f32 x, f32 y) noexcept
        {
            return Combine(Transform2D{1.0f, 0.0f, 0.0f, 1.0f, x, y});
        }
        constexpr Transform2D& Translate(core::Float2 offset) noexcept
        {
            return Translate(offset.x, offset.y);
        }

        Transform2D& Rotate(f32 radians) noexcept
        {
            const f32 cs = core::Cos(radians), sn = core::Sin(radians);
            return Combine(Transform2D{cs, sn, -sn, cs, 0.0f, 0.0f});
        }
        Transform2D& Rotate(f32 radians, f32 centerX, f32 centerY) noexcept
        {
            const f32 cs = core::Cos(radians), sn = core::Sin(radians);
            return Combine(Transform2D{cs, sn, -sn, cs, centerX * (1.0f - cs) + centerY * sn,
                                       -centerX * sn + centerY * (1.0f - cs)});
        }
        Transform2D& Rotate(f32 radians, core::Float2 center) noexcept
        {
            return Rotate(radians, center.x, center.y);
        }

        constexpr Transform2D& Scale(f32 sx, f32 sy) noexcept
        {
            return Combine(Transform2D{sx, 0.0f, 0.0f, sy, 0.0f, 0.0f});
        }
        constexpr Transform2D& Scale(core::Float2 factors) noexcept
        {
            return Scale(factors.x, factors.y);
        }
        constexpr Transform2D& Scale(f32 sx, f32 sy, f32 centerX, f32 centerY) noexcept
        {
            return Combine(
                Transform2D{sx, 0.0f, 0.0f, sy, centerX * (1.0f - sx), centerY * (1.0f - sy)});
        }
        constexpr Transform2D& Scale(core::Float2 factors, core::Float2 center) noexcept
        {
            return Scale(factors.x, factors.y, center.x, center.y);
        }

        // === Inverse ===
        [[nodiscard]] Transform2D GetInverse() const noexcept
        {
            const f32 det = a * d - c * b;
            if (core::NearlyZero(det))
            {
                return Transform2D::Identity();
            }
            const f32 invDet = 1.0f / det;
            const f32 ia = d * invDet, ic = -c * invDet;
            const f32 ib = -b * invDet, id = a * invDet;
            return Transform2D{ia, ib, ic, id, -(ia * tx + ic * ty), -(ib * tx + id * ty)};
        }

        // === Float4x4 for the VG DrawContext (row-vector, translation in row 3) ===
        [[nodiscard]] constexpr core::Float4x4 ToMatrix() const noexcept
        {
            core::Float4x4 m = core::Float4x4::Identity();
            m.m[0][0] = a;
            m.m[0][1] = b;
            m.m[1][0] = c;
            m.m[1][1] = d;
            m.m[3][0] = tx;
            m.m[3][1] = ty;
            return m;
        }

        // p' = A * (B * p): result applies B first, then A.
        [[nodiscard]] static constexpr Transform2D Multiply(const Transform2D& A,
                                                            const Transform2D& B) noexcept
        {
            return Transform2D{
                A.a * B.a + A.c * B.b,          A.b * B.a + A.d * B.b,
                A.a * B.c + A.c * B.d,          A.b * B.c + A.d * B.d,
                A.a * B.tx + A.c * B.ty + A.tx, A.b * B.tx + A.d * B.ty + A.ty,
            };
        }
    };

    [[nodiscard]] constexpr Transform2D operator*(const Transform2D& a,
                                                  const Transform2D& b) noexcept
    {
        return Transform2D::Multiply(a, b);
    }

    [[nodiscard]] inline bool NearlyEqual(const Transform2D& x, const Transform2D& y,
                                          f32 epsilon = kEpsilon) noexcept
    {
        return core::NearlyEqual(x.a, y.a, epsilon) && core::NearlyEqual(x.b, y.b, epsilon) &&
               core::NearlyEqual(x.c, y.c, epsilon) && core::NearlyEqual(x.d, y.d, epsilon) &&
               core::NearlyEqual(x.tx, y.tx, epsilon) && core::NearlyEqual(x.ty, y.ty, epsilon);
    }
}
