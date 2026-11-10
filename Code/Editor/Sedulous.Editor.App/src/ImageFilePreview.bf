using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Importer; // FileNameOf
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The import window's preview of a picture file: the image pages'
// ImagePreview over a bar of its own (Fit, 1:1, the zoom, the channels, the pixel under the
// pointer), with the facts the file's header gives: its size, its channels and depth as stored, and
// whether its alpha is used. It decodes the file as a task on the editor's pool, saying it is
// reading meanwhile. A domain whose importer makes an asset from a picture registers it for that
// asset type (ImageFilePreviewFactory.Register).

class ImageFilePreview : IImportPreview
{
	/// One reference, this one's.
	private Node mRoot ~ _.ReleaseRef();
	private ImagePreview mPicture ~ delete _;
	private List<String> mFacts = new .() ~ DeleteContainerAndItems!(_);
	private delegate void() mOnChanged ~ delete _;

	/// What the worker reads, for the main thread to show: nothing else touches it until it is back.
	private class Decoded : RefCounted
	{
		/// RGBA8, shown as is; Show takes it.
		public Sedulous.Image.Image Pixels = null ~ delete _;
		public List<String> Facts = new .() ~ DeleteContainerAndItems!(_);
		public bool Ok = false;
	}

	/// The read it started, cancelled as it goes: a reference of ours.
	private TaskHandle mRead = null;

	/// Shows that it is reading `path` and submits the read to `tasks` (borrowed: it outlives this);
	/// the picture and its facts show when it comes back, or why it did not decode.
	public this(StringView path, TaskPool tasks)
	{
		mRoot = BuildImageView();
		mPicture = new ImagePreview(mRoot);
		mPicture.ShowNone(scope $"Reading {ImportPaths.FileNameOf(path)}...");
		let decoded = new Decoded(); // the done's reference
		decoded.AddRef(); // the read's
		let file = new String(path);
		mRead = tasks.Submit(scope $"Reading {ImportPaths.FileNameOf(path)}",
			// On the worker: only the file and `decoded`.
			new [=file, =decoded] (context) =>
			{
				Decode(file, decoded);
				return Result<void, ErrorCode>.Ok; // Show says when it did not decode
			} ~ { delete file; decoded.ReleaseRef(); },
			// On the main thread, and only while this preview lives (it cancels its task as it goes).
			new [=this, =decoded] (status) => { Show(decoded); } ~ { decoded.ReleaseRef(); });
		mRead.AddRef(); // ours
	}

	public ~this()
	{
		if (mRead != null)
		{
			mRead.Cancel();
			mRead.ReleaseRef();
		}
	}

	/// On the worker: the picture at `file` into `decoded`, as RGBA8, and its facts.
	private static void Decode(StringView file, Decoded decoded)
	{
		var shown = new Sedulous.Image.Image();
		if (!(ImageIO.LoadImage(file, shown) case .Ok) || (shown.Width == 0) || (shown.Height == 0))
		{
			delete shown;
			return;
		}
		// The display is 8-bit: converted through the image library (floats clamp).
		if (shown.Format != .RGBA8)
		{
			let converted = shown.ConvertFormat(.RGBA8);
			delete shown;
			shown = converted;
		}
		decoded.Pixels = shown;
		let size = new String();
		size.AppendF("{} × {}", shown.Width, shown.Height);
		decoded.Facts.Add(size);
		if (ImageIO.ReadImageFileInfo(file, let info))
		{
			decoded.Facts.Add(ChannelsText(info, .. new .()));
			if ((info.Channels == 2) || (info.Channels == 4))
				decoded.Facts.Add(new String(UsesAlpha(shown) ? "Uses alpha" : "Alpha unused"));
		}
		decoded.Ok = true;
	}

	/// On the main thread: the read's result shown, or why there is none; the window told.
	private void Show(Decoded decoded)
	{
		if (!decoded.Ok)
			mPicture.ShowNone("This file did not decode as a picture.");
		else
		{
			mFacts.AddRange(decoded.Facts); // taken
			decoded.Facts.Clear();
			mPicture.Show(decoded.Pixels); // taken
			decoded.Pixels = null;
		}
		if (mOnChanged != null)
			mOnChanged();
	}

	public Node View => mRoot;
	public Span<String> Facts => mFacts;

	public void SetOnChanged(delegate void() onChanged)
	{
		delete mOnChanged;
		mOnChanged = onChanged;
	}

	// For tests.
	public ImagePreview Picture => mPicture;

	/// The channels as the file stores them, and their depth: "RGBA, 8-bit", appended.
	private static void ChannelsText(ImageFileInfo info, String outText)
	{
		StringView channels = "RGBA";
		switch (info.Channels)
		{
		case 1: channels = "Grey";
		case 2: channels = "Grey and alpha";
		case 3: channels = "RGB";
		default:
		}
		StringView depth = "8-bit";
		if (info.Hdr)
			depth = "HDR";
		else if (info.SixteenBit)
			depth = "16-bit";
		outText.AppendF("{}, {}", channels, depth);
	}

	/// Whether any pixel of an RGBA8 picture is less than opaque.
	private static bool UsesAlpha(Sedulous.Image.Image pixels)
	{
		let bytes = pixels.PixelData;
		for (int i = 3; i < bytes.Length; i += 4)
		{
			if (bytes[i] != 255)
				return true;
		}
		return false;
	}

	/// The picture's view: its bar (Fit, 1:1, the zoom, the channel, the pixel under the pointer) and
	/// the stage it shows in, with the ids an ImagePreview binds (as the image pages' markup has them),
	/// for a preview that shows a picture (a picture file's, a model's texture): a node with one
	/// reference, the caller's.
	public static Node BuildImageView()
	{
		let root = new Sedulous.GUI.Panel();
		root.AddClass("import-image");
		let bar = new Sedulous.GUI.Panel();
		bar.AddClasses("panel-toolbar image-bar");
		let fit = new ToolButton();
		fit.Id = "image-fit";
		fit.Icon = "Editor/Icons/maximize.svg";
		fit.Tooltip = "Fit the picture (double click)";
		let actual = new ToolButton();
		actual.Id = "image-actual";
		actual.Text = "1:1";
		actual.Tooltip = "One pixel to one pixel";
		let zoom = new Sedulous.GUI.Label();
		zoom.Id = "image-zoom";
		zoom.AddClasses("mono image-zoom");
		let channel = new ComboBox();
		channel.Id = "image-channel";
		channel.AddClass("image-channel");
		StringView[6] channels = .("RGBA", "RGB", "Red", "Green", "Blue", "Alpha"); // ImageChannel's order
		for (let item in channels)
			channel.AddItem(item);
		channel.SelectedIndex = 0;
		channel.Tooltip = "The channels shown";
		let readout = new Sedulous.GUI.Label();
		readout.Id = "image-readout";
		readout.AddClasses("mono image-readout");
		Add(bar, fit);
		Add(bar, actual);
		Add(bar, zoom);
		Add(bar, channel);
		Add(bar, new Spacer());
		Add(bar, readout);
		let stage = new Sedulous.GUI.Panel();
		stage.Id = "image-stage";
		stage.AddClass("image-stage");
		let empty = new Sedulous.GUI.Panel();
		empty.Id = "image-empty";
		empty.AddClasses("state-box image-empty");
		let why = new Sedulous.GUI.Label();
		why.Id = "image-empty-text";
		why.AddClass("state-text");
		Add(empty, why);
		Add(root, bar);
		Add(root, stage);
		Add(root, empty);
		return root;
	}

	/// `child` into `into`, whose reference keeps it: the caller's one goes.
	private static void Add(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}
}

/// Previews the picture files an importer lists by one asset type.
class ImageFilePreviewFactory : IImportPreviewFactory
{
	private Type mType;

	public this(Type type)
	{
		mType = type;
	}

	public Type AssetType => mType;
	public IImportPreview Create(ImportPreviewSource file, TaskPool tasks) => new ImageFilePreview(file.Path, tasks);

	/// Registers the picture preview for the files listed by `type`.
	public static void Register(EditorContext context, Type type)
	{
		context.ImportPreviews.Register(new ImageFilePreviewFactory(type));
	}
}
