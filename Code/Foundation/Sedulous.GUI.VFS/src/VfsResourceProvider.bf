using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.VFS;

// An IResourceProvider backed by a VFS filesystem.
//
// The concrete image loader for the GUI's CSS resource seam: background-image: url(path) resolves
// through this. Kept in a SEPARATE library (like the GUI's shell bridge, and mirroring
// Sedulous.UI.VFS) so the core GUI stays free of a VFS dependency - the app links this and hands
// the provider to a StyleManager.
//
// The provider owns the decoded images, one per path, matching the IResourceProvider contract that
// LoadImage returns a borrowed, provider-owned image: a sheet restyled every frame asks again and
// gets the same image, not a new copy.

/// IResourceProvider that loads (and decodes) images from a VFS filesystem. The caller owns the
/// filesystem: this provider does not delete it.
class VfsResourceProvider : IResourceProvider
{
	private class Entry
	{
		public String Path = new .() ~ delete _;
		public OwnedImageData Image ~ delete _;
	}

	private class SvgEntry
	{
		public String Path = new .() ~ delete _;
		public SVGDocument Document ~ delete _;
	}

	private List<SvgEntry> mSvgs = new .() ~ DeleteContainerAndItems!(_); // parsed SVGs, one per path
	private IFileSystem mFs; // borrowed
	private List<Entry> mImages = new .() ~ DeleteContainerAndItems!(_); // decoded images owned by this provider, one per path

	public this(IFileSystem fs)
	{
		mFs = fs;
	}

	/// Load + decode image data at `path` the first time it is asked for. Returns a borrowed image
	/// owned by this provider (the same one for the same path), or null if the file is missing or
	/// fails to decode (asked again, it tries again: it may have arrived).
	public override ImageData LoadImage(StringView path)
	{
		if (mFs == null)
			return null;
		for (let e in mImages)
		{
			if (e.Path == path)
				return e.Image;
		}
		let stream = mFs.Open(path, .Read);
		if (stream == null)
			return null;
		defer delete stream;

		let length = stream.Size();
		if (length <= 0)
			return null;

		let buf = scope List<uint8>();
		buf.Resize((int)length);
		let read = stream.Read(Span<uint8>(buf.Ptr, buf.Count));

		let decoded = scope Sedulous.Image.Image();
		if (ImageIO.LoadImageFromMemory(Span<uint8>(buf.Ptr, Math.Max(read, 0)), decoded) case .Err)
			return null;

		let entry = new Entry();
		entry.Path.Set(path);
		entry.Image = new OwnedImageData(decoded.Width, decoded.Height, decoded.Format, decoded.PixelData);
		mImages.Add(entry);
		return entry.Image;
	}

	/// A text file read whole (a sheet's @import), appended to `outText`.
	public override bool LoadText(StringView path, String outText)
	{
		if (mFs == null)
			return false;
		let stream = mFs.Open(path, .Read);
		if (stream == null)
			return false;
		defer delete stream;
		let length = stream.Size();
		if (length < 0)
			return false;
		let buf = scope List<uint8>();
		buf.Resize((int)length);
		let read = (length > 0) ? stream.Read(Span<uint8>(buf.Ptr, buf.Count)) : 0;
		if (read > 0)
			outText.Append(StringView((char8*)buf.Ptr, read));
		return true;
	}

	/// An SVG parsed the first time it is asked for, kept (asked again after a failure, it tries
	/// again: it may have arrived).
	public override SVGDocument LoadSvg(StringView path)
	{
		for (let e in mSvgs)
		{
			if (e.Path == path)
				return e.Document;
		}
		let text = scope String();
		if (!LoadText(path, text))
			return null;
		SVGDocument parsed = null;
		if (SVGLoader.Load(text) case .Ok(let document))
			parsed = document;
		if (parsed == null)
			return null;
		let entry = new SvgEntry();
		entry.Path.Set(path);
		entry.Document = parsed;
		mSvgs.Add(entry);
		return entry.Document;
	}
}
