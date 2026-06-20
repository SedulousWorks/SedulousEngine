namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.Fonts;

// === Standalone multi-component numeric fields ===
//
// Drop-in controls for editing Vector2/3/4 and Quaternion values
// outside the PropertyEditor / PropertyGrid framework. Each is a
// horizontal FlexLayout containing one NumericField per component,
// with the same colored axis labels the property-grid editors use
// so the look matches:
//
//     X = red, Y = green, Z = blue, W = gold
//
// All expose:
//   - `Value` get/set (typed)
//   - `OnValueChanged(typedValue)` fired per keystroke
//   - `OnEditBegan(field)` / `OnEditEnded(field)` bracket an editing
//     session - consumers that rebuild UI in response to value changes
//     should defer the rebuild until OnEditEnded, otherwise the user
//     loses focus mid-typing
//   - `SetRange(min, max)`, `Step`, `DecimalPlaces` applied uniformly

/// Colored single-character axis label used as a NumericField prefix.
public class AxisLabel : View
{
	private String mText ~ delete _;
	private Color32 mColor;

	public this(StringView text, Color32 color)
	{
		mText = new String(text);
		mColor = color;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float w = 12, h = 14;
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(11);
			if (font != null)
			{
				w = font.Font.MeasureString(mText);
				h = font.Font.Metrics.LineHeight;
			}
		}
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let font = ctx.FontService?.GetFont(11);
		if (font != null)
			ctx.VG.DrawText(mText, font, .(0, 0, Width, Height), .Center, .Middle, mColor);
	}
}

/// Standard axis colors used by all VectorN fields. Match the
/// property-grid Vector3Editor scheme.
static class AxisColors
{
	public const Color32 X = .(220,  80,  80, 255);
	public const Color32 Y = .( 80, 200,  80, 255);
	public const Color32 Z = .( 80, 120, 220, 255);
	public const Color32 W = .(200, 180, 120, 255);
}

/// Shared aggregation: counts child-field edit transactions and fires
/// one Begin / End on the parent. The End is deferred through the UI
/// MutationQueue so a focus jump between sibling fields produces a
/// single edit transaction (sibling.Begin runs synchronously after the
/// other sibling's End and cancels the pending parent.End).
abstract class AggregatingVectorField : FlexLayout
{
	private int mEditCount;
	private bool mPendingEnd;

	public Event<delegate void(AggregatingVectorField)> OnEditBegan ~ _.Dispose();
	public Event<delegate void(AggregatingVectorField)> OnEditEnded ~ _.Dispose();

	protected void WireChildEditEvents(NumericField nf)
	{
		nf.OnEditBegan.Add(new (_) =>
		{
			mPendingEnd = false;
			if (mEditCount == 0)
				OnEditBegan(this);
			mEditCount++;
		});
		nf.OnEditEnded.Add(new (_) =>
		{
			mEditCount--;
			if (mEditCount == 0)
			{
				mPendingEnd = true;
				let ctx = Context;
				if (ctx == null)
				{
					mPendingEnd = false;
					OnEditEnded(this);
					return;
				}
				ctx.MutationQueue.QueueAction(new () =>
				{
					if (mPendingEnd)
					{
						mPendingEnd = false;
						OnEditEnded(this);
					}
				});
			}
		});
	}
}

/// Standalone Vector2 input. Two NumericFields with colored X/Y labels.
public class Vector2Field : AggregatingVectorField
{
	private NumericField mX, mY;
	private Vector2 mValue;
	private bool mSyncing;

	public Event<delegate void(Vector2)> OnValueChanged ~ _.Dispose();

	public Vector2 Value
	{
		get => mValue;
		set { mValue = value; SyncToFields(); }
	}

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4;

		mX = MakeField("X", AxisColors.X);
		mY = MakeField("Y", AxisColors.Y);

		mX.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.X = (float)v; OnValueChanged(mValue); } });
		mY.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.Y = (float)v; OnValueChanged(mValue); } });

		WireChildEditEvents(mX);
		WireChildEditEvents(mY);

		AddView(mX, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mY, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
	}

	public void SetRange(double min, double max) { mX.Min = min; mX.Max = max; mY.Min = min; mY.Max = max; }
	public double Step { get => mX.Step; set { mX.Step = value; mY.Step = value; } }
	public int32 DecimalPlaces { get => mX.DecimalPlaces; set { mX.DecimalPlaces = value; mY.DecimalPlaces = value; } }
	public bool ShowSpinButtons { get => mX.ShowSpinButtons.Value; set { mX.ShowSpinButtons.Value = value; mY.ShowSpinButtons.Value = value; } }

	private void SyncToFields()
	{
		if (mSyncing) return;
		mSyncing = true;
		mX.Value = mValue.X;
		mY.Value = mValue.Y;
		mSyncing = false;
	}

	private static NumericField MakeField(StringView axisText, Color32 axisColor)
	{
		let f = new NumericField();
		f.ShowSpinButtons.Value = false;
		f.Min = -1e6; f.Max = 1e6;
		f.Step = 0.1;
		f.DecimalPlaces = 3;
		f.SetPrefix(new AxisLabel(axisText, axisColor));
		return f;
	}
}

/// Standalone Vector3 input. Three NumericFields with colored X/Y/Z labels.
public class Vector3Field : AggregatingVectorField
{
	private NumericField mX, mY, mZ;
	private Vector3 mValue;
	private bool mSyncing;

	public Event<delegate void(Vector3)> OnValueChanged ~ _.Dispose();

	public Vector3 Value
	{
		get => mValue;
		set { mValue = value; SyncToFields(); }
	}

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4;

		mX = MakeField("X", AxisColors.X);
		mY = MakeField("Y", AxisColors.Y);
		mZ = MakeField("Z", AxisColors.Z);

		mX.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.X = (float)v; OnValueChanged(mValue); } });
		mY.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.Y = (float)v; OnValueChanged(mValue); } });
		mZ.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.Z = (float)v; OnValueChanged(mValue); } });

		WireChildEditEvents(mX);
		WireChildEditEvents(mY);
		WireChildEditEvents(mZ);

		AddView(mX, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mY, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mZ, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
	}

	public void SetRange(double min, double max) { mX.Min = min; mX.Max = max; mY.Min = min; mY.Max = max; mZ.Min = min; mZ.Max = max; }
	public double Step { get => mX.Step; set { mX.Step = value; mY.Step = value; mZ.Step = value; } }
	public int32 DecimalPlaces { get => mX.DecimalPlaces; set { mX.DecimalPlaces = value; mY.DecimalPlaces = value; mZ.DecimalPlaces = value; } }
	public bool ShowSpinButtons { get => mX.ShowSpinButtons.Value; set { mX.ShowSpinButtons.Value = value; mY.ShowSpinButtons.Value = value; mZ.ShowSpinButtons.Value = value; } }

	private void SyncToFields()
	{
		if (mSyncing) return;
		mSyncing = true;
		mX.Value = mValue.X;
		mY.Value = mValue.Y;
		mZ.Value = mValue.Z;
		mSyncing = false;
	}

	private static NumericField MakeField(StringView axisText, Color32 axisColor)
	{
		let f = new NumericField();
		f.ShowSpinButtons.Value = false;
		f.Min = -1e6; f.Max = 1e6;
		f.Step = 0.1;
		f.DecimalPlaces = 3;
		f.SetPrefix(new AxisLabel(axisText, axisColor));
		return f;
	}
}

/// Standalone Vector4 input. Four NumericFields with colored X/Y/Z/W labels.
public class Vector4Field : AggregatingVectorField
{
	private NumericField mX, mY, mZ, mW;
	private Vector4 mValue;
	private bool mSyncing;

	public Event<delegate void(Vector4)> OnValueChanged ~ _.Dispose();

	public Vector4 Value
	{
		get => mValue;
		set { mValue = value; SyncToFields(); }
	}

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4;

		mX = MakeField("X", AxisColors.X);
		mY = MakeField("Y", AxisColors.Y);
		mZ = MakeField("Z", AxisColors.Z);
		mW = MakeField("W", AxisColors.W);

		mX.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.X = (float)v; OnValueChanged(mValue); } });
		mY.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.Y = (float)v; OnValueChanged(mValue); } });
		mZ.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.Z = (float)v; OnValueChanged(mValue); } });
		mW.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mValue.W = (float)v; OnValueChanged(mValue); } });

		WireChildEditEvents(mX);
		WireChildEditEvents(mY);
		WireChildEditEvents(mZ);
		WireChildEditEvents(mW);

		AddView(mX, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mY, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mZ, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mW, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
	}

	public void SetRange(double min, double max) { mX.Min = min; mX.Max = max; mY.Min = min; mY.Max = max; mZ.Min = min; mZ.Max = max; mW.Min = min; mW.Max = max; }
	public double Step { get => mX.Step; set { mX.Step = value; mY.Step = value; mZ.Step = value; mW.Step = value; } }
	public int32 DecimalPlaces { get => mX.DecimalPlaces; set { mX.DecimalPlaces = value; mY.DecimalPlaces = value; mZ.DecimalPlaces = value; mW.DecimalPlaces = value; } }
	public bool ShowSpinButtons { get => mX.ShowSpinButtons.Value; set { mX.ShowSpinButtons.Value = value; mY.ShowSpinButtons.Value = value; mZ.ShowSpinButtons.Value = value; mW.ShowSpinButtons.Value = value; } }

	private void SyncToFields()
	{
		if (mSyncing) return;
		mSyncing = true;
		mX.Value = mValue.X;
		mY.Value = mValue.Y;
		mZ.Value = mValue.Z;
		mW.Value = mValue.W;
		mSyncing = false;
	}

	private static NumericField MakeField(StringView axisText, Color32 axisColor)
	{
		let f = new NumericField();
		f.ShowSpinButtons.Value = false;
		f.Min = -1e6; f.Max = 1e6;
		f.Step = 0.1;
		f.DecimalPlaces = 3;
		f.SetPrefix(new AxisLabel(axisText, axisColor));
		return f;
	}
}

/// Standalone Quaternion input that exposes Euler angles (degrees) for
/// editing. The quaternion is the source of truth on the wire (Value
/// get/set), but the user manipulates three Euler fields - same UX as
/// the property-grid Quat editor.
///
/// Euler convention matches Sedulous.Engine's PropertyGridDescriptor:
/// X = pitch (around X), Y = yaw (around Y), Z = roll (around Z).
///
/// Round-tripping quat -> Euler -> quat isn't always identity because
/// the same orientation can have multiple Euler representations. The
/// field caches the last typed Eulers so the displayed angles stay
/// stable while the user is editing (they're only re-derived from the
/// quaternion when Value is set externally).
public class QuaternionField : AggregatingVectorField
{
	private NumericField mX, mY, mZ;
	private Quaternion mValue = .Identity;
	private Vector3 mEulerDegrees;
	private bool mSyncing;

	public Event<delegate void(Quaternion)> OnValueChanged ~ _.Dispose();

	public Quaternion Value
	{
		get => mValue;
		set
		{
			mValue = value;
			mEulerDegrees = QuaternionToEulerDegrees(value);
			SyncToFields();
		}
	}

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4;

		mX = MakeField("X", AxisColors.X);
		mY = MakeField("Y", AxisColors.Y);
		mZ = MakeField("Z", AxisColors.Z);

		mX.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mEulerDegrees.X = (float)v; RebuildQuaternionFromEulers(); } });
		mY.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mEulerDegrees.Y = (float)v; RebuildQuaternionFromEulers(); } });
		mZ.OnValueChanged.Add(new (nf, v) => { if (!mSyncing) { mEulerDegrees.Z = (float)v; RebuildQuaternionFromEulers(); } });

		WireChildEditEvents(mX);
		WireChildEditEvents(mY);
		WireChildEditEvents(mZ);

		SyncToFields();

		AddView(mX, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mY, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		AddView(mZ, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
	}

	public void SetRange(double min, double max) { mX.Min = min; mX.Max = max; mY.Min = min; mY.Max = max; mZ.Min = min; mZ.Max = max; }
	public double Step { get => mX.Step; set { mX.Step = value; mY.Step = value; mZ.Step = value; } }
	public int32 DecimalPlaces { get => mX.DecimalPlaces; set { mX.DecimalPlaces = value; mY.DecimalPlaces = value; mZ.DecimalPlaces = value; } }
	public bool ShowSpinButtons { get => mX.ShowSpinButtons.Value; set { mX.ShowSpinButtons.Value = value; mY.ShowSpinButtons.Value = value; mZ.ShowSpinButtons.Value = value; } }

	private void RebuildQuaternionFromEulers()
	{
		mValue = EulerDegreesToQuaternion(mEulerDegrees);
		OnValueChanged(mValue);
	}

	private void SyncToFields()
	{
		if (mSyncing) return;
		mSyncing = true;
		mX.Value = mEulerDegrees.X;
		mY.Value = mEulerDegrees.Y;
		mZ.Value = mEulerDegrees.Z;
		mSyncing = false;
	}

	private static NumericField MakeField(StringView axisText, Color32 axisColor)
	{
		let f = new NumericField();
		f.ShowSpinButtons.Value = false;
		f.Min = -360; f.Max = 360;
		f.Step = 1;
		f.DecimalPlaces = 2;
		f.SetPrefix(new AxisLabel(axisText, axisColor));
		return f;
	}

	// Conversion helpers - same convention as
	// `Sedulous.Editor.Core.PropertyGridDescriptor.QuaternionToEuler` so
	// inputs round-trip identically with the editor's property grid.

	private static Vector3 QuaternionToEulerDegrees(Quaternion q)
	{
		let sinP = 2.0f * (q.W * q.X - q.Z * q.Y);
		float pitch;
		if (Math.Abs(sinP) >= 1.0f)
			pitch = (sinP >= 0) ? (Math.PI_f / 2.0f) : -(Math.PI_f / 2.0f);
		else
			pitch = Math.Asin(sinP);

		let sinYCosP = 2.0f * (q.W * q.Y + q.X * q.Z);
		let cosYCosP = 1.0f - 2.0f * (q.X * q.X + q.Y * q.Y);
		let yaw = Math.Atan2(sinYCosP, cosYCosP);

		let sinRCosP = 2.0f * (q.W * q.Z + q.X * q.Y);
		let cosRCosP = 1.0f - 2.0f * (q.X * q.X + q.Z * q.Z);
		let roll = Math.Atan2(sinRCosP, cosRCosP);

		let radToDeg = 180.0f / Math.PI_f;
		return .(pitch * radToDeg, yaw * radToDeg, roll * radToDeg);
	}

	private static Quaternion EulerDegreesToQuaternion(Vector3 euler)
	{
		let degToRad = Math.PI_f / 180.0f;
		let pitch = euler.X * degToRad;
		let yaw   = euler.Y * degToRad;
		let roll  = euler.Z * degToRad;

		let cp = Math.Cos(pitch * 0.5f);
		let sp = Math.Sin(pitch * 0.5f);
		let cy = Math.Cos(yaw * 0.5f);
		let sy = Math.Sin(yaw * 0.5f);
		let cr = Math.Cos(roll * 0.5f);
		let sr = Math.Sin(roll * 0.5f);

		return .(
			sp * cy * cr - cp * sy * sr,
			cp * sy * cr + sp * cy * sr,
			cp * cy * sr - sp * sy * cr,
			cp * cy * cr + sp * sy * sr
		);
	}
}
