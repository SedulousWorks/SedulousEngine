using System;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Image: a picture in its content box, placed as CSS places a replaced element's: `object-fit`
// (fill, contain, cover, none, scale-down) sizes it, `object-position` places it (keywords,
// percentages or pixels, centred by default), and cover clips what overflows. Its picture is a
// Drawable from code or `src` from markup or a sheet, loaded through the GUI's resource provider
// when first needed. `image-color` tints it (RmlUi's name), for one that can be tinted. Sized by
// one axis alone, it keeps its picture's aspect ratio on the other, as an <img> does. (A
// nine-slice stays with backgrounds.)

/// How a picture fills its box (CSS's object-fit).
enum ObjectFit : uint8
{
	/// Stretched to the box, its aspect ignored.
	Fill,
	/// The largest that fits, aspect kept.
	Contain,
	/// The smallest that covers, aspect kept, clipped.
	Cover,
	/// Its natural size.
	None,
	/// None or contain, whichever is smaller.
	ScaleDown,
}

/// Where a picture sits in its box on one axis (CSS's object-position): a share of the room left
/// over, plus pixels.
struct ObjectPositionAxis : IEquatable<ObjectPositionAxis>
{
	public float Share = 0.5f;
	public float Pixels = 0.0f;

	public this() { }

	public this(float share, float pixels)
	{
		Share = share;
		Pixels = pixels;
	}

	public bool Equals(ObjectPositionAxis other) => this == other;

	[Commutable]
	public static bool operator==(ObjectPositionAxis a, ObjectPositionAxis b) => (a.Share == b.Share) && (a.Pixels == b.Pixels);
}

[GuiReflect(true)]
class Image : UIWidget
{
	private Sedulous.GUI.Drawable mDrawable = null ~ _?.ReleaseRef();
	private String mSource = new .() ~ delete _;
	private bool mSourceLoaded = true;
	private ObjectFit mFit = .Fill;
	private ObjectPositionAxis mPositionX = .();
	private ObjectPositionAxis mPositionY = .();
	private Color mImageColor = .White;
	// What ObjectPositionName last wrote.
	private String mPositionText = new .() ~ delete _;

	public this()
	{
		Tag = "image";
		AccessRoleName = "image"; // what a screen reader takes it for
	}

	/// Its picture from code (ending one from `src`). It takes a reference of its own; the caller
	/// keeps its.
	public void SetDrawable(Sedulous.GUI.Drawable drawable)
	{
		mSource.Clear();
		mSourceLoaded = true;
		if (drawable != null)
			drawable.AddRef();
		if (mDrawable != null)
			mDrawable.ReleaseRef();
		mDrawable = drawable;
		RequestLayout(); // its size follows its picture's
		Invalidate();
	}

	/// Borrowed.
	public Sedulous.GUI.Drawable Drawable => mDrawable;

	/// Its picture by path, loaded through the GUI's resource provider when first needed.
	[GuiProperty("src")]
	public StringView Source
	{
		get => mSource;
		set
		{
			if (value == mSource)
				return;
			mSource.Set(value);
			mSourceLoaded = false;
			if (mDrawable != null)
			{
				mDrawable.ReleaseRef();
				mDrawable = null;
			}
			RequestLayout();
			Invalidate();
		}
	}

	public ObjectFit Fit
	{
		get => mFit;
		set
		{
			mFit = value;
			Invalidate();
		}
	}

	/// CSS's keywords (markup's and a sheet's `object-fit`); one it does not know is fill.
	[GuiProperty("object-fit")]
	public StringView FitName
	{
		get => ImageDetail.sFitNames[(int)mFit];
		set
		{
			var fit = ObjectFit.Fill;
			let name = ParseUtil.Trim(value);
			for (int i = 0; i < 5; i++)
			{
				if (name == ImageDetail.sFitNames[i])
					fit = (ObjectFit)i;
			}
			Fit = fit;
		}
	}

	public void SetObjectPosition(ObjectPositionAxis x, ObjectPositionAxis y)
	{
		mPositionX = x;
		mPositionY = y;
		Invalidate();
	}

	public ObjectPositionAxis ObjectPositionX => mPositionX;
	public ObjectPositionAxis ObjectPositionY => mPositionY;

	/// CSS's object-position: one or two of left, center, right, top, bottom, a percentage or
	/// pixels ("right 8px" reads as right then pixels from the left). Read, shares as percentages,
	/// pixels added (`50% 0%`, `0% 8px`).
	[GuiProperty("object-position")]
	public StringView ObjectPositionName
	{
		get
		{
			mPositionText.Clear();
			ImageDetail.AppendAxis(mPositionX, mPositionText);
			mPositionText.Append(' ');
			ImageDetail.AppendAxis(mPositionY, mPositionText);
			return mPositionText;
		}
		set
		{
			var x = ObjectPositionAxis();
			var y = ObjectPositionAxis();
			bool haveX = false;
			bool haveY = false;
			var rest = ParseUtil.Trim(value);
			while (rest.Length != 0)
			{
				int end = 0;
				while ((end < rest.Length) && (rest[end] != ' '))
					++end;
				let word = rest.Substring(0, end);
				rest = ParseUtil.Trim(rest.Substring(end, rest.Length - end));
				var a = ObjectPositionAxis();
				bool vertical = false;
				bool either = false;
				if (word == "left")
					a.Share = 0.0f;
				else if (word == "right")
					a.Share = 1.0f;
				else if (word == "top")
				{
					a.Share = 0.0f;
					vertical = true;
				}
				else if (word == "bottom")
				{
					a.Share = 1.0f;
					vertical = true;
				}
				else if (word == "center")
					either = true;
				else if ((word.Length > 1) && (word[word.Length - 1] == '%'))
				{
					a.Share = ImageDetail.ParseNumber(word.Substring(0, word.Length - 1)) / 100.0f;
					either = true;
				}
				else
				{
					let digits = ((word.Length > 2) && (word.Substring(word.Length - 2, 2) == "px")) ? word.Substring(0, word.Length - 2) : word;
					a.Share = 0.0f;
					a.Pixels = ImageDetail.ParseNumber(digits);
					either = true;
				}
				// The first word along whichever axis it names, the second the other.
				if (vertical || (either && haveX && !haveY))
				{
					y = a;
					haveY = true;
				}
				else
				{
					x = a;
					haveX = true;
				}
			}
			SetObjectPosition(x, y);
		}
	}

	/// The picture multiplied by this (`image-color`); white leaves it as it is.
	[GuiProperty("image-color")]
	public Color ImageColor
	{
		get => mImageColor;
		set
		{
			mImageColor = value;
			Invalidate();
		}
	}

	/// Its picture's size, or with one axis given by its style, that axis and the other by the
	/// picture's aspect ratio.
	public override Float2 MeasureContent(Float2 available)
	{
		let natural = IntrinsicSize;
		if (!natural.HasValue || (natural.Value.X <= 0.0f) || (natural.Value.Y <= 0.0f))
			return .(0.0f, 0.0f);
		let n = natural.Value;
		let s = LayoutStyle;
		let fixedW = !s.Width.IsAuto && !IsUnbounded(available.X);
		let fixedH = !s.Height.IsAuto && !IsUnbounded(available.Y);
		if (fixedW && !fixedH)
			return .(available.X, available.X * n.Y / n.X);
		if (fixedH && !fixedW)
			return .(available.Y * n.X / n.Y, available.Y);
		return n;
	}

	/// Its picture's natural size (a read: the picture `src` names, once loaded); null with none.
	public Float2? IntrinsicSize
	{
		get
		{
			LoadSource();
			if (mDrawable == null)
				return null;
			return mDrawable.IntrinsicSize;
		}
	}

	/// Where the picture is drawn in its content box (it may pass the box's edges: cover, none).
	public Rect DrawnBounds
	{
		get
		{
			let area = ContentBounds;
			let intrinsic = IntrinsicSize;
			if ((mFit == .Fill) || !intrinsic.HasValue || (intrinsic.Value.X <= 0.0f) || (intrinsic.Value.Y <= 0.0f))
				return area;
			let nat = intrinsic.Value;
			let sx = area.Width / nat.X;
			let sy = area.Height / nat.Y;
			float scale = 1.0f;
			switch (mFit)
			{
			case .Contain: scale = Math.Min(sx, sy);
			case .Cover: scale = Math.Max(sx, sy);
			case .ScaleDown: scale = Math.Min(1.0f, Math.Min(sx, sy));
			default: break;
			}
			let size = Float2(nat.X * scale, nat.Y * scale);
			return .(area.X + (area.Width - size.X) * mPositionX.Share + mPositionX.Pixels,
				area.Y + (area.Height - size.Y) * mPositionY.Share + mPositionY.Pixels, size.X, size.Y);
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		LoadSource();
		if (mDrawable == null)
			return;
		let at = DrawnBounds;
		let area = ContentBounds;
		// What passes the box is clipped, as CSS clips a replaced element's content.
		let clip = (at.X < area.X) || (at.Y < area.Y) || (at.X + at.Width > area.X + area.Width) || (at.Y + at.Height > area.Y + area.Height);
		if (clip)
			ctx.PushClip(area);
		if (mImageColor == .White)
			mDrawable.Draw(ctx, at);
		else
			mDrawable.DrawTinted(ctx, at, mImageColor);
		if (clip)
			ctx.PopClip();
	}

	private void LoadSource()
	{
		if (mSourceLoaded || mSource.IsEmpty)
			return;
		let resources = ResourceProvider;
		if (resources == null)
			return; // not in a GUI with one yet: tried again when drawn or measured
		mSourceLoaded = true;
		if (mDrawable != null)
			mDrawable.ReleaseRef();
		mDrawable = PictureDrawable(resources, mSource); // an SVG drawn as paths
		RequestLayout();
	}
}

/// What Image.bf keeps out of the public surface.
internal static class ImageDetail
{
	/// By ObjectFit.
	public static String[5] sFitNames = .("fill", "contain", "cover", "none", "scale-down");

	public static float ParseNumber(StringView text) => (float)TextRunsDetail.ParseFloat(text).GetValueOrDefault(0.0);

	/// An axis as text: its pixels when it has some, else its share as a percentage.
	public static void AppendAxis(ObjectPositionAxis a, String outText)
	{
		if (a.Pixels != 0.0f)
		{
			a.Pixels.ToString(outText);
			outText.Append("px");
		}
		else
		{
			(a.Share * 100.0f).ToString(outText);
			outText.Append('%');
		}
	}
}
