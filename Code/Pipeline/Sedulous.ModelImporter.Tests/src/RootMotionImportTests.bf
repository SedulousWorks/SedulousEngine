using System;
using Sedulous.Animation.Pipeline;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Pipeline.Importer;
using Sedulous.ModelImporter;

namespace Sedulous.ModelImporter.Tests;

/// The import side of root motion (root-motion.md P0): the armature node (the skeleton's
/// parent) animated in the file keeps its channels as model tracks (bone minus one), the clip
/// names its skeleton and the armature's rest for the root motion cook, and root motion settings
/// authored on a clip survive a re-import while a clip new to it takes the import's option.
class RootMotionImportTests
{
	private static Quaternion Turn => Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f);

	private static void Prepare(Model model, bool withRun)
	{
		let armature = new ModelBone();
		armature.Name.Set("Armature");
		armature.Rotation = Turn;
		model.AddBone(armature);
		let hips = new ModelBone();
		hips.Name.Set("Hips");
		hips.ParentIndex = 0;
		model.AddBone(hips);
		let skin = new ModelSkin();
		skin.Name.Set("skeleton");
		skin.AddJoint(1, Float4x4.Identity());
		model.AddSkin(skin);
		StringView[2] names = .("Walk", "Run");
		for (let name in names)
		{
			if ((name == "Run") && !withRun)
				continue;
			let animation = new ModelAnimation();
			animation.Name.Set(name);
			let onHips = new AnimationChannel();
			onHips.TargetBone = 1;
			onHips.Path = .Translation;
			onHips.AddKeyframe(0.0f, .(0, 1, 0, 0));
			onHips.AddKeyframe(1.0f, .(0, 1, 0.1f, 0));
			animation.AddChannel(onHips);
			let onArmature = new AnimationChannel();
			onArmature.TargetBone = 0;
			onArmature.Path = .Translation;
			onArmature.AddKeyframe(0.0f, .(0, 0, 0, 0));
			onArmature.AddKeyframe(1.0f, .(0, 0, 2, 0));
			animation.AddChannel(onArmature);
			animation.CalculateDuration();
			model.AddAnimation(animation);
		}
	}

	private static AnimationClipAsset ReadClip(Group group, StringView name)
	{
		let instance = group.GetInstance(name);
		Test.Assert(instance != null, scope $"no clip '{name}'");
		return instance.ReadObject() as AnimationClipAsset;
	}

	[Test]
	public static void AClipKeepsTheArmaturesChannelsItsSkeletonAndRestAndARe_ImportKeepsItsRootMotion()
	{
		let fixture = scope ImportFixture("scratch_model_root_motion");
		let dropped = scope String();
		fixture.WriteDroppedFile("walker.glb", "x", dropped);
		let importer = scope ModelFileImporter();

		let prepared = scope LoadedModel();
		Prepare(prepared.Model, false);
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null, prepared, null);
		Test.Assert(imported case .Ok);
		let group = imported.Value.OwningGroup;
		{
			let walk = ReadClip(group, "Walk");
			Test.Assert(walk != null);
			defer delete walk;
			var modelTracks = 0;
			for (let bone in walk.Source.TrackBone)
				modelTracks += (bone < 0) ? 1 : 0;
			Test.Assert(modelTracks == 1, "the armature's translation");
			Test.Assert(walk.Source.TrackBone.Count == 2);
			Test.Assert(!walk.Skeleton.IsNil);
			let skeleton = group.GetInstance("skeleton");
			Test.Assert((skeleton != null) && (walk.Skeleton == skeleton.Id));
			Test.Assert(Math.Abs(Dot(walk.RestRotation, Turn)) > 1.0f - 1.0e-5f);
			Test.Assert(!walk.Source.RootMotionAny, "off unless asked");

			// Authored on the clip, kept by a re-import.
			walk.Source.RootHorizontal = true;
			walk.Source.RootBone.Set("Hips");
			Test.Assert(group.GetInstance("Walk").WriteObject(walk) case .Ok);
		}

		let options = scope ModelImportOptions();
		options.RootMotion = true;
		let again = scope LoadedModel();
		Prepare(again.Model, true);
		let reimported = importer.Import(dropped, fixture.Context, fixture.RootGroup, options, again, null);
		Test.Assert(reimported case .Ok);
		{
			let kept = ReadClip(group, "Walk");
			Test.Assert(kept != null);
			defer delete kept;
			Test.Assert(kept.Source.RootHorizontal);
			Test.Assert(!kept.Source.RootYaw, "the clip's, not the option's");
			Test.Assert(kept.Source.RootBone == "Hips");
		}
		{
			// A clip new to the import takes the option.
			let run = ReadClip(group, "Run");
			Test.Assert(run != null);
			defer delete run;
			Test.Assert(run.Source.RootHorizontal);
			Test.Assert(run.Source.RootYaw);
		}
	}
}
