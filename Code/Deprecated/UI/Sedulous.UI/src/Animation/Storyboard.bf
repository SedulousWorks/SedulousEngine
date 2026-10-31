using System.Collections;

namespace Sedulous.UI;

/// A group of animations played together or in turn.
///
/// A storyboard IS an animation, so it nests: a sequential storyboard of parallel ones is an
/// ordinary composition rather than a special case.
class Storyboard : Animation
{
	private StoryboardMode mMode;
	/// OWNED.
	private List<Animation> mChildren = new .() ~ DeleteContainerAndItems!(_);
	private int mCurrentIndex = 0;

	public this(StoryboardMode mode) : base(0)
	{
		mMode = mode;
	}

	/// OWNERSHIP transfers.
	public void Add(Animation animation)
	{
		if (animation != null)
			mChildren.Add(animation);
	}

	public int ChildCount => mChildren.Count;

	public override bool Update(float deltaTime)
	{
		if (!IsRunning || IsComplete)
			return IsComplete;

		// An empty storyboard is finished immediately rather than waiting forever for
		// children that will never arrive.
		if (mChildren.IsEmpty)
		{
			MarkComplete();
			return true;
		}

		switch (mMode)
		{
		case .Sequential: return UpdateSequential(deltaTime);
		case .Parallel: return UpdateParallel(deltaTime);
		}
	}

	/// Resets this storyboard AND every child, so replaying starts genuinely from the top.
	public override void Reset()
	{
		base.Reset();
		mCurrentIndex = 0;
		for (let child in mChildren)
			child.Reset();
	}

	/// Not used: a storyboard drives its children through Update rather than a value.
	protected override void Apply(float t) {}

	private bool UpdateSequential(float deltaTime)
	{
		// Looped rather than returning after one child: a zero duration child finishes within
		// the same tick, and the next has to start in it rather than a frame later.
		while (mCurrentIndex < mChildren.Count)
		{
			let child = mChildren[mCurrentIndex];
			if (!child.IsRunning && !child.IsComplete)
				child.Start();

			if (!child.Update(deltaTime))
				return false; // this one is still running

			mCurrentIndex++;
		}

		MarkComplete();
		return true;
	}

	private bool UpdateParallel(float deltaTime)
	{
		var allDone = true;
		for (let child in mChildren)
		{
			if (!child.IsRunning && !child.IsComplete)
				child.Start();
			if (!child.Update(deltaTime))
				allDone = false;
		}

		if (!allDone)
			return false;

		MarkComplete();
		return true;
	}
}
