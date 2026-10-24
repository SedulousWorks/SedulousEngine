// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_applier partition
//
// ApplyStyle: writes a resolved style's typed values onto a node (G2 of Specs/vg-and-gui-lab.md).
// Node and text properties go to their setters; the box properties (background colour and layers,
// a border per side, radii, box shadows, filters, the backdrop filter, the blend mode) become the node's NodeBox and `transform` its style
// transform, both owned by the sheet; a property the table (StyleProperties) does not name goes to
// the widget's reflected property declaring it as its CSS name, so a library's widget is styled
// with no applier code of its own.

module;
#include "Core/Prelude.h"

export module foundation.gui:style_applier;

import foundation.core;  // Cast, Optional, Color, Float2, MakeRef, DefaultAllocator
import foundation.fonts; // CachedFont, IFontService
import foundation.image; // ImageData
import foundation.vg;    // CornerRadii
import :thickness;
import :text; // TextHAlign / TextVAlign
import :node;
import :layout_style;
import :ui_node;
import :ui_widget;
import :drawable;
import :node_box;
import :style_sheet; // ResolvedStyle
import :style_properties;
import :style_value;
import :css_values;
import :resource_provider;
import :data_model; // ConvertVariant (a reflected property of any convertible type)

using namespace foundation::core;
namespace core = foundation::core;
// Declared here, not inherited: a namespace alias is not an exported entity, so one written in
// a sibling partition is not visible in this one. This file uses fonts::, image:: and vg:: but
// declared none of them; clang happened to resolve them anyway, while MSVC (correctly) reported
// "C2653: '<name>': is not a class or namespace name". Every other partition using these
// declares its own aliases the same way. One per module imported above and referenced qualified.
namespace fonts = foundation::fonts;
namespace image = foundation::image;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    // Strip a CSS url(...) wrapper (and any quotes) to the inner resource name; returns the
    // value unchanged if it is not a url() form.
    [[nodiscard]] inline core::StringView ParseUrl(core::StringView value)
    {
        core::StringView v = core::Trim(value);
        if (v.Size() >= 5 && v.SubStr(0, 4) == core::StringView(u8"url(") &&
            v[v.Size() - 1] == u8')')
            v = core::Trim(v.SubStr(4, v.Size() - 5));
        if (v.Size() >= 2 && (v[0] == u8'"' || v[0] == u8'\'') && v[v.Size() - 1] == v[0])
            v = v.SubStr(1, v.Size() - 2);
        return v;
    }

    namespace detail
    {
        // === Layout keywords and grid values (E2) ===
        [[nodiscard]] inline LayoutLength LayoutKeyword(core::StringView k) noexcept
        {
            if (k == core::StringView(u8"fit-content"))
                return LayoutLength{LayoutLengthKind::FitContent, 0.0f};
            if (k == core::StringView(u8"min-content"))
                return LayoutLength{LayoutLengthKind::MinContent, 0.0f};
            if (k == core::StringView(u8"max-content"))
                return LayoutLength{LayoutLengthKind::MaxContent, 0.0f};
            if (k == core::StringView(u8"none"))
                return LayoutLength::None();
            return LayoutLength{};
        }
        template <typename E, usize N>
        [[nodiscard]] Optional<E> Named(core::StringView k, const core::StringView (&names)[N], const E (&values)[N])
        {
            for (usize i = 0; i < N; ++i)
                if (names[i] == k)
                    return values[i];
            return {};
        }
        [[nodiscard]] inline Optional<Display> DisplayNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"flex", u8"grid", u8"stack", u8"dock", u8"none", u8"block"};
            static constexpr Display values[] = {Display::Flex, Display::Grid, Display::Stack, Display::Dock, Display::None, Display::Flex};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<Position> PositionNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"static", u8"relative", u8"absolute"};
            static constexpr Position values[] = {Position::Static, Position::Relative, Position::Absolute};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<BoxSizing> BoxSizingNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"border-box", u8"content-box"};
            static constexpr BoxSizing values[] = {BoxSizing::BorderBox, BoxSizing::ContentBox};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<Overflow> OverflowNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"visible", u8"hidden", u8"clip", u8"scroll", u8"auto"};
            static constexpr Overflow values[] = {Overflow::Visible, Overflow::Hidden, Overflow::Hidden, Overflow::Scroll, Overflow::Auto};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<ScrollBehavior> ScrollBehaviorNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"auto", u8"smooth"};
            static constexpr ScrollBehavior values[] = {ScrollBehavior::Auto, ScrollBehavior::Smooth};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<OverscrollBehavior> OverscrollBehaviorNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"auto", u8"contain", u8"none"};
            static constexpr OverscrollBehavior values[] = {OverscrollBehavior::Auto, OverscrollBehavior::Contain, OverscrollBehavior::Contain};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<ScrollbarWidth> ScrollbarWidthNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"auto", u8"thin", u8"none"};
            static constexpr ScrollbarWidth values[] = {ScrollbarWidth::Auto, ScrollbarWidth::Thin, ScrollbarWidth::None};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<ScrollbarVisibility> ScrollbarVisibilityNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"auto", u8"overlay"};
            static constexpr ScrollbarVisibility values[] = {ScrollbarVisibility::Auto, ScrollbarVisibility::Overlay};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<FlexDirection> DirectionNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"row", u8"column", u8"row-reverse", u8"column-reverse"};
            static constexpr FlexDirection values[] = {FlexDirection::Row, FlexDirection::Column, FlexDirection::RowReverse, FlexDirection::ColumnReverse};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<FlexWrap> WrapNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"nowrap", u8"wrap", u8"wrap-reverse"};
            static constexpr FlexWrap values[] = {FlexWrap::NoWrap, FlexWrap::Wrap, FlexWrap::WrapReverse};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<Justify> JustifyNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"start", u8"flex-start", u8"end", u8"flex-end", u8"center", u8"space-between",
                                                         u8"space-around", u8"space-evenly", u8"stretch", u8"normal"};
            static constexpr Justify values[] = {Justify::Start, Justify::Start, Justify::End, Justify::End, Justify::Center, Justify::SpaceBetween,
                                                 Justify::SpaceAround, Justify::SpaceEvenly, Justify::Stretch, Justify::Stretch};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<Align> AlignNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"auto", u8"start", u8"flex-start", u8"end", u8"flex-end", u8"center",
                                                         u8"stretch", u8"baseline", u8"normal"};
            static constexpr Align values[] = {Align::Auto, Align::Start, Align::Start, Align::End, Align::End, Align::Center,
                                               Align::Stretch, Align::Baseline, Align::Stretch};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<GridAutoFlow> AutoFlowNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"row", u8"column"};
            static constexpr GridAutoFlow values[] = {GridAutoFlow::Row, GridAutoFlow::Column};
            return Named(k, names, values);
        }
        [[nodiscard]] inline Optional<Dock> DockNamed(core::StringView k)
        {
            static constexpr core::StringView names[] = {u8"fill", u8"left", u8"top", u8"right", u8"bottom", u8"start", u8"end"};
            static constexpr Dock values[] = {Dock::Fill, Dock::Left, Dock::Top, Dock::Right, Dock::Bottom, Dock::Start, Dock::End};
            return Named(k, names, values);
        }

        // A sheet's length as layout takes it: a percentage, pixels, or (a calc() with a percentage
        // part, E13) both, the units other than % resolved now.
        [[nodiscard]] inline LayoutLength ToLayoutLength(const LengthValue& l, const LengthContext& lengths)
        {
            if (l.Unit == LengthUnit::Percent)
                return LayoutLength::Percent(l.Value);
            const f32 px = ResolveLengthValue(l, lengths, 0.0f); // a calc()'s percent term drops out at base 0
            return l.PercentPart() != 0.0f ? LayoutLength::Calc(px, l.PercentPart()) : LayoutLength::Px(px);
        }

        // One track size: a length or percentage, auto, min-content, max-content, <n>fr.
        [[nodiscard]] inline Optional<LayoutLength> TrackLength(core::StringView t, const LengthContext& lengths)
        {
            if (t == core::StringView(u8"auto"))
                return LayoutLength{};
            if (t == core::StringView(u8"min-content") || t == core::StringView(u8"max-content"))
                return LayoutLength{}; // sized by content, as auto
            if (Optional<LengthValue> l = ParseLengthValue(t); l.HasValue())
                return ToLayoutLength(l.Value(), lengths);
            return {};
        }
        [[nodiscard]] inline Optional<f32> Fraction(core::StringView t)
        {
            if (t.Size() < 3 || t.SubStr(t.Size() - 2, 2) != core::StringView(u8"fr"))
                return {};
            return ParseLength(t.SubStr(0, t.Size() - 2));
        }
        [[nodiscard]] inline Optional<GridTrack> ParseTrack(core::StringView t, const LengthContext& lengths)
        {
            if (const Optional<f32> fr = Fraction(t); fr.HasValue())
                return GridTrack::Flex(fr.Value());
            if (t.Size() > 8 && t.SubStr(0, 7) == core::StringView(u8"minmax(") && t[t.Size() - 1] == u8')')
            {
                const Array<core::StringView> args = SplitTopLevel(t.SubStr(7, t.Size() - 8), u8',');
                if (args.Size() != 2)
                    return {};
                const Optional<LayoutLength> lo = TrackLength(Trim(args[0]), lengths);
                if (!lo.HasValue())
                    return {};
                if (const Optional<f32> fr = Fraction(Trim(args[1])); fr.HasValue())
                    return GridTrack{lo.Value(), LayoutLength{}, fr.Value()};
                const Optional<LayoutLength> hi = TrackLength(Trim(args[1]), lengths);
                if (!hi.HasValue())
                    return {};
                return GridTrack{lo.Value(), hi.Value(), 0.0f};
            }
            if (const Optional<LayoutLength> l = TrackLength(t, lengths); l.HasValue())
                return GridTrack{l.Value(), l.Value(), 0.0f};
            return {};
        }
        // A track list: sizes separated by spaces, `repeat(<n>, <sizes>)` among them.
        [[nodiscard]] inline Optional<Array<GridTrack>> ParseGridTracks(core::StringView text, const LengthContext& lengths)
        {
            Array<GridTrack> tracks;
            if (Trim(text) == core::StringView(u8"none"))
                return tracks;
            for (const core::StringView part : SplitTopLevel(Trim(text), u8' '))
            {
                if (part.Size() > 8 && part.SubStr(0, 7) == core::StringView(u8"repeat(") && part[part.Size() - 1] == u8')')
                {
                    const Array<core::StringView> args = SplitTopLevel(part.SubStr(7, part.Size() - 8), u8',');
                    if (args.Size() != 2)
                        return {};
                    const Optional<f32> count = ParseLength(Trim(args[0]));
                    if (!count.HasValue() || count.Value() < 1.0f)
                        return {};
                    Array<GridTrack> unit;
                    for (const core::StringView size : SplitTopLevel(Trim(args[1]), u8' '))
                    {
                        const Optional<GridTrack> track = ParseTrack(size, lengths);
                        if (!track.HasValue())
                            return {};
                        unit.PushBack(track.Value());
                    }
                    for (i32 n = 0; n < static_cast<i32>(count.Value()); ++n)
                        for (const GridTrack& track : unit)
                            tracks.PushBack(track);
                    continue;
                }
                const Optional<GridTrack> track = ParseTrack(part, lengths);
                if (!track.HasValue())
                    return {};
                tracks.PushBack(track.Value());
            }
            return tracks;
        }
        [[nodiscard]] inline bool SameTracks(const Array<GridTrack>& a, const Array<GridTrack>& b)
        {
            if (a.Size() != b.Size())
                return false;
            for (usize i = 0; i < a.Size(); ++i)
                if (!(a[i] == b[i]))
                    return false;
            return true;
        }
        // grid-column / grid-row: `2`, `1 / 3`, `span 2`, `2 / span 3`, `auto`.
        [[nodiscard]] inline Optional<GridPlacement> ParseGridPlacement(core::StringView text)
        {
            const Array<core::StringView> sides = SplitTopLevel(Trim(text), u8'/');
            if (sides.IsEmpty() || sides.Size() > 2)
                return {};
            const auto spanOf = [](core::StringView t) -> Optional<i32>
            {
                t = Trim(t);
                if (t.Size() > 5 && t.SubStr(0, 5) == core::StringView(u8"span "))
                    if (const Optional<f32> n = ParseLength(Trim(t.SubStr(5, t.Size() - 5))); n.HasValue() && n.Value() >= 1.0f)
                        return static_cast<i32>(n.Value());
                return {};
            };
            const auto lineOf = [](core::StringView t) -> Optional<i32>
            {
                t = Trim(t);
                if (t == core::StringView(u8"auto"))
                    return 0;
                if (const Optional<f32> n = ParseLength(t); n.HasValue() && n.Value() >= 1.0f)
                    return static_cast<i32>(n.Value());
                return {};
            };
            GridPlacement out;
            if (const Optional<i32> span = spanOf(sides[0]); span.HasValue())
                out.Span = span.Value();
            else if (const Optional<i32> line = lineOf(sides[0]); line.HasValue())
                out.Start = line.Value();
            else
                return {};
            if (sides.Size() == 2)
            {
                if (const Optional<i32> span = spanOf(sides[1]); span.HasValue())
                    out.Span = span.Value();
                else if (const Optional<i32> end = lineOf(sides[1]); end.HasValue() && out.Start > 0 && end.Value() > out.Start)
                    out.Span = end.Value() - out.Start;
                else
                    return {};
            }
            return out;
        }

        [[nodiscard]] inline f32 PixelsOf(const StyleValue* v, const LengthContext& lengths, f32 percentBase, f32 fallback)
        {
            return v != nullptr && v->Kind == StyleValueKind::Length ? ResolveLengthValue(v->Length, lengths, percentBase)
                                                                    : fallback;
        }

        [[nodiscard]] inline BoxGradient ToBoxGradient(const GradientValue& g)
        {
            BoxGradient out;
            out.Kind = g.Kind == GradientKind::Linear   ? BoxGradientKind::Linear
                       : g.Kind == GradientKind::Radial ? BoxGradientKind::Radial
                                                        : BoxGradientKind::Conic;
            out.Angle = g.Angle;
            out.Repeating = g.Repeating;
            for (const GradientStopValue& stop : SettleStops(g.Stops))
                out.Stops.PushBack(vg::GradientStop{stop.Position, stop.StopColor});
            return out;
        }

        // mix-blend-mode: the blends VG composites (plus-lighter is additive); another is normal.
        [[nodiscard]] inline vg::VGBlendMode BlendModeOf(core::StringView keyword)
        {
            if (keyword == core::StringView(u8"multiply"))
                return vg::VGBlendMode::Multiply;
            if (keyword == core::StringView(u8"screen"))
                return vg::VGBlendMode::Screen;
            if (keyword == core::StringView(u8"plus-lighter"))
                return vg::VGBlendMode::Additive;
            return vg::VGBlendMode::Normal;
        }

        [[nodiscard]] inline bool AnyBoxProperty(const ResolvedStyle& style)
        {
            for (const ResolvedProperty& p : style.Properties())
            {
                const core::StringView n = p.Name.AsView();
                if (n == core::StringView(u8"background-color") || n == core::StringView(u8"background-image") ||
                    n == core::StringView(u8"box-shadow") || n == core::StringView(u8"filter") ||
                    n == core::StringView(u8"backdrop-filter") || n == core::StringView(u8"mix-blend-mode") ||
                    n == core::StringView(u8"text-shadow") || n == core::StringView(u8"text-outline") ||
                    n == core::StringView(u8"text-glow") || n == core::StringView(u8"background-size") ||
                    n == core::StringView(u8"background-position") ||
                    (n.Size() > 7 && n.SubStr(0, 7) == core::StringView(u8"border-")))
                    return true;
            }
            return false;
        }

        // An image's path and, after `#xywh=`, the region of it to draw (a sprite of an atlas, as
        // Media Fragments write one: `atlas.png#xywh=0,32,16,16`); no region: all of it.
        inline core::StringView ImagePath(core::StringView url, Rectangle& region)
        {
            region = Rectangle{};
            static constexpr core::StringView kFragment(u8"#xywh=");
            for (usize i = 0; i + kFragment.Size() <= url.Size(); ++i)
                if (url.SubStr(i, kFragment.Size()) == kFragment)
                {
                    f32 v[4]{};
                    usize n = 0;
                    for (const core::StringView part : SplitTopLevel(url.SubStr(i + kFragment.Size(), url.Size() - i - kFragment.Size()), u8','))
                        if (const Optional<f32> number = ParseLength(Trim(part)); number.HasValue() && n < 4)
                            v[n++] = number.Value();
                    if (n == 4)
                        region = Rectangle{v[0], v[1], v[2], v[3]};
                    return url.SubStr(0, i);
                }
            return url;
        }

        // border-image (E13): `url(skin.png) <slice>{1,4} [fill] [/ <width>{1,4} [/ <outset>]]
        // [stretch | repeat | round | space]{1,2}`. A slice is image pixels or a percentage of
        // the image; a width a length, or a number times the border's width.
        inline void ParseBorderImage(core::StringView value, IResourceProvider* resources, const LengthContext& lengths, const vg::BorderWidths& borders,
                                     BorderImage& out)
        {
            core::String spaced; // a top-level '/' parted from what touches it (one in a url() is the path's)
            usize depth = 0;
            for (const char8_t c : value)
            {
                depth += c == u8'(' ? 1u : 0u;
                if (c == u8')' && depth > 0)
                    --depth;
                if (c == u8'/' && depth == 0)
                    spaced.Append(core::StringView(u8" / "));
                else
                    spaced.PushBack(c);
            }
            core::StringView source;
            f32 slice[4]{};
            usize slices = 0;
            bool sliceIsPercent[4]{};
            f32 width[4]{-1.0f, -1.0f, -1.0f, -1.0f};
            usize widths = 0;
            BorderImageRepeat repeats[2]{BorderImageRepeat::Stretch, BorderImageRepeat::Stretch};
            usize repeatCount = 0;
            int section = 0; // 0 slices, 1 widths, 2 outsets
            const f32 borderOf[4] = {borders.top, borders.right, borders.bottom, borders.left};
            for (const core::StringView token : SplitTopLevel(spaced.AsView(), u8' '))
            {
                core::StringView name, arguments;
                if (SplitFunction(token, name, arguments) && name == core::StringView(u8"url"))
                {
                    source = Trim(arguments);
                    if (source.Size() >= 2 && (source[0] == u8'"' || source[0] == u8'\'') && source[source.Size() - 1] == source[0])
                        source = source.SubStr(1, source.Size() - 2);
                }
                else if (token == core::StringView(u8"/"))
                    ++section;
                else if (token == core::StringView(u8"fill"))
                    out.Fill = true;
                else if (token == core::StringView(u8"stretch") || token == core::StringView(u8"repeat") || token == core::StringView(u8"round") ||
                         token == core::StringView(u8"space"))
                {
                    if (repeatCount < 2)
                        repeats[repeatCount++] = token == core::StringView(u8"stretch") ? BorderImageRepeat::Stretch
                                                 : token == core::StringView(u8"round") ? BorderImageRepeat::Round
                                                                                        : BorderImageRepeat::Repeat;
                }
                else if (section == 0 && slices < 4)
                {
                    const bool percent = token.Size() > 1 && token[token.Size() - 1] == u8'%';
                    if (const Optional<f32> n = ParseLength(percent ? token.SubStr(0, token.Size() - 1) : token); n.HasValue())
                    {
                        sliceIsPercent[slices] = percent;
                        slice[slices++] = n.Value();
                    }
                }
                else if (section == 1 && widths < 4)
                {
                    bool plain = token.Size() != 0; // a bare number (ParseLength would read "6px" as 6 too)
                    for (const char8_t c : token)
                        plain = plain && (IsDigit(c) || c == u8'.' || c == u8'-' || c == u8'+');
                    if (const Optional<f32> n = plain ? ParseLength(token) : Optional<f32>{}; n.HasValue())
                        width[widths] = -2.0f - n.Value(); // a multiple of the border's, settled below
                    else if (const Optional<LengthValue> l = ParseLengthValue(token); l.HasValue())
                        width[widths] = ResolveLengthValue(l.Value(), lengths, 0.0f);
                    ++widths;
                }
            }
            if (source.Size() == 0 || resources == nullptr)
                return;
            Rectangle region;
            f32 iw = 0.0f, ih = 0.0f;
            if (IsSvgSource(source)) // by its name or written inline: sliced in its own units
            {
                out.Svg = resources->Svg(source);
                if (out.Svg == nullptr || out.Svg->width <= 0.0f || out.Svg->height <= 0.0f)
                {
                    out.Svg = nullptr; // a picture of no size has nothing to slice
                    return;
                }
                iw = out.Svg->width;
                ih = out.Svg->height;
            }
            else
            {
                out.Image = resources->LoadImage(ImagePath(source, region));
                if (out.Image == nullptr)
                    return;
                out.Source = region;
                iw = region.width > 0.0f ? region.width : static_cast<f32>(out.Image->Width());
                ih = region.width > 0.0f ? region.height : static_cast<f32>(out.Image->Height());
            }
            // One to four values, as margins take them: top, right, bottom, left.
            const auto spread = [](f32 (&v)[4], usize count)
            {
                if (count == 1)
                    v[1] = v[2] = v[3] = v[0];
                else if (count == 2)
                {
                    v[2] = v[0];
                    v[3] = v[1];
                }
                else if (count == 3)
                    v[3] = v[1];
            };
            const auto spreadFlags = [](bool (&v)[4], usize count)
            {
                if (count == 1)
                    v[1] = v[2] = v[3] = v[0];
                else if (count == 2)
                {
                    v[2] = v[0];
                    v[3] = v[1];
                }
                else if (count == 3)
                    v[3] = v[1];
            };
            if (slices == 0)
            {
                slices = 1;
                slice[0] = 100.0f;
                sliceIsPercent[0] = true; // CSS's initial slice: 100%
            }
            spread(slice, slices);
            spreadFlags(sliceIsPercent, slices);
            for (usize i = 0; i < 4; ++i)
                out.Slice[i] = sliceIsPercent[i] ? slice[i] * ((i % 2 == 0) ? ih : iw) * 0.01f : slice[i];
            if (widths > 0)
            {
                spread(width, widths);
                for (usize i = 0; i < 4; ++i)
                    out.Width[i] = width[i] <= -2.0f ? (-2.0f - width[i]) * borderOf[i] : width[i];
            }
            out.RepeatX = repeats[0];
            out.RepeatY = repeatCount > 1 ? repeats[1] : repeats[0];
        }

        // One axis of a layer's size or position: a length, a percentage, or (`allowAuto`) auto.
        [[nodiscard]] inline Optional<LayerLength> ParseLayerLength(core::StringView t, const LengthContext& lengths, bool allowAuto)
        {
            if (t == core::StringView(u8"auto"))
                return allowAuto ? Optional<LayerLength>(LayerLength{0.0f, 0.0f, true}) : Optional<LayerLength>{};
            const Optional<LengthValue> l = ParseLengthValue(t);
            if (!l.HasValue())
                return {};
            return LayerLength{ResolveLengthValue(l.Value(), lengths, 0.0f), l.Value().PercentPart(), false};
        }
        // background-size for one layer: cover, contain, or one or two of a length, a percentage
        // (of the box) and auto (one given: the height auto).
        inline void ParseLayerSize(core::StringView t, const LengthContext& lengths, BoxLayer& out)
        {
            if (t == core::StringView(u8"cover") || t == core::StringView(u8"contain"))
            {
                out.Size = t == core::StringView(u8"cover") ? LayerSize::Cover : LayerSize::Contain;
                return;
            }
            const Array<core::StringView> parts = SplitTopLevel(t, u8' ');
            if (parts.IsEmpty() || parts.Size() > 2)
                return;
            const Optional<LayerLength> w = ParseLayerLength(parts[0], lengths, true);
            const Optional<LayerLength> h = parts.Size() > 1 ? ParseLayerLength(parts[1], lengths, true) : Optional<LayerLength>(LayerLength{0.0f, 0.0f, true});
            if (!w.HasValue() || !h.HasValue())
                return;
            out.Size = w.Value().Auto && h.Value().Auto ? LayerSize::Auto : LayerSize::Lengths;
            out.Width = w.Value();
            out.Height = h.Value();
        }
        // background-position for one layer: one or two of left, center, right, top, bottom, a
        // length and a percentage (of the room left over); one given: the other centred.
        inline void ParseLayerPosition(core::StringView t, const LengthContext& lengths, BoxLayer& out)
        {
            const Array<core::StringView> parts = SplitTopLevel(t, u8' ');
            if (parts.IsEmpty() || parts.Size() > 2)
                return;
            LayerLength x{0.0f, 50.0f, false}, y{0.0f, 50.0f, false};
            bool xSet = false;
            for (usize i = 0; i < parts.Size(); ++i)
            {
                const core::StringView p = parts[i];
                const auto percent = [](f32 v) { return LayerLength{0.0f, v, false}; };
                if (p == core::StringView(u8"left") || p == core::StringView(u8"right"))
                {
                    x = percent(p == core::StringView(u8"left") ? 0.0f : 100.0f);
                    xSet = true;
                }
                else if (p == core::StringView(u8"top") || p == core::StringView(u8"bottom"))
                {
                    y = percent(p == core::StringView(u8"top") ? 0.0f : 100.0f);
                }
                else if (p == core::StringView(u8"center"))
                    continue;
                else if (const Optional<LayerLength> l = ParseLayerLength(p, lengths, false); l.HasValue())
                {
                    if (i == 0 && !xSet)
                    {
                        x = l.Value();
                        xSet = true;
                    }
                    else
                        y = l.Value();
                }
                else
                    return;
            }
            out.X = x;
            out.Y = y;
        }

        // The node's box from the sheet's box properties, in pixels.
        [[nodiscard]] inline NodeBox BuildBox(const UINode& node, const ResolvedStyle& style, IResourceProvider* resources,
                                              const LengthContext& lengths)
        {
            NodeBox box;
            if (const StyleValue* c = style.Value(u8"background-color"))
                box.BackgroundColor = c->ColorValue;
            if (const StyleValue* layers = style.Value(u8"background-image"))
            {
                // background-size and background-position (E13): a comma list, one per layer, the
                // last repeated for layers past it (CSS's rule).
                const Array<core::StringView> sizes = SplitTopLevel(style.Get(u8"background-size"), u8',');
                const Array<core::StringView> positions = SplitTopLevel(style.Get(u8"background-position"), u8',');
                usize index = 0;
                for (const BackgroundLayer& layer : layers->Layers)
                {
                    const usize at = index++;
                    BoxLayer out;
                    if (layer.Kind == BackgroundKind::Image)
                    {
                        out.IsImage = true;
                        // An SVG by its name or written inline (E13): paths, drawn at the size it fills.
                        const core::StringView path = layer.Image.AsView();
                        const bool svg = IsSvgSource(path);
                        if (resources != nullptr && svg)
                            out.Svg = resources->Svg(path);
                        else if (resources != nullptr)
                            out.Image = resources->LoadImage(ImagePath(path, out.Source)); // a sprite's region too
                        if (out.Image == nullptr && out.Svg == nullptr)
                            continue; // not loaded (no provider, or no such image)
                        if (!sizes.IsEmpty())
                            ParseLayerSize(Trim(sizes[Min(at, sizes.Size() - 1)]), lengths, out);
                        if (!positions.IsEmpty())
                            ParseLayerPosition(Trim(positions[Min(at, positions.Size() - 1)]), lengths, out);
                    }
                    else if (layer.Kind == BackgroundKind::Gradient)
                    {
                        out.Gradient = ToBoxGradient(layer.Gradient);
                    }
                    else
                    {
                        continue; // a colour layer above the bottom is not CSS
                    }
                    box.Layers.PushBack(Move(out));
                }
            }
            // A border per side: its style none or hidden draws nothing, whatever its width.
            const auto side = [&](const char8_t* name, f32& width, Color& color, BorderLine& line)
            {
                core::String w(u8"border-");
                w.Append(core::StringView(name));
                core::String styleName = w;
                core::String colorName = w;
                w.Append(core::StringView(u8"-width"));
                styleName.Append(core::StringView(u8"-style"));
                colorName.Append(core::StringView(u8"-color"));
                const StyleValue* styleValue = style.Value(styleName.AsView());
                const core::StringView lineStyle = styleValue != nullptr ? styleValue->Keyword.AsView() : core::StringView(u8"none");
                const bool drawn = lineStyle != core::StringView(u8"none") && lineStyle != core::StringView(u8"hidden");
                width = drawn ? Max(0.0f, PixelsOf(style.Value(w.AsView()), lengths, 0.0f, 3.0f)) : 0.0f;
                line = lineStyle == core::StringView(u8"dashed")   ? BorderLine::Dashed
                       : lineStyle == core::StringView(u8"dotted") ? BorderLine::Dotted
                                                                   : BorderLine::Solid; // double, groove and the rest: solid
                if (const StyleValue* c = style.Value(colorName.AsView()))
                    color = c->ColorValue;
                else
                    color = Color{0.0f, 0.0f, 0.0f, 1.0f};
            };
            side(u8"top", box.BorderWidths.top, box.BorderColors.top, box.BorderLines[0]);
            side(u8"right", box.BorderWidths.right, box.BorderColors.right, box.BorderLines[1]);
            side(u8"bottom", box.BorderWidths.bottom, box.BorderColors.bottom, box.BorderLines[2]);
            side(u8"left", box.BorderWidths.left, box.BorderColors.left, box.BorderLines[3]);
            // A border image over the border's widths (E13).
            if (const core::StringView skin = style.Get(u8"border-image"); skin.Size() != 0 && skin != core::StringView(u8"none"))
                ParseBorderImage(skin, resources, lengths, box.BorderWidths, box.Skin);
            // Radii: a percentage of the box's smaller side.
            const core::Float2 size = node.GetSize();
            const f32 percentBase = Min(size.x, size.y);
            box.Radii = vg::CornerRadii(PixelsOf(style.Value(u8"border-top-left-radius"), lengths, percentBase, 0.0f),
                                        PixelsOf(style.Value(u8"border-top-right-radius"), lengths, percentBase, 0.0f),
                                        PixelsOf(style.Value(u8"border-bottom-right-radius"), lengths, percentBase, 0.0f),
                                        PixelsOf(style.Value(u8"border-bottom-left-radius"), lengths, percentBase, 0.0f));
            if (const StyleValue* shadows = style.Value(u8"box-shadow"))
            {
                for (const ShadowValue& s : shadows->Shadows)
                {
                    BoxShadow shadow;
                    shadow.Offset = core::Float2{ResolveLengthValue(s.OffsetX, lengths), ResolveLengthValue(s.OffsetY, lengths)};
                    shadow.Blur = ResolveLengthValue(s.Blur, lengths);
                    shadow.Spread = ResolveLengthValue(s.Spread, lengths);
                    shadow.ShadowColor = s.ShadowColor;
                    shadow.Inset = s.Inset;
                    box.Shadows.PushBack(shadow);
                }
            }
            // Effects: blurs in sequence add as variances (a blur of a blur is one of the root of the
            // squares' sum).
            const auto blurOf = [&](const char8_t* name)
            {
                f32 variance = 0.0f;
                if (const StyleValue* filters = style.Value(name))
                    for (const FilterFunction& f : filters->Filters)
                        if (f.Kind == FilterKind::Blur)
                        {
                            const f32 sigma = ResolveLengthValue(f.Amount, lengths);
                            variance += sigma * sigma;
                        }
                return Sqrt(variance);
            };
            box.FilterBlur = blurOf(u8"filter");
            box.BackdropBlur = blurOf(u8"backdrop-filter");
            if (const StyleValue* blend = style.Value(u8"mix-blend-mode"))
                box.BlendMode = BlendModeOf(blend->Keyword.AsView());
            // Text effects: each set (none included) replaces the inherited one.
            if (const StyleValue* v = style.Value(u8"text-shadow"))
            {
                box.TextEffectsSet |= NodeBox::kTextShadow;
                if (!v->Shadows.IsEmpty())
                {
                    const ShadowValue& s = v->Shadows[0];
                    box.TextEffects.shadowOffset =
                        core::Float2{ResolveLengthValue(s.OffsetX, lengths), ResolveLengthValue(s.OffsetY, lengths)};
                    box.TextEffects.shadowBlur = ResolveLengthValue(s.Blur, lengths);
                    box.TextEffects.shadowColor = s.ShadowColor;
                }
            }
            if (const StyleValue* v = style.Value(u8"text-outline"))
            {
                box.TextEffectsSet |= NodeBox::kTextOutline;
                if (!v->Shadows.IsEmpty())
                {
                    box.TextEffects.outlineWidth = ResolveLengthValue(v->Shadows[0].Spread, lengths);
                    box.TextEffects.outlineColor = v->Shadows[0].ShadowColor;
                }
            }
            if (const StyleValue* v = style.Value(u8"text-glow"))
            {
                box.TextEffectsSet |= NodeBox::kTextGlow;
                if (!v->Shadows.IsEmpty())
                {
                    box.TextEffects.glowRadius = ResolveLengthValue(v->Shadows[0].Blur, lengths);
                    box.TextEffects.glowColor = v->Shadows[0].ShadowColor;
                }
            }
            return box;
        }

        // The reflected property of the node's type (or a base's) that declares `name` as its CSS
        // name (the `css` property attribute).
        [[nodiscard]] inline const PropertyInfo* FindCssProperty(const UINode& node, core::StringView name)
        {
            for (const TypeInfo* type = node.GetType(); type != nullptr; type = type->base)
                for (usize i = 0; i < PropertyCount(*type); ++i)
                {
                    const PropertyInfo& property = PropertyAt(*type, i);
                    const Attribute* css = FindAttribute(property, u8"css");
                    const core::String* cssName = css != nullptr ? css->value.TryGet<core::String>() : nullptr;
                    if (cssName != nullptr && cssName->AsView() == name)
                        return &property;
                }
            return nullptr;
        }
        // `text` as a value of the property's type (empty when it does not convert).
        [[nodiscard]] inline Variant ParseForProperty(const PropertyInfo& property, core::StringView text, const LengthContext& lengths)
        {
            text = Trim(text);
            if (property.type == &TypeOf<f32>())
            {
                if (Optional<f32> px = ResolveLength(text, lengths); px.HasValue())
                    return Variant::From<f32>(px.Value());
                return {};
            }
            if (property.type == &TypeOf<Color>())
            {
                if (Optional<Color> c = ParseColor(text); c.HasValue())
                    return Variant::From<Color>(c.Value());
                return {};
            }
            if (property.type == &TypeOf<bool>())
            {
                if (Optional<bool> b = ParseBool(text); b.HasValue())
                    return Variant::From<bool>(b.Value());
                return {};
            }
            if (property.type == &TypeOf<core::String>())
                return Variant::From<core::String>(core::String(text));
            // Any other type a value converts to (a column count, a maximum length).
            return ConvertVariant(Variant::From<core::String>(core::String(text)), *property.type);
        }
        [[nodiscard]] inline core::String ValueText(const Variant& value)
        {
            const Variant text = ConvertVariant(value, TypeOf<core::String>());
            const core::String* s = text.TryGet<core::String>();
            return s != nullptr ? *s : core::String{};
        }

        // The reflected properties a sheet sets by their CSS names (a library's widget's own), each
        // as a setter-applied property is: the sheet's while it sets it, the node's own value back
        // when it stops, and code's once code changes it (seen as a value other than the one the
        // sheet last wrote).
        inline void ApplyReflected(UINode& node, const ResolvedStyle& style, const LengthContext& lengths)
        {
            Array<UINode::StyledProperty>& records = node.StyledProperties();
            Instance instance = Instance::From(&node);
            for (const ResolvedProperty& p : style.Properties())
            {
                if (ResolvedStyle::IsCustomProperty(p.Name.AsView()) || FindStyleProperty(p.Name.AsView()) != nullptr)
                    continue;
                const PropertyInfo* property = FindCssProperty(node, p.Name.AsView());
                if (property == nullptr)
                    continue;
                UINode::StyledProperty* record = nullptr;
                for (UINode::StyledProperty& r : records)
                    if (r.Name.AsView() == p.Name.AsView())
                        record = &r;
                if (record == nullptr)
                {
                    records.PushBack(UINode::StyledProperty{core::String(p.Name), GetProperty(*property, instance), {}, false});
                    record = &records[records.Size() - 1];
                }
                if (record->Code)
                    continue;
                if (record->Written.Size() != 0 && ValueText(GetProperty(*property, instance)) != record->Written)
                {
                    record->Code = true; // code set it since: code's now
                    continue;
                }
                const Variant value = ParseForProperty(*property, p.Value.AsView(), lengths);
                if (value.IsEmpty())
                    continue;
                // A value it holds already is not written again: a restyle would otherwise run a
                // setter each time (a list rebuilding its rows, which restyled it again, every frame).
                // Compared as text, so a value with none (a colour) is written as before.
                const core::String current = ValueText(GetProperty(*property, instance));
                if (current.Size() != 0 && ValueText(value) == current)
                {
                    record->Written = current;
                    continue;
                }
                (void)SetProperty(*property, instance, value);
                record->Written = ValueText(GetProperty(*property, instance));
            }
            // What the sheet set and sets no more: back to the node's own value.
            for (UINode::StyledProperty& r : records)
            {
                if (r.Code || r.Written.Size() == 0 || style.Has(r.Name.AsView()))
                    continue;
                const PropertyInfo* property = FindCssProperty(node, r.Name.AsView());
                if (property == nullptr)
                    continue;
                if (ValueText(GetProperty(*property, instance)) != r.Written)
                    r.Code = true;
                else
                    (void)SetProperty(*property, instance, r.Own);
                r.Written = core::String{};
            }
        }
    }

    // Apply the supported declarations of `style` to `node`. `resources` (optional) loads
    // background-image; `fontService` (optional) resolves font-family/size. Missing either
    // just skips that property. The box properties (background, border, radius, box-shadow)
    // become the node's box, owned by the sheet: a restyle without any replaces it with none.
    inline void ApplyStyle(UINode& node, const ResolvedStyle& input,
                           IResourceProvider* resources = nullptr,
                           fonts::IFontService* fontService = nullptr,
                           const LengthContext& lengths = {})
    {
        using core::StringView;
        ResolvedStyle settledCopy;
        const ResolvedStyle* settled = &input;
        if (!input.IsFinalized())
        {
            settledCopy = input;
            settledCopy.Finalize();
            settled = &settledCopy;
        }
        const ResolvedStyle& style = *settled;

        const auto length = [&](const char8_t* name, f32 base) -> Optional<f32>
        {
            const StyleValue* v = style.Value(name);
            if (v == nullptr || v->Kind != StyleValueKind::Length)
                return {};
            return ResolveLengthValue(v->Length, lengths, base);
        };
        // A length given as a percentage, which layout resolves (a margin's, a padding's, a gap's).
        const auto percentOf = [&](const char8_t* name) -> Optional<f32>
        {
            const StyleValue* v = style.Value(name);
            if (v == nullptr || v->Kind != StyleValueKind::Length || v->Length.PercentPart() == 0.0f)
                return {};
            return v->Length.PercentPart(); // a calc()'s too: layout adds it to the pixels
        };
        const auto keyword = [&](const char8_t* name) -> StringView
        {
            const StyleValue* v = style.Value(name);
            return v != nullptr ? v->Keyword.AsView() : StringView{};
        };

        // What the sheet sets through setters (E3): a property code pinned stays code's; one the
        // sheet sets takes its value; one it does not returns to the node's own value.
        Node::StyleWriteScope writing(node);
        const Node::UnstyledValues& own = node.CaptureUnstyledValues();
        const auto free = [&](StyleSlot slot) { return !node.IsStylePinned(slot); };

        if (free(SlotOpacity))
        {
            const StyleValue* o = style.Value(u8"opacity");
            const f32 alpha = o != nullptr ? o->Number : own.Alpha;
            if (alpha != node.GetAlpha())
                node.SetAlpha(alpha);
        }

        // The direction (E9b): first, as the logical sides (inline start and end)
        // and the text's start and end follow it. Not inherited
        // through the style: a node with none runs as the first ancestor that says does.
        if (free(SlotDirection))
        {
            const StringView v = keyword(u8"direction");
            node.SetLayoutDirection(v == StringView(u8"rtl")    ? Node::LayoutDirection::RightToLeft
                                    : v == StringView(u8"ltr")  ? Node::LayoutDirection::LeftToRight
                                    : v == StringView(u8"auto") ? Node::LayoutDirection::Auto
                                                                : Node::LayoutDirection::Inherit);
        }

        // The logical sides (E9b) name the physical ones the node's direction puts them on; given
        // beside a physical one for the same side, the logical one wins.
        const bool rtl = node.IsRightToLeft();
        const char8_t* const startSide = rtl ? u8"right" : u8"left";
        const auto logical = [&](const char8_t* prefix, const char8_t* side) -> const char8_t*
        {
            // margin- / padding- / inset- with inline-start or inline-end, by which side `side` is.
            const bool start = StringView(side) == StringView(startSide);
            if (StringView(prefix) == StringView(u8"margin-"))
                return start ? u8"margin-inline-start" : u8"margin-inline-end";
            if (StringView(prefix) == StringView(u8"padding-"))
                return start ? u8"padding-inline-start" : u8"padding-inline-end";
            return start ? u8"inset-inline-start" : u8"inset-inline-end";
        };

        {
            Thickness padding = node.GetPaddingLengths();
            Thickness paddingPercent = node.GetPaddingPercent();
            const auto side = [&](StyleSlot slot, const char8_t* name, f32& field, f32 ownValue, f32& percentField)
            {
                if (!free(slot))
                    return;
                // A percentage is of the containing box's width, which layout knows.
                // A calc() has both: its percent part here, its pixels (base 0 drops the percent) there.
                const Optional<f32> percent = percentOf(name);
                percentField = percent.ValueOr(0.0f);
                field = length(name, 0.0f).ValueOr(percent.HasValue() ? 0.0f : ownValue);
            };
            side(SlotPaddingTop, u8"padding-top", padding.Top, own.Padding.Top, paddingPercent.Top);
            side(SlotPaddingRight, u8"padding-right", padding.Right, own.Padding.Right, paddingPercent.Right);
            side(SlotPaddingBottom, u8"padding-bottom", padding.Bottom, own.Padding.Bottom, paddingPercent.Bottom);
            side(SlotPaddingLeft, u8"padding-left", padding.Left, own.Padding.Left, paddingPercent.Left);
            const auto logicalSide = [&](StyleSlot slot, const char8_t* name, f32& field, f32& percentField)
            {
                if (!free(slot))
                    return;
                if (const Optional<f32> percent = percentOf(name); percent.HasValue())
                {
                    percentField = percent.Value();
                    field = length(name, 0.0f).ValueOr(0.0f); // a calc()'s pixels beside its percent
                }
                else if (const Optional<f32> v = length(name, 0.0f); v.HasValue())
                {
                    field = v.Value();
                    percentField = 0.0f;
                }
            };
            logicalSide(SlotPaddingLeft, logical(u8"padding-", u8"left"), padding.Left, paddingPercent.Left);
            logicalSide(SlotPaddingRight, logical(u8"padding-", u8"right"), padding.Right, paddingPercent.Right);
            if (!(padding == node.GetPaddingLengths()))
                node.SetPadding(padding);
            node.SetPaddingPercent(paddingPercent);
        }

        // Layout (E2): the sheet's values over the node's own, then each field code pinned as code
        // left it. Percentages and auto wait for layout.
        {
            LayoutStyle ls = own.Layout;
            bool changed = false;
            const auto assign = [&changed](auto& field, const auto& value)
            {
                if (!(field == value))
                {
                    field = value;
                    changed = true;
                }
            };
            const auto size = [&](const char8_t* name, LayoutLength& field)
            {
                const StyleValue* v = style.Value(name);
                if (v == nullptr)
                    return;
                if (v->Kind == StyleValueKind::Length)
                    assign(field, detail::ToLayoutLength(v->Length, lengths));
                else if (v->Kind == StyleValueKind::Keyword)
                    assign(field, detail::LayoutKeyword(v->Keyword.AsView()));
            };
            size(u8"width", ls.Width);
            size(u8"height", ls.Height);
            size(u8"min-width", ls.MinWidth);
            size(u8"min-height", ls.MinHeight);
            size(u8"max-width", ls.MaxWidth);
            size(u8"max-height", ls.MaxHeight);
            size(u8"top", ls.Top);
            size(u8"right", ls.Right);
            size(u8"bottom", ls.Bottom);
            size(u8"left", ls.Left);
            size(logical(u8"inset-", u8"left"), ls.Left);
            size(logical(u8"inset-", u8"right"), ls.Right);
            size(u8"flex-basis", ls.Basis);
            {
                // A side as a length, or as a percentage of the containing box's width (layout's).
                Thickness margin = ls.Margin;
                Thickness percent = ls.MarginPercent;
                const auto marginSide = [&](const char8_t* name, f32& field, f32& percentField)
                {
                    if (const Optional<f32> p = percentOf(name); p.HasValue())
                    {
                        percentField = p.Value();
                        field = length(name, 0.0f).ValueOr(0.0f); // a calc()'s pixels beside its percent
                    }
                    else if (const Optional<f32> v = length(name, 0.0f); v.HasValue())
                    {
                        field = v.Value();
                        percentField = 0.0f;
                    }
                };
                marginSide(u8"margin-top", margin.Top, percent.Top);
                marginSide(u8"margin-right", margin.Right, percent.Right);
                marginSide(u8"margin-bottom", margin.Bottom, percent.Bottom);
                marginSide(u8"margin-left", margin.Left, percent.Left);
                marginSide(logical(u8"margin-", u8"left"), margin.Left, percent.Left);
                marginSide(logical(u8"margin-", u8"right"), margin.Right, percent.Right);
                assign(ls.Margin, margin);
                assign(ls.MarginPercent, percent);
            }
            const auto number = [&](const char8_t* name) -> Optional<f32>
            {
                if (const StyleValue* v = style.Value(name); v != nullptr && v->Kind == StyleValueKind::Number)
                    return v->Number;
                return {};
            };
            if (const Optional<f32> n = number(u8"flex-grow"); n.HasValue()) assign(ls.Grow, n.Value());
            if (const Optional<f32> n = number(u8"flex-shrink"); n.HasValue()) assign(ls.Shrink, n.Value());
            if (const Optional<f32> n = number(u8"order"); n.HasValue()) assign(ls.Order, static_cast<i32>(n.Value()));
            if (const Optional<f32> n = number(u8"z-index"); n.HasValue()) assign(ls.ZIndex, static_cast<i32>(n.Value()));
            // A gap as a length, or a percentage of the container's content size (layout's).
            if (const Optional<f32> p = percentOf(u8"row-gap"); p.HasValue())
            {
                assign(ls.RowGapPercent, p.Value());
                assign(ls.RowGap, length(u8"row-gap", 0.0f).ValueOr(0.0f));
            }
            else if (Optional<f32> v = length(u8"row-gap", 0.0f); v.HasValue())
                assign(ls.RowGap, v.Value());
            if (const Optional<f32> p = percentOf(u8"column-gap"); p.HasValue())
            {
                assign(ls.ColumnGapPercent, p.Value());
                assign(ls.ColumnGap, length(u8"column-gap", 0.0f).ValueOr(0.0f));
            }
            else if (Optional<f32> v = length(u8"column-gap", 0.0f); v.HasValue())
                assign(ls.ColumnGap, v.Value());
            const auto choose = [&](const char8_t* name, auto& field, auto parse)
            {
                if (const StringView k = keyword(name); k.Size() != 0)
                    if (const auto parsed = parse(k); parsed.HasValue())
                        assign(field, parsed.Value());
            };
            choose(u8"display", ls.Kind, detail::DisplayNamed);
            choose(u8"position", ls.Placement, detail::PositionNamed);
            choose(u8"box-sizing", ls.Sizing, detail::BoxSizingNamed);
            choose(u8"overflow-x", ls.OverflowX, detail::OverflowNamed);
            choose(u8"overflow-y", ls.OverflowY, detail::OverflowNamed);
            choose(u8"scroll-behavior", ls.Scrolling, detail::ScrollBehaviorNamed);
            choose(u8"overscroll-behavior", ls.Overscroll, detail::OverscrollBehaviorNamed);
            choose(u8"scrollbar-width", ls.BarWidth, detail::ScrollbarWidthNamed);
            choose(u8"scrollbar-visibility", ls.BarVisibility, detail::ScrollbarVisibilityNamed);
            choose(u8"flex-direction", ls.Direction, detail::DirectionNamed);
            choose(u8"flex-wrap", ls.Wrap, detail::WrapNamed);
            choose(u8"justify-content", ls.JustifyContent, detail::JustifyNamed);
            choose(u8"align-content", ls.AlignContent, detail::JustifyNamed);
            choose(u8"align-items", ls.AlignItems, detail::AlignNamed);
            choose(u8"justify-items", ls.JustifyItems, detail::AlignNamed);
            choose(u8"align-self", ls.AlignSelf, detail::AlignNamed);
            choose(u8"justify-self", ls.JustifySelf, detail::AlignNamed);
            choose(u8"grid-auto-flow", ls.AutoFlow, detail::AutoFlowNamed);
            choose(u8"dock", ls.DockSide, detail::DockNamed);
            if (const StringView t = keyword(u8"grid-template-columns"); t.Size() != 0)
                if (Optional<Array<GridTrack>> tracks = detail::ParseGridTracks(t, lengths); tracks.HasValue() && !detail::SameTracks(ls.Columns, tracks.Value()))
                {
                    ls.Columns = Move(tracks.Value());
                    changed = true;
                }
            if (const StringView t = keyword(u8"grid-template-rows"); t.Size() != 0)
                if (Optional<Array<GridTrack>> tracks = detail::ParseGridTracks(t, lengths); tracks.HasValue() && !detail::SameTracks(ls.Rows, tracks.Value()))
                {
                    ls.Rows = Move(tracks.Value());
                    changed = true;
                }
            if (const StringView t = keyword(u8"grid-auto-rows"); t.Size() != 0)
                if (Optional<Array<GridTrack>> tracks = detail::ParseGridTracks(t, lengths); tracks.HasValue() && tracks.Value().Size() == 1)
                    assign(ls.AutoRows, tracks.Value()[0]);
            if (const StringView t = keyword(u8"grid-auto-columns"); t.Size() != 0)
                if (Optional<Array<GridTrack>> tracks = detail::ParseGridTracks(t, lengths); tracks.HasValue() && tracks.Value().Size() == 1)
                    assign(ls.AutoColumns, tracks.Value()[0]);
            if (const StringView t = keyword(u8"grid-column"); t.Size() != 0)
                if (const Optional<GridPlacement> g = detail::ParseGridPlacement(t); g.HasValue())
                    assign(ls.Column, g.Value());
            if (const StringView t = keyword(u8"grid-row"); t.Size() != 0)
                if (const Optional<GridPlacement> g = detail::ParseGridPlacement(t); g.HasValue())
                    assign(ls.Row, g.Value());
            (void)changed;
            LayoutStyle result = node.GetLayoutStyle();
            ForEachLayoutField([&](StyleSlot slot, auto member)
            {
                if (free(slot))
                    result.*member = ls.*member;
            });
            if (free(SlotMarginTop)) { result.Margin.Top = ls.Margin.Top; result.MarginPercent.Top = ls.MarginPercent.Top; }
            if (free(SlotMarginRight)) { result.Margin.Right = ls.Margin.Right; result.MarginPercent.Right = ls.MarginPercent.Right; }
            if (free(SlotMarginBottom)) { result.Margin.Bottom = ls.Margin.Bottom; result.MarginPercent.Bottom = ls.MarginPercent.Bottom; }
            if (free(SlotMarginLeft)) { result.Margin.Left = ls.Margin.Left; result.MarginPercent.Left = ls.MarginPercent.Left; }
            if (free(SlotRowGap)) result.RowGapPercent = ls.RowGapPercent;
            if (free(SlotColumnGap)) result.ColumnGapPercent = ls.ColumnGapPercent;
            if (ChangedLayoutSlots(result, node.GetLayoutStyle()).Any())
                node.SetLayoutStyle(result);
            // Anything but visible clips the children to the box (and scroll and auto scroll them);
            // a widget that clips its own parts (an item view's rows) keeps doing so unless the
            // sheet says.
            if (free(SlotOverflowX) && free(SlotOverflowY))
            {
                if (keyword(u8"overflow-x").Size() != 0 || keyword(u8"overflow-y").Size() != 0)
                    node.SetClipChildren(result.OverflowX != Overflow::Visible || result.OverflowY != Overflow::Visible);
                else
                    node.SetClipChildren(own.ClipChildren);
            }
        }

        if (free(SlotEnabled))
        {
            bool enabled = own.Enabled;
            if (const StringView e = keyword(u8"enabled"); e.Size() != 0)
                if (Optional<bool> b = ParseBool(e); b.HasValue())
                    enabled = b.Value();
            if (enabled != node.IsEnabled())
                node.SetEnabled(enabled);
        }
        if (free(SlotVisibility))
        {
            const StringView v = keyword(u8"visibility");
            const bool visible = v == StringView(u8"hidden") ? false : v == StringView(u8"visible") ? true : own.Visible;
            if (visible != node.IsVisible())
                node.SetVisible(visible);
        }

        // Text (E3, E4): colour, the font, text-align, white-space, line-height and letter-spacing
        // inherit (the sheet's value, else the parent's, else the node's own; `initial` is the
        // node's own, or CSS's where the table names one); vertical-align does not.
        {
            const UINode::TextStyle& ownText = node.CaptureUnstyledText();
            const UINode* parent = core::Cast<UINode>(node.GetParent());
            const auto initial = [&](const char8_t* name) { return style.Get(name) == StringView(u8"initial"); };
            const auto inherits = [&](const char8_t* name) { return parent != nullptr && !initial(name); };
            UINode::TextStyle text = node.GetTextStyle();
            if (free(SlotColor))
            {
                if (const StyleValue* c = style.Value(u8"color"))
                    text.TextColor = c->ColorValue;
                else
                    text.TextColor = inherits(u8"color") ? parent->GetTextColor() : ownText.TextColor;
            }
            if (free(SlotTextAlign))
            {
                // start and end are the line's (E9c): its paragraph's direction places them.
                const StringView v = keyword(u8"text-align");
                if (v == StringView(u8"left") || v == StringView(u8"justify"))
                    text.HAlign = TextHAlign::Left;
                else if (v == StringView(u8"center") || v == StringView(u8"centre"))
                    text.HAlign = TextHAlign::Center;
                else if (v == StringView(u8"right"))
                    text.HAlign = TextHAlign::Right;
                else if (v == StringView(u8"start"))
                    text.HAlign = TextHAlign::Start;
                else if (v == StringView(u8"end"))
                    text.HAlign = TextHAlign::End;
                else
                    text.HAlign = inherits(u8"text-align") ? parent->GetTextAlignH() : ownText.HAlign;
            }
            if (free(SlotVerticalAlign))
            {
                const StringView v = keyword(u8"vertical-align");
                if (v == StringView(u8"top"))
                    text.VAlign = TextVAlign::Top;
                else if (v == StringView(u8"middle") || v == StringView(u8"center"))
                    text.VAlign = TextVAlign::Middle;
                else if (v == StringView(u8"bottom"))
                    text.VAlign = TextVAlign::Bottom;
                else
                    text.VAlign = ownText.VAlign;
            }
            if (free(SlotFontFamily) || free(SlotFontSize))
            {
                // The family and the size each from the sheet, the parent or the node itself; the
                // font is the parent's or the node's own when both come from there, else the
                // font service's for the pair.
                // A list (E11 of Specs/gui-lab-evolution-2.md): the first family the service has is
                // the font, the rest after it the faces a character it lacks falls back to. When it
                // has none of them, the first is asked for all the same (a service may resolve a
                // family it does not list, to its default).
                const StringView declaredList = initial(u8"font-family") ? StringView{} : keyword(u8"font-family");
                StringView declaredFamily;
                StringView firstFamily;
                core::String declaredFallbacks;
                ForEachFamily(declaredList,
                              [&](StringView family)
                              {
                                  if (firstFamily.Size() == 0)
                                      firstFamily = family;
                                  if (declaredFamily.Size() == 0)
                                  {
                                      if (fontService == nullptr || fontService->HasFamily(family))
                                          declaredFamily = family;
                                      return;
                                  }
                                  if (declaredFallbacks.Size() != 0)
                                      declaredFallbacks.Append(u8", ");
                                  declaredFallbacks.Append(family);
                              });
                if (declaredFamily.Size() == 0)
                    declaredFamily = firstFamily;
                // font-size's em and percentages are of the parent's size, not its own.
                LengthContext parentLengths = lengths;
                parentLengths.ElementFontSize = parent != nullptr && parent->GetTextStyle().FontSize > 0.0f ? parent->GetTextStyle().FontSize
                                                                                                             : lengths.RootFontSize;
                const StyleValue* sizeValue = style.Value(u8"font-size");
                const Optional<f32> declaredSize = sizeValue != nullptr && sizeValue->Kind == StyleValueKind::Length
                                                       ? Optional<f32>(ResolveLengthValue(sizeValue->Length, parentLengths, parentLengths.ElementFontSize))
                                                       : Optional<f32>{};
                const UINode::TextStyle& from = inherits(u8"font-family") || inherits(u8"font-size") ? parent->GetTextStyle() : ownText;
                const bool familyDeclared = free(SlotFontFamily) && declaredFamily.Size() != 0;
                const bool sizeDeclared = free(SlotFontSize) && declaredSize.HasValue() && declaredSize.Value() > 0.0f;
                if (!familyDeclared && !sizeDeclared)
                {
                    text.Font = from.Font;
                    text.FontFamily = from.FontFamily;
                    text.Selection.FallbackFamilies = from.Selection.FallbackFamilies;
                    text.FontSize = from.FontSize;
                }
                else
                {
                    const core::String family = familyDeclared ? core::String(declaredFamily) : from.FontFamily;
                    const core::String fallbacks = familyDeclared ? Move(declaredFallbacks) : from.Selection.FallbackFamilies;
                    const f32 size = sizeDeclared ? declaredSize.Value() : (from.FontSize > 0.0f ? from.FontSize : 16.0f);
                    if (fontService != nullptr && family.Size() != 0)
                        if (fonts::CachedFont* font = fontService->GetFont(family.AsView(), size))
                        {
                            text.Font = font;
                            text.FontFamily = family;
                            text.Selection.FallbackFamilies = fallbacks;
                            text.FontSize = size;
                        }
                }
            }
            // white-space, line-height and letter-spacing inherit as the rest do (E4).
            if (free(SlotWhiteSpace))
            {
                const StringView v = keyword(u8"white-space");
                if (v == StringView(u8"normal"))
                    text.WhiteSpace = TextWhiteSpace::Normal;
                else if (v == StringView(u8"nowrap"))
                    text.WhiteSpace = TextWhiteSpace::NoWrap;
                else if (v == StringView(u8"pre"))
                    text.WhiteSpace = TextWhiteSpace::Pre;
                else if (v == StringView(u8"pre-wrap") || v == StringView(u8"pre-line") || v == StringView(u8"break-spaces"))
                    text.WhiteSpace = TextWhiteSpace::PreWrap;
                else
                    text.WhiteSpace = inherits(u8"white-space") ? parent->GetTextStyle().WhiteSpace : ownText.WhiteSpace;
            }
            if (free(SlotLineHeight))
            {
                // normal; a bare number, a multiple of each node's own font size (inherited as the
                // number); a length; a percentage of the font size (inherited as the pixels).
                const StringView v = Trim(keyword(u8"line-height"));
                const Optional<f64> number = v.Size() != 0 ? ParseFloat(v) : Optional<f64>{};
                const UINode::TextStyle& from = inherits(u8"line-height") ? parent->GetTextStyle() : ownText;
                if (v == StringView(u8"normal"))
                {
                    text.LineHeight = 0.0f;
                    text.LineHeightFactor = false;
                }
                else if (number.HasValue())
                {
                    text.LineHeight = core::Max(0.0f, static_cast<f32>(number.Value()));
                    text.LineHeightFactor = true;
                }
                else if (v.Size() > 1 && v[v.Size() - 1] == u8'%' && ParseFloat(v.SubStr(0, v.Size() - 1)).HasValue())
                {
                    text.LineHeight = core::Max(0.0f, static_cast<f32>(ParseFloat(v.SubStr(0, v.Size() - 1)).Value()) * 0.01f * text.FontSize);
                    text.LineHeightFactor = false;
                }
                else if (const Optional<f32> px = v.Size() != 0 ? ResolveLength(v, lengths) : Optional<f32>{}; px.HasValue())
                {
                    text.LineHeight = core::Max(0.0f, px.Value());
                    text.LineHeightFactor = false;
                }
                else
                {
                    text.LineHeight = from.LineHeight;
                    text.LineHeightFactor = from.LineHeightFactor;
                }
            }
            // font-weight and font-style (E11) inherit; a run's face is chosen from them as it lays
            // out. bolder and lighter are of the parent's weight.
            if (free(SlotFontWeight))
            {
                const StringView v = Trim(keyword(u8"font-weight"));
                const u16 inherited = parent != nullptr ? parent->GetTextStyle().Selection.Weight : u16{400};
                const Optional<f64> number = v.Size() != 0 ? ParseFloat(v) : Optional<f64>{};
                if (v == StringView(u8"normal"))
                    text.Selection.Weight = 400;
                else if (v == StringView(u8"bold"))
                    text.Selection.Weight = 700;
                else if (v == StringView(u8"bolder"))
                    text.Selection.Weight = detail::Bolder(inherited);
                else if (v == StringView(u8"lighter"))
                    text.Selection.Weight = detail::Lighter(inherited);
                else if (number.HasValue() && number.Value() >= 1.0 && number.Value() <= 1000.0)
                    text.Selection.Weight = static_cast<u16>(number.Value());
                else
                    text.Selection.Weight = inherits(u8"font-weight") ? inherited : ownText.Selection.Weight;
            }
            if (free(SlotFontStyle))
            {
                const StringView v = Trim(keyword(u8"font-style"));
                if (v == StringView(u8"normal"))
                    text.Selection.Italic = false;
                else if (v == StringView(u8"italic") || v.StartsWith(StringView(u8"oblique")))
                    text.Selection.Italic = true;
                else
                    text.Selection.Italic = inherits(u8"font-style") ? parent->GetTextStyle().Selection.Italic : ownText.Selection.Italic;
            }
            if (free(SlotOverflowWrap))
            {
                const StringView v = keyword(u8"overflow-wrap");
                if (v == StringView(u8"normal"))
                    text.BreakWords = false;
                else if (v == StringView(u8"break-word") || v == StringView(u8"anywhere"))
                    text.BreakWords = true;
                else
                    text.BreakWords = inherits(u8"overflow-wrap") ? parent->GetTextStyle().BreakWords : ownText.BreakWords;
            }
            if (free(SlotLetterSpacing))
            {
                const StringView v = Trim(keyword(u8"letter-spacing"));
                if (v == StringView(u8"normal"))
                    text.LetterSpacing = 0.0f;
                else if (const Optional<f32> px = v.Size() != 0 ? ResolveLength(v, lengths) : Optional<f32>{}; px.HasValue())
                    text.LetterSpacing = px.Value();
                else
                    text.LetterSpacing = inherits(u8"letter-spacing") ? parent->GetTextStyle().LetterSpacing : ownText.LetterSpacing;
            }
            node.ApplyTextStyle(text);
        }

        // The box: the sheet's, or none when a restyle drops every box property it had set.
        if (detail::AnyBoxProperty(style))
            node.SetBox(detail::BuildBox(node, style, resources, lengths), true);
        else if (node.IsBoxFromStyle())
            node.SetBox(NodeBox{}, true);

        // The transform about its origin; likewise owned by the sheet once it sets one.
        const StyleValue* transform = style.Value(u8"transform");
        const StyleValue* origin = style.Value(u8"transform-origin");
        if (transform != nullptr || origin != nullptr)
        {
            node.SetStyleTransform(transform != nullptr ? transform->Transforms : Array<TransformFunction>{},
                                   origin != nullptr ? origin->OriginX : LengthValue{50.0f, LengthUnit::Percent},
                                   origin != nullptr ? origin->OriginY : LengthValue{50.0f, LengthUnit::Percent});
        }
        else if (node.IsTransformFromStyle())
        {
            node.SetStyleTransform(Array<TransformFunction>{}, LengthValue{50.0f, LengthUnit::Percent},
                                   LengthValue{50.0f, LengthUnit::Percent});
        }

        // What the table does not name: a reflected property that takes it by its CSS name.
        detail::ApplyReflected(node, style, lengths);
    }

    // Apply a resolved pseudo-element style to a widget part (slider::thumb, checkbox::box,
    // window::title, ...): its box properties, opacity and colour (a part that is text), each
    // aspect marked where the sheet gives it, so the widget's own look shows through the rest.
    inline void ApplyPartStyle(UINode& node, core::StringView part, const ResolvedStyle& input,
                               IResourceProvider* resources = nullptr, const LengthContext& lengths = {})
    {
        ResolvedStyle settledCopy;
        const ResolvedStyle* settled = &input;
        if (!input.IsFinalized())
        {
            settledCopy = input;
            settledCopy.Finalize();
            settled = &settledCopy;
        }
        const ResolvedStyle& style = *settled;
        PartStyle out;
        out.Box = detail::BuildBox(node, style, resources, lengths);
        const auto any = [&](const char8_t* const (&names)[4]) {
            for (const char8_t* n : names)
                if (style.Has(n))
                    return true;
            return false;
        };
        static constexpr const char8_t* kWidths[4] = {u8"border-top-width", u8"border-right-width", u8"border-bottom-width", u8"border-left-width"};
        static constexpr const char8_t* kStyles[4] = {u8"border-top-style", u8"border-right-style", u8"border-bottom-style", u8"border-left-style"};
        static constexpr const char8_t* kColors[4] = {u8"border-top-color", u8"border-right-color", u8"border-bottom-color", u8"border-left-color"};
        static constexpr const char8_t* kRadii[4] = {u8"border-top-left-radius", u8"border-top-right-radius", u8"border-bottom-right-radius",
                                                     u8"border-bottom-left-radius"};
        out.HasBackground = style.Has(u8"background-color") || style.Has(u8"background-image");
        out.HasBorderWidth = any(kWidths) || any(kStyles);
        out.HasBorderColor = any(kColors);
        out.HasRadii = any(kRadii);
        out.HasShadows = style.Has(u8"box-shadow");
        if (const StyleValue* o = style.Value(u8"opacity"))
            out.Opacity = o->Number;
        if (const StyleValue* c = style.Value(u8"color"); c != nullptr && c->Kind == StyleValueKind::ColorValue)
        {
            out.TextColor = c->ColorValue;
            out.HasColor = true;
        }
        node.SetPartStyle(part, out);
    }
}
