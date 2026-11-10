using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// The picture the image pages show (Texture, Image, Heightfield, Fonts), where they had a fitted
// image and nothing more (no zoom, pan, channels, checkerboard or pixel readout). The picture sits
// on a checkerboard so alpha
// shows; the wheel zooms about the pointer, a drag (left or middle) pans, a double click fits it
// again. It fits the view until the user zooms or pans, and again whenever the picture's size
// changes. A channel (red, green, blue or alpha) shows on its own as grey, and the colour channels
// without alpha as opaque. The pixel under the pointer is told, its position and its RGBA8 value,
// so a page can say it.
//
// It holds its own copy of the pixels (RGBA8; another format shows its picture but no readout or
// channels), so a page reading its asset again just gives it the new one.

enum ImageChannel : uint8
{
	/// As it is, alpha over the checkerboard.
	case All;
	/// The colour channels, opaque.
	case Rgb;
	case Red;
	case Green;
	case Blue;
	case Alpha;
}

/// A pixel's RGBA8 value.
struct ImagePixel
{
	public uint8 R;
	public uint8 G;
	public uint8 B;
	public uint8 A;

	public this(uint8 r, uint8 g, uint8 b, uint8 a)
	{
		R = r;
		G = g;
		B = b;
		A = a;
	}
}

class ImageInspectView : UIWidget
{
	public const float cMinZoom = 1.0f / 64.0f;
	public const float cMaxZoom = 64.0f;
	/// A checkerboard square, in view pixels.
	private const float cCell = 10.0f;
	/// One wheel notch's zoom.
	private const float cWheelStep = 1.25f;

	/// Owned; null: no picture. Each picture a new object, never one written over: the renderer's
	/// texture cache keys on an image's identity, so a picture written into the last one's (a font
	/// rebaked, a channel picked) would draw the old texture.
	private Sedulous.Image.Image mPixels = null ~ delete _;
	/// mPixels as a channel shows it (not All); owned.
	private Sedulous.Image.Image mChannelPixels = null ~ delete _;
	private bool mChannelStale = true;
	private ImageChannel mChannel = .All;
	private float mZoom = 1.0f;
	private Float2 mOrigin = .Zero;
	/// The view's, at the last layout.
	private Float2 mSize = .Zero;
	private bool mFitting = true;
	private bool mPanning = false;
	private Float2 mPanFrom = .Zero;
	private Float2 mPanOrigin = .Zero;
	private int32 mHoverX = -1;
	private int32 mHoverY = -1;

	/// Told the pixel under the pointer as it moves (x < 0: none), and when the zoom changed.
	public delegate void(int32 x, int32 y) OnHover ~ delete _;
	public delegate void() OnZoomChanged ~ delete _;

	public this()
	{
		AddClass("image-inspect");
	}

	/// Shows `pixels` (taken: its own from now on); fitted again when its size differs from the
	/// last one's.
	public void SetImage(Sedulous.Image.Image pixels)
	{
		let resized = (mPixels == null) || (pixels.Width != mPixels.Width) || (pixels.Height != mPixels.Height);
		delete mPixels;
		mPixels = pixels;
		mChannelStale = true;
		if (resized)
			mFitting = true;
		if (mFitting)
			Fit();
		Invalidate();
	}

	/// Shows nothing (an asset with no picture yet).
	public void ClearImage()
	{
		DeleteAndNullify!(mPixels);
		DeleteAndNullify!(mChannelPixels);
		mChannelStale = true;
		mFitting = true;
		Invalidate();
	}

	public bool HasImage => (mPixels != null) && (mPixels.Width > 0) && (mPixels.Height > 0);
	public Sedulous.Image.Image Pixels => mPixels;

	public ImageChannel Channel => mChannel;

	public void SetChannel(ImageChannel channel)
	{
		if (channel == mChannel)
			return;
		mChannel = channel;
		mChannelStale = true;
		Invalidate();
	}

	/// The whole picture in the view, centred, as large as fits.
	public void Fit()
	{
		mFitting = true;
		if (!HasImage || (mSize.X <= 0.0f) || (mSize.Y <= 0.0f))
			return;
		let w = (float)mPixels.Width;
		let h = (float)mPixels.Height;
		mZoom = Math.Clamp(Math.Min(mSize.X / w, mSize.Y / h), cMinZoom, cMaxZoom);
		mOrigin = .(0.5f * (mSize.X - w * mZoom), 0.5f * (mSize.Y - h * mZoom));
		ZoomChanged();
	}

	/// One picture pixel to one view pixel, about the view's middle.
	public void ActualSize()
	{
		ZoomAbout(1.0f, .(0.5f * mSize.X, 0.5f * mSize.Y));
	}

	/// `zoom` (clamped), keeping the picture's point under `local` where it is.
	public void ZoomAbout(float zoom, Float2 local)
	{
		let clamped = Math.Clamp(zoom, cMinZoom, cMaxZoom);
		// The picture's point under `local` stays under it.
		let at = Float2((local.X - mOrigin.X) / mZoom, (local.Y - mOrigin.Y) / mZoom);
		mZoom = clamped;
		mOrigin = .(local.X - at.X * mZoom, local.Y - at.Y * mZoom);
		mFitting = false;
		ZoomChanged();
	}

	public float Zoom => mZoom;
	public bool Fitting => mFitting;
	/// Where the picture's top left corner is, in the view's space.
	public Float2 Origin => mOrigin;

	/// The picture's pixel at `local` (the view's space); false off the picture.
	public bool PixelAt(Float2 local, out int32 x, out int32 y)
	{
		x = -1;
		y = -1;
		if (!HasImage || (mZoom <= 0.0f))
			return false;
		let px = (local.X - mOrigin.X) / mZoom;
		let py = (local.Y - mOrigin.Y) / mZoom;
		if ((px < 0.0f) || (py < 0.0f) || (px >= (float)mPixels.Width) || (py >= (float)mPixels.Height))
			return false;
		x = (int32)px;
		y = (int32)py;
		return true;
	}

	/// Its RGBA8 value; false when there is none (off the picture, not RGBA8).
	public bool ValueAt(int32 x, int32 y, out ImagePixel outValue)
	{
		outValue = default;
		if (!HasImage || (mPixels.Format != .RGBA8) || (x < 0) || (y < 0) || ((uint32)x >= mPixels.Width) || ((uint32)y >= mPixels.Height))
			return false;
		let data = mPixels.PixelData;
		let at = ((int)y * (int)mPixels.Width + (int)x) * 4;
		if (at + 3 >= data.Length)
			return false;
		outValue = .(data[at], data[at + 1], data[at + 2], data[at + 3]);
		return true;
	}

	// === For tests: the gestures at points in its own space ===

	public void WheelAt(Float2 local, float steps)
	{
		ZoomAbout(mZoom * Math.Pow(cWheelStep, steps), local);
		Hover(local);
	}

	public void DragBy(Float2 from, Float2 to)
	{
		mOrigin = .(mOrigin.X + to.X - from.X, mOrigin.Y + to.Y - from.Y);
		mFitting = false;
		Invalidate();
	}

	public override Float2 MeasureContent(Float2 available) => .(64.0f, 64.0f);

	public override void OnLayout()
	{
		base.OnLayout();
		let size = Float2(Width, Height);
		if ((size.X != mSize.X) || (size.Y != mSize.Y))
		{
			// Resized: a fitted picture fits again; else it keeps its middle where it was.
			let shift = Float2(0.5f * (size.X - mSize.X), 0.5f * (size.Y - mSize.Y));
			mSize = size;
			if (mFitting)
				Fit();
			else
				mOrigin = .(mOrigin.X + shift.X, mOrigin.Y + shift.Y);
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let shown = Shown();
		if (shown == null)
			return;
		ctx.PushClip(localBounds);
		defer ctx.PopClip();
		let w = (float)mPixels.Width * mZoom;
		let h = (float)mPixels.Height * mZoom;
		let picture = Rect(localBounds.X + mOrigin.X, localBounds.Y + mOrigin.Y, w, h);
		// The checkerboard under it, where alpha can show through: the view's own background with
		// every other square in the text's colour, faint, so it follows the theme.
		if (mChannel == .All)
		{
			let left = Math.Max(picture.X, localBounds.X);
			let top = Math.Max(picture.Y, localBounds.Y);
			let right = Math.Min(picture.X + w, localBounds.X + localBounds.Width);
			let bottom = Math.Min(picture.Y + h, localBounds.Y + localBounds.Height);
			var ink = TextColor;
			ink.A *= 0.08f;
			let firstColumn = (int32)Math.Floor((left - picture.X) / cCell);
			let firstRow = (int32)Math.Floor((top - picture.Y) / cCell);
			for (int32 row = firstRow; picture.Y + (float)row * cCell < bottom; row++)
			{
				for (int32 column = firstColumn; picture.X + (float)column * cCell < right; column++)
				{
					if (((row + column) & 1) == 0)
						continue;
					let x0 = Math.Max(picture.X + (float)column * cCell, left);
					let y0 = Math.Max(picture.Y + (float)row * cCell, top);
					let x1 = Math.Min(picture.X + (float)(column + 1) * cCell, right);
					let y1 = Math.Min(picture.Y + (float)(row + 1) * cCell, bottom);
					ctx.VG.FillRect(.(x0, y0, x1 - x0, y1 - y0), ink);
				}
			}
		}
		ctx.VG.DrawImage(shown, picture.ToRectangle(), .(0.0f, 0.0f, (float)shown.Width, (float)shown.Height), .White);
	}

	public override Sedulous.GUI.Cursor CursorNow => mPanning ? .Grabbing : base.CursorNow;

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((e.Button != .Left) && (e.Button != .Middle))
			return;
		e.Handled = true;
		if ((e.Button == .Left) && (e.ClickCount == 2))
		{
			Fit();
			return;
		}
		mPanning = true;
		mPanFrom = ConvertToNodeSpace(e.Position);
		mPanOrigin = mOrigin;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let local = ConvertToNodeSpace(e.Position);
		if (mPanning)
		{
			mOrigin = .(mPanOrigin.X + local.X - mPanFrom.X, mPanOrigin.Y + local.Y - mPanFrom.Y);
			mFitting = false;
			Invalidate();
		}
		Hover(local);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mPanning && ((e.Button == .Left) || (e.Button == .Middle)))
		{
			mPanning = false;
			e.Handled = true;
		}
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		if ((mHoverX >= 0) && !mPanning)
		{
			mHoverX = -1;
			mHoverY = -1;
			if (OnHover != null)
				OnHover(-1, -1);
		}
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		let steps = (e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X;
		if ((steps == 0.0f) || !HasImage)
			return;
		e.Handled = true;
		WheelAt(ConvertToNodeSpace(e.Position), steps);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mPanning = false;
	}

	/// The picture as the channel shows it, made again when the channel or the pixels change.
	private ImageData Shown()
	{
		if (!HasImage)
			return null;
		if ((mChannel == .All) || (mPixels.Format != .RGBA8))
			return mPixels;
		if (mChannelStale)
		{
			delete mChannelPixels;
			mChannelPixels = new Sedulous.Image.Image(mPixels.Width, mPixels.Height, .RGBA8, mPixels.PixelData);
			let data = mChannelPixels.PixelData;
			for (int i = 0; i + 3 < data.Length; i += 4)
			{
				if (mChannel == .Rgb)
				{
					data[i + 3] = 255;
					continue;
				}
				let from = (mChannel == .Red) ? 0 : ((mChannel == .Green) ? 1 : ((mChannel == .Blue) ? 2 : 3));
				let value = data[i + from];
				data[i] = value;
				data[i + 1] = value;
				data[i + 2] = value;
				data[i + 3] = 255;
			}
			mChannelStale = false;
		}
		return mChannelPixels;
	}

	private void Hover(Float2 local)
	{
		int32 x;
		int32 y;
		if (!PixelAt(local, out x, out y))
		{
			x = -1;
			y = -1;
		}
		if ((x == mHoverX) && (y == mHoverY))
			return;
		mHoverX = x;
		mHoverY = y;
		if (OnHover != null)
			OnHover(x, y);
	}

	private void ZoomChanged()
	{
		Invalidate();
		if (OnZoomChanged != null)
			OnZoomChanged();
	}
}

/// The picture of an image page's markup, bound: the view in `image-stage`, Fit (`image-fit`), 1:1
/// (`image-actual`), the zoom (`image-zoom`), the channel (`image-channel`, in ImageChannel's
/// order), the pixel under the pointer (`image-readout`), and what shows when there is no picture
/// (`image-empty`, its words `image-empty-text`).
class ImagePreview
{
	/// One reference, this one's: its stage holds its own.
	private ImageInspectView mView ~ _.ReleaseRef();
	// The markup's: the tree holds them.
	private Node mStage = null;
	private Node mEmpty = null;
	private Sedulous.GUI.Label mEmptyText = null;
	private Sedulous.GUI.Label mZoom = null;
	private Sedulous.GUI.Label mReadout = null;
	private ComboBox mChannel = null;
	/// What the readout says of a pixel in place of its RGBA8 value; null: the value.
	private delegate void(int32 x, int32 y, String outText) mDescribe ~ delete _;

	/// The picture bound to `root`'s parts; `root` is borrowed.
	public this(Node root)
	{
		mView = new ImageInspectView();
		mStage = root.FindElement("image-stage");
		if (mStage != null)
			mStage.AddChild(mView);
		mEmpty = root.FindElement("image-empty");
		mEmptyText = root.FindElement("image-empty-text") as Sedulous.GUI.Label;
		mZoom = root.FindElement("image-zoom") as Sedulous.GUI.Label;
		mReadout = root.FindElement("image-readout") as Sedulous.GUI.Label;
		mChannel = root.FindElement("image-channel") as ComboBox;
		if (let fit = root.FindElement("image-fit") as ButtonBase)
			fit.SetOnClick(new [=this] () => { mView.Fit(); });
		if (let actual = root.FindElement("image-actual") as ButtonBase)
			actual.SetOnClick(new [=this] () => { mView.ActualSize(); });
		if (mChannel != null)
			mChannel.SetOnSelectionChanged(new [=this] (index) =>
				{
					if ((index >= 0) && (index <= (int32)ImageChannel.Alpha))
						mView.SetChannel((ImageChannel)index);
				});
		mView.OnZoomChanged = new [=this] () => { ShowZoom(); };
		mView.OnHover = new [=this] (x, y) => { ShowPixel(x, y); };
		ShowNone();
	}

	/// Shows `pixels` (taken).
	public void Show(Sedulous.Image.Image pixels)
	{
		mView.SetImage(pixels);
		if (mStage != null)
			mStage.Displayed = true;
		if (mEmpty != null)
			mEmpty.Displayed = false;
		ShowZoom();
	}

	/// Shows no picture, `why` in its place (empty: the markup's words).
	public void ShowNone(StringView why = default)
	{
		mView.ClearImage();
		if (mStage != null)
			mStage.Displayed = false;
		if (mEmpty != null)
			mEmpty.Displayed = true;
		if ((mEmptyText != null) && !why.IsEmpty)
			mEmptyText.Text = why;
		ShowPixel(-1, -1);
	}

	public ImageInspectView View => mView;

	/// What the readout says of pixel (x, y), in place of its RGBA8 value: a page whose picture
	/// stands for something else (a heightfield's heights) says that. Takes `describe`.
	public void SetDescribe(delegate void(int32 x, int32 y, String outText) describe)
	{
		delete mDescribe;
		mDescribe = describe;
	}

	public StringView ZoomText => (mZoom != null) ? mZoom.Text : default;
	public StringView Readout => (mReadout != null) ? mReadout.Text : default;

	/// A picture's pixel value as a readout says it, "x 12  y 40  ·  R 255 G 128 B 0 A 255",
	/// appended; nothing for x < 0.
	public static void DescribePixel(int32 x, int32 y, ImagePixel* value, String outText)
	{
		if ((x < 0) || (y < 0))
			return;
		if (value == null)
			outText.AppendF("x {}  y {}", x, y);
		else
			outText.AppendF("x {}  y {}  ·  R {} G {} B {} A {}", x, y, value.R, value.G, value.B, value.A);
	}

	private void ShowZoom()
	{
		if (mZoom != null)
			mZoom.Text = scope String()..AppendF("{}%", (int32)(mView.Zoom * 100.0f + 0.5f));
	}

	private void ShowPixel(int32 x, int32 y)
	{
		if (mReadout == null)
			return;
		let text = scope String();
		if (mDescribe != null)
		{
			if (x >= 0)
				mDescribe(x, y, text);
		}
		else
		{
			ImagePixel value = default;
			let known = mView.ValueAt(x, y, out value);
			DescribePixel(x, y, known ? &value : null, text);
		}
		mReadout.Text = text;
	}
}
