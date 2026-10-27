using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.VG.SVG;
using Sedulous.GUI; // IResourceProvider, Observable

namespace Sedulous.Editor.Core;

/// The editor's own files: its sheets, markup and
/// icons under Data/Editor and the fonts they name, given to the GUI as its resource provider,
/// and reloaded as they change on disk, the editor's development loop.
///
/// Text (a sheet, a page's markup) is read when it is asked for, so what reads it again reads
/// the file as it is now. Images and SVGs are kept once loaded, because the GUI borrows them;
/// one whose file changed is set aside (still alive for what draws it) and loaded afresh when
/// next asked for.
///
/// Poll sweeps the files for changes (the caller throttles it: a sweep is a walk of the
/// folder). A change is a change to TrackChanges' observable, so a sheet or a page that read
/// through it in a GUI Effect reloads itself; LastChanged says which files they were.
///
/// Not a VfsResourceProvider: that one keeps what it loaded for good, and a reload has to set
/// an image or an SVG aside by its path.
class EditorResources : IResourceProvider
{
	private class ImageEntry
	{
		public String Path = new .() ~ delete _;
		public OwnedImageData Pixels ~ delete _;
	}

	private class SvgEntry
	{
		public String Path = new .() ~ delete _;
		public SVGDocument Document ~ delete _;
	}

	private NativeFileSystem mFs ~ delete _;
	private List<ImageEntry> mImages = new .() ~ DeleteContainerAndItems!(_);
	private List<SvgEntry> mSvgs = new .() ~ DeleteContainerAndItems!(_);
	/// Replaced while the GUI may still borrow them: freed with the provider.
	private List<OwnedImageData> mSetAsideImages = new .() ~ DeleteContainerAndItems!(_);
	private List<SVGDocument> mSetAsideSvgs = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mLastChanged = new .() ~ DeleteContainerAndItems!(_);
	private Observable mChanged = new .() ~ delete _;

	/// Over the folder `root` (the one holding Editor/ and Assets/): paths are relative to it
	/// ("Editor/Icons/save.svg"). The whole folder is tracked for changes from here on.
	public this(StringView root)
	{
		mFs = new NativeFileSystem(root);
		mFs.ChangeSource.Track("");
	}

	// ---- IResourceProvider ----

	/// Loaded and decoded the first time it is asked for, then kept (the same one for the same
	/// path) until its file changes; null when it is missing or does not decode (asked again,
	/// it tries again: it may have arrived).
	public override ImageData LoadImage(StringView path)
	{
		for (let e in mImages)
		{
			if (e.Path == path)
				return e.Pixels;
		}
		let bytes = scope List<uint8>();
		if (!ReadBytes(path, bytes) || bytes.IsEmpty)
			return null;
		let decoded = scope Sedulous.Image.Image();
		if (ImageIO.LoadImageFromMemory(Span<uint8>(bytes.Ptr, bytes.Count), decoded) case .Err)
			return null;
		let entry = new ImageEntry();
		entry.Path.Set(path);
		entry.Pixels = new OwnedImageData(decoded.Width, decoded.Height, decoded.Format, decoded.PixelData);
		mImages.Add(entry);
		return entry.Pixels;
	}

	/// The file as it is now, appended to `outText`: never kept, so a sheet read again after an
	/// edit reads the edit.
	public override bool LoadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		if (!ReadBytes(path, bytes))
			return false;
		if (!bytes.IsEmpty)
			outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		return true;
	}

	/// Parsed the first time it is asked for, then kept until its file changes; null when it is
	/// missing or does not parse.
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

	/// Whether a file is there (an icon a type may or may not have).
	public bool Exists(StringView path) => mFs.Exists(path);

	// ---- Reload ----

	/// Sweeps the files for changes since the last sweep: true when any changed, and then the
	/// images and SVGs loaded from them are set aside, LastChanged names them, and what tracks
	/// the changes runs again.
	public bool Poll()
	{
		let changed = scope List<String>();
		defer { ClearAndDeleteItems(changed); }
		if (!mFs.ChangeSource.Poll(changed) || changed.IsEmpty)
			return false;
		for (let path in changed)
			Forget(path);
		ClearAndDeleteItems(mLastChanged);
		mLastChanged.AddRange(changed);
		changed.Clear(); // the strings are mLastChanged's now
		mChanged.Notify();
		return true;
	}

	/// Records a read of the files for the GUI's reactive evaluation in progress: a change found
	/// by Poll runs it again (a sheet reapplied, a page's markup loaded anew).
	public void TrackChanges() => mChanged.Track();

	/// The files the last change was to, relative to the root.
	public Span<String> LastChanged => mLastChanged;

	/// The whole file, or false when it cannot be opened.
	private bool ReadBytes(StringView path, List<uint8> outBytes)
	{
		let stream = mFs.Open(path, .Read);
		if (stream == null)
			return false;
		defer delete stream;
		let length = stream.Size();
		if (length < 0)
			return false;
		outBytes.Resize((int)length);
		let read = (length > 0) ? stream.Read(Span<uint8>(outBytes.Ptr, outBytes.Count)) : 0;
		outBytes.Resize(Math.Max(read, 0));
		return true;
	}

	/// What was loaded from `path` is set aside: alive for what still draws it, loaded afresh
	/// when next asked for.
	private void Forget(StringView path)
	{
		for (int i = mImages.Count - 1; i >= 0; i--)
		{
			let e = mImages[i];
			if (e.Path != path)
				continue;
			mSetAsideImages.Add(e.Pixels);
			e.Pixels = null;
			delete e;
			mImages.RemoveAt(i);
		}
		for (int i = mSvgs.Count - 1; i >= 0; i--)
		{
			let e = mSvgs[i];
			if (e.Path != path)
				continue;
			mSetAsideSvgs.Add(e.Document);
			e.Document = null;
			delete e;
			mSvgs.RemoveAt(i);
		}
	}
}
