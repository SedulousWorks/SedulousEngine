using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.Script.Tests;

/// Script property annotations, `[default, "description"]` in front of a field: only an
/// annotated field is a property, its default and description come from the annotation, an
/// asset reference is a Guid tagged "asset:<Type>", and the builder strips the annotation
/// without moving a line or touching an array or an index.
static class ScriptAnnotationTests
{
	[Test]
	public static void TheAnnotationDeclaresTheDefaultTheDescriptionAndTheAsset()
	{
		let play = scope ScriptPlayScene();
		let tuned = play.Class("Tuned", """
			class Tuned
			{
				[0.5, "Scale, as a fraction [0..1]"] float scale;
				["asset:AudioClip", "Played on a hit"] Guid hitSound;
				[4] private int hidden;
				int[] values;
				float seenScale = -1;
				Guid seenSound;
				void onStart() { values.insertLast(7); seenScale = scale + float(values[0] - 7); seenSound = hitSound; }
			}
			""");
		Test.Assert(tuned.Properties.Count == 3, scope $"{tuned.Properties.Count} properties");
		let scale = tuned.FindProperty("scale");
		Test.Assert((scale.Type == .Float) && (scale.Default.Number == 0.5));
		Test.Assert(scale.Description == "Scale, as a fraction [0..1]", "commas and brackets inside the string stay in it");
		let sound = tuned.FindProperty("hitSound");
		Test.Assert((sound.Type == .Asset) && (sound.AssetType == "AudioClip") && (sound.Description == "Played on a hit"));
		Test.Assert(tuned.FindProperty("hidden").Default.Number == 4, "the annotation, not the access, makes a property");
		Test.Assert((tuned.FindProperty("values") == null) && (tuned.FindProperty("seenScale") == null));

		// At runtime the annotation's default lands with no initialiser in the source, and an
		// asset override arrives as the guid.
		let e = play.AddBehavior(tuned);
		let clip = Guid.Create();
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("hitSound"), .Asset(clip));
		play.Start();
		play.Step();
		Test.Assert(!play.BehaviorOf(e).Faulted);
		Test.Assert(play.PropFloat(e, "seenScale") == 0.5f, scope $"seen {play.PropFloat(e, "seenScale")}");
		Test.Assert(play.Prop(e, "seenSound").AsGuid == clip);
	}

	/// The builder blanks an annotation out rather than removing it, so a compile error after
	/// one still names its own line.
	[Test]
	public static void AnAnnotationDoesNotMoveALine()
	{
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		let runtime = scope AngelScriptRuntime();
		runtime.Bind(surface);
		let compiled = runtime.Compile("m", "Lines.as", """
			class Lines
			{
				[1.0, "One"]
				float one;
				void onStart() { Nope(); }
			}
			""");
		Test.Assert(!compiled);
		bool named = false;
		for (let p in runtime.Problems)
			if (p.Contains("Lines.as") && p.Contains("(5,"))
				named = true;
		Test.Assert(named, "the error names line 5");
		ClearAndDeleteItems!(runtime.Problems);
	}
}
