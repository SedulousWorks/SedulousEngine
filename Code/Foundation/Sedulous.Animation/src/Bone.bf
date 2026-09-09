using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// One node of a skeleton.
///
/// A class owned by the skeleton's bone list: the children list makes it own storage, and a
/// value type holding one would copy that list on every read.
class Bone
{
	public String Name = new .() ~ delete _;
	public int32 Index = 0;
	/// Minus one is a root.
	public int32 ParentIndex = -1;

	/// Where it sits relative to its parent when nothing is animating it.
	public BoneTransform LocalBindPose = .();
	/// Model space into bone space.
	public Float4x4 InverseBindPose = Float4x4.Identity();

	/// The transform of the ancestors an import DID NOT bring across, which is where an
	/// axis convention from the source file ends up. Applied to a root in place of a parent.
	public Float4x4 RootCorrection = Float4x4.Identity();

	public List<int32> Children = new .() ~ delete _;
}
