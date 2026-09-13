using System;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.Animation.Tests;

/// A scratch mount, a database and the animation factories: the real resolve stack, so a
/// component's references are measured against it rather than against a stand in.
class AnimationResourceFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;

	public SkeletonFactory Skeletons = new .() ~ delete _;
	public AnimationClipFactory Clips = new .() ~ delete _;
	public AnimationGraphFactory Graphs = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String cSkeletonTypeName = "Sedulous.Animation.Resource.SkeletonSource";
	public const String cClipTypeName = "Sedulous.Animation.Resource.AnimationClipSource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		AnimationResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		Manager = new ResourceManager(Database, null);

		AnimationResources.AddFactories(Manager, Skeletons, Clips, Graphs);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// A chain of two, the second parented to the first.
	public static void BuildChain(Skeleton skeleton)
	{
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[0].Name.Set("root");
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.Bones[1].Name.Set("child");

		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	public Guid CookSkeleton(StringView name)
	{
		let skeleton = scope Skeleton(2);
		BuildChain(skeleton);

		let record = scope SkeletonSource();
		SkeletonSource.FromSkeleton(skeleton, record);

		let instance = Database.RootGroup.CreateInstance(name, cSkeletonTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}

	public Guid CookClip(StringView name, float duration = 2.0f, bool looping = true)
	{
		let clip = scope AnimationClip(name, duration, looping);
		let track = clip.GetOrCreatePositionTrack(1);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(duration, .(0, 1, 0));

		let record = scope AnimationClipSource();
		AnimationClipSource.FromClip(clip, record);

		let instance = Database.RootGroup.CreateInstance(name, cClipTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
