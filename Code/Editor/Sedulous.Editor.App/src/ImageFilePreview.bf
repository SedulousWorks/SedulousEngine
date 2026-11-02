using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Image.IO;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The import window's preview of a picture file (Raptor's import-window spec, W2): the image pages'
// ImagePreview over a bar of its own (Fit, 1:1, the zoom, the channels, the pixel under the
// pointer), with the facts the file's header gives: its size, its channels and depth as stored, and
// whether its alpha is used. A domain whose importer makes an asset from a picture registers it for
// that asset type (ImageFilePreviewFactory.Register).

class ImageFilePreview : IImportPreview
{
	/// One reference, this one's.
	private Node mRoot ~ _.ReleaseRef();
	private ImagePreview mPicture ~ delete _;
	private List<String> mFacts = new .() ~ DeleteContainerAndItems!(_);
	private delegate void() mOnChanged ~ delete _;

	/// Reads and shows the picture at `path`; a file that does not decode shows why, and no facts.
	public this(StringView path)
	{
		mRoot = BuildView();
		mPicture = new ImagePreview(mRoot);
		var shown = new Sedulous.Image.Image();
		if (!(ImageIO.LoadImage(path, shown) case .Ok) || (shown.Width == 0) || (shown.Height == 0))
		{
			delete shown;
			mPicture.ShowNone("This file did not decode as a picture.");
			return;
		}
		// The display is 8-bit: converted through the image library (floats clamp).
		if (shown.Format != .RGBA8)
		{
			let converted = shown.ConvertFormat(.RGBA8);
			delete shown;
			shown = converted;
		}
		let size = new String();
		size.AppendF("{} × {}", shown.Width, shown.Height);
		mFacts.Add(size);
		if (ImageIO.ReadImageFileInfo(path, let info))
		{
			mFacts.Add(ChannelsText(info, .. new .()));
			if ((info.Channels == 2) || (info.Channels == 4))
				mFacts.Add(new String(UsesAlpha(shown) ? "Uses alpha" : "Alpha unused"));
		}
		mPicture.Show(shown);
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

	/// The bar over the picture and the stage it shows in, with the ids ImagePreview binds (as the
	/// image pages' markup has them): a node with one reference, the caller's.
	private static Node BuildView()
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
	public IImportPreview Create(StringView path, ImportPreviewReader reader) => new ImageFilePreview(path);

	/// Registers the picture preview for the files listed by `type`.
	public static void Register(EditorContext context, Type type)
	{
		context.ImportPreviews.Register(new ImageFilePreviewFactory(type));
	}
}
