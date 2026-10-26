using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A reflected root, as Node will be: it declares the virtual its reflected descendants override.
[GuiReflect(true)]
class ReflectedKnob
{
	private String mLabel = new .() ~ delete _;

	[GuiProperty("page")]
	public float Page { get; set; }

	[GuiProperty("label", .Translatable)]
	public StringView Label
	{
		get => mLabel;
		set => mLabel.Set(value);
	}

	[GuiProperty("", .TwoWay, "value")]
	public int32 Clicks { get; set; }

	/// Reflected but read only.
	[GuiProperty("turns")]
	public int32 Turns => 3;

	/// Not reflected: no [GuiProperty].
	public float Hidden { get; set; }

	public virtual GuiTypeInfo GuiType => StaticGuiType;
}

[GuiReflect(true, "fancy-knob")]
class FancyKnob : ReflectedKnob
{
	[GuiProperty("tint-strength")]
	public double TintStrength { get; set; }
}

/// A reflected type markup may not build.
[GuiReflect]
class PlainKnob : ReflectedKnob
{
	public this(int32 turnsAtStart)
	{
		Clicks = turnsAtStart;
	}
}

/// How a knob turns: an enum whose cases the table carries.
enum KnobMode : uint8
{
	Coarse,
	Fine = 4,
}

/// Where a knob clicks: a value struct, its marked fields a group.
struct KnobDetent
{
	[GuiProperty, Range(0.0f, 1.0f, 0.25f), Description("Where it clicks")]
	public float At = 0.5f;
	[GuiProperty("", .NoAlpha)]
	public Color Mark = .(1.0f, 1.0f, 1.0f, 1.0f);
	/// The id of the knob it belongs to, naming the type by name.
	[GuiProperty, GuiReference("PlainKnob")]
	public Guid Owner = .();
	/// Not reflected: no [GuiProperty].
	public float Unmarked = 0.0f;
}

/// A reflected type carrying what an inspector reads: a property's attributes, an enum, lists of
/// values, of structs and of objects, and a value struct.
[GuiReflect(true), DisplayName("Annotated knob")]
class AnnotatedKnob
{
	private List<float> mStops = new .() ~ delete _;
	private List<ReflectedKnob> mChildren = new .() ~ DeleteContainerAndItems!(_);
	private List<KnobDetent> mDetents = new .() ~ delete _;
	private List<KnobMode> mModes = new .() ~ delete _;

	[GuiProperty, DisplayName("Turning"), Description("How far a step goes"), VisibleWhen("Steps=1"), Range(1.0f, 10.0f, 1.0f)]
	public KnobMode Mode { get; set; }

	[GuiProperty("", .BitFlags | .HdrColor)]
	public int32 Steps { get; set; }

	[GuiProperty, GuiList(5)]
	public List<float> Stops => mStops;

	[GuiProperty, GuiList(0, "FancyKnob")]
	public List<ReflectedKnob> Children => mChildren;

	[GuiProperty]
	public KnobDetent Detent { get; set; }

	[GuiProperty]
	public List<KnobDetent> Detents => mDetents;

	[GuiProperty]
	public List<KnobMode> Modes => mModes;

	/// Nothing beyond its type.
	[GuiProperty]
	public float Plain { get; set; }

	/// The id of a knob kept elsewhere: what it points at, by its type's name.
	[GuiProperty, GuiReference("FancyKnob")]
	public Guid Twin { get; set; }
}

/// The compile-time GUI table: a property written down once serves sheets, markup and bindings.
class GuiReflectTests
{
	[Test]
	public static void ATypesTableListsItsMarkedPropertiesWithTheirNamesAndFlags()
	{
		let info = ReflectedKnob.StaticGuiType;
		Test.Assert(info.Type == typeof(ReflectedKnob));
		Test.Assert(info.Tag == "ReflectedKnob");
		Test.Assert(info.Base == null);
		Test.Assert(info.OwnProperties.Length == 4, "the unmarked one is left out");

		let page = info.FindCss("page");
		Test.Assert(page != null);
		Test.Assert(page.Name == "Page");
		Test.Assert(page.ValueType == typeof(float));
		Test.Assert(page.CanWrite);

		let label = info.Find("label");
		Test.Assert(label.IsTranslatable);
		Test.Assert(!label.IsTwoWay);

		let clicks = info.Find("clicks");
		Test.Assert(clicks != null, "by its own name in any case, having no CSS name");
		Test.Assert(clicks.Css.IsEmpty);
		Test.Assert(clicks.IsTwoWay);
		Test.Assert(clicks.Access == "value");
		Test.Assert(info.FindCss("clicks") == null);

		Test.Assert(!info.Find("turns").CanWrite);
		Test.Assert(info.Find("hidden") == null);
	}

	[Test]
	public static void APropertyIsReadAndWrittenThroughItsThunksConverted()
	{
		let knob = scope ReflectedKnob();
		let info = knob.GuiType;
		Test.Assert(info.Find("page").Set(knob, System.Variant.Create(4)), "an int for a float");
		Test.Assert(knob.Page == 4.0f);

		var text = System.Variant.Create(StringView(" 2.5 "));
		defer text.Dispose();
		Test.Assert(info.Find("page").Set(knob, text), "text that reads as a number");
		Test.Assert(knob.Page == 2.5f);

		var word = System.Variant.Create(StringView("many"));
		defer word.Dispose();
		Test.Assert(!info.Find("page").Set(knob, word));
		Test.Assert(knob.Page == 2.5f, "a value that does not convert changes nothing");

		Test.Assert(info.Find("label").Set(knob, System.Variant.Create(7)));
		Test.Assert(knob.Label == "7", "anything formats to text");

		var read = info.Find("label").Get(knob);
		knob.Label = "changed";
		Test.Assert(TextOf(read) == "7", "a read is its own copy");
		read.Dispose();

		var page = info.Find("page").Get(knob);
		Test.Assert(page.Get<float>() == 2.5f);
		Test.Assert(!info.Find("turns").Set(knob, System.Variant.Create(9)), "read only");
	}

	[Test]
	public static void ADerivedTypeChainsToItsBaseAndAnswersForItself()
	{
		let fancy = scope FancyKnob();
		ReflectedKnob asBase = fancy;
		Test.Assert(asBase.GuiType == FancyKnob.StaticGuiType, "an instance answers for its most derived type");
		let info = FancyKnob.StaticGuiType;
		Test.Assert(info.Tag == "fancy-knob");
		Test.Assert(info.Base == ReflectedKnob.StaticGuiType);
		Test.Assert(info.Is(ReflectedKnob.StaticGuiType));
		Test.Assert(!ReflectedKnob.StaticGuiType.Is(info));
		Test.Assert(info.OwnProperties.Length == 1);
		Test.Assert(info.FindCss("page") != null, "its base's properties are found through it");
		Test.Assert(info.Find("clicks") != null, "by their own names too");

		Test.Assert(info.FindCss("tint-strength").Set(fancy, System.Variant.Create(0.75f)));
		Test.Assert(fancy.TintStrength == 0.75);
	}

	[Test]
	public static void MarkupBuildsOnlyATypeWithACreator()
	{
		Test.Assert(FancyKnob.StaticGuiType.CanCreate);
		let made = FancyKnob.StaticGuiType.Create();
		defer delete made;
		Test.Assert(made is FancyKnob);
		Test.Assert(!PlainKnob.StaticGuiType.CanCreate);
		Test.Assert(PlainKnob.StaticGuiType.Create() == null);
	}

	[Test]
	public static void AMembersAttributesRideInItsRecord()
	{
		let info = AnnotatedKnob.StaticGuiType;
		Test.Assert(info.DisplayName == "Annotated knob");
		Test.Assert(ReflectedKnob.StaticGuiType.DisplayName.IsEmpty);
		let mode = info.Find("Mode");
		Test.Assert(mode.DisplayName == "Turning");
		Test.Assert(mode.Description == "How far a step goes");
		Test.Assert(mode.VisibleWhen == "Steps=1");
		Test.Assert(mode.HasRange);
		Test.Assert(mode.Min == 1.0f);
		Test.Assert(mode.Max == 10.0f);
		Test.Assert(mode.Step == 1.0f);
		let steps = info.Find("Steps");
		Test.Assert(steps.Flags.HasFlag(.BitFlags) && steps.Flags.HasFlag(.HdrColor) && !steps.Flags.HasFlag(.NoAlpha));
		Test.Assert(steps.DisplayName.IsEmpty && steps.Description.IsEmpty && !steps.HasRange);
		Test.Assert(info.Find("Plain").Value == null, "a value that is only its type carries nothing more");
	}

	[Test]
	public static void AnEnumsCasesAsDeclared()
	{
		let cases = AnnotatedKnob.StaticGuiType.Find("Mode").Value.Cases;
		Test.Assert(cases.Length == 2);
		Test.Assert(cases[0].Name == "Coarse");
		Test.Assert(cases[0].Value == 0);
		Test.Assert(cases[1].Name == "Fine");
		Test.Assert(cases[1].Value == 4);
		let modes = AnnotatedKnob.StaticGuiType.Find("Modes").Value.ListInfo;
		Test.Assert(modes.ElementType == typeof(KnobMode));
		Test.Assert(modes.Element.Cases.Length == 2, "a list's elements carry their enum's cases");
	}

	[Test]
	public static void AListOfValuesThroughItsThunksAtMostItsMost()
	{
		let knob = scope AnnotatedKnob();
		let list = AnnotatedKnob.StaticGuiType.Find("Stops").Value.ListInfo;
		Test.Assert(list.ElementType == typeof(float));
		Test.Assert(list.MaxCount == 5);
		Test.Assert(!list.HoldsObjects);
		Test.Assert(list.Element == null);
		for (int i < 5)
			Test.Assert(list.Insert(knob.Stops, list.Count(knob.Stops)));
		Test.Assert(list.IsFull(knob.Stops));
		Test.Assert(!list.Insert(knob.Stops, 0), "full");
		Test.Assert(list.SetAt(knob.Stops, 1, System.Variant.Create(2.5)), "a double for a float");
		Test.Assert(knob.Stops[1] == 2.5f);
		var read = list.GetAt(knob.Stops, 1);
		Test.Assert(read.Get<float>() == 2.5f);
		read.Dispose();
		list.Move(knob.Stops, 1, 0);
		Test.Assert(knob.Stops[0] == 2.5f);
		list.RemoveAt(knob.Stops, 0);
		Test.Assert(knob.Stops.Count == 4);
		Test.Assert(knob.Stops[0] == 0.0f);
	}

	[Test]
	public static void AListOfObjectsMakesTheTypesItNamesAndLetsGoOfOneRemoved()
	{
		let knob = scope AnnotatedKnob();
		let list = AnnotatedKnob.StaticGuiType.Find("Children").Value.ListInfo;
		Test.Assert(list.HoldsObjects);
		Test.Assert(list.ElementTable == ReflectedKnob.StaticGuiType);
		let types = scope List<GuiTypeInfo>();
		list.GetTypes(types);
		Test.Assert(types.Count == 1);
		Test.Assert(types[0] == FancyKnob.StaticGuiType);
		Test.Assert(!list.Insert(knob.Children, 0), "an object is made by a type, not a default");
		Test.Assert(list.InsertObject(knob.Children, 0, types[0].Create()));
		Test.Assert(knob.Children[0] is FancyKnob);
		let wrong = new GuiTypeInfo(typeof(int), "", null);
		Test.Assert(!list.InsertObject(knob.Children, 0, wrong), "not of the list's type");
		delete wrong;
		var held = list.GetAt(knob.Children, 0);
		Test.Assert(held.Get<Object>() === knob.Children[0], "by reference");
		held.Dispose();
		Test.Assert(!list.SetAt(knob.Children, 0, System.Variant.Create(knob, false)), "an object is never replaced");
		list.RemoveAt(knob.Children, 0); // deleted: the leak check says so
		Test.Assert(knob.Children.IsEmpty);
	}

	[Test]
	public static void AValueStructsMarkedFieldsThroughAPointerToACopy()
	{
		let detent = AnnotatedKnob.StaticGuiType.Find("Detent").Value;
		Test.Assert(detent.IsStruct);
		Test.Assert(detent.Fields.Length == 3, "the unmarked one is left out");
		let at = detent.FindField("at");
		Test.Assert(at != null, "by its name in any case");
		Test.Assert(at.ValueType == typeof(float));
		Test.Assert(at.HasRange && (at.Max == 1.0f) && (at.Step == 0.25f));
		Test.Assert(at.Description == "Where it clicks");
		Test.Assert(detent.FindField("Mark").Flags.HasFlag(.NoAlpha));

		let knob = scope AnnotatedKnob();
		var copy = knob.Detent;
		copy.At = 0.5f;
		var read = at.Get(&copy);
		Test.Assert(read.Get<float>() == 0.5f);
		read.Dispose();
		Test.Assert(at.Set(&copy, System.Variant.Create(0.75f)));
		Test.Assert(copy.At == 0.75f);
		knob.Detent = copy;
		Test.Assert(knob.Detent.At == 0.75f);

		let detents = AnnotatedKnob.StaticGuiType.Find("Detents").Value.ListInfo;
		Test.Assert(detents.Element.IsStruct, "a list's struct elements carry their fields");
		Test.Assert(detents.Insert(knob.Detents, 0));
		Test.Assert(knob.Detents[0].At == 0.5f, "a new element is made by its constructor, its initializers run");
	}

	[Test]
	public static void AGuidMembersReferenceTypeRidesInItsRecordResolvedWhereItIsDeclared()
	{
		let info = AnnotatedKnob.StaticGuiType;
		let twin = info.Find("Twin");
		Test.Assert(twin.ValueType == typeof(Guid));
		Test.Assert(twin.ReferenceType == typeof(FancyKnob));
		Test.Assert(info.Find("Plain").ReferenceType == null, "a member that names nothing");
		let owner = info.Find("Detent").Value.FindField("Owner");
		Test.Assert(owner.ValueType == typeof(Guid));
		Test.Assert(owner.ReferenceType == typeof(PlainKnob), "a value struct's field carries it too");
	}
}
