using System;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Animation.Pipeline.Tests;

/// The authoring to runtime path for a skeleton: cooked through the builder, read back through
/// the factory.
///
/// End to end on purpose. Each half can be right on its own and still not meet, and a skeleton
/// that cooks into something the factory rebuilds wrongly is a rig that animates wrongly.
class SkeletonAssetTests
{
	private const String cRoot = "scratch_anim_pipeline";
	private const String cProductType = "Sedulous.Animation.Resource.SkeletonSource";

	private static void AuthorSkeleton(Skeleton outSkeleton)
	{
		outSkeleton.Bones[0].Index = 0;
		outSkeleton.Bones[0].ParentIndex = -1;
		outSkeleton.Bones[0].Name.Set("root");
		outSkeleton.Bones[1].Index = 1;
		outSkeleton.Bones[1].ParentIndex = 0;
		outSkeleton.Bones[1].Name.Set("child");
		outSkeleton.BuildNameMap();
		outSkeleton.FindRootBones();
		outSkeleton.BuildChildIndices();
		outSkeleton.ComputeInverseBindPoses();
	}

	[Test]
	public static void ACookedSkeletonBindsBackWithItsHierarchy()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		AnimationResources.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("skel", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let skeleton = scope Skeleton(2);
			AuthorSkeleton(skeleton);

			let asset = scope SkeletonAsset();
			// A note about which model it came from rather than something the build reads.
			asset.FileName.Set("models/char.gltf");
			SkeletonSource.FromSkeleton(skeleton, asset.Source);

			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(scope SkeletonAssetBuilder().Build(asset, context) case .Ok);
		}

		// A FRESH database over the same mount, which is what a later session opens.
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope SkeletonFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<Skeleton>(id);
		let skeleton = bound.Get;
		Test.Assert(skeleton != null);
		Test.Assert(skeleton.BoneCount == 2);
		Test.Assert(skeleton.FindBone("child") == 1);
		Test.Assert(skeleton.RootBones.Length == 1);
	}
}
