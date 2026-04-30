namespace Sedulous.Audio;

using System;
using System.Collections;
using Sedulous.Audio.Graph;

/// Concrete audio bus implementation. Owns its graph nodes:
/// CombineNode (input) -> [EffectNodes] -> VolumeNode (output) -> parent's CombineNode
/// The bus creates, connects, and deletes its own nodes.
class AudioBus : IAudioBus
{
	private String mName ~ delete _;
	private AudioBus mParent;
	private List<AudioBus> mChildren = new .() ~ delete _;
	private CombineNode mInputNode;
	private VolumeNode mVolumeNode;
	private List<EffectNode> mEffectNodes = new .() ~ delete _;
	private bool mMuted;

	public StringView Name => mName;

	public float Volume
	{
		get => mVolumeNode.Volume;
		set => mVolumeNode.Volume = value;
	}

	public bool Muted
	{
		get => mMuted;
		set
		{
			mMuted = value;
			mVolumeNode.Enabled = !value;
		}
	}

	public IAudioBus Parent => mParent;

	public int EffectCount => mEffectNodes.Count;

	public CombineNode InputNode => mInputNode;
	public VolumeNode OutputNode => mVolumeNode;

	/// Creates a bus with its own graph nodes.
	public this(StringView name)
	{
		mName = new String(name);

		mInputNode = new CombineNode();
		mVolumeNode = new VolumeNode();

		// Direct chain: input -> volume (no effects yet)
		mVolumeNode.AddInput(mInputNode);
	}

	public ~this()
	{
		ClearEffects(true);

		// Disconnect before deleting
		if (mVolumeNode != null)
		{
			mVolumeNode.DisconnectAll();
			delete mVolumeNode;
			mVolumeNode = null;
		}
		if (mInputNode != null)
		{
			mInputNode.DisconnectAll();
			delete mInputNode;
			mInputNode = null;
		}
	}

	public IAudioEffect GetEffect(int index)
	{
		if (index < 0 || index >= mEffectNodes.Count)
			return null;
		return mEffectNodes[index].Effect;
	}

	public void AddEffect(IAudioEffect effect)
	{
		let effectNode = new EffectNode(effect);

		if (mEffectNodes.Count == 0)
		{
			mVolumeNode.RemoveInput(mInputNode);
			effectNode.AddInput(mInputNode);
			mVolumeNode.AddInput(effectNode);
		}
		else
		{
			let lastEffect = mEffectNodes[mEffectNodes.Count - 1];
			mVolumeNode.RemoveInput(lastEffect);
			effectNode.AddInput(lastEffect);
			mVolumeNode.AddInput(effectNode);
		}

		mEffectNodes.Add(effectNode);
	}

	public void InsertEffect(int index, IAudioEffect effect)
	{
		if (index < 0 || index > mEffectNodes.Count)
			return;

		if (index == mEffectNodes.Count)
		{
			AddEffect(effect);
			return;
		}

		let effectNode = new EffectNode(effect);

		let nextNode = mEffectNodes[index];

		if (index == 0)
		{
			nextNode.RemoveInput(mInputNode);
			effectNode.AddInput(mInputNode);
			nextNode.AddInput(effectNode);
		}
		else
		{
			let prevNode = mEffectNodes[index - 1];
			nextNode.RemoveInput(prevNode);
			effectNode.AddInput(prevNode);
			nextNode.AddInput(effectNode);
		}

		mEffectNodes.Insert(index, effectNode);
	}

	public IAudioEffect RemoveEffect(int index)
	{
		if (index < 0 || index >= mEffectNodes.Count)
			return null;

		let effectNode = mEffectNodes[index];

		AudioNode prevNode = (index == 0) ? (AudioNode)mInputNode : mEffectNodes[index - 1];
		AudioNode nextNode = (index == mEffectNodes.Count - 1) ? (AudioNode)mVolumeNode : mEffectNodes[index + 1];

		nextNode.RemoveInput(effectNode);
		effectNode.RemoveInput(prevNode);
		nextNode.AddInput(prevNode);

		mEffectNodes.RemoveAt(index);

		let releasedEffect = effectNode.ReleaseEffect();
		delete effectNode;

		return releasedEffect;
	}

	public void ClearEffects(bool deleteEffects = true)
	{
		if (mEffectNodes.Count == 0)
			return;

		mVolumeNode.RemoveInput(mEffectNodes[mEffectNodes.Count - 1]);
		mVolumeNode.AddInput(mInputNode);

		for (let effectNode in mEffectNodes)
		{
			effectNode.DisconnectAll();
			delete effectNode;
		}
		mEffectNodes.Clear();
	}

	/// Sets the parent bus. Connects this bus's volume output to parent's input.
	public void SetParent(AudioBus parent)
	{
		if (mParent != null)
		{
			mParent.mInputNode.RemoveInput(mVolumeNode);
			mParent.mChildren.Remove(this);
		}

		mParent = parent;

		if (mParent != null)
		{
			mParent.mInputNode.AddInput(mVolumeNode);
			mParent.mChildren.Add(this);
		}
	}

	/// Re-routes all children to a new parent.
	public void ReparentChildrenTo(AudioBus newParent)
	{
		while (mChildren.Count > 0)
		{
			let child = mChildren[0];
			child.SetParent(newParent);
		}
	}

	/// Gets the list of child buses (read-only access).
	public List<AudioBus> Children => mChildren;
}
