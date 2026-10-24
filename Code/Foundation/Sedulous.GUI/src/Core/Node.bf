using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Node: the retained-mode scene-graph node, the tree content base (eepp Scene::Node). Ported from
// eepp include/eepp/scene/node.hpp: Transformable for its geometry, a reference count for its
// lifetime, and a list of children it holds a reference to each of, with a parent pointer back.
// Draws its subtree through the DrawContext/VG seam (eepp's nodeDraw + matrix/clip, on VG).
// Measure, arrange, the display kinds and scrolling are Layout/LayoutImpl.bf.

/// What a focus scope does when navigation reaches its edge: not a scope; pass to the neighbours
/// outside it (the default for a scope); wrap around to its other side (menus, carousels); or
/// contain focus (a dialog).
enum NavScope : uint8
{
	None,
	Pass,
	Wrap,
	Contain,
}

/// One GUI's element table: what a script's handle to a node resolves through, a slot and a
/// generation, so the tree owns its nodes and a script only ever holds them weakly. Each GUI owns
/// one, so two GUIs never share slots and a handle survives its node moving between roots. Handles
/// hold a reference to the table: when its GUI goes, the table is closed and every handle into it
/// reads as gone, never as freed memory. A slot does not hold its node: a node frees its slot as
/// it is destroyed.
class ElementTable : RefCounted
{
	private struct Slot
	{
		public Node Node = null;
		public uint32 Generation = 1;

		public this() { }
	}

	private List<Slot> mSlots = new .() ~ delete _;
	private List<uint32> mFree = new .() ~ delete _;
	private bool mClosed = false;

	/// A slot for `node` (1-based), reusing a freed one under a new generation.
	public uint32 Take(Node node)
	{
		uint32 slot = 0;
		if (!mFree.IsEmpty)
			slot = mFree.PopBack();
		else
		{
			mSlots.Add(Slot());
			slot = (uint32)mSlots.Count;
		}
		mSlots[(int)slot - 1].Node = node;
		return slot;
	}

	/// The node is gone: its handles stop resolving and the slot is free for another.
	public void Free(uint32 slot)
	{
		if ((slot == 0) || ((int)slot > mSlots.Count))
			return;
		mSlots[(int)slot - 1].Node = null;
		mSlots[(int)slot - 1].Generation++;
		if (!mClosed)
			mFree.Add(slot);
	}

	/// The node in `slot` if `generation` is still its, else null.
	public Node Resolve(uint32 slot, uint32 generation)
	{
		if (mClosed || (slot == 0) || ((int)slot > mSlots.Count))
			return null;
		let entry = mSlots[(int)slot - 1];
		return (entry.Generation == generation) ? entry.Node : null;
	}

	public uint32 Generation(uint32 slot) => ((slot != 0) && ((int)slot <= mSlots.Count)) ? mSlots[(int)slot - 1].Generation : 0;

	/// The owning GUI is going: every handle into this table reads as gone from now on.
	public void Close()
	{
		mClosed = true;
	}

	public bool IsClosed => mClosed;
}

/// A node of the GUI's tree.
///
/// Ownership: a node is reference counted (it starts with one reference, its maker's). A parent
/// holds one reference to each child, taken in AddChild and let go in RemoveChild (or when the
/// parent is destroyed); a child keeps a plain pointer back to its parent, cleared when it leaves
/// or the parent goes, so a child held elsewhere outlives its parent and points at none. Anything
/// else that must not keep a node alive holds it weakly, through its GUI's ElementTable (a slot
/// and a generation, which the node frees as it is destroyed): Element<T>, an action's target, a
/// scope's remembered focus. The node holds a reference to the table it took a slot in.
[GuiReflect]
class Node : Transformable, IRefCounted
{
	/// Not a child's place: what GetChildIndex gives for a node that is not one.
	public const int cInvalidIndex = -1;
	/// A node with this many children keeps an index of where each one's drawing reaches, so
	/// drawing and hit testing visit those that can matter, not every one.
	public const int cIndexedChildren = 32;

	/// Where a weak reference to a node resolves: its GUI's table, a slot and a generation.
	public struct ElementRef
	{
		public Sedulous.GUI.ElementTable Table = null;
		public uint32 Slot = 0;
		public uint32 Generation = 0;

		public this() { }

		public this(Sedulous.GUI.ElementTable table, uint32 slot, uint32 generation)
		{
			Table = table;
			Slot = slot;
			Generation = generation;
		}
	}

	// The states a selector reads, one bit each: a node whose state changed restyles alone, or
	// with its subtree or its later siblings when a sheet reads that state through an ancestor or
	// a sibling (the style pass decides; StyleManager knows its sheets). Constants, as they are
	// combined and kept as a uint32.
	public const uint32 StateHover = 1 << 0;
	public const uint32 StateFocus = 1 << 1;
	public const uint32 StateActive = 1 << 2;
	public const uint32 StateDisabled = 1 << 3;
	public const uint32 StateFocusVisible = 1 << 4;
	public const uint32 StateEnabled = 1 << 5;
	public const uint32 StateFocusWithin = 1 << 6;
	public const uint32 StateChecked = 1 << 7;
	public const uint32 StateIndeterminate = 1 << 8;
	public const uint32 StateReadOnly = 1 << 9;
	public const uint32 StateReadWrite = 1 << 10;
	public const uint32 StatePlaceholderShown = 1 << 11;
	public const uint32 StateSelected = 1 << 18; // after the selector's own flags (12 to 17)
	public const uint32 StateDropTarget = 1 << 19;
	public const uint32 StateDragSource = 1 << 20;
	public const uint32 StateLeaving = 1 << 22; // after :root (21)
	public const uint32 StateEntering = 1 << 23;

	// Overrides where the geometry is wrong (`nav-up`, `nav-down`, `nav-left`, `nav-right`,
	// `nav-next`, `nav-prev`): a widget's id to go to, `none` to stop, or `auto` (or empty) for the
	// picker or the tab order. Reflected with their CSS names, so sheets, markup and scripts set
	// them alike; a scope's kind (`nav-scope`: pass, wrap, contain, none) and default focus
	// (`nav-default`) likewise.
	public enum NavOverride : uint8
	{
		NavOverrideUp,
		NavOverrideDown,
		NavOverrideLeft,
		NavOverrideRight,
		NavOverrideNext,
		NavOverridePrevious,
		NavOverrideCount,
	}

	/// Which way its content runs: as what holds it does (the top of a GUI: its language's, as the
	/// Localization's tables say), left to right, or right to left (CSS's `direction`). Auto
	/// (HTML's dir="auto"): its text's paragraphs each run as their first strong character reads,
	/// typed or translated; its boxes run as what holds it does.
	public enum LayoutDirection : uint8
	{
		Inherit,
		LeftToRight,
		RightToLeft,
		Auto,
	}

	/// Whether its translated properties resolve their keys: as what holds it does (the root
	/// does), always, or never (a key then shows as written).
	public enum AutoTranslate : uint8
	{
		Inherit,
		Always,
		Off,
	}

	// === Code over the sheet ===
	// A property a sheet sets through a setter (opacity, padding, the layout properties, enabled,
	// visibility, the text properties) is code's once code sets it, as CSS's inline style: the
	// setter pins it and the sheet leaves it be. What no rule sets returns to the node's own
	// value: its default, or what code set before a sheet first styled it.

	/// The node's own values, captured when a sheet first styles it. A class: it owns a layout
	/// style.
	public class UnstyledValues
	{
		public bool Captured = false;
		public float Alpha = 1.0f;
		public Thickness Padding = .();
		public Sedulous.GUI.LayoutStyle Layout = new .() ~ delete _;
		public bool Visible = true;
		public bool Enabled = true;
		public bool ClipChildren = false;
	}

	/// While one lives, the node's setters write without pinning: what a sheet applies, and a
	/// widget's defaults (set in its constructor, the values a sheet returns to). Made with
	/// `scope`, so it ends with the block.
	public class StyleWriteScope
	{
		private Node mNode;
		private bool mWas;

		public this(Node node)
		{
			mNode = node;
			mWas = node.mStyleWriting;
			node.mStyleWriting = true;
		}

		public ~this()
		{
			mNode.mStyleWriting = mWas;
		}
	}

	/// One argument of a translated text: a literal, or a value of the GUI's data by name. A
	/// class: it owns its text.
	public class TranslationArgument
	{
		public String Text = new .() ~ delete _;
		public bool IsName = false;

		public void Set(TranslationArgument other)
		{
			Text.Set(other.Text);
			IsName = other.IsName;
		}
	}

	// === Reference counting ===

	protected int32 mRefCount = 1;

	public int RefCount => mRefCount;

	public void AddRef()
	{
		mRefCount++;
	}

	/// Lets go of one reference; the last one deletes the node.
	public void ReleaseRef()
	{
		mRefCount--;
		Debug.Assert(mRefCount >= 0);
		if (mRefCount == 0)
			delete this;
	}

	/// Lets go of a reference that must be the last one.
	public void ReleaseLastRef()
	{
		mRefCount--;
		Debug.Assert(mRefCount == 0);
		if (mRefCount == 0)
			delete this;
	}

	void IRefCounted.Release() => ReleaseRef();

	public this()
	{
	}

	public ~this()
	{
		Debug.Assert(mRefCount == 0);
		// A child held elsewhere outlives its parent: it must not point at it after.
		for (let child in mChildren)
		{
			child.mParent = null;
			child.ReleaseRef();
		}
		mChildren.Clear();
		if (mElementTable != null)
		{
			mElementTable.Free(mElementSlot);
			mElementTable.ReleaseRef();
		}
		for (let text in mNavOverrides)
			delete text;
	}

	// === Tree query ===

	public Node Parent => mParent;
	public int ChildCount => mChildren.Count;

	public Node GetChildAt(int index) => ((index >= 0) && (index < mChildren.Count)) ? mChildren[index] : null;
	public Node FirstChild => (mChildren.Count != 0) ? mChildren[0] : null;
	public Node LastChild => (mChildren.Count != 0) ? mChildren[mChildren.Count - 1] : null;

	/// Its place among the children (cInvalidIndex when it is not one). Each child keeps its index
	/// until the children change, when the next ask numbers them all at once, so asking for each
	/// child in turn (siblings, :nth-child, `+` and `~`) costs one pass, not one each.
	public int GetChildIndex(Node child)
	{
		if ((child == null) || (child.mParent != this))
			return cInvalidIndex;
		if (child.mIndexGeneration != mChildrenGeneration)
		{
			for (int i = 0; i < mChildren.Count; i++)
			{
				mChildren[i].mIndexInParent = i;
				mChildren[i].mIndexGeneration = mChildrenGeneration;
			}
		}
		return (child.mIndexGeneration == mChildrenGeneration) ? child.mIndexInParent : cInvalidIndex;
	}

	/// Counts changes to the children (added, removed, moved), for what is kept per arrangement.
	public uint32 ChildrenGeneration => mChildrenGeneration;

	public bool HasChild(Node child) => GetChildIndex(child) != cInvalidIndex;

	public Node NextSibling
	{
		get
		{
			if (mParent == null)
				return null;
			let i = mParent.GetChildIndex(this);
			return ((i != cInvalidIndex) && (i + 1 < mParent.mChildren.Count)) ? mParent.mChildren[i + 1] : null;
		}
	}

	public Node PrevSibling
	{
		get
		{
			if (mParent == null)
				return null;
			let i = mParent.GetChildIndex(this);
			return ((i != cInvalidIndex) && (i > 0)) ? mParent.mChildren[i - 1] : null;
		}
	}

	// === Tree mutation === (owning: the tree holds a reference to each child)

	/// Makes `child` its last child, taking it from its old parent. The tree takes a reference of
	/// its own: the caller keeps (and releases) the one it holds.
	public virtual Node AddChild(Node child)
	{
		if ((child == null) || (child == this) || (child.mParent == this))
			return this;
		child.AddRef(); // the tree's, taken first: it survives leaving its old parent
		if (child.mParent != null)
			child.mParent.RemoveChild(child);
		child.mParent = this;
		mChildren.Add(child);
		ChildrenRearranged(child);
		child.MarkStyleDirty(true); // its selectors may match differently here
		ChildrenStyleChanged();
		child.HandleParentChange();
		OnChildrenChanged();
		RequestLayout(); // what it holds changed
		Invalidate();
		return this;
	}

	public Node AddChildAt(Node child, int index)
	{
		AddChild(child);
		SetChildIndex(child, index);
		return this;
	}

	/// Takes `child` out; the tree's reference to it goes last, after the callbacks.
	public void RemoveChild(Node child)
	{
		if (GetChildIndex(child) == cInvalidIndex)
			return;
		// The dispatcher first drops its refs into the subtree (hover, press, focus, a popup): the
		// tree stops keeping those nodes alive. It may close a popup, which edits the tree, so the
		// index is found after.
		NotifyRemovingChild(child);
		let index = GetChildIndex(child);
		if (index == cInvalidIndex)
			return;
		child.NoteOldArea(null); // where it showed is to be drawn again
		child.mParent = null;
		child.mLeaving = false; // out of its parent, it has left: taken back, it is whole
		child.mLeaveQueued = false;
		child.mEnterPhase = 0; // and its entrance is over
		mChildren.RemoveAt(index);
		ChildrenRearranged(child);
		ChildrenStyleChanged();
		child.HandleParentChange();
		OnChildrenChanged();
		RequestLayout();
		Invalidate();
		child.ReleaseRef(); // the tree's, held across the detach and the callbacks
	}

	public void RemoveAllChildren()
	{
		while (mChildren.Count != 0)
			RemoveChild(mChildren[mChildren.Count - 1]);
	}

	public void RemoveFromParent()
	{
		if (mParent != null)
			mParent.RemoveChild(this);
	}

	/// Its access key (the `F` of `&File`, lower case), or 0: Alt and the key focus and activate it
	/// in its window or menu.
	public virtual char32 Mnemonic => '\0';

	/// The topmost ancestor (the SceneRoot, when the node is in a GUI).
	public Node RootNode
	{
		get
		{
			var n = this;
			while (n.mParent != null)
				n = n.mParent;
			return n;
		}
	}

	// === Z-order (draw/hit order = child index; last = topmost) ===

	public void SetChildIndex(Node child, int newIndex)
	{
		let cur = GetChildIndex(child);
		if (cur == cInvalidIndex)
			return;
		var newIndex;
		if (newIndex >= mChildren.Count)
			newIndex = mChildren.Count - 1;
		if (cur == newIndex)
			return;
		mChildren.RemoveAt(cur);
		mChildren.Insert(newIndex, child);
		ChildrenRearranged(child);
		ChildrenStyleChanged();
		RequestLayout(); // the flow follows the child order
		Invalidate();
	}

	public void ToFront()
	{
		if (mParent != null)
			mParent.SetChildIndex(this, mParent.mChildren.Count);
	}

	public void ToBack()
	{
		if (mParent != null)
			mParent.SetChildIndex(this, 0);
	}

	// === Size / bounds ===

	/// The node's size. From code, it is the node's width and height in pixels (inline `width` and
	/// `height`), kept by every layout; a layout placing the node (Arrange) sets it without.
	public Float2 Size
	{
		get => mSize;
		set
		{
			bool styleChanged = false;
			if (!IsBeingPlaced)
			{
				PinStyle(SlotBit(.SlotWidth) | SlotBit(.SlotHeight));
				let w = LayoutLength.Px(value.X);
				let h = LayoutLength.Px(value.Y);
				styleChanged = !(mLayoutStyle.Width == w) || !(mLayoutStyle.Height == h);
				mLayoutStyle.Width = w;
				mLayoutStyle.Height = h;
			}
			let changed = value != mSize;
			if (changed)
			{
				mSize = value;
				HandleSizeChange();
			}
			if (styleChanged || (changed && !IsBeingPlaced))
				RequestBoxLayout();
		}
	}

	public Rect LocalBounds => .(0.0f, 0.0f, mSize.X, mSize.Y);

	/// The world transform accumulates the parent chain (parentWorld * local). A node in the top
	/// layer (an open popup) sits in its root's space instead: its position is the root's.
	public Transform2D WorldTransform
	{
		get
		{
			if (mTopLayer)
			{
				var root = this;
				while (root.mParent != null)
					root = root.mParent;
				return root.Transform * Transform;
			}
			return (mParent != null) ? (mParent.ChildrenTransform * Transform) : Transform;
		}
	}

	/// Where this node's children sit in the world: its own world transform, moved by its scroll
	/// offset (a scroll container's content scrolls without being laid out again).
	public Transform2D ChildrenTransform
	{
		get
		{
			var t = WorldTransform;
			if ((mScrollOffset.X != 0.0f) || (mScrollOffset.Y != 0.0f))
			{
				let shift = ScrollShift;
				t.Translate(-shift.X, -shift.Y);
			}
			return t;
		}
	}

	public Float2 ConvertToWorldSpace(Float2 nodePoint) => WorldTransform.TransformPoint(nodePoint);
	public Float2 ConvertToNodeSpace(Float2 worldPoint) => WorldTransform.GetInverse().TransformPoint(worldPoint);

	/// A point of this node in its root's own space, where a popup attached to the root is placed.
	/// The root's transform (its display scale) maps that space to device pixels, which is what
	/// world space is.
	public Float2 ConvertToRootSpace(Float2 nodePoint)
	{
		var root = this;
		while (root.mParent != null)
			root = root.mParent;
		return root.ConvertToNodeSpace(ConvertToWorldSpace(nodePoint));
	}

	public Float2 ScreenPosition => ConvertToWorldSpace(.(0.0f, 0.0f));
	public Rect ScreenBounds => WorldTransform.TransformRect(LocalBounds);

	// === Visibility / enabled / alpha ===

	/// Hidden (CSS `visibility: hidden`): not drawn and takes no input, but keeps its place in the
	/// layout. Displayed = false takes it out.
	[GuiProperty]
	public bool Visible
	{
		get => mVisible;
		set
		{
			PinStyle(SlotBit(.SlotVisibility));
			if (value == mVisible)
				return;
			mVisible = value;
			HandleVisibilityChange();
		}
	}

	public bool IsTreeVisible => mVisible && Displayed && ((mParent == null) || mParent.IsTreeVisible);

	/// In the layout, or out of it with its subtree (CSS `display: none`): a page switched away, a
	/// panel collapsed. Shown again, it takes back the display kind it had.
	[GuiProperty]
	public bool Displayed
	{
		get => mLayoutStyle.Kind != .None;
		set
		{
			PinStyle(SlotBit(.SlotDisplay));
			if (value == Displayed)
				return;
			if (value)
				mLayoutStyle.Kind = mDisplayBeforeNone;
			else
			{
				mDisplayBeforeNone = mLayoutStyle.Kind;
				mLayoutStyle.Kind = .None;
			}
			RequestBoxLayout();
			Invalidate();
		}
	}

	[GuiProperty]
	public bool Enabled
	{
		get => mEnabled;
		set
		{
			PinStyle(SlotBit(.SlotEnabled));
			if (value == mEnabled)
				return;
			mEnabled = value;
			HandleEnabledChange();
		}
	}

	/// Enabled itself and under enabled ancestors: a disabled panel disables what it holds.
	public bool IsTreeEnabled => mEnabled && ((mParent == null) || mParent.IsTreeEnabled);

	public float Alpha
	{
		get => mAlpha;
		set
		{
			PinStyle(SlotBit(.SlotOpacity));
			mAlpha = value;
			Invalidate();
		}
	}

	/// Alpha, as markup, bindings and scripts name it.
	[GuiProperty]
	public float Opacity
	{
		get => mAlpha;
		set => Alpha = value;
	}

	// === Hit testing ===

	/// When false, this node is transparent to the pointer: OverFind skips it (clicks fall through
	/// to whatever is behind), though it still draws. Useful for decorative overlays (a title-bar
	/// caption, an image over a draggable area). Children are still hit-tested.
	public bool HitTestVisible
	{
		get => mHitTestVisible;
		set => mHitTestVisible = value;
	}

	/// CSS `pointer-events`: `none` is HitTestVisible = false, `auto` the default.
	[GuiProperty("pointer-events")]
	public StringView PointerEvents
	{
		get => mHitTestVisible ? "auto" : "none";
		set => HitTestVisible = value != "none";
	}

	/// The pointer's look over this node (CSS `cursor`); Auto takes its parent's.
	public Sedulous.GUI.Cursor Cursor
	{
		get => mCursor;
		set => mCursor = value;
	}

	/// The look the pointer takes over it now: its `cursor`, unless what is under the pointer says
	/// otherwise (a rich text's link shows the pointer hand).
	public virtual Sedulous.GUI.Cursor CursorNow => mCursor;

	[GuiProperty("cursor")]
	public StringView CursorName
	{
		get => sCursorNames[(int)mCursor];
		set => mCursor = CursorNamed(value);
	}

	/// What a finger over it may do that the GUI does itself (CSS `touch-action`, cTouch* bits);
	/// not inherited: an ancestor narrows it instead (EffectiveTouchActions).
	public uint8 TouchActions
	{
		get => mTouchActions;
		set => mTouchActions = (uint8)(value & cTouchAuto);
	}

	/// Its own value narrowed by every ancestor's, as CSS intersects them.
	public uint8 EffectiveTouchActions
	{
		get
		{
			uint8 bits = cTouchAuto;
			for (var n = this; n != null; n = n.mParent)
				bits &= n.mTouchActions;
			return bits;
		}
	}

	/// A text it does not know is `auto`, its initial value, as a dropped declaration leaves it.
	[GuiProperty("touch-action")]
	public StringView TouchActionName
	{
		get => NodeDetail.sTouchActionNames[(int)(mTouchActions & cTouchAuto)];
		set => mTouchActions = TouchActionsNamed(value) ?? cTouchAuto;
	}

	public virtual bool PointInside(Float2 worldPoint)
	{
		if (!mHitTestVisible)
			return false;
		return WithinBox(worldPoint);
	}

	/// Whether a world point lies in its box, whether or not it takes the pointer.
	public bool WithinBox(Float2 worldPoint)
	{
		let p = ConvertToNodeSpace(worldPoint);
		return (p.X >= 0.0f) && (p.X <= mSize.X) && (p.Y >= 0.0f) && (p.Y <= mSize.Y);
	}

	/// Whether any child sets a z-index (else they paint and hit-test as they stand).
	public bool HasStackedChildren
	{
		get
		{
			// Kept until the children or one's z-index change: asked on every draw and hit test, it
			// read each child, which on a long column cost more than drawing what shows.
			if (!mStackedKnown)
			{
				mStacked = false;
				for (let child in mChildren)
					mStacked = mStacked || (child.mLayoutStyle.ZIndex != 0);
				mStackedKnown = true;
			}
			return mStacked;
		}
	}

	/// Its children in paint order: by z-index (CSS's, among siblings), then as they stand.
	public void ChildrenInPaintOrder(List<Node> outOrder)
	{
		outOrder.Clear();
		for (let child in mChildren)
			outOrder.Add(child);
		for (int i = 1; i < outOrder.Count; i++) // insertion sort: stable, and sibling lists are short
		{
			for (int j = i; (j > 0) && (outOrder[j].mLayoutStyle.ZIndex < outOrder[j - 1].mLayoutStyle.ZIndex); j--)
			{
				let swap = outOrder[j];
				outOrder[j] = outOrder[j - 1];
				outOrder[j - 1] = swap;
			}
		}
	}

	/// The topmost visible descendant (or self) under a world point; null if none.
	public virtual Node OverFind(Float2 worldPoint)
	{
		if (!mVisible || !Displayed || mLeaving || mInert) // a leaving or inert node takes no pointer
			return null;
		// A scroll container's bars lie over its content: a press on one is the container's.
		if (IsScrollContainer && mHitTestVisible)
		{
			let p = ConvertToNodeSpace(worldPoint);
			if (ScrollBarTrack(0).Contains(p) || ScrollBarTrack(1).Contains(p))
				return this;
		}
		// What it clips is hit only where it shows: a row scrolled out of a list takes no press over
		// what lies beyond the list (navigation skips it likewise).
		if (!ClipsChildren || WithinBox(worldPoint))
		{
			// The topmost first: the last drawn (z-index, then the order they stand in).
			let order = scope List<Node>();
			if (HasStackedChildren)
				ChildrenInPaintOrder(order);
			else if (mChildren.Count >= cIndexedChildren)
			{
				// Many children: those whose drawing holds the point, from the index.
				var p = ConvertToNodeSpace(worldPoint);
				if ((mScrollOffset.X != 0.0f) || (mScrollOffset.Y != 0.0f))
				{
					let shift = ScrollShift;
					p = .(p.X + shift.X, p.Y + shift.Y);
				}
				ChildrenReaching(.(p.X, p.Y, 0.0f, 0.0f), order);
				for (int i = order.Count - 1; i >= 0; i--)
				{
					if (!order[i].mTopLayer)
					{
						let hit = order[i].OverFind(worldPoint);
						if (hit != null)
							return hit;
					}
				}
				return PointInside(worldPoint) ? this : null;
			}
			let count = order.IsEmpty ? mChildren.Count : order.Count;
			for (int i = count - 1; i >= 0; i--)
			{
				let child = order.IsEmpty ? mChildren[i] : order[i];
				if (!child.mTopLayer) // the top layer is hit-tested first, from the root
				{
					let hit = child.OverFind(worldPoint);
					if (hit != null)
						return hit;
				}
			}
		}
		return PointInside(worldPoint) ? this : null;
	}

	// === The top layer ===

	/// Open as a popup: drawn after the whole tree in its root's space, unclipped by its ancestors,
	/// hit-tested first, out of its parent's layout, while staying in its owner's subtree (its
	/// styles and its events' route). The dispatcher's popup stack sets it.
	public bool InTopLayer
	{
		get => mTopLayer;
		set
		{
			if (value == mTopLayer)
				return;
			mTopLayer = value;
			if (mParent != null)
				mParent.RequestLayout(); // in or out of its parent's flow
			Invalidate();
		}
	}

	/// Takes the GUI's "enter the menu bar" key (F10, the `menu.enter-bar` command): a menu bar
	/// focuses its first menu. False when it is not one to enter.
	public virtual bool EnterFromKeyboard() => false;

	/// What a modal popup draws over the root under itself: a dim (a widget's `::backdrop` part).
	public virtual void DrawBackdrop(DrawContext ctx, Rect bounds)
	{
		FilledBox(.(0.0f, 0.0f, 0.0f, 0.45f), scope NodeBox()).DrawUnder(ctx, bounds);
	}

	/// Where an event's route ends (a modal popup: what is below it is inert, its owner too).
	public bool RouteStop
	{
		get => mRouteStop;
		set => mRouteStop = value;
	}

	// === Drawing === A node draws its box (SetBox, or a sheet's) under what it draws itself.

	/// Clips its children to its box (ClipsChildren says whether it does, by this or its overflow).
	public bool ClipChildren
	{
		get => mClipChildren;
		set
		{
			if (value == mClipChildren)
				return;
			mClipChildren = value;
			Invalidate();
		}
	}

	/// Clips its children to its box: set so, or its overflow is not visible (hidden, scroll, auto).
	public bool ClipsChildren => mClipChildren || (mLayoutStyle.OverflowX != .Visible) || (mLayoutStyle.OverflowY != .Visible);

	/// Draws this node and its subtree through the DrawContext, applying the node's transform,
	/// opacity and optional child clip. Order: background, OnDraw, children (back to front),
	/// foreground.
	public void Draw(DrawContext ctx)
	{
		if (!mVisible || !Displayed)
			return;

		ctx.Save();
		ctx.ConcatTransform(Transform);
		// Nothing it or its subtree draws reaches the clip: none of it is drawn.
		if (!ctx.IsVisible(SubtreeInk))
		{
			ctx.CountCulled();
			mDrawnAreaValid = false; // not on screen: nothing of it to draw again
			mDamageNoted = false;
			ctx.Restore();
			return;
		}
		// In view though fully transparent, it counts as drawn: a fade in from nothing is in view,
		// so its frames are asked for (not taken for a quiet animation out of sight).
		mDrawnFrame = ctx.Frame;
		if (mAlpha <= 0.0f)
		{
			mDrawnAreaValid = false; // shows nothing (a fade out noted where it showed)
			mDamageNoted = false;
			ctx.Restore();
			return;
		}
		// Damage: where it covers now, when that is new, changed or moved, beside where it covered
		// before (noted when it changed).
		if (ctx.RecordsDamage)
		{
			let area = ctx.DeviceRect(SubtreeInk);
			if (!mDrawnAreaValid || mDamageNoted || !(area == mDrawnArea))
				ctx.RecordDamage(area);
			mDrawnArea = area;
			mDrawnAreaValid = true;
			mDamageNoted = false;
		}
		ctx.CountDrawn();
		if (mInvalidatedSelf && ctx.RecordsRedraws && (mParent != null)) // the root would flash all
			ctx.RecordRedraw(ScreenBounds);
		mInvalidatedSelf = false;
		if (mBox.TextEffectsSet != 0)
			ctx.VG.SetTextEffects(mBox.MergeTextEffects(ctx.VG.TextEffects));
		// A node with children fades as one picture (CSS's opacity), as does one with a filter or a
		// blend: through a VG layer, composited once. A leaf's opacity multiplies into what it
		// draws (no offscreen target for a label).
		let layered = mBox.NeedsLayer || ((mAlpha < 1.0f) && !mChildren.IsEmpty);
		let pushedOpacity = !layered && (mAlpha < 1.0f);
		// A backdrop blur is of what lies behind the node, so a node drawing through a layer (where
		// nothing lies behind) draws it first, onto the canvas behind, at its opacity, as CSS
		// composites it: frosted glass fading in blurs as it fades, rather than showing the
		// backdrop sharp until the fade ends and then the blur all at once.
		let backdropFirst = layered && (mBox.BackdropBlur > 0.0f);
		if (backdropFirst)
		{
			ctx.PushOpacity(mAlpha);
			mBox.DrawBackdrop(ctx, LocalBounds);
			ctx.PopOpacity();
		}
		if (layered)
			ctx.VG.PushLayer(mAlpha, mBox.BlendMode, mBox.FilterBlur * ctx.DeviceScale);
		else if (pushedOpacity)
			ctx.PushOpacity(mAlpha);

		let local = LocalBounds;

		mBox.DrawUnder(ctx, local, !backdropFirst);
		OnDraw(ctx, local);

		// Children clip to the box, its rounded corners included (a path clip; a host without
		// stencil fills gets the bounds' scissor).
		let clips = ClipsChildren;
		let roundedClip = clips && !mBox.Radii.IsZero;
		if (roundedClip)
		{
			let shape = scope PathBuilder();
			ShapeBuilder.BuildRoundedRect(local.ToRectangle(), mBox.Radii, shape);
			let clip = shape.ToPath();
			ctx.VG.PushClipPath(clip); // flattened as it is pushed
			delete clip;
		}
		else if (clips)
			ctx.PushClip(local);
		let scrolled = (mScrollOffset.X != 0.0f) || (mScrollOffset.Y != 0.0f);
		if (scrolled)
		{
			ctx.Save();
			let shift = ScrollShift;
			var t = Transform2D();
			t.Translate(-shift.X, -shift.Y);
			ctx.ConcatTransform(t);
		}
		Rect view = .();
		if (!HasStackedChildren && (mChildren.Count >= cIndexedChildren) && ctx.GetVisibleBounds(out view))
		{
			// Many children under a clip: those that can reach it, from the index, rather than each
			// asked in turn (a long column visited thousands only to cull them).
			let shown = scope List<Node>();
			ChildrenReaching(view, shown);
			for (let child in shown)
			{
				if (!child.mTopLayer)
					child.Draw(ctx);
			}
		}
		else if (!HasStackedChildren)
		{
			for (int i = 0; i < mChildren.Count; i++)
			{
				let child = mChildren[i];
				if (!child.mTopLayer) // drawn by the root's top layer, after the tree
					child.Draw(ctx);
			}
		}
		else
		{
			let order = scope List<Node>();
			ChildrenInPaintOrder(order);
			for (let child in order)
			{
				if (!child.mTopLayer)
					child.Draw(ctx);
			}
		}
		if (scrolled)
			ctx.Restore();
		if (roundedClip)
			ctx.VG.PopClipPath();
		else if (clips)
			ctx.PopClip();

		if (IsScrollContainer)
			DrawScrollBars(ctx);

		if (layered)
			ctx.VG.PopLayer();
		else if (pushedOpacity)
			ctx.PopOpacity();
		OnDrawAbove(ctx);
		ctx.Restore();
		mNeedsRedraw = false; // drawn: clean until something invalidates it again
	}

	/// Its children whose drawing can reach `area` (in their parent's space, past its scroll), in
	/// their order, from its index of them, added to `outNodes`. The index is checked against the
	/// children once something under it changed, and built again only when a child's reach moved:
	/// a colour animating in a row costs no rebuild, a row resized does.
	public void ChildrenReaching(Rect area, List<Node> outNodes)
	{
		RefreshChildIndex();
		let index = mChildIndex;
		let vertical = index.Vertical;
		let lo = vertical ? area.Y : area.X;
		let hi = vertical ? area.Bottom : area.Right;
		let n = index.Order.Count;
		// Those starting at or before the area's far edge: a prefix of the order.
		int first = 0;
		int last = n;
		{
			int a = 0;
			int b = n;
			while (a < b)
			{
				let mid = (a + b) / 2;
				let r = index.Rects[(int)index.Order[mid]];
				if ((vertical ? r.Y : r.X) <= hi)
					a = mid + 1;
				else
					b = mid;
			}
			last = a;
		}
		// And of those, the ones from where the farthest reach so far gets to the near edge.
		{
			int a = 0;
			int b = last;
			while (a < b)
			{
				let mid = (a + b) / 2;
				if (index.Reach[mid] < lo)
					a = mid + 1;
				else
					b = mid;
			}
			first = a;
		}
		let picked = scope List<uint32>();
		for (int j = first; j < last; j++)
		{
			let i = index.Order[j];
			let r = index.Rects[(int)i];
			if ((r.X <= area.Right) && (area.X <= r.Right) && (r.Y <= area.Bottom) && (area.Y <= r.Bottom))
				picked.Add(i);
		}
		picked.Sort(scope (a, b) => a <=> b); // few, and nearly in order already
		for (let i in picked)
			outNodes.Add(mChildren[(int)i]);
	}

	/// How many times its index of its children was built (tests, the inspector): once, then again
	/// only when a child's reach moved.
	public uint32 ChildIndexBuilds => mChildIndexBuilds;

	/// What it draws itself, in its own space: its box grown by its outer shadows (three sigma of
	/// their blur past their spread and offset). A widget drawing past its box adds that (a label's
	/// overflowing text); a filter's blur is added over the whole subtree.
	public virtual Rect InkBounds
	{
		get
		{
			var ink = LocalBounds;
			for (let shadow in mBox.Shadows)
			{
				if (shadow.Inset)
					continue;
				let reach = shadow.Spread + 1.5f * shadow.Blur; // the blur is CSS's: sigma is half
				ink = Rect.Union(ink, .(shadow.Offset.X - reach, shadow.Offset.Y - reach, mSize.X + 2.0f * reach, mSize.Y + 2.0f * reach));
			}
			return ink;
		}
	}

	/// What it and its subtree draw, in its own space: its ink and its shown children's (within its
	/// box when it clips them), grown by its filter's blur. Kept until it or something in it
	/// invalidates, which reaches every ancestor of what changed.
	public Rect SubtreeInk
	{
		get
		{
			if (mSubtreeInkValid)
				return mSubtreeInk;
			var ink = InkBounds;
			if (!ClipsChildren && (mChildren.Count >= cIndexedChildren))
			{
				// Many children: what the index holds of their reach, not each asked again. It
				// counts hidden ones too, so it is never smaller than what they draw.
				RefreshChildIndex();
				if (!mChildren.IsEmpty)
					ink = Rect.Union(ink, mChildIndex.Bounds);
			}
			else if (!ClipsChildren)
			{
				for (let c in mChildren)
				{
					if (c.mTopLayer || !c.mVisible || (c.mAlpha <= 0.0f) || !c.Displayed)
						continue;
					ink = Rect.Union(ink, c.Transform.TransformRect(c.SubtreeInk));
				}
			}
			if (mBox.FilterBlur > 0.0f)
			{
				let reach = 3.0f * mBox.FilterBlur; // a sigma
				ink = .(ink.X - reach, ink.Y - reach, ink.Width + 2.0f * reach, ink.Height + 2.0f * reach);
			}
			mSubtreeInk = ink;
			mSubtreeInkValid = true;
			return mSubtreeInk;
		}
	}

	/// The host's frame it was last drawn in (0: none yet); one hidden or culled keeps an older one.
	public uint32 DrawnFrame => mDrawnFrame;
	/// The host's last drawn frame, as its root counts them (0 outside a GUI or before one).
	public virtual uint32 LastDrawnFrame => (mParent != null) ? mParent.LastDrawnFrame : 0;

	/// Not drawn in the host's last frame: hidden, culled, or under something culled.
	public bool WasOutOfView
	{
		get
		{
			let last = LastDrawnFrame;
			return (last != 0) && (mDrawnFrame != last);
		}
	}

	/// Between these, its invalidations mark it alone, as a hidden node's do: a change that only
	/// paints it differently, made while it is out of view, asks for no frame (it shows when
	/// something brings it into view, which redraws on its own).
	public void BeginQuietInvalidation()
	{
		mQuietInvalidations++;
	}

	public void EndQuietInvalidation()
	{
		mQuietInvalidations--;
	}

	// === What a frame must redo (only what changed: a clean subtree costs nothing) ===

	/// This node must be restyled (with its subtree when `withDescendants`: a selector with a
	/// combinator may match them differently): a class, id, tag or state changed, or it joined a
	/// tree. Its ancestors learn a descendant waits, so the style pass finds it.
	public void MarkStyleDirty(bool withDescendants)
	{
		mStyleDirty = true;
		mStyleSubtreeDirty = mStyleSubtreeDirty || withDescendants;
		for (var p = mParent; (p != null) && !p.mChildStyleDirty; p = p.mParent)
			p.mChildStyleDirty = true;
	}

	/// What a tween moves changed: the style pass applies the style it has with the node's
	/// animated layer over it again, without resolving the cascade anew.
	public void MarkStyleMotionDirty()
	{
		mStyleMotionDirty = true;
		for (var p = mParent; (p != null) && !p.mChildStyleDirty; p = p.mParent)
			p.mChildStyleDirty = true;
	}

	public bool IsStyleMotionDirty => mStyleMotionDirty;

	/// `states` changed on this node: it restyles (its subtree too when the sheets read them
	/// through it).
	public void MarkStyleStateDirty(uint32 states)
	{
		mChangedStyleStates |= states;
		MarkStyleDirty(false);
	}

	public uint32 ChangedStyleStates => mChangedStyleStates;

	/// States the style pass reads as set whatever the node's own (the inspector forcing :hover,
	/// :active, :focus, :focus-visible, :checked or :disabled to see their rules).
	public uint32 ForcedStyleStates
	{
		get => mForcedStyleStates;
		set
		{
			let changed = value ^ mForcedStyleStates;
			if (changed == 0)
				return;
			mForcedStyleStates = value;
			// What a forced state turns with it: disabled is not enabled, focus-visible is focus.
			var marks = changed;
			if ((changed & StateDisabled) != 0)
				marks |= StateEnabled;
			if ((changed & StateFocusVisible) != 0)
				marks |= StateFocus;
			MarkStyleStateDirty(marks);
		}
	}

	/// The children changed (one joined, left or moved): every kept index is stale, and `moved`'s
	/// from another parent too.
	public void ChildrenRearranged(Node moved)
	{
		if (++mChildrenGeneration == cNoGeneration) // never the mark of "none"
			mChildrenGeneration = 0;
		moved.mIndexGeneration = cNoGeneration;
	}

	/// Its children's arrangement changed: a selector reading siblings (:nth-child, `+`, `~`) may
	/// match them differently. The style pass decides once whether they restyle (it knows its
	/// sheets); marking each child here made building a long list quadratic.
	public void ChildrenStyleChanged()
	{
		mChildIndexAll = true; // its index of its children is of others
		mStackedKnown = false;
		mChangedChildren.Clear();
		MarkAccessDirty(); // its accessibility node's children changed
		mChildrenArrangementChanged = true;
		MarkStyleDirty(false);
	}

	/// Its children were added, removed or moved since its last restyle.
	public bool ChildrenArrangementChanged => mChildrenArrangementChanged;
	public bool IsStyleDirty => mStyleDirty;
	public bool IsStyleSubtreeDirty => mStyleSubtreeDirty;
	public bool HasStyleDirtyDescendant => mChildStyleDirty;

	public void ClearStyleDirty()
	{
		mStyleDirty = false;
		mStyleMotionDirty = false;
		mStyleSubtreeDirty = false;
		mChildStyleDirty = false;
		mChildrenArrangementChanged = false;
		mChangedStyleStates = 0;
	}

	/// Pins `slots` as code's (no-op while a StyleWriteScope lives).
	public void PinStyle(StyleSlotSet slots)
	{
		if (!mStyleWriting)
			mStylePins = mStylePins | slots;
	}

	/// Gives `slots` back to the sheet: the next restyle sets them, or returns them to the node's
	/// own value.
	public void UnpinStyle(StyleSlotSet slots)
	{
		mStylePins = mStylePins & ~slots;
		MarkStyleDirty(false);
	}

	public bool IsStylePinned(StyleSlot slot) => mStylePins.Has(slot);
	public StyleSlotSet StylePins => mStylePins;
	/// A StyleWriteScope lives (a sheet or a widget's defaults are writing).
	public bool IsStyleWriting => mStyleWriting;

	/// Its own values, captured now unless they were already.
	public UnstyledValues CaptureUnstyledValues()
	{
		if (!mUnstyled.Captured)
		{
			mUnstyled.Captured = true;
			mUnstyled.Alpha = mAlpha;
			mUnstyled.Padding = mPadding;
			mUnstyled.Layout.Set(mLayoutStyle);
			mUnstyled.Visible = mVisible;
			mUnstyled.Enabled = mEnabled;
			mUnstyled.ClipChildren = mClipChildren;
		}
		return mUnstyled;
	}

	// === Layout ===
	// A node asks for a size within constraints (Measure: the size its style and content want,
	// cached until either changes) and is placed by its container (Arrange), which lays out its own
	// children when its size changed or they did (OnLayout: by its display kind, or a composite
	// widget's own arrangement). The bodies are Layout/LayoutImpl.bf.

	/// What it asks of layout. Read it here; set it whole (a copy is taken, and what changed from
	/// code is pinned) or edit it with EditLayoutStyle, either of which lays out again.
	public Sedulous.GUI.LayoutStyle LayoutStyle
	{
		get => mLayoutStyle;
		set
		{
			PinStyle(ChangedLayoutSlots(mLayoutStyle, value)); // from code: what it changed is its own
			if ((value.ZIndex != mLayoutStyle.ZIndex) && (mParent != null))
				mParent.mStackedKnown = false; // its parent paints its children in another order
			mLayoutStyle.Set(value);
			RequestBoxLayout();
		}
	}

	/// Edits a copy of the layout style (`edit(style)`), then sets it, laying out again.
	public void EditLayoutStyle(delegate void(Sedulous.GUI.LayoutStyle style) edit)
	{
		let edited = scope Sedulous.GUI.LayoutStyle();
		edited.Set(mLayoutStyle);
		edit(edited);
		LayoutStyle = edited;
	}

	/// The space inside the border the content starts from: its lengths, and its percentages of the
	/// containing box's width beside them (resolved against the width it was last measured in).
	/// Set from code, it is lengths alone.
	public Thickness Padding
	{
		get
		{
			if ((mPaddingPercent == Thickness()) || (mPercentWidth <= 0.0f))
				return mPadding;
			let k = mPercentWidth * 0.01f;
			return .(mPadding.Left + mPaddingPercent.Left * k, mPadding.Top + mPaddingPercent.Top * k,
				mPadding.Right + mPaddingPercent.Right * k, mPadding.Bottom + mPaddingPercent.Bottom * k);
		}
		set
		{
			PinStyle(SlotBit(.SlotPaddingTop) | SlotBit(.SlotPaddingRight) | SlotBit(.SlotPaddingBottom) | SlotBit(.SlotPaddingLeft));
			mPadding = value;
			mPaddingPercent = .();
			RequestLayout();
			Invalidate();
		}
	}

	/// Padding in percentages of the containing box's width beside the lengths (CSS's
	/// `padding: 5%`; the style pass sets it).
	public Thickness PaddingPercent
	{
		get => mPaddingPercent;
		set
		{
			if (value == mPaddingPercent)
				return;
			mPaddingPercent = value;
			RequestLayout();
			Invalidate();
		}
	}

	/// Its padding as set, without the percentages.
	public Thickness PaddingLengths => mPadding;

	/// The space outside the border its container keeps clear.
	public Thickness Margin
	{
		get => mLayoutStyle.Margin;
		set
		{
			PinStyle(SlotBit(.SlotMarginTop) | SlotBit(.SlotMarginRight) | SlotBit(.SlotMarginBottom) | SlotBit(.SlotMarginLeft));
			mLayoutStyle.Margin = value;
			mLayoutStyle.MarginPercent = .(); // code gives lengths
			RequestBoxLayout();
		}
	}

	/// Its margin within a containing box `width` wide: its lengths and its percentages of that
	/// width (none when the width is not known, below 0).
	public Thickness GetMarginWithin(float width)
	{
		let p = mLayoutStyle.MarginPercent;
		if ((width <= 0.0f) || (p == Thickness()))
			return mLayoutStyle.Margin;
		let k = width * 0.01f;
		let m = mLayoutStyle.Margin;
		return .(m.Left + p.Left * k, m.Top + p.Top * k, m.Right + p.Right * k, m.Bottom + p.Bottom * k);
	}

	/// The box's border widths (its NodeBox's), the part of its chrome a sheet's border gives.
	public Thickness BorderThickness
	{
		get
		{
			let w = mBox.BorderWidths;
			return .(w.Left, w.Top, w.Right, w.Bottom);
		}
	}

	/// Padding and border: what lies between the box's edge and its content.
	public Thickness Chrome
	{
		get
		{
			let b = BorderThickness;
			let p = Padding;
			return .(p.Left + b.Left, p.Top + b.Top, p.Right + b.Right, p.Bottom + b.Bottom);
		}
	}

	/// The local bounds inset by the padding and border: where content and children go.
	public Rect ContentBounds
	{
		get
		{
			let c = Chrome;
			return .(c.Left, c.Top, Max(0.0f, mSize.X - c.TotalHorizontal), Max(0.0f, mSize.Y - c.TotalVertical));
		}
	}

	/// Where this node's baseline sits, down from its top, when its border box is `size`: what a
	/// flex row with `align-items: baseline` lines up. A widget showing text answers its first
	/// line's; any other node the bottom of its content box.
	public virtual float BaselineAt(Float2 size) => size.Y - Chrome.Bottom;

	/// Its baseline at the size it has.
	public float Baseline => BaselineAt(mSize);

	/// Lays out the children again where something in this subtree asked (the pass a GUI runs each
	/// frame), keeping this node where it is.
	public void ArrangeAgain()
	{
		Arrange(.(mPosition.X, mPosition.Y, mSize.X, mSize.Y));
	}

	/// Device pixels per logical unit where this node was last laid out (its GUI's display scale; 1
	/// in a tree with no GUI). Layout rounds every arranged edge to that grid, so borders and
	/// backgrounds land on whole device pixels at any scale.
	public float PixelScale => mPixelScale;

	/// Its own box changed (its size, margin, display, position): its container lays out again too.
	public void RequestBoxLayout()
	{
		RequestLayout();
		if (mParent != null)
			mParent.RequestLayout();
	}

	public bool IsLayoutDirty => mLayoutDirty;
	public bool HasLayoutDirtyDescendant => mChildLayoutDirty;

	/// Inside this node's own placement or its parent's layout: a size or a position set now is the
	/// layout's, not code's.
	public bool IsBeingPlaced => mPlacing || ((mParent != null) && mParent.mLayingOut);

	/// How many containers laid out on this thread (a GUI's pass reads the difference).
	public static uint32 LayoutRunCounter => sLayoutRunCounter;

	// === Scrolling (overflow: scroll or auto) ===

	/// Whether this node scrolls its content on either axis.
	public bool IsScrollContainer => NodeDetail.Scrolls(mLayoutStyle.OverflowX) || NodeDetail.Scrolls(mLayoutStyle.OverflowY);

	/// How far the content is scrolled (its children move by minus this). Set, it scrolls there at
	/// once (ending a smooth scroll or a fling), kept within the range on the axes that scroll
	/// (with a layout pending, kept as asked until the layout knows the content's extent and
	/// clamps it).
	public Float2 ScrollOffset
	{
		get => mScrollOffset;
		set
		{
			mSmoothScrolling = false;
			mFlinging = false;
			ApplyScrollOffset(value);
		}
	}

	public void StopFling()
	{
		mFlinging = false;
	}

	public bool IsFlinging => mFlinging;

	/// Keeps it at the end of its content as the content grows (a log, a chat), while it is at the
	/// end: scrolled away it lets go, and back at the end it holds again (AUI's way).
	[GuiProperty("stick-to-end")]
	public bool StickToEnd
	{
		get => mStickToEnd;
		set
		{
			mStickToEnd = value;
			mLatchedToEnd = value && IsAtScrollEnd;
		}
	}

	/// Held at the end now (stick-to-end and at the end).
	public bool IsLatchedToEnd => mStickToEnd && mLatchedToEnd;

	/// At the end of its content on the axis ScrollToEnd moves (within half a pixel).
	public bool IsAtScrollEnd
	{
		get
		{
			let range = ScrollRange;
			if ((range.Y > 0.0f) || (range.X <= 0.0f))
				return mScrollOffset.Y >= range.Y - 0.5f;
			return ScrollsFromRight ? (mScrollOffset.X <= ScrollMin.X + 0.5f) : (mScrollOffset.X >= range.X - 0.5f);
		}
	}

	/// Where a smooth scroll is going (the offset itself when none runs).
	public Float2 ScrollTarget => mSmoothScrolling ? mScrollTarget : mScrollOffset;
	public bool IsSmoothScrolling => mSmoothScrolling;

	/// Scrolls by `delta` from where it is going, at once or easing (Auto: the node's own way).
	public void ScrollBy(Float2 delta, ScrollBehavior behavior = .Instant)
	{
		let from = ScrollTarget;
		ScrollTo(.(from.X + delta.X, from.Y + delta.Y), behavior);
	}

	/// The scroll offset as the children move by it: on the device grid, as their edges are.
	public Float2 ScrollShift => .(Round(mScrollOffset.X * mPixelScale) / mPixelScale, Round(mScrollOffset.Y * mPixelScale) / mPixelScale);

	/// How far the content can scroll on each axis that scrolls (0 on one that does not).
	public Float2 ScrollRange
	{
		get
		{
			let contentBox = ContentBounds;
			return .(NodeDetail.Scrolls(mLayoutStyle.OverflowX) ? Max(0.0f, mContentExtent.X - contentBox.Width) : 0.0f,
				NodeDetail.Scrolls(mLayoutStyle.OverflowY) ? Max(0.0f, mContentExtent.Y - contentBox.Height) : 0.0f);
		}
	}

	/// Where the offset may go on each axis (CSS's scroll positions): from 0 at the content's start
	/// to its range, except across a right-to-left scroller, whose start is its right, so it goes
	/// from minus its range at the left to 0 there.
	public Float2 ScrollMin => .(ScrollsFromRight ? -ScrollRange.X : 0.0f, 0.0f);

	public Float2 ScrollMax
	{
		get
		{
			let range = ScrollRange;
			return .(ScrollsFromRight ? 0.0f : range.X, range.Y);
		}
	}

	/// Its content starts at its right and overflows to the left: it scrolls across, its flow
	/// running right to left (a dock's sides stay where they say).
	public bool ScrollsFromRight
	{
		get
		{
			let across = (mLayoutStyle.OverflowX == .Scroll) || (mLayoutStyle.OverflowX == .Auto);
			return across && (mLayoutStyle.Kind != .Dock) && (mLayoutStyle.Kind != .None) && IsRightToLeft;
		}
	}

	/// The content's size as last laid out: what a scroll container scrolls over.
	public Float2 ContentExtent => mContentExtent;

	/// How far the wheel scrolls per notch, and the arrow keys per press.
	public float ScrollStep
	{
		get => mScrollStep;
		set => mScrollStep = value;
	}

	/// Whether, focused, the arrows, Page Up and Down, Home and End scroll it (true): a scroller
	/// whose keys are its own (a code editor's caret moves) says false, the keymap then hearing
	/// them; the wheel and the bars scroll it still.
	public bool ScrollsByKeys
	{
		get => mScrollsByKeys;
		set => mScrollsByKeys = value;
	}

	/// A part's own states (`::scrollbar-thumb:hover` matches through them): a scroller's bar
	/// hovered, its thumb hovered or dragged. A widget with parts of its own adds theirs.
	public virtual uint32 GetPartStates(StringView part)
	{
		if (part == "scrollbar-thumb")
			return ((mScrollHover == 2) ? StateHover : 0) | ((mScrollDragAxis <= 1) ? StateActive : 0);
		if (part == "scrollbar")
			return ((mScrollHover != 0) || (mScrollDragAxis <= 1)) ? StateHover : 0;
		return 0;
	}

	/// A part's style as the sheet set it (a UINode's; null for a bare node).
	public virtual PartStyle FindPartStyle(StringView part) => null;

	/// How visible an overlay scroller's bars are now, 0 to 1 (1 for bars that stay).
	public float ScrollbarOpacity => (mLayoutStyle.BarVisibility == .Overlay) ? mScrollbarAlpha : 1.0f;

	// === The box ===
	// Background colour and layers, a border per side, radii and shadows, drawn under the node's
	// content. A sheet sets it (fromStyle: the next restyle replaces or clears it); native code may
	// set it directly.

	/// Copies `box` into the node's box (the caller keeps its own).
	public void SetBox(NodeBox nodeBox, bool fromStyle = false)
	{
		mBox.Set(nodeBox);
		mBoxFromStyle = fromStyle;
		Invalidate();
	}

	/// Its box (the node's own: read it, or set a new one with SetBox).
	public NodeBox Box => mBox;

	/// Whether its box paints a fill of its own (a background colour, a layer, a border image): a
	/// widget's default face then gives way to it (a theme's).
	public bool BoxFills => (mBox.BackgroundColor.A > 0.0f) || !mBox.Layers.IsEmpty || mBox.Skin.HasPicture;

	public bool IsBoxFromStyle => mBoxFromStyle;

	/// CSS's `transform` about `transform-origin`: functions applied left to right after the node's
	/// own position, scale and rotation; translations and the origin in percentages resolve against
	/// the node's size, now and whenever it changes. The functions are copied.
	public void SetStyleTransform(List<TransformFunction> functions, LengthValue originX, LengthValue originY, bool fromStyle = true)
	{
		if (functions !== mStyleTransforms)
		{
			mStyleTransforms.Clear();
			mStyleTransforms.AddRange(functions);
		}
		mTransformOriginX = originX;
		mTransformOriginY = originY;
		mTransformFromStyle = fromStyle;
		UpdateStyleTransform();
	}

	public bool IsTransformFromStyle => mTransformFromStyle;
	public List<TransformFunction> StyleTransforms => mStyleTransforms;

	/// Places the children in the content box (Arrange calls it when needed). The default lays
	/// them out by the display kind (LayoutChildren); a composite widget arranges its own.
	public virtual void OnLayout()
	{
		LayoutChildren();
	}

	/// Subclass-drawn content, between background and children.
	public virtual void OnDraw(DrawContext ctx, Rect localBounds)
	{
	}

	// === Coordinator lookup + lifecycle ===
	// The SceneRoot's ActionManager / MutationQueue and the rest, found by walking to the root:
	// the base returns the parent's, a SceneRoot its own. Null when the node is not attached under
	// a SceneRoot.

	/// Where children given to this node by markup or a script go: the node itself, or, for a
	/// widget built of parts (a scroller, a window), the part that holds its content.
	public virtual Node ChildHost => this;

	/// Where this node's bindings wait for the frame: its SceneRoot's scheduler, or none outside a
	/// scene (a binding then runs at once).
	public virtual Sedulous.GUI.EffectScheduler EffectScheduler => (mParent != null) ? mParent.EffectScheduler : null;
	public virtual Sedulous.GUI.ActionManager ActionManager => (mParent != null) ? mParent.ActionManager : null;
	public virtual Sedulous.GUI.MutationQueue MutationQueue => (mParent != null) ? mParent.MutationQueue : null;
	/// What the GUI this node is in may create (its SceneRoot's set), or null when detached.
	public virtual Sedulous.GUI.ElementSet ElementSet => (mParent != null) ? mParent.ElementSet : null;
	/// The element table of the GUI this node is in (its SceneRoot's), or null when detached.
	public virtual Sedulous.GUI.ElementTable ElementTable => (mParent != null) ? mParent.ElementTable : null;
	/// What the last frame of the GUI this node is in cost (its SceneRoot's), or null when
	/// detached: the phases write it as they run.
	public virtual Sedulous.GUI.FrameStats FrameStats => (mParent != null) ? mParent.FrameStats : null;

	/// A short name for diagnostics: its type (a widget adds its id), appended to `outText`.
	public virtual void DebugName(String outText)
	{
		GetType().GetName(outText);
	}

	/// The font service of the GUI this node is in (its SceneRoot's context's), or null: what a
	/// rich text's runs that set a font of their own ask.
	public virtual IFontService FontService => (mParent != null) ? mParent.FontService : null;
	/// The resources of the GUI this node is in, or null: what loads a rich text's icons.
	public virtual IResourceProvider ResourceProvider => (mParent != null) ? mParent.ResourceProvider : null;

	/// Runs an action on this node: targets it and hands it to the SceneRoot's manager, which takes
	/// a reference of its own (the caller keeps and releases the one it holds). Dropped when the
	/// node is not attached under a SceneRoot.
	public void RunAction(Sedulous.GUI.Action action)
	{
		if (action == null)
			return;
		TargetAction(action);
		let manager = ActionManager;
		if (manager != null)
			manager.AddAction(action);
	}

	/// Makes this node `action`'s target, held weakly too: a node destroyed mid-animation takes its
	/// actions with it. RunAction does it; a step of a group is targeted so, then run by its group.
	public void TargetAction(Sedulous.GUI.Action action)
	{
		action.Target = this;
		let elementRef = TakeElementRef();
		if (elementRef.Table != null)
			action.SetWeakTarget(Sedulous.GUI.Action.WeakTarget(elementRef.Table, elementRef.Slot, elementRef.Generation, => ResolveActionTarget));
	}

	public static Node ResolveActionTarget(Sedulous.GUI.Action.WeakTarget weak) => weak.Table.Resolve(weak.Slot, weak.Generation);

	// === Weak references ===
	// The tree owns its nodes. Anything else holds one weakly: a slot and a generation in its GUI's
	// element table, resolved on every use (Element<T> natively, a handle in a script), reading as
	// gone once the node is destroyed.

	/// This node's place in its GUI's element table, taking a slot the first time; an empty ref
	/// (null table) for a node in no GUI.
	public ElementRef TakeElementRef()
	{
		if (mElementTable == null)
		{
			let table = ElementTable;
			if (table == null)
				return .();
			table.AddRef();
			mElementTable = table;
			mElementSlot = table.Take(this);
		}
		return .(mElementTable, mElementSlot, mElementTable.Generation(mElementSlot));
	}

	public int32 ElementChildCount => (int32)mChildren.Count;

	/// Stops what On or OnCommandScript started, from inside that handler too; false when the
	/// token is none of this node's.
	public bool Off(int32 token)
	{
		let id = (uint32)token;
		return (token > 0) && (RemoveEventListener(id) || RemoveCommandHandler(id));
	}

	/// Removes this node from its tree at the end of the UI's update (Close): never under a running
	/// handler.
	public void Destroy()
	{
		Close();
	}

	[GuiProperty]
	public float Width
	{
		get => mSize.X;
		set => Size = .(value, mSize.Y);
	}

	[GuiProperty]
	public float Height
	{
		get => mSize.Y;
		set => Size = .(mSize.X, value);
	}

	[GuiProperty]
	public float X
	{
		get => mPosition.X;
		set => Position = .(value, mPosition.Y);
	}

	[GuiProperty]
	public float Y
	{
		get => mPosition.Y;
		set => Position = .(mPosition.X, value);
	}

	/// Detaches this node from its tree at the next safe sync point (the SceneRoot's drain), held
	/// alive until then. Removed at once when there is no coordinator.
	public void Close()
	{
		let queue = MutationQueue;
		if (queue != null)
		{
			AddRef(); // kept alive until the deferred op runs
			queue.Enqueue(new () =>
				{
					RemoveFromParent();
					ReleaseRef();
				});
		}
		else
			RemoveFromParent();
	}

	// === Input routing ===

	/// One step of a route, at this node, in `e.Phase`: the capture listeners in the capture and
	/// target phases; this node's handler and its bubble listeners in the target and bubble phases.
	/// Everything at a node runs; marking the event Handled ends the route after it (as the DOM's
	/// stopPropagation does). A node given an event outside a route (an enter or a leave) is given
	/// it at the target. `ownHandler` false: its listeners hear it, its own handler does not (an
	/// event from a popup it holds: a click in a menu is not a click on the button that opened it).
	public void DeliverRouted(Event e, bool ownHandler = true)
	{
		e.CurrentTarget = this;
		if (e.Phase != .Bubble)
			RunListeners(e, true);
		if (e.Phase != .Capture)
		{
			if (ownHandler)
				InvokeInputHandler(e);
			RunListeners(e, false);
		}
	}

	/// Under the pointer: this node or one inside it (the dispatcher's hover path); `:hover`. Set by
	/// the dispatcher as the hover path changes.
	public bool Hovered
	{
		get => mHovered;
		set
		{
			if (value == mHovered)
				return;
			mHovered = value;
			OnPointerStateChange();
		}
	}

	/// Pressed: a press on this node or one inside it, not yet released; `:active`. Set by the
	/// dispatcher as the press path changes.
	public bool Pressed
	{
		get => mPressed;
		set
		{
			if (value == mPressed)
				return;
			mPressed = value;
			OnPointerStateChange();
		}
	}

	public bool HandleActivate() => OnActivate();

	public void HandleFocusGained()
	{
		mFocused = true;
		MarkStyleStateDirty(StateFocus | StateFocusVisible | StateFocusWithin);
		for (var p = mParent; p != null; p = p.mParent)
		{
			p.mFocusWithin++;
			p.MarkStyleStateDirty(StateFocusWithin);
		}
		OnFocusGained();
		SendEvent(scope Event(.FocusGained, this));
	}

	public void HandleFocusLost()
	{
		mFocused = false;
		MarkStyleStateDirty(StateFocus | StateFocusVisible | StateFocusWithin);
		for (var p = mParent; p != null; p = p.mParent)
		{
			if (p.mFocusWithin > 0)
				p.mFocusWithin--;
			p.MarkStyleStateDirty(StateFocusWithin);
		}
		OnFocusLost();
		SendEvent(scope Event(.FocusLost, this));
	}

	public bool IsFocused => mFocused;
	/// Focused, or holding the focused node (CSS's :focus-within).
	public bool IsFocusWithin => mFocused || (mFocusWithin > 0);

	/// Focused, and by the keyboard or a gamepad (CSS's :focus-visible): the focus ring shows in
	/// that use only, not after a click. Set, it is how focus came.
	public bool FocusVisible
	{
		get => mFocused && mFocusVisible;
		set
		{
			if (value == mFocusVisible)
				return;
			mFocusVisible = value;
			if (mFocused)
				MarkStyleStateDirty(StateFocusVisible);
		}
	}

	/// A widget under this node took focus: a scroller brings it into view, by the least that
	/// shows it.
	public virtual void OnDescendantFocused(Node focused)
	{
		ScrollIntoView(focused);
	}

	/// Whether this node brings a focused descendant into view, so a widget its clip hides is
	/// still one navigation reaches (a scroller).
	public virtual bool ScrollsDescendantsIntoView => IsScrollContainer;

	/// Scrolls (a scroll container) to show `descendant` in the content box: by the least that
	/// shows it, or with its start, centre or end at the box's.
	public void ScrollIntoView(Node descendant, ScrollAlign align = .Nearest, ScrollBehavior behavior = .Auto)
	{
		ScrollIntoView(descendant, descendant.LocalBounds, align, behavior);
	}

	/// The part of it the scrollers round it keep in view while it has focus (a text field's
	/// caret, in its own space), as it moves and as their content grows; false: none.
	public virtual bool GetFocusArea(out Rect outArea)
	{
		outArea = .();
		return false;
	}

	// === Drag and drop ===
	// A press that moves past the GUI's threshold offers a drag to the pressed node and then up its
	// ancestors: the first that fills the request starts it, and one that owns its press (a slider,
	// a scroll bar's thumb, a field selecting) ends the walk. While it goes, the node under the
	// pointer and up its ancestors are asked what a drop would do; the first that takes it is the
	// target (`:drop-target`). The source shows `:drag-source` and is told how it ended.

	/// Gives what a press on it drags (an alternative to overriding OnDragRequested). OWNERSHIP of
	/// `source` transfers (one set before is deleted).
	public void SetDragSource(delegate bool(DragRequest request) source)
	{
		delete mDragSource;
		mDragSource = source;
	}

	/// Takes drops of these types (markup's `drop-types`, space-separated) with the source's
	/// preferred effect; an alternative to overriding OnDragQuery or SetOnDragQuery.
	[GuiProperty("drop-types")]
	public StringView DropTypes
	{
		get => NodeDetail.ViewOf(mDropTypes);
		set => NodeDetail.SetText(ref mDropTypes, value);
	}

	/// Answers each drop query here (after OnDragQuery leaves it undecided). OWNERSHIP of `query`
	/// transfers.
	public void SetOnDragQuery(delegate void(DropQuery query) query)
	{
		delete mDropQuery;
		mDropQuery = query;
	}

	/// How a drag from here ended. OWNERSHIP of `callback` transfers.
	public void SetOnDragEnd(delegate void(DragResult result) callback)
	{
		delete mDragEnd;
		mDragEnd = callback;
	}

	/// Whether it takes drops of a type, by its drop types.
	public bool TakesDropType(StringView type)
	{
		var rest = ParseUtil.Trim(DropTypes);
		while (rest.Length != 0)
		{
			int end = 0;
			while ((end < rest.Length) && (rest[end] != ' '))
				end++;
			if (rest.Substring(0, end) == type)
				return true;
			rest = ParseUtil.Trim(rest.Substring(end));
		}
		return false;
	}

	// The dispatcher's calls (each runs the virtual, then the callbacks, then the listeners).

	public bool HandleDragRequested(DragRequest request)
	{
		if (OnDragRequested(request))
			return true;
		return (mDragSource != null) && mDragSource(request);
	}

	public void HandleDragQuery(DropQuery query)
	{
		OnDragQuery(query);
		// A listener (a script's `dragquery`) that takes the event takes the drop.
		if ((query.Effect == .None) && !query.Refused && HasListener(.DragQuery))
		{
			let asked = scope DragEvent(.DragQuery, this, query.Payload);
			asked.Effect = query.Preferred;
			asked.Modifiers = query.Modifiers;
			SendEvent(asked);
			if (asked.Handled)
				query.Accept();
		}
		if ((query.Effect == .None) && !query.Refused && (mDropQuery != null))
			mDropQuery(query);
		if ((query.Effect == .None) && !query.Refused && TakesDropType(query.Payload.Type))
			query.Accept();
	}

	public void HandleDragEvent(DragEvent e)
	{
		switch (e.Type)
		{
		case .DragEnter: OnDragEnter(e);
		case .DragOver: OnDragOver(e);
		case .DragLeave: OnDragLeave(e);
		case .Drop: OnDrop(e);
		default:
		}
		SendEvent(e);
	}

	public bool HandleDragHoverOpen(Float2 local) => OnDragHoverOpen(local);

	public void HandleDragEnd(DragResult result, DragEvent e)
	{
		OnDragEnd(result);
		if (mDragEnd != null)
			mDragEnd(result);
		SendEvent(e);
	}

	/// The dispatcher's: whether it is the drag's target now (`:drop-target`).
	public bool DropTargetState
	{
		get => mDropTargetState;
		set
		{
			if (value == mDropTargetState)
				return;
			mDropTargetState = value;
			MarkStyleStateDirty(StateDropTarget);
			Invalidate();
		}
	}

	public bool IsDropTarget => mDropTargetState;

	/// The dispatcher's: whether it is the drag's source now (`:drag-source`).
	public bool DragSourceState
	{
		get => mDragSourceState;
		set
		{
			if (value == mDragSourceState)
				return;
			mDragSourceState = value;
			MarkStyleStateDirty(StateDragSource);
			Invalidate();
		}
	}

	public bool IsDragSource => mDragSourceState;

	// === Leaving ===
	// A node that goes plays its way out first: Leave puts it in `:leaving`, where the sheet's exit
	// transition or animation runs, takes it out of the pointer, focus and navigation at once, and
	// the style pass removes it from its parent when what the sheet started on it has ended.
	// Leaving ends when it leaves its parent, by this or any other removal, so a node taken back is
	// whole again.

	/// Whether it is leaving (`:leaving`).
	public bool IsLeaving => mLeaving;

	/// Whether it or an ancestor is leaving.
	public bool IsTreeLeaving
	{
		get
		{
			for (var n = this; n != null; n = n.mParent)
			{
				if (n.mLeaving)
					return true;
			}
			return false;
		}
	}

	// === Inert (HTML's `inert`) ===

	/// An inert node and what it holds take no pointer, focus, navigation, keys or commands, and
	/// still draw (a game's screen under a blocking one).
	public bool IsInert => mInert;

	/// Whether it or an ancestor is inert or leaving: it takes no input.
	public bool IsTreeInert
	{
		get
		{
			for (var n = this; n != null; n = n.mParent)
			{
				if (n.mLeaving || n.mInert)
					return true;
			}
			return false;
		}
	}

	// === Entering ===
	// A node that arrives plays its way in: Enter puts it in `:entering`, where the sheet's
	// entrance runs, until what that started has ended; then `:entering` goes, the node moves to
	// its own style (through its transitions), and once that has settled it hears `entered`.

	/// In `:entering`, its entrance's first half.
	public bool IsEntering => mEnterPhase == 1;
	/// Entering, or moving to its own style after: `entered` is still to come.
	public bool IsArriving => mEnterPhase != 0;
	/// Whether the style pass tells it when what moves it settles (MotionSettled): leaving or
	/// arriving.
	public bool WatchesMotion => mLeaving || (mEnterPhase != 0);

	/// A style pass ran over the tree this node tops (StyleManager.ApplyTree says so): a node
	/// leaving it waits for the sheet's exit.
	public void NoteStylePass()
	{
		mStyledTree = true;
	}

	public bool HasStylePass => mStyledTree;

	/// It owns a press at `local` for a drag of its own (a slider's thumb, a scroll bar, a field
	/// selecting): a drag from an ancestor is not offered.
	public virtual bool OwnsPressDrag(Float2 local)
	{
		// A scroll container's bars are its own.
		return IsScrollContainer && (ScrollBarTrack(0).Contains(local) || ScrollBarTrack(1).Contains(local));
	}

	/// A preview hears the effect a drop would have now (a default preview shows a badge).
	public virtual void OnDragPreviewEffect(DropEffect effect)
	{
	}

	/// True if this node edits text and wants the platform's text-input (IME) enabled while it
	/// holds focus. The gui.shell bridge reads the focused node's answer and drives the window's
	/// StartTextInput/StopTextInput accordingly. Default: false.
	public virtual bool WantsTextInput => false;
	/// Whether what it takes is secret (a password): the platform's IME keeps out of it.
	public virtual bool IsTextInputSecret => false;

	/// Where text is typed in this node, in its own space, and the caret's x there: the IME places
	/// its candidate list beside it. False when it types no text.
	public virtual bool GetTextInputArea(out Rect outArea, out float outCaretX)
	{
		outArea = .();
		outCaretX = 0.0f;
		return false;
	}

	/// Whether the pointer over this node is the GUI's, so a game host leaves a click there alone:
	/// a node that paints a background, takes focus, or listens for the pointer. A plain layout
	/// container lets the pointer through to the game.
	public virtual bool TakesPointer
	{
		get
		{
			if ((mBox.BackgroundColor.A > 0.0f) || !mBox.Layers.IsEmpty || mTabFocusable)
				return true;
			for (let listener in mListeners)
			{
				if (listener.Removed)
					continue;
				switch (listener.Type)
				{
				case .MouseDown, .MouseUp, .MouseClick, .MouseWheel:
					return true;
				default:
				}
			}
			return false;
		}
	}

	/// Optional hover-tooltip text: the dispatcher shows the nearest one up the parent chain from
	/// the hovered node, after a delay. Empty (the default) means none here.
	public virtual StringView TooltipText => default;
	/// Its tooltip takes the pointer: it holds while the pointer crosses into it, and a press
	/// inside it does not close it (a tooltip with a link or a button).
	public virtual bool IsTooltipInteractive => false;

	/// Tab navigation: whether Tab / Shift+Tab focus traversal can land on this node (distinct from
	/// click focus, which targets whatever is hit). Interactive widgets opt in; static nodes
	/// (labels, layouts) stay false. Modeled on eepp's UI_TAB_FOCUSABLE flag.
	public bool TabFocusable
	{
		get => mTabFocusable;
		set => mTabFocusable = value;
	}

	/// Where Tab reaches it (CSS's and HTML's `tab-index`): a positive index before the rest,
	/// lowest first (a tie in tree order); 0, in tree order (the default); below 0, never by Tab,
	/// though a click, an arrow or code still focuses it.
	[GuiProperty("tab-index")]
	public int32 TabIndex
	{
		get => mTabIndex;
		set => mTabIndex = value;
	}

	/// Tab and Shift+Tab reach it as keys rather than moving focus (CSS-like `tab-captures`: a code
	/// editor, a terminal); Ctrl+Tab and Ctrl+Shift+Tab move focus from it instead.
	[GuiProperty("tab-captures")]
	public bool TabCaptures
	{
		get => mTabCaptures;
		set => mTabCaptures = value;
	}

	/// A press in it leaves the focus where it is, rather than moving it to what was pressed or
	/// clearing it (the web's prevented `mousedown`): a code editor's completion list, whose row a
	/// click picks while the editor keeps the keys. A focusable widget inside it still takes the
	/// focus.
	public bool KeepsFocus
	{
		get => mKeepsFocus;
		set => mKeepsFocus = value;
	}

	// === Focus scopes ===
	// A scope groups what directional and tab navigation move between: it says what happens at its
	// edge, remembers what was last focused inside it (so coming back returns there), and may name
	// the widget focus starts on (its id).

	/// Its scope's kind: as set, or, for a focus group that sets none, wrap.
	public Sedulous.GUI.NavScope NavScope
	{
		get => ((mNavScope == .None) && mFocusGroup) ? .Wrap : mNavScope;
		set => mNavScope = value;
	}

	/// A focus group (a radio group, a tab strip, a toolbar): one Tab stop however many it holds,
	/// the member focused there last (else its `nav-default`, else its current one, else the
	/// first); the arrows move inside it, wrapping unless its `nav-scope` says otherwise.
	[GuiProperty("focus-group")]
	public bool FocusGroup
	{
		get => mFocusGroup;
		set => mFocusGroup = value;
	}

	/// Whether it is its group's current member (a checked radio, the selected tab): where Tab
	/// enters a focus group no one has focused in yet.
	public virtual bool IsCurrentInGroup => false;

	[GuiProperty("nav-default")]
	public StringView DefaultFocusId
	{
		get => NodeDetail.ViewOf(mDefaultFocusId);
		set => NodeDetail.SetText(ref mDefaultFocusId, value);
	}

	/// What was last focused inside this scope (weakly: null once it is gone).
	public Node RememberedFocus => (mRememberedFocus.Table != null) ? mRememberedFocus.Table.Resolve(mRememberedFocus.Slot, mRememberedFocus.Generation) : null;

	public void RememberFocus(Node focused)
	{
		mRememberedFocus = focused.TakeElementRef();
	}

	public StringView GetNavOverride(NavOverride which) => NodeDetail.ViewOf(mNavOverrides[(int)which]);

	public void SetNavOverride(NavOverride which, StringView target)
	{
		NodeDetail.SetText(ref mNavOverrides[(int)which], target);
	}

	[GuiProperty("nav-up")]
	public StringView NavUp
	{
		get => GetNavOverride(.NavOverrideUp);
		set => SetNavOverride(.NavOverrideUp, value);
	}

	[GuiProperty("nav-down")]
	public StringView NavDown
	{
		get => GetNavOverride(.NavOverrideDown);
		set => SetNavOverride(.NavOverrideDown, value);
	}

	[GuiProperty("nav-left")]
	public StringView NavLeft
	{
		get => GetNavOverride(.NavOverrideLeft);
		set => SetNavOverride(.NavOverrideLeft, value);
	}

	[GuiProperty("nav-right")]
	public StringView NavRight
	{
		get => GetNavOverride(.NavOverrideRight);
		set => SetNavOverride(.NavOverrideRight, value);
	}

	[GuiProperty("nav-next")]
	public StringView NavNext
	{
		get => GetNavOverride(.NavOverrideNext);
		set => SetNavOverride(.NavOverrideNext, value);
	}

	[GuiProperty("nav-prev")]
	public StringView NavPrevious
	{
		get => GetNavOverride(.NavOverridePrevious);
		set => SetNavOverride(.NavOverridePrevious, value);
	}

	[GuiProperty("nav-scope")]
	public StringView NavScopeName
	{
		get
		{
			switch (mNavScope)
			{
			case .Pass: return "pass";
			case .Wrap: return "wrap";
			case .Contain: return "contain";
			case .None:
			}
			return "none";
		}
		set
		{
			mNavScope = (value == "pass") ? .Pass : (value == "wrap") ? .Wrap : (value == "contain") ? .Contain : .None;
		}
	}

	/// The key context this node declares for bindings ("menu", "editor mode=insert"): a binding's
	/// context predicate is matched against these along the focus path.
	[GuiProperty("key-context")]
	public StringView KeyContext
	{
		get => NodeDetail.ViewOf(mKeyContext);
		set => NodeDetail.SetText(ref mKeyContext, value);
	}

	// === Invalidation === (marks self and every ancestor up to the root)
	// Not stopping at an ancestor already marked: one marked after it was drawn in a frame (a later
	// node's drawing touched it) or never drawn (hidden) keeps its mark while the root's is
	// cleared, and a change under it would never reach the root; a skipped frame then hid it (a
	// list's rows, a field's committed value, a selection showed only once something else redrew).
	// A node not shown (hidden, or under a node not displayed) marks itself alone: nothing on
	// screen changes (an animation running on a page out of view asks for no frames), and it
	// reaches the root again once shown (showing it invalidates, or lays out).

	public void Invalidate()
	{
		MarkAccessDirty(); // what shows differently may read differently
		mNeedsRedraw = true;
		mInvalidatedSelf = true;
		mSubtreeInkValid = false;
		if (!IsTreeVisible || (mQuietInvalidations != 0))
		{
			NoteOldArea(null); // hidden: where it showed is to be drawn again
			return;
		}
		NoteOldArea(MarkAncestorsForRedraw()); // the topmost: its root
	}

	/// Its ancestors draw again (what holds it changed), up to its root, which it returns: what
	/// Invalidate does above the node, without the node's own area counting as changed.
	public Node MarkAncestorsForRedraw()
	{
		var through = this; // the child of each ancestor the change came up through
		for (var p = mParent; p != null; p = p.mParent)
		{
			p.mNeedsRedraw = true;
			p.mSubtreeInkValid = false; // what it holds may reach elsewhere now
			p.NoteChildChanged(through); // and that child's reach may have moved
			through = p;
		}
		return through;
	}

	/// A frame's damage: the root collects the areas, in device pixels, that changed since its last
	/// frame (where a node was, before it changed, moved, hid or went). Nodes other than a root
	/// keep none.
	public virtual void AddDamage(Rect device)
	{
	}

	// What it covered when last drawn is to be drawn again: told to its root, once a frame.
	private void NoteOldArea(Node root)
	{
		if (!mDrawnAreaValid || mDamageNoted)
			return;
		mDamageNoted = true;
		let to = (root != null) ? root : RootNode;
		if (to != null)
			to.AddDamage(mDrawnArea);
	}

	public bool NeedsRedraw => mNeedsRedraw;

	/// Its accessibility node may read differently: the next update sends it, and its ancestors
	/// learn something below waits, so the walk finds it. A node starts marked.
	public void MarkAccessDirty()
	{
		mAccessDirty = true;
		for (var p = mParent; (p != null) && !p.mAccessChildDirty; p = p.mParent)
			p.mAccessChildDirty = true;
	}

	public bool IsAccessDirty => mAccessDirty;

	/// A hash of what was last sent of it to the bridge: marked again (an animation's frames), it is
	/// sent only when what it reads changed.
	public uint64 AccessSent
	{
		get => mAccessSent;
		set => mAccessSent = value;
	}

	/// Whether code placed it (Position set from code): its insets are a place in its parent's
	/// box, not a sheet's insets from inside the parent's border.
	public bool IsPlacedByCode => mPlacedByCode;
	public bool HasAccessDirtyDescendant => mAccessChildDirty;

	public void ClearAccessDirty()
	{
		mAccessDirty = false;
		mAccessChildDirty = false;
	}

	public void ClearNeedsRedraw()
	{
		mNeedsRedraw = false;
	}

	// === Transformable overrides: geometry changes invalidate + notify ===
	// An unchanged value is no change: hosts and layouts set geometry every pass, and an idle frame
	// must find nothing to redraw.

	/// The node's place in its parent. From code (not a layout placing it), it takes the node out
	/// of its container's flow to that place, as `position: absolute` with `left` and `top` does;
	/// every layout keeps it there.
	public override Float2 Position
	{
		get => mPosition;
		set
		{
			if (!IsBeingPlaced)
			{
				PinStyle(SlotBit(.SlotPosition) | SlotBit(.SlotLeft) | SlotBit(.SlotTop) | SlotBit(.SlotRight) | SlotBit(.SlotBottom));
				let wasInFlow = mLayoutStyle.Placement != .Absolute;
				mLayoutStyle.Placement = .Absolute;
				mPlacedByCode = true; // at this place in its parent's box, not inside its border
				mLayoutStyle.Left = LayoutLength.Px(value.X);
				mLayoutStyle.Top = LayoutLength.Px(value.Y);
				mLayoutStyle.Right = LayoutLength();
				mLayoutStyle.Bottom = LayoutLength();
				if (wasInFlow && (mParent != null))
					mParent.RequestLayout(); // its siblings close the gap
			}
			if (value == mPosition)
				return;
			base.Position = value;
			HandlePositionChange();
		}
	}

	public override float Rotation
	{
		get => mRotation;
		set
		{
			if (value == mRotation)
				return;
			base.Rotation = value;
			Invalidate();
		}
	}

	public override Float2 Scale
	{
		get => mScale;
		set
		{
			if (value == mScale)
				return;
			base.Scale = value;
			Invalidate();
		}
	}

	// === Direction ===

	public LayoutDirection GetLayoutDirection() => mDirection;

	public void SetLayoutDirection(LayoutDirection direction)
	{
		PinStyle(SlotBit(.SlotDirection));
		if (direction == mDirection)
			return;
		mDirection = direction;
		DirectionChanged();
	}

	/// It places its children itself, at points of its own rather than in a flow (a canvas: a node
	/// graph's nodes), so right to left does not move them; what is inside each child still runs as
	/// its direction says.
	public bool PlacesChildren
	{
		get => mPlacesChildren;
		set => mPlacesChildren = value;
	}

	/// Its direction as CSS's `direction` names it: rtl, ltr, auto or inherit (any other text).
	[GuiProperty]
	public StringView Direction
	{
		get
		{
			switch (mDirection)
			{
			case .RightToLeft: return "rtl";
			case .LeftToRight: return "ltr";
			case .Auto: return "auto";
			case .Inherit:
			}
			return "inherit";
		}
		set
		{
			SetLayoutDirection((value == "rtl") ? .RightToLeft : (value == "ltr") ? .LeftToRight : (value == "auto") ? .Auto : .Inherit);
		}
	}

	/// Whether its content runs right to left (the first ancestor not inheriting says, else the
	/// GUI's language).
	public bool IsRightToLeft
	{
		get
		{
			for (var n = this; n != null; n = n.mParent)
			{
				if ((n.mDirection == .LeftToRight) || (n.mDirection == .RightToLeft))
					return n.mDirection == .RightToLeft;
				if (n.mParent == null)
					return n.ContextRightToLeft;
			}
			return false;
		}
	}

	/// Which way an arrow key goes along the line: +1 toward the inline end (Right, or Left in right
	/// to left), -1 toward its start, 0 for any other key.
	public int32 InlineStep(KeyCode key)
	{
		if ((key != .Left) && (key != .Right))
			return 0;
		return ((key == .Right) != IsRightToLeft) ? 1 : -1;
	}

	/// Whether its drawing (with what it holds) flips left for right in right to left: an arrow or
	/// icon that points along the line (CSS has none; the GUI's `mirror-on-rtl`).
	[GuiProperty("mirror-on-rtl")]
	public bool MirrorOnRtl
	{
		get => mMirrorOnRtl;
		set
		{
			if (value == mMirrorOnRtl)
				return;
			mMirrorOnRtl = value;
			RefreshMirror();
		}
	}

	/// Whether it is drawn flipped now.
	public bool IsMirrored => mMirrored;

	public void RefreshMirror()
	{
		let mirrored = mMirrorOnRtl && IsRightToLeft;
		if (mirrored == mMirrored)
			return;
		mMirrored = mirrored;
		UpdateStyleTransform();
	}

	/// Tells it and what it holds that the way they run may have changed (stopping below at a node
	/// that sets its own): text takes its paragraphs' direction from it.
	public void NotifyDirectionChange()
	{
		OnDirectionChange();
		for (int i = 0; i < mChildren.Count; i++)
		{
			let child = mChildren[i];
			if ((child != null) && child.FollowsParentDirection)
				child.NotifyDirectionChange();
		}
	}

	/// Whether its text's paragraphs take their direction from their content: the first node up
	/// from it that sets a direction sets auto.
	public bool IsDirectionAuto
	{
		get
		{
			for (var n = this; n != null; n = n.mParent)
			{
				if (n.mDirection != .Inherit)
					return n.mDirection == .Auto;
			}
			return false;
		}
	}

	/// Its boxes run as its parent's do (inherited, or auto, whose boxes follow the parent).
	public bool FollowsParentDirection => (mDirection == .Inherit) || (mDirection == .Auto);

	/// The way it runs may have changed (its own direction, an ancestor's, or a new parent).
	public virtual void OnDirectionChange()
	{
	}

	/// The direction changed here or above: the subtree lays out again (its rows run the other
	/// way) and restyles (text-align's start and end follow it).
	public void DirectionChanged()
	{
		RequestLayoutTree();
		NotifyDirectionChange();
		if (mStyleWriting) // the style pass applies it before its text: only what it holds waits
		{
			for (int i = 0; i < mChildren.Count; i++)
			{
				let child = mChildren[i];
				if (child != null)
					child.MarkStyleDirty(true);
			}
		}
		else
			MarkStyleDirty(true);
		Invalidate();
	}

	// === Translation ===

	public AutoTranslate GetAutoTranslate() => mAutoTranslate;

	public void SetAutoTranslate(AutoTranslate mode)
	{
		if (mode == mAutoTranslate)
			return;
		mAutoTranslate = mode;
		mTranslationChanged.Notify();
	}

	[GuiProperty("auto-translate")]
	public StringView AutoTranslateName
	{
		get => (mAutoTranslate == .Always) ? "always" : (mAutoTranslate == .Off) ? "off" : "inherit";
		set => SetAutoTranslate((value == "always") ? .Always : (value == "off") ? .Off : .Inherit);
	}

	/// Whether its translated properties resolve now (the first ancestor not inheriting says; the
	/// top of a tree does). Read by a translated binding, which follows a change above.
	public bool IsAutoTranslating
	{
		get
		{
			for (var n = this; n != null; n = n.mParent)
			{
				n.mTranslationChanged.Track();
				if (n.mAutoTranslate != .Inherit)
					return n.mAutoTranslate == .Always;
			}
			return true;
		}
	}

	/// The language it speaks (`lang`, as markup's attribute; inherited: empty takes what holds it
	/// speaks, the top of a GUI its Localization's). `:lang()` matches it.
	[GuiProperty("lang")]
	public StringView Lang
	{
		get => NodeDetail.ViewOf(mLang);
		set
		{
			if (value == NodeDetail.ViewOf(mLang))
				return;
			NodeDetail.SetText(ref mLang, value);
			MarkStyleDirty(true); // what :lang matches here and below may differ
		}
	}

	/// The language it speaks, its own or inherited, appended to `outText`.
	public void Language(String outText)
	{
		for (var n = this; n != null; n = n.mParent)
		{
			if ((n.mLang != null) && !n.mLang.IsEmpty)
			{
				outText.Append(n.mLang);
				return;
			}
			if (n.mParent == null)
			{
				n.ContextLanguage(outText);
				return;
			}
		}
	}

	/// The key a translated property resolves (null when it is not translated). Borrowed.
	public String TranslationKey(StringView property)
	{
		for (let t in mTranslations)
		{
			if (t.Property == property)
				return t.Key;
		}
		return null;
	}

	// === Bindings ===

	/// Runs `body` now, and again on this GUI's frame whenever something it read changed (at once
	/// outside a scene). The node owns it: it ends with the node, or at ClearBindings. OWNERSHIP of
	/// `body` transfers.
	public Effect Bind(delegate void() body)
	{
		let effect = new Effect(body, new () => EffectScheduler);
		mBindings.Add(effect);
		return effect;
	}

	public void ClearBindings()
	{
		ClearAndDeleteItems!(mBindings);
		mPropertyBindings.Clear();
	}

	/// Bind for one reflected property (`back`: the write-back from it): binding the property again
	/// replaces the binding, rather than leaving the old one running beside it. OWNERSHIP of `body`
	/// transfers.
	public Effect BindFor(GuiPropertyInfo property, bool back, delegate void() body)
	{
		for (int i = 0; i < mPropertyBindings.Count; i++)
		{
			if ((mPropertyBindings[i].Property == property) && (mPropertyBindings[i].Back == back))
			{
				for (int b = 0; b < mBindings.Count; b++)
				{
					if (mBindings[b] == mPropertyBindings[i].Bound)
					{
						let old = mBindings[b];
						mBindings.RemoveAt(b);
						delete old;
						break;
					}
				}
				mPropertyBindings.RemoveAt(i);
				break;
			}
		}
		let bound = Bind(body);
		mPropertyBindings.Add(.(property, back, bound));
		return bound;
	}

	public int BindingCount => mBindings.Count;

	/// Calls `f(id, phase)` for each command it handles (the inspector lists them).
	public void ForEachCommandHandler(delegate void(StringView id, CommandPhase phase) f)
	{
		for (let entry in mCommandHandlers)
			f(entry.Id, entry.Phase);
	}

	/// Calls `f(type, capture)` for each event listener on it (the inspector lists them).
	public void ForEachListener(delegate void(EventType type, bool capture) f)
	{
		for (let listener in mListeners)
		{
			if (!listener.Removed)
				f(listener.Type, listener.Capture);
		}
	}

	// === Command handlers ===
	// A node handles commands by id: running one walks the focus path (capture from the root down,
	// then bubble from the focused widget up), and a command is available while a handler for it
	// is on that path. A screen's commands live on the screen; the GUI's own on its root.

	/// Handles command `id` in `phase`; a token for RemoveCommandHandler. OWNERSHIP of `handler`
	/// transfers.
	public uint32 OnCommand(StringView id, CommandHandler handler, CommandPhase phase = .Bubble)
	{
		let entry = new CommandHandlerEntry();
		entry.Id.Set(id);
		entry.Phase = phase;
		entry.Handler = handler;
		entry.Token = ++mNextListenerId;
		if (mDispatching != 0)
			mPendingCommandHandlers.Add(entry); // joins once the running ones return
		else
			mCommandHandlers.Add(entry);
		NotifyCommandsChanged();
		return mNextListenerId;
	}

	/// Removes a handler; one removed while handlers run (its own, from inside it) is marked and
	/// goes once they return, never destroyed while it runs. False when the token is none of its.
	public bool RemoveCommandHandler(uint32 token)
	{
		for (int i = 0; i < mCommandHandlers.Count; i++)
		{
			let entry = mCommandHandlers[i];
			if ((entry.Token == token) && !entry.Removed)
			{
				if (mDispatching != 0)
					entry.Removed = true;
				else
				{
					mCommandHandlers.RemoveAt(i);
					delete entry;
				}
				NotifyCommandsChanged();
				return true;
			}
		}
		for (int i = 0; i < mPendingCommandHandlers.Count; i++)
		{
			let entry = mPendingCommandHandlers[i];
			if (entry.Token == token)
			{
				mPendingCommandHandlers.RemoveAt(i);
				delete entry;
				NotifyCommandsChanged();
				return true;
			}
		}
		return false;
	}

	public bool HandlesCommand(StringView id)
	{
		for (let entry in mCommandHandlers)
		{
			if (!entry.Removed && (entry.Id == id))
				return true;
		}
		return false;
	}

	/// The bound command's state reached the control: enabled by availability; a checkable control
	/// shows its checked state too, and one with a tooltip the reason.
	public virtual void OnBoundCommandState(BoundCommandState state)
	{
		Enabled = state.Available;
	}

	/// What the bound command shows reached the control: its label, its icon (an image path) and
	/// its keys as text ("Ctrl+S"), each followed as it changes. A button or a menu item with no
	/// text of its own takes the label; a menu item, the keys and the icon.
	public virtual void OnBoundCommandText(StringView label, StringView icon, StringView shortcut)
	{
	}

	/// Runs this node's handlers for `e` in its phase; whether any ran.
	public bool RunCommandHandlers(ref CommandEvent e)
	{
		bool ran = false;
		mDispatching++;
		defer
		{
			if (--mDispatching == 0)
				SettleHandlers();
		}
		for (int i = 0; i < mCommandHandlers.Count; i++)
		{
			let entry = mCommandHandlers[i];
			if (entry.Removed || (entry.Phase != e.Phase) || (entry.Id != e.Id))
				continue;
			entry.Handler(ref e);
			ran = true;
		}
		return ran;
	}

	// === Event listeners ===

	/// Listens for `type`. An input event reaches a `capture` listener on its way down from the
	/// root (before the target's own handling), any other on its way back up. OWNERSHIP of
	/// `callback` transfers; an id for RemoveEventListener.
	public uint32 AddEventListener(EventType type, EventCallback callback, bool capture = false)
	{
		let id = ++mNextListenerId;
		let listener = new Listener();
		listener.Id = id;
		listener.Type = type;
		listener.Callback = callback;
		listener.Capture = capture;
		if (mDispatching != 0)
			mPendingListeners.Add(listener); // after the running ones
		else
			mListeners.Add(listener);
		return id;
	}

	public bool HasListener(EventType type)
	{
		for (let l in mListeners)
		{
			if ((l.Type == type) && !l.Removed)
				return true;
		}
		for (let l in mPendingListeners)
		{
			if (l.Type == type)
				return true;
		}
		return false;
	}

	/// Removes a listener; one removed while listeners run (its own, from inside it) is marked and
	/// goes once they return, never destroyed while it runs. False when the id is none of its.
	public bool RemoveEventListener(uint32 id)
	{
		for (int i = 0; i < mListeners.Count; i++)
		{
			let listener = mListeners[i];
			if ((listener.Id == id) && !listener.Removed)
			{
				if (mDispatching != 0)
					listener.Removed = true;
				else
				{
					mListeners.RemoveAt(i);
					delete listener;
				}
				return true;
			}
		}
		for (int i = 0; i < mPendingListeners.Count; i++)
		{
			let listener = mPendingListeners[i];
			if (listener.Id == id)
			{
				mPendingListeners.RemoveAt(i);
				delete listener;
				return true;
			}
		}
		return false;
	}

	/// Tells this node's listeners of the event a library names `name` (EventType.Named), with a
	/// detail as text.
	public void SendNamedEvent(StringView name, StringView detail = default)
	{
		SendEvent(scope NamedEvent(this, name, detail));
	}

	/// Calls `callback` on each event named `name` this node is told (SendNamedEvent); a token for
	/// RemoveEventListener. OWNERSHIP of `callback` transfers.
	public uint32 AddNamedListener(StringView name, EventCallback callback)
	{
		let wanted = new String(name);
		return AddEventListener(.Named, new (e) =>
			{
				if (((NamedEvent)e).Name == wanted)
					callback(e);
			}
			~
			{
				delete wanted;
				delete callback;
			});
	}

	/// Tells this node's listeners of an event about it (not routed: geometry, focus, change).
	public void SendEvent(Event e)
	{
		mDispatching++;
		defer
		{
			if (--mDispatching == 0)
				SettleHandlers();
		}
		for (int i = 0; i < mListeners.Count; i++)
		{
			let listener = mListeners[i];
			if (!listener.Removed && (listener.Type == e.Type))
				listener.Callback(e);
		}
	}

	// === Change hooks (subclass overrides; the Handle* wrappers fire the event too) ===

	public virtual void OnPositionChange() { }
	public virtual void OnSizeChange() { }
	public virtual void OnVisibilityChange() { }
	public virtual void OnEnabledChange() { }
	public virtual void OnParentChange() { }
	/// Called on this node after a child is added or removed (containers re-layout here).
	public virtual void OnChildrenChanged() { }
	/// Its scroll offset moved (a container realising what is in view follows it here).
	public virtual void OnScrollChange() { }

	/// The device pixels per logical unit the top of a tree lays out on (its children take theirs
	/// from it): 1, or a GUI root's display scale.
	protected virtual float TopPixelScale => 1.0f;

	/// The language of a tree with no `lang` on it, appended to `outText`: none, or a GUI root's
	/// Localization's.
	protected virtual void ContextLanguage(String outText)
	{
	}

	/// The direction of a tree with no `direction` on it: left to right, or as a GUI root's
	/// Localization's language is written.
	protected virtual bool ContextRightToLeft => false;

	/// Draws over this node and everything under it, after them, in its space and at full opacity:
	/// what a GUI root puts over its tree (the layout overlay).
	protected virtual void OnDrawAbove(DrawContext ctx)
	{
	}

	// Input handler hooks (override in subclasses; the Handle* wrappers call these).
	protected virtual void OnMouseEnter(MouseEvent e) { }
	protected virtual void OnMouseLeave(MouseEvent e) { }
	protected virtual void OnMouseMove(MouseEvent e) { }
	protected virtual void OnMouseDown(MouseEvent e) { }
	protected virtual void OnMouseUp(MouseEvent e) { }
	protected virtual void OnMouseClick(MouseEvent e) { }
	protected virtual void OnMouseWheel(WheelEvent e) { }
	protected virtual void OnKeyDown(KeyEvent e) { }
	/// Return or Space (a gamepad's South) on the focused widget, when it used neither: what a
	/// click does, for the widgets a click acts on. True when it did something.
	protected virtual bool OnActivate() => false;
	protected virtual void OnKeyUp(KeyEvent e) { }
	protected virtual void OnTextInput(TextInputEvent e) { }
	protected virtual void OnComposition(CompositionEvent e) { }
	/// A context menu asked for at the event's position (a right release, a long press,
	/// Shift+F10): open one and mark it Handled; unhandled, it bubbles up.
	protected virtual void OnContextMenu(MouseEvent e) { }
	protected virtual void OnFocusGained() { }
	protected virtual void OnFocusLost() { }

	/// Hovered or pressed changed: restyles the node (`:hover`, `:active`; its subtree when a sheet
	/// reads them through it) and redraws it.
	protected virtual void OnPointerStateChange()
	{
		MarkStyleStateDirty(StateHover | StateActive);
		Invalidate();
	}

	/// The pointer this node captured was taken away or released.
	protected virtual void OnPointerCaptureLost() { }
	/// The press on this node (or inside it) was cancelled: no release or click follows.
	protected virtual void OnPointerCancel(MouseEvent e) { }
	/// A source's answer to a drag offered by a press on it or inside it: fill the request's payload
	/// (and a preview) and return true to start it.
	protected virtual bool OnDragRequested(DragRequest request) => false;
	/// A target's answer: what a drop here would do (DropQuery.Accept, Refuse).
	protected virtual void OnDragQuery(DropQuery query) { }
	protected virtual void OnDragEnter(DragEvent e) { }
	protected virtual void OnDragOver(DragEvent e) { }
	protected virtual void OnDragLeave(DragEvent e) { }
	protected virtual void OnDrop(DragEvent e) { }
	/// A source hears how its drag ended (a move removes what was moved).
	protected virtual void OnDragEnd(DragResult result) { }
	/// A drag rested on it a moment (at `local`): a closed tree node opens, an expander opens, a tab
	/// is selected. True when it did something (and the drag is asked again).
	protected virtual bool OnDragHoverOpen(Float2 local) => false;

	protected void HandlePositionChange()
	{
		OnPositionChange();
		Invalidate();
		SendEvent(scope Event(.PositionChanged, this));
	}

	protected void HandleSizeChange()
	{
		if (!mStyleTransforms.IsEmpty || mMirrored)
			UpdateStyleTransform();
		OnSizeChange();
		Invalidate();
		SendEvent(scope Event(.SizeChanged, this));
	}

	protected void HandleVisibilityChange()
	{
		OnVisibilityChange();
		Invalidate();
		if (!mVisible)
			MarkAncestorsForRedraw(); // hidden, it marks itself alone: what drew it must draw again
		SendEvent(scope Event(.VisibilityChanged, this)); // hidden keeps its place: no layout
	}

	protected void HandleEnabledChange()
	{
		OnEnabledChange();
		MarkStyleStateDirty(StateDisabled | StateEnabled);
		Invalidate();
		SendEvent(scope Event(.EnabledChanged, this));
	}

	protected void HandleParentChange()
	{
		OnParentChange();
		if (FollowsParentDirection)
			NotifyDirectionChange(); // it may run another way under its new parent
		Invalidate();
		SendEvent(scope Event(.ParentChanged, this));
		NotifySceneRootChanged(); // the subtree may have joined or left a GUI
	}

	// Tells the bindings that read which GUI this subtree is in; a node with none costs a visit.
	protected void NotifySceneRootChanged()
	{
		mSceneRootChanged.Notify();
		for (let child in mChildren)
			child.NotifySceneRootChanged();
	}

	protected class Listener
	{
		public uint32 Id;
		public EventType Type;
		public EventCallback Callback ~ delete _;
		public bool Capture = false;
		/// While listeners run: goes once they return.
		public bool Removed = false;
	}

	// The listeners of one kind (capture or bubble) for an input event. By index: a listener may
	// add another.
	protected void RunListeners(Event e, bool capture)
	{
		mDispatching++;
		defer
		{
			if (--mDispatching == 0)
				SettleHandlers();
		}
		for (int i = 0; i < mListeners.Count; i++)
		{
			let listener = mListeners[i];
			if (!listener.Removed && (listener.Type == e.Type) && (listener.Capture == capture))
				listener.Callback(e);
		}
	}

	// While its listeners or handlers run, the lists hold still: one removed is marked, one added
	// waits; both settle when the outermost run returns (a script's `off` from inside its own
	// handler would otherwise free the function running).
	protected void SettleHandlers()
	{
		for (int i = 0; i < mListeners.Count;)
		{
			if (mListeners[i].Removed)
			{
				delete mListeners[i];
				mListeners.RemoveAt(i);
			}
			else
				i++;
		}
		mListeners.AddRange(mPendingListeners);
		mPendingListeners.Clear();
		for (int i = 0; i < mCommandHandlers.Count;)
		{
			if (mCommandHandlers[i].Removed)
			{
				delete mCommandHandlers[i];
				mCommandHandlers.RemoveAt(i);
			}
			else
				i++;
		}
		mCommandHandlers.AddRange(mPendingCommandHandlers);
		mPendingCommandHandlers.Clear();
	}

	// The widget's own handler for an input event.
	protected void InvokeInputHandler(Event e)
	{
		switch (e.Type)
		{
		case .MouseDown: OnMouseDown((MouseEvent)e);
		case .MouseUp: OnMouseUp((MouseEvent)e);
		case .MouseMove: OnMouseMove((MouseEvent)e);
		case .MouseClick: OnMouseClick((MouseEvent)e);
		case .MouseEnter: OnMouseEnter((MouseEvent)e);
		case .MouseLeave: OnMouseLeave((MouseEvent)e);
		case .MouseWheel: OnMouseWheel((WheelEvent)e);
		case .KeyDown: OnKeyDown((KeyEvent)e);
		case .KeyUp: OnKeyUp((KeyEvent)e);
		case .TextInput: OnTextInput((TextInputEvent)e);
		case .Composition: OnComposition((CompositionEvent)e);
		case .ContextMenu: OnContextMenu((MouseEvent)e);
		case .PointerCaptureLost: OnPointerCaptureLost();
		case .PointerCancel: OnPointerCancel((MouseEvent)e);
		default:
		}
		if (!e.Handled && IsScrollContainer)
			ScrollDefaultAction(e);
	}

	/// Moves the offset (clamped as ScrollOffset says) and reports the scroll; a smooth scroll's
	/// steps come here without ending it.
	protected void ApplyScrollOffset(Float2 offset)
	{
		let clamped = ClampScroll(offset);
		if (clamped == mScrollOffset)
			return;
		mScrollOffset = clamped;
		Invalidate();
		if (mStickToEnd)
			mLatchedToEnd = IsAtScrollEnd; // scrolled away it lets go; back at the end it holds
		if (mLayoutStyle.BarVisibility == .Overlay)
			ShowOverlayScrollbars();
		OnScrollChange();
		SendEvent(scope Event(.Scroll, this));
	}

	/// `offset` within where it may go (with a layout pending, as asked: the layout clamps it).
	protected Float2 ClampScroll(Float2 offset)
	{
		if (mLayoutDirty || mChildLayoutDirty)
			return offset;
		let low = ScrollMin;
		let high = ScrollMax;
		return .(Clamp(offset.X, low.X, high.X), Clamp(offset.Y, low.Y, high.Y));
	}

	// Tells this GUI's dispatcher a child's subtree is leaving: it drops what it held in it. A node
	// in no GUI has no dispatcher to tell.
	protected void NotifyRemovingChild(Node child)
	{
	}

	// Tells this GUI's commands that what decides availability changed. A node in no GUI has no
	// commands to tell.
	private void NotifyCommandsChanged()
	{
	}

	// Something changed under `child`: its reach is read again at the next check (all of them,
	// once that is most of them). Cleared with the children, so it never holds one gone.
	private void NoteChildChanged(Node child)
	{
		if ((mChildIndex == null) || mChildIndexAll)
			return;
		if (mChangedChildren.Count > mChildren.Count / 4 + 8)
		{
			mChildIndexAll = true;
			mChangedChildren.Clear();
			return;
		}
		mChangedChildren.Add(child);
	}

	// Checks the index against the children (those something changed under, or all when the
	// children changed), building it again when a reach moved.
	private void RefreshChildIndex()
	{
		if (mChildIndex == null)
			mChildIndex = new ChildIndex();
		let index = mChildIndex;
		let n = mChildren.Count;
		bool moved = false;
		if (!index.Built || mChildIndexAll || (index.Rects.Count != n))
		{
			moved = !index.Built || (index.Rects.Count != n);
			index.Rects.Resize(n);
			for (int i = 0; i < n; i++)
			{
				let c = mChildren[i];
				let r = c.Transform.TransformRect(c.SubtreeInk);
				moved = moved || !(index.Rects[i] == r);
				index.Rects[i] = r;
			}
		}
		else
		{
			for (let child in mChangedChildren)
			{
				let i = GetChildIndex(child);
				if (i == cInvalidIndex)
					continue;
				let r = child.Transform.TransformRect(child.SubtreeInk);
				moved = moved || !(index.Rects[i] == r);
				index.Rects[i] = r;
			}
		}
		mChildIndexAll = false;
		mChangedChildren.Clear();
		if (!moved)
			return;
		// The axis they spread along more: a column's, or a row's; and the bounds of them all.
		float minX = 0.0f;
		float maxX = 0.0f;
		float minY = 0.0f;
		float maxY = 0.0f;
		for (int i = 0; i < n; i++)
		{
			let r = index.Rects[i];
			minX = (i == 0) ? r.X : Min(minX, r.X);
			maxX = (i == 0) ? r.X : Max(maxX, r.X);
			minY = (i == 0) ? r.Y : Min(minY, r.Y);
			maxY = (i == 0) ? r.Y : Max(maxY, r.Y);
			index.Bounds = (i == 0) ? r : Rect.Union(index.Bounds, r);
		}
		index.Vertical = maxY - minY >= maxX - minX;
		let vertical = index.Vertical;
		float StartOf(uint32 i) => vertical ? index.Rects[(int)i].Y : index.Rects[(int)i].X;
		// Ordered by start: a merge sort, as children placed anywhere may come in any order.
		index.Order.Resize(n);
		for (int i = 0; i < n; i++)
			index.Order[i] = (uint32)i;
		var scratch = new List<uint32>();
		scratch.Resize(n);
		for (int width = 1; width < n; width *= 2)
		{
			for (int lo = 0; lo < n; lo += 2 * width)
			{
				let mid = Math.Min(lo + width, n);
				let hi = Math.Min(lo + 2 * width, n);
				int a = lo;
				int b = mid;
				int k = lo;
				while ((a < mid) && (b < hi))
					scratch[k++] = (StartOf(index.Order[b]) < StartOf(index.Order[a])) ? index.Order[b++] : index.Order[a++];
				while (a < mid)
					scratch[k++] = index.Order[a++];
				while (b < hi)
					scratch[k++] = index.Order[b++];
			}
			Swap!(index.Order, scratch);
		}
		delete scratch; // what the order was built from last
		index.Reach.Resize(n);
		float reach = 0.0f;
		for (int j = 0; j < n; j++)
		{
			let r = index.Rects[(int)index.Order[j]];
			let end = vertical ? r.Bottom : r.Right;
			reach = (j == 0) ? end : Max(reach, end);
			index.Reach[j] = reach;
		}
		index.Built = true;
		mChildIndexBuilds++;
	}

	// The style transform's matrix and origin in local units, from the functions and the size.
	// Mirrored, flipped about its centre first, wherever the origin is.
	private void UpdateStyleTransform()
	{
		let origin = Float2(ResolveAgainst(mTransformOriginX, mSize.X), ResolveAgainst(mTransformOriginY, mSize.Y));
		var transform = ComposeTransforms(mStyleTransforms, mSize);
		if (mMirrored)
		{
			var flip = Transform2D.Identity;
			flip.Scale(-1.0f, 1.0f, mSize.X * 0.5f - origin.X, 0.0f);
			transform = transform * flip;
		}
		SetExtraTransform(transform, origin);
		Invalidate();
	}

	// Where each child's drawing reaches, in this node's children's space, ordered along the axis
	// they spread on, with the farthest reach so far at each place.
	private class ChildIndex
	{
		/// By child.
		public List<Rect> Rects = new .() ~ delete _;
		/// Children by where they start along the axis.
		public List<uint32> Order = new .() ~ delete _;
		/// The farthest end along the axis of Order[0..i].
		public List<float> Reach = new .() ~ delete _;
		/// Around every child's reach.
		public Rect Bounds = .();
		public bool Vertical = true;
		public bool Built = false;
	}

	private class CommandHandlerEntry
	{
		public String Id = new .() ~ delete _;
		public CommandPhase Phase;
		public CommandHandler Handler ~ delete _;
		public uint32 Token;
		/// While handlers run: goes once they return.
		public bool Removed = false;
	}

	private struct PropertyBinding
	{
		/// The property bound (its table's record).
		public GuiPropertyInfo Property;
		/// The write-back from it.
		public bool Back;
		/// One of mBindings.
		public Effect Bound;

		public this(GuiPropertyInfo property, bool back, Effect bound)
		{
			Property = property;
			Back = back;
			Bound = bound;
		}
	}

	private class TranslatedProperty
	{
		public String Property = new .() ~ delete _;
		public String Key = new .() ~ delete _;
	}

	// The last few measures, by the constraints each was for. One slot is not enough: a flex item
	// is measured for its base size and again at its resolved size, and with one slot each level of
	// nesting would measure what it holds twice (2^depth).
	private struct MeasureEntry
	{
		public LayoutConstraints Key = .();
		public Float2 Size = .(0.0f, 0.0f);

		public this() { }

		public this(LayoutConstraints key, Float2 size)
		{
			Key = key;
			Size = size;
		}
	}

	private const uint32 cNoGeneration = uint32.MaxValue;
	private const int cMeasureSlots = 4;

	/// How many containers laid out on this thread.
	[ThreadStatic]
	private static uint32 sLayoutRunCounter = 0;

	private Sedulous.GUI.Cursor mCursor = .Auto;
	private uint8 mTouchActions = cTouchAuto; // touch-action
	private bool mHovered = false; // on the dispatcher's hover path
	private bool mPressed = false; // on its press path
	private Node mParent = null; // not owned: the parent holds this node, not the other way
	private uint32 mChildrenGeneration = 0; // bumped when the children change
	private int mIndexInParent = 0; // its index, while
	private uint32 mIndexGeneration = cNoGeneration; // this is its parent's generation
	private List<Node> mChildren = new .() ~ delete _; // one reference held to each
	private ChildIndex mChildIndex = null ~ delete _; // made for a node with many children
	private bool mChildIndexAll = true; // every child's reach to be read again
	private List<Node> mChangedChildren = new .() ~ delete _; // children something under changed in, since the index was checked
	private uint32 mChildIndexBuilds = 0;
	private bool mStackedKnown = false; // whether mStacked holds HasStackedChildren's answer
	private Rect mDrawnArea = .(); // what its subtree covered when last drawn, in device pixels
	private bool mDrawnAreaValid = false; // drawn, and on screen
	private bool mDamageNoted = false; // its old area went to its root since it was drawn
	private bool mStacked = false;
	private List<Listener> mListeners = new .() ~ DeleteContainerAndItems!(_);
	private List<Effect> mBindings = new .() ~ DeleteContainerAndItems!(_); // this node's bindings (Bind, BindFor)
	private List<PropertyBinding> mPropertyBindings = new .() ~ delete _; // which binding is each property's
	private Observable mSceneRootChanged = new .() ~ delete _; // told when this subtree joins or leaves a GUI
	private List<CommandHandlerEntry> mCommandHandlers = new .() ~ DeleteContainerAndItems!(_);
	private List<CommandHandlerEntry> mPendingCommandHandlers = new .() ~ DeleteContainerAndItems!(_); // added while handlers ran
	private List<Listener> mPendingListeners = new .() ~ DeleteContainerAndItems!(_); // added while listeners ran
	private uint16 mDispatching = 0; // runs of its listeners or handlers in progress
	private delegate bool(DragRequest request) mDragSource ~ delete _;
	private delegate void(DropQuery query) mDropQuery ~ delete _;
	private delegate void(DragResult result) mDragEnd ~ delete _;
	private String mDropTypes ~ delete _; // null until set
	private bool mDropTargetState = false;
	private bool mDragSourceState = false;
	private bool mLeaving = false; // Leave was called; it goes when its exit ends
	private bool mInert = false; // takes no input
	private bool mLeaveQueued = false; // its removal waits in the mutation queue
	private uint8 mEnterPhase = 0; // 1 in :entering, 2 moving to its own style, 0 arrived
	private bool mEnterQueued = false; // its entrance's next step waits in the mutation queue
	private bool mStyledTree = false; // the top of a tree a style pass ran over
	private Float2 mSize = .(0.0f, 0.0f);
	private Sedulous.GUI.LayoutStyle mLayoutStyle = new .() ~ delete _; // what it asks of layout
	private Display mDisplayBeforeNone = .Flex; // what Displayed = true gives back
	private Thickness mPadding = .();
	private Thickness mPaddingPercent = .(); // of the containing box's width (CSS's padding percentages)
	private float mPercentWidth = -1.0f; // the containing box's width it was last measured in (-1: unknown)
	private Float2 mScrollOffset = .(0.0f, 0.0f); // a scroll container's (its children move by minus it)
	private float mPixelScale = 1.0f; // device pixels per unit at its last arrange (its edges round to them)
	private Float2 mContentExtent = .(0.0f, 0.0f); // the children's extent as last laid out
	private MeasureEntry[cMeasureSlots] mMeasures = default;
	private uint8 mMeasureCount = 0; // slots in use (0: nothing cached)
	private uint8 mMeasureNext = 0; // the slot the next measure replaces once all are in use
	private bool mPlacing = false; // inside Arrange: the size and place set are the layout's
	private float mScrollStep = 40.0f; // the wheel's notch and an arrow key's step
	private bool mScrollsByKeys = true; // focused, the arrow and page keys scroll it
	private Float2 mScrollTarget = .(0.0f, 0.0f); // where a smooth scroll is going
	private bool mSmoothScrolling = false; // a smooth scroll is easing toward mScrollTarget
	private bool mSmoothTicking = false; // its tick runs on the GUI's clock
	private uint8 mScrollHover = 0; // the pointer over a bar: 0 none, 1 its track, 2 its thumb
	private float mScrollbarAlpha = 0.0f; // an overlay's bars: shown while scrolling or hovered, then fading
	private float mScrollbarIdle = 0.0f; // seconds since an overlay's bars were last wanted
	private bool mScrollbarFading = false; // the overlay's tick runs
	private bool mStickToEnd = false; // held at the end as the content grows
	private bool mLatchedToEnd = false; // at the end, so held there
	private bool mFlinging = false; // a fling is gliding
	private bool mFlingTicking = false; // its tick runs
	private Float2 mFlingVelocity = .(0.0f, 0.0f); // as it was let go
	private Float2 mFlingStart = .(0.0f, 0.0f); // the offset it was let go at
	private float mFlingTime = 0.0f; // seconds since
	private uint32 mScrollDragAxis = 2; // a bar being dragged (0, 1), 2 for none
	private float mScrollDragGrab = 0.0f; // where on the thumb it was taken
	private float mAlpha = 1.0f;
	private bool mVisible = true;
	private bool mEnabled = true;
	private bool mNeedsRedraw = true;
	private bool mSubtreeInkValid = false; // mSubtreeInk holds what it and its subtree draw
	private uint32 mDrawnFrame = 0; // the host's frame it was last drawn in
	private uint32 mForcedStyleStates = 0; // StyleState bits the style pass reads as set
	private bool mInvalidatedSelf = true; // invalidated itself (not through a descendant) since drawn
	private uint8 mQuietInvalidations = 0; // inside BeginQuietInvalidation's
	private AutoTranslate mAutoTranslate = .Inherit;
	private LayoutDirection mDirection = .Inherit;
	private bool mPlacesChildren = false; // its children at points of its own, not mirrored
	private bool mMirrorOnRtl = false;
	private bool mAccessDirty = true; // its accessibility node waits to be sent
	private bool mAccessChildDirty = false; // some descendant's does
	private uint64 mAccessSent = 0; // a hash of its node as last sent (0: never)
	private bool mPlacedByCode = false; // Position set from code put it where it is (its insets are in the parent's box)
	private bool mMirrored = false; // mirror-on-rtl, and it runs right to left: flipped about its centre
	private Observable mTranslationChanged = new .() ~ delete _; // its auto-translation changed (its translated bindings follow)
	private String mLang ~ delete _; // its language, null or empty: inherited
	private List<TranslatedProperty> mTranslations = new .() ~ DeleteContainerAndItems!(_); // what a translation binding bound (the inspector reads it)
	private Rect mSubtreeInk = .();
	private bool mStyleDirty = true; // restyle this node
	private bool mStyleSubtreeDirty = true; // ... and every descendant
	private bool mChildStyleDirty = false; // some descendant waits for a restyle
	private bool mStyleMotionDirty = false; // a tween moved: apply again, the cascade as it was
	private bool mChildrenArrangementChanged = false; // its children were added, removed or moved
	private bool mLayoutDirty = false; // this container's layout must run
	private bool mChildLayoutDirty = false; // some descendant's must
	private bool mLayingOut = false; // inside OnLayout: the sizes it sets are its own
	private bool mClipChildren = false;
	private bool mTopLayer = false; // open as a popup (InTopLayer)
	private bool mRouteStop = false; // an event's route ends here (a modal popup)
	private Sedulous.GUI.NavScope mNavScope = .None;
	private bool mFocusGroup = false; // one Tab stop; its arrows move inside it
	private String mDefaultFocusId ~ delete _; // null until set
	private ElementRef mRememberedFocus = .(); // weak: resolved through the GUI's element table
	private String[(int)NavOverride.NavOverrideCount] mNavOverrides = default; // nav-up and the rest: an id, none, or auto (null until set)
	private String mKeyContext ~ delete _; // for bindings (key-context); null until set
	private bool mFocused = false;
	private bool mStyleWriting = false; // a StyleWriteScope lives: setters do not pin
	private StyleSlotSet mStylePins = .(); // the StyleSlots code set (they are its, over the sheet's)
	private UnstyledValues mUnstyled = new .() ~ delete _;
	private uint32 mFocusWithin = 0; // focused descendants (one at most; a count survives odd orders)
	private uint32 mChangedStyleStates = 0; // the StyleStates that changed since the last style pass
	private bool mFocusVisible = false; // focused by the keyboard or a gamepad
	private bool mTabFocusable = false;
	private bool mKeepsFocus = false; // a press in it leaves the focus where it is
	private int32 mTabIndex = 0; // where Tab reaches it: positive first, 0 in tree order, below 0 never
	private bool mTabCaptures = false; // Tab is its key, not focus's
	private bool mHitTestVisible = true;
	private uint32 mNextListenerId = 0;
	private NodeBox mBox = new .() ~ delete _;
	private bool mBoxFromStyle = false;
	private List<TransformFunction> mStyleTransforms = new .() ~ delete _;
	private LengthValue mTransformOriginX = .(50.0f, .Percent);
	private LengthValue mTransformOriginY = .(50.0f, .Percent);
	private bool mTransformFromStyle = false;
	private Sedulous.GUI.ElementTable mElementTable = null; // the table it took a slot in (null: none yet); one reference held
	private uint32 mElementSlot = 0;

	/// Its own reflected table (an instance answers for its most derived reflected type).
	public virtual GuiTypeInfo GuiType => StaticGuiType;
}

/// What Node.bf keeps out of the public surface.
internal static class NodeDetail
{
	/// touch-action's text for each of the bits' combinations (as TouchActionsName writes them).
	public static String[8] sTouchActionNames = .(
		"none", "pan-x", "pan-y", "pan-x pan-y", "pinch-zoom", "pan-x pinch-zoom", "pan-y pinch-zoom", "auto");

	public static bool Scrolls(Overflow o) => (o == .Scroll) || (o == .Auto);

	/// A text a node keeps only once it is set (most nodes set none of them).
	public static StringView ViewOf(String text) => (text != null) ? (StringView)text : default;

	public static void SetText(ref String text, StringView value)
	{
		if (text == null)
		{
			if (value.IsEmpty)
				return;
			text = new String();
		}
		text.Set(value);
	}
}
