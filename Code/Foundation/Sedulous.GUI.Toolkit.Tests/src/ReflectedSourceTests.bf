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

/// A lamp's layers: flags (None, no bit, is no choice).
enum LampLayers : uint32
{
	None = 0,
	Main = 1,
	Shadows = 2,
	Reflections = 4,
}

/// A value struct a lamp holds: a group of its fields, read from a copy and written back whole.
struct LampShape
{
	[GuiProperty]
	public float Radius = 1.0f;
	[GuiProperty]
	public float Softness = 0.5f;
}

/// The effects a lamp's list holds: added by type, each by its [DisplayName].
[GuiReflect]
class TestEffect
{
	private float mStrength = 1.0f;

	[GuiProperty]
	public float Strength
	{
		get => mStrength;
		set => mStrength = value;
	}
}

[GuiReflect(true), DisplayName("Flicker")]
class TestFlicker : TestEffect
{
	private float mSpeed = 4.0f;

	[GuiProperty]
	public float Speed
	{
		get => mSpeed;
		set => mSpeed = value;
	}
}

[GuiReflect(true), DisplayName("Pulse")]
class TestPulse : TestEffect
{
	private float mPeriod = 2.0f;

	[GuiProperty]
	public float Period
	{
		get => mPeriod;
		set => mPeriod = value;
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
	private LampLayers mLayers = .Main;
	private float mConeAngle = 45.0f;
	private Float2 mCone = .(20.0f, 35.0f);
	private Float3 mPosition = .(1.0f, 2.0f, 3.0f);
	private Quaternion mRotation = .Identity;
	private LampShape mShape = .();
	private Color mTint = .(1.0f, 1.0f, 1.0f, 1.0f);
	private Color mEdge = .(0.2f, 0.2f, 0.2f, 1.0f);
	/// sRGB rgb, a linear intensity in w.
	private Float4 mGlow = .(1.0f, 0.5f, 0.0f, 4.0f);
	private float mExposure = 0.0f;
	private List<float> mWeights = new .() ~ delete _;
	private List<TestEffect> mEffects = new .() ~ DeleteContainerAndItems!(_);
	private List<float> mSteps = new .() ~ delete _;

	public this()
	{
		mSteps.Add(1.0f);
		mSteps.Add(2.0f);
	}

	[GuiProperty, Description("What the scene calls it")]
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

	[GuiProperty, Range(0.0f, 100.0f, 0.5f)]
	public float Intensity
	{
		get => mIntensity;
		set => mIntensity = value;
	}

	[GuiProperty, DisplayName("Reach")]
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

	[GuiProperty("", .BitFlags)]
	public LampLayers Layers
	{
		get => mLayers;
		set => mLayers = value;
	}

	/// A spot's alone.
	[GuiProperty, VisibleWhen("Kind=1")]
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
		set => mShape = value;
	}

	[GuiProperty]
	public Color Tint
	{
		get => mTint;
		set => mTint = value;
	}

	[GuiProperty("", .NoAlpha)]
	public Color Edge
	{
		get => mEdge;
		set => mEdge = value;
	}

	[GuiProperty("", .HdrColor)]
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

	/// A list, changed in place: no setter.
	[GuiProperty]
	public List<float> Weights => mWeights;

	[GuiProperty, GuiList(0, "TestFlicker, TestPulse")]
	public List<TestEffect> Effects => mEffects;

	/// A bounded array: at most three.
	[GuiProperty, GuiList(3)]
	public List<float> Steps => mSteps;
}

/// A node a property holds: a group of its own table's rows.
[GuiReflect(true)]
class LampBulb : Node
{
	private float mWatts = 60.0f;

	[GuiProperty]
	public float Watts
	{
		get => mWatts;
		set => mWatts = value;
	}
}

[GuiReflect(true)]
class TestSconce
{
	private LampBulb mBulb = new .() ~ _.ReleaseRef();

	[GuiProperty]
	public LampBulb Bulb
	{
		get => mBulb;
		set
		{
			if (value == mBulb)
				return;
			value?.AddRef();
			mBulb?.ReleaseRef();
			mBulb = value;
		}
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

/// A curve of an application's own (as a particle module's is): Core's keys in a bounded list,
/// registered with the source as one value. Its holder owns the list.
struct TestCurve
{
	[GuiProperty, GuiList(4)]
	public List<CurveKey> Keys;
}

/// A gradient of an application's own: Core's stops in bounded lists, and its blend.
struct TestGradient
{
	[GuiProperty, GuiList(3)]
	public List<GradientColorStop> Colors;
	[GuiProperty, GuiList(3)]
	public List<GradientAlphaStop> Alphas;
	[GuiProperty]
	public GradientInterpolation Interpolation = .Srgb;
}

/// A particle module's of its own: a curve and a gradient registered by their parts.
[GuiReflect(true)]
class TestModule
{
	private TestCurve mSize = .();
	private TestGradient mShade = .();
	private float mRate = 10.0f;

	public this()
	{
		mSize.Keys = new .();
		mSize.Keys.Add(CurveKey(0.0f, 1.0f));
		mSize.Keys.Add(CurveKey(1.0f, 0.0f));
		mShade.Colors = new .();
		mShade.Colors.Add(GradientColorStop(0.0f, Color(1.0f, 1.0f, 1.0f, 1.0f)));
		mShade.Alphas = new .();
		mShade.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
		mShade.Alphas.Add(GradientAlphaStop(1.0f, 0.0f));
	}

	public ~this()
	{
		delete mSize.Keys;
		delete mShade.Colors;
		delete mShade.Alphas;
	}

	[GuiProperty, Range(0.0f, 4.0f)]
	public TestCurve Size
	{
		get => mSize;
		set => mSize = value;
	}

	[GuiProperty]
	public TestGradient Shade
	{
		get => mShade;
		set => mShade = value;
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

	/// A list edit made in each object.
	public bool Edit(StringView path, ListEdit.Op kind, int index, int to = 0, StringView elementType = default)
	{
		let edit = scope ListEdit(kind, index, to);
		edit.ElementType.Set(elementType);
		return Source.EditList(path, edit);
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

/// Two particle modules, their curve and gradient registered as the application would.
class ModuleBed
{
	public TestModule A = new .() ~ delete _;
	public TestModule B = new .() ~ delete _;
	public ReflectedPropertySource Source = new .() ~ delete _;
	public BlobFormat Format = new .() ~ delete _;
	public List<ReflectedChange> Changes = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		Source.RegisterCurveType("TestCurve", .("Keys"));
		Source.RegisterGradientType("TestGradient", .("Colors", "Alphas", "Interpolation"));
		Object[2] objects = .(A, B);
		Source.SetObjects(objects, TestModule.StaticGuiType);
		Source.TextFormat = Format;
		Source.SetOnChange(new (change) =>
			{
				let copy = new ReflectedChange();
				copy.Set(change);
				Changes.Add(copy);
			});
	}
}

/// The reflected property source: a reflected type's properties as rows (values, an enum's choices
/// and flags, Float2/3/4, a Quaternion as Euler degrees, a value struct and a node it holds as
/// groups, lists of values and of objects, an HDR colour, other types hinted with their names) with
/// what an inspector reads of each, writes through its table's setters, and each commit told as one
/// change the text format writes and Restore reads back; Core's curve and the GUI's gradient one
/// value each, and an application's own registered by their parts.
class ReflectedSourceTests
{
	[Test]
	public static void ATypesPropertiesAsRowsEachOfItsKindWithTheAttributesTheInspectorReads()
	{
		let bed = scope ReflectedBed();
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		Test.Assert(rows.Count == 21);
		Test.Assert(rows[0].Name == "Name");
		Test.Assert(rows[0].DisplayName == "Name");
		Test.Assert(rows[0].Description == "What the scene calls it");
		Test.Assert(rows[0].Kind == .String);
		Test.Assert(Find(rows, "Enabled").Kind == .Bool);
		Test.Assert(Find(rows, "Priority").Kind == .Integer); // a uint8
		let intensity = Find(rows, "Intensity");
		Test.Assert(intensity.Kind == .Float);
		Test.Assert(intensity.HasRange);
		CheckNear(intensity.Max, 100.0);
		CheckNear(intensity.Step, 0.5);
		Test.Assert(Find(rows, "Range").Kind == .Float); // a double
		Test.Assert(Find(rows, "Range").DisplayName == "Reach");
		let kind = Find(rows, "Kind");
		Test.Assert(kind.Kind == .Enum);
		Test.Assert(kind.Choices.Count == 3);
		Test.Assert(kind.Choices[1].Name == "Spot");
		Test.Assert(kind.Choices[1].Value == 1);
		let layers = Find(rows, "Layers");
		Test.Assert(layers.Kind == .Flags);
		Test.Assert(layers.Choices.Count == 3); // None, no bit, is no choice
		Test.Assert(layers.Choices[2].Value == 4);
		Test.Assert(Find(rows, "ConeAngle").DisplayName == "Cone Angle");
		Test.Assert(!Find(rows, "ConeAngle").Visible); // a point light: visible when Kind=1
		Test.Assert(Find(rows, "Cone").Hint == "Float2");
		Test.Assert(Find(rows, "Position").Hint == "Float3");
		Test.Assert(Find(rows, "Rotation").Hint == "Float3"); // Euler degrees
		Test.Assert(Find(rows, "Shape").Kind == .Group);
		Test.Assert(Find(rows, "Shape").Hint == "LampShape"); // no editor takes it: its rows
		Test.Assert(Find(rows, "Tint").Kind == .Color);
		Test.Assert(Find(rows, "Tint").ShowsAlpha);
		Test.Assert(!Find(rows, "Edge").ShowsAlpha);
		Test.Assert(Find(rows, "Glow").Hint == "ColorHdr");
		Test.Assert(Find(rows, "Id").ReadOnly);
		Test.Assert(!Find(rows, "Intensity").ReadOnly);
		Test.Assert(Find(rows, "Exposure").Kind == .Float); // a setter's
		Test.Assert(Find(rows, "Weights").Kind == .List);
		Test.Assert(!Find(rows, "Weights").ReadOnly); // changed in place: no setter needed

		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		bed.Source.GetProperties("Rotation", parts);
		Test.Assert(parts.Count == 3);
		Test.Assert(parts[0].Name == "pitch");
		// Shown as their axes, as a position's parts are.
		Test.Assert(parts[0].DisplayName == "X");
		Test.Assert(parts[1].DisplayName == "Y");
		Test.Assert(parts[2].DisplayName == "Z");
		ClearAndDeleteItems!(parts);
		bed.Source.GetProperties("Shape", parts);
		Test.Assert(parts.Count == 2);
		Test.Assert(parts[1].DisplayName == "Softness");

		bed.A.Kind = .Spot;
		ClearAndDeleteItems!(rows);
		bed.Source.GetProperties("", rows);
		Test.Assert(Find(rows, "ConeAngle").Visible);
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
		bed.Source.BeginEdit("Layers");
		bed.Source.CommitEdit("Layers", PropertyWrite(.((int64)4), 4)); // a flag alone
		Test.Assert((uint32)bed.A.Layers == 5);
		bed.Commit("Position.z", .(9.0));
		CheckNear(bed.A.Position.Z, 9.0);
		bed.Commit("Shape.Radius", .(4.0)); // into a copy of the struct, written back whole
		CheckNear(bed.A.Shape.Radius, 4.0);
		CheckNear(bed.A.Shape.Softness, 0.5);
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

		// A field of a struct, undone.
		bed.Commit("Shape.Radius", .(6.0));
		var shape = bed.A.Shape;
		shape.Softness = 0.9f; // changed beside it, outside the source
		bed.A.Shape = shape;
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
		Test.Assert(grid.FindEditor("Glow") is HdrColorPropertyEditor);
		Test.Assert(grid.FindEditor("Shape") == null); // a struct no editor takes: a group of its rows
		Test.Assert(grid.GetRow(grid.FindRow("Shape")).HasChildren);
		Test.Assert(grid.FindEditor("Kind") is EnumPropertyEditor);
		Test.Assert(grid.FindEditor("Layers") is FlagsPropertyEditor);
		Test.Assert(grid.FindRow("ConeAngle") < 0);
		grid.Source = null;
	}

	[Test]
	public static void ArraysAndBoundedArraysAreListsElementsByIndexChangedInEachObjectAsOneChange()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		bed.A.Weights.Add(0.5f);
		bed.A.Weights.Add(0.25f);
		bed.B.Weights.Add(0.5f);
		bed.B.Weights.Add(0.75f);
		bed.B.Weights.Add(1.0f);
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		let weights = Find(rows, "Weights");
		Test.Assert(weights.Kind == .List);
		Test.Assert(weights.ListOps == (PropertyListAdd | PropertyListRemove | PropertyListMove));
		Test.Assert(IsMixed(bed.Source, "Weights", .List)); // two and three
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		bed.Source.GetProperties("Weights", elements);
		Test.Assert(elements.Count == 2); // the fewest
		Test.Assert(elements[1].Kind == .Float);
		Test.Assert(elements[1].DisplayName == "Element 2");
		Test.Assert(IsMixed(bed.Source, "Weights.1", .Float));

		bed.Commit("Weights.1", .(2.0));
		CheckNear(bed.B.Weights[1], 2.0);
		Test.Assert(bed.Edit("Weights", .Move, 1, 0));
		CheckNear(bed.A.Weights[0], 2.0);
		CheckNear(bed.B.Weights[2], 1.0); // b's third stays
		Test.Assert(bed.Edit("Weights", .Insert, 99));
		Test.Assert(bed.A.Weights.Count == 3);
		Test.Assert(bed.B.Weights.Count == 4);

		// An undo of the add puts each object's list back as it was.
		Test.Assert(bed.Source.Restore(bed.Changes.Back, true));
		Test.Assert(bed.A.Weights.Count == 2);
		Test.Assert(bed.B.Weights.Count == 3);
		CheckNear(bed.B.Weights[2], 1.0);

		// A bounded array: its count, at most its capacity, which its row says; a List has no most.
		ClearAndDeleteItems!(rows);
		bed.Source.GetProperties("", rows);
		Test.Assert(Find(rows, "Steps").MaxCount == 3);
		Test.Assert(Find(rows, "Weights").MaxCount == 0);
		ClearAndDeleteItems!(elements);
		bed.Source.GetProperties("Steps", elements);
		Test.Assert(elements.Count == 2);
		Test.Assert(bed.Edit("Steps", .Insert, 99));
		Test.Assert(bed.A.Steps.Count == 3);
		Test.Assert(!bed.Edit("Steps", .Insert, 99)); // full
	}

	[Test]
	public static void APolymorphicListAddsByTypeItsElementsOwnPropertiesAndAnUndoRebuildsIt()
	{
		let bed = scope ReflectedBed();
		bed.Source.TextFormat = bed.Format;
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		let effects = Find(rows, "Effects");
		Test.Assert(effects.ElementTypes.Count == 2);
		Test.Assert(effects.ElementTypes[0] == "Flicker");
		Test.Assert(effects.ElementTypes[1] == "Pulse");

		Test.Assert(bed.Edit("Effects", .Insert, 0, 0, "Pulse"));
		Test.Assert(bed.Edit("Effects", .Insert, 1, 0, "Flicker"));
		Test.Assert(bed.A.Effects.Count == 2);
		Test.Assert(bed.A.Effects[0] is TestPulse);

		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		bed.Source.GetProperties("Effects", elements);
		Test.Assert(elements.Count == 2);
		Test.Assert(elements[0].DisplayName == "Pulse 1");
		let pulse = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(pulse); }
		bed.Source.GetProperties("Effects.0", pulse);
		Test.Assert(pulse.Count == 2); // its base's strength, then its period
		Test.Assert(pulse[1].Name == "Period");
		bed.Commit("Effects.0.Period", .(5.0));
		CheckNear(((TestPulse)bed.A.Effects[0]).Period, 5.0);

		// Removing the pulse and undoing it makes a pulse again, with its period.
		let before = bed.Changes.Count;
		Test.Assert(bed.Edit("Effects", .Remove, 0));
		Test.Assert(bed.Changes.Count == before + 1);
		Test.Assert(bed.A.Effects[0] is TestFlicker);
		Test.Assert(bed.Source.Restore(bed.Changes.Back, true));
		Test.Assert(bed.A.Effects.Count == 2);
		let back = bed.A.Effects[0] as TestPulse;
		Test.Assert(back != null);
		CheckNear(back.Period, 5.0);
	}

	[Test]
	public static void TheTypesDefaultsFromItsCreatorProvidersOverThemAndARevertOfEachObjectsOwn()
	{
		let bed = scope ReflectedBed(true);
		bed.Source.TextFormat = bed.Format;
		CheckNear(DefaultFloatOf(bed.Source, "Intensity", 0), 5.0);
		CheckNear(DefaultFloatOf(bed.Source, "Position.z", 1), 3.0);
		Test.Assert(IntOfDefault(bed.Source, "Weights", 0) == 0);
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
		var shape = bed.A.Shape;
		shape.Radius = 7.0f;
		bed.A.Shape = shape;
		bed.B.Position = .(8.0f, 2.0f, 3.0f);
		bed.A.Weights.Add(0.5f);
		Test.Assert(bed.Source.Revert("Intensity"));
		CheckNear(bed.A.Intensity, 5.0);
		CheckNear(bed.B.Intensity, 9.0); // each its own
		Test.Assert(bed.Source.Revert("Shape"));
		CheckNear(bed.A.Shape.Radius, 1.0);
		Test.Assert(bed.Source.Revert("Position"));
		CheckNear(bed.B.Position.X, 1.0);
		Test.Assert(bed.Source.Revert("Weights")); // a list whole, from the type's instance
		Test.Assert(bed.A.Weights.IsEmpty);
		Test.Assert(!bed.Source.Revert("Weights")); // nothing left
		Test.Assert(bed.Changes.Count == 4); // one change each

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

		// A struct whole, and a list with its elements.
		var shape = bed.A.Shape;
		shape.Radius = 3.0f;
		bed.A.Shape = shape;
		let copiedShape = bed.Source.CopyValue("Shape", .. scope String());
		Test.Assert(bed.Source.PasteValue("Shape", copiedShape, reason));
		CheckNear(bed.B.Shape.Radius, 3.0);
		bed.A.Weights.Add(0.1f);
		bed.A.Weights.Add(0.2f);
		let weights = bed.Source.CopyValue("Weights", .. scope String());
		Test.Assert(bed.Source.PasteValue("Weights", weights, reason));
		Test.Assert(bed.B.Weights.Count == 2);
		CheckNear(bed.B.Weights[1], 0.2);

		// A paste undoes in one.
		Test.Assert(bed.Source.Restore(bed.Changes.Back, true));
		Test.Assert(bed.B.Weights.IsEmpty);
	}

	[Test]
	public static void AColorIsAColourAnHdrColourItsColourAndItsIntensityInStopsOnItsRow()
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

		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		bed.Source.GetProperties("Glow", parts);
		Test.Assert(parts.Count == 2);
		Test.Assert(parts[0].Kind == .Color);
		Test.Assert(!parts[0].ShowsAlpha);
		Test.Assert(parts[1].Hint == "stops");
		CheckNear(bed.ColorOf("Glow.color", 0).G, 0.5);
		CheckNear(FloatOf(bed.Source, "Glow.intensity", 0), 4.0);
		bed.Commit("Glow.color", .(Color(0.0f, 0.0f, 1.0f, 1.0f)));
		CheckNear(bed.A.Glow.Z, 1.0);
		CheckNear(bed.A.Glow.W, 4.0); // its intensity kept
		bed.Commit("Glow.intensity", .(8.0));
		CheckNear(bed.B.Glow.W, 8.0);
		CheckNear(bed.B.Glow.Z, 1.0);

		// A colour copied pastes onto an HDR colour's colour part; reverted, the type's comes back.
		let tint = bed.Source.CopyValue("Tint", .. scope String());
		let reason = scope String();
		Test.Assert(bed.Source.PasteValue("Glow.color", tint, reason));
		CheckNear(bed.A.Glow.X, 1.0);
		Test.Assert(bed.Source.Revert("Glow"));
		CheckNear(bed.A.Glow.Y, 0.5);
		CheckNear(bed.B.Glow.W, 4.0);
	}

	[Test]
	public static void TheStopsEditorShowsLog2OfTheIntensityAndWrites2ToItsStops()
	{
		let bed = scope ReflectedBed();
		let root = NewRoot(400.0f, 900.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();
		grid.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(360.0f);
				s.Height = LayoutLength.Px(860.0f);
			});
		root.AddChild(grid);
		grid.Source = bed.Source;
		root.UpdateLayout();
		let glow = grid.FindEditor("Glow") as HdrColorPropertyEditor;
		Test.Assert(glow != null);
		let stops = glow.IntensityPart.Field;
		CheckNear(stops.Value, 2.0); // 4 is two stops
		stops.RequestFocus();
		for (int i < 10)
			root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Up); // a stop more
		CheckNear(bed.A.Glow.W, 8.0, 0.01);
		grid.Source = null;
	}

	// What no Raptor test covers: a node a property holds is a group of its own table's rows,
	// written in place and serialized apart from its holder.
	[Test]
	public static void ANodeAPropertyHoldsIsAGroupOfItsOwnTablesRows()
	{
		let a = scope TestSconce();
		let source = scope ReflectedPropertySource();
		let format = scope BlobFormat();
		source.TextFormat = format;
		Object[1] objects = .(a);
		source.SetObjects(objects, TestSconce.StaticGuiType);
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.Count == 1);
		Test.Assert(rows[0].Kind == .Group);
		Test.Assert(rows[0].Hint == "LampBulb");
		ClearAndDeleteItems!(rows);
		source.GetProperties("Bulb", rows);
		Test.Assert(Find(rows, "Watts") != null);

		CheckNear(FloatOf(source, "Bulb.Watts", 0), 60.0);
		source.BeginEdit("Bulb.Watts");
		source.CommitEdit("Bulb.Watts", PropertyWrite(.(100.0)));
		CheckNear(a.Bulb.Watts, 100.0);
		Test.Assert(source.Revert("Bulb"));
		CheckNear(a.Bulb.Watts, 60.0);
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

	[Test]
	public static void ARegisteredCurveAndGradientAreOneValueEachOfTheirKindTheirMostTheirListsCapacity()
	{
		let bed = scope ModuleBed();
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Source.GetProperties("", rows);
		Test.Assert(rows.Count == 3);
		Test.Assert(rows[0].Kind == .Curve);
		Test.Assert(rows[0].MaxCount == 4);
		Test.Assert(rows[0].HasRange);
		CheckNear(rows[0].Max, 4.0);
		Test.Assert(rows[1].Kind == .Gradient);
		Test.Assert(rows[1].MaxCount == 3);

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

		// Unregistered, the same type is a struct of its own rows.
		let plain = scope ReflectedPropertySource();
		Object[1] one = .(bed.A);
		plain.SetObjects(one, TestModule.StaticGuiType);
		ClearAndDeleteItems!(rows);
		plain.GetProperties("", rows);
		Test.Assert(rows[0].Kind == .Group);
		Test.Assert(rows[0].Hint == "TestCurve");
	}

	[Test]
	public static void ARegisteredCurveKeepsItsMostAndAGradientItsBlendEachUndoneAndPastedItsLikeOnly()
	{
		let bed = scope ModuleBed();
		CurveKey[3] three = .(EmitterBed.K(0.0f, 0.0f), EmitterBed.K(0.5f, 2.0f), EmitterBed.K(1.0f, 1.0f));
		bed.Source.BeginEdit("Size");
		bed.Source.PreviewEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(three)));
		Test.Assert(bed.A.Size.Keys.Count == 3);
		CheckNear(bed.B.Size.Keys[1].Value, 2.0);
		bed.Source.CommitEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(three)));
		Test.Assert(bed.Changes.Count == 1);

		// Its most: five keys keep four.
		CurveKey[5] five = .(EmitterBed.K(0.0f, 0.0f), EmitterBed.K(0.2f, 1.0f), EmitterBed.K(0.4f, 0.0f), EmitterBed.K(0.6f, 1.0f), EmitterBed.K(0.8f, 0.0f));
		bed.Source.BeginEdit("Size");
		bed.Source.CommitEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(five)));
		Test.Assert(bed.A.Size.Keys.Count == 4);

		// A cancel puts each back.
		bed.Source.BeginEdit("Size");
		bed.Source.PreviewEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(three)));
		bed.Source.CancelEdit("Size");
		Test.Assert(bed.A.Size.Keys.Count == 4);

		// Undo the first: the two keys each had.
		Test.Assert(bed.Source.Restore(bed.Changes[0], true));
		Test.Assert(bed.A.Size.Keys.Count == 2);
		CheckNear(bed.B.Size.Keys[0].Value, 1.0);
		Test.Assert(bed.Source.Restore(bed.Changes[0], false));
		Test.Assert(bed.B.Size.Keys.Count == 3);
		CheckNear(bed.B.Size.Keys[1].Time, 0.5);

		// A gradient whole, its blend through a copy of the struct written back.
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

		// Copied from the first, pasted onto both: its like only, the reason naming the types.
		var second = bed.A.Size.Keys[1];
		second.Value = 2.5f;
		bed.A.Size.Keys[1] = second;
		let copied = bed.Source.CopyValue("Size", .. scope String());
		Test.Assert(copied.Length != 0);
		let reason = scope String();
		Test.Assert(bed.Source.PasteValue("Size", copied, reason));
		CheckNear(bed.B.Size.Keys[0].Value, 0.0); // the first's (redone to three keys), over the 3 it differed by
		CheckNear(bed.B.Size.Keys[1].Value, 2.5);
		Test.Assert(!bed.Source.PasteValue("Shade", copied, reason));
		Test.Assert(reason == "A TestCurve does not paste onto a TestGradient");
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

	/// Object `object`'s default at `path` as a whole number (the value disposed).
	private static int64 IntOfDefault(IPropertySource source, StringView path, int object)
	{
		var value = source.GetDefault(path, object);
		defer value.Dispose();
		return value.AsInt;
	}
}
