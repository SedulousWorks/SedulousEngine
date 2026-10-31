using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// One function of a sheet's `transform`. Translate moves by X and Y (lengths: dp, or a percent
/// of the view's own size); Scale scales by A and B; Rotate turns by A degrees (clockwise);
/// Skew slants by A and B degrees (CSS's skew(ax, ay)); Matrix is M (a, b, c, d, tx, ty), what
/// interpolating two lists of different functions gives.
enum TransformFunctionKind : uint8
{
	Translate,
	Scale,
	Rotate,
	Skew,
	Matrix
}

struct TransformFunction
{
	public TransformFunctionKind Kind = .Translate;
	public Unit X = .();
	public Unit Y = .();
	public float A = 0.0f;
	public float B = 0.0f;
	public float[6] M = .(1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);

	public this() {}

	/// The function that does nothing, of this one's kind (CSS pads `none` with them).
	public TransformFunction Identity
	{
		get
		{
			TransformFunction f = .();
			f.Kind = Kind;
			f.A = (Kind == .Scale) ? 1.0f : 0.0f;
			f.B = (Kind == .Scale) ? 1.0f : 0.0f;
			return f;
		}
	}

	[Commutable]
	public static bool operator==(TransformFunction l, TransformFunction r)
	{
		if ((l.Kind != r.Kind) || !(l.X == r.X) || !(l.Y == r.Y) || (l.A != r.A) || (l.B != r.B))
			return false;
		for (int i < 6)
		{
			if (l.M[i] != r.M[i])
				return false;
		}
		return true;
	}
}

/// A sheet's `transform`: its functions in written order, composed as CSS composes them (the
/// last written applies to the view first), about the view's `transform-origin`, and drawn over
/// the view's own Transform field. Empty is `none`.
///
/// It rides in a StyleValue BORROWED: the sheet that parsed it owns it, and a transition's or an
/// animation's in-between is owned by the view's StyleLerpScratch.
class TransformList : RefCounted
{
	/// The most functions a list holds; one written with more keeps its first ones.
	public const int cMaxFunctions = 8;

	private TransformFunction[cMaxFunctions] mFunctions = .();
	private int mCount = 0;

	public this() {}

	public int Count => mCount;
	public bool IsIdentity => mCount == 0;
	public TransformFunction this[int index]
	{
		get => mFunctions[index];
	}

	/// Appends a function; one past cMaxFunctions is dropped.
	public void Push(TransformFunction added)
	{
		if (mCount >= cMaxFunctions)
			return;
		mFunctions[mCount] = added;
		mCount++;
	}

	public void Clear() => mCount = 0;

	/// The functions as one matrix, for a view of `size` (a translate's percentages) at
	/// `dpiScale`. The origin is the caller's.
	public Transform2D Compose(Float2 size, float dpiScale)
	{
		var m = Transform2D();
		for (int i < mCount)
		{
			let f = mFunctions[i];
			switch (f.Kind)
			{
			case .Translate: m.Translate(f.X.Resolve(dpiScale, size.X, 0.0f), f.Y.Resolve(dpiScale, size.Y, 0.0f));
			case .Scale: m.Scale(f.A, f.B);
			case .Rotate: m.Rotate(f.A * (Math.PI_f / 180.0f));
			case .Skew: m.Skew(f.A * (Math.PI_f / 180.0f), f.B * (Math.PI_f / 180.0f));
			case .Matrix: m.Combine(.(f.M[0], f.M[1], f.M[2], f.M[3], f.M[4], f.M[5]));
			}
		}
		return m;
	}

	/// Whether `other` holds the same functions.
	public bool Same(TransformList other)
	{
		if (other.mCount != mCount)
			return false;
		for (int i < mCount)
		{
			if (mFunctions[i] != other.mFunctions[i])
				return false;
		}
		return true;
	}
}

/// A point as two lengths, x then y (CSS's transform-origin: dp, or a percent of the view).
///
/// Borrowed by the StyleValue carrying it, as a TransformList is.
class StylePoint : RefCounted
{
	public Unit X = Unit.Percent(50.0f);
	public Unit Y = Unit.Percent(50.0f);

	public this() {}

	public bool Same(StylePoint other) => (X == other.X) && (Y == other.Y);
}
