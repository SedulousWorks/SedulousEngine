using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG.SVG;

namespace Sedulous.UI;

/// An SVGDrawable that PREFERS pre baked bitmap variants.
///
/// The crispness recipe: raster once at an integer size with the antialiasing baked into the
/// texels, then draw as a pixel snapped textured quad. Every instance then samples identical
/// texels, so there is no per instance subpixel shimmer as things move.
///
/// Falls back to the live vector render until a baker supplies variants, which covers headless
/// runs and tests and the window before the first bake, and again after ClearBakedVariants on
/// a DPI change until the re-bake lands.
class BakedSVGDrawable : SVGDrawable
{
	private List<BakedSVGVariant> mVariants = new .() ~ delete _;

	/// OWNERSHIP of the document transfers.
	public this(SVGDocument document) : base(document) {}

	/// Parses an SVG string. Null when it does not parse.
	public static new BakedSVGDrawable FromString(StringView svgContent)
	{
		if (SVGLoader.Load(svgContent) case .Ok(let document))
			return new BakedSVGDrawable(document);
		return null;
	}

	/// Replaces the variants. The atlases inside them are BORROWED.
	public void SetBakedVariants(Span<BakedSVGVariant> variants)
	{
		mVariants.Clear();
		for (let variant in variants)
			mVariants.Add(variant);
	}

	public void ClearBakedVariants() => mVariants.Clear();
	public bool HasBakedVariants => !mVariants.IsEmpty;

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (mVariants.IsEmpty)
		{
			// Live vector fallback.
			base.Draw(ctx, bounds);
			return;
		}

		// The nearest baked size to the DEVICE pixel extent. The bounds are logical and the
		// transform carries whatever DPI scale is in play, while bake sizes are device pixels,
		// so the scale has to come out of the transform rather than be assumed.
		let transform = ctx.VG.GetTransform();
		let scaleX = Length(Float2(transform[0, 0], transform[0, 1]));
		let scaleY = Length(Float2(transform[1, 0], transform[1, 1]));
		let scale = Max(0.0001f, Max(scaleX, scaleY));
		let wanted = Max(bounds.Width, bounds.Height) * scale;

		var best = mVariants[0];
		for (let variant in mVariants)
		{
			let bestDistance = Abs(best.SizePx - wanted);
			let distance = Abs(variant.SizePx - wanted);
			// A tie prefers the LARGER bake: downscaling only softens, where upscaling blurs.
			if ((distance < bestDistance)
				|| ((distance == bestDistance) && (variant.SizePx > best.SizePx)))
				best = variant;
		}

		ctx.VG.DrawImageSnapped(best.Atlas, bounds, best.SourceRect,
			(TintColor != null) ? TintColor.Value : Color.White);
	}
}
