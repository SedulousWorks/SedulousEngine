using System;
using System.Collections;
using Sedulous.Particles;

namespace Sedulous.Editor.Scene;

/// The effect as a node table for the tree: the root, a row per system, and under each
/// its emitter and the two module folders with a row per module.
class ParticleTreeSnapshot
{
	public List<ParticleTreeNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> Roots = new .() ~ delete _;

	public bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < Nodes.Count);

	public void Rebuild(ParticleEffect effect)
	{
		ClearAndDeleteItems!(Nodes);
		Roots.Clear();
		if (effect == null)
			return;

		let rootId = Add(.Effect, -1, -1, 0, "Effect");
		Roots.Add(rootId);

		for (int32 s < effect.SystemCount)
		{
			let sys = effect.GetSystem(s);
			if (sys == null)
				continue;
			let sysId = Add(.System, s, -1, 1, sys.Name.IsEmpty ? scope $"System {s}" : StringView(sys.Name));
			Nodes[rootId].Children.Add(sysId);

			Nodes[sysId].Children.Add(Add(.Emitter, s, -1, 2, "Emitter"));

			let initFolder = Add(.InitializersFolder, s, -1, 2, scope $"Initializers ({sys.InitializerCount})");
			Nodes[sysId].Children.Add(initFolder);
			for (int32 i < sys.InitializerCount)
				Nodes[initFolder].Children.Add(Add(.Initializer, s, i, 3, ParticleEffectEdit.ModuleLabel(sys.GetInitializer(i), .. scope .())));

			let behFolder = Add(.BehaviorsFolder, s, -1, 2, scope $"Behaviors ({sys.BehaviorCount})");
			Nodes[sysId].Children.Add(behFolder);
			for (int32 i < sys.BehaviorCount)
				Nodes[behFolder].Children.Add(Add(.Behavior, s, i, 3, ParticleEffectEdit.ModuleLabel(sys.GetBehavior(i), .. scope .())));
		}
	}

	/// The node standing for `ref`, or -1.
	public int32 NodeIdForRef(ParticleNodeRef target)
	{
		for (int32 i < (int32)Nodes.Count)
		{
			if (Nodes[i].Ref == target)
				return i;
		}
		return -1;
	}

	private int32 Add(ParticleNodeKind kind, int32 sys, int32 mod, int32 depth, StringView label)
	{
		let node = new ParticleTreeNode();
		node.Kind = kind;
		node.SystemIndex = sys;
		node.ModuleIndex = mod;
		node.Depth = depth;
		node.Label.Set(label);
		Nodes.Add(node);
		return (int32)Nodes.Count - 1;
	}
}
