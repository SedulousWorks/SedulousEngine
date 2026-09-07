using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Model;

/// A skin: the joints a mesh is bound to, and the bind pose those joints were bound in.
///
/// The two lists are PARALLEL, one inverse bind matrix per joint, which is why they are
/// added together rather than separately.
class ModelSkin
{
	public String Name = new .() ~ delete _;

	private List<int32> mJoints = new .() ~ delete _;
	private List<Float4x4> mInverseBindMatrices = new .() ~ delete _;

	/// The skeleton root this skin hangs from, or -1 when the file did not say.
	public int32 SkeletonRootIndex = -1;

	public Span<int32> Joints => .(mJoints.Ptr, mJoints.Count);
	public Span<Float4x4> InverseBindMatrices => .(mInverseBindMatrices.Ptr, mInverseBindMatrices.Count);
	public int JointCount => mJoints.Count;

	public void AddJoint(int32 boneIndex, Float4x4 inverseBindMatrix)
	{
		mJoints.Add(boneIndex);
		mInverseBindMatrices.Add(inverseBindMatrix);
	}
}
