using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A GUI's named values and the conversions bindings use. Raptor's tests of them need markup and
/// bindings (BindingTests), so these check the model itself until those land.
class DataModelTests
{
	[Test]
	public static void ANameReadBeforeItIsSetIsFollowedAndTakesItsFirstValue()
	{
		let model = new DataModel();
		defer model.ReleaseRef();
		double seen = -1.0;
		let effect = scope Effect(new [&]() => { seen = NumberOf(model.Get("score"), let n) ? n : -1.0; });
		Test.Assert(seen == -1.0);
		Test.Assert(!model.Has("score"));
		Test.Assert(model.Set("score", System.Variant.Create(5)));
		Test.Assert(seen == 5.0);
		Test.Assert(model.Has("score"));
		Test.Assert(effect.RunCount == 2);
	}

	/// Writing back what was just read is no change, whatever numeric type it comes back as.
	[Test]
	public static void TheSameNumberInAnotherTypeIsNoChange()
	{
		let model = new DataModel();
		defer model.ReleaseRef();
		Test.Assert(model.Set("volume", System.Variant.Create(3)));
		Test.Assert(!model.Set("volume", System.Variant.Create(3.0f)));
		Test.Assert(!model.Set("volume", System.Variant.Create(3.0)));
		Test.Assert(model.Set("volume", System.Variant.Create(4.5)));
	}

	/// The model keeps its own copy of text: the caller's string may go.
	[Test]
	public static void TheModelKeepsItsOwnCopyOfText()
	{
		let model = new DataModel();
		defer model.ReleaseRef();
		let name = new String("Ada");
		var given = System.Variant.Create(name, true);
		model.Set("player", given);
		given.Dispose();
		Test.Assert(TextOf(model.Get("player")) == "Ada");
		var view = System.Variant.Create(StringView("Ada"));
		defer view.Dispose();
		Test.Assert(!model.Set("player", view));
		Test.Assert(TextOf(model.Peek("player")) == "Ada");
	}

	[Test]
	public static void AValueFormatsAsText()
	{
		let text = scope String();
		FormatVariant(System.Variant.Create(12), text);
		Test.Assert(text == "12");
		text.Clear();
		FormatVariant(System.Variant.Create(12.0), text);
		Test.Assert(text == "12", "a whole number has no fraction");
		text.Clear();
		FormatVariant(System.Variant.Create(0.4f), text);
		Test.Assert(text == "0.4", text);
		text.Clear();
		FormatVariant(System.Variant.Create(2.5), text);
		Test.Assert(text == "2.5", text);
		text.Clear();
		FormatVariant(System.Variant.Create(true), text);
		Test.Assert(text == "true");
		text.Clear();
		FormatVariant(default, text);
		Test.Assert(text.IsEmpty);
	}

	[Test]
	public static void AValueConvertsToAPropertysType()
	{
		var asFloat = ConvertVariant(System.Variant.Create(3), typeof(float));
		defer asFloat.Dispose();
		Test.Assert(asFloat.Get<float>() == 3.0f);

		var text = System.Variant.Create(StringView(" 2.6 "));
		defer text.Dispose();
		var fromText = ConvertVariant(text, typeof(int32));
		defer fromText.Dispose();
		Test.Assert(fromText.Get<int32>() == 3, "to the nearest");

		var no = System.Variant.Create(StringView("false"));
		defer no.Dispose();
		var flag = ConvertVariant(no, typeof(bool));
		defer flag.Dispose();
		Test.Assert(flag.Get<bool>() == false);

		var label = ConvertVariant(System.Variant.Create(7), typeof(String));
		defer label.Dispose();
		Test.Assert(TextOf(label) == "7");

		var word = System.Variant.Create(StringView("seven"));
		defer word.Dispose();
		var never = ConvertVariant(word, typeof(int32));
		Test.Assert(!never.HasValue);

		var unsigned = ConvertVariant(System.Variant.Create(-4), typeof(uint32));
		Test.Assert(unsigned.Get<uint32>() == 0);
	}

	[Test]
	public static void ATweenClaimsAName()
	{
		let model = new DataModel();
		defer model.ReleaseRef();
		Test.Assert(model.TweenOwnerOf("x") == 0);
		model.ClaimTween("x", 7);
		Test.Assert(model.TweenOwnerOf("x") == 7);
	}

	/// A copy of a borrowed view (what Get hands out) holds the value, not where it was.
	[Test]
	public static void ACopyOfAReadHoldsTheValueItself()
	{
		let model = new DataModel();
		defer model.ReleaseRef();
		model.Set("volume", System.Variant.Create(0.5));
		var four = System.Variant.Create(Float4(1.0f, 2.0f, 3.0f, 4.0f));
		defer four.Dispose(); // the caller keeps what it gives the model
		model.Set("big", four);
		var small = CopyVariant(model.Get("volume"));
		defer small.Dispose();
		Test.Assert(small.Get<double>() == 0.5);
		var wide = CopyVariant(model.Get("big"));
		defer wide.Dispose();
		var zero = System.Variant.Create(Float4(0.0f, 0.0f, 0.0f, 0.0f));
		defer zero.Dispose();
		model.Set("big", zero);
		Test.Assert(wide.Get<Float4>().W == 4.0f, "its own copy, not a view of the model's");
		var converted = ConvertVariant(model.Get("volume"), typeof(double));
		defer converted.Dispose();
		Test.Assert(converted.Get<double>() == 0.5);
	}
}
