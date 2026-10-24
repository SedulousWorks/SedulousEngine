using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @media conditions evaluated against a MediaContext: one feature, a conjunction, height, the
/// empty query, orientation, `not`, comma lists and media types.
class MediaQueryTests
{
	private static bool Matches(StringView query, MediaContext context)
	{
		let q = scope MediaQuery(query);
		return q.Evaluate(context);
	}

	[Test]
	public static void SingleFeature()
	{
		let mq = scope MediaQuery("(min-width: 600px)");
		Test.Assert(mq.FeatureCount == 1);
		Test.Assert(mq.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(400.0f, 0.0f, 96.0f)));
		Test.Assert(mq.Evaluate(.(600.0f, 0.0f, 96.0f))); // inclusive
	}

	[Test]
	public static void ConjunctionAnd()
	{
		let mq = scope MediaQuery("(min-width: 600px) and (max-width: 900px)");
		Test.Assert(mq.FeatureCount == 2);
		Test.Assert(mq.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(1000.0f, 0.0f, 96.0f))); // over max
		Test.Assert(!mq.Evaluate(.(500.0f, 0.0f, 96.0f))); // under min
	}

	[Test]
	public static void HeightFeatures()
	{
		let mq = scope MediaQuery("(max-height: 480px)");
		Test.Assert(mq.Evaluate(.(0.0f, 400.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(0.0f, 600.0f, 96.0f)));
	}

	[Test]
	public static void EmptyAlwaysMatches()
	{
		let empty = scope MediaQuery();
		Test.Assert(empty.IsEmpty);
		Test.Assert(empty.Evaluate(.(0.0f, 0.0f, 0.0f)));
	}

	[Test]
	public static void OrientationNotCommaListsAndMediaTypes()
	{
		let wide = MediaContext(800.0f, 600.0f, 96.0f);
		let tall = MediaContext(600.0f, 800.0f, 96.0f);
		Test.Assert(Matches("(orientation: landscape)", wide));
		Test.Assert(!Matches("(orientation: landscape)", tall));
		Test.Assert(Matches("(orientation: portrait)", tall));
		Test.Assert(Matches("not (orientation: portrait)", wide));
		Test.Assert(!Matches("not all and (min-width: 700px)", wide));
		Test.Assert(Matches("screen and (max-width: 500px), (orientation: portrait)", tall)); // the second
		Test.Assert(!Matches("screen and (max-width: 500px), (orientation: portrait)", wide));
		Test.Assert(!Matches("print", wide));
		Test.Assert(!Matches("not (hover: hover)", wide)); // a feature it cannot test: not either
		Test.Assert(Matches("(hover: hover), (min-width: 1px)", wide)); // another in the list still can
	}
}
