using System;

namespace Sedulous.UI;

/// A length.
///
/// Not a tagged value but a SUM of components: dp, px, pt, a percentage of a reference box,
/// and em of a font size. That is what makes `calc(100% - 20dp)` an ordinary value with two
/// components rather than an expression tree, and it means every unit resolves through one
/// function instead of a switch per consumer.
///
/// Dp, Px and Pt need only the DPI scale; Percent and Em additionally need a reference size
/// and a font size, which the full Resolve takes and the DPI-only Resolve treats as absent.
///
/// The component fields are lower case against the house style, which reserves PascalCase for
/// public fields: the static factories have to be Dp, Pt, Px, Percent and Em so a call site
/// reads `Unit.Dp(8)`, and an identifier cannot be both.
struct Unit
{
	/// Which component a single unit value was built from. Kept for display, and for callers
	/// that need to ask what unit a value is written in.
	public enum Kind
	{
		Dp,
		Pt,
		Px,
		Percent,
		Em
	}

	public Kind kind = .Dp;
	/// Density independent pixels: the LOGICAL layout unit, one dp being one device pixel at
	/// 96 dpi.
	public float dp = 0.0f;
	/// Points, a seventy second of an inch. Used for font sizes.
	public float pt = 0.0f;
	/// PHYSICAL device pixels, divided out of the root draw scale.
	public float px = 0.0f;
	/// Percent of the reference box on the same axis, a hundred being the whole box.
	public float percent = 0.0f;
	/// Multiples of the computed font size.
	public float em = 0.0f;

	public this() {}

	public static Unit Dp(float value)
	{
		Unit unit = .();
		unit.kind = .Dp;
		unit.dp = value;
		return unit;
	}

	public static Unit Pt(float value)
	{
		Unit unit = .();
		unit.kind = .Pt;
		unit.pt = value;
		return unit;
	}

	public static Unit Px(float value)
	{
		Unit unit = .();
		unit.kind = .Px;
		unit.px = value;
		return unit;
	}

	public static Unit Percent(float value)
	{
		Unit unit = .();
		unit.kind = .Percent;
		unit.percent = value;
		return unit;
	}

	public static Unit Em(float value)
	{
		Unit unit = .();
		unit.kind = .Em;
		unit.em = value;
		return unit;
	}

	[Commutable]
	public static bool operator==(Unit a, Unit b) =>
		(a.kind == b.kind) && (a.dp == b.dp) && (a.pt == b.pt) && (a.px == b.px)
		&& (a.percent == b.percent) && (a.em == b.em);

	/// calc(a + b), component wise. The kind stays the LEFT operand's, because that is the
	/// unit the author wrote the value in.
	public static Unit operator+(Unit a, Unit b)
	{
		var result = a;
		result.dp += b.dp;
		result.pt += b.pt;
		result.px += b.px;
		result.percent += b.percent;
		result.em += b.em;
		return result;
	}

	/// calc(a - b).
	public static Unit operator-(Unit a, Unit b)
	{
		var result = a;
		result.dp -= b.dp;
		result.pt -= b.pt;
		result.px -= b.px;
		result.percent -= b.percent;
		result.em -= b.em;
		return result;
	}

	/// Whether a Percent or Em component is present, meaning the value cannot resolve without
	/// a reference box or a font size. The DPI-only Resolve leaves those components out.
	public bool IsRelative => (percent != 0.0f) || (em != 0.0f);

	/// Resolves the ABSOLUTE components to LOGICAL units.
	///
	/// Layout runs entirely in logical space and the root applies the DPI scale ONCE at draw,
	/// so Dp is identity here: multiplying by the scale would scale twice, once now and again
	/// at draw. Px divides by the scale so that it lands on exact device pixels afterwards.
	public float Resolve(float dpiScale) =>
		dp + pt * (96.0f / 72.0f) + ((dpiScale > 0.0f) ? (px / dpiScale) : px);

	/// Resolves EVERY component. `referenceSize` is the containing box on this axis, in
	/// logical units and nought when unbounded; `fontSize` is the computed font size for em.
	public float Resolve(float dpiScale, float referenceSize, float fontSize) =>
		Resolve(dpiScale) + percent * 0.01f * referenceSize + em * fontSize;

	/// The dominant component's raw value, with no DPI conversion.
	public float RawValue
	{
		get
		{
			switch (kind)
			{
			case .Dp: return dp;
			case .Pt: return pt;
			case .Px: return px;
			case .Percent: return percent;
			case .Em: return em;
			}
		}
	}
}
