using System;
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
		Test.Assert(info.Find("page").Set(knob, Variant.Create(4)), "an int for a float");
		Test.Assert(knob.Page == 4.0f);

		var text = Variant.Create(StringView(" 2.5 "));
		defer text.Dispose();
		Test.Assert(info.Find("page").Set(knob, text), "text that reads as a number");
		Test.Assert(knob.Page == 2.5f);

		var word = Variant.Create(StringView("many"));
		defer word.Dispose();
		Test.Assert(!info.Find("page").Set(knob, word));
		Test.Assert(knob.Page == 2.5f, "a value that does not convert changes nothing");

		Test.Assert(info.Find("label").Set(knob, Variant.Create(7)));
		Test.Assert(knob.Label == "7", "anything formats to text");

		var read = info.Find("label").Get(knob);
		knob.Label = "changed";
		Test.Assert(TextOf(read) == "7", "a read is its own copy");
		read.Dispose();

		var page = info.Find("page").Get(knob);
		Test.Assert(page.Get<float>() == 2.5f);
		Test.Assert(!info.Find("turns").Set(knob, Variant.Create(9)), "read only");
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

		Test.Assert(info.FindCss("tint-strength").Set(fancy, Variant.Create(0.75f)));
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
}
