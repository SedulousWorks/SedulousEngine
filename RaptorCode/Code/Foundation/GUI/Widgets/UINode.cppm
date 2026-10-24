// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :ui_node partition
//
// UINode: a Node with UI chrome. Ported from eepp's UI::UINode - adds padding (a content
// inset) and the text style; its look is its box, which sheets set, its states the selectors'.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:ui_node;

import foundation.core;  // RefPtr, Max, Move, Color
import foundation.fonts; // CachedFont
import :rect;
import :thickness;
import :event;
import :drawable;
import :text; // TextHAlign / TextVAlign (theme text-align hooks)
import :node;
import :node_box; // PartStyle
import :style_properties; // StyleValue, for MotionValue (E14)

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// One declaration of a node's inline style: markup's attributes the node does not claim, a
    /// script's style. The cascade's highest origin (E3).
    struct InlineStyleDeclaration
    {
        core::String Name;
        core::String Value;
    };

    /// One property a tween moves (E14): the style pass composes it over the cascade, as CSS's
    /// animation origin, from `From` (or the value underneath when it has none) toward `To`.
    struct MotionValue
    {
        core::String Property;
        StyleValue From;
        bool HasFrom = false;
        StyleValue To;
        f32 Progress = 0.0f; ///< eased: a curve that overshoots leaves [0, 1]
        StyleValue Shown;    ///< what the last style pass showed
        bool HasShown = false;
        StyleValue Under;    ///< what it moved from there (From, or the value underneath)
        bool HasUnder = false;
        u64 Owner = 0; ///< the tween writing it
    };

    class UINode : public Node
    {
        RTTI_OBJECT(UINode, Node)
    public:
        UINode() = default;

        // === Text style (E3) ===
        // Every node carries the text properties, so they inherit down the tree through nodes
        // that draw no text (a panel's colour reaches the labels in it): the colour, the font
        // (family and size, resolved to one cached font), and the alignment. A widget showing text
        // reads them, told by OnTextStyleChange; from code they are the code's (pinned), and the
        // subtree restyles, as what it inherits changed.
        struct TextStyle
        {
            Color TextColor = Color::White;
            fonts::CachedFont* Font = nullptr;
            core::String FontFamily; ///< the font's family as CSS names it (empty: unknown)
            /// Its font-family list's rest, its font-weight and its font-style (E11).
            FontSelection Selection;
            f32 FontSize = 0.0f;     ///< in pixels (0: unknown)
            TextHAlign HAlign = TextHAlign::Start;
            TextVAlign VAlign = TextVAlign::Top;
            TextWhiteSpace WhiteSpace = TextWhiteSpace::NoWrap; ///< a node's own: one line (CSS's initial is normal)
            f32 LineHeight = 0.0f;        ///< pixels, or a multiple of the font size when LineHeightFactor; 0: normal
            bool LineHeightFactor = false; ///< a unitless line-height, which each node applies to its own font size
            f32 LetterSpacing = 0.0f;     ///< pixels
            bool BreakWords = false;      ///< overflow-wrap: break-word or anywhere
            [[nodiscard]] bool operator==(const TextStyle& o) const noexcept
            {
                return TextColor == o.TextColor && Font == o.Font && FontFamily == o.FontFamily &&
                       Selection == o.Selection && FontSize == o.FontSize &&
                       HAlign == o.HAlign && VAlign == o.VAlign && WhiteSpace == o.WhiteSpace && LineHeight == o.LineHeight &&
                       LineHeightFactor == o.LineHeightFactor && LetterSpacing == o.LetterSpacing &&
                       BreakWords == o.BreakWords;
            }
            /// The line height in pixels (0: the font's own).
            [[nodiscard]] f32 LineHeightPixels() const noexcept { return LineHeightFactor ? LineHeight * FontSize : LineHeight; }
        };
        void SetTextColor(Color color)
        {
            PinStyle(SlotBit(SlotColor));
            TextStyle style = m_textStyle;
            style.TextColor = color;
            ChangeTextStyle(style);
        }
        void SetFont(fonts::CachedFont* font)
        {
            PinStyle(SlotBit(SlotFontFamily) | SlotBit(SlotFontSize));
            TextStyle style = m_textStyle;
            style.Font = font;
            style.FontFamily = font != nullptr && font->font != nullptr ? core::String(font->font->FamilyName()) : core::String{};
            style.Selection.FallbackFamilies.Clear();
            style.FontSize = font != nullptr && font->font != nullptr ? font->font->PixelHeight() : 0.0f;
            ChangeTextStyle(style);
        }
        void SetTextAlignment(TextHAlign horizontal, TextVAlign vertical)
        {
            PinStyle(SlotBit(SlotTextAlign) | SlotBit(SlotVerticalAlign));
            TextStyle style = m_textStyle;
            style.HAlign = horizontal;
            style.VAlign = vertical;
            ChangeTextStyle(style);
        }
        /// CSS's white-space (inherited): whether spaces collapse and lines wrap.
        void SetWhiteSpace(TextWhiteSpace whiteSpace)
        {
            PinStyle(SlotBit(SlotWhiteSpace));
            TextStyle style = m_textStyle;
            style.WhiteSpace = whiteSpace;
            ChangeTextStyle(style);
        }
        /// CSS's line-height (inherited): pixels, or with `factor` a multiple of the font size; 0: normal.
        void SetLineHeight(f32 value, bool factor = false)
        {
            PinStyle(SlotBit(SlotLineHeight));
            TextStyle style = m_textStyle;
            style.LineHeight = core::Max(0.0f, value);
            style.LineHeightFactor = factor;
            ChangeTextStyle(style);
        }
        /// CSS's letter-spacing (inherited), in pixels.
        void SetLetterSpacing(f32 pixels)
        {
            PinStyle(SlotBit(SlotLetterSpacing));
            TextStyle style = m_textStyle;
            style.LetterSpacing = pixels;
            ChangeTextStyle(style);
        }
        /// CSS's overflow-wrap (inherited): a word wider than its line breaks inside it.
        void SetBreakWords(bool breakWords)
        {
            PinStyle(SlotBit(SlotOverflowWrap));
            TextStyle style = m_textStyle;
            style.BreakWords = breakWords;
            ChangeTextStyle(style);
        }
        /// CSS's font-weight (inherited), 100 to 900: the face of the nearest weight the family has.
        void SetFontWeight(u16 weight)
        {
            PinStyle(SlotBit(SlotFontWeight));
            TextStyle style = m_textStyle;
            style.Selection.Weight = core::Clamp<u16>(weight, 1, 1000);
            ChangeTextStyle(style);
        }
        /// CSS's font-style (inherited): italic takes the family's italic face, or slants.
        void SetFontItalic(bool italic)
        {
            PinStyle(SlotBit(SlotFontStyle));
            TextStyle style = m_textStyle;
            style.Selection.Italic = italic;
            ChangeTextStyle(style);
        }
        [[nodiscard]] TextWhiteSpace GetWhiteSpace() const noexcept { return m_textStyle.WhiteSpace; }
        [[nodiscard]] const TextStyle& GetTextStyle() const noexcept { return m_textStyle; }
        [[nodiscard]] Color GetTextColor() const noexcept { return m_textStyle.TextColor; }
        [[nodiscard]] fonts::CachedFont* GetFont() const noexcept { return m_textStyle.Font; }
        [[nodiscard]] TextHAlign GetTextAlignH() const noexcept { return m_textStyle.HAlign; }
        /// Which way its text's paragraphs run: as it does (E9c), or each as it reads (auto, E11).
        [[nodiscard]] ParagraphDirection TextDirectionFor() const
        {
            const bool rightToLeft = IsRightToLeft();
            if (IsDirectionAuto())
                return ParagraphDirection{fonts::TextDirection::Auto, rightToLeft};
            return ParagraphDirection{rightToLeft ? fonts::TextDirection::RightToLeft : fonts::TextDirection::LeftToRight, false};
        }
        [[nodiscard]] TextVAlign GetTextAlignV() const noexcept { return m_textStyle.VAlign; }
        /// A modal popup's dim: its `::backdrop` part over the default one.
        void DrawBackdrop(DrawContext& ctx, const Rect& bounds) const override
        {
            GetPartStyle(u8"backdrop").Draw(ctx, bounds, FilledBox(Color{0.0f, 0.0f, 0.0f, 0.45f}));
        }
        /// The whole text style as a sheet computed it (no pins; inside a StyleWriteScope).
        void ApplyTextStyle(const TextStyle& style) { ChangeTextStyle(style); }
        /// Its own text style, captured when a sheet first styles it (what no rule and no parent gives).
        const TextStyle& CaptureUnstyledText()
        {
            if (!m_unstyledTextCaptured)
            {
                m_unstyledTextCaptured = true;
                m_unstyledText = m_textStyle;
            }
            return m_unstyledText;
        }
        /// Gives `child` this node's font and colour as its own (no pin): a composite widget's
        /// parts, kept in step where no sheet runs; a sheet's inheritance gives them the same.
        void ShareTextStyle(UINode& child, bool color = true) const
        {
            StyleWriteScope scope(child);
            TextStyle style = child.m_textStyle;
            style.Font = m_textStyle.Font;
            style.FontFamily = m_textStyle.FontFamily;
            style.Selection = m_textStyle.Selection;
            style.FontSize = m_textStyle.FontSize;
            if (color)
                style.TextColor = m_textStyle.TextColor;
            child.ChangeTextStyle(style);
        }

        // === Inline style (E3) ===
        /// Sets `name: value` in this node's inline style (replacing one of that name): it wins
        /// over every sheet's normal declarations, at the next restyle.
        void SetInlineStyle(core::StringView name, core::StringView value)
        {
            for (InlineStyleDeclaration& d : m_inlineStyle)
                if (d.Name.AsView() == name)
                {
                    if (d.Value.AsView() == value)
                        return;
                    d.Value = core::String(value);
                    MarkStyleDirty(false);
                    return;
                }
            m_inlineStyle.PushBack(InlineStyleDeclaration{core::String(name), core::String(value)});
            MarkStyleDirty(false);
        }
        void RemoveInlineStyle(core::StringView name)
        {
            for (usize i = 0; i < m_inlineStyle.Size(); ++i)
                if (m_inlineStyle[i].Name.AsView() == name)
                {
                    m_inlineStyle.RemoveAt(i);
                    MarkStyleDirty(false);
                    return;
                }
        }
        [[nodiscard]] core::Span<const InlineStyleDeclaration> GetInlineStyle() const noexcept { return m_inlineStyle.AsSpan(); }

        // === The animated layer (E14) ===
        /// What tweens move on it, over its cascade. A change marks it for the style pass to apply
        /// again (MarkStyleMotionDirty), not to resolve anew.
        [[nodiscard]] core::Span<MotionValue> MotionValues() noexcept { return m_motion.AsSpan(); }
        [[nodiscard]] bool HasMotion() const noexcept { return !m_motion.IsEmpty(); }
        [[nodiscard]] MotionValue* FindMotion(core::StringView property) noexcept
        {
            for (MotionValue& m : m_motion)
                if (m.Property.AsView() == property)
                    return &m;
            return nullptr;
        }
        /// Sets the layer's value for its property (replacing the one there).
        MotionValue& SetMotion(MotionValue value)
        {
            MarkStyleMotionDirty();
            if (MotionValue* m = FindMotion(value.Property.AsView()))
                return *m = core::Move(value);
            m_motion.PushBack(core::Move(value));
            return m_motion[m_motion.Size() - 1];
        }
        /// Gives `property` back to the cascade; false when nothing moved it.
        bool RemoveMotion(core::StringView property)
        {
            for (usize i = 0; i < m_motion.Size(); ++i)
                if (m_motion[i].Property.AsView() == property)
                {
                    m_motion.RemoveAt(i);
                    MarkStyleMotionDirty();
                    return true;
                }
            return false;
        }

        /// A reflected property a sheet set by its CSS name: the node's own value from before, the
        /// value the sheet last wrote (as text; empty when it writes none now), and whether code
        /// has since taken it.
        struct StyledProperty
        {
            core::String Name;
            Variant Own;
            core::String Written;
            bool Code = false;
        };
        [[nodiscard]] core::Array<StyledProperty>& StyledProperties() noexcept { return m_styledProperties; }

        // Markup hook: a widget consumes its own structural XML attributes (e.g. a number field's
        // "prefix" and "suffix", a table item's "cells"), returning true if it handled `name`.
        // Attributes it doesn't claim are applied as CSS properties by the markup loader. Default: none.
        virtual bool SetMarkupAttribute(core::StringView /*name*/, core::StringView /*value*/)
        {
            return false;
        }
        /// Markup hook: a `<template type="...">` child's markup (its first element, as text),
        /// which a widget that makes nodes from it (an item view's rows) keeps; false when it
        /// takes none, and the loader drops it.
        virtual bool SetMarkupTemplate(core::StringView /*type*/, core::StringView /*markup*/) { return false; }

        // Pseudo-element parts: a widget names the parts it paints (slider "track"/"fill"/
        // "thumb", checkbox "box"/"mark", window "title"/"grip", ...) so CSS `tag::part` can
        // style them with the box properties and opacity (E3). CollectStyleParts lists them; the
        // sheet sets each one's PartStyle; the widget draws a part through GetPartStyle(part).
        virtual void CollectStyleParts(core::Array<core::StringView>&) const {}
        void SetPartStyle(core::StringView part, const PartStyle& style)
        {
            for (NamedPartStyle& p : m_partStyles)
                if (p.Name.AsView() == part)
                {
                    p.Style = style;
                    OnPartStyleChange(part);
                    Invalidate();
                    return;
                }
            m_partStyles.PushBack(NamedPartStyle{core::String(part), style});
            OnPartStyleChange(part);
            Invalidate();
        }
        /// The sheet's style for `part` (an empty one when the sheet styles it not).
        [[nodiscard]] const PartStyle& GetPartStyle(core::StringView part) const; // GUIClusterImpl.cpp
        [[nodiscard]] const PartStyle* FindPartStyle(core::StringView part) const override { return &GetPartStyle(part); }

    protected:
        /// The text style changed: a widget showing text refreshes what it draws with.
        virtual void OnTextStyleChange() {}
        /// The way it runs may have changed: what shows text takes it in OnTextStyleChange.
        void OnDirectionChange() override
        {
            const ParagraphDirection direction = TextDirectionFor();
            if (direction == m_textDirection)
                return; // it runs as it did: joining a tree that runs the same way costs nothing
            m_textDirection = direction;
            OnTextStyleChange();
            RequestLayout();
            Invalidate();
        }
        /// A part's style changed: a widget whose part is a node of its own passes it on.
        virtual void OnPartStyleChange(core::StringView /*part*/) {}

    private:
        void ChangeTextStyle(const TextStyle& style)
        {
            if (style == m_textStyle)
                return;
            m_textStyle = style;
            if (!IsStyleWriting())
                MarkStyleDirty(true); // what the subtree inherits changed
            OnTextStyleChange();
            RequestLayout();
            Invalidate();
        }

        TextStyle m_textStyle;
        ParagraphDirection m_textDirection; // the direction its text was last told (E9c, E11)
        TextStyle m_unstyledText;
        bool m_unstyledTextCaptured = false;
        core::Array<InlineStyleDeclaration> m_inlineStyle;
        core::Array<MotionValue> m_motion; // what tweens move, over the cascade (E14)
        core::Array<StyledProperty> m_styledProperties;
        struct NamedPartStyle
        {
            core::String Name;
            PartStyle Style;
        };
        core::Array<NamedPartStyle> m_partStyles;
    };
}
