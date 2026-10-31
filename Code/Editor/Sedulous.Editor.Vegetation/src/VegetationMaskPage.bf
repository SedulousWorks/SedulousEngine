using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Vegetation.Resource;
using Sedulous.Vegetation.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation;

/// A vegetation mask on the GUI from the image pages' markup (Data/Editor/ImagePage.xml; Raptor's
/// editor-gui spec, 5.4, layer 7, part 2), new: no editor had one, a mask opened on the generic page.
/// A mask is where each vegetation layer that places by Mask may grow, a density plane per layer; the
/// page shows one plane at a time (chosen on the picture's bar, in the channel's place: a plane is one
/// value, not colours), none to full as black to white, the pointer's density read out, beside the
/// mask's options on the grid, as the heightfield page shows its heights. Painting stays the scene
/// view's tool.
///
/// Its size and plane count, as the cook reads them: a painted mask's planes are kept at its size, so
/// once anything is painted its width and height are read only (a notice says why); its plane count
/// may change (the cook keeps the planes that still exist, a new one empty). An imported mask is
/// decoded from its image at its own size, a plane per channel (red, green, blue, alpha) up to its
/// plane count: its width and height are read only, its size a fact.
class VegetationMaskPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/ImagePage.xml";
	/// An imported mask's planes at most: its image's channels.
	public const uint32 cImageChannels = 4;

	private ImagePreview mPreview = null ~ delete _;
	private ComboBox mPlaneChoice = null ~ _?.ReleaseRef();
	/// Every plane, plane after plane, row by row.
	private List<uint8> mDensities = new .() ~ delete _;
	private int32 mWidth = 0;
	private int32 mHeight = 0;
	/// The planes read.
	private uint32 mPlaneCount = 0;
	private uint32 mPlane = 0;
	private bool mPainted = false;
	private bool mImported = false;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(VegetationMaskAsset), cMarkupPath)
	{
		ReadPlanes();
		// What the cook allows: a painted mask's size is its planes', an imported one's its image's.
		if (Properties != null)
		{
			Properties.SetOnDescribe(new [=this] (path, info) =>
				{
					let size = (path == "Width") || (path == "Height");
					if (size)
						info.ReadOnly = info.ReadOnly || mImported || mPainted;
					if (path == "PlaneCount")
					{
						info.HasRange = true;
						info.Min = 1.0;
						info.Max = (double)(mImported ? cImageChannels : VegetationMask.cMaxPlanes);
					}
				});
			Properties.Refresh(); // the grid listed the rows before the hook was set
		}
		if (Content != null)
		{
			mPreview = new ImagePreview(Content);
			mPreview.SetDescribe(new [=this] (x, y, outText) =>
				{
					if (!DensityAt(x, y, let density))
					{
						outText.AppendF("x {}  y {}", x, y);
						return;
					}
					outText.AppendF("x {}  y {}  ·  {}%", x, y, ((uint32)density * 100 + 127) / 255);
				});
			// The plane in the channel's place: a plane is one value, not colours.
			if (let channel = Find<Node>("image-channel"))
			{
				channel.Displayed = false;
				mPlaneChoice = new ComboBox();
				mPlaneChoice.Id = "mask-plane";
				mPlaneChoice.AddClass("image-channel");
				mPlaneChoice.Tooltip = "The density plane shown: one per vegetation layer that places by this mask";
				mPlaneChoice.SetOnSelectionChanged(new [=this] (index) => { ShowPlane((uint32)Math.Max(0, index)); });
				if (let bar = channel.Parent)
					bar.AddChildAt(mPlaneChoice, bar.GetChildIndex(channel) + 1);
			}
		}
		ShowChoices();
		ShowPlanePicture();
		ShowFacts();
	}

	/// Shows plane `plane` (from 0), as its choice on the picture's bar does.
	public void ShowPlane(uint32 plane)
	{
		mPlane = (mPlaneCount > 0) ? Math.Min(plane, mPlaneCount - 1) : 0;
		if ((mPlaneChoice != null) && (mPlaneChoice.SelectedIndex != (int32)mPlane))
			mPlaneChoice.SelectedIndex = (int32)mPlane;
		ShowPlanePicture();
		ShowFacts();
	}

	/// The density at (x, y) of the plane shown, 0 to 255; false off the mask or with nothing read.
	public bool DensityAt(int32 x, int32 y, out uint8 outDensity)
	{
		outDensity = 0;
		if ((x < 0) || (y < 0) || (x >= mWidth) || (y >= mHeight) || (mPlane >= mPlaneCount) || mDensities.IsEmpty)
			return false;
		let planeBytes = (int)mWidth * (int)mHeight;
		outDensity = mDensities[(int)mPlane * planeBytes + (int)y * (int)mWidth + (int)x];
		return true;
	}

	// === For tests ===

	public uint32 ShownPlane => mPlane;
	public uint32 PlaneCount => mPlaneCount;
	public bool Painted => mPainted;
	public bool Imported => mImported;
	public ComboBox PlaneChoice => mPlaneChoice;
	public ImagePreview Preview => mPreview;

	protected override void OnObjectChanged()
	{
		// A plane count changed (or its undo): the planes as the cook would now read them.
		let shown = mPlane;
		ReadPlanes();
		mPlane = (mPlaneCount > 0) ? Math.Min(shown, mPlaneCount - 1) : 0;
		ShowChoices();
		ShowPlanePicture();
		ShowFacts();
	}

	// The planes as the cook would read them: the painted stream, or the imported image.
	private void ReadPlanes()
	{
		mDensities.Clear();
		mWidth = 0;
		mHeight = 0;
		mPlaneCount = 0;
		mPainted = false;
		mImported = false;
		let asset = ObjectAs<VegetationMaskAsset>();
		if ((asset == null) || (Context.Project == null))
			return;
		let planes = (asset.PlaneCount == 0) ? 1 : asset.PlaneCount;
		if (!asset.FileName.IsEmpty)
		{
			// Imported: its image at its own size, a plane per channel up to its plane count, as the
			// cook decodes it.
			mImported = true;
			let path = PathJoin(Context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
			let source = scope Sedulous.Image.Image();
			if (!(ImageIO.LoadImage(path, source) case .Ok) || (source.Format != .RGBA8) || (source.Width == 0))
			{
				GlobalLog(.Warning, "Editor: vegetation mask source missing or not 8-bit RGBA: {}", path);
				return;
			}
			mWidth = (int32)source.Width;
			mHeight = (int32)source.Height;
			mPlaneCount = (uint32)Math.Clamp(planes, 1, cImageChannels);
			let texels = (int)mWidth * (int)mHeight;
			mDensities.Resize(texels * (int)mPlaneCount);
			let rgba = source.PixelData;
			for (uint32 plane < mPlaneCount)
			{
				for (int i < texels)
					mDensities[(int)plane * texels + i] = rgba[i * (int)cImageChannels + (int)plane];
			}
			mPainted = true;
			return;
		}
		// Painted: its stream, at the asset's size (absent: never painted, nothing grows yet).
		mWidth = Math.Max(asset.Width, 1);
		mHeight = Math.Max(asset.Height, 1);
		mPlaneCount = (uint32)Math.Clamp(planes, 1, VegetationMask.cMaxPlanes);
		let planeBytes = (int)mWidth * (int)mHeight;
		mDensities.Resize(planeBytes * (int)mPlaneCount);
		for (int i < mDensities.Count)
			mDensities[i] = 0;
		let instance = Context.Project.SourceDb.GetInstance(InstanceId);
		let stream = (instance != null) ? instance.ReadData(VegetationMaskSource.DensityStream) : null;
		if (stream == null)
			return;
		defer delete stream;
		let size = stream.Size();
		if ((size <= 0) || ((size % planeBytes) != 0))
			return;
		// The planes it has (the count may have changed since: the cook keeps those that remain).
		let painted = scope List<uint8>();
		painted.Resize((int)size);
		if (stream.Read(.(painted.Ptr, painted.Count)) != painted.Count)
			return;
		mPainted = true;
		Internal.MemCpy(mDensities.Ptr, painted.Ptr, Math.Min(painted.Count, mDensities.Count));
	}

	private void ShowPlanePicture()
	{
		if (mPreview == null)
			return;
		if (mImported && mDensities.IsEmpty)
		{
			let asset = ObjectAs<VegetationMaskAsset>();
			mPreview.ShowNone(scope String()..AppendF("{} is missing or is not an 8-bit RGBA image.", (asset != null) ? asset.FileName.Value : ""));
			return;
		}
		if (!mPainted)
		{
			mPreview.ShowNone("Nothing painted yet: the scene view's Paint Vegetation tool paints it, over a terrain whose vegetation uses it.");
			return;
		}
		// None to full as black to white.
		let planeBytes = (int)mWidth * (int)mHeight;
		let grey = new Sedulous.Image.Image((uint32)mWidth, (uint32)mHeight, .RGBA8);
		let rgba = grey.PixelData;
		let start = (int)mPlane * planeBytes;
		for (int i < planeBytes)
		{
			let d = mDensities[start + i];
			rgba[i * 4 + 0] = d;
			rgba[i * 4 + 1] = d;
			rgba[i * 4 + 2] = d;
			rgba[i * 4 + 3] = 255;
		}
		mPreview.Show(grey);
	}

	private void ShowChoices()
	{
		if (mPlaneChoice == null)
			return;
		let items = scope String();
		for (uint32 plane < Math.Max(mPlaneCount, 1))
		{
			if (!items.IsEmpty)
				items.Append('|');
			PlaneName(plane, mImported, items);
		}
		mPlaneChoice.ItemsText = items;
		mPlaneChoice.SelectedIndex = (int32)mPlane;
	}

	private void ShowFacts()
	{
		if (mImported)
			SetFact("Source Size", (mWidth > 0) ? scope String()..AppendF("{} x {}", mWidth, mHeight) : "Not read");
		SetFact("Painted", mPainted ? "Yes" : "Not yet");
		if (mPainted && (mPlane < mPlaneCount))
		{
			// How much of the plane shown lets anything grow.
			let planeBytes = (int)mWidth * (int)mHeight;
			let start = (int)mPlane * planeBytes;
			int covered = 0;
			for (int i < planeBytes)
				covered += (mDensities[start + i] != 0) ? 1 : 0;
			SetFact("Covered", scope String()..AppendF("{}%", (planeBytes > 0) ? (covered * 100 + planeBytes / 2) / planeBytes : 0));
		}
		else
			SetFact("Covered", "None");
		SetNotice("size", (mPainted && !mImported) ? "Its width and height are fixed once painted: its planes are kept at that size." : "");
	}

	// "Plane 1 (red)": an imported mask's planes are its image's channels.
	private static void PlaneName(uint32 plane, bool imported, String outText)
	{
		StringView[4] channels = .("red", "green", "blue", "alpha");
		if (imported && (plane < 4))
			outText.AppendF("Plane {} ({})", plane + 1, channels[plane]);
		else
			outText.AppendF("Plane {}", plane + 1);
	}
}

/// Opens a VegetationMaskAsset in its page; a page asks for its services when it is made.
class VegetationMaskPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(VegetationMaskAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new VegetationMaskPage(context, mServices.Make(), instance);
}
