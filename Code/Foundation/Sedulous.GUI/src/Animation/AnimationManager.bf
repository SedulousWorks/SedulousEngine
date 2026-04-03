using System;
using System.Collections;

namespace Sedulous.GUI;

/// Manages all active animations in a GUIContext.
/// Updates animations each frame and handles lifecycle.
public class AnimationManager
{
	// Active animations
	private List<Animation> mAnimations = new .() ~ DeleteContainerAndItems!(_);
	private List<Animation> mPendingAdd = new .() ~ delete _;
	private List<Animation> mPendingRemove = new .() ~ delete _;
	private List<Storyboard> mStoryboards = new .() ~ DeleteContainerAndItems!(_);
	private List<Storyboard> mPendingStoryboardAdd = new .() ~ delete _;
	private List<Storyboard> mPendingStoryboardRemove = new .() ~ delete _;
	private bool mIsUpdating = false;

	// Owning context
	private GUIContext mContext;

	/// Creates an AnimationManager for the given context.
	public this(GUIContext context)
	{
		mContext = context;
	}

	/// Number of active animations.
	public int ActiveCount => mAnimations.Count;

	/// Number of active storyboards.
	public int StoryboardCount => mStoryboards.Count;

	/// Starts an animation.
	/// The manager takes ownership of the animation.
	public void Start(Animation animation)
	{
		if (animation == null)
			return;

		animation.Start();

		if (mIsUpdating)
			mPendingAdd.Add(animation);
		else
			mAnimations.Add(animation);
	}

	/// Starts an animation with a target element.
	public void Start(Animation animation, UIElement target)
	{
		if (animation == null)
			return;

		animation.SetTarget(target);
		Start(animation);
	}

	/// Starts a storyboard.
	/// The manager takes ownership of the storyboard.
	public void Start(Storyboard storyboard)
	{
		if (storyboard == null)
			return;

		storyboard.Start();

		if (mIsUpdating)
			mPendingStoryboardAdd.Add(storyboard);
		else
			mStoryboards.Add(storyboard);
	}

	/// Starts a storyboard with a default target element.
	public void Start(Storyboard storyboard, UIElement target)
	{
		if (storyboard == null)
			return;

		storyboard.SetTarget(target);
		Start(storyboard);
	}

	/// Stops an animation.
	public void Stop(Animation animation)
	{
		if (animation == null)
			return;

		animation.Cancel();

		if (mIsUpdating)
			mPendingRemove.Add(animation);
		else
		{
			mAnimations.Remove(animation);
			delete animation;
		}
	}

	/// Stops a storyboard.
	public void Stop(Storyboard storyboard)
	{
		if (storyboard == null)
			return;

		storyboard.Cancel();

		if (mIsUpdating)
			mPendingStoryboardRemove.Add(storyboard);
		else
		{
			mStoryboards.Remove(storyboard);
			delete storyboard;
		}
	}

	/// Stops all animations on a specific element.
	public void StopAllFor(UIElement element)
	{
		if (element == null)
			return;

		for (let anim in mAnimations)
		{
			if (anim.Target == element)
			{
				anim.Cancel();
				mPendingRemove.Add(anim);
			}
		}

		if (!mIsUpdating)
		{
			for (let anim in mPendingRemove)
			{
				mAnimations.Remove(anim);
				delete anim;
			}
			mPendingRemove.Clear();
		}
	}

	/// Stops all active animations and storyboards.
	public void StopAll()
	{
		for (let anim in mAnimations)
		{
			anim.Cancel();
			if (!mIsUpdating)
				delete anim;
		}

		for (let sb in mStoryboards)
		{
			sb.Cancel();
			if (!mIsUpdating)
				delete sb;
		}

		if (mIsUpdating)
		{
			for (let anim in mAnimations)
				mPendingRemove.Add(anim);
			for (let sb in mStoryboards)
				mPendingStoryboardRemove.Add(sb);
		}
		else
		{
			mAnimations.Clear();
			mStoryboards.Clear();
		}
	}

	/// Updates all active animations. Called by GUIContext.Update().
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		// Update standalone animations
		for (let animation in mAnimations)
		{
			if (!animation.Update(deltaTime))
			{
				mPendingRemove.Add(animation);
			}
		}

		// Update storyboards
		for (let storyboard in mStoryboards)
		{
			if (!storyboard.Update(deltaTime))
			{
				mPendingStoryboardRemove.Add(storyboard);
			}
		}

		mIsUpdating = false;

		// Process pending animation additions
		for (let anim in mPendingAdd)
			mAnimations.Add(anim);
		mPendingAdd.Clear();

		// Process pending animation removals
		for (let anim in mPendingRemove)
		{
			mAnimations.Remove(anim);
			delete anim;
		}
		mPendingRemove.Clear();

		// Process pending storyboard additions
		for (let sb in mPendingStoryboardAdd)
			mStoryboards.Add(sb);
		mPendingStoryboardAdd.Clear();

		// Process pending storyboard removals
		for (let sb in mPendingStoryboardRemove)
		{
			mStoryboards.Remove(sb);
			delete sb;
		}
		mPendingStoryboardRemove.Clear();
	}

	/// Called when an element is about to be deleted.
	/// Cancels any animations targeting that element.
	public void OnElementDeleted(UIElement element)
	{
		StopAllFor(element);
	}
}
