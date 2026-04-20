namespace Sedulous.UI;

using System;
using System.Collections;

/// Manages active animations. Owned by UIContext and ticked each frame.
/// Owns animations - deletes on completion or cancellation.
public class AnimationManager
{
	private List<Animation> mAnimations = new .() ~ DeleteContainerAndItems!(_);
	private List<Animation> mPending = new .() ~ DeleteContainerAndItems!(_);
	private bool mIsUpdating;

	/// Number of currently active animations.
	public int ActiveCount => mAnimations.Count + mPending.Count;

	/// Add an animation and start it. AnimationManager takes ownership.
	public void Add(Animation anim)
	{
		anim.Start();
		if (mIsUpdating)
			mPending.Add(anim);
		else
			mAnimations.Add(anim);
	}

	/// Tick all animations. Removes and deletes completed ones.
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		for (int i = mAnimations.Count - 1; i >= 0; i--)
		{
			let anim = mAnimations[i];
			if (anim.Update(deltaTime))
			{
				mAnimations.RemoveAtFast(i);
				delete anim;
			}
		}

		mIsUpdating = false;

		// Merge pending animations added during Update.
		if (mPending.Count > 0)
		{
			for (let anim in mPending)
				mAnimations.Add(anim);
			mPending.Clear();
		}
	}

	/// Cancel and delete all animations.
	public void CancelAll()
	{
		for (let anim in mAnimations)
			delete anim;
		mAnimations.Clear();

		for (let anim in mPending)
			delete anim;
		mPending.Clear();
	}

	/// Cancel and delete all animations targeting a specific view.
	public void CancelForView(View view)
	{
		for (int i = mAnimations.Count - 1; i >= 0; i--)
		{
			if (mAnimations[i].Target === view)
			{
				delete mAnimations[i];
				mAnimations.RemoveAtFast(i);
			}
		}

		for (int i = mPending.Count - 1; i >= 0; i--)
		{
			if (mPending[i].Target === view)
			{
				delete mPending[i];
				mPending.RemoveAtFast(i);
			}
		}
	}
}
