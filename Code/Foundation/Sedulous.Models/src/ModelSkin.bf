using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// Skin data for skeletal animation
public class ModelSkin
{
	private String mName ~ delete _;
	private List<int32> mJoints ~ delete _;
	private List<Matrix> mInverseBindMatrices ~ delete _;

	/// Index of the skeleton root bone (-1 if not specified)
	public int32 SkeletonRootIndex = -1;

	public StringView Name => mName;
	public List<int32> Joints => mJoints;
	public List<Matrix> InverseBindMatrices => mInverseBindMatrices;

	public this()
	{
		mName = new String();
		mJoints = new List<int32>();
		mInverseBindMatrices = new List<Matrix>();
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	/// Add a joint to the skin
	public void AddJoint(int32 boneIndex, Matrix inverseBindMatrix)
	{
		mJoints.Add(boneIndex);
		mInverseBindMatrices.Add(inverseBindMatrix);
	}
}
