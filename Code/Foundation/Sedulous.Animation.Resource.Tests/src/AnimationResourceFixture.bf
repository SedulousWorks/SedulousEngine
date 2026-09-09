using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Animation.Resource.Tests;

/// A scratch mount, a database, and the three factories cooked animation content is built
/// through.
///
/// All three, because a graph resolves its clips through the manager and a fixture missing
/// the clip factory would test the graph in isolation from what it binds.
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

	public const String SkeletonTypeName = "Sedulous.Animation.Resource.SkeletonSource";
	public const String ClipTypeName = "Sedulous.Animation.Resource.AnimationClipSource";
	public const String GraphTypeName = "Sedulous.Animation.Resource.AnimationGraphSource";

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
		skeleton.Bones[0].LocalBindPose.Position = .(0, 10, 0);
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.Bones[1].Name.Set("child");
		skeleton.Bones[1].LocalBindPose.Position = .(0, 5, 0);

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

		let instance = Database.RootGroup.CreateInstance(name, SkeletonTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}

	public Guid CookClip(StringView name, float duration = 1.0f, bool looping = true)
	{
		let clip = scope AnimationClip(name, duration, looping);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(duration, .(0, 10, 0));
		clip.GetOrCreateRotationTrack(1).AddKeyframe(0.0f, Quaternion.Identity);
		clip.AddEvent(duration * 0.5f, "Footstep");

		let record = scope AnimationClipSource();
		AnimationClipSource.FromClip(clip, record);

		let instance = Database.RootGroup.CreateInstance(name, ClipTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
