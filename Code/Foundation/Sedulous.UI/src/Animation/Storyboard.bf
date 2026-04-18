namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Groups multiple animations to play sequentially or in parallel.
/// Storyboard is itself an Animation, so it can be nested.
public class Storyboard : Animation
{
	public enum Mode
	{
		/// Play animations one after another.
		Sequential,
		/// Play all animations at the same time.
		Parallel
	}

	private Mode mMode;
	private List<Animation> mChildren = new .() ~ DeleteContainerAndItems!(_);
	private int mCurrentIndex;

	public this(Mode mode)
		: base(0) // Duration is computed from children.
	{
		mMode = mode;
	}

	/// Add a child animation. Storyboard takes ownership.
	public void Add(Animation anim)
	{
		mChildren.Add(anim);
	}

	/// Number of child animations.
	public int ChildCount => mChildren.Count;

	protected override void Apply(float t)
	{
		// Not used — Storyboard overrides Update directly.
	}

	public override bool Update(float deltaTime)
	{
		if (!IsRunning || IsComplete)
			return IsComplete;

		if (mChildren.Count == 0)
		{
			MarkComplete();
			return true;
		}

		switch (mMode)
		{
		case .Sequential:
			return UpdateSequential(deltaTime);
		case .Parallel:
			return UpdateParallel(deltaTime);
		}
	}

	private bool UpdateSequential(float deltaTime)
	{
		while (mCurrentIndex < mChildren.Count)
		{
			let child = mChildren[mCurrentIndex];
			if (!child.IsRunning && !child.IsComplete)
				child.Start();

			if (child.Update(deltaTime))
			{
				mCurrentIndex++;
				continue;
			}
			return false; // Current child still running.
		}

		// All children complete.
		MarkComplete();
		return true;
	}

	private bool UpdateParallel(float deltaTime)
	{
		bool allDone = true;
		for (let child in mChildren)
		{
			if (!child.IsRunning && !child.IsComplete)
				child.Start();

			if (!child.Update(deltaTime))
				allDone = false;
		}

		if (allDone)
		{
			MarkComplete();
			return true;
		}
		return false;
	}

	/// Reset this storyboard and all children.
	public override void Reset()
	{
		base.Reset();
		mCurrentIndex = 0;
		for (let child in mChildren)
			child.Reset();
	}
}
