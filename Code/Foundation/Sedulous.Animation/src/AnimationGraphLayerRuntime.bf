using System;
using System.Collections;

namespace Sedulous.Animation;

/// One layer's per instance state: where it is, what it is fading from, and the poses it
/// evaluated into.
///
/// The scratch poses live HERE rather than in the player, because a layer is evaluated on
/// its own and then combined: they all need to exist at once.
class AnimationGraphLayerRuntime
{
	public int32 CurrentStateIndex = -1;
	public float CurrentTime = 0.0f;

	public int32 PreviousStateIndex = -1;
	public float PreviousTime = 0.0f;

	public float TransitionElapsed = 0.0f;
	public float TransitionDuration = 0.0f;
	public bool IsTransitioning = false;

	public List<BoneTransform> Poses = new .() ~ delete _;
	public List<BoneTransform> PrevPoses = new .() ~ delete _;

	public void Init(int boneCount)
	{
		Poses.Count = boneCount;
		PrevPoses.Count = boneCount;
	}

	public void Reset(int32 defaultStateIndex)
	{
		CurrentStateIndex = defaultStateIndex;
		CurrentTime = 0.0f;
		PreviousStateIndex = -1;
		PreviousTime = 0.0f;
		TransitionElapsed = 0.0f;
		TransitionDuration = 0.0f;
		IsTransitioning = false;
	}
}
