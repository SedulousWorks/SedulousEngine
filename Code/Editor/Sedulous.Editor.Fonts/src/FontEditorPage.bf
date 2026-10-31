using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Fonts;

/// The font page (Raptor's editor-gui spec, 5.4, layer 2), on the image pages' markup
/// (Data/Editor/ImagePage.xml): the baked atlas in the picture, beside the asset's fields and, in a
/// section of its own, the raster ramp's sizes as one row of text ("12, 16, 24"), validated, one
/// undo step. What it says of the bake (its glyphs, its atlas) is read only. What every asset page
/// does is AssetObjectPage's.
///
/// The preview bake runs OFF the UI thread (a distance field over the whole codepoint range takes
/// long enough to hitch the editor), on the job service's light lane; the work fills a slot and the
/// completion, on the main thread, applies it. Latest wins: edits during a bake stash the newest
/// request, a stale outcome is dropped and the stash bakes. The old atlas stays on screen until its
/// replacement is ready. No job service (a test): it bakes in place.
class FontEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/ImagePage.xml";
	private const String cSizesPath = "sizes";

	private ImagePreview mPreview = null ~ delete _;
	/// The page's own rows: the sizes.
	private Sedulous.GUI.PropertyBag mRamp = new .() ~ delete _;
	private int mPreviewGlyphs = 0;
	private float mPreviewSize = 0.0f;
	private bool mBakeBusy = false;
	private uint64 mBakeGeneration = 0;
	/// The newest request stashed while a bake is in flight.
	private FontBakeRequest mPendingRequest = null ~ delete _;
	/// The in flight slot, borrowed: the completion closure owns and deletes it.
	private FontBakeSlot mActiveSlot = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(FontAsset), cMarkupPath)
	{
		if (Content != null)
			mPreview = new ImagePreview(Content);
		if (let asset = ObjectAs<FontAsset>())
		{
			let info = mRamp.Add(cSizesPath, .String, Sedulous.GUI.Variant(FontSizes.Format(asset.Sizes, .. scope .())));
			info.DisplayName.Set("Sizes");
			info.Description.Set("The pixel sizes a raster ramp bakes, one atlas each: \"12, 16, 24\"");
			mRamp.SetOnCommit(new [=this] (commit) =>
				{
					if (!commit.After.IsEmpty)
						SetSizes(commit.After[0].AsString);
				});
			AddSection("ramp", "Raster Ramp", mRamp);
			ShowRamp();
		}
		RebakePreview();
	}

	public ~this()
	{
		// The ramp goes before the base's sections: they let go of it first.
		ClearSections();
		if (mActiveSlot != null)
		{
			mActiveSlot.PageAlive = false; // the completion closure still owns and deletes it
			mActiveSlot = null;
		}
	}

	/// A font's source relinks to another font file of the project's (Browse on its row).
	public override void SourceExtensions(List<StringView> outExtensions)
	{
		outExtensions.Add(".ttf");
		outExtensions.Add(".otf");
		outExtensions.Add(".ttc");
	}

	/// Sets the raster ramp's sizes from text ("10, 12.5 24"), one undo step; false, with the row
	/// put back and a notice saying why, when it is not a list of sizes from 1 to 512.
	public bool SetSizes(StringView text)
	{
		let sizes = scope List<float>();
		if (!FontSizes.Parse(text, sizes))
		{
			SetNotice("sizes", "Sizes are numbers from 1 to 512, apart by commas or spaces: the row keeps what it had.");
			ShowRamp();
			return false;
		}
		SetNotice("sizes", "");
		EditWhole("font_sizes", scope [&] (object) =>
			{
				let asset = (FontAsset)object;
				asset.Sizes.Clear();
				asset.Sizes.AddRange(sizes);
			});
		return true;
	}

	// === For tests ===

	public ImagePreview Preview => mPreview;
	public Sedulous.GUI.PropertyBag Ramp => mRamp;
	public int PreviewGlyphs => mPreviewGlyphs;

	protected override void OnObjectChanged()
	{
		ShowRamp();
		RebakePreview();
	}

	/// The ramp's row as the asset has it, shown only for a raster ramp.
	private void ShowRamp()
	{
		let asset = ObjectAs<FontAsset>();
		if (asset == null)
			return;
		// A distance field bakes one size; the ramp is a raster's alone.
		let raster = asset.Mode == .RasterRamp;
		if (let info = mRamp.FindInfo(cSizesPath))
		{
			if (info.Visible != raster)
			{
				info.Visible = raster;
				mRamp.PropertiesChanged();
			}
		}
		let text = FontSizes.Format(asset.Sizes, .. scope .());
		var shown = mRamp.GetValue(cSizesPath, 0);
		defer shown.Dispose();
		if (shown.AsString != text)
			mRamp.SetValue(cSizesPath, 0, Sedulous.GUI.Variant(text));
	}

	/// The bake parameters from the asset, on the UI thread; the largest ramp size stands in for
	/// the ramp. The caller owns the request.
	private FontBakeRequest CaptureBakeRequest()
	{
		let request = new FontBakeRequest();
		let asset = ObjectAs<FontAsset>();
		if ((asset == null) || asset.FileName.IsEmpty || (Context.Project == null))
			return request;
		request.Valid = true;
		PathJoin(Context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, request.Path);
		request.DistanceField = asset.Mode == .DistanceField;
		request.Size = asset.DistanceFieldSize;
		request.DistanceFieldRange = asset.DistanceFieldRange;
		if (!request.DistanceField)
		{
			request.Size = 14.0f;
			for (let s in asset.Sizes)
				request.Size = Math.Max(request.Size, s);
		}
		request.FirstCodepoint = asset.FirstCodepoint;
		request.LastCodepoint = asset.LastCodepoint;
		request.AtlasWidth = asset.AtlasWidth;
		request.AtlasHeight = asset.AtlasHeight;
		if (request.DistanceField)
			DistanceFieldFonts.Initialize(); // idempotent; the registration happens on the UI thread
		return request;
	}

	/// Bakes now without a job service, else on a light job with the newest request winning.
	private void RebakePreview()
	{
		let request = CaptureBakeRequest();
		request.Generation = ++mBakeGeneration;
		let jobs = Context.Jobs;
		if (jobs == null)
		{
			let outcome = scope FontBakeOutcome();
			FontBake.Run(request, outcome);
			delete request;
			ApplyBakeOutcome(outcome);
			return;
		}
		if (mBakeBusy)
		{
			delete mPendingRequest;
			mPendingRequest = request; // latest wins; submitted when the flight lands
			return;
		}
		StartBake(request);
	}

	/// `request` is consumed.
	private void StartBake(FontBakeRequest request)
	{
		let jobs = Context.Jobs;
		let slot = new FontBakeSlot();
		delete slot.Request;
		slot.Request = request;
		mActiveSlot = slot;
		mBakeBusy = true;
		SetFact("Atlas", "Baking...");
		jobs.SubmitLight(new [=slot]() => { FontBake.Run(slot.Request, slot.Outcome); },
			new [=this, =slot]() =>
			{
				// The main thread. The page may have closed mid flight; the slot's flag is the
				// guard (set and read on the main thread only).
				if (slot.PageAlive)
				{
					mActiveSlot = null;
					mBakeBusy = false;
					ApplyBakeOutcome(slot.Outcome);
					if (mPendingRequest != null)
					{
						let next = mPendingRequest;
						mPendingRequest = null;
						StartBake(next);
					}
				}
				delete slot;
			});
	}

	/// Shows a bake's atlas, unless a newer request has since been made (a stale outcome never
	/// reaches the screen; the stash is already on its way).
	private void ApplyBakeOutcome(FontBakeOutcome outcome)
	{
		if (outcome.Generation != mBakeGeneration)
			return;
		mPreviewGlyphs = outcome.Glyphs;
		mPreviewSize = outcome.Size;
		let baked = outcome.Image;
		if ((baked == null) || (baked.Width == 0))
		{
			SetFact("Atlas", "Not baked");
			if (mPreview != null)
				mPreview.ShowNone("No atlas: the source file is missing or unreadable, or the atlas is too small for the range.");
			return;
		}
		SetFact("Glyphs", scope String()..AppendF("{} at {} px", mPreviewGlyphs, (int32)mPreviewSize));
		SetFact("Atlas", scope String()..AppendF("{} x {}", baked.Width, baked.Height));
		if (mPreview != null)
			mPreview.Show(new Sedulous.Image.Image(baked.Width, baked.Height, .RGBA8, baked.PixelData));
	}
}
