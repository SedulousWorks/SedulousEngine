using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

enum LampKind : uint8
{
	Point,
	Spot,
	Area,
}

/// A node a lamp holds: a group of its own table's rows.
[GuiReflect(true)]
class LampShape : Node
{
	private float mRadius = 1.0f;
	private float mSoftness = 0.5f;

	[GuiProperty]
	public float Radius
	{
		get => mRadius;
		set => mRadius = value;
	}

	[GuiProperty]
	public float Softness
	{
		get => mSoftness;
		set => mSoftness = value;
	}
}

[GuiReflect(true)]
class TestLamp
{
	private String mName = new .("Lamp") ~ delete _;
	private bool mEnabled = true;
	private uint8 mPriority = 3;
	private int32 mBounces = 2;
	private float mIntensity = 5.0f;
	private double mRange = 10.0;
	private LampKind mKind = .Point;
	private float mConeAngle = 45.0f;
	private Float2 mCone = .(20.0f, 35.0f);
	private Float3 mPosition = .(1.0f, 2.0f, 3.0f);
	private Quaternion mRotation = .Identity;
	private LampShape mShape = new .() ~ _.ReleaseRef();
	private Color mTint = .(1.0f, 1.0f, 1.0f, 1.0f);
	private Float4 mGlow = .(1.0f, 0.5f, 0.0f, 4.0f);
	private float mExposure = 0.0f;

	[GuiProperty]
	public StringView Name
	{
		get => mName;
		set => mName.Set(value);
	}

	[GuiProperty]
	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	[GuiProperty]
	public uint8 Priority
	{
		get => mPriority;
		set => mPriority = value;
	}

	[GuiProperty]
	public int32 Bounces
	{
		get => mBounces;
		set => mBounces = value;
	}

	[GuiProperty]
	public float Intensity
	{
		get => mIntensity;
		set => mIntensity = value;
	}

	[GuiProperty]
	public double Range
	{
		get => mRange;
		set => mRange = value;
	}

	[GuiProperty]
	public LampKind Kind
	{
		get => mKind;
		set => mKind = value;
	}

	[GuiProperty]
	public float ConeAngle
	{
		get => mConeAngle;
		set => mConeAngle = value;
	}

	[GuiProperty]
	public Float2 Cone
	{
		get => mCone;
		set => mCone = value;
	}

	[GuiProperty]
	public Float3 Position
	{
		get => mPosition;
		set => mPosition = value;
	}

	[GuiProperty]
	public Quaternion Rotation
	{
		get => mRotation;
		set => mRotation = value;
	}

	[GuiProperty]
	public LampShape Shape
	{
		get => mShape;
		set
		{
			if (value == mShape)
				return;
			value?.AddRef();
			mShape?.ReleaseRef();
			mShape = value;
		}
	}

	[GuiProperty]
	public Color Tint
	{
		get => mTint;
		set => mTint = value;
	}

	[GuiProperty]
	public Float4 Glow
	{
		get => mGlow;
		set => mGlow = value;
	}

	/// Read only: no setter.
	[GuiProperty]
	public int64 Id => 101;

	/// Written through its setter, held apart.
	[GuiProperty]
	public float Exposure
	{
		get => mExposure;
		set => mExposure = value;
	}
}

/// An emitter of Core's curve and the GUI's gradient, one value each.
[GuiReflect(true)]
class TestEmitter
{
	private Sedulous.Core.Curve mSize = new .() ~ delete _;
	private ColorGradient mShade = new .() ~ delete _;
	private float mRate = 10.0f;

	public this()
	{
		mSize.Keys.Add(CurveKey(0.0f, 1.0f));
		mSize.Keys.Add(CurveKey(1.0f, 0.0f));
		mShade.Colors.Add(GradientColorStop(0.0f, Color(1.0f, 1.0f, 1.0f, 1.0f)));
		mShade.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
		mShade.Alphas.Add(GradientAlphaStop(1.0f, 0.0f));
	}

	[GuiProperty]
	public Sedulous.Core.Curve Size
	{
		get => mSize;
		set
		{
			if (value == mSize)
				return;
			mSize.Keys.Clear();
			mSize.Keys.AddRange(value.Keys);
		}
	}

	[GuiProperty]
	public ColorGradient Shade
	{
		get => mShade;
		set => mShade.Set(value);
	}

	[GuiProperty]
	public float Rate
	{
		get => mRate;
		set => mRate = value;
	}
}

/// Two lamps, the source over the first (or both), its changes kept.
class ReflectedBed
{
	public TestLamp A = new .() ~ delete _;
	public TestLamp B = new .() ~ delete _;
	public ReflectedPropertySource Source = new .() ~ delete _;
	public BlobFormat Format = new .() ~ delete _;
	public List<ReflectedChange> Changes = new .() ~ DeleteContainerAndItems!(_);

	public this(bool both = false)
	{
		Object[2] objects = .(A, B);
		Span<Object> all = objects;
		Source.SetObjects(all.Slice(0, both ? 2 : 1), TestLamp.StaticGuiType);
		Source.SetOnChange(new (change) =>
			{
				let copy = new ReflectedChange();
				copy.Set(change);
				Changes.Add(copy);
			});
	}

	public void Commit(StringView path, Sedulous.GUI.Variant value)
	{
		Source.BeginEdit(path);
		Source.CommitEdit(path, PropertyWrite(value));
	}

	public Color ColorOf(StringView path, int object)
	{
		var value = Source.GetValue(path, object);
		defer value.Dispose();
		return value.AsColor;
	}
}

/// Two emitters, the source over both.
class EmitterBed
{
	public TestEmitter A = new .() ~ delete _;
	public TestEmitter B = new .() ~ delete _;
	public ReflectedPropertySource Source = new .() ~ delete _;
	public BlobFormat Format = new .() ~ delete _;
	public List<ReflectedChange> Changes = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		Object[2] objects = .(A, B);
		Source.SetObjects(objects, TestEmitter.StaticGuiType);
		Source.TextFormat = Format;
		Source.SetOnChange(new (change) =>
			{
				let copy = new ReflectedChange();
				copy.Set(change);
				Changes.Add(copy);
			});
	}

	public static CurveKey K(float time, float value) => CurveKey(time, value);
}

/// The reflected property source: a reflected type's properties as rows (values, an enum as its
/// integer, Float2/3/4, a Quaternion as Euler degrees, a node it holds as a group, other types hinted
/// with their names), writes through its table's setters, and each commit told as one change the
/// text format writes and Restore reads back; Core's curve and the GUI's gradient one value each.
class ReflectedSourceTests
{
	[Test]
	public static void ATypesPropertiesAsRowsEachOfItsKind()
	{
		let bed = scope ReflectedBed();
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		Test.Assert(rows.Count == 16);
		Test.Assert(rows[0].Name == "Name");
		Test.Assert(rows[0].DisplayName == "Name");
		Test.Assert(rows[0].Kind == .String);
		Test.Assert(Find(rows, "Enabled").Kind == .Bool);
		Test.Assert(Find(rows, "Priority").Kind == .Integer); // a uint8
		Test.Assert(Find(rows, "Intensity").Kind == .Float);
		Test.Assert(Find(rows, "Range").Kind == .Float); // a double
		Test.Assert(Find(rows, "Kind").Kind == .Integer); // an enum, as its integer
		Test.Assert(Find(rows, "ConeAngle").DisplayName == "Cone Angle");
		Test.Assert(Find(rows, "Cone").Hint == "Float2");
		Test.Assert(Find(rows, "Position").Hint == "Float3");
		Test.Assert(Find(rows, "Rotation").Hint == "Float3"); // Euler degrees
		Test.Assert(Find(rows, "Glow").Hint == "Float4");
		Test.Assert(Find(rows, "Shape").Kind == .Group);
		Test.Assert(Find(rows, "Shape").Hint == "LampShape"); // no editor takes it: its rows
		Test.Assert(Find(rows, "Tint").Kind == .Color);
		Test.Assert(Find(rows, "Tint").ShowsAlpha);
		Test.Assert(Find(rows, "Id").ReadOnly);
		Test.Assert(!Find(rows, "Intensity").ReadOnly);
		Test.Assert(Find(rows, "Exposure").Kind == .Float); // a setter's

		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		bed.Source.GetProperties("Rotation", parts);
		Test.Assert(parts.Count == 3);
		Test.Assert(parts[0].Name == "pitch");
		ClearAndDeleteItems!(parts);
		bed.Source.GetProperties("Shape", parts);
		Test.Assert(Find(parts, "Radius") != null);
		Test.Assert(Find(parts, "Softness").DisplayName == "Softness");
	}

	[Test]
	public static void ValuesReadAndWrittenThroughSettersPartsAndEulerDegrees()
	{
		let bed = scope ReflectedBed();
		Test.Assert(TextIs(bed.Source, "Name", 0, "Lamp"));
		Test.Assert(IntOf(bed.Source, "Priority", 0) == 3);
		CheckNear(FloatOf(bed.Source, "Position.y", 0), 2.0);
		CheckNear(FloatOf(bed.Source, "Shape.Softness", 0), 0.5);
		Test.Assert(IntOf(bed.Source, "Kind", 0) == 0);

		bed.Commit("Priority", .((int64)7));
		Test.Assert(bed.A.Priority == 7);
		bed.Commit("Range", .(2.5));
		CheckNear(bed.A.Range, 2.5);
		bed.Commit("Kind", .((int64)2));
		Test.Assert(bed.A.Kind == .Area);
		bed.Commit("Position.z", .(9.0));
		CheckNear(bed.A.Position.Z, 9.0);
		bed.Commit("Shape.Radius", .(4.0));
		CheckNear(bed.A.Shape.Radius, 4.0);
		bed.Commit("Exposure", .(1.5)); // through its setter
		CheckNear(bed.A.Exposure, 1.5);
		CheckNear(FloatOf(bed.Source, "Exposure", 0), 1.5);
		bed.Commit("Name", .("Key light"));
		Test.Assert(bed.A.Name == "Key light");

		// A Quaternion's yaw in degrees.
		bed.Commit("Rotation.yaw", .(90.0));
		CheckNear(FloatOf(bed.Source, "Rotation.yaw", 0), 90.0, 0.001);
		float yaw = 0.0f;
		float pitch = 0.0f;
		float roll = 0.0f;
		ToYawPitchRoll(bed.A.Rotation, out yaw, out pitch, out roll);
		CheckNear(RadiansToDegrees(yaw), 90.0, 0.001);

		// Read only: refused.
		bed.Commit("Id", .((int64)5));
		Test.Assert(bed.A.Id == 101);
		Test.Assert(IntOf(bed.Source, "Id", 0) == 101);
	}

	[Test]
	public static void SeveralObjectsMixedAPreviewOnEachAndACommitToldAsOneChangeRestoreReadsBack()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		bed.B.Intensity = 8.0f;
		Test.Assert(IsMixed(bed.Source, "Intensity", .Float));
		Test.Assert(!IsMixed(bed.Source, "Position.x", .Float));

		bed.Source.BeginEdit("Intensity");
		bed.Source.PreviewEdit("Intensity", PropertyWrite(.(20.0)));
		CheckNear(bed.A.Intensity, 20.0);
		CheckNear(bed.B.Intensity, 20.0);
		bed.Source.CommitEdit("Intensity", PropertyWrite(.(30.0)));
		Test.Assert(bed.Changes.Count == 1);
		let change = bed.Changes[0];
		Test.Assert(change.Path == "Intensity");
		Test.Assert(change.Before.Count == 2);

		Test.Assert(bed.Source.Restore(change, true)); // an undo: each its own value back
		CheckNear(bed.A.Intensity, 5.0);
		CheckNear(bed.B.Intensity, 8.0);
		Test.Assert(bed.Source.Restore(change, false)); // a redo
		CheckNear(bed.B.Intensity, 30.0);

		// A part of a node it holds, undone.
		bed.Commit("Shape.Radius", .(6.0));
		bed.A.Shape.Softness = 0.9f; // changed beside it, outside the source
		bed.Source.Restore(bed.Changes.Back, true);
		CheckNear(bed.A.Shape.Radius, 1.0);

		// Cancelled: each back.
		bed.Source.BeginEdit("Range");
		bed.Source.PreviewEdit("Range", PropertyWrite(.(99.0)));
		bed.Source.CancelEdit("Range");
		CheckNear(bed.A.Range, 10.0);
	}

	[Test]
	public static void TheGridShowsIt()
	{
		let bed = scope ReflectedBed();
		let root = NewRoot(400.0f, 600.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();
		grid.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(360.0f);
				s.Height = LayoutLength.Px(560.0f);
			});
		root.AddChild(grid);
		grid.Source = bed.Source;
		root.UpdateLayout();
		Test.Assert(grid.FindEditor("Position") is FloatsPropertyEditor);
		Test.Assert(grid.FindEditor("Rotation") is FloatsPropertyEditor);
		Test.Assert(grid.FindEditor("Tint") is ColorPropertyEditor);
		Test.Assert(grid.FindEditor("Kind") is NumberPropertyEditor); // an enum's integer
		Test.Assert(grid.FindEditor("Shape") == null); // a node no editor takes: a group of its rows
		Test.Assert(grid.GetRow(grid.FindRow("Shape")).HasChildren);
		grid.Source = null;
	}

	[Test]
	public static void TheTypesDefaultsFromItsCreatorProvidersOverThemAndARevertOfEachObjectsOwn()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		CheckNear(DefaultFloatOf(bed.Source, "Intensity", 0), 5.0);
		CheckNear(DefaultFloatOf(bed.Source, "Position.z", 1), 3.0);
		Test.Assert(HasNoDefault(bed.Source, "Id", 0)); // read only: nothing to put back
		Test.Assert(bed.Source.GetRevertText("Intensity", .. scope String()) == "Revert to default");

		// A prefab for the second object: its intensity 9.
		bed.Source.PushDefaults(new (path, object) => ((object == 1) && (path == "Intensity")) ? Sedulous.GUI.Variant(9.0) : Sedulous.GUI.Variant(),
			"Revert to prefab");
		CheckNear(DefaultFloatOf(bed.Source, "Intensity", 1), 9.0);
		CheckNear(DefaultFloatOf(bed.Source, "Intensity", 0), 5.0);
		Test.Assert(bed.Source.GetRevertText("Intensity", .. scope String()) == "Revert to prefab");

		bed.A.Intensity = 1.0f;
		bed.B.Intensity = 1.0f;
		bed.A.Shape.Radius = 7.0f;
		bed.B.Position = .(8.0f, 2.0f, 3.0f);
		Test.Assert(bed.Source.Revert("Intensity"));
		CheckNear(bed.A.Intensity, 5.0);
		CheckNear(bed.B.Intensity, 9.0); // each its own
		Test.Assert(bed.Source.Revert("Shape.Radius"));
		CheckNear(bed.A.Shape.Radius, 1.0);
		Test.Assert(bed.Source.Revert("Position"));
		CheckNear(bed.B.Position.X, 1.0);
		Test.Assert(!bed.Source.Revert("Position")); // nothing left
		Test.Assert(bed.Changes.Count == 3); // one change each

		// An undo of a revert puts the edit back.
		Test.Assert(bed.Source.Restore(bed.Changes[0], true));
		CheckNear(bed.B.Intensity, 1.0);
	}

	[Test]
	public static void CopyAndPasteThroughTheTextFormatOneChangeItsLikeOnly()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		bed.A.Position = .(4.0f, 5.0f, 6.0f);
		let position = bed.Source.CopyValue("Position", .. scope String());
		Test.Assert(position.Length != 0);

		// A Float3 onto a rotation's Euler degrees: each object turned the same.
		let reason = scope String();
		Test.Assert(bed.Source.PasteValue("Rotation", position, reason));
		CheckNear(FloatOf(bed.Source, "Rotation.pitch", 1), 4.0, 0.001);
		Test.Assert(bed.Changes.Count == 1);
		// Onto a Float2: refused, saying why.
		Test.Assert(!bed.Source.PasteValue("Cone", position, reason));
		Test.Assert(reason == "A Float3 does not paste onto a Float2");
		Test.Assert(!bed.Source.PasteValue("Id", position, reason));

		// A value and a part.
		bed.A.Intensity = 3.0f;
		let intensity = bed.Source.CopyValue("Intensity", .. scope String());
		Test.Assert(bed.Source.PasteValue("Intensity", intensity, reason));
		CheckNear(bed.B.Intensity, 3.0);
		Test.Assert(bed.Source.PasteValue("Position.y", intensity, reason));
		CheckNear(bed.B.Position.Y, 3.0);

		// A paste undoes in one.
		Test.Assert(bed.Source.Restore(bed.Changes.Back, true));
		CheckNear(bed.B.Position.Y, 2.0);
	}

	[Test]
	public static void AColorIsAColour()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		CheckNear(bed.ColorOf("Tint", 0).R, 1.0);
		bed.B.Tint = .(0.0f, 1.0f, 0.0f, 1.0f);
		Test.Assert(IsMixed(bed.Source, "Tint", .Color));
		bed.Commit("Tint", .(Color(0.2f, 0.4f, 0.6f, 0.5f)));
		CheckNear(bed.B.Tint.G, 0.4);
		Test.Assert(bed.Source.Restore(bed.Changes.Back, true));
		CheckNear(bed.B.Tint.G, 1.0);
	}

	[Test]
	public static void ACurveAndAGradientAreOneValueEachOfTheirKind()
	{
		let bed = scope EmitterBed();
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		Test.Assert(rows.Count == 3);
		Test.Assert(rows[0].Kind == .Curve);
		Test.Assert(rows[1].Kind == .Gradient);

		var size = bed.Source.GetValue("Size", 0);
		defer size.Dispose();
		Test.Assert(size.Kind == .Curve);
		Test.Assert(size.AsCurve.Length == 2);
		CheckNear(size.AsCurve[0].Value, 1.0);
		var color = bed.Source.GetValue("Shade", 1);
		defer color.Dispose();
		Test.Assert(color.Kind == .Gradient);
		Test.Assert(color.AsGradient.Colors.Count == 1);
		Test.Assert(color.AsGradient.Alphas.Count == 2);
	}

	[Test]
	public static void ACurveWrittenWholeOnEachObjectPreviewedCommittedAsOneChangeAnUndoReadsBack()
	{
		let bed = scope EmitterBed();
		CurveKey[3] three = .(EmitterBed.K(0.0f, 0.0f), EmitterBed.K(0.5f, 2.0f), EmitterBed.K(1.0f, 1.0f));
		bed.Source.BeginEdit("Size");
		bed.Source.PreviewEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(three)));
		Test.Assert(bed.A.Size.KeyCount == 3);
		CheckNear(bed.B.Size.Keys[1].Value, 2.0);
		bed.Source.CommitEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(three)));
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.B.Size.KeyCount == 3);

		// A cancel puts each back.
		CurveKey[1] one = .(EmitterBed.K(0.0f, 4.0f));
		bed.Source.BeginEdit("Size");
		bed.Source.PreviewEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(one)));
		Test.Assert(bed.A.Size.KeyCount == 1);
		bed.Source.CancelEdit("Size");
		Test.Assert(bed.A.Size.KeyCount == 3);

		// Undo the first: the two keys each had.
		Test.Assert(bed.Source.Restore(bed.Changes[0], true));
		Test.Assert(bed.A.Size.KeyCount == 2);
		CheckNear(bed.B.Size.Keys[0].Value, 1.0);
		Test.Assert(bed.Source.Restore(bed.Changes[0], false));
		Test.Assert(bed.B.Size.KeyCount == 3);
		CheckNear(bed.B.Size.Keys[1].Time, 0.5);
	}

	[Test]
	public static void AGradientWrittenWholeItsBlendTooMixedRevertedCopiedAndPastedAsOneValue()
	{
		let bed = scope EmitterBed();
		let gradient = scope ColorGradient();
		gradient.Colors.Add(GradientColorStop(0.0f, Color(1.0f, 0.0f, 0.0f, 1.0f)));
		gradient.Colors.Add(GradientColorStop(1.0f, Color(0.0f, 0.0f, 1.0f, 1.0f)));
		gradient.Alphas.Add(GradientAlphaStop(0.0f, 0.5f));
		gradient.Interpolation = .OkLab;
		bed.Source.BeginEdit("Shade");
		bed.Source.CommitEdit("Shade", PropertyWrite(Sedulous.GUI.Variant(gradient)));
		Test.Assert(bed.A.Shade.Colors.Count == 2);
		Test.Assert(bed.B.Shade.Alphas.Count == 1);
		Test.Assert(bed.B.Shade.Interpolation == .OkLab);
		var read = bed.Source.GetValue("Shade", 0);
		defer read.Dispose();
		Test.Assert(read.AsGradient.Equals(gradient));

		// Mixed when one differs.
		var key = bed.B.Size.Keys[0];
		key.Value = 3.0f;
		bed.B.Size.Keys[0] = key;
		Test.Assert(IsMixed(bed.Source, "Size", .Curve));
		Test.Assert(!IsMixed(bed.Source, "Shade", .Gradient));

		// Reverted to the type's own.
		Test.Assert(bed.Source.Revert("Shade"));
		Test.Assert(bed.A.Shade.Colors.Count == 1);
		Test.Assert(bed.B.Shade.Interpolation == .Srgb);

		// Copied from the first, pasted onto both: its like only.
		var second = bed.A.Size.Keys[1];
		second.Value = 2.5f;
		bed.A.Size.Keys[1] = second;
		let copied = bed.Source.CopyValue("Size", .. scope String());
		Test.Assert(copied.Length != 0);
		let reason = scope String();
		Test.Assert(bed.Source.PasteValue("Size", copied, reason));
		CheckNear(bed.B.Size.Keys[0].Value, 1.0);
		CheckNear(bed.B.Size.Keys[1].Value, 2.5);
		Test.Assert(!bed.Source.PasteValue("Shade", copied, reason));
		Test.Assert(reason == "A Curve does not paste onto a ColorGradient");
	}

	// What no Raptor test covers: a name as a row says it, and a source without objects.
	[Test]
	public static void ANameAsARowSaysItAndASourceWithoutObjectsHasNoRows()
	{
		Test.Assert(ReadablePropertyName("castsShadows", .. scope String()) == "Casts Shadows");
		Test.Assert(ReadablePropertyName("fovYRadians", .. scope String()) == "Fov Y Radians");
		Test.Assert(ReadablePropertyName("IBL", .. scope String()) == "IBL");
		Test.Assert(ReadablePropertyName("ConeAngle", .. scope String()) == "Cone Angle");

		let source = scope ReflectedPropertySource();
		source.SetObjects(Span<Object>(), TestLamp.StaticGuiType);
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.IsEmpty);
		Test.Assert(source.ObjectCount == 0);
		var value = source.GetValue("Intensity", 0);
		defer value.Dispose();
		Test.Assert(value.IsEmpty);
	}
}
