using System.Collections;

namespace Sedulous.UI;

/// Owns and ticks the running animations.
class AnimationManager
{
	/// OWNED.
	private List<Animation> mAnimations = new .() ~ DeleteContainerAndItems!(_);
	/// OWNED: animations added DURING a tick, merged in after it.
	private List<Animation> mPending = new .() ~ DeleteContainerAndItems!(_);
	private bool mIsUpdating = false;

	public this() {}

	public int ActiveCount => mAnimations.Count + mPending.Count;

	/// Adds an animation and starts it. OWNERSHIP transfers.
	///
	/// Added DURING a tick it goes to a pending list instead: an onComplete callback that
	/// starts the next animation must not mutate the list being walked.
	public void Add(Animation animation)
	{
		if (animation == null)
			return;

		animation.Start();
		if (mIsUpdating)
			mPending.Add(animation);
		else
			mAnimations.Add(animation);
	}

	/// Ticks everything, dropping what finished.
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		// Walked BACKWARD so removing an entry does not skip the next one.
		for (int i = mAnimations.Count - 1; i >= 0; i--)
		{
			if (mAnimations[i].Update(deltaTime))
			{
				let finished = mAnimations[i];
				mAnimations.RemoveAtFast(i);
				delete finished;
			}
		}

		mIsUpdating = false;

		for (let pending in mPending)
			mAnimations.Add(pending);
		mPending.Clear();
	}

	public void CancelAll()
	{
		ClearAndDeleteItems!(mAnimations);
		ClearAndDeleteItems!(mPending);
	}

	/// Cancels everything targeting one view, which is what a view leaving the tree needs so a
	/// running animation cannot write to it afterwards.
	public void CancelForView(View view)
	{
		CancelIn(mAnimations, view);
		CancelIn(mPending, view);
	}

	private static void CancelIn(List<Animation> animations, View view)
	{
		for (int i = animations.Count - 1; i >= 0; i--)
		{
			if (animations[i].Target != view)
				continue;

			let cancelled = animations[i];
			animations.RemoveAtFast(i);
			delete cancelled;
		}
	}
}
