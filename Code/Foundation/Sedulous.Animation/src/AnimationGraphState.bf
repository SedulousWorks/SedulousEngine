namespace Sedulous.Animation;

using System;

/// A state in an animation graph layer.
/// Wraps an IAnimationStateNode (clip or blend tree) with playback settings.
class AnimationGraphState
{
	/// Display name of this state.
	public String Name ~ delete _;

	/// The node that produces this state's animation pose.
	public IAnimationStateNode Node;

	/// Playback speed multiplier (1.0 = normal).
	public float Speed = 1.0f;

	/// Whether this state's animation should loop.
	public bool Loop = true;

	/// Whether the graph owns (and should delete) the node.
	public bool OwnsNode;

	public this(StringView name, IAnimationStateNode node, bool ownsNode = false)
	{
		Name = new .(name);
		Node = node;
		OwnsNode = ownsNode;
	}

	public ~this()
	{
		if (OwnsNode)
		{
			// ClipStateNode, BlendTree1D, BlendTree2D are all classes
			if (let clipNode = Node as ClipStateNode)
				delete clipNode;
			else if (let blend1D = Node as BlendTree1D)
				delete blend1D;
			else if (let blend2D = Node as BlendTree2D)
				delete blend2D;
		}
	}

	/// Duration of the underlying node's animation in seconds.
	public float Duration => Node != null ? Node.Duration : 0.0f;
}
