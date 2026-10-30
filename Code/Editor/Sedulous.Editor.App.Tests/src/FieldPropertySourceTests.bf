using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The test's own hint attribute (an application's, as the engine's BoneName is).
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct FieldSourceBoneAttribute : Attribute
{
}

/// A joint of an application's: a bone named by a string its editor offers from a skeleton, and
/// rows whose conditions read or do not.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class FieldSourceJoint
{
	[FieldSourceBone]
	public String Bone = new .() ~ delete _;
	public String Label = new .() ~ delete _;
	public int32 Mode = 0;
	[VisibleWhen("Mode=2")]
	public float WhenTwo = 0.0f;
	[VisibleWhen("=1")]
	public float NoName = 0.0f;
	[VisibleWhen("Mode=")]
	public float NoValue = 0.0f;
	[VisibleWhen("Mode=x")]
	public float NotANumber = 0.0f;
	[VisibleWhen("Mode=1,,2")]
	public float EmptyItem = 0.0f;
}

/// What a Guid list points at, by the full name of a type its library cannot see.
class FieldSourceTarget
{
}

/// Tints a runtime keeps as four floats, and a list of bare Guids naming what they point at.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class FieldSourceTints
{
	[References("Sedulous.Editor.App.Tests.FieldSourceTarget")]
	public List<Guid> Meshes = new .() ~ delete _;
	[AsColor]
	public Float4 Tint = .(1.0f, 0.5f, 0.25f, 0.75f);
	[AsColor(false)]
	public Float4 Rim = .(0.0f, 0.0f, 1.0f, 1.0f);
	public Float4 Plain = .(1.0f, 2.0f, 3.0f, 4.0f);
}

/// A private list an inspector is given, beside a public value.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class FieldSourceSteps
{
	public int32 Count = 3;
	[InspectorField, DisplayName("Steps")]
	private List<int32> mSteps = new .() ~ delete _;
	private int32 mHidden = 7;

	public List<int32> Steps => mSteps;
}

/// A curve kept as a fixed array and a count, as a particle curve is.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
struct FieldSourceCurve
{
	public CurveKey[4] Keys = .();
	public int32 KeyCount = 0;

	public this() { }
}

/// A gradient kept the same way.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
struct FieldSourceGradient
{
	public GradientColorStop[3] Colors = .();
	public int32 ColorCount = 0;
	public GradientAlphaStop[2] Alphas = .();
	public int32 AlphaCount = 0;
	public GradientInterpolation Interpolation = .Srgb;

	public this() { }
}

[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class FieldSourceCurves
{
	public FieldSourceCurve Size = .();
	public FieldSourceGradient Tint = .();
}

/// A module of a list that owns its modules: an add chooses its type.
abstract class FieldSourceModule
{
}

[Reflect(.Type | .NonStaticFields | .DefaultConstructor), AlwaysInclude(AssumeInstantiated=true), DisplayName("Spin")]
class FieldSourceSpin : FieldSourceModule
{
	public float Speed = 1.0f;
}

[Reflect(.Type | .NonStaticFields | .DefaultConstructor), AlwaysInclude(AssumeInstantiated=true), DisplayName("Glow")]
class FieldSourceGlow : FieldSourceModule
{
	public float Strength = 2.0f;
}

[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
class FieldSourceModules
{
	public List<FieldSourceModule> Modules = new .() ~ DeleteContainerAndItems!(_);
}

/// A budget a setter guards (it reallocates), and a count only read.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor | .Methods), AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
class FieldSourceBudget
{
	public float Rate = 1.0f;
	private int32 mBudget = 16;
	public int32 Reallocations = 0;

	[InspectorProperty("Budget", "SetBudget"), DisplayName("Most Alive"), Range(1, 1000, 1)]
	public int32 GetBudget() => mBudget;
	public void SetBudget(int32 budget)
	{
		mBudget = budget;
		Reallocations++;
	}

	[InspectorProperty("Twice")]
	public int32 GetTwice() => mBudget * 2;
}

/// The field source's colours kept as four floats, its lists of named ids, the private fields an
/// inspector is given and the computed rows.
class FieldPropertySourceTests
{
	[Test]
	public static void AnInspectorPropertyIsARowReadByItsGetterAndWrittenThroughItsSetter()
	{
		let budget = scope FieldSourceBudget();
		let address = Internal.UnsafeCastToPtr(budget);
		let source = scope FieldPropertySource(typeof(FieldSourceBudget), 1, new (object) => address,
			new (apply) => { apply(0, address); });

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		PropertyInfo shown = null;
		PropertyInfo twice = null;
		for (let info in rows)
		{
			if (info.Name == "Budget")
				shown = info;
			else if (info.Name == "Twice")
				twice = info;
		}
		Test.Assert((shown != null) && (twice != null), "after the fields, by the attribute's name");
		Test.Assert(shown.DisplayName == "Most Alive");
		Test.Assert(shown.Kind == .Integer);
		Test.Assert(shown.HasRange && (shown.Max == 1000));
		Test.Assert(!shown.ReadOnly);
		Test.Assert(twice.ReadOnly, "no setter: read only");

		var value = source.GetValue("Budget", 0);
		Test.Assert(value.AsInt == 16);
		value.Dispose();
		source.BeginEdit("Budget");
		source.CommitEdit("Budget", PropertyWrite(Sedulous.GUI.Variant((int64)64)));
		Test.Assert(budget.GetBudget() == 64);
		Test.Assert(budget.Reallocations >= 1, "through the setter");
		var doubled = source.GetValue("Twice", 0);
		Test.Assert(doubled.AsInt == 128);
		doubled.Dispose();
		source.BeginEdit("Twice");
		source.CommitEdit("Twice", PropertyWrite(Sedulous.GUI.Variant((int64)3)));
		Test.Assert(budget.GetBudget() == 64, "a read-only row writes nothing");
		let copied = scope String();
		source.CopyValue("Budget", copied);
		Test.Assert(copied == "64", copied);
	}

	[Test]
	public static void AListOfObjectsAddsATypeDerivingFromItsElementsRemovesAndMoves()
	{
		let owner = scope FieldSourceModules();
		let address = Internal.UnsafeCastToPtr(owner);
		let source = scope FieldPropertySource(typeof(FieldSourceModules), 1, new (object) => address,
			new (apply) => { apply(0, address); });

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.Count == 1);
		Test.Assert(rows[0].Kind == .List);
		Test.Assert((rows[0].ListOps & PropertyListAdd) != 0);
		Test.Assert((rows[0].ListOps & PropertyListMove) != 0);
		Test.Assert(rows[0].ElementTypes.Count == 2, "the concrete types deriving from the element type");
		Test.Assert((rows[0].ElementTypes[0] == "Glow") && (rows[0].ElementTypes[1] == "Spin"), "by their shown names");

		let spin = scope ListEdit(.Insert, 0);
		spin.ElementType.Set("Spin");
		Test.Assert(source.EditList("Modules", spin));
		let glow = scope ListEdit(.Insert, 1);
		glow.ElementType.Set("Glow");
		Test.Assert(source.EditList("Modules", glow));
		Test.Assert((owner.Modules.Count == 2) && (owner.Modules[0] is FieldSourceSpin) && (owner.Modules[1] is FieldSourceGlow));

		// Each element named by its own type, its own fields its rows.
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		source.GetProperties("Modules", elements);
		Test.Assert((elements.Count == 2) && (elements[0].DisplayName == "Spin 1") && (elements[1].DisplayName == "Glow 2"));
		source.BeginEdit("Modules.1.Strength");
		source.CommitEdit("Modules.1.Strength", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		Test.Assert(((FieldSourceGlow)owner.Modules[1]).Strength == 5.0f);

		Test.Assert(source.EditList("Modules", scope ListEdit(.Move, 1, 0)));
		Test.Assert(owner.Modules[0] is FieldSourceGlow);
		Test.Assert(source.EditList("Modules", scope ListEdit(.Remove, 0)));
		Test.Assert((owner.Modules.Count == 1) && (owner.Modules[0] is FieldSourceSpin), "the removed one deleted, the other kept");
		let unknown = scope ListEdit(.Insert, 0);
		unknown.ElementType.Set("Smoke");
		Test.Assert(!source.EditList("Modules", unknown), "no such type: nothing added");
		Test.Assert(owner.Modules.Count == 1);
	}

	[Test]
	public static void ARegisteredCurveAndGradientAreOneValueEachForTheToolkitsEditors()
	{
		FieldPropertySource.RegisterCurveType(typeof(FieldSourceCurve), .("Keys", "KeyCount"));
		FieldPropertySource.RegisterGradientType(typeof(FieldSourceGradient), .("Colors", "ColorCount", "Alphas", "AlphaCount", "Interpolation"));
		let curves = scope FieldSourceCurves();
		curves.Size.Keys[0] = CurveKey(0.0f, 1.0f);
		curves.Size.Keys[1] = CurveKey(1.0f, 0.5f);
		curves.Size.KeyCount = 2;
		curves.Tint.Colors[0] = .(0.0f, Color(1, 0, 0, 1));
		curves.Tint.ColorCount = 1;
		let address = Internal.UnsafeCastToPtr(curves);
		let source = scope FieldPropertySource(typeof(FieldSourceCurves), 1, new (object) => address,
			new (apply) => { apply(0, address); });

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.Count == 2);
		Test.Assert((rows[0].Kind == .Curve) && (rows[0].MaxCount == 4), "its most keys the array's length");
		Test.Assert((rows[1].Kind == .Gradient) && (rows[1].MaxCount == 2), "the smaller stop array's");
		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		source.GetProperties("Size", parts);
		Test.Assert(parts.IsEmpty, "one value, not its fields");

		var size = source.GetValue("Size", 0);
		Test.Assert((size.AsCurve.Length == 2) && (size.AsCurve[1].Value == 0.5f));
		size.Dispose();
		CurveKey[3] three = .(CurveKey(0.0f, 0.0f), CurveKey(0.5f, 2.0f), CurveKey(1.0f, 1.0f));
		source.BeginEdit("Size");
		source.CommitEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(.(&three[0], 3))));
		Test.Assert((curves.Size.KeyCount == 3) && (curves.Size.Keys[1].Value == 2.0f));
		CurveKey[5] five = .(CurveKey(0.0f, 0.0f), CurveKey(0.25f, 1.0f), CurveKey(0.5f, 2.0f), CurveKey(0.75f, 3.0f), CurveKey(1.0f, 4.0f));
		source.BeginEdit("Size");
		source.CommitEdit("Size", PropertyWrite(Sedulous.GUI.Variant.FromCurve(.(&five[0], 5))));
		Test.Assert((curves.Size.KeyCount == 4) && (curves.Size.Keys[3].Value == 3.0f), "kept to the array");

		var tint = source.GetValue("Tint", 0);
		Test.Assert((tint.AsGradient.Colors.Count == 1) && (tint.AsGradient.Colors[0].Color.R == 1.0f) && tint.AsGradient.Alphas.IsEmpty);
		tint.Dispose();
		let wanted = scope ColorGradient();
		wanted.Colors.Add(.(0.0f, Color(0, 0, 1, 1)));
		wanted.Colors.Add(.(1.0f, Color(0, 1, 0, 1)));
		wanted.Alphas.Add(.(0.0f, 1.0f));
		wanted.Alphas.Add(.(0.5f, 0.5f));
		wanted.Alphas.Add(.(1.0f, 0.0f)); // past the array: dropped
		wanted.Interpolation = .OkLab;
		source.BeginEdit("Tint");
		source.CommitEdit("Tint", PropertyWrite(Sedulous.GUI.Variant(wanted)));
		Test.Assert((curves.Tint.ColorCount == 2) && (curves.Tint.Colors[1].Color.G == 1.0f));
		Test.Assert(curves.Tint.AlphaCount == 2, "kept to the array");
		Test.Assert(curves.Tint.Interpolation == .OkLab);
	}

	[Test]
	public static void APrivateFieldMarkedForTheInspectorIsARowAndStaysOutOfFieldJson()
	{
		let steps = scope FieldSourceSteps();
		steps.Steps.Add(4);
		let address = Internal.UnsafeCastToPtr(steps);
		let source = scope FieldPropertySource(typeof(FieldSourceSteps), 1, new (object) => address,
			new (apply) => { apply(0, address); });

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.Count == 2, "the public value and the marked list; the unmarked private not");
		Test.Assert(rows[1].Name == "mSteps");
		Test.Assert(rows[1].DisplayName == "Steps");
		Test.Assert(rows[1].Kind == .List);
		var count = source.GetValue("mSteps", 0);
		Test.Assert(count.AsInt == 1);
		count.Dispose();
		Test.Assert(source.EditList("mSteps", scope ListEdit(.Insert, 1)));
		Test.Assert(steps.Steps.Count == 2);

		// The MCP tools' JSON is unchanged: the public fields alone.
		let json = FieldJson.FieldsJson(typeof(FieldSourceSteps), address);
		defer delete json;
		Test.Assert(json.Has("Count"));
		Test.Assert(!json.Has("mSteps"));
		Test.Assert(!json.Has("mHidden"));
	}

	[Test]
	public static void AFloat4AsAColourIsOneColourAndAGuidListNamesItsElementsTarget()
	{
		let tints = scope FieldSourceTints();
		tints.Meshes.Add(Guid());
		let address = Internal.UnsafeCastToPtr(tints);
		let source = scope FieldPropertySource(typeof(FieldSourceTints), 1, new (object) => address,
			new (apply) => { apply(0, address); });

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(rows.Count == 4);
		Test.Assert(rows[1].Kind == .Color);
		Test.Assert(rows[1].Hint.IsEmpty);
		Test.Assert(rows[1].ShowsAlpha);
		Test.Assert(rows[2].Kind == .Color);
		Test.Assert(!rows[2].ShowsAlpha);
		Test.Assert(rows[3].Kind == .Group, "an unmarked Float4 stays its parts");

		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		source.GetProperties("Tint", parts);
		Test.Assert(parts.IsEmpty, "one value, not its parts");
		var tint = source.GetValue("Tint", 0);
		Test.Assert(Math.Abs(tint.AsColor.G - 0.5f) < 1e-5f);
		Test.Assert(Math.Abs(tint.AsColor.A - 0.75f) < 1e-5f);
		tint.Dispose();

		source.BeginEdit("Tint");
		source.CommitEdit("Tint", PropertyWrite(Sedulous.GUI.Variant(Color(0.1f, 0.2f, 0.3f, 0.4f))));
		Test.Assert(Math.Abs(tints.Tint.Y - 0.2f) < 1e-5f);
		Test.Assert(Math.Abs(tints.Tint.W - 0.4f) < 1e-5f);

		// Copied as a colour, pasted back as one.
		let copied = scope String();
		source.CopyValue("Tint", copied);
		tints.Tint = .(0, 0, 0, 0);
		Test.Assert(source.PasteValue("Tint", copied, scope String()), copied);
		Test.Assert(Math.Abs(tints.Tint.Z - 0.3f) < 1e-5f);

		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		source.GetProperties("Meshes", elements);
		Test.Assert(elements.Count == 1);
		Test.Assert(elements[0].Kind == .Reference);
		Test.Assert(elements[0].ReferenceType == typeof(FieldSourceTarget));
	}

	private static PropertyInfo Row(List<PropertyInfo> rows, StringView name)
	{
		for (let info in rows)
		{
			if (info.Name == name)
				return info;
		}
		Test.Assert(false, "no row");
		return null;
	}

	[Test]
	public static void AnAttributeTheApplicationRegistersHintsItsRows()
	{
		let joint = scope FieldSourceJoint();
		let address = Internal.UnsafeCastToPtr(joint);
		let source = scope FieldPropertySource(typeof(FieldSourceJoint), 1, new (object) => address,
			new (apply) => { apply(0, address); });
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(Row(rows, "Bone").Kind == .String);
		Test.Assert(Row(rows, "Bone").Hint.IsEmpty); // not registered: a string's field

		FieldPropertySource.RegisterHintAttribute<FieldSourceBoneAttribute>("fieldSourceBone");
		ClearAndDeleteItems!(rows);
		source.GetProperties("", rows);
		Test.Assert(Row(rows, "Bone").Kind == .String);
		Test.Assert(Row(rows, "Bone").Hint == "fieldSourceBone");
		Test.Assert(Row(rows, "Label").Hint.IsEmpty); // a string without it
	}

	[Test]
	public static void AConditionThatDoesNotReadHidesNothing()
	{
		let joint = scope FieldSourceJoint();
		let address = Internal.UnsafeCastToPtr(joint);
		let source = scope FieldPropertySource(typeof(FieldSourceJoint), 1, new (object) => address,
			new (apply) => { apply(0, address); });
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		Test.Assert(!Row(rows, "WhenTwo").Visible); // Mode 0
		Test.Assert(Row(rows, "NoName").Visible);
		Test.Assert(Row(rows, "NoValue").Visible);
		Test.Assert(Row(rows, "NotANumber").Visible);
		Test.Assert(Row(rows, "EmptyItem").Visible);
		joint.Mode = 2;
		ClearAndDeleteItems!(rows);
		source.GetProperties("", rows);
		Test.Assert(Row(rows, "WhenTwo").Visible);
	}
}
