// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_interpolation partition
//
// Interpolating typed style values (G3 of Specs/vg-and-gui-lab.md), so every property a sheet
// sets can transition and be keyframed, not only opacity and colour: numbers, lengths of one
// unit, colours (straight RGBA), shadow lists (the shorter padded with transparent shadows, as
// CSS does), transform lists of the same functions (function by function), transform origins, and
// gradient layers of the same shape (angle, stop colours and positions). With a context (the
// length context and the box's size), lengths in different units move in pixels, and transform
// lists of different functions move through their matrices, decomposed into translation, rotation,
// skew and scale (the rotation the short way round). What cannot interpolate (keywords, a
// percentage against another unit) switches at the halfway point: CSS's discrete animation.

module;
#include "Core/Prelude.h"

export module foundation.gui:style_interpolation;

import foundation.core;
import :css_values;
import :style_value;
import :style_properties;
import :transform2d;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What interpolating lengths of different units and different transform lists needs: the
    /// length context (em, rem, vw, vh) and the size of the box the value is for.
    struct StyleInterpolationContext
    {
        LengthContext Lengths{};
        core::Float2 BoxSize{};
    };

    namespace detail
    {
        [[nodiscard]] inline f32 Mix(f32 a, f32 b, f32 t) noexcept { return a + (b - a) * t; }

        [[nodiscard]] inline Color MixColor(Color a, Color b, f32 t) noexcept
        {
            return Color{Mix(a.r, b.r, t), Mix(a.g, b.g, t), Mix(a.b, b.b, t), Mix(a.a, b.a, t)};
        }

        [[nodiscard]] inline bool MixLength(LengthValue a, LengthValue b, f32 t, LengthValue& out,
                                            const StyleInterpolationContext* ctx = nullptr) noexcept
        {
            // A calc() on either side: term by term (E13), each unit as it is.
            if (a.Unit == LengthUnit::Calc || b.Unit == LengthUnit::Calc)
            {
                f32 x[kLengthUnitCount]{}, y[kLengthUnitCount]{}, mixed[kLengthUnitCount]{};
                a.ToTerms(x);
                b.ToTerms(y);
                for (usize i = 0; i < kLengthUnitCount; ++i)
                    mixed[i] = Mix(x[i], y[i], t);
                out = LengthValue::FromTerms(mixed);
                return true;
            }
            // A zero converts to any unit (CSS writes 0 unitless).
            if (a.Value == 0.0f)
                a.Unit = b.Unit;
            if (b.Value == 0.0f)
                b.Unit = a.Unit;
            if (a.Unit != b.Unit)
            {
                // Different units meet in pixels, when neither is a percentage (whose base the
                // property decides).
                if (ctx == nullptr || a.Unit == LengthUnit::Percent || b.Unit == LengthUnit::Percent)
                    return false;
                out = LengthValue{Mix(ResolveLengthValue(a, ctx->Lengths), ResolveLengthValue(b, ctx->Lengths), t),
                                  LengthUnit::Px};
                return true;
            }
            out = LengthValue{Mix(a.Value, b.Value, t), a.Unit};
            return true;
        }

        [[nodiscard]] inline bool MixShadows(const Array<ShadowValue>& a, const Array<ShadowValue>& b, f32 t,
                                             Array<ShadowValue>& out, const StyleInterpolationContext* ctx)
        {
            const usize n = Max(a.Size(), b.Size());
            out.Clear();
            for (usize i = 0; i < n; ++i)
            {
                // The shorter list is padded with a transparent shadow of the other's insetness.
                ShadowValue from = i < a.Size() ? a[i] : ShadowValue{};
                ShadowValue to = i < b.Size() ? b[i] : ShadowValue{};
                if (i >= a.Size())
                {
                    from.Inset = to.Inset;
                    from.ShadowColor = Color{to.ShadowColor.r, to.ShadowColor.g, to.ShadowColor.b, 0.0f};
                }
                if (i >= b.Size())
                {
                    to.Inset = from.Inset;
                    to.ShadowColor = Color{from.ShadowColor.r, from.ShadowColor.g, from.ShadowColor.b, 0.0f};
                }
                if (from.Inset != to.Inset)
                    return false;
                ShadowValue mixed;
                mixed.Inset = from.Inset;
                if (!MixLength(from.OffsetX, to.OffsetX, t, mixed.OffsetX, ctx) ||
                    !MixLength(from.OffsetY, to.OffsetY, t, mixed.OffsetY, ctx) ||
                    !MixLength(from.Blur, to.Blur, t, mixed.Blur, ctx) ||
                    !MixLength(from.Spread, to.Spread, t, mixed.Spread, ctx))
                    return false;
                mixed.ShadowColor = MixColor(from.ShadowColor, to.ShadowColor, t);
                out.PushBack(mixed);
            }
            return true;
        }

        // A 2D matrix as translation, rotation, skew and scale: M = T * R(angle) * K(skew) * S, K the
        // x-shear (x' = x + skew y); the scale's y takes a reflection's sign.
        struct Decomposed
        {
            f32 Tx = 0.0f, Ty = 0.0f, Angle = 0.0f, Skew = 0.0f, Sx = 1.0f, Sy = 1.0f;
        };

        [[nodiscard]] inline Decomposed Decompose(const Transform2D& m) noexcept
        {
            Decomposed d;
            d.Tx = m.tx;
            d.Ty = m.ty;
            d.Sx = Sqrt(m.a * m.a + m.b * m.b);
            if (d.Sx <= 1e-12f)
            {
                d.Sx = 0.0f;
                d.Sy = Sqrt(m.c * m.c + m.d * m.d);
                return d;
            }
            d.Angle = Atan2(m.b, m.a);
            const f32 cs = Cos(d.Angle), sn = Sin(d.Angle);
            const f32 skewed = m.c * cs + m.d * sn;  // the second column along the rotated x axis
            d.Sy = -m.c * sn + m.d * cs;              // ... and along the rotated y axis
            d.Skew = d.Sy != 0.0f ? skewed / d.Sy : 0.0f;
            return d;
        }

        [[nodiscard]] inline Transform2D Recompose(const Decomposed& d) noexcept
        {
            Transform2D m;
            m.Translate(d.Tx, d.Ty);
            m.Rotate(d.Angle);
            m.Combine(Transform2D{1.0f, 0.0f, d.Skew, 1.0f, 0.0f, 0.0f});
            m.Scale(d.Sx, d.Sy);
            return m;
        }

        // Two transform lists of different functions, through their matrices.
        [[nodiscard]] inline TransformFunction MixMatrices(const Array<TransformFunction>& a,
                                                           const Array<TransformFunction>& b, f32 t, core::Float2 size)
        {
            const Decomposed x = Decompose(ComposeTransforms(a, size));
            const Decomposed y = Decompose(ComposeTransforms(b, size));
            constexpr f32 kPi = 3.14159265358979f;
            f32 turn = y.Angle - x.Angle; // the short way round
            while (turn > kPi)
                turn -= 2.0f * kPi;
            while (turn < -kPi)
                turn += 2.0f * kPi;
            Decomposed mixed;
            mixed.Tx = Mix(x.Tx, y.Tx, t);
            mixed.Ty = Mix(x.Ty, y.Ty, t);
            mixed.Angle = x.Angle + turn * t;
            mixed.Skew = Mix(x.Skew, y.Skew, t);
            mixed.Sx = Mix(x.Sx, y.Sx, t);
            mixed.Sy = Mix(x.Sy, y.Sy, t);
            const Transform2D m = Recompose(mixed);
            TransformFunction f;
            f.Kind = TransformKind::Matrix;
            const f32 values[6] = {m.a, m.b, m.c, m.d, m.tx, m.ty};
            for (usize k = 0; k < 6; ++k)
                f.M[k] = values[k];
            return f;
        }

        [[nodiscard]] inline bool MixTransforms(const Array<TransformFunction>& a, const Array<TransformFunction>& b,
                                                f32 t, Array<TransformFunction>& out,
                                                const StyleInterpolationContext* ctx)
        {
            // none against a list: the list's identity functions (CSS), so `none -> rotate(90deg)`
            // turns from 0.
            const auto identity = [](const TransformFunction& like)
            {
                TransformFunction id;
                id.Kind = like.Kind;
                id.A = LengthValue{0.0f, like.A.Unit};
                id.B = LengthValue{0.0f, like.B.Unit};
                return id; // angle 0, scale 1, matrix identity by default
            };
            const Array<TransformFunction>* from = &a;
            const Array<TransformFunction>* to = &b;
            Array<TransformFunction> padded;
            if (a.IsEmpty() && !b.IsEmpty())
            {
                for (const TransformFunction& f : b)
                    padded.PushBack(identity(f));
                from = &padded;
            }
            else if (b.IsEmpty() && !a.IsEmpty())
            {
                for (const TransformFunction& f : a)
                    padded.PushBack(identity(f));
                to = &padded;
            }
            // Lists of different functions (or lengths that cannot meet) go through their matrices.
            const auto throughMatrices = [&]()
            {
                out.Clear();
                out.PushBack(MixMatrices(a, b, t, ctx != nullptr ? ctx->BoxSize : core::Float2{}));
                return true;
            };
            bool same = from->Size() == to->Size();
            for (usize i = 0; same && i < from->Size(); ++i)
                same = (*from)[i].Kind == (*to)[i].Kind;
            if (!same)
                return throughMatrices();
            out.Clear();
            for (usize i = 0; i < from->Size(); ++i)
            {
                const TransformFunction& x = (*from)[i];
                const TransformFunction& y = (*to)[i];
                TransformFunction m = x;
                if (!MixLength(x.A, y.A, t, m.A, ctx) || !MixLength(x.B, y.B, t, m.B, ctx))
                    return throughMatrices();
                m.Angle = Mix(x.Angle, y.Angle, t);
                m.AngleY = Mix(x.AngleY, y.AngleY, t);
                m.ScaleX = Mix(x.ScaleX, y.ScaleX, t);
                m.ScaleY = Mix(x.ScaleY, y.ScaleY, t);
                for (usize k = 0; k < 6; ++k)
                    m.M[k] = Mix(x.M[k], y.M[k], t);
                out.PushBack(m);
            }
            return true;
        }

        [[nodiscard]] inline bool MixLayers(const Array<BackgroundLayer>& a, const Array<BackgroundLayer>& b, f32 t,
                                            Array<BackgroundLayer>& out)
        {
            if (a.Size() != b.Size())
                return false;
            out.Clear();
            for (usize i = 0; i < a.Size(); ++i)
            {
                const BackgroundLayer& x = a[i];
                const BackgroundLayer& y = b[i];
                if (x.Kind != y.Kind)
                    return false;
                BackgroundLayer m = x;
                if (x.Kind == BackgroundKind::Gradient)
                {
                    const Array<GradientStopValue> sx = SettleStops(x.Gradient.Stops);
                    const Array<GradientStopValue> sy = SettleStops(y.Gradient.Stops);
                    if (x.Gradient.Kind != y.Gradient.Kind || x.Gradient.Repeating != y.Gradient.Repeating ||
                        sx.Size() != sy.Size())
                        return false;
                    m.Gradient.Angle = Mix(x.Gradient.Angle, y.Gradient.Angle, t);
                    m.Gradient.Stops.Clear();
                    for (usize k = 0; k < sx.Size(); ++k)
                        m.Gradient.Stops.PushBack(GradientStopValue{MixColor(sx[k].StopColor, sy[k].StopColor, t),
                                                                    Mix(sx[k].Position, sy[k].Position, t)});
                }
                else if (x.Kind == BackgroundKind::Color)
                {
                    m.LayerColor = MixColor(x.LayerColor, y.LayerColor, t);
                }
                else if (x.Image != y.Image)
                {
                    return false; // two images do not blend
                }
                out.PushBack(Move(m));
            }
            return true;
        }

        // Filter lists: the shorter padded with the other's functions at their identity (blur(0)),
        // then function by function; lists of different functions switch.
        [[nodiscard]] inline bool MixFilters(const Array<FilterFunction>& a, const Array<FilterFunction>& b, f32 t,
                                             Array<FilterFunction>& out, const StyleInterpolationContext* ctx)
        {
            const usize n = Max(a.Size(), b.Size());
            out.Clear();
            for (usize i = 0; i < n; ++i)
            {
                FilterFunction from = i < a.Size() ? a[i] : FilterFunction{b[i].Kind, LengthValue{}};
                FilterFunction to = i < b.Size() ? b[i] : FilterFunction{a[i].Kind, LengthValue{}};
                if (from.Kind != to.Kind)
                    return false;
                FilterFunction mixed{from.Kind, LengthValue{}};
                if (!MixLength(from.Amount, to.Amount, t, mixed.Amount, ctx))
                    return false;
                mixed.Amount.Value = Max(0.0f, mixed.Amount.Value); // an overshooting easing
                out.PushBack(mixed);
            }
            return true;
        }
    }

        /// `a` toward `b` at `t` (0: a, 1: b; t may leave [0, 1] for an overshooting easing). Values
    /// that cannot interpolate switch at t = 0.5.
    [[nodiscard]] inline StyleValue InterpolateStyleValue(const StyleValue& a, const StyleValue& b, f32 t,
                                                          const StyleInterpolationContext* ctx = nullptr)
    {
        const auto discrete = [&]() { return t < 0.5f ? a : b; };
        if (a.Kind != b.Kind)
            return discrete();
        StyleValue out = a;
        switch (a.Kind)
        {
        case StyleValueKind::Number:
            out.Number = detail::Mix(a.Number, b.Number, t);
            return out;
        case StyleValueKind::Length:
            return detail::MixLength(a.Length, b.Length, t, out.Length, ctx) ? out : discrete();
        case StyleValueKind::ColorValue:
            out.ColorValue = detail::MixColor(a.ColorValue, b.ColorValue, t);
            return out;
        case StyleValueKind::Shadows:
            return detail::MixShadows(a.Shadows, b.Shadows, t, out.Shadows, ctx) ? out : discrete();
        case StyleValueKind::Transforms:
            return detail::MixTransforms(a.Transforms, b.Transforms, t, out.Transforms, ctx) ? out : discrete();
        case StyleValueKind::Origin:
            if (detail::MixLength(a.OriginX, b.OriginX, t, out.OriginX, ctx) &&
                detail::MixLength(a.OriginY, b.OriginY, t, out.OriginY, ctx))
                return out;
            return discrete();
        case StyleValueKind::Layers:
            return detail::MixLayers(a.Layers, b.Layers, t, out.Layers) ? out : discrete();
        case StyleValueKind::Filters:
            return detail::MixFilters(a.Filters, b.Filters, t, out.Filters, ctx) ? out : discrete();
        case StyleValueKind::Keyword:
        case StyleValueKind::None:
            return discrete();
        }
        return discrete();
    }
}
