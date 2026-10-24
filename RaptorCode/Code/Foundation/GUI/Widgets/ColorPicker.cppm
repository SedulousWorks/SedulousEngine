// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :color_picker partition
//
// Colour widgets (T4 of Specs/gui-lab-evolution-3.md). They edit the values an authored Color holds,
// which are sRGB (the engine's rule: what a picker and a hex code show; the renderer decodes to
// linear), so HSV here is over sRGB values and linear is never stored.
//   - ColorSwatch: a colour over a checkerboard (its alpha seen), or hatched when mixed (several
//     objects' colours differing); a click, Return or Space reports it.
//   - ColorPicker: a saturation and value plane, a hue strip, an alpha strip, a hex field (any CSS
//     colour typed: #rgb, #rrggbb, #rrggbbaa, rgb(), a name) and, on the row below it, 0-255 fields
//     for each channel. A drag
//     reports each step (`input`) and its end (`change`); a field reports its commit. The hue is kept
//     where a grey or black has none, so dragging back out of the corner keeps it.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:color_picker;

import foundation.core; // Color, Clamp, Format
import foundation.vg;   // PathBuilder, VGLinearGradientFill
import :rect;
import :event;
import :draw_context;
import :layout_style;
import :ui_widget;
import :text_field;
import :number_field;
import :label;
import :css_values; // ParseColor (the hex field)

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A colour as hue (0-360), saturation, value and alpha, each of 0-1 but the hue.
    struct ColorHsv
    {
        f32 H = 0.0f;
        f32 S = 0.0f;
        f32 V = 0.0f;
        f32 A = 1.0f;
    };

    /// `color` as HSV of its (sRGB) values; `hue` is kept where it has none (a grey).
    [[nodiscard]] inline ColorHsv ToHsv(Color color, f32 hue = 0.0f) noexcept
    {
        const f32 r = core::Clamp(color.r, 0.0f, 1.0f), g = core::Clamp(color.g, 0.0f, 1.0f), b = core::Clamp(color.b, 0.0f, 1.0f);
        const f32 high = core::Max(r, core::Max(g, b));
        const f32 low = core::Min(r, core::Min(g, b));
        const f32 span = high - low;
        ColorHsv out;
        out.V = high;
        out.S = high > 0.0f ? span / high : 0.0f;
        out.A = color.a;
        if (span <= 0.0f)
            out.H = hue;
        else if (high == r)
            out.H = 60.0f * ((g - b) / span) + (g < b ? 360.0f : 0.0f);
        else if (high == g)
            out.H = 60.0f * ((b - r) / span + 2.0f);
        else
            out.H = 60.0f * ((r - g) / span + 4.0f);
        return out;
    }
    [[nodiscard]] inline Color FromHsv(const ColorHsv& hsv) noexcept
    {
        const f32 h = hsv.H - 360.0f * core::Floor(hsv.H / 360.0f);
        const f32 c = hsv.V * hsv.S;
        const f32 sector = h / 60.0f;
        const f32 x = c * (1.0f - core::Abs(sector - 2.0f * core::Floor(sector / 2.0f) - 1.0f));
        const f32 m = hsv.V - c;
        f32 r = 0.0f, g = 0.0f, b = 0.0f;
        switch (static_cast<i32>(sector) % 6)
        {
        case 0:
            r = c, g = x;
            break;
        case 1:
            r = x, g = c;
            break;
        case 2:
            g = c, b = x;
            break;
        case 3:
            g = x, b = c;
            break;
        case 4:
            r = x, b = c;
            break;
        default:
            r = c, b = x;
            break;
        }
        return Color{r + m, g + m, b + m, hsv.A};
    }
    /// "#RRGGBB", with "AA" after when `alpha` and it is not opaque.
    [[nodiscard]] inline core::String FormatHexColor(Color color, bool alpha)
    {
        const u32 packed = color.ToRGBA8();
        const i32 digits = alpha && (packed & 0xFFu) != 0xFFu ? 8 : 6;
        const u32 value = digits == 8 ? packed : packed >> 8;
        char8_t text[9] = {u8'#'};
        for (i32 i = 0; i < digits; ++i)
        {
            const u32 nibble = (value >> ((digits - 1 - i) * 4)) & 0xFu;
            text[1 + i] = static_cast<char8_t>(nibble < 10 ? u8'0' + nibble : u8'A' + nibble - 10);
        }
        return core::String(core::StringView(text, static_cast<usize>(digits + 1)));
    }

    namespace detail
    {
        // A checkerboard behind a colour with alpha.
        inline void DrawChecker(DrawContext& ctx, const Rect& box, f32 cell = 6.0f)
        {
            ctx.VG().FillRect(box.ToRectangle(), Color{0.85f, 0.85f, 0.85f, 1.0f});
            const Color dark{0.6f, 0.6f, 0.6f, 1.0f};
            for (f32 y = 0.0f; y < box.height; y += cell)
                for (f32 x = (static_cast<i32>(y / cell) % 2 == 0) ? 0.0f : cell; x < box.width; x += cell * 2.0f)
                    ctx.VG().FillRect(Rectangle{box.x + x, box.y + y, core::Min(cell, box.width - x), core::Min(cell, box.height - y)}, dark);
        }
        inline vg::Path RectPath(const Rect& box)
        {
            vg::PathBuilder pb;
            pb.MoveTo(box.x, box.y);
            pb.LineTo(box.Right(), box.y);
            pb.LineTo(box.Right(), box.Bottom());
            pb.LineTo(box.x, box.Bottom());
            pb.Close();
            return pb.ToPath();
        }
    }

    /// A colour shown: over a checkerboard, or hatched when mixed. Clicked, it says so.
    class ColorSwatch : public UIWidget
    {
        RTTI_OBJECT(ColorSwatch, UIWidget)
    public:
        ColorSwatch()
        {
            SetTag(core::StringView(u8"colorswatch"));
            SetTabFocusable(true);
        }
        void SetColor(Color color)
        {
            m_color = color;
            Invalidate();
        }
        [[nodiscard]] Color GetColor() const noexcept { return m_color; }
        /// Several colours stand behind it that differ: hatched, no colour shown.
        void SetMixed(bool mixed)
        {
            m_mixed = mixed;
            Invalidate();
        }
        [[nodiscard]] bool IsMixed() const noexcept { return m_mixed; }
        /// Whether its alpha shows (else drawn opaque).
        void SetShowsAlpha(bool shows)
        {
            m_showsAlpha = shows;
            Invalidate();
        }
        void SetOnClick(core::Function<void()> callback) { m_onClick = core::Move(callback); }

    protected:
        void OnMouseClick(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left)
                return;
            event.Handled = true;
            Click();
        }
        void OnKeyDown(const KeyEvent& event) override
        {
            const KeyCode key = static_cast<KeyCode>(event.KeyCode);
            if (event.Target == this && event.Modifiers == 0 && (key == KeyCode::Return || key == KeyCode::Space))
            {
                event.Handled = true;
                Click();
            }
        }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            UIWidget::OnDraw(ctx, localBounds);
            const Rect box = GetContentBounds();
            if (m_mixed)
            {
                ctx.VG().FillRect(box.ToRectangle(), Color{0.3f, 0.32f, 0.36f, 1.0f});
                ctx.PushClip(box);
                vg::PathBuilder lines;
                for (f32 x = -box.height; x < box.width; x += 6.0f)
                {
                    lines.MoveTo(box.x + x, box.Bottom());
                    lines.LineTo(box.x + x + box.height, box.y);
                }
                ctx.VG().StrokePath(lines.ToPath(), GetTextColor(), vg::StrokeStyle(1.0f));
                ctx.PopClip();
                return;
            }
            Color color = m_color;
            if (m_showsAlpha && color.a < 1.0f)
                detail::DrawChecker(ctx, box);
            else
                color.a = 1.0f;
            ctx.VG().FillRect(box.ToRectangle(), color);
        }

    private:
        void Click()
        {
            if (m_onClick && IsTreeEnabled())
                m_onClick();
        }

        Color m_color{1.0f, 1.0f, 1.0f, 1.0f};
        bool m_mixed = false;
        bool m_showsAlpha = true;
        core::Function<void()> m_onClick;
    };

    class ColorPicker;

    /// A picker's draggable area: the saturation and value plane, or a hue or alpha strip.
    class ColorPickerArea : public UIWidget
    {
        RTTI_OBJECT(ColorPickerArea, UIWidget)
    public:
        enum class Kind : u8
        {
            Plane,
            Hue,
            Alpha,
        };
        ColorPickerArea(ColorPicker& picker, Kind kind) : m_picker(picker), m_kind(kind)
        {
            SetTag(core::StringView(kind == Kind::Plane ? u8"colorplane" : (kind == Kind::Hue ? u8"huestrip" : u8"alphastrip")));
        }
        [[nodiscard]] Kind GetKind() const noexcept { return m_kind; }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;

    private:
        void At(core::Float2 screen);

        ColorPicker& m_picker;
        Kind m_kind;
        bool m_dragging = false;
    };

    class ColorPicker : public UIWidget
    {
        RTTI_OBJECT(ColorPicker, UIWidget)
    public:
        ColorPicker()
        {
            SetTag(core::StringView(u8"colorpicker"));
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.RowGap = 8.0f;
            });
            m_plane = core::MakeRef<ColorPickerArea>(MemoryAllocator(), *this, ColorPickerArea::Kind::Plane);
            m_plane->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(140.0f); });
            AddChild(m_plane.Get());
            m_hue = core::MakeRef<ColorPickerArea>(MemoryAllocator(), *this, ColorPickerArea::Kind::Hue);
            m_hue->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(14.0f); });
            AddChild(m_hue.Get());
            m_alpha = core::MakeRef<ColorPickerArea>(MemoryAllocator(), *this, ColorPickerArea::Kind::Alpha);
            m_alpha->EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(14.0f); });
            AddChild(m_alpha.Get());

            // The hex code on a row of its own, the channels on the next: each field wide enough to
            // show its number beside its arrows.
            ColorPicker* self = this;
            m_hex = core::MakeRef<TextField>(MemoryAllocator());
            m_hex->AddClass(core::StringView(u8"hex"));
            m_hex->SetOnTextChanged([self](core::StringView text) { self->TypedHex(text); });
            AddChild(m_hex.Get());
            m_fields = core::MakeRef<UIWidget>(MemoryAllocator());
            m_fields->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.ColumnGap = 4.0f;
                s.AlignItems = Align::Center;
            });
            AddChild(m_fields.Get());
            const char8_t* const names[] = {u8"R", u8"G", u8"B", u8"A"};
            for (i32 i = 0; i < 4; ++i)
            {
                auto label = core::MakeRef<Label>(MemoryAllocator());
                label->SetText(core::StringView(names[i]));
                label->SetHitTestVisible(false);
                m_fields->AddChild(label.Get());
                m_channelLabels[i] = label;
                auto field = core::MakeRef<NumberField>(MemoryAllocator());
                field->SetInteger(true);
                field->SetMin(0.0);
                field->SetMax(255.0);
                field->SetStep(1.0);
                field->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Grow = 1.0f;
                    s.Basis = LayoutLength::Px(0.0f);
                    s.MinWidth = LayoutLength::Px(0.0f);
                });
                field->SetOnValueChanging([self, i](f64 value) { self->TypedChannel(i, value, false); });
                field->SetOnValueChanged([self, i](f64 value) { self->TypedChannel(i, value, true); });
                m_fields->AddChild(field.Get());
                m_channels[i] = field;
            }
            ShowFields();
        }

        // === The colour ===
        /// Sets the colour from code: shown, nothing reported.
        void SetColor(Color color)
        {
            m_hsv = ToHsv(color, m_hsv.H);
            ShowFields();
            Invalidate();
        }
        [[nodiscard]] Color GetColor() const noexcept { return FromHsv(m_hsv); }
        [[nodiscard]] const ColorHsv& GetHsv() const noexcept { return m_hsv; }
        /// Whether it edits alpha (its strip and field show).
        void SetShowsAlpha(bool shows)
        {
            m_showsAlpha = shows;
            m_alpha->SetDisplayed(shows);
            m_channels[3]->SetDisplayed(shows);
            m_channelLabels[3]->SetDisplayed(shows);
            if (!shows)
                m_hsv.A = 1.0f;
            ShowFields();
        }
        [[nodiscard]] bool ShowsAlpha() const noexcept { return m_showsAlpha; }

        /// Each step of a drag (or a field's scrub), as it goes.
        void SetOnColorChanging(core::Function<void(Color)> callback) { m_onChanging = core::Move(callback); }
        /// A change made: a drag let go, a field committed.
        void SetOnColorChanged(core::Function<void(Color)> callback) { m_onChanged = core::Move(callback); }

        [[nodiscard]] ColorPickerArea* GetPlane() const noexcept { return m_plane.Get(); }
        [[nodiscard]] ColorPickerArea* GetHueStrip() const noexcept { return m_hue.Get(); }
        [[nodiscard]] ColorPickerArea* GetAlphaStrip() const noexcept { return m_alpha.Get(); }
        [[nodiscard]] TextField* GetHexField() const noexcept { return m_hex.Get(); }
        [[nodiscard]] NumberField* GetChannelField(i32 channel) const { return channel >= 0 && channel < 4 ? m_channels[channel].Get() : nullptr; }

    private:
        friend class ColorPickerArea;

        // A drag's step in an area: `x` and `y` across it, 0-1.
        void Dragged(ColorPickerArea::Kind kind, f32 x, f32 y, bool done)
        {
            x = core::Clamp(x, 0.0f, 1.0f);
            y = core::Clamp(y, 0.0f, 1.0f);
            if (kind == ColorPickerArea::Kind::Plane)
            {
                m_hsv.S = x;
                m_hsv.V = 1.0f - y;
            }
            else if (kind == ColorPickerArea::Kind::Hue)
                m_hsv.H = x * 360.0f;
            else
                m_hsv.A = x;
            ShowFields();
            Invalidate();
            Report(done);
        }
        void TypedHex(core::StringView text)
        {
            const Optional<Color> parsed = ParseColor(core::Trim(text));
            if (!parsed.HasValue())
            {
                ShowFields(); // not a colour: what it was
                return;
            }
            Color color = parsed.Value();
            if (!m_showsAlpha)
                color.a = 1.0f;
            m_hsv = ToHsv(color, m_hsv.H);
            ShowFields();
            Invalidate();
            Report(true);
        }
        void TypedChannel(i32 channel, f64 value, bool done)
        {
            if (m_showing)
                return;
            Color color = FromHsv(m_hsv);
            f32* channels[] = {&color.r, &color.g, &color.b, &color.a};
            *channels[channel] = static_cast<f32>(value / 255.0);
            m_hsv = ToHsv(color, m_hsv.H);
            ShowFields(channel);
            Invalidate();
            Report(done);
        }
        void Report(bool done)
        {
            const Color color = FromHsv(m_hsv);
            if (done)
            {
                if (m_onChanged)
                    m_onChanged(color);
                SendEvent(Event(EventType::Changed, this));
            }
            else
            {
                if (m_onChanging)
                    m_onChanging(color);
                SendEvent(Event(EventType::Input, this));
            }
        }
        // The fields show the colour (all but `except`, being typed into).
        void ShowFields(i32 except = -1)
        {
            m_showing = true;
            const Color color = FromHsv(m_hsv);
            m_hex->SetText(FormatHexColor(color, m_showsAlpha).AsView());
            const f32 channels[] = {color.r, color.g, color.b, color.a};
            for (i32 i = 0; i < 4; ++i)
                if (i != except)
                    m_channels[i]->SetValue(static_cast<f64>(core::Clamp(channels[i], 0.0f, 1.0f) * 255.0f + 0.5f));
            m_showing = false;
            m_plane->Invalidate();
            m_hue->Invalidate();
            m_alpha->Invalidate();
        }

        ColorHsv m_hsv{0.0f, 0.0f, 1.0f, 1.0f};
        bool m_showsAlpha = true;
        bool m_showing = false; // the fields are being set from the colour
        core::RefPtr<ColorPickerArea> m_plane;
        core::RefPtr<ColorPickerArea> m_hue;
        core::RefPtr<ColorPickerArea> m_alpha;
        core::RefPtr<UIWidget> m_fields;
        core::RefPtr<TextField> m_hex;
        core::RefPtr<NumberField> m_channels[4];
        core::RefPtr<Label> m_channelLabels[4];
        core::Function<void(Color)> m_onChanging;
        core::Function<void(Color)> m_onChanged;
    };

    // === The areas ===

    inline void ColorPickerArea::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        m_dragging = true;
        At(event.Position);
    }
    inline void ColorPickerArea::OnMouseMove(const MouseEvent& event)
    {
        if (m_dragging)
            At(event.Position);
    }
    inline void ColorPickerArea::OnMouseUp(const MouseEvent& event)
    {
        if (!m_dragging)
            return;
        m_dragging = false;
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        const Rect box = GetContentBounds();
        f32 x = box.width > 0.0f ? (local.x - box.x) / box.width : 0.0f;
        if (m_kind != Kind::Plane && IsRightToLeft())
            x = 1.0f - x; // a strip runs from the inline start
        m_picker.Dragged(m_kind, x, box.height > 0.0f ? (local.y - box.y) / box.height : 0.0f, true);
    }
    inline void ColorPickerArea::OnPointerCancel(const MouseEvent&) { m_dragging = false; }
    inline void ColorPickerArea::At(core::Float2 screen)
    {
        const core::Float2 local = ConvertToNodeSpace(screen);
        const Rect box = GetContentBounds();
        f32 x = box.width > 0.0f ? (local.x - box.x) / box.width : 0.0f;
        if (m_kind != Kind::Plane && IsRightToLeft())
            x = 1.0f - x;
        m_picker.Dragged(m_kind, x, box.height > 0.0f ? (local.y - box.y) / box.height : 0.0f, false);
    }
    inline void ColorPickerArea::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        const Rect box = GetContentBounds();
        const ColorHsv& hsv = m_picker.GetHsv();
        const bool rtl = IsRightToLeft() && m_kind != Kind::Plane;
        const Color marker{1.0f, 1.0f, 1.0f, 1.0f};
        const Color edge{0.0f, 0.0f, 0.0f, 0.6f};
        if (m_kind == Kind::Plane)
        {
            // The hue at full, white across from the left, black up from the bottom.
            ctx.VG().FillRect(box.ToRectangle(), FromHsv(ColorHsv{hsv.H, 1.0f, 1.0f, 1.0f}));
            vg::VGLinearGradientFill white{core::Float2{box.x, box.y}, core::Float2{box.Right(), box.y}};
            white.AddStop(0.0f, Color{1.0f, 1.0f, 1.0f, 1.0f});
            white.AddStop(1.0f, Color{1.0f, 1.0f, 1.0f, 0.0f});
            ctx.VG().FillPath(detail::RectPath(box), white);
            vg::VGLinearGradientFill black{core::Float2{box.x, box.y}, core::Float2{box.x, box.Bottom()}};
            black.AddStop(0.0f, Color{0.0f, 0.0f, 0.0f, 0.0f});
            black.AddStop(1.0f, Color{0.0f, 0.0f, 0.0f, 1.0f});
            ctx.VG().FillPath(detail::RectPath(box), black);
            const core::Float2 at{box.x + hsv.S * box.width, box.y + (1.0f - hsv.V) * box.height};
            vg::PathBuilder ring;
            vg::ShapeBuilder::BuildCircle(at, 5.0f, ring);
            ctx.VG().StrokePath(ring.ToPath(), edge, vg::StrokeStyle(3.0f));
            ctx.VG().StrokePath(ring.ToPath(), marker, vg::StrokeStyle(1.5f));
            return;
        }
        const core::Float2 from{rtl ? box.Right() : box.x, box.y};
        const core::Float2 to{rtl ? box.x : box.Right(), box.y};
        f32 at = 0.0f;
        if (m_kind == Kind::Hue)
        {
            vg::VGLinearGradientFill hues{from, to};
            for (i32 i = 0; i <= 6; ++i)
                hues.AddStop(static_cast<f32>(i) / 6.0f, FromHsv(ColorHsv{static_cast<f32>(i) * 60.0f, 1.0f, 1.0f, 1.0f}));
            ctx.VG().FillPath(detail::RectPath(box), hues);
            at = hsv.H / 360.0f;
        }
        else
        {
            detail::DrawChecker(ctx, box, 7.0f);
            Color opaque = FromHsv(hsv);
            opaque.a = 1.0f;
            Color clear = opaque;
            clear.a = 0.0f;
            vg::VGLinearGradientFill alpha{from, to};
            alpha.AddStop(0.0f, clear);
            alpha.AddStop(1.0f, opaque);
            ctx.VG().FillPath(detail::RectPath(box), alpha);
            at = hsv.A;
        }
        const f32 x = rtl ? box.Right() - at * box.width : box.x + at * box.width;
        const Rect handle{x - 2.0f, box.y - 1.0f, 4.0f, box.height + 2.0f};
        ctx.VG().FillRect(Rectangle{handle.x - 1.0f, handle.y - 1.0f, handle.width + 2.0f, handle.height + 2.0f}, edge);
        ctx.VG().FillRect(handle.ToRectangle(), marker);
    }
}
