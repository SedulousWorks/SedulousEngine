using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Where a bone attachment stands: following, waiting for its animator's first pose, or off for
/// what it cannot resolve (each off state logs once when it begins).
enum BoneAttachmentStatus : uint8
{
	Waiting,
	Following,
	NoAnimator,
	UnknownBone,
}

/// A bone attachment's runtime side, none of it saved. Created and freed by its manager: a
/// component is a struct in a packed pool and cannot own heap data.
class BoneAttachmentRuntime
{
	/// The skeleton the bone was found in, BORROWED and compared by reference.
	public Skeleton ResolvedFor = null;
	public int32 BoneIndex = -1;
	/// The bone's bind pose in model space.
	public Float4x4 BindModel = Float4x4.Identity();
	public BoneAttachmentStatus Status = .Waiting;
	public BoneAttachmentStatus Logged = .Waiting;
}

/// An entity that follows one bone of the nearest animator, as a weapon in a hand or a hat on a
/// head does: the animator at or above it, else the one below (as IK finds it). The bones animate
/// only as a skinning palette, so an entity under a bone's node stands where the file put it while
/// the skin moves; this moves it, and its children ride along at their own offsets. The importer
/// puts one on the nearest bone node above each unskinned mesh of a rigged model
/// (ModelPlacement.RigidMeshBone).
[SerializableComponent("bone_attachment")]
[DisplayName("Bone Attachment")]
[Category("Animation")]
[Scriptable]
[Description("Follows one bone of the animator above it while the scene runs, such as a weapon in a hand or a hat on a head; its children ride along.")]
struct BoneAttachmentComponent : ISerializable
{
	/// The bone by name. OWNED, created and freed by the manager.
	[Scriptable, BoneName, Description("The bone this entity follows.")]
	public String Bone = null;

	[Hidden]
	public BoneAttachmentRuntime Runtime = null;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		Sedulous.Core.Serialization.Serialize(ar, "bone", Bone);
	}
}
