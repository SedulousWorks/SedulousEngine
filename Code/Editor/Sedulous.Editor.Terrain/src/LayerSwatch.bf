using Sedulous.Core;
using System;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// A palette layer's albedo thumbnail at a fixed size, the texture icon until the
/// thumbnail service has one.
class LayerSwatch : View
{
	/// Borrowed, app owned.
	private ThumbnailService mThumbs;
	private Guid mId;
	/// Borrowed, an EditorIcons icon.
	private Drawable mFallback;
	private float mSize;

	public this(ThumbnailService thumbs, Guid albedoId, Drawable fallback, float size)
	{
		mThumbs = thumbs;
		mId = albedoId;
		mFallback = fallback;
		mSize = size;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(mSize), constraints.ConstrainHeight(mSize));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let thumb = ((mThumbs != null) && !mId.IsNil) ? mThumbs.Get(mId) : null;
		let drawable = (thumb != null) ? thumb : mFallback;
		if (drawable != null)
			drawable.Draw(ctx, .(0, 0, Width, Height));
	}
}
