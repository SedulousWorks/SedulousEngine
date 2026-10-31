using System;

namespace Sedulous.UI;

/// How a view is sized along ONE axis.
struct SizeSpec
{
	public enum Kind
	{
		Fixed,
		Match,
		Wrap
	}

	public Kind kind = .Wrap;
	public Unit fixedSize = .();

	/// Defaults to Wrap: a view with nothing said about it fits its content, which is the
	/// answer that cannot be wrong.
	public this() {}

	/// An explicit size, in any unit or a calc sum of them.
	public static SizeSpec Fixed(Unit size)
	{
		SizeSpec spec = .();
		spec.kind = .Fixed;
		spec.fixedSize = size;
		return spec;
	}

	/// Fill the parent's available space.
	public static SizeSpec Match()
	{
		SizeSpec spec = .();
		spec.kind = .Match;
		return spec;
	}

	/// Fit the view's own content.
	public static SizeSpec Wrap()
	{
		SizeSpec spec = .();
		spec.kind = .Wrap;
		return spec;
	}

	/// Fixed resolves its ABSOLUTE components; Match and Wrap are nought, because the parent
	/// decides those. Percent and em components need the three argument overload.
	public float ResolveFixed(float dpiScale) =>
		(kind == .Fixed) ? fixedSize.Resolve(dpiScale) : 0.0f;

	/// Fixed resolves EVERY component. `referenceSize` is the containing box on this axis,
	/// nought when unbounded; `fontSize` is the computed font size for em.
	public float ResolveFixed(float dpiScale, float referenceSize, float fontSize) =>
		(kind == .Fixed) ? fixedSize.Resolve(dpiScale, referenceSize, fontSize) : 0.0f;

	public bool IsFixed => kind == .Fixed;

	[Commutable]
	public static bool operator==(SizeSpec a, SizeSpec b) =>
		(a.kind == b.kind) && (a.fixedSize == b.fixedSize);
}
