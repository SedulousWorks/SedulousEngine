// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :image partition
//
// Image: a picture in its content box (E6 of Specs/gui-lab-evolution.md), placed as CSS places a
// replaced element's: `object-fit` (fill, contain, cover, none, scale-down) sizes it,
// `object-position` places it (keywords, percentages or pixels, centred by default), and cover
// clips what overflows. Its picture is a Drawable from code or `src` from markup or a sheet,
// loaded through the GUI's resource provider when first needed. `image-color` tints it (RmlUi's
// name), for one that can be tinted. Sized by one axis alone, it keeps its picture's aspect ratio
// on the other, as an <img> does. (A nine-slice stays with backgrounds.)

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:image;

import foundation.core; // RefPtr, Move, Optional, Float2, Min, Max, String, Color
import foundation.image; // ImageData
import :rect;
import :draw_context;
import :drawable;
import :image_drawable;
import :svg_drawable; // PictureDrawable (an SVG drawn as paths)
import :resource_provider;
import :ui_widget;
import :layout_style; // kUnbounded, LayoutLengthKind

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// How a picture fills its box (CSS's object-fit).
    enum class ObjectFit : u8
    {
        Fill,      ///< stretched to the box, its aspect ignored
        Contain,   ///< the largest that fits, aspect kept
        Cover,     ///< the smallest that covers, aspect kept, clipped
        None,      ///< its natural size
        ScaleDown, ///< none or contain, whichever is smaller
    };

    /// Where a picture sits in its box on one axis (CSS's object-position): a share of the room
    /// left over, plus pixels.
    struct ObjectPositionAxis
    {
        f32 Share = 0.5f;
        f32 Pixels = 0.0f;
        [[nodiscard]] bool operator==(const ObjectPositionAxis&) const noexcept = default;
    };

    class Image : public UIWidget
    {
        RTTI_OBJECT(Image, UIWidget)
    public:
        Image() { SetTag(core::StringView(u8"image")); }

        /// Its picture from code (ending one from `src`).
        void SetDrawable(RefPtr<Drawable> drawable)
        {
            m_source = core::String{};
            m_sourceLoaded = true;
            m_drawable = core::Move(drawable);
            RequestLayout(); // its size follows its picture's
            Invalidate();
        }
        [[nodiscard]] Drawable* GetDrawable() const noexcept { return m_drawable.Get(); }

        /// Its picture by path, loaded through the GUI's resource provider when first needed.
        void SetSource(const core::String& path)
        {
            if (path == m_source)
                return;
            m_source = path;
            m_sourceLoaded = false;
            m_drawable = RefPtr<Drawable>{};
            RequestLayout();
            Invalidate();
        }
        [[nodiscard]] core::String GetSource() const { return m_source; }

        void SetFit(ObjectFit fit)
        {
            m_fit = fit;
            Invalidate();
        }
        [[nodiscard]] ObjectFit GetFit() const noexcept { return m_fit; }
        /// CSS's keywords (markup's and a sheet's `object-fit`); one it does not know is fill.
        void SetFitName(const core::String& name)
        {
            static constexpr core::StringView kNames[] = {u8"fill", u8"contain", u8"cover", u8"none", u8"scale-down"};
            ObjectFit fit = ObjectFit::Fill;
            for (usize i = 0; i < 5; ++i)
                if (Trim(name.AsView()) == kNames[i])
                    fit = static_cast<ObjectFit>(i);
            SetFit(fit);
        }
        [[nodiscard]] core::String GetFitName() const
        {
            static constexpr core::StringView kNames[] = {u8"fill", u8"contain", u8"cover", u8"none", u8"scale-down"};
            return core::String(kNames[static_cast<usize>(m_fit)]);
        }

        void SetObjectPosition(ObjectPositionAxis x, ObjectPositionAxis y)
        {
            m_positionX = x;
            m_positionY = y;
            Invalidate();
        }
        /// CSS's object-position: one or two of left, center, right, top, bottom, a percentage or
        /// pixels ("right 8px" reads as right then pixels from the left).
        void SetObjectPositionName(const core::String& text)
        {
            ObjectPositionAxis x, y;
            bool haveX = false, haveY = false;
            core::StringView rest = Trim(text.AsView());
            while (rest.Size() != 0)
            {
                usize end = 0;
                while (end < rest.Size() && rest[end] != u8' ')
                    ++end;
                const core::StringView word = rest.SubStr(0, end);
                rest = Trim(rest.SubStr(end, rest.Size() - end));
                ObjectPositionAxis a;
                bool vertical = false, either = false;
                if (word == core::StringView(u8"left"))
                    a.Share = 0.0f;
                else if (word == core::StringView(u8"right"))
                    a.Share = 1.0f;
                else if (word == core::StringView(u8"top"))
                {
                    a.Share = 0.0f;
                    vertical = true;
                }
                else if (word == core::StringView(u8"bottom"))
                {
                    a.Share = 1.0f;
                    vertical = true;
                }
                else if (word == core::StringView(u8"center"))
                    either = true;
                else if (word.Size() > 1 && word[word.Size() - 1] == u8'%')
                {
                    a.Share = ParseNumber(word.SubStr(0, word.Size() - 1)) / 100.0f;
                    either = true;
                }
                else
                {
                    const core::StringView digits = word.Size() > 2 && word.SubStr(word.Size() - 2, 2) == core::StringView(u8"px") ? word.SubStr(0, word.Size() - 2) : word;
                    a.Share = 0.0f;
                    a.Pixels = ParseNumber(digits);
                    either = true;
                }
                // The first word along whichever axis it names, the second the other.
                if (vertical || (either && haveX && !haveY))
                {
                    y = a;
                    haveY = true;
                }
                else
                {
                    x = a;
                    haveX = true;
                }
            }
            SetObjectPosition(x, y);
        }
        [[nodiscard]] core::String GetObjectPositionName() const
        {
            // Shares as percentages, pixels added (`50% 0%`, `0% 8px`).
            const auto axis = [](ObjectPositionAxis a)
            {
                return a.Pixels != 0.0f ? core::Format(u8"{}px", a.Pixels) : core::Format(u8"{}%", a.Share * 100.0f);
            };
            return core::Format(u8"{} {}", axis(m_positionX), axis(m_positionY));
        }

        /// The picture multiplied by this (`image-color`); white leaves it as it is.
        void SetImageColor(Color color)
        {
            m_imageColor = color;
            Invalidate();
        }
        [[nodiscard]] Color GetImageColor() const noexcept { return m_imageColor; }

        /// Its picture's size, or with one axis given by its style, that axis and the other by the
        /// picture's aspect ratio (E2).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2 available) override
        {
            const Optional<core::Float2> natural = IntrinsicSize();
            if (!natural.HasValue() || natural.Value().x <= 0.0f || natural.Value().y <= 0.0f)
                return core::Float2{0.0f, 0.0f};
            const core::Float2 n = natural.Value();
            const LayoutStyle& s = GetLayoutStyle();
            const bool fixedW = !s.Width.IsAuto() && !IsUnbounded(available.x);
            const bool fixedH = !s.Height.IsAuto() && !IsUnbounded(available.y);
            if (fixedW && !fixedH)
                return core::Float2{available.x, available.x * n.y / n.x};
            if (fixedH && !fixedW)
                return core::Float2{available.y * n.x / n.y, available.y};
            return n;
        }
        [[nodiscard]] Optional<core::Float2> IntrinsicSize() const
        {
            const_cast<Image*>(this)->LoadSource(); // a read: the picture `src` names, once loaded
            return m_drawable ? m_drawable->IntrinsicSize() : Optional<core::Float2>{};
        }

        /// Where the picture is drawn in its content box (it may pass the box's edges: cover, none).
        [[nodiscard]] Rect DrawnBounds() const
        {
            const Rect box = GetContentBounds();
            const Optional<core::Float2> intrinsic = IntrinsicSize();
            if (m_fit == ObjectFit::Fill || !intrinsic.HasValue() || intrinsic.Value().x <= 0.0f || intrinsic.Value().y <= 0.0f)
                return box;
            const core::Float2 nat = intrinsic.Value();
            const f32 sx = box.width / nat.x;
            const f32 sy = box.height / nat.y;
            f32 scale = 1.0f;
            switch (m_fit)
            {
            case ObjectFit::Contain: scale = core::Min(sx, sy); break;
            case ObjectFit::Cover: scale = core::Max(sx, sy); break;
            case ObjectFit::ScaleDown: scale = core::Min(1.0f, core::Min(sx, sy)); break;
            default: break;
            }
            const core::Float2 size{nat.x * scale, nat.y * scale};
            return Rect{box.x + (box.width - size.x) * m_positionX.Share + m_positionX.Pixels,
                        box.y + (box.height - size.y) * m_positionY.Share + m_positionY.Pixels, size.x, size.y};
        }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            LoadSource();
            if (!m_drawable)
                return;
            const Rect at = DrawnBounds();
            const Rect box = GetContentBounds();
            // What passes the box is clipped, as CSS clips a replaced element's content.
            const bool clip = at.x < box.x || at.y < box.y || at.x + at.width > box.x + box.width || at.y + at.height > box.y + box.height;
            if (clip)
                ctx.PushClip(box);
            if (m_imageColor == Color::White)
                m_drawable->Draw(ctx, at);
            else
                m_drawable->DrawTinted(ctx, at, m_imageColor);
            if (clip)
                ctx.PopClip();
        }

    private:
        void LoadSource()
        {
            if (m_sourceLoaded || m_source.IsEmpty())
                return;
            IResourceProvider* resources = GetResourceProvider();
            if (resources == nullptr)
                return; // not in a GUI with one yet: tried again when drawn or measured
            m_sourceLoaded = true;
            m_drawable = PictureDrawable(*resources, m_source.AsView(), MemoryAllocator()); // an SVG drawn as paths
            RequestLayout();
        }
        [[nodiscard]] static f32 ParseNumber(core::StringView text)
        {
            return static_cast<f32>(core::ParseFloat(text).ValueOr(0.0));
        }

        RefPtr<Drawable> m_drawable;
        core::String m_source;
        bool m_sourceLoaded = true;
        ObjectFit m_fit = ObjectFit::Fill;
        ObjectPositionAxis m_positionX{};
        ObjectPositionAxis m_positionY{};
        Color m_imageColor = Color::White;
    };
}
