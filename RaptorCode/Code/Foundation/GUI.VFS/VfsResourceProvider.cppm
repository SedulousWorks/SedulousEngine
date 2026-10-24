// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - `foundation.gui.vfs`: an IResourceProvider backed by a VFS filesystem.
//
// The concrete image loader for the GUI's CSS resource seam: background-image: url(path) resolves
// through this. Kept in a SEPARATE module (like foundation.gui.shell, and mirroring
// foundation.ui.vfs) so the core foundation.gui stays free of a VFS dependency - the app links this
// and hands the provider to a StyleManager. Modeled on foundation.ui.vfs::VfsResourceProvider.
//
// The provider owns the decoded images, one per path, matching the IResourceProvider contract that
// LoadImage returns a borrowed, provider-owned pointer: a sheet restyled every frame asks again
// and gets the same image, not a new copy.

module;
#include "Core/Prelude.h"

export module foundation.gui.vfs;

import foundation.core;     // IStream, FileMode, SeekOrigin, Array, Span, UniquePtr, MakeUnique
import foundation.image;    // ImageData, Image, OwnedImageData
import foundation.image.io; // LoadImageFromMemory
import foundation.vfs;      // IFileSystem
import foundation.gui;      // IResourceProvider
import foundation.vg.svg;     // SVGDocument, SVGLoader

using namespace foundation::core;
namespace core = foundation::core;
namespace image = foundation::image;

export namespace foundation::gui::vfs
{
    // IResourceProvider that loads (and decodes) images from a VFS filesystem. The caller owns
    // the filesystem: this provider does not delete it. Images come from the owner's allocator.
    class VfsResourceProvider final : public foundation::gui::IResourceProvider
    {
    public:
        VfsResourceProvider(foundation::vfs::IFileSystem* fs, IAllocator& allocator) noexcept
            : IResourceProvider(allocator), m_fs(fs), m_allocator(allocator), m_images(allocator)
        {
        }

        // Load + decode image data at `path` the first time it is asked for. Returns a borrowed
        // pointer owned by this provider (the same one for the same path), or null if the file is
        // missing or fails to decode (asked again, it tries again: it may have arrived).
        const image::ImageData* LoadImage(core::StringView path) override
        {
            if (m_fs == nullptr)
                return nullptr;
            for (const Entry& e : m_images)
                if (e.Path.AsView() == path)
                    return e.Image.Get();
            UniquePtr<IStream> stream = m_fs->Open(path, FileMode::Read);
            if (!stream)
                return nullptr;

            const i64 length = stream->Size();
            if (length <= 0)
                return nullptr;

            Array<u8> buf;
            buf.Resize(static_cast<usize>(length));
            const u64 read = stream->Read(buf.Data(), static_cast<u64>(length));

            image::Image decoded;
            if (!image::io::LoadImageFromMemory(
                     Span<const u8>(buf.Data(), static_cast<usize>(read)), decoded)
                     .IsOk())
                return nullptr;

            UniquePtr<image::OwnedImageData> owned =
                MakeUnique<image::OwnedImageData>(m_allocator, decoded.Width(), decoded.Height(), decoded.Format(), decoded.PixelData());
            image::OwnedImageData* raw = owned.Get();
            m_images.PushBack(Entry{core::String(path), Move(owned)});
            return raw;
        }

        // A text file read whole (a sheet's @import).
        bool LoadText(core::StringView path, core::String& out) override
        {
            if (m_fs == nullptr)
                return false;
            UniquePtr<IStream> stream = m_fs->Open(path, FileMode::Read);
            if (!stream)
                return false;
            const i64 length = stream->Size();
            if (length < 0)
                return false;
            Array<u8> buf;
            buf.Resize(static_cast<usize>(length));
            const u64 read = stream->Read(buf.Data(), static_cast<u64>(length));
            out = core::String(core::StringView(reinterpret_cast<const char8_t*>(buf.Data()), static_cast<usize>(read)));
            return true;
        }

        // An SVG parsed the first time it is asked for, kept (asked again after a failure, it tries
        // again: it may have arrived).
        const foundation::vg::svg::SVGDocument* LoadSvg(core::StringView path) override
        {
            for (const SvgEntry& e : m_svgs)
                if (e.Path.AsView() == path)
                    return e.Document.Get();
            core::String text;
            if (!LoadText(path, text))
                return nullptr;
            Result<foundation::vg::svg::SVGDocument> parsed = foundation::vg::svg::SVGLoader::Load(text.AsView());
            if (!parsed.HasValue())
                return nullptr;
            m_svgs.PushBack(SvgEntry{core::String(path), MakeUnique<foundation::vg::svg::SVGDocument>(m_allocator, Move(parsed.Value()))});
            return m_svgs[m_svgs.Size() - 1].Document.Get();
        }

    private:
        struct Entry
        {
            core::String Path;
            UniquePtr<image::OwnedImageData> Image;
        };
        struct SvgEntry
        {
            core::String Path;
            UniquePtr<foundation::vg::svg::SVGDocument> Document;
        };
        Array<SvgEntry> m_svgs; // parsed SVGs, one per path
        foundation::vfs::IFileSystem* m_fs;
        IAllocator& m_allocator;
        Array<Entry> m_images; // decoded images owned by this provider, one per path
    };
}
