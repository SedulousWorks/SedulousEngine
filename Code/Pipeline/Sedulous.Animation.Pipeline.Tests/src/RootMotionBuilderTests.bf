using System;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Animation.Pipeline.Tests;

/// The clip builder's root motion cook (root-motion.md P0): the clip names its root bone, the
/// builder resolves it against the skeleton the clip addresses (read from the SOURCE database,
/// and declared as a read so a changed skeleton re-cooks the clip), bakes the travel and strips
/// it from the cooked pose; the authored clip is untouched.
class RootMotionBuilderTests
{
	private const String cRoot = "scratch_anim_root_motion";

	[Test]
	public static void TheBuilderBakesRootMotionFromANamedRootThroughTheClipsSkeleton()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		AnimationResources.RegisterAll();
		AnimationPipeline.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = scope ContentDatabase(mount, serializers, "rasset");

		let skeleton = scope SkeletonAsset();
		skeleton.Source.BoneName.Add(new String("root"));
		skeleton.Source.BoneName.Add(new String("hips"));
		skeleton.Source.ParentIndex.Add(-1);
		skeleton.Source.ParentIndex.Add(0);
		let skelInst = db.RootGroup.CreateInstance("skel", typeof(SkeletonAsset).GetFullName(.. scope .()));
		Test.Assert(skelInst.WriteObject(skeleton) case .Ok);

		let walk = scope AnimationClipAsset();
		walk.Skeleton = skelInst.Id;
		walk.Source.Name.Set("Walk");
		walk.Source.Duration = 1.0f;
		walk.Source.TrackBone.Add(1); // the hips
		walk.Source.TrackKindValue.Add((uint8)TrackKind.Position);
		walk.Source.TrackInterp.Add((uint8)InterpolationMode.Linear);
		walk.Source.TrackStart.Add(0);
		walk.Source.TrackCount.Add(2);
		walk.Source.KeyTime.Add(0.0f);
		walk.Source.KeyTime.Add(1.0f);
		walk.Source.KeyValue.Add(.(0, 1, 0, 0));
		walk.Source.KeyValue.Add(.(0, 1, 2, 0));
		walk.Source.RootBone.Set("hips");
		walk.Source.RootHorizontal = true;

		let builder = scope AnimationClipAssetBuilder();
		Test.Assert(builder.Version >= 2, "every clip re-cooks into the new layout");
		let context = scope AssetBuildContext();
		let deps = scope AssetDependencies();
		builder.ScanDependencies(walk, context, deps);
		Test.Assert((deps.Reads.Count == 1) && (deps.Reads[0] == skelInst.Id));

		let cookedInst = db.RootGroup.CreateInstance("cooked", typeof(AnimationClipSource).GetFullName(.. scope .()));
		context.Output = cookedInst;
		context.SourceDatabase = db;
		Test.Assert(builder.Build(walk, context) case .Ok);
		{
			let object = cookedInst.ReadObject();
			defer delete object;
			let cooked = object as AnimationClipSource;
			Test.Assert(cooked != null);
			Test.Assert(!cooked.RootTimes.IsEmpty);
			Test.Assert(Math.Abs(cooked.RootPositions.Back.Z - 2.0f) < 1e-4f);
			Test.Assert(Math.Abs(cooked.KeyValue[1].Z) < 1e-4f, "the cooked hips walk in place");
		}
		Test.Assert(Math.Abs(walk.Source.KeyValue[1].Z - 2.0f) < 1e-4f, "the authored clip is untouched");

		// A root the skeleton does not have, or no skeleton at all, fails the cook loudly.
		walk.Source.RootBone.Set("pelvis");
		Test.Assert(builder.Build(walk, context) case .Err);
		walk.Source.RootBone.Set("hips");
		walk.Skeleton = .();
		Test.Assert(builder.Build(walk, context) case .Err);
		// Root motion off: no skeleton needed, the clip cooks as authored.
		walk.Source.RootHorizontal = false;
		Test.Assert(builder.Build(walk, context) case .Ok);
		let none = scope AssetDependencies();
		builder.ScanDependencies(walk, context, none);
		Test.Assert(none.Reads.IsEmpty);
	}

	/// The clip asset's appended fields through text: an asset saved before them reads at their
	/// defaults, and one saved after them reads them back, the rest transform included (a field
	/// written flat would never find its own key, and read as its default silently).
	[Test]
	public static void AClipAssetsAppendedFieldsRoundTripThroughText()
	{
		AnimationPipeline.RegisterAll();
		let asset = scope AnimationClipAsset();
		asset.Source.Name.Set("Walk");
		asset.Skeleton = Guid(0x11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		asset.RestPosition = .(1, 2, 3);
		asset.RestRotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f);
		asset.RestScale = .(2, 2, 2);
		asset.Source.RootYaw = true;
		let text = scope String();
		{
			let writer = scope XmlSerializer();
			((ISerializable)asset).Serialize(writer);
			writer.GetOutput(text);
		}
		{
			let document = scope XmlDocument();
			Test.Assert(document.Parse(text) == .Ok, text);
			let reader = scope XmlSerializer(document);
			let back = scope AnimationClipAsset();
			((ISerializable)back).Serialize(reader);
			Test.Assert(reader.IsOk);
			Test.Assert(back.Skeleton == asset.Skeleton);
			Test.Assert(back.RestPosition == Float3(1, 2, 3), text);
			Test.Assert(Math.Abs(Dot(back.RestRotation, asset.RestRotation)) > 1.0f - 1e-5f);
			Test.Assert(back.RestScale == Float3(2, 2, 2));
			Test.Assert(back.Source.RootYaw);
		}
		// Saved before them: the asset's own appended keys removed.
		let older = scope String(text);
		let cut = older.IndexOf("name=\"skeleton\"");
		Test.Assert(cut > 0, text);
		// The asset is one object in the document's root, its appended keys last: cut them and
		// close both.
		let open = older.LastIndexOf('<', cut);
		older.RemoveToEnd(open);
		older.Append("</object></root>");
		let document = scope XmlDocument();
		Test.Assert(document.Parse(older) == .Ok, older);
		let reader = scope XmlSerializer(document);
		let back = scope AnimationClipAsset();
		((ISerializable)back).Serialize(reader);
		Test.Assert(reader.IsOk);
		Test.Assert(back.Skeleton == Guid());
		Test.Assert(back.RestScale == Float3(1, 1, 1));
		Test.Assert(back.Source.RootYaw, "the source before them still reads");
	}
}
