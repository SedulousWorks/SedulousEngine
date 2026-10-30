using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Texture;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Texture;

/// The texture page (Raptor's editor-gui spec, 5.4, layer 2), on the image pages' markup
/// (Data/Editor/ImagePage.gml): the source, or the embedded pixels, in the picture, beside the
/// asset's import settings; its presets in a menu on the bar, each one undo step however many
/// settings it moves; a usage edit sets the colour space with it, as one step, and a colour space
/// that disagrees with the usage is a notice over the rows. What it says of the source (its size,
/// its mip chain, what it cooks to) is read only. What every asset page does is AssetObjectPage's.
class TextureEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/ImagePage.gml";

	/// A preset: what its menu item says, and what it sets.
	public struct Preset
	{
		public String Label;
		public function void(TextureAsset asset) Setup;

		public this(String label, function void(TextureAsset asset) setup)
		{
			Label = label;
			Setup = setup;
		}
	}

	/// The presets, in their menu's order.
	public static Preset[7] sPresets = .(
		.("UI", (asset) => asset.SetupForUI()),
		.("Sprite", (asset) => asset.SetupForSprite()),
		.("3D Surface", (asset) => asset.SetupFor3D()),
		.("Normal Map", (asset) => asset.SetupForNormalMap()),
		.("Data Mask", (asset) => asset.SetupForDataMask()),
		.("Equirect Sky", (asset) => asset.SetupForEquirectangularSkybox()),
		.("Cubemap Sky", (asset) => asset.SetupForCubemapSkybox()));

	private ImagePreview mPreview = null ~ delete _;
	/// One reference, the page's: the bar holds its own.
	private ToolMenuButton mPresets = null ~ _?.ReleaseRef();
	/// The source's format, before the preview's conversion.
	private PixelFormat mSourceFormat = .RGBA8;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(TextureAsset), cMarkupPath)
	{
		if (Content != null)
		{
			mPreview = new ImagePreview(Content);
			AddPresets();
		}
		LoadPreview(instance);
		ShowFacts();
	}

	/// Applies the preset `label`, one undo step; false when there is none by that name.
	public bool ApplyPreset(StringView label)
	{
		for (let preset in sPresets)
		{
			if (preset.Label != label)
				continue;
			let setup = preset.Setup;
			EditWhole("texture_preset", scope [&] (object) => { setup((TextureAsset)object); });
			return true;
		}
		return false;
	}

	/// "Cooks to": the compression policy for desktop (and mobile when it differs) from the
	/// asset's usage, colour space and compression and the source's facts, appended.
	public void ResolvedFormatText(String outText)
	{
		let pixels = ((mPreview != null) && mPreview.View.HasImage) ? mPreview.View.Pixels : null;
		TextureAssetEdit.ResolvedFormatText(ObjectAs<TextureAsset>(), pixels, mSourceFormat, outText);
	}

	// === For tests ===

	public ImagePreview Preview => mPreview;
	public ToolMenuButton PresetButton => mPresets;

	/// Usage is the question; the colour space follows it (data is linear, colour sRGB), so the two
	/// change as one step. Colour Space stays its own row for the rare override.
	protected override bool FollowEdit(StringView path, ISerializable object)
	{
		if (path != "Usage")
			return false;
		let asset = (TextureAsset)object;
		asset.ColorSpace = TextureAssetEdit.ColorSpaceFor(asset.Usage);
		return true;
	}

	protected override void OnObjectChanged()
	{
		ShowFacts();
	}

	/// The presets' menu after the bar's own separator: the page's own controls follow Save, Undo
	/// and Redo.
	private void AddPresets()
	{
		let own = Find<Node>("page-own");
		let bar = (own != null) ? own.Parent : null;
		if ((bar == null) || LoadFailed)
			return;
		mPresets = new ToolMenuButton();
		mPresets.Id = "texture-presets";
		mPresets.Text = "Preset";
		mPresets.Tooltip = "Set what a kind of texture needs (usage, colour space, shape, filters, wraps, mips) in one step";
		for (let preset in sPresets)
		{
			let label = preset.Label;
			mPresets.Menu.AddItem(label, new [=this, =label] () => { ApplyPreset(label); });
		}
		bar.AddChildAt(mPresets, bar.GetChildIndex(own) + 1);
	}

	/// The embedded pixels when there is no source file, else the decoded source (the +X face
	/// stands in for a cubemap's).
	private void LoadPreview(Instance instance)
	{
		let asset = ObjectAs<TextureAsset>();
		if (asset == null)
			return;
		// Embedded (a model's import): the "pixels" stream, raw RGBA8 at EmbeddedWidth x Height.
		if (asset.FileName.IsEmpty && (asset.EmbeddedWidth > 0) && (asset.EmbeddedHeight > 0))
		{
			let expected = (int)asset.EmbeddedWidth * (int)asset.EmbeddedHeight * 4;
			let stream = instance.ReadData("pixels");
			defer delete stream;
			let pixels = new Sedulous.Image.Image(asset.EmbeddedWidth, asset.EmbeddedHeight, .RGBA8);
			if ((stream == null) || (stream.Size() < expected) || (stream.Read(Span<uint8>(pixels.PixelData.Ptr, expected)) != expected))
			{
				delete pixels;
				if (mPreview != null)
					mPreview.ShowNone("Its embedded pixels did not read.");
				return;
			}
			mSourceFormat = .RGBA8;
			if (mPreview != null)
				mPreview.Show(pixels);
			else
				delete pixels;
			return;
		}
		if (asset.FileName.IsEmpty || (Context.Project == null))
		{
			if (mPreview != null)
				mPreview.ShowNone("This texture names no source file.");
			return;
		}
		let path = PathJoin(Context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
		let source = scope Sedulous.Image.Image();
		Sedulous.Image.Image shown = null;
		if (ImageIO.LoadImage(path, source) case .Ok)
			shown = TexturePreview.From(source);
		if (shown == null)
		{
			GlobalLog(.Warning, "Editor: texture source missing or undecodable: {}", path);
			if (mPreview != null)
				mPreview.ShowNone(scope String()..AppendF("{} is missing or did not decode.", asset.FileName.Value));
			return;
		}
		mSourceFormat = source.Format;
		if (mPreview != null)
			mPreview.Show(shown);
		else
			delete shown;
	}

	private void ShowFacts()
	{
		let asset = ObjectAs<TextureAsset>();
		if (asset == null)
			return;
		// Data stored as sRGB warps its values; colour stored as linear is unusual.
		SetNotice("colorSpace", TextureAssetEdit.Lint(asset.Usage, asset.ColorSpace));
		if (asset.FileName.IsEmpty && (asset.EmbeddedWidth > 0))
			SetFact("Pixels", "Embedded in the asset (a model's import)");
		if (!asset.SourceHint.IsEmpty)
			SetFact("Imported From", asset.SourceHint);
		let pixels = ((mPreview != null) && mPreview.View.HasImage) ? mPreview.View.Pixels : null;
		if (pixels == null)
			return;
		SetFact("Size", scope String()..AppendF("{} x {}  ({})", pixels.Width, pixels.Height, (mSourceFormat == .RGBA32F) ? "HDR" : "LDR"));
		// The mip chain the cook makes: down to 1x1 when it makes one.
		let mips = asset.GenerateMipmaps ? TextureAssetEdit.MipLevels(pixels.Width, pixels.Height) : 1;
		SetFact("Mip Levels", scope String()..AppendF("{}", mips));
		SetFact("Cooks To", ResolvedFormatText(.. scope .()));
	}
}
