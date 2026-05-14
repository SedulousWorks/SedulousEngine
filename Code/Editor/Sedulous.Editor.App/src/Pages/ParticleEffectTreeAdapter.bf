namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;
using Sedulous.Particles.Resources;

/// Tree adapter for the particle editor's left pane. Mirrors the
/// effect → system → (emitter + initializers folder + behaviors folder)
/// hierarchy. Selection fires OnObjectSelected with the model object
/// represented by the picked node (or null for folder nodes).
///
/// Folder nodes are display-only grouping containers - they have no
/// underlying model object. v1 has no Add/Remove UI; the registry-backed
/// type picker for structural mutations lands in a follow-up.
class ParticleEffectTreeAdapter : ITreeAdapter
{
	public enum NodeKind
	{
		Root,                // The ParticleEffect itself
		System,              // ParticleSystem
		Emitter,             // ParticleEmitter
		InitializersFolder,  // grouping
		Initializer,         // ParticleInitializer
		BehaviorsFolder,     // grouping
		Behavior             // ParticleBehavior
	}

	class TreeNode
	{
		public int32 Id;
		public int32 ParentId = -1;
		public NodeKind Kind;
		public String DisplayName ~ delete _;
		/// The model object for this node (null for folder nodes).
		public Object Target;
		public List<int32> ChildIds = new .() ~ delete _;
	}

	private ParticleEffectResource mEffectRes;
	private Dictionary<int32, TreeNode> mNodes = new .() ~ DeleteDictionaryAndValues!(_);
	private List<int32> mRootIds = new .() ~ delete _;
	private int32 mNextId = 1;
	private ITreeAdapterObserver mObserver;
	private int32 mSelectedNodeId = -1;

	/// Fired when the user picks a tree node. Object may be null for folder rows.
	public Event<delegate void(Object)> OnObjectSelected ~ _.Dispose();

	public this(ParticleEffectResource effectRes)
	{
		mEffectRes = effectRes;
		Rebuild();
	}

	public int32 SelectedNodeId => mSelectedNodeId;

	/// Rebuilds the entire tree from the current effect graph. Call after any
	/// structural mutation (add/remove/move of a system, initializer, or
	/// behavior).
	public void Rebuild()
	{
		for (let kv in mNodes)
			delete kv.value;
		mNodes.Clear();
		mRootIds.Clear();
		mNextId = 1;

		let effect = mEffectRes?.Effect;
		if (effect != null)
		{
			let root = CreateNode(.Root, scope String(effect.Name.Length > 0 ? effect.Name : "Effect"), effect, -1);
			mRootIds.Add(root.Id);

			for (let system in effect.Systems)
				BuildSystemSubtree(root, system);
		}

		mObserver?.OnTreeDataChanged();
	}

	private void BuildSystemSubtree(TreeNode parent, ParticleSystem system)
	{
		let sysNode = CreateNode(.System, scope String("System"), system, parent.Id);
		parent.ChildIds.Add(sysNode.Id);

		// Emitter row.
		let emitter = CreateNode(.Emitter, scope String("Emitter"), system.Emitter, sysNode.Id);
		sysNode.ChildIds.Add(emitter.Id);

		// Initializers folder + children.
		let initFolder = CreateNode(.InitializersFolder, scope String("Initializers"), null, sysNode.Id);
		sysNode.ChildIds.Add(initFolder.Id);
		for (let init in system.Initializers)
		{
			let label = scope String();
			AppendTypeDisplayName(label, init.GetType());
			let initNode = CreateNode(.Initializer, label, init, initFolder.Id);
			initFolder.ChildIds.Add(initNode.Id);
		}

		// Behaviors folder + children.
		let behFolder = CreateNode(.BehaviorsFolder, scope String("Behaviors"), null, sysNode.Id);
		sysNode.ChildIds.Add(behFolder.Id);
		for (let beh in system.Behaviors)
		{
			let label = scope String();
			AppendTypeDisplayName(label, beh.GetType());
			let behNode = CreateNode(.Behavior, label, beh, behFolder.Id);
			behFolder.ChildIds.Add(behNode.Id);
		}
	}

	private TreeNode CreateNode(NodeKind kind, StringView displayName, Object target, int32 parentId)
	{
		let node = new TreeNode();
		node.Id = mNextId++;
		node.ParentId = parentId;
		node.Kind = kind;
		node.DisplayName = new String(displayName);
		node.Target = target;
		mNodes[node.Id] = node;
		return node;
	}

	/// Strips the trailing Initializer/Behavior suffix for cleaner tree labels.
	/// Mirrors the suffix stripping done by InspectorCodegen for category headers.
	private static void AppendTypeDisplayName(String dst, Type type)
	{
		let raw = type.GetName(.. scope .());
		dst.Append(raw);
		if (dst.EndsWith("Initializer"))
			dst.RemoveFromEnd(11);
		else if (dst.EndsWith("Behavior"))
			dst.RemoveFromEnd(8);
	}

	/// Selects a node and fires OnObjectSelected with the bound model object.
	public void SelectNode(int32 nodeId)
	{
		mSelectedNodeId = nodeId;
		if (mNodes.TryGetValue(nodeId, let node))
			OnObjectSelected(node.Target);
		else
			OnObjectSelected(null);
	}

	public Object GetNodeTarget(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.Target;
		return null;
	}

	/// Find the current node ID for a given model target. Useful after
	/// Rebuild() when callers want to restore selection on a still-alive
	/// object whose node ID was invalidated by the rebuild.
	public int32 FindNodeForTarget(Object target)
	{
		if (target == null) return -1;
		for (let kv in mNodes)
			if (kv.value.Target === target) return kv.key;
		return -1;
	}

	public NodeKind GetNodeKind(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.Kind;
		return .Root;
	}

	public int32 GetParentNodeId(int32 nodeId)
	{
		if (mNodes.TryGetValue(nodeId, let node))
			return node.ParentId;
		return -1;
	}

	/// Returns the ParticleSystem that owns this node (the system whose
	/// Emitter/Initializers/Behaviors list contains the node's target).
	/// Returns null for the effect root and for System nodes themselves.
	public ParticleSystem GetOwningSystem(int32 nodeId)
	{
		if (!mNodes.TryGetValue(nodeId, let node)) return null;
		// Walk up until we find a System node; that's the owner.
		var current = node;
		while (current.Kind != .System && current.ParentId >= 0)
		{
			if (!mNodes.TryGetValue(current.ParentId, let parent)) return null;
			current = parent;
		}
		return current.Kind == .System ? current.Target as ParticleSystem : null;
	}

	/// Returns the node's index within its data container (System index in
	/// effect, Initializer/Behavior index in system). Returns -1 for nodes
	/// without a data slot (root, folders, emitter).
	public int32 GetDataIndex(int32 nodeId)
	{
		if (!mNodes.TryGetValue(nodeId, let node)) return -1;
		let effect = mEffectRes?.Effect;
		if (effect == null) return -1;

		switch (node.Kind)
		{
		case .System:
			let sys = node.Target as ParticleSystem;
			for (int32 i = 0; i < effect.Systems.Length; i++)
				if (effect.Systems[i] === sys) return i;
			return -1;
		case .Initializer:
			let owner = GetOwningSystem(nodeId);
			let target = node.Target as ParticleInitializer;
			if (owner == null || target == null) return -1;
			for (int32 i = 0; i < owner.Initializers.Length; i++)
				if (owner.Initializers[i] === target) return i;
			return -1;
		case .Behavior:
			let owner = GetOwningSystem(nodeId);
			let target = node.Target as ParticleBehavior;
			if (owner == null || target == null) return -1;
			for (int32 i = 0; i < owner.Behaviors.Length; i++)
				if (owner.Behaviors[i] === target) return i;
			return -1;
		default:
			return -1;
		}
	}

	// === ITreeAdapter ===

	public int32 RootCount => (int32)mRootIds.Count;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return (int32)mRootIds.Count;
		if (!mNodes.TryGetValue(nodeId, let node))
			return 0;
		return (int32)node.ChildIds.Count;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
		{
			if (childIndex < 0 || childIndex >= mRootIds.Count) return -1;
			return mRootIds[childIndex];
		}
		if (!mNodes.TryGetValue(parentId, let node))
			return -1;
		if (childIndex < 0 || childIndex >= node.ChildIds.Count) return -1;
		return node.ChildIds[childIndex];
	}

	public int32 GetDepth(int32 nodeId)
	{
		int32 depth = 0;
		var currentId = nodeId;
		while (mNodes.TryGetValue(currentId, let node) && node.ParentId >= 0)
		{
			depth++;
			currentId = node.ParentId;
		}
		return depth;
	}

	public bool HasChildren(int32 nodeId)
	{
		if (!mNodes.TryGetValue(nodeId, let node))
			return false;
		return node.ChildIds.Count > 0;
	}

	public View CreateView(int32 viewType)
	{
		return new ParticleTreeItemView();
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let itemView = view as ParticleTreeItemView;
		if (itemView == null) return;
		if (!mNodes.TryGetValue(nodeId, let node)) return;

		itemView.Set(node.DisplayName, depth);

		// Highlight selected; folders are dim, leaves are normal, root is light.
		if (nodeId == mSelectedNodeId)
			itemView.TextColor = .(220, 225, 240, 255);
		else if (node.Kind == .Root || node.Kind == .System)
			itemView.TextColor = .(195, 200, 215, 255);
		else if (node.Kind == .InitializersFolder || node.Kind == .BehaviorsFolder)
			itemView.TextColor = .(150, 155, 170, 255);
		else
			itemView.TextColor = .(170, 175, 190, 255);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer)
	{
		mObserver = observer;
	}
}

/// Tree item view for the particle effect tree. Mirrors RegistryTreeItemView
/// but draws using its own indent so the label sits to the right of the
/// TreeView's expand arrow column.
class ParticleTreeItemView : View
{
	private String mText = new .() ~ delete _;
	private int32 mDepth;
	private float mIndentWidth = 20;

	public Color TextColor = .(180, 185, 200, 255);

	public void Set(StringView text, int32 depth)
	{
		mText.Set(text);
		mDepth = depth;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mText.Length == 0 || ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(12);
		if (font == null) return;

		let indent = (mDepth + 1) * mIndentWidth;
		let bounds = RectangleF(indent, 0, Width - indent, Height);
		ctx.VG.DrawText(mText, font, bounds, .Left, .Middle, TextColor);
	}
}
