using System;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Pipeline.Importer;
using Sedulous.ModelImporter;

namespace Sedulous.ModelImporter.Tests;

/// A model's Scale and Up axis at import: each root node and the keys that move it are scaled and
/// turned before the import fans out, and the scale's note says how tall the model comes in.
class ModelImportFrameTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void ScaleAndUpAxisMoveEachRootNodeAndTheKeysThatMoveItAChildKeepsItsOwn()
	{
		let model = scope Model();
		let root = new ModelBone();
		root.Name.Set("Root");
		root.Translation = .(0.0f, 0.0f, 1.0f); // one unit along the file's Z, its up
		model.AddBone(root);
		let child = new ModelBone();
		child.Name.Set("Child");
		child.ParentIndex = root.Index;
		child.Translation = .(0.0f, 0.0f, 1.0f);
		model.AddBone(child);
		let clip = new ModelAnimation();
		let moves = new AnimationChannel();
		moves.TargetBone = root.Index;
		moves.Path = .Translation;
		moves.AddKeyframe(0.0f, .(0.0f, 0.0f, 2.0f, 0.0f));
		clip.AddChannel(moves);
		let childMoves = new AnimationChannel();
		childMoves.TargetBone = child.Index;
		childMoves.Path = .Translation;
		childMoves.AddKeyframe(0.0f, .(0.0f, 0.0f, 2.0f, 0.0f));
		clip.AddChannel(childMoves);
		model.AddAnimation(clip);

		ModelImportFrame.Apply(model, 2.0f, .Z);
		// Z up is turned to Y up, and every root length doubled.
		Test.Assert(Near(root.Translation.X, 0.0f));
		Test.Assert(Near(root.Translation.Y, 2.0f));
		Test.Assert(Near(root.Translation.Z, 0.0f));
		Test.Assert(Near(root.Scale.X, 2.0f));
		Test.Assert(Near(moves.Keyframes[0].Value.Y, 4.0f));
		// A child sits in its parent's space, so it keeps its own transform and keys.
		Test.Assert(Near(child.Translation.Z, 1.0f));
		Test.Assert(Near(childMoves.Keyframes[0].Value.Z, 2.0f));

		// 1 and Y change nothing; a scale of zero is taken as 1.
		ModelImportFrame.Apply(model, 0.0f, .Y);
		Test.Assert(Near(root.Translation.Y, 2.0f));
		Test.Assert(Near(root.Scale.X, 2.0f));
	}

	[Test]
	public static void TheScalesNoteSaysHowTallTheModelComesIn()
	{
		let importer = scope ModelFileImporter();
		let prepared = scope LoadedModel();
		prepared.Model.Bounds = .(.(0.0f, 0.0f, 0.0f), .(1.0f, 79.0f, 4.0f)); // 79 units tall, 4 deep
		let options = scope ModelImportOptions();
		options.Scale = 0.01f;
		Test.Assert(options.FindSetting("Scale", let scale));
		Test.Assert(options.FindSetting("Textures", let textures));
		let effect = scope String();
		let reason = scope String();
		importer.DescribeSetting("fox.gltf", options, prepared, scale, effect, reason);
		Test.Assert(effect == "Makes it 0.790 m tall", scope String(effect));
		Test.Assert(reason.IsEmpty);

		// Z up: the height is the file's Z.
		options.UpAxis = .Z;
		options.Scale = 1.0f;
		importer.DescribeSetting("fox.gltf", options, prepared, scale, effect..Clear(), reason);
		Test.Assert(effect == "Makes it 4.00 m tall", scope String(effect));

		importer.DescribeSetting("fox.gltf", options, prepared, textures, effect..Clear(), reason);
		Test.Assert(effect.IsEmpty);
		importer.DescribeSetting("fox.gltf", options, null, scale, effect..Clear(), reason);
		Test.Assert(effect.IsEmpty, "nothing read, nothing to say");
	}
}
