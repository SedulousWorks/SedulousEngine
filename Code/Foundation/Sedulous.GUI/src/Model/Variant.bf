using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// Variant: a small tagged value a Model hands to a view for a cell - the currency of the MVC
// layer. Modeled on eepp's Models::Variant (role only, common subset): empty / bool / int /
// float / string / color, and Core's curve keys and colour gradient (what a property grid's
// curve and gradient rows carry, one value each, as a colour is). Stored as a plain struct (no
// union) for simplicity and safety; ToString renders it for display (a colour as #RRGGBBAA, a
// curve as its count of keys) and Compare orders it for sorting (a colour channel by channel, a
// curve and a gradient field by field, so differing values never compare equal).

/// A colour gradient as one value: Core's colour stops and alpha stops, sorted by time, and the
/// space they blend in (Core's gradient, no model of the GUI's own). A class, so a Variant can
/// borrow one; Set copies another into it.
class ColorGradient : IEquatable<ColorGradient>
{
	public List<GradientColorStop> Colors = new .() ~ delete _;
	public List<GradientAlphaStop> Alphas = new .() ~ delete _;
	public GradientInterpolation Interpolation = .Srgb;

	public Color Evaluate(float time) => EvaluateGradient(Colors, Alphas, Interpolation, time);

	/// Makes this a copy of `other` (its stops and its interpolation).
	public void Set(ColorGradient other)
	{
		if (other === this)
			return;
		Colors.Clear();
		Colors.AddRange(other.Colors);
		Alphas.Clear();
		Alphas.AddRange(other.Alphas);
		Interpolation = other.Interpolation;
	}

	/// Whether the two hold the same stops in the same order, blended the same way.
	public bool Equals(ColorGradient other)
	{
		if ((Interpolation != other.Interpolation) || (Colors.Count != other.Colors.Count) || (Alphas.Count != other.Alphas.Count))
			return false;
		for (int i = 0; i < Colors.Count; i++)
		{
			if ((Colors[i].Time != other.Colors[i].Time) || !(Colors[i].Color == other.Colors[i].Color))
				return false;
		}
		for (int i = 0; i < Alphas.Count; i++)
		{
			if ((Alphas[i].Time != other.Alphas[i].Time) || (Alphas[i].Alpha != other.Alphas[i].Alpha))
				return false;
		}
		return true;
	}
}

/// A cell's value. Its text, curve keys and gradient are either BORROWED or OWNED:
/// - Built from text, keys or a gradient, it is a view of them: the caller keeps them alive while
///   the Variant is used, and nothing is allocated.
/// - Copy() makes one that owns its own copy of them; Dispose frees what it owns. Dispose on a
///   view does nothing, so disposing any Variant is safe.
/// - An owned Variant is not copied by assignment (the copy would share what it owns): it hands
///   out View(), which owns nothing.
/// A model keeps owned copies of what it is given (the caller keeps what it passed) and hands out
/// views: what Data returns is valid until the model changes, never disposed by the caller, and
/// copied (Copy) by one that keeps it longer. A model that makes its values as it is asked keeps
/// them until it changes, as it keeps its stored ones.
struct Variant : IDisposable
{
	public enum Type
	{
		Empty,
		Bool,
		Int,
		Float,
		String,
		Color,
		/// Core's curve keys, sorted by time
		Curve,
		/// a ColorGradient
		Gradient
	}

	private static ColorGradient sEmptyGradient = new .() ~ delete _;

	private Type mType = .Empty;
	private bool mBool = false;
	private int64 mInt = 0;
	private double mFloat = 0.0;
	private Color mColor = .();
	/// The text: the owned String's, or the caller's.
	private StringView mText = default;
	/// The curve's keys: the owned list's, or the caller's.
	private Span<CurveKey> mKeys = default;
	/// The gradient: the owned one, or the caller's.
	private ColorGradient mGradient = null;
	/// What this one owns (a String, a List<CurveKey> or a ColorGradient); null for a view.
	private Object mOwned = null;

	public this() { }
	public this(bool value) { mType = .Bool; mBool = value; }
	public this(int64 value) { mType = .Int; mInt = value; }
	public this(int32 value) { mType = .Int; mInt = value; }
	public this(double value) { mType = .Float; mFloat = value; }
	/// A view of `value`.
	public this(StringView value) { mType = .String; mText = value; }
	public this(Color value) { mType = .Color; mColor = value; }
	/// A view of `value`.
	public this(ColorGradient value) { mType = .Gradient; mGradient = value; }

	/// A curve's keys, a view of them (a constructor of its own: a span of keys is no other value).
	public static Sedulous.GUI.Variant FromCurve(Span<CurveKey> keys)
	{
		Sedulous.GUI.Variant result = .();
		result.mType = .Curve;
		result.mKeys = keys;
		return result;
	}

	public Type Kind => mType;
	public bool IsEmpty => mType == .Empty;
	/// Whether it owns its text, keys or gradient (Copy made it).
	public bool IsOwner => mOwned != null;

	public bool AsBool => (mType == .Bool) ? mBool : ((mType == .Int) ? (mInt != 0) : false);
	public int64 AsInt => (mType == .Int) ? mInt : ((mType == .Float) ? (int64)mFloat : 0);
	public double AsFloat => (mType == .Float) ? mFloat : ((mType == .Int) ? (double)mInt : 0.0);
	/// Its text; empty for another type.
	public StringView AsString => (mType == .String) ? mText : default;
	public Color AsColor => mColor;
	/// A curve's keys; none for another type.
	public Span<CurveKey> AsCurve => (mType == .Curve) ? mKeys : default;
	/// A gradient; an empty one for another type (shared: not to be changed).
	public ColorGradient AsGradient => ((mType == .Gradient) && (mGradient != null)) ? mGradient : sEmptyGradient;

	/// The same value, owning nothing: valid while this one (or what it borrows) is.
	public Sedulous.GUI.Variant View()
	{
		var result = this;
		result.mOwned = null;
		return result;
	}

	/// A copy that owns its own text, keys or gradient; the caller disposes it.
	public Sedulous.GUI.Variant Copy()
	{
		var result = this;
		result.mOwned = null;
		switch (mType)
		{
		case .String:
			let text = new String(mText);
			result.mText = text;
			result.mOwned = text;
		case .Curve:
			let keys = new List<CurveKey>(mKeys);
			result.mKeys = keys;
			result.mOwned = keys;
		case .Gradient:
			let gradient = new ColorGradient();
			if (mGradient != null)
				gradient.Set(mGradient);
			result.mGradient = gradient;
			result.mOwned = gradient;
		default:
		}
		return result;
	}

	/// Frees what it owns, leaving it empty; a view's does nothing.
	public void Dispose() mut
	{
		if (mOwned == null)
			return;
		delete mOwned;
		this = .();
	}

	/// Appends a display string for any type (numbers rendered simply; text as it is).
	public override void ToString(String strBuffer)
	{
		switch (mType)
		{
		case .Empty:
			return;
		case .Bool:
			strBuffer.Append(mBool ? "true" : "false");
		case .Int:
			mInt.ToString(strBuffer);
		case .Float:
			AppendFloat(mFloat, strBuffer);
		case .String:
			strBuffer.Append(mText);
		case .Color:
			// #RRGGBBAA, as a hex code writes it.
			let packed = mColor.ToRGBA8();
			let hex = "0123456789ABCDEF";
			strBuffer.Append('#');
			for (int32 i = 0; i < 8; i++)
			{
				let nibble = (packed >> ((7 - i) * 4)) & 0xF;
				strBuffer.Append(hex[(int)nibble]);
			}
		case .Curve:
			strBuffer.AppendF("{} keys", mKeys.Length);
		case .Gradient:
			let gradient = AsGradient;
			strBuffer.AppendF("{} colours, {} alphas", gradient.Colors.Count, gradient.Alphas.Count);
		}
	}

	// Order two variants: numbers by value (an int against a float too, so a column mixing
	// them sorts as numbers), strings lexicographically, bools false<true. Other mixed and
	// empty types compare by their Type ordinal (a stable, if arbitrary, total order).
	public int32 Compare(Sedulous.GUI.Variant other)
	{
		let numbers = ((mType == .Int) || (mType == .Float)) && ((other.mType == .Int) || (other.mType == .Float));
		if (numbers && (mType != other.mType))
		{
			let a = (mType == .Int) ? (double)mInt : mFloat;
			let b = (other.mType == .Int) ? (double)other.mInt : other.mFloat;
			return (a == b) ? 0 : ((a < b) ? -1 : 1);
		}
		if (mType != other.mType)
			return ((int32)mType < (int32)other.mType) ? -1 : 1;
		switch (mType)
		{
		case .Empty:
			return 0;
		case .Bool:
			return (mBool == other.mBool) ? 0 : (!mBool ? -1 : 1);
		case .Int:
			return (mInt == other.mInt) ? 0 : ((mInt < other.mInt) ? -1 : 1);
		case .Float:
			return (mFloat == other.mFloat) ? 0 : ((mFloat < other.mFloat) ? -1 : 1);
		case .String:
			return CompareStrings(mText, other.mText);
		case .Color:
			// Channel by channel, so two colours are equal only when they are the same.
			float[4] mine = .(mColor.R, mColor.G, mColor.B, mColor.A);
			float[4] theirs = .(other.mColor.R, other.mColor.G, other.mColor.B, other.mColor.A);
			return CompareFloats(mine, theirs);
		case .Curve:
			// Its count, then key by key, field by field.
			if (mKeys.Length != other.mKeys.Length)
				return (mKeys.Length < other.mKeys.Length) ? -1 : 1;
			for (int k = 0; k < mKeys.Length; k++)
			{
				let p = mKeys[k];
				let q = other.mKeys[k];
				float[6] keyA = .(p.Time, p.Value, p.TangentIn, p.TangentOut, (float)(int32)p.Interpolation, (float)(int32)p.TangentMode);
				float[6] keyB = .(q.Time, q.Value, q.TangentIn, q.TangentOut, (float)(int32)q.Interpolation, (float)(int32)q.TangentMode);
				let keyOrder = CompareFloats(keyA, keyB);
				if (keyOrder != 0)
					return keyOrder;
			}
			return 0;
		case .Gradient:
			let x = AsGradient;
			let y = other.AsGradient;
			if (x.Interpolation != y.Interpolation)
				return ((int32)x.Interpolation < (int32)y.Interpolation) ? -1 : 1;
			if (x.Colors.Count != y.Colors.Count)
				return (x.Colors.Count < y.Colors.Count) ? -1 : 1;
			if (x.Alphas.Count != y.Alphas.Count)
				return (x.Alphas.Count < y.Alphas.Count) ? -1 : 1;
			for (int i = 0; i < x.Colors.Count; i++)
			{
				let s = x.Colors[i];
				let t = y.Colors[i];
				float[5] stopA = .(s.Time, s.Color.R, s.Color.G, s.Color.B, s.Color.A);
				float[5] stopB = .(t.Time, t.Color.R, t.Color.G, t.Color.B, t.Color.A);
				let stopOrder = CompareFloats(stopA, stopB);
				if (stopOrder != 0)
					return stopOrder;
			}
			for (int i = 0; i < x.Alphas.Count; i++)
			{
				float[2] alphaA = .(x.Alphas[i].Time, x.Alphas[i].Alpha);
				float[2] alphaB = .(y.Alphas[i].Time, y.Alphas[i].Alpha);
				let alphaOrder = CompareFloats(alphaA, alphaB);
				if (alphaOrder != 0)
					return alphaOrder;
			}
			return 0;
		}
	}

	private static int32 CompareFloats(Span<float> a, Span<float> b)
	{
		for (int i = 0; i < a.Length; i++)
		{
			if (a[i] != b[i])
				return (a[i] < b[i]) ? -1 : 1;
		}
		return 0;
	}

	private static int32 CompareStrings(StringView a, StringView b)
	{
		let n = (a.Length < b.Length) ? a.Length : b.Length;
		for (int i = 0; i < n; i++)
		{
			if (a[i] != b[i])
				return ((uint8)a[i] < (uint8)b[i]) ? -1 : 1;
		}
		if (a.Length == b.Length)
			return 0;
		return (a.Length < b.Length) ? -1 : 1;
	}

	// Compact fixed-ish float rendering (integer part + up to 3 decimals, trailing zeros trimmed).
	private static void AppendFloat(double value, String outText)
	{
		let neg = value < 0.0;
		let v = neg ? -value : value;
		let whole = (int64)v;
		var frac = v - (double)whole;
		if (neg)
			outText.Append('-');
		whole.ToString(outText);
		// up to 3 decimal digits
		char8[3] digits = default;
		int dc = 0;
		for (int i = 0; i < 3; i++)
		{
			frac *= 10.0;
			let d = (int32)frac;
			digits[dc++] = (char8)((int32)'0' + d);
			frac -= d;
		}
		while ((dc > 0) && (digits[dc - 1] == '0'))
			dc--; // trim trailing zeros
		if (dc > 0)
		{
			outText.Append('.');
			outText.Append(StringView(&digits[0], dc));
		}
	}
}
