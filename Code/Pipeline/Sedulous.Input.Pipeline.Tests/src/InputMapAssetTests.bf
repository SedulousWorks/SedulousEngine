using System;
using Sedulous.Input;

namespace Sedulous.Input.Pipeline.Tests;

/// The authored input map.
class InputMapAssetTests
{
	/// The editor page never opens on a void: a fresh asset carries one gameplay set with the
	/// four actions nearly every game has, their bindings left for the author.
	///
	/// Raptor's case reaches this through its reflection tables, proving the tree is
	/// traversable. Beef's reflection is the language's own and needs no registration, so what
	/// is left to measure is the CONTENT, which is what the tree was being walked for.
	[Test]
	public static void AFreshAssetSeedsTheConventionalStarterSet()
	{
		let asset = scope InputMapAsset();
		Test.Assert(asset.Map.Sets.IsEmpty);

		asset.SeedDefaultContent();
		Test.Assert(asset.Map.Sets.Count == 1);

		let gameplay = asset.Map.Sets[0];
		Test.Assert(gameplay.Name == "Gameplay");
		Test.Assert(gameplay.Actions.Count == 4);

		let names = scope String[]("Move", "Look", "Jump", "Fire");
		let kinds = scope ActionKind[](.Axis2D, .Axis2D, .Button, .Button);
		for (int i < 4)
		{
			Test.Assert(gameplay.Actions[i].Name == names[i]);
			Test.Assert(gameplay.Actions[i].Kind == kinds[i]);
			// Bindings are the author's to fill in.
			Test.Assert(gameplay.Actions[i].Bindings.IsEmpty);
		}
	}
}
