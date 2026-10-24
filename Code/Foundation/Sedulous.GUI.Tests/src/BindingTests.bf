using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Bindings: a node's bindings follow what they read, on the GUI's frame; any reflected property
// binds by name, converted to its type; a widget's user-set state writes back; the GUI's data model
// holds named values; nothing subscribes by hand.

/// The conversions bindings make between values and properties' types, and a text field written
/// back.
class BindingTests
{
	[Test]
	public static void ValuesConvertToThePropertysTypeAndCompareAcrossNumbers()
	{
		let text = scope String();
		FormatVariant(System.Variant.Create(3.0), text);
		Test.Assert(text == "3");
		text.Clear();
		FormatVariant(System.Variant.Create(0.25f), text);
		Test.Assert(text == "0.25");
		text.Clear();
		FormatVariant(System.Variant.Create(0.4f), text);
		Test.Assert(text == "0.4"); // not 0.4000000059604645
		text.Clear();
		FormatVariant(System.Variant.Create(2.0f), text);
		Test.Assert(text == "2");
		text.Clear();
		FormatVariant(System.Variant.Create(true), text);
		Test.Assert(text == "true");
		var f = ConvertVariant(System.Variant.Create(0.5), typeof(float));
		defer f.Dispose();
		Test.Assert(f.VariantType == typeof(float));
		Test.Assert(NodeFixtures.Near(f.Get<float>(), 0.5f));
		var spaced = TextVariant(" 42 ");
		defer spaced.Dispose();
		var i = ConvertVariant(spaced, typeof(int32));
		defer i.Dispose();
		Test.Assert(i.VariantType == typeof(int32));
		Test.Assert(i.Get<int32>() == 42);
		var word = TextVariant("abc");
		defer word.Dispose();
		var none = ConvertVariant(word, typeof(float));
		defer none.Dispose();
		Test.Assert(!none.HasValue);
		Test.Assert(VariantsEqual(System.Variant.Create((int32)2), System.Variant.Create(2.0)));
		var two = TextVariant("2");
		defer two.Dispose();
		Test.Assert(!VariantsEqual(System.Variant.Create((int32)2), two));
	}

	[Test]
	public static void ATextFieldWrittenBackKeepsItsCaret()
	{
		let field = new TextField();
		defer field.ReleaseRef();
		field.Text = "hello";
		field.Caret = 2;
		field.Text = "hello"; // a binding writing back what was typed
		Test.Assert(field.Caret == 2);
	}
}
