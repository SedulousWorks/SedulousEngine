using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Heightfield;

/// The heightfield page, on the image pages' markup
/// (Data/Editor/ImagePage.xml): the source heightmap in the picture, from its own lowest sample
/// (black) to its highest (white), so a low relief shows where the high byte alone was one flat
/// grey; the readout says the height under the pointer in metres. Beside it the asset's fields
/// (its Y range among them), and its source's size and range in metres, following an edit. What
/// every asset page does is AssetObjectPage's.
class HeightfieldEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/ImagePage.xml";

	private ImagePreview mPreview = null ~ delete _;
	/// The source's samples, row by row.
	private List<uint16> mSamples = new .() ~ delete _;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint16 mLow = 0;
	private uint16 mHigh = 0;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(HeightfieldAsset), cMarkupPath)
	{
		if (Content != null)
		{
			mPreview = new ImagePreview(Content);
			mPreview.SetDescribe(new [=this] (x, y, outText) =>
				{
					if (!SampleAt(x, y, let sample))
					{
						outText.AppendF("x {}  y {}", x, y);
						return;
					}
					outText.AppendF("x {}  y {}  ·  ", x, y);
					Metres(HeightOf(sample), outText);
					outText.AppendF("  ({})", sample);
				});
		}
		LoadPreview();
		ShowFacts();
	}

	/// The source's height sample at (x, y) (0..65535); false off it.
	public bool SampleAt(int32 x, int32 y, out uint16 outSample)
	{
		outSample = 0;
		if ((x < 0) || (y < 0) || ((uint32)x >= mWidth) || ((uint32)y >= mHeight))
			return false;
		outSample = mSamples[(int)y * (int)mWidth + (int)x];
		return true;
	}

	/// What a sample is in metres: the asset's Y range spread over the samples.
	public float HeightOf(uint16 sample)
	{
		let asset = ObjectAs<HeightfieldAsset>();
		if (asset == null)
			return 0.0f;
		return asset.MinY + (asset.MaxY - asset.MinY) * ((float)sample / 65535.0f);
	}

	/// "12.34 m", "-0.50 m": a height to the centimetre, appended.
	public static void Metres(float value, String outText)
	{
		let hundredths = (int64)Math.Round(Math.Abs(value) * 100.0f);
		let cents = hundredths % 100;
		outText.AppendF("{}{}.{}{} m", ((value < 0.0f) && (hundredths != 0)) ? "-" : "", hundredths / 100, cents / 10, cents % 10);
	}

	// === For tests ===

	public ImagePreview Preview => mPreview;

	protected override void OnObjectChanged()
	{
		ShowFacts();
	}

	/// Decodes the source heightmap (16-bit) and shows it, with its facts.
	private void LoadPreview()
	{
		let asset = ObjectAs<HeightfieldAsset>();
		if (asset == null)
			return;
		if (asset.FileName.IsEmpty || (Context.Project == null))
		{
			if (mPreview != null)
				mPreview.ShowNone("A blank heightfield: no source image, its heights flat until sculpted.");
			return;
		}
		let path = PathJoin(Context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
		let source = scope Sedulous.Image.Image();
		if (!(ImageIO.LoadImage16(path, source) case .Ok) || (source.Width == 0) || (source.Height == 0))
		{
			GlobalLog(.Warning, "Editor: heightfield source missing or undecodable: {}", path);
			if (mPreview != null)
				mPreview.ShowNone(scope String()..AppendF("{} is missing or did not decode.", asset.FileName.Value));
			return;
		}
		mWidth = source.Width;
		mHeight = source.Height;
		let count = (int)mWidth * (int)mHeight;
		let samples = (uint16*)source.PixelData.Ptr;
		mSamples.Clear();
		mLow = 65535;
		mHigh = 0;
		for (int i < count)
		{
			mSamples.Add(samples[i]);
			mLow = Math.Min(mLow, samples[i]);
			mHigh = Math.Max(mHigh, samples[i]);
		}
		// Its lowest to its highest as black to white: a low relief over a few hundred samples
		// shows, where the high byte alone was one flat grey.
		let span = (mHigh > mLow) ? (float)(mHigh - mLow) : 1.0f;
		let grey = new Sedulous.Image.Image(mWidth, mHeight, .RGBA8);
		let rgba = grey.PixelData;
		for (int i < count)
		{
			let g = (uint8)(255.0f * (float)(mSamples[i] - mLow) / span + 0.5f);
			rgba[i * 4 + 0] = g;
			rgba[i * 4 + 1] = g;
			rgba[i * 4 + 2] = g;
			rgba[i * 4 + 3] = 255;
		}
		if (mPreview != null)
			mPreview.Show(grey);
		else
			delete grey;
	}

	private void ShowFacts()
	{
		if ((ObjectAs<HeightfieldAsset>() == null) || (mWidth == 0))
			return;
		SetFact("Source Size", scope String()..AppendF("{} x {}", mWidth, mHeight));
		// The source's own range, in metres by the asset's Y range: what the black and the white are.
		SetFact("Lowest", Metres(HeightOf(mLow), .. scope .()));
		SetFact("Highest", Metres(HeightOf(mHigh), .. scope .()));
	}
}
