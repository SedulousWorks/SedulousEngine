using System;

namespace Sedulous.Animation;

/// A state: one node, and how it is played.
class AnimationGraphState
{
	private String mName = new .() ~ delete _;
	private IAnimationStateNode mNode;
	private bool mOwnsNode;

	public float Speed = 1.0f;
	public bool Loop = true;

	/// Borrows the node, which the caller keeps alive.
	public this(StringView name, IAnimationStateNode node)
	{
		mName.Set(name);
		mNode = node;
		mOwnsNode = false;
	}

	/// TAKES OWNERSHIP of the node when told to, which is what a graph built in one place
	/// and handed over uses.
	public this(StringView name, IAnimationStateNode node, bool ownsNode)
	{
		mName.Set(name);
		mNode = node;
		mOwnsNode = ownsNode;
	}

	public ~this()
	{
		if (mOwnsNode && (mNode != null))
			delete mNode;
	}

	public String Name => mName;
	public IAnimationStateNode Node => mNode;
	public bool OwnsNode => mOwnsNode;

	public float Duration => (mNode != null) ? mNode.Duration : 0.0f;
}
