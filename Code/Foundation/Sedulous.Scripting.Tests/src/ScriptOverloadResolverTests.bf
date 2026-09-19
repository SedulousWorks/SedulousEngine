using System;
using Sedulous.Core;
using Sedulous.Scripting;
using Sedulous.Scripting.Fixture;

namespace Sedulous.Scripting.Tests;

/// Picking a callable from the table for what a script actually passed.
static class ScriptOverloadResolverTests
{
	private const String cFixture = "Sedulous.Scripting.Fixture";

	[Test]
	public static void AnExactKindWinsOverAPromotion()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let thing = s.Find(scope $"{cFixture}.Thing");
		let error = scope String();

		// Twice(int) and Twice(float): an Int argument is exact on one, a promotion on the other.
		var intArg = ScriptValue[1](.FromInt(4));
		let picked = ScriptOverloadResolver.Resolve(thing, "Twice", false, intArg, error);
		Test.Assert((picked != null) && (picked.Params[0].Kind == .Int), error);

		var floatArg = ScriptValue[1](.FromFloat(1.5));
		let pickedF = ScriptOverloadResolver.Resolve(thing, "Twice", false, floatArg, error);
		Test.Assert((pickedF != null) && (pickedF.Params[0].Kind == .Float));

		// And the picked one runs with the promotion applied.
		let ctx = scope ScratchCallContext();
		let made = scope Thing();
		var frame = ScriptCallFrame(ctx, intArg);
		frame.Self = .FromObject(made);
		pickedF.Invoke(ref frame);
		Test.Assert(!frame.Failed && (frame.Result.Kind == .Float) && (frame.Result.AsFloat == 8.0));
	}

	[Test]
	public static void ArityFollowsTheDefaults()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let thing = s.Find(scope $"{cFixture}.Thing");
		let error = scope String();

		// Move(to, speed = 1.5f, teleport = false): one to three arguments.
		var to = Vec2(1, 1);
		var one = ScriptValue[1](.FromStruct(&to, typeof(Vec2)));
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Move", false, one, error) != null, error);
		var three = ScriptValue[3](.FromStruct(&to, typeof(Vec2)), .FromInt(2), .FromBool(true));
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Move", false, three, error) != null, "Int promotes into speed");
		var four = ScriptValue[4](.FromStruct(&to, typeof(Vec2)), .FromInt(2), .FromBool(true), .FromBool(true));
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Move", false, four, error) == null);
		Test.Assert(error.Contains("4 arguments"));

		// Go() and GoTo(Vec2) are different script names, not an arity family.
		error.Clear();
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Go", false, one, error) == null);
	}

	[Test]
	public static void MismatchesAndUnknownsSayWhy()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let thing = s.Find(scope $"{cFixture}.Thing");
		let error = scope String();

		var text = ScriptValue[1](.FromString("x"));
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Twice", false, text, error) == null);
		Test.Assert(error.Contains("Twice"));

		error.Clear();
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Nope", false, text, error) == null);
		Test.Assert(error.Contains("has no Nope"));

		// Staticness is part of the name: Make is static.
		error.Clear();
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Make", false, default, error) == null);
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Make", true, default, error) != null);

		// A struct argument is typed: the wrong struct is no match, a null pointer neither.
		var wrong = Guid();
		var wrongArg = ScriptValue[1](.FromStruct(&wrong, typeof(Guid)));
		let vec = s.Find(scope $"{cFixture}.Vec2");
		Test.Assert(ScriptOverloadResolver.Resolve(vec, "Dot", true, wrongArg, error) == null);
		var nullArg = ScriptValue[2](.FromStruct(null, typeof(Vec2)), .FromStruct(null, typeof(Vec2)));
		Test.Assert(ScriptOverloadResolver.Resolve(vec, "Dot", true, nullArg, error) == null);
	}

	[Test]
	public static void AnObjectMatchesItsTypeOrABaseAndNilIsNull()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let thing = s.Find(scope $"{cFixture}.Thing");
		let error = scope String();

		// A derived object fills a Thing slot; an unrelated one does not; nil is null.
		var derived = ScriptValue[1](.FromObject(scope Derived()));
		var other = ScriptValue[1](.FromObject(scope Object()));
		var nil = ScriptValue[1](.Nil);
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Follow", false, derived, error) != null, error);
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Follow", false, other, error) == null);
		Test.Assert(ScriptOverloadResolver.Resolve(thing, "Follow", false, nil, error) != null);
	}

	private class Derived : Thing {}
}
