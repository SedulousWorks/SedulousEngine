// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :resource_provider partition
//
// IResourceProvider: the seam the CSS engine uses to load image assets referenced by
// background-image: url(path). Aligned with Sedulous.UI / foundation.ui's IResourceProvider - it
// returns a raw, provider-owned image (not a framework Drawable), so the provider stays a pure
// asset loader (VFS + foundation.image) with no dependency on the GUI's drawable types; the
// StyleApplier wraps the image into an ImageDrawable. Font resolution is a separate seam
// (IFontProvider). An SVG may also be written inline, as a `data:image/svg+xml,...` URL (its
// markup percent-encoded or plain, or base64 after `;base64`): the provider parses it once and
// keeps it as it keeps a named one, so a box borrows either for as long as the provider lives.

module;
#include "Core/Prelude.h"

export module foundation.gui:resource_provider;

import foundation.core;  // StringView, String, Array, UniquePtr
import foundation.image; // ImageData
import foundation.vg.svg; // SVGDocument

using namespace foundation::core;
namespace core = foundation::core;
namespace image = foundation::image;

export namespace foundation::gui
{
    namespace detail
    {
        [[nodiscard]] inline char8_t LowerAscii(char8_t c) noexcept { return c >= u8'A' && c <= u8'Z' ? static_cast<char8_t>(c + 32) : c; }
        [[nodiscard]] inline bool StartsWithNoCase(core::StringView s, core::StringView prefix) noexcept
        {
            if (s.Size() < prefix.Size())
                return false;
            for (usize i = 0; i < prefix.Size(); ++i)
                if (LowerAscii(s[i]) != LowerAscii(prefix[i]))
                    return false;
            return true;
        }
        [[nodiscard]] inline i32 HexValue(char8_t c) noexcept
        {
            if (c >= u8'0' && c <= u8'9')
                return c - u8'0';
            c = LowerAscii(c);
            return c >= u8'a' && c <= u8'f' ? c - u8'a' + 10 : -1;
        }
        [[nodiscard]] inline i32 Base64Value(char8_t c) noexcept
        {
            if (c >= u8'A' && c <= u8'Z')
                return c - u8'A';
            if (c >= u8'a' && c <= u8'z')
                return c - u8'a' + 26;
            if (c >= u8'0' && c <= u8'9')
                return c - u8'0' + 52;
            if (c == u8'+' || c == u8'-')
                return 62;
            if (c == u8'/' || c == u8'_')
                return 63;
            return -1;
        }
        // `%XX` escapes decoded; a `%` not followed by two hex digits is kept as it is.
        inline void DecodePercent(core::StringView in, core::String& out)
        {
            for (usize i = 0; i < in.Size(); ++i)
            {
                const i32 hi = in[i] == u8'%' && i + 2 < in.Size() ? HexValue(in[i + 1]) : -1;
                const i32 lo = hi >= 0 ? HexValue(in[i + 2]) : -1;
                if (lo >= 0)
                {
                    out.PushBack(static_cast<char8_t>(hi * 16 + lo));
                    i += 2;
                }
                else
                    out.PushBack(in[i]);
            }
        }
        // Base64 (either alphabet, white space and padding skipped); false on any other character.
        [[nodiscard]] inline bool DecodeBase64(core::StringView in, core::String& out)
        {
            u32 bits = 0;
            i32 count = 0;
            for (const char8_t c : in)
            {
                if (c == u8'=' || c == u8' ' || c == u8'\n' || c == u8'\r' || c == u8'\t')
                    continue;
                const i32 v = Base64Value(c);
                if (v < 0)
                    return false;
                bits = (bits << 6) | static_cast<u32>(v);
                count += 6;
                if (count >= 8)
                {
                    count -= 8;
                    out.PushBack(static_cast<char8_t>((bits >> count) & 0xFFu));
                }
            }
            return true;
        }
    }

    /// Whether `source` is an SVG written inline: a `data:image/svg+xml` URL.
    [[nodiscard]] inline bool IsSvgDataUrl(core::StringView source) noexcept
    {
        static constexpr core::StringView kPrefix(u8"data:image/svg+xml");
        return detail::StartsWithNoCase(source, kPrefix) && source.Size() > kPrefix.Size() &&
               (source[kPrefix.Size()] == u8',' || source[kPrefix.Size()] == u8';');
    }

    /// The SVG markup a `data:image/svg+xml[;param]*[;base64],payload` URL carries; false when
    /// `source` is not one or its payload does not decode.
    [[nodiscard]] inline bool DecodeSvgDataUrl(core::StringView source, core::String& out)
    {
        out.Clear();
        if (!IsSvgDataUrl(source))
            return false;
        usize comma = 0;
        while (comma < source.Size() && source[comma] != u8',')
            ++comma;
        if (comma == source.Size())
            return false;
        const core::StringView header = source.SubStr(0, comma);
        const core::StringView payload = source.SubStr(comma + 1, source.Size() - comma - 1);
        static constexpr core::StringView kBase64(u8";base64");
        const bool base64 = header.Size() >= kBase64.Size() &&
                            detail::StartsWithNoCase(header.SubStr(header.Size() - kBase64.Size(), kBase64.Size()), kBase64);
        if (!base64)
        {
            detail::DecodePercent(payload, out);
            return true;
        }
        core::String unescaped; // base64 may itself be percent-encoded (its '+', '/' and '=')
        detail::DecodePercent(payload, unescaped);
        return detail::DecodeBase64(unescaped.AsView(), out);
    }

    /// Whether a picture's source is an SVG: a path ending in .svg (either case), or one written
    /// inline (IsSvgDataUrl). Drawn as paths, not loaded as a raster.
    [[nodiscard]] inline bool IsSvgSource(core::StringView source) noexcept
    {
        if (IsSvgDataUrl(source))
            return true;
        if (source.Size() <= 4)
            return false;
        const core::StringView end = source.SubStr(source.Size() - 4, 4);
        return end == core::StringView(u8".svg") || end == core::StringView(u8".SVG");
    }

    class IResourceProvider
    {
    public:
        virtual ~IResourceProvider() = default;

        // Load image data for a path (background-image: url(path)). Returns a borrowed pointer
        // owned by the provider (valid until the provider releases it), or null if not found.
        [[nodiscard]] virtual const image::ImageData* LoadImage(core::StringView path) = 0;
        // A text file's contents (a sheet's @import, E13 of Specs/gui-lab-evolution-2.md): true and
        // `out` filled when it is there.
        [[nodiscard]] virtual bool LoadText(core::StringView path, core::String& out) = 0;
        // An SVG picture by its path (a CSS image whose path ends in .svg, E13): a borrowed
        // document the provider keeps (parsed once), drawn as paths at whatever size it fills;
        // null if not found. Callers ask Svg, which answers an inline one itself.
        [[nodiscard]] virtual const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView path) = 0;

        /// An SVG picture by its source: one written inline (a data: URL) parsed the first time
        /// and kept here, any other through LoadSvg. Borrowed; null when there is none (an inline
        /// one that does not parse is remembered as none).
        [[nodiscard]] const foundation::vg::svg::SVGDocument* Svg(core::StringView source)
        {
            if (!IsSvgDataUrl(source))
                return LoadSvg(source);
            for (const InlineSvg& known : m_inline)
                if (known.Source.AsView() == source)
                    return known.Document.Get();
            InlineSvg entry{core::String(source), {}};
            core::String markup;
            if (DecodeSvgDataUrl(source, markup))
                if (Result<foundation::vg::svg::SVGDocument> parsed = foundation::vg::svg::SVGLoader::Load(markup.AsView()); parsed.HasValue())
                    entry.Document = core::MakeUnique<foundation::vg::svg::SVGDocument>(*m_allocator, core::Move(parsed.Value()));
            m_inline.PushBack(core::Move(entry));
            return m_inline.Back().Document.Get();
        }

    protected:
        /// `allocator` holds the inline SVGs the provider keeps.
        explicit IResourceProvider(IAllocator& allocator) noexcept : m_allocator(&allocator), m_inline(allocator) {}

    private:
        struct InlineSvg
        {
            core::String Source;
            UniquePtr<foundation::vg::svg::SVGDocument> Document; // null: it did not parse
        };
        IAllocator* m_allocator;
        Array<InlineSvg> m_inline;
    };
}
