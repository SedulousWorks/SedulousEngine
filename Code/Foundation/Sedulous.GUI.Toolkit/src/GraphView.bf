using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The graph view: a graph source's nodes on a canvas that pans and zooms over a grid. A node is a
// widget (its header, title and a row per pin, which the sheet styles), made only while it is in
// view and reused as the view moves (Godot, traktor); a node never seen is made once to learn its
// size. The canvas runs left to right in every language, as a dopesheet's time does: where the nodes
// are placed is the graph's, so inputs stay on a node's left and outputs on its right, and only its
// text follows the language. Mouse first:
//   - a click selects a node (Shift or Ctrl adds or takes it away), a drag from nothing selects by a
//     box (Shift or Ctrl adding to what is selected);
//   - a drag moves the selected nodes (one gesture through the source, on the grid where it snaps;
//     Escape cancels it);
//   - a drag from a pin links it (ezEngine): the source is asked of each pin, which it answers
//     allowed or refused (and why) and which links it would replace, so the pins that fit are lit,
//     the rest dimmed, a link about to be replaced faded and a refusal's reason shown; a drag from an
//     input that has a link takes that link's end, to rewire it or, dropped on nothing, let it go;
//   - a drag from just outside a node's edge links it to another node (a state machine's
//     transition), where the source takes node links: a straight arrow between their borders, the
//     two ways kept apart, a node to itself when the drag leaves it and comes back;
//   - a click on a link selects it (Shift or Ctrl adds or takes it away);
//   - a link dropped on nothing opens the picker of the kinds of node with a pin that fits, the node
//     chosen made there, linked to it, in one change;
//   - the menu over nothing adds a node (the picker: by category, with a search), pastes, and frames
//     every node or the selection; a node's copies, duplicates, deletes and begins a node link (then
//     the link follows the pointer until a click ends it); a link's deletes it;
//   - Delete deletes the selected nodes and links, Escape cancels a drag or clears the selection,
//     Ctrl+C copies the selected nodes and Ctrl+V pastes them at the pointer, as the property grid's;
//   - a frame (a titled, tinted box behind the nodes; with a body, a comment) moves by its title, the
//     nodes and frames inside it moving with it, and resizes from its edges, each one change; a
//     double click on its title or its body edits it in place.
//   - a double click on a node is the application's (a subgraph opened);
//   - the wheel zooms about the pointer within limits, a middle drag pans.
// Frames' boxes are drawn by the view under the links, their titles and bodies widgets over them.
// Links are drawn by the view under the nodes, culled to it, each pin's place kept from when its node
// was last laid out. The application may highlight nodes and links (a state machine's active state).
// Read only, it selects and does not edit.

/// What a pin or a node is to a link being dragged: nothing, a place it may end (lit), one it may
/// not (dimmed), or the one under the pointer that it would end at.
enum GraphLinkState : uint8
{
	None,
	Fits,
	Refused,
	Target,
}

static
{
	/// Shows `state` as a class (`fits`, `refused` or `target`) for the sheet.
	public static void ShowLinkState(UIWidget widget, GraphLinkState state)
	{
		widget.RemoveClass("fits");
		widget.RemoveClass("refused");
		widget.RemoveClass("target");
		if (state == .Fits)
			widget.AddClass("fits");
		else if (state == .Refused)
			widget.AddClass("refused");
		else if (state == .Target)
			widget.AddClass("target");
	}
}

/// A pin's row in a node: its name, the pin drawn on the node's edge by the node.
[GuiReflect]
class GraphPinRow : UIWidget
{
	private Label mName ~ _.ReleaseRef();
	private GraphLinkState mLinkState = .None;
	private GraphId mPin = 0;
	private GraphPinDirection mDirection = .Input;
	private Color mColor = .();

	public this()
	{
		Tag = "graphpin";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.MinHeight = LayoutLength.Px(20.0f);
				});
			Padding = Thickness(12.0f, 0.0f, 12.0f, 0.0f);
		}
		mName = new Label();
		mName.HitTestVisible = false;
		mName.SetLayoutDirection(.Auto); // its text reads as written; the row stays left to right
		AddChild(mName);
	}

	public void Show(GraphPinInfo pin)
	{
		mPin = pin.Id;
		mDirection = pin.Direction;
		mColor = pin.TypeColor;
		mName.Text = pin.Name;
		if (pin.Direction == .Output)
		{
			RemoveClass("input");
			AddClass("output");
		}
		else
		{
			RemoveClass("output");
			AddClass("input");
		}
	}

	public GraphId PinId => mPin;
	public GraphPinDirection PinDirection => mDirection;
	public Color TypeColor => mColor;
	public Label NameLabel => mName;

	/// What it is to a link being dragged.
	public GraphLinkState LinkState
	{
		get => mLinkState;
		set
		{
			if (value == mLinkState)
				return;
			mLinkState = value;
			ShowLinkState(this, value);
			// The node draws its pins: up from the row through its column and the body.
			Node node = this;
			for (int32 up = 0; (up < 3) && (node != null); ++up)
				node = node.Parent;
			if (node != null)
				node.Invalidate();
		}
	}
}

/// A node's header: its title and subtitle over the source's header colour.
[GuiReflect]
class GraphNodeHeader : UIWidget
{
	private Color mColor = .(0.27f, 0.47f, 0.73f, 1.0f);

	public this()
	{
		Tag = "graphnodeheader";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.MinHeight = LayoutLength.Px(22.0f);
					s.JustifyContent = .Center;
				});
			Padding = Thickness(8.0f, 3.0f, 8.0f, 3.0f);
		}
	}

	public Color HeaderColor
	{
		get => mColor;
		set
		{
			if ((value.R == mColor.R) && (value.G == mColor.G) && (value.B == mColor.B) && (value.A == mColor.A))
				return;
			mColor = value;
			Invalidate();
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		// Rounded as the node's top corners are, inside its border.
		var radii = CornerRadii();
		if (let node = Parent)
		{
			let @box = node.Box;
			radii.TopLeft = Max(0.0f, @box.Radii.TopLeft - Max(@box.BorderWidths.Top, @box.BorderWidths.Left));
			radii.TopRight = Max(0.0f, @box.Radii.TopRight - Max(@box.BorderWidths.Top, @box.BorderWidths.Right));
		}
		ctx.VG.FillRoundedRect(.(0.0f, 0.0f, Size.X, Size.Y), radii, mColor);
		base.OnDraw(ctx, localBounds);
	}
}

/// A node of a graph view: its header and a row per pin, inputs on its left and outputs on its right
/// in every language (the canvas's flow), each pin drawn on the node's edge. A view fills it from the
/// source.
[GuiReflect]
class GraphNodeWidget : UIWidget
{
	public const float cPinRadius = 4.5f;

	private GraphNodeHeader mHeader ~ _.ReleaseRef();
	private Label mTitle ~ _.ReleaseRef();
	private Label mSubtitle ~ _.ReleaseRef();
	private UIWidget mBody ~ _.ReleaseRef();
	private UIWidget mInputs ~ _.ReleaseRef();
	private UIWidget mOutputs ~ _.ReleaseRef();
	private List<GraphPinRow> mInputRows = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; };
	private List<GraphPinRow> mOutputRows = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; };
	private GraphId mNode = 0;
	private bool mSelected = false;
	private bool mHighlighted = false;
	private GraphLinkState mLinkState = .None;

	public this()
	{
		Tag = "graphnode";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.MinWidth = LayoutLength.Px(140.0f);
				});
		}
		mHeader = new GraphNodeHeader();
		AddChild(mHeader);
		mTitle = new Label();
		mTitle.AddClass("title");
		mTitle.HitTestVisible = false;
		mHeader.AddChild(mTitle);
		mSubtitle = new Label();
		mSubtitle.AddClass("subtitle");
		mSubtitle.HitTestVisible = false;
		mSubtitle.Displayed = false;
		mHeader.AddChild(mSubtitle);

		mBody = MakePart(this, "graphnodebody");
		using (StyleWriteScope(mBody))
		{
			mBody.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.JustifyContent = .SpaceBetween;
					s.ColumnGap = 8.0f;
				});
			mBody.Padding = Thickness(0.0f, 4.0f, 0.0f, 4.0f);
		}
		mBody.SetLayoutDirection(.LeftToRight);
		mInputs = MakePart(mBody, "graphpins");
		mInputs.AddClass("inputs");
		mOutputs = MakePart(mBody, "graphpins");
		mOutputs.AddClass("outputs");
		using (StyleWriteScope(mInputs))
		{
			mInputs.EditLayoutStyle(scope (s) => { s.Direction = .Column; });
		}
		using (StyleWriteScope(mOutputs))
		{
			mOutputs.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.AlignItems = .End;
				});
		}
	}

	/// Shows `node` (what changed since it last showed one).
	public void Show(GraphNodeInfo node)
	{
		mNode = node.Id;
		mTitle.Text = node.Title;
		mSubtitle.Text = node.Subtitle;
		mSubtitle.Displayed = !node.Subtitle.IsEmpty;
		mHeader.HeaderColor = node.HeaderColor;
		int inputs = 0;
		int outputs = 0;
		for (let pin in node.Pins)
		{
			let @out = pin.Direction == .Output;
			RowAt(@out ? mOutputRows : mInputRows, @out ? mOutputs : mInputs, @out ? outputs++ : inputs++).Show(pin);
		}
		Trim(mInputRows, mInputs, inputs);
		Trim(mOutputRows, mOutputs, outputs);
	}

	public GraphId NodeId => mNode;

	/// Shown selected (the sheet's `graphnode.selected`).
	public bool IsSelected
	{
		get => mSelected;
		set
		{
			if (value == mSelected)
				return;
			mSelected = value;
			if (value)
				AddClass("selected");
			else
				RemoveClass("selected");
		}
	}

	/// Highlighted by the application (the sheet's `graphnode.highlighted`): a state machine's active
	/// state.
	public bool IsHighlighted
	{
		get => mHighlighted;
		set
		{
			if (value == mHighlighted)
				return;
			mHighlighted = value;
			if (value)
				AddClass("highlighted");
			else
				RemoveClass("highlighted");
		}
	}

	/// What the node is to a node link being dragged.
	public GraphLinkState LinkState
	{
		get => mLinkState;
		set
		{
			if (value == mLinkState)
				return;
			mLinkState = value;
			ShowLinkState(this, value);
		}
	}

	/// Where pin `pin` is drawn, in the node's own space (on its left edge for an input, its right for
	/// an output, across from its row's middle); false when it has no such pin.
	public bool PinPoint(GraphId pin, out Float2 outPoint)
	{
		outPoint = .(0.0f, 0.0f);
		for (int side = 0; side < 2; ++side)
		{
			let output = side == 1;
			for (let row in output ? mOutputRows : mInputRows)
			{
				if (row.PinId != pin)
					continue;
				let at = OffsetIn(row);
				outPoint = .(output ? Size.X : 0.0f, at.Y + row.Size.Y * 0.5f);
				return true;
			}
		}
		return false;
	}

	/// The pin rows, inputs then outputs.
	public int PinRowCount => mInputRows.Count + mOutputRows.Count;
	public GraphPinRow PinRowAt(int index) => (index < mInputRows.Count) ? mInputRows[index] : mOutputRows[index - mInputRows.Count];
	public Label TitleLabel => mTitle;
	public Label SubtitleLabel => mSubtitle;
	public GraphNodeHeader Header => mHeader;
	/// Under the pin rows: where an application puts widgets of its own.
	public UIWidget Body => mBody;

	/// What it draws: its box and its pins over its edges.
	public override Rect InkBounds
	{
		get
		{
			let ink = base.InkBounds;
			let reach = cPinRadius + 3.0f;
			return .(ink.X - reach, ink.Y, ink.Width + 2.0f * reach, ink.Height);
		}
	}

	protected override void OnDrawAbove(DrawContext ctx)
	{
		for (int i = 0; i < PinRowCount; ++i)
		{
			let row = PinRowAt(i);
			Float2 at;
			if (!PinPoint(row.PinId, out at))
				continue;
			// While a link is dragged: the pins it may end at ringed light, the one under the pointer
			// larger, the rest dimmed.
			let state = row.LinkState;
			let radius = (state == .Target) ? cPinRadius + 2.0f : cPinRadius;
			var ringColor = Color(0.0f, 0.0f, 0.0f, 0.55f);
			var color = row.TypeColor;
			if ((state == .Fits) || (state == .Target))
				ringColor = .(1.0f, 1.0f, 1.0f, 0.9f);
			else if (state == .Refused)
			{
				color.A *= 0.3f;
				ringColor.A *= 0.3f;
			}
			let ring = scope PathBuilder();
			ShapeBuilder.BuildCircle(at, radius + 1.0f, ring);
			let ringPath = ring.ToPath();
			ctx.VG.FillPath(ringPath, ringColor);
			delete ringPath;
			let dot = scope PathBuilder();
			ShapeBuilder.BuildCircle(at, radius, dot);
			let dotPath = dot.ToPath();
			ctx.VG.FillPath(dotPath, color);
			delete dotPath;
		}
	}

	// A part it holds, the last child of `parent`: the caller keeps the reference it comes with.
	private static UIWidget MakePart(UIWidget parent, StringView tag)
	{
		let part = new UIWidget();
		part.Tag = tag;
		parent.AddChild(part);
		return part;
	}

	private GraphPinRow RowAt(List<GraphPinRow> rows, UIWidget column, int index)
	{
		while (rows.Count <= index)
		{
			let row = new GraphPinRow();
			rows.Add(row);
			column.AddChild(row);
		}
		return rows[index];
	}

	private static void Trim(List<GraphPinRow> rows, UIWidget column, int count)
	{
		while (rows.Count > count)
		{
			let last = rows.Back;
			column.RemoveChild(last);
			rows.PopBack();
			last.ReleaseRef();
		}
	}

	// `inner`'s top-left in this node's space (nothing between them is transformed).
	private Float2 OffsetIn(Node inner)
	{
		var at = Float2(0.0f, 0.0f);
		for (var n = inner; (n != null) && (n != this); n = n.Parent)
			at = .(at.X + n.Position.X, at.Y + n.Position.Y);
		return at;
	}
}

/// A frame of a graph view: its title and its body (a comment's), each edited in place by a double
/// click. The view draws its tinted box under the links; it holds the words over them.
[GuiReflect]
class GraphFrameWidget : UIWidget
{
	public const float cHeaderMin = 24.0f;

	private EditableLabel mTitle ~ _.ReleaseRef();
	private UIWidget mBodyBox ~ _.ReleaseRef();
	private EditableLabel mBody ~ _.ReleaseRef();
	private GraphId mFrame = 0;
	private bool mSelected = false;
	private delegate void(GraphId frame, StringView text, bool body) mOnCommitted ~ delete _;

	public this()
	{
		Tag = "graphframe";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.RowGap = 8.0f;
				});
			Padding = Thickness(8.0f, 4.0f, 8.0f, 8.0f);
		}
		ClipChildren = true;
		mTitle = new EditableLabel();
		mTitle.AddClass("title");
		using (StyleWriteScope(mTitle))
		{
			mTitle.EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		}
		AddChild(mTitle);
		// The comment in the room the frame has left, as tall as its text and scrolled there when
		// longer (the wheel taken while it moves, then the view's again; while it is typed in, to keep
		// the caret in view).
		mBodyBox = new UIWidget();
		mBodyBox.Tag = "graphframebody";
		using (StyleWriteScope(mBodyBox))
		{
			mBodyBox.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.Grow = 1.0f;
					s.MinHeight = LayoutLength.Px(0.0f);
					s.OverflowY = .Auto;
				});
		}
		AddChild(mBodyBox);
		mBody = new EditableLabel();
		mBody.AddClass("body");
		mBody.IsMultiline = true;
		mBody.Displayed = false;
		mBodyBox.AddChild(mBody);
		mTitle.SetOnTextCommitted(new (text) =>
			{
				if (mOnCommitted != null)
					mOnCommitted(mFrame, text, false);
			});
		mBody.SetOnTextCommitted(new (text) =>
			{
				if (mOnCommitted != null)
					mOnCommitted(mFrame, text, true);
			});
	}

	public void Show(GraphFrameInfo frame)
	{
		mFrame = frame.Id;
		if (!mTitle.IsEditing)
			mTitle.Text = frame.Title;
		if (!mBody.IsEditing)
		{
			mBody.Text = frame.Body;
			mBody.Displayed = !frame.Body.IsEmpty;
		}
	}

	public GraphId FrameId => mFrame;
	public EditableLabel TitleLabel => mTitle;
	public EditableLabel BodyLabel => mBody;
	/// What scrolls a comment longer than the frame.
	public UIWidget BodyBox => mBodyBox;

	/// Edits its body in place, shown while it does (a frame made a comment).
	public void EditBody()
	{
		mBody.Displayed = true;
		mBody.BeginEdit();
	}

	/// How tall its title band is, in its own space: what a press moves it by.
	public float HeaderHeight => Max(cHeaderMin, mTitle.Position.Y + mTitle.Size.Y + 4.0f);

	/// Shown selected (the sheet's `graphframe.selected`).
	public bool IsSelected
	{
		get => mSelected;
		set
		{
			if (value == mSelected)
				return;
			mSelected = value;
			if (value)
				AddClass("selected");
			else
				RemoveClass("selected");
		}
	}

	/// A title or a body (`body`) committed: the view's, to edit the frame through the source.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnCommitted(delegate void(GraphId frame, StringView text, bool body) callback)
	{
		delete mOnCommitted;
		mOnCommitted = callback;
	}
}

[GuiReflect(true)]
class GraphView : UIWidget, IGraphSourceClient
{
	public const float cDragThreshold = 3.0f;
	/// How near a pin a press or a drop takes it (at least; the pin's own size when larger).
	public const float cPinReach = 9.0f;
	/// How far outside a node's edge a press begins a node link.
	public const float cEdgeReach = 7.0f;
	/// How near a link a click selects it.
	public const float cLinkReach = 5.0f;
	/// How far apart a node link and its reverse are drawn.
	public const float cParallelGap = 6.0f;
	/// How far inside a frame's edge a press resizes it.
	public const float cFrameEdge = 6.0f;
	/// The least a frame is resized to, in the graph's units.
	public const float cFrameMinWidth = 80.0f;
	public const float cFrameMinHeight = 48.0f;
	/// How far past its edges nodes are made before they come into view.
	public const float cViewMargin = 64.0f;

	/// The size a node is taken to have before it was measured.
	public static Float2 EstimatedNodeSize() => .(160.0f, 80.0f);

	private enum Drag : uint8
	{
		None,
		/// Pressed on a node, not moved past the threshold.
		Pending,
		Nodes,
		Box,
		Pan,
		Link,
		Resize,
	}

	// A frame's edges a press is on (several at a corner).
	private const uint8 cEdgeLeft = 1;
	private const uint8 cEdgeTop = 2;
	private const uint8 cEdgeRight = 4;
	private const uint8 cEdgeBottom = 8;

	// Where a pin is in its node, as the node was last laid out.
	private struct PinPlace
	{
		public GraphId Node = 0;
		// In the node's space, unzoomed.
		public Float2 Offset = .(0.0f, 0.0f);
		public GraphPinDirection Direction = .Input;
		public Color TypeColor = .();

		public this() { }

		public this(GraphId node, Float2 offset, GraphPinDirection direction, Color typeColor)
		{
			Node = node;
			Offset = offset;
			Direction = direction;
			TypeColor = typeColor;
		}
	}

	// Not owned: the source outlives the view or is set to null first.
	private IGraphSource mSource = null;
	private bool mReadOnly = false;
	private Float2 mPan = .(0.0f, 0.0f);
	private float mZoom = 1.0f;
	private float mZoomMin = 0.2f;
	private float mZoomMax = 2.0f;
	private float mGridSize = 16.0f;
	private bool mSnap = true;
	// FrameAll's: fitting every node until the canvas is moved.
	private bool mFitting = false;
	private List<GraphId> mSelection = new .() ~ delete _;
	private delegate void() mOnSelectionChanged ~ delete _;
	private delegate void(GraphId node) mOnNodeDoubleClick ~ delete _;

	// The nodes made, by id (a reference held each).
	private Dictionary<GraphId, GraphNodeWidget> mLive = new .() ~ GraphViewDetail.ReleaseAll(_);
	// Made, waiting to be reused (a reference held each).
	private List<GraphNodeWidget> mPool = new .() ~ { for (let w in _) w.ReleaseRef(); delete _; };
	// Each node's size as last measured.
	private Dictionary<GraphId, Float2> mSizes = new .() ~ delete _;
	// Each pin's place, by pin id.
	private Dictionary<GraphId, PinPlace> mPins = new .() ~ delete _;
	private List<GraphId> mSelectedLinks = new .() ~ delete _;
	private List<GraphId> mHighlightedNodes = new .() ~ delete _;
	private List<GraphId> mHighlightedLinks = new .() ~ delete _;
	private Dictionary<GraphId, GraphFrameWidget> mFrameWidgets = new .() ~ GraphViewDetail.ReleaseAll(_);
	private List<GraphId> mSelectedFrames = new .() ~ delete _;
	// The frames a box adds to.
	private List<GraphId> mFrameBoxBase = new .() ~ delete _;
	// What a move moves: the selected nodes, and those inside the selected frames.
	private List<GraphId> mMoveNodes = new .() ~ delete _;
	private List<GraphId> mMoveFrames = new .() ~ delete _;
	// The frame pressed by its title.
	private GraphId mPressedFrame = 0;
	private GraphId mResizeFrame = 0;
	private uint8 mResizeEdges = 0;
	// The graph's.
	private Rect mResizeFrom = .();
	private Rect mResizeTo = .();

	private Drag mDrag = .None;
	// Where the gesture began, its own space.
	private Float2 mPressAt = .(0.0f, 0.0f);
	private Float2 mBoxTo = .(0.0f, 0.0f);
	// The node pressed.
	private GraphId mPressed = 0;
	// Its place in the graph when the move began.
	private Float2 mPressedFrom = .(0.0f, 0.0f);
	// Shift or Ctrl held at the press.
	private bool mAdditive = false;
	// What a box adds to.
	private List<GraphId> mBoxBase = new .() ~ delete _;
	private Float2 mPanFrom = .(0.0f, 0.0f);

	// A link dragged: from a pin (or, a node link, a node), or an existing link's input end.
	private GraphLinkKind mLinkKind = .Pins;
	private GraphId mAnchorNode = 0;
	private GraphId mAnchorPin = 0;
	// The anchor is the link's From end.
	private bool mAnchorOutput = true;
	// The link whose end is carried.
	private GraphId mRelinking = 0;
	// The input it came off.
	private GraphId mRelinkFrom = 0;
	// Past the threshold.
	private bool mLinkMoved = false;
	// A node link's pointer left its node (so it may come back to it).
	private bool mLeftAnchor = false;
	private Float2 mLinkTo = .(0.0f, 0.0f);
	private GraphId mTarget = 0;
	private GraphLinkCheck mTargetCheck = new .() ~ delete _;
	// Each pin's (or node's) answer, asked once per drag.
	private Dictionary<GraphId, bool> mFits = new .() ~ delete _;
	// Begun from a menu: it follows the pointer until a click.
	private bool mSticky = false;
	// A refusal's reason.
	private Sedulous.GUI.Text mText = new .() ~ delete _;

	// Where the pointer was last over it, its own space.
	private Float2 mPointer = .(0.0f, 0.0f);
	private bool mPointerInside = false;
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	private GraphNodePicker mPicker ~ _?.ReleaseRef();
	// Where the node picked goes, the graph's.
	private Float2 mPickAt = .(0.0f, 0.0f);
	// The pin it is linked from.
	private GraphId mPickFrom = 0;

	public this()
	{
		Tag = "graphview";
		TabFocusable = true;
		ClipChildren = true;
		PlacesChildren = true; // the nodes at their points on the canvas, which stays left to right
	}

	public ~this()
	{
		if (mSource != null)
			mSource.RemoveGraphClient(this);
	}

	// === What it shows ===

	/// The graph it shows and edits (not owned: the source outlives the view or is set to null
	/// first).
	public IGraphSource Source
	{
		get => mSource;
		set
		{
			if (mSource != null)
				mSource.RemoveGraphClient(this);
			mSource = value;
			if (mSource != null)
				mSource.AddGraphClient(this);
			mSelection.Clear();
			mSelectedLinks.Clear();
			mSelectedFrames.Clear();
			mSizes.Clear();
			mPins.Clear();
			RequestLayout();
		}
	}

	/// Read only: it selects, and moves and edits nothing.
	public bool IsReadOnly
	{
		get => mReadOnly;
		set => mReadOnly = value;
	}

	// === The canvas ===

	/// The graph's point at its content box's top-left.
	public Float2 Pan
	{
		get => mPan;
		set
		{
			mFitting = false;
			mPan = value;
			RequestLayout();
		}
	}

	/// The zoom (within its limits), the graph's point at `about` (its own space) kept in place.
	public void SetZoom(float zoom, Float2 about)
	{
		mFitting = false;
		let @fixed = ViewToGraph(about);
		mZoom = Clamp(zoom, mZoomMin, mZoomMax);
		let @box = ContentBounds;
		mPan = .(@fixed.X - (about.X - @box.X) / mZoom, @fixed.Y - (about.Y - @box.Y) / mZoom);
		RequestLayout();
	}

	public void SetZoom(float zoom) => SetZoom(zoom, Float2(ContentBounds.X, ContentBounds.Y));
	public float Zoom => mZoom;

	public void SetZoomLimits(float least, float most)
	{
		mZoomMin = Max(0.01f, least);
		mZoomMax = Max(mZoomMin, most);
		SetZoom(mZoom);
	}

	public float ZoomMin => mZoomMin;
	public float ZoomMax => mZoomMax;

	/// The grid's cell in the graph's units, what a move snaps to when it snaps.
	[GuiProperty("grid-size")]
	public float GridSize
	{
		get => mGridSize;
		set
		{
			mGridSize = Max(1.0f, value);
			Invalidate();
		}
	}

	public bool SnapToGrid
	{
		get => mSnap;
		set => mSnap = value;
	}

	public Float2 GraphToView(Float2 graph)
	{
		let @box = ContentBounds;
		return .(@box.X + (graph.X - mPan.X) * mZoom, @box.Y + (graph.Y - mPan.Y) * mZoom);
	}

	public Float2 ViewToGraph(Float2 local)
	{
		let @box = ContentBounds;
		return .(mPan.X + (local.X - @box.X) / mZoom, mPan.Y + (local.Y - @box.Y) / mZoom);
	}

	/// Fits every node in view (at most at the zoom of 1), and goes on fitting them as it is laid out
	/// (its size settling, its nodes measured) until the canvas is moved: a press or the wheel in it,
	/// or code setting its pan or zoom.
	public void FrameAll()
	{
		mFitting = true;
		Frame(false);
		RequestLayout();
	}

	/// Fits the selected nodes in view; every node with none selected.
	public void FrameSelection()
	{
		mFitting = false;
		Frame(!mSelection.IsEmpty);
	}

	/// Whether it still fits every node (FrameAll, the canvas not moved since).
	public bool IsFitting => mFitting;

	// === Edits of the selection (one change each, through the source) ===

	/// Deletes the selected nodes (and their links), then the selected links left; false when nothing
	/// went.
	public bool DeleteSelected()
	{
		if ((mSource == null) || mReadOnly)
			return false;
		bool any = false;
		if (!mSelection.IsEmpty)
		{
			let nodes = scope List<GraphId>();
			nodes.AddRange(mSelection);
			any = mSource.DeleteNodes(nodes);
		}
		if (!mSelectedLinks.IsEmpty) // those the nodes did not take with them
		{
			let links = scope List<GraphLinkInfo>();
			mSource.GetLinks(links);
			let left = scope List<GraphId>();
			for (let link in mSelectedLinks)
			{
				for (let at in links)
				{
					if (at.Id == link)
						left.Add(link);
				}
			}
			if (!left.IsEmpty)
				any = mSource.Disconnect(left) || any;
		}
		if (!mSelectedFrames.IsEmpty)
		{
			let frames = scope List<GraphId>();
			frames.AddRange(mSelectedFrames);
			any = mSource.DeleteFrames(frames) || any;
		}
		return any;
	}

	/// Copies the selected nodes (and the links among them) to the clipboard as the source's text.
	public bool CopySelected()
	{
		let dispatcher = EventDispatcher;
		let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
		if ((mSource == null) || (clipboard == null) || mSelection.IsEmpty)
			return false;
		let text = scope String();
		mSource.CopyNodes(mSelection, text);
		if (text.IsEmpty)
			return false;
		clipboard.SetText(text);
		return true;
	}

	/// Pastes the clipboard's nodes, their top-left at `at` (the graph's), selecting them.
	public bool PasteAt(Float2 at)
	{
		let dispatcher = EventDispatcher;
		let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
		if ((mSource == null) || mReadOnly || (clipboard == null) || !clipboard.HasText)
			return false;
		let text = scope String();
		clipboard.GetText(text);
		let made = scope List<GraphId>();
		if (!mSource.PasteNodes(text, at, made))
			return false;
		Reselect(made);
		ReselectLinks(scope List<GraphId>());
		return true;
	}

	/// Copies and pastes the selected nodes beside them, selecting the copies (the clipboard kept).
	public bool DuplicateSelected()
	{
		if ((mSource == null) || mReadOnly || mSelection.IsEmpty)
			return false;
		let text = scope String();
		mSource.CopyNodes(mSelection, text);
		if (text.IsEmpty)
			return false;
		bool any = false;
		var corner = Float2(0.0f, 0.0f);
		for (let node in mSelection)
		{
			if (let info = mSource.GetNode(node))
			{
				corner = any ? Float2(Min(corner.X, info.Position.X), Min(corner.Y, info.Position.Y)) : info.Position;
				any = true;
			}
		}
		let made = scope List<GraphId>();
		let step = 2.0f * mGridSize;
		if (!mSource.PasteNodes(text, .(corner.X + step, corner.Y + step), made))
			return false;
		Reselect(made);
		return true;
	}

	/// Makes a node of `type` at `at` (the graph's), linked from pin `linkFrom` when it is not 0,
	/// selecting it; its id, 0 when it was not made.
	public GraphId AddNode(StringView type, Float2 at, GraphId linkFrom = 0)
	{
		var at;
		if ((mSource == null) || mReadOnly)
			return 0;
		if (mSnap)
			at = .(Round(at.X / mGridSize) * mGridSize, Round(at.Y / mGridSize) * mGridSize);
		let made = mSource.CreateNode(type, at, linkFrom);
		if (made != 0)
		{
			SelectOnly(made);
			ReselectLinks(scope List<GraphId>());
		}
		return made;
	}

	// === Frames ===

	/// Where a frame is, in its own space (as it is being resized, while it is); empty when there is
	/// no such frame.
	public Rect FrameRect(GraphId frame)
	{
		let info = scope GraphFrameInfo();
		if (!FindFrame(frame, info))
			return .();
		let graph = ((mDrag == .Resize) && (frame == mResizeFrame)) ? mResizeTo : Rect(info.Position.X, info.Position.Y, info.Size.X, info.Size.Y);
		let at = GraphToView(.(graph.X, graph.Y));
		return .(at.X, at.Y, graph.Width * mZoom, graph.Height * mZoom);
	}

	public GraphFrameWidget GetFrameWidget(GraphId frame) => mFrameWidgets.TryGetValue(frame, let widget) ? widget : null;

	public Span<GraphId> SelectedFrames => mSelectedFrames;

	public void SetSelectedFrames(Span<GraphId> frames)
	{
		let next = scope List<GraphId>();
		for (let frame in frames)
		{
			if (!Holds(next, frame))
				next.Add(frame);
		}
		ReselectFrames(next);
	}

	public bool IsFrameSelected(GraphId frame) => Holds(mSelectedFrames, frame);

	/// Makes a frame (with `comment`, a comment: a frame with a body) around the selected nodes, or at
	/// `at` (the graph's) with none selected, selecting it; its id, 0 when none was made.
	public GraphId AddFrame(Float2 at, bool comment = false)
	{
		if ((mSource == null) || mReadOnly)
			return 0;
		let frame = scope GraphFrameInfo();
		frame.Title.Set(comment ? "Comment" : "Frame");
		if (comment)
			frame.Body.Set("Write here");
		frame.Position = at;
		bool any = false;
		float left = 0.0f;
		float top = 0.0f;
		float right = 0.0f;
		float bottom = 0.0f;
		for (let node in mSelection) // around the selected nodes, room for its title above them
		{
			if (let info = mSource.GetNode(node))
			{
				let size = NodeSize(node);
				left = any ? Min(left, info.Position.X) : info.Position.X;
				top = any ? Min(top, info.Position.Y) : info.Position.Y;
				right = any ? Max(right, info.Position.X + size.X) : info.Position.X + size.X;
				bottom = any ? Max(bottom, info.Position.Y + size.Y) : info.Position.Y + size.Y;
				any = true;
			}
		}
		if (any)
		{
			let margin = mGridSize;
			let above = comment ? 3.0f * mGridSize : 2.0f * mGridSize;
			frame.Position = .(left - margin, top - above);
			frame.Size = .(right - left + 2.0f * margin, bottom - top + above + margin);
		}
		else if (mSnap)
			frame.Position = .(Round(at.X / mGridSize) * mGridSize, Round(at.Y / mGridSize) * mGridSize);
		let made = mSource.CreateFrame(frame);
		if (made != 0)
		{
			GraphId[1] only = .(made);
			SetSelectedFrames(only);
		}
		return made;
	}

	// === Menus ===

	/// Opens the node picker at `local` (its own space), the node chosen made there; with `fitting`, a
	/// pin, only the kinds a link from it reaches, the node linked to it. False when there is no kind
	/// to offer.
	public bool OpenNodePicker(Float2 local, GraphId fitting = 0)
	{
		if ((mSource == null) || mReadOnly)
			return false;
		let types = scope List<GraphNodeType>();
		defer { ClearAndDeleteItems!(types); }
		mSource.GetNodeTypes(fitting, types);
		if (types.IsEmpty)
			return false;
		if (mPicker == null)
			mPicker = new GraphNodePicker();
		ShareTextStyle(mPicker, false);
		mPicker.SetTypes(types);
		mPickAt = ViewToGraph(local);
		mPickFrom = fitting;
		mPicker.SetOnChosen(new (type) =>
			{
				let chosen = scope String(type.Type);
				if (let dispatcher = EventDispatcher)
					dispatcher.ClosePopup(mPicker);
				AddNode(chosen, mPickAt, mPickFrom);
			});
		let options = new PopupOptions();
		options.TakesFocus = true;
		options.FitContent = true;
		PopupAt(mPicker, local, options);
		return true;
	}

	public bool IsNodePickerOpen
	{
		get
		{
			let dispatcher = (mPicker != null) ? mPicker.EventDispatcher : null;
			return (dispatcher != null) && dispatcher.IsPopupOpen(mPicker);
		}
	}

	public GraphNodePicker NodePicker => mPicker;
	/// The context menu while it is open; null when it is not.
	public Sedulous.GUI.Menu Menu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Begins a node link from `node` that follows the pointer until a click ends it (a node's menu);
	/// false when the source takes none from it.
	public bool BeginNodeLink(GraphId node)
	{
		if ((mSource == null) || mReadOnly || (mDrag != .None) || (mSource.GetNode(node) == null))
			return false;
		mRelinking = 0;
		mRelinkFrom = 0;
		mTarget = 0;
		mTargetCheck.Clear();
		mLeftAnchor = false;
		mFits.Clear();
		let at = NodeRect(node);
		mLinkTo = mPointerInside ? mPointer : Float2(at.Right, at.Y);
		mPressAt = mLinkTo;
		if (!BeginNodeLinkFrom(node))
			return false;
		mSticky = true;
		mLinkMoved = true;
		RequestFocus();
		CapturePointer();
		return true;
	}

	// === Nodes ===

	/// A node's size as last measured (an estimate before it was).
	public Float2 NodeSize(GraphId node) => mSizes.TryGetValue(node, let size) ? size : EstimatedNodeSize();

	/// Where a node is, in its own space; empty when there is no such node.
	public Rect NodeRect(GraphId node)
	{
		let info = (mSource != null) ? mSource.GetNode(node) : null;
		if (info == null)
			return .();
		let at = GraphToView(info.Position);
		let size = NodeSize(node);
		return .(at.X, at.Y, size.X * mZoom, size.Y * mZoom);
	}

	/// The topmost node at `local` (its own space); 0 when none.
	public GraphId HitNode(Float2 local)
	{
		if (mSource == null)
			return 0;
		let order = scope List<GraphId>();
		PaintOrder(order);
		for (int i = order.Count - 1; i >= 0; i--)
		{
			if (NodeRect(order[i]).Contains(local))
				return order[i];
		}
		return 0;
	}

	/// Where pin `pin` is drawn, in its own space, as its node was last laid out; false when the view
	/// has not laid it out.
	public bool PinPoint(GraphId pin, out Float2 outPoint)
	{
		outPoint = .(0.0f, 0.0f);
		if (!mPins.TryGetValue(pin, let place) || (mSource == null))
			return false;
		let node = mSource.GetNode(place.Node);
		if (node == null)
			return false;
		let at = GraphToView(node.Position);
		outPoint = .(at.X + place.Offset.X * mZoom, at.Y + place.Offset.Y * mZoom);
		return true;
	}

	/// The pin of a node in view at `local` (its own space); 0 when none.
	public GraphId HitPin(Float2 local) => NearestPin(local, PinReach);

	/// The line link `link` is drawn along, in its own space (a curve's points, or an edge with its
	/// arrow at the end), into `outPoints` (emptied first); false when an end has no place yet.
	public bool LinkPoints(GraphLinkInfo link, List<Float2> outPoints)
	{
		outPoints.Clear();
		if (mSource == null)
			return false;
		if (link.Kind == .Nodes)
		{
			if ((mSource.GetNode(link.FromNode) == null) || (mSource.GetNode(link.ToNode) == null))
				return false;
			// Apart from its reverse; a second the same way further apart again.
			float gap = 0.0f;
			int before = 0;
			bool reverse = false;
			let links = scope List<GraphLinkInfo>();
			mSource.GetLinks(links);
			for (let at in links)
			{
				if ((at.Kind != .Nodes) || (link.FromNode == link.ToNode))
					continue;
				if ((at.FromNode == link.ToNode) && (at.ToNode == link.FromNode))
					reverse = true;
				if ((at.FromNode == link.FromNode) && (at.ToNode == link.ToNode) && (at.Id < link.Id))
					++before;
			}
			if (reverse || (before > 0))
				gap = cParallelGap * (1.0f + 2.0f * (float)before);
			EdgePoints(NodeRect(link.FromNode), NodeRect(link.ToNode), gap, outPoints);
			return true;
		}
		Float2 from = .Zero;
		Float2 to = .Zero;
		if (!PinPoint(link.FromPin, out from) || !PinPoint(link.ToPin, out to))
			return false;
		CurvePoints(from, to, outPoints);
		return true;
	}

	/// The topmost link at `local` (its own space); 0 when none.
	public GraphId HitLink(Float2 local)
	{
		if (mSource == null)
			return 0;
		let links = scope List<GraphLinkInfo>();
		mSource.GetLinks(links);
		let points = scope List<Float2>();
		for (int l = links.Count - 1; l >= 0; l--)
		{
			if (!LinkPoints(links[l], points))
				continue;
			for (int i = 1; i < points.Count; ++i)
			{
				let a = points[i - 1];
				let b = points[i];
				let vx = b.X - a.X;
				let vy = b.Y - a.Y;
				let lengthSq = vx * vx + vy * vy;
				var t = (lengthSq > 0.0f) ? ((local.X - a.X) * vx + (local.Y - a.Y) * vy) / lengthSq : 0.0f;
				t = Clamp(t, 0.0f, 1.0f);
				let dx = a.X + vx * t - local.X;
				let dy = a.Y + vy * t - local.Y;
				if (dx * dx + dy * dy <= cLinkReach * cLinkReach)
					return links[l].Id;
			}
		}
		return 0;
	}

	/// A node's widget while it is made (in view); null when it is not.
	public GraphNodeWidget GetNodeWidget(GraphId node) => mLive.TryGetValue(node, let widget) ? widget : null;

	/// How many node widgets are made now (those in view), and how many wait to be reused.
	public int MadeNodeCount => mLive.Count;
	public int PooledNodeCount => mPool.Count;

	// === The selection ===

	public Span<GraphId> SelectedNodes => mSelection;

	public void SetSelectedNodes(Span<GraphId> nodes)
	{
		let next = scope List<GraphId>();
		for (let node in nodes)
		{
			if ((mSource != null) && (mSource.GetNode(node) != null) && !Holds(next, node))
				next.Add(node);
		}
		Reselect(next);
	}

	public bool IsNodeSelected(GraphId node) => Holds(mSelection, node);

	public Span<GraphId> SelectedLinks => mSelectedLinks;

	public void SetSelectedLinks(Span<GraphId> links)
	{
		let next = scope List<GraphId>();
		for (let link in links)
		{
			if (!Holds(next, link))
				next.Add(link);
		}
		ReselectLinks(next);
	}

	public bool IsLinkSelected(GraphId link) => Holds(mSelectedLinks, link);

	// === Highlights (the application's: a state machine's active state) ===

	public void SetHighlightedNodes(Span<GraphId> nodes)
	{
		mHighlightedNodes.Clear();
		mHighlightedNodes.AddRange(nodes);
		RequestLayout();
	}

	public void SetHighlightedLinks(Span<GraphId> links)
	{
		mHighlightedLinks.Clear();
		mHighlightedLinks.AddRange(links);
		Invalidate();
	}

	public bool IsNodeHighlighted(GraphId node) => Holds(mHighlightedNodes, node);
	public bool IsLinkHighlighted(GraphId link) => Holds(mHighlightedLinks, link);

	/// Whether a link is being dragged, and what the source said of where it would end (Allowed false
	/// with no reason: it is over nothing).
	public bool IsLinking => mDrag == .Link;
	public GraphLinkCheck LinkCheck => mTargetCheck;

	/// Told each time the selection changes. OWNERSHIP of `callback` transfers.
	public void SetOnSelectionChanged(delegate void() callback)
	{
		delete mOnSelectionChanged;
		mOnSelectionChanged = callback;
	}

	/// A double click on a node: the application's (a subgraph opened). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnNodeDoubleClick(delegate void(GraphId node) callback)
	{
		delete mOnNodeDoubleClick;
		mOnNodeDoubleClick = callback;
	}

	public void OnGraphChanged()
	{
		if (mSource == null)
			return;
		let kept = scope List<GraphId>(); // an undo may take nodes away
		for (let node in mSelection)
		{
			if (mSource.GetNode(node) != null)
				kept.Add(node);
		}
		if (kept.Count != mSelection.Count)
			Reselect(kept);
		let links = scope List<GraphLinkInfo>();
		mSource.GetLinks(links);
		let keptLinks = scope List<GraphId>();
		for (let link in mSelectedLinks)
		{
			for (let at in links)
			{
				if (at.Id == link)
					keptLinks.Add(link);
			}
		}
		if (keptLinks.Count != mSelectedLinks.Count)
			ReselectLinks(keptLinks);
		let frames = scope List<GraphFrameInfo>();
		defer { ClearAndDeleteItems!(frames); }
		mSource.GetFrames(frames);
		let keptFrames = scope List<GraphId>();
		for (let frame in mSelectedFrames)
		{
			for (let at in frames)
			{
				if (at.Id == frame)
					keptFrames.Add(frame);
			}
		}
		if (keptFrames.Count != mSelectedFrames.Count)
			ReselectFrames(keptFrames);
		RequestLayout();
		Invalidate();
	}

	// === Making the nodes in view ===

	public override void OnLayout()
	{
		let live = new Dictionary<GraphId, GraphNodeWidget>();
		let sizes = new Dictionary<GraphId, Float2>();
		let order = scope List<GraphId>();
		// Made only to be measured.
		let unseen = scope List<GraphNodeWidget>();
		if (mSource != null)
			PaintOrder(order);
		let @box = ContentBounds;
		let reach = Rect(@box.X - cViewMargin, @box.Y - cViewMargin, @box.Width + 2.0f * cViewMargin, @box.Height + 2.0f * cViewMargin);
		int index = 0;
		// The frames first, under the nodes; few, each made while it is in the graph.
		{
			let frames = scope List<GraphFrameInfo>();
			defer { ClearAndDeleteItems!(frames); }
			if (mSource != null)
				mSource.GetFrames(frames);
			let made = new Dictionary<GraphId, GraphFrameWidget>();
			for (let frame in frames)
			{
				GraphFrameWidget widget;
				if (mFrameWidgets.GetAndRemove(frame.Id) case .Ok(let had))
					widget = had.value;
				else
				{
					widget = new GraphFrameWidget();
					widget.SetOnCommitted(new (id, text, body) => { EditFrameText(id, text, body); });
					AddChild(widget);
				}
				widget.Show(frame);
				widget.IsSelected = Holds(mSelectedFrames, frame.Id);
				let at = FrameRect(frame.Id);
				widget.Arrange(.(at.X, at.Y, at.Width / mZoom, at.Height / mZoom));
				if ((widget.Scale.X != mZoom) || (widget.Scale.Y != mZoom))
					widget.Scale = .(mZoom, mZoom);
				if ((index < ChildCount) && (GetChildAt(index) != widget))
					SetChildIndex(widget, index);
				++index;
				made[frame.Id] = widget;
			}
			for (let gone in mFrameWidgets.Values)
			{
				RemoveChild(gone);
				gone.ReleaseRef();
			}
			delete mFrameWidgets;
			mFrameWidgets = made;
		}
		for (let id in order)
		{
			let info = mSource.GetNode(id);
			Float2 knownSize;
			let known = mSizes.TryGetValue(id, out knownSize);
			let at = GraphToView(info.Position);
			let guess = known ? knownSize : EstimatedNodeSize();
			let inView = reach.Intersects(.(at.X, at.Y, guess.X * mZoom, guess.Y * mZoom));
			if (!inView && known)
			{
				sizes[id] = knownSize;
				continue;
			}
			GraphNodeWidget widget;
			if (mLive.GetAndRemove(id) case .Ok(let had))
				widget = had.value;
			else
			{
				widget = TakeWidget();
				if (widget.Parent != this)
					AddChild(widget);
			}
			widget.Show(info);
			widget.IsSelected = Holds(mSelection, id);
			widget.IsHighlighted = Holds(mHighlightedNodes, id);
			let size = widget.Measure(LayoutConstraints());
			sizes[id] = size;
			widget.Arrange(.(at.X, at.Y, size.X, size.Y));
			for (int i = 0; i < widget.PinRowCount; ++i) // the pins' places, kept for the links
			{
				let row = widget.PinRowAt(i);
				Float2 offset;
				if (widget.PinPoint(row.PinId, out offset))
					mPins[row.PinId] = PinPlace(id, offset, row.PinDirection, row.TypeColor);
			}
			if ((widget.Scale.X != mZoom) || (widget.Scale.Y != mZoom))
				widget.Scale = .(mZoom, mZoom);
			if ((index < ChildCount) && (GetChildAt(index) != widget))
				SetChildIndex(widget, index); // drawn in the paint order
			++index;
			if (!reach.Intersects(.(at.X, at.Y, size.X * mZoom, size.Y * mZoom)))
				unseen.Add(widget);
			live[id] = widget;
		}
		// Those that left the view (or the graph) go back to the pool, as do those made only to be
		// measured.
		for (let gone in mLive.Values)
		{
			RemoveChild(gone);
			mPool.Add(gone);
		}
		for (let widget in unseen)
		{
			if (live.GetAndRemove(widget.NodeId) case .Ok(let held))
			{
				RemoveChild(held.value);
				mPool.Add(held.value);
			}
		}
		delete mLive;
		mLive = live;
		delete mSizes;
		mSizes = sizes;
		let pins = new Dictionary<GraphId, PinPlace>(); // those of nodes gone go
		for (let entry in mPins)
		{
			if (mSizes.ContainsKey(entry.value.Node))
				pins[entry.key] = entry.value;
		}
		delete mPins;
		mPins = pins;
		ShowLinkStates();
		if (mFitting)
			Frame(false); // every node measured now; laid out again where that moves them
	}

	// === Gestures ===

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((mSource == null) || ((mDrag != .None) && !((mDrag == .Link) && mSticky)))
			return;
		mFitting = false; // the canvas is the user's now
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		if (e.Button == .Middle)
		{
			e.Handled = true;
			mDrag = .Pan;
			mPressAt = local;
			mPanFrom = mPan;
			CapturePointer();
			return;
		}
		if ((mDrag == .Link) && mSticky) // a link begun from a menu: a click ends it
		{
			e.Handled = true;
			LinkTo(local);
			EndLink(e.Button == .Left);
			return;
		}
		if (e.Button != .Left)
			return;
		e.Handled = true;
		RequestFocus();
		mPressAt = local;
		mBoxTo = local;
		mAdditive = (e.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
		if (!mReadOnly && BeginLink(local))
		{
			CapturePointer();
			return;
		}
		let hit = HitNode(local);
		if ((hit != 0) && (e.ClickCount == 2) && !mAdditive)
		{
			SelectOnly(hit);
			if (mOnNodeDoubleClick != null)
				mOnNodeDoubleClick(hit);
			return;
		}
		let link = (hit == 0) ? HitLink(local) : 0;
		uint8 edges = 0;
		bool header = false;
		let frame = ((hit == 0) && (link == 0)) ? HitFrame(local, out edges, out header) : 0;
		if (!mAdditive)
			ReselectLinks(scope List<GraphId>());
		mPressed = 0;
		mPressedFrame = 0;
		if (hit != 0)
		{
			mPressed = hit;
			if (!mAdditive && !IsNodeSelected(hit))
				ReselectFrames(scope List<GraphId>());
			if (mAdditive)
				Toggle(hit);
			else if (!IsNodeSelected(hit))
				SelectOnly(hit);
			mDrag = IsNodeSelected(hit) ? .Pending : .None;
		}
		else if ((frame != 0) && (edges != 0) && !mReadOnly)
		{
			if (!mAdditive)
			{
				SelectOnly(0);
				GraphId[1] only = .(frame);
				SetSelectedFrames(only);
			}
			let info = scope GraphFrameInfo();
			FindFrame(frame, info);
			mResizeFrame = frame;
			mResizeEdges = edges;
			mResizeFrom = .(info.Position.X, info.Position.Y, info.Size.X, info.Size.Y);
			mResizeTo = mResizeFrom;
			mDrag = .Resize;
		}
		else if ((frame != 0) && header)
		{
			mPressedFrame = frame;
			if (mAdditive)
			{
				let next = scope List<GraphId>();
				next.AddRange(mSelectedFrames);
				if (Holds(next, frame))
				{
					for (int i = 0; i < next.Count; ++i)
					{
						if (next[i] == frame)
						{
							next.RemoveAt(i);
							break;
						}
					}
				}
				else
					next.Add(frame);
				ReselectFrames(next);
			}
			else if (!IsFrameSelected(frame))
			{
				SelectOnly(0);
				GraphId[1] only = .(frame);
				SetSelectedFrames(only);
			}
			mDrag = IsFrameSelected(frame) ? .Pending : .None;
		}
		else if (link != 0)
		{
			if (!mAdditive)
				SelectOnly(0);
			let next = scope List<GraphId>();
			next.AddRange(mSelectedLinks);
			if (Holds(next, link))
			{
				for (int i = 0; i < next.Count; ++i)
				{
					if (next[i] == link)
					{
						next.RemoveAt(i);
						break;
					}
				}
			}
			else
				next.Add(link);
			ReselectLinks(next);
			mDrag = .None;
		}
		else
		{
			if (!mAdditive)
			{
				SelectOnly(0);
				ReselectFrames(scope List<GraphId>());
			}
			mBoxBase.Clear();
			mBoxBase.AddRange(mSelection);
			mFrameBoxBase.Clear();
			mFrameBoxBase.AddRange(mSelectedFrames);
			mDrag = .Box;
		}
		if ((link != 0) && !mAdditive)
			ReselectFrames(scope List<GraphId>());
		if (mDrag != .None)
			CapturePointer();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let local = ConvertToNodeSpace(e.Position);
		mPointer = local;
		mPointerInside = true;
		if ((mDrag == .None) || (mSource == null))
			return;
		switch (mDrag)
		{
		case .Pending:
			if ((Abs(local.X - mPressAt.X) < cDragThreshold) && (Abs(local.Y - mPressAt.Y) < cDragThreshold))
				return;
			if (mReadOnly)
				return;
			mDrag = .Nodes;
			BeginMove();
			MoveTo(local);
		case .Nodes:
			MoveTo(local);
		case .Box:
			mBoxTo = local;
			let area = Rect(Min(mPressAt.X, local.X), Min(mPressAt.Y, local.Y), Abs(local.X - mPressAt.X), Abs(local.Y - mPressAt.Y));
			let next = scope List<GraphId>();
			next.AddRange(mBoxBase);
			let ids = scope List<GraphId>();
			mSource.GetNodes(ids);
			for (let id in ids)
			{
				if (!Holds(next, id) && area.Intersects(NodeRect(id)))
					next.Add(id);
			}
			Reselect(next);
			let frames = scope List<GraphId>(); // a frame wholly inside
			frames.AddRange(mFrameBoxBase);
			let all = scope List<GraphFrameInfo>();
			defer { ClearAndDeleteItems!(all); }
			mSource.GetFrames(all);
			for (let frame in all)
			{
				if (!Holds(frames, frame.Id) && area.Contains(FrameRect(frame.Id)))
					frames.Add(frame.Id);
			}
			ReselectFrames(frames);
			Invalidate();
		case .Link:
			LinkTo(local);
		case .Resize:
			ResizeTo(local);
		case .Pan:
			Pan = .(mPanFrom.X - (local.X - mPressAt.X) / mZoom, mPanFrom.Y - (local.Y - mPressAt.Y) / mZoom);
		default:
		}
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mDrag == .Pan)
		{
			if (e.Button == .Middle)
			{
				mDrag = .None;
				ReleasePointer();
			}
			return;
		}
		if (e.Button != .Left)
			return;
		if (mDrag == .Link)
		{
			if (mSticky)
				return; // the press that began it from a menu, or the one that ended it
			LinkTo(ConvertToNodeSpace(e.Position));
			EndLink(true);
			return;
		}
		if ((mDrag == .Pending) && !mAdditive) // a click on one of several selected selects it alone
		{
			SelectOnly(mPressed);
			let frames = scope List<GraphId>();
			if (mPressedFrame != 0)
				frames.Add(mPressedFrame);
			ReselectFrames(frames);
		}
		EndDrag(true);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		if (mDrag == .Link)
			EndLink(false);
		else
			EndDrag(false);
	}

	protected override void OnPointerCaptureLost()
	{
		if (mDrag == .Link)
			EndLink(false);
		else
			EndDrag(false);
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		mPointerInside = false;
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if (e.Target != this)
			return; // a frame's title being edited types its own keys
		let key = (KeyCode)e.KeyCode;
		if ((key == .Escape) && ((mDrag == .Nodes) || (mDrag == .Resize)))
		{
			e.Handled = true;
			EndDrag(false);
		}
		else if ((key == .Escape) && (mDrag == .Link))
		{
			e.Handled = true;
			EndLink(false);
		}
		else if ((key == .Escape) && (e.Modifiers == 0) && (mDrag == .None) &&
			(!mSelection.IsEmpty || !mSelectedLinks.IsEmpty || !mSelectedFrames.IsEmpty))
		{
			e.Handled = true;
			Reselect(scope List<GraphId>());
			ReselectLinks(scope List<GraphId>());
			ReselectFrames(scope List<GraphId>());
		}
		else if ((e.Modifiers == 0) && ((key == .Delete) || (key == .Backspace)) && (mDrag == .None))
			e.Handled = DeleteSelected();
		else if ((e.Modifiers == KeyModCtrl) && (key == .C) && (mDrag == .None))
			e.Handled = CopySelected();
		else if ((e.Modifiers == KeyModCtrl) && (key == .V) && (mDrag == .None))
		{
			let @box = ContentBounds;
			let at = mPointerInside ? mPointer : Float2(@box.X + @box.Width * 0.5f, @box.Y + @box.Height * 0.5f);
			e.Handled = PasteAt(ViewToGraph(at));
		}
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		let steps = (e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X;
		if (steps == 0.0f)
			return;
		e.Handled = true;
		SetZoom(mZoom * Pow(1.15f, steps), ConvertToNodeSpace(e.Position));
	}

	protected override void OnContextMenu(MouseEvent e)
	{
		if ((mSource == null) || (mDrag != .None))
			return;
		e.Handled = true;
		OpenMenu(ConvertToNodeSpace(e.Position), e.Position);
	}

	public override Sedulous.GUI.Cursor CursorNow
	{
		get
		{
			if (mDrag == .Pan)
				return .Grabbing;
			uint8 edges = (mDrag == .Resize) ? mResizeEdges : 0;
			if ((mDrag == .None) && mPointerInside && !mReadOnly && (HitNode(mPointer) == 0) && (HitLink(mPointer) == 0))
				HitFrame(mPointer, out edges, let header);
			let horizontal = (edges & (cEdgeLeft | cEdgeRight)) != 0;
			let vertical = (edges & (cEdgeTop | cEdgeBottom)) != 0;
			if (horizontal && vertical)
			{
				let falling = ((edges & cEdgeLeft) != 0) ? ((edges & cEdgeTop) != 0) : ((edges & cEdgeBottom) != 0);
				return falling ? .NwseResize : .NeswResize;
			}
			if (horizontal)
				return .EwResize;
			if (vertical)
				return .NsResize;
			return base.CursorNow;
		}
	}

	protected override void OnTextStyleChange()
	{
		mText.Font = Font;
		mText.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
		mText.Color = TextColor;
		mText.SetAlignment(.Start, .Top);
	}

	// === Drawing ===

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let @box = ContentBounds;
		ctx.PushClip(@box);
		// The grid: a line each cell while they stand apart, and a stronger one each eighth.
		let minor = PartColor("grid", .(1.0f, 1.0f, 1.0f, 0.04f));
		let major = PartColor("grid-major", .(1.0f, 1.0f, 1.0f, 0.09f));
		let cell = mGridSize * mZoom;
		let fine = cell >= 6.0f;
		let step = fine ? mGridSize : mGridSize * 8.0f;
		let first = ViewToGraph(.(@box.X, @box.Y));
		let last = ViewToGraph(.(@box.Right, @box.Bottom));
		for (int64 i = (int64)Floor(first.X / step); (float)i * step <= last.X; ++i)
		{
			let strong = !fine || (i % 8 == 0);
			let x = GraphToView(.((float)i * step, 0.0f)).X;
			ctx.VG.FillRect(.(Floor(x), @box.Y, 1.0f, @box.Height), strong ? major : minor);
		}
		for (int64 i = (int64)Floor(first.Y / step); (float)i * step <= last.Y; ++i)
		{
			let strong = !fine || (i % 8 == 0);
			let y = GraphToView(.(0.0f, (float)i * step)).Y;
			ctx.VG.FillRect(.(@box.X, Floor(y), @box.Width, 1.0f), strong ? major : minor);
		}
		// The frames' boxes, under the links: tinted, their title bands more so.
		if (mSource != null)
		{
			let frames = scope List<GraphFrameInfo>();
			defer { ClearAndDeleteItems!(frames); }
			mSource.GetFrames(frames);
			let round = CornerRadii(Clamp(4.0f * mZoom, 1.0f, 6.0f));
			for (let frame in frames)
			{
				let r = FrameRect(frame.Id);
				if (!@box.Intersects(r))
					continue;
				ctx.VG.FillRoundedRect(r.ToRectangle(), round, frame.Tint);
				let widget = GetFrameWidget(frame.Id);
				let band = Min(r.Height, ((widget != null) ? widget.HeaderHeight : GraphFrameWidget.cHeaderMin) * mZoom);
				var strong = frame.Tint;
				strong.A = Min(1.0f, strong.A * 1.8f);
				var top = round;
				top.BottomLeft = 0.0f;
				top.BottomRight = 0.0f;
				ctx.VG.FillRoundedRect(.(r.X, r.Y, r.Width, band), top, strong);
			}
		}
		// The links, under the nodes, each culled to the view; one being rewired is drawn as the drag.
		if (mSource != null)
		{
			let nodeLink = PartColor("node-link", .(0.8f, 0.82f, 0.88f, 1.0f));
			let selected = PartColor("link-selected", .(1.0f, 1.0f, 1.0f, 1.0f));
			let highlight = PartColor("link-highlight", .(1.0f, 0.65f, 0.2f, 1.0f));
			let width = Clamp(2.0f * mZoom, 1.0f, 3.0f);
			let links = scope List<GraphLinkInfo>();
			mSource.GetLinks(links);
			let points = scope List<Float2>();
			let replacing = (mDrag == .Link) && mTargetCheck.Allowed;
			for (let link in links)
			{
				if (((mDrag == .Link) && mLinkMoved && (link.Id == mRelinking)) || !LinkPoints(link, points))
					continue;
				var left = points[0].X;
				var right = left;
				var top = points[0].Y;
				var bottom = top;
				for (let p in points)
				{
					left = Min(left, p.X);
					right = Max(right, p.X);
					top = Min(top, p.Y);
					bottom = Max(bottom, p.Y);
				}
				if (!@box.Intersects(.(left - 8.0f, top - 8.0f, right - left + 16.0f, bottom - top + 16.0f)))
					continue;
				var color = nodeLink;
				if (link.Kind == .Pins)
				{
					if (mPins.TryGetValue(link.FromPin, let place))
						color = place.TypeColor;
				}
				var stroke = width;
				if (Holds(mHighlightedLinks, link.Id))
				{
					color = highlight;
					stroke = width + 1.5f;
				}
				if (Holds(mSelectedLinks, link.Id))
				{
					color = selected;
					stroke = width + 1.0f;
				}
				if (replacing && Holds(mTargetCheck.Replaces, link.Id))
					color.A *= 0.3f; // about to be replaced
				StrokeLine(ctx, points, color, stroke, link.Kind == .Nodes);
			}
		}
		ctx.PopClip();
	}

	protected override void OnDrawAbove(DrawContext ctx)
	{
		if ((mDrag == .Link) && mLinkMoved && (mSource != null))
		{
			ctx.PushClip(ContentBounds);
			let part = GetPartStyle("link-drag");
			var color = part.HasBackground ? part.Box.BackgroundColor : Color(1.0f, 1.0f, 1.0f, 0.85f);
			color.A *= part.Opacity;
			let width = Clamp(2.0f * mZoom, 1.0f, 3.0f);
			let points = scope List<Float2>();
			if (mLinkKind == .Nodes)
			{
				let from = NodeRect(mAnchorNode);
				let to = ((mTarget != 0) && mTargetCheck.Allowed) ? NodeRect(mTarget) : Rect(mLinkTo.X, mLinkTo.Y, 0.0f, 0.0f);
				EdgePoints(from, to, 0.0f, points);
				StrokeLine(ctx, points, color, width, true);
			}
			else
			{
				Float2 anchor;
				var carried = mLinkTo;
				if ((mTarget != 0) && mTargetCheck.Allowed)
					PinPoint(mTarget, out carried); // it snaps to the pin it would end at
				if (PinPoint(mAnchorPin, out anchor))
				{
					if (mAnchorOutput)
						CurvePoints(anchor, carried, points);
					else
						CurvePoints(carried, anchor, points);
					if (mPins.TryGetValue(mAnchorPin, let place))
						color = .(place.TypeColor.R, place.TypeColor.G, place.TypeColor.B, color.A);
					StrokeLine(ctx, points, color, width, false);
				}
			}
			// Why not, beside the pointer.
			if ((mTarget != 0) && !mTargetCheck.Allowed && !mTargetCheck.Reason.IsEmpty && mText.HasFont)
			{
				mText.SetString(mTargetCheck.Reason);
				let size = mText.Measure();
				let note = Rect(mLinkTo.X + 14.0f, mLinkTo.Y + 10.0f, size.X + 12.0f, size.Y + 6.0f);
				let tip = GetPartStyle("link-refused");
				var back = tip.HasBackground ? tip.Box.BackgroundColor : Color(0.45f, 0.12f, 0.12f, 0.95f);
				back.A *= tip.Opacity;
				ctx.VG.FillRoundedRect(note.ToRectangle(), 4.0f, back);
				mText.Draw(ctx, Float2(note.X + 6.0f, note.Y + 3.0f));
			}
			ctx.PopClip();
			return;
		}
		if (mDrag != .Box)
			return;
		let part = GetPartStyle("selection-box");
		var fill = part.HasBackground ? part.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 0.2f);
		fill.A *= part.Opacity;
		let area = Rect(Min(mPressAt.X, mBoxTo.X), Min(mPressAt.Y, mBoxTo.Y), Abs(mBoxTo.X - mPressAt.X), Abs(mBoxTo.Y - mPressAt.Y));
		ctx.PushClip(ContentBounds);
		ctx.VG.FillRect(area.ToRectangle(), fill);
		ctx.PopClip();
	}

	private Color PartColor(StringView name, Color fallback)
	{
		let part = GetPartStyle(name);
		var color = part.HasBackground ? part.Box.BackgroundColor : fallback;
		color.A *= part.Opacity;
		return color;
	}

	private float PinReach => Max(cPinReach, (GraphNodeWidget.cPinRadius + 3.0f) * mZoom);

	// The pin of a made node nearest `local` within `reach`; 0 when none.
	private GraphId NearestPin(Float2 local, float reach)
	{
		GraphId best = 0;
		var bestDistance = reach * reach;
		for (let entry in mPins)
		{
			if (!mLive.ContainsKey(entry.value.Node))
				continue;
			Float2 at;
			if (!PinPoint(entry.key, out at))
				continue;
			let dx = at.X - local.X;
			let dy = at.Y - local.Y;
			if (dx * dx + dy * dy <= bestDistance)
			{
				bestDistance = dx * dx + dy * dy;
				best = entry.key;
			}
		}
		return best;
	}

	// The node whose edge `local` is just outside of (none when it is inside a node).
	private GraphId HitNodeEdge(Float2 local)
	{
		if (mSource == null)
			return 0;
		let order = scope List<GraphId>();
		PaintOrder(order);
		for (int i = order.Count - 1; i >= 0; i--)
		{
			let r = NodeRect(order[i]);
			if (r.Contains(local))
				return 0;
			if (Rect(r.X - cEdgeReach, r.Y - cEdgeReach, r.Width + 2.0f * cEdgeReach, r.Height + 2.0f * cEdgeReach).Contains(local))
				return order[i];
		}
		return 0;
	}

	// The link a drag would make ending at `target` (a pin, or a node for a node link).
	private GraphLinkInfo Candidate(GraphId target)
	{
		var link = GraphLinkInfo();
		link.Kind = mLinkKind;
		if (mLinkKind == .Nodes)
		{
			link.FromNode = mAnchorNode;
			link.ToNode = target;
			return link;
		}
		let targetNode = mPins.TryGetValue(target, let place) ? place.Node : 0;
		if (mAnchorOutput)
		{
			link.FromNode = mAnchorNode;
			link.FromPin = mAnchorPin;
			link.ToNode = targetNode;
			link.ToPin = target;
		}
		else
		{
			link.FromNode = targetNode;
			link.FromPin = target;
			link.ToNode = mAnchorNode;
			link.ToPin = mAnchorPin;
		}
		return link;
	}

	// A copy of frame `frame`, into `outInfo`; false when there is none.
	private bool FindFrame(GraphId frame, GraphFrameInfo outInfo)
	{
		if ((mSource == null) || (frame == 0))
			return false;
		let frames = scope List<GraphFrameInfo>();
		defer { ClearAndDeleteItems!(frames); }
		mSource.GetFrames(frames);
		for (let at in frames)
		{
			if (at.Id == frame)
			{
				outInfo.Set(at);
				return true;
			}
		}
		return false;
	}

	// The topmost frame at `local`: on which of its edges, and whether on its title band.
	private GraphId HitFrame(Float2 local, out uint8 edges, out bool header)
	{
		edges = 0;
		header = false;
		if (mSource == null)
			return 0;
		let frames = scope List<GraphFrameInfo>();
		defer { ClearAndDeleteItems!(frames); }
		mSource.GetFrames(frames);
		for (int i = frames.Count - 1; i >= 0; i--)
		{
			let r = FrameRect(frames[i].Id);
			if (!r.Contains(local))
				continue;
			if (local.X < r.X + cFrameEdge)
				edges |= cEdgeLeft;
			if (local.X > r.Right - cFrameEdge)
				edges |= cEdgeRight;
			if (local.Y < r.Y + cFrameEdge)
				edges |= cEdgeTop;
			if (local.Y > r.Bottom - cFrameEdge)
				edges |= cEdgeBottom;
			let widget = GetFrameWidget(frames[i].Id);
			let band = ((widget != null) ? widget.HeaderHeight : GraphFrameWidget.cHeaderMin) * mZoom;
			header = local.Y < r.Y + band;
			return frames[i].Id;
		}
		return 0;
	}

	private void ReselectFrames(List<GraphId> next)
	{
		var same = next.Count == mSelectedFrames.Count;
		for (int i = 0; same && (i < next.Count); ++i)
			same = Holds(mSelectedFrames, next[i]);
		if (next != mSelectedFrames)
		{
			mSelectedFrames.Clear();
			mSelectedFrames.AddRange(next);
		}
		if (same)
			return;
		RequestLayout();
		Invalidate();
		if (mOnSelectionChanged != null)
			mOnSelectionChanged();
	}

	private void EditFrameText(GraphId frame, StringView text, bool body)
	{
		let info = scope GraphFrameInfo();
		if (mReadOnly || !FindFrame(frame, info))
			return;
		if (body)
			info.Body.Set(text);
		else
			info.Title.Set(text);
		mSource.EditFrame(info);
	}

	private void ResizeTo(Float2 local)
	{
		let dx = (local.X - mPressAt.X) / mZoom;
		let dy = (local.Y - mPressAt.Y) / mZoom;
		float Snap(float v) => mSnap ? Round(v / mGridSize) * mGridSize : v;
		let from = mResizeFrom;
		var left = from.X;
		var top = from.Y;
		var right = from.Right;
		var bottom = from.Bottom;
		if ((mResizeEdges & cEdgeLeft) != 0)
			left = Min(Snap(from.X + dx), right - cFrameMinWidth);
		if ((mResizeEdges & cEdgeRight) != 0)
			right = Max(Snap(from.Right + dx), left + cFrameMinWidth);
		if ((mResizeEdges & cEdgeTop) != 0)
			top = Min(Snap(from.Y + dy), bottom - cFrameMinHeight);
		if ((mResizeEdges & cEdgeBottom) != 0)
			bottom = Max(Snap(from.Bottom + dy), top + cFrameMinHeight);
		mResizeTo = .(left, top, right - left, bottom - top);
		RequestLayout();
		Invalidate();
	}

	private void ReselectLinks(List<GraphId> next)
	{
		var same = next.Count == mSelectedLinks.Count;
		for (int i = 0; same && (i < next.Count); ++i)
			same = Holds(mSelectedLinks, next[i]);
		if (next != mSelectedLinks)
		{
			mSelectedLinks.Clear();
			mSelectedLinks.AddRange(next);
		}
		if (same)
			return;
		Invalidate();
		if (mOnSelectionChanged != null)
			mOnSelectionChanged();
	}

	private bool BeginLink(Float2 local)
	{
		mRelinking = 0;
		mRelinkFrom = 0;
		mTarget = 0;
		mTargetCheck.Clear();
		mLinkMoved = false;
		mLeftAnchor = false;
		mLinkTo = local;
		mFits.Clear();
		var begin = GraphLinkInfo();
		let pin = HitPin(local);
		if (pin != 0)
		{
			let place = mPins[pin];
			mLinkKind = .Pins;
			// An input with a link: its end is taken (the last made), to rewire it or let it go.
			if (place.Direction == .Input)
			{
				let links = scope List<GraphLinkInfo>();
				mSource.GetLinks(links);
				for (let link in links)
				{
					if ((link.Kind == .Pins) && (link.ToPin == pin))
					{
						mRelinking = link.Id;
						mAnchorNode = link.FromNode;
						mAnchorPin = link.FromPin;
					}
				}
			}
			if (mRelinking != 0)
			{
				mRelinkFrom = pin;
				mAnchorOutput = true;
			}
			else
			{
				mAnchorNode = place.Node;
				mAnchorPin = pin;
				mAnchorOutput = place.Direction == .Output;
				begin.FromNode = place.Node;
				begin.FromPin = pin;
				let check = scope GraphLinkCheck();
				mSource.CheckLink(begin, check);
				if (!check.Allowed)
					return false;
			}
			// Each pin asked once: where this link may end.
			let check = scope GraphLinkCheck();
			for (let key in mPins.Keys)
			{
				if (key == mAnchorPin)
					continue;
				var fits = key == mRelinkFrom;
				if (!fits)
				{
					mSource.CheckLink(Candidate(key), check);
					fits = check.Allowed;
				}
				mFits[key] = fits;
			}
		}
		else
		{
			let node = HitNodeEdge(local);
			if (node == 0)
				return false;
			mPressAt = local;
			return BeginNodeLinkFrom(node);
		}
		mDrag = .Link;
		mPressAt = local;
		ShowLinkStates();
		Invalidate();
		return true;
	}

	private bool BeginNodeLinkFrom(GraphId node)
	{
		var begin = GraphLinkInfo();
		begin.Kind = .Nodes;
		begin.FromNode = node;
		let check = scope GraphLinkCheck();
		mSource.CheckLink(begin, check);
		if (!check.Allowed)
			return false;
		mLinkKind = .Nodes;
		mAnchorNode = node;
		mAnchorPin = 0;
		mAnchorOutput = true;
		let ids = scope List<GraphId>();
		mSource.GetNodes(ids);
		for (let id in ids)
		{
			mSource.CheckLink(Candidate(id), check);
			mFits[id] = check.Allowed;
		}
		mDrag = .Link;
		ShowLinkStates();
		Invalidate();
		return true;
	}

	private void OpenMenu(Float2 local, Float2 screen)
	{
		let top = RootNode;
		if (top == null)
			return;
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		let node = HitNode(local);
		let link = (node == 0) ? HitLink(local) : 0;
		uint8 edges = 0;
		bool header = false;
		let frame = ((node == 0) && (link == 0)) ? HitFrame(local, out edges, out header) : 0;
		if ((frame != 0) && header)
		{
			if (mReadOnly)
				return;
			if (!IsFrameSelected(frame))
			{
				SelectOnly(0);
				ReselectLinks(scope List<GraphId>());
				GraphId[1] only = .(frame);
				SetSelectedFrames(only);
			}
			mMenu.AddItem("Rename", new () =>
				{
					if (let widget = GetFrameWidget(frame))
						widget.TitleLabel.BeginEdit();
				});
			mMenu.AddItem("Edit comment", new () =>
				{
					if (let widget = GetFrameWidget(frame))
						widget.EditBody();
				});
			mMenu.AddSeparator();
			mMenu.AddItem("Delete", new () => { DeleteSelected(); });
		}
		else if (node != 0)
		{
			if (!IsNodeSelected(node))
			{
				SelectOnly(node);
				ReselectLinks(scope List<GraphId>());
			}
			mMenu.AddItem("Copy", new () => { CopySelected(); });
			if (!mReadOnly)
			{
				mMenu.AddItem("Duplicate", new () => { DuplicateSelected(); });
				bool deletable = false;
				for (let at in mSelection)
				{
					if (let info = mSource.GetNode(at))
						deletable = deletable || info.Deletable;
				}
				mMenu.AddItem("Delete", new () => { DeleteSelected(); }).Enabled = deletable;
				var begin = GraphLinkInfo();
				begin.Kind = .Nodes;
				begin.FromNode = node;
				let check = scope GraphLinkCheck();
				mSource.CheckLink(begin, check);
				if (check.Allowed)
					mMenu.AddItem("Add transition", new () => { BeginNodeLink(node); });
			}
			mMenu.AddSeparator();
			mMenu.AddItem("Frame selection", new () => { FrameSelection(); });
		}
		else if (link != 0)
		{
			if (mReadOnly)
				return;
			if (!IsLinkSelected(link))
			{
				SelectOnly(0);
				GraphId[1] only = .(link);
				SetSelectedLinks(only);
			}
			mMenu.AddItem("Delete", new () => { DeleteSelected(); });
		}
		else
		{
			if (!mReadOnly)
			{
				let types = scope List<GraphNodeType>();
				defer { ClearAndDeleteItems!(types); }
				mSource.GetNodeTypes(0, types);
				mMenu.AddItem("Add node\u{2026}", new () => { OpenNodePicker(local); }).Enabled = !types.IsEmpty;
				let dispatcher = EventDispatcher;
				let clipboard = (dispatcher != null) ? dispatcher.Clipboard : null;
				let at = ViewToGraph(local);
				mMenu.AddItem("Paste", new () => { PasteAt(at); }).Enabled = (clipboard != null) && clipboard.HasText;
				mMenu.AddItem("Add frame", new () => { AddFrame(at); });
				mMenu.AddItem("Add comment", new () => { AddFrame(at, true); });
				mMenu.AddSeparator();
			}
			mMenu.AddItem("Frame all", new () => { FrameAll(); });
			mMenu.AddItem("Frame selection", new () => { FrameSelection(); }).Enabled = !mSelection.IsEmpty;
		}
		mMenu.Open(this, top.ConvertToNodeSpace(screen));
	}

	// OWNERSHIP of `options` transfers.
	private void PopupAt(Node popup, Float2 local, PopupOptions options)
	{
		let dispatcher = EventDispatcher;
		let top = RootNode;
		if ((dispatcher == null) || (top == null))
		{
			delete options;
			return;
		}
		let at = top.ConvertToNodeSpace(ConvertToWorldSpace(local));
		options.AnchorRect = .(at.X, at.Y, 0.0f, 0.0f);
		options.HasAnchorRect = true;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 0.0f;
		options.Placement.Shrink = true;
		dispatcher.OpenPopup(this, popup, options);
	}

	private void LinkTo(Float2 local)
	{
		mLinkTo = local;
		if (!mLinkMoved && (Abs(local.X - mPressAt.X) < cDragThreshold) && (Abs(local.Y - mPressAt.Y) < cDragThreshold))
			return;
		mLinkMoved = true;
		GraphId target = 0;
		if (mLinkKind == .Pins)
		{
			target = NearestPin(local, Max(PinReach, 14.0f));
			if (target == mAnchorPin)
				target = 0;
		}
		else
		{
			target = HitNode(local);
			if ((target != mAnchorNode) && (HitNodeEdge(local) != mAnchorNode))
				mLeftAnchor = true;
			if ((target == mAnchorNode) && !mLeftAnchor) // to itself only once it has left and come back
				target = 0;
		}
		if (target != mTarget)
		{
			mTarget = target;
			mTargetCheck.Clear();
			if ((target != 0) && (target == mRelinkFrom))
				mTargetCheck.Allowed = true; // back where it came from: nothing changes
			else if (target != 0)
				mSource.CheckLink(Candidate(target), mTargetCheck);
			ShowLinkStates();
		}
		Invalidate();
	}

	private void EndLink(bool commit)
	{
		if (mDrag != .Link)
			return;
		mDrag = .None;
		mSticky = false;
		let target = mTarget;
		let allowed = mTargetCheck.Allowed;
		mTarget = 0;
		mTargetCheck.Clear();
		mFits.Clear();
		ShowLinkStates();
		ReleasePointer();
		Invalidate();
		if (!commit || !mLinkMoved || (mSource == null))
			return;
		if (target == 0)
		{
			if (mRelinking != 0) // an end dropped on nothing lets the link go
			{
				GraphId[1] gone = .(mRelinking);
				mSource.Disconnect(gone);
			}
			else if (mLinkKind == .Pins) // a new one: the kinds of node it may reach
				OpenNodePicker(mLinkTo, mAnchorPin);
			return;
		}
		if (!allowed || (target == mRelinkFrom))
			return;
		if (mRelinking != 0)
			mSource.Relink(mRelinking, Candidate(target));
		else
			mSource.Connect(Candidate(target));
	}

	private void ShowLinkStates()
	{
		let linking = mDrag == .Link;
		GraphLinkState StateOf(GraphId id, bool kind)
		{
			if (!linking || !kind)
				return .None;
			if (!mFits.TryGetValue(id, let fits))
				return .None;
			if ((id == mTarget) && mTargetCheck.Allowed)
				return .Target;
			return fits ? .Fits : .Refused;
		}
		for (let entry in mLive)
		{
			let widget = entry.value;
			widget.LinkState = StateOf(entry.key, mLinkKind == .Nodes);
			for (int i = 0; i < widget.PinRowCount; ++i)
			{
				let row = widget.PinRowAt(i);
				row.LinkState = StateOf(row.PinId, mLinkKind == .Pins);
			}
		}
	}

	// A curve from an output's point to an input's, leaving and arriving along the reading direction.
	private void CurvePoints(Float2 from, Float2 to, List<Float2> outPoints)
	{
		let reach = Max(30.0f * mZoom, Abs(to.X - from.X) * 0.5f);
		let c0 = Float2(from.X + reach, from.Y); // out of an output's right, into an input's left
		let c1 = Float2(to.X - reach, to.Y);
		let steps = 32;
		for (int32 i = 0; i <= steps; ++i)
		{
			let t = (float)i / (float)steps;
			let u = 1.0f - t;
			let a = u * u * u;
			let b = 3.0f * u * u * t;
			let c = 3.0f * u * t * t;
			let d = t * t * t;
			outPoints.Add(.(a * from.X + b * c0.X + c * c1.X + d * to.X, a * from.Y + b * c0.Y + c * c1.Y + d * to.Y));
		}
	}

	// A straight edge between two nodes' borders (`gap` to its right), or a loop on one node.
	private void EdgePoints(Rect from, Rect to, float gap, List<Float2> outPoints)
	{
		let a = Float2(from.X + from.Width * 0.5f, from.Y + from.Height * 0.5f);
		let b = Float2(to.X + to.Width * 0.5f, to.Y + to.Height * 0.5f);
		var dx = b.X - a.X;
		var dy = b.Y - a.Y;
		let length = Sqrt(dx * dx + dy * dy);
		if (length < 1e-3f) // a node to itself: a loop over its top right corner
		{
			let side = from.Right - 24.0f * mZoom;
			let lift = 36.0f * mZoom;
			let spread = 14.0f * mZoom;
			let start = Float2(side - spread, from.Y);
			let end = Float2(side + spread, from.Y);
			let c0 = Float2(start.X - spread, from.Y - lift);
			let c1 = Float2(end.X + spread, from.Y - lift);
			let steps = 24;
			for (int32 i = 0; i <= steps; ++i)
			{
				let t = (float)i / (float)steps;
				let u = 1.0f - t;
				let p = u * u * u;
				let q = 3.0f * u * u * t;
				let r = 3.0f * u * t * t;
				let w = t * t * t;
				outPoints.Add(.(p * start.X + q * c0.X + r * c1.X + w * end.X, p * start.Y + q * c0.Y + r * c1.Y + w * end.Y));
			}
			return;
		}
		dx /= length;
		dy /= length;
		let side = Float2(-dy * gap, dx * gap); // to the edge's right, so its reverse lies apart
		// Where the line from the middle leaves each box.
		float ExitAt(Rect @box, float x, float y)
		{
			let hx = @box.Width * 0.5f;
			let hy = @box.Height * 0.5f;
			let tx = (Abs(x) > 1e-6f) ? hx / Abs(x) : 1e30f;
			let ty = (Abs(y) > 1e-6f) ? hy / Abs(y) : 1e30f;
			return Min(tx, ty);
		}
		let leave = ExitAt(from, dx, dy);
		let arrive = ExitAt(to, dx, dy);
		outPoints.Add(.(a.X + dx * leave + side.X, a.Y + dy * leave + side.Y));
		outPoints.Add(.(b.X - dx * arrive + side.X, b.Y - dy * arrive + side.Y));
	}

	private void StrokeLine(DrawContext ctx, Span<Float2> points, Color color, float width, bool arrow)
	{
		if (points.Length < 2)
			return;
		let line = scope PathBuilder();
		line.MoveTo(points[0].X, points[0].Y);
		for (int i = 1; i < points.Length; ++i)
			line.LineTo(points[i].X, points[i].Y);
		let linePath = line.ToPath();
		ctx.VG.StrokePath(linePath, color, StrokeStyle(width));
		delete linePath;
		if (!arrow)
			return;
		// Its head at the end, along the last stretch.
		let tip = points[points.Length - 1];
		let back = points[points.Length - 2];
		var dx = tip.X - back.X;
		var dy = tip.Y - back.Y;
		let length = Sqrt(dx * dx + dy * dy);
		if (length < 1e-4f)
			return;
		dx /= length;
		dy /= length;
		let size = Clamp(9.0f * mZoom, 6.0f, 14.0f);
		let head = scope PathBuilder();
		head.MoveTo(tip.X, tip.Y);
		head.LineTo(tip.X - dx * size - dy * size * 0.55f, tip.Y - dy * size + dx * size * 0.55f);
		head.LineTo(tip.X - dx * size + dy * size * 0.55f, tip.Y - dy * size - dx * size * 0.55f);
		head.Close();
		let headPath = head.ToPath();
		ctx.VG.FillPath(headPath, color);
		delete headPath;
	}

	private static bool Holds(List<GraphId> ids, GraphId id)
	{
		for (let at in ids)
		{
			if (at == id)
				return true;
		}
		return false;
	}

	private void Reselect(List<GraphId> next)
	{
		var same = next.Count == mSelection.Count;
		for (int i = 0; same && (i < next.Count); ++i)
			same = Holds(mSelection, next[i]);
		if (next != mSelection)
		{
			mSelection.Clear();
			mSelection.AddRange(next);
		}
		if (same)
			return;
		RequestLayout(); // selected nodes stand on top
		Invalidate();
		if (mOnSelectionChanged != null)
			mOnSelectionChanged();
	}

	private void Toggle(GraphId node)
	{
		let next = scope List<GraphId>();
		for (let at in mSelection)
		{
			if (at != node)
				next.Add(at);
		}
		if (next.Count == mSelection.Count)
			next.Add(node);
		Reselect(next);
	}

	private void SelectOnly(GraphId node)
	{
		let next = scope List<GraphId>();
		if (node != 0)
			next.Add(node);
		Reselect(next);
	}

	// The source's nodes in the order they are drawn: the selected last, over the rest.
	private void PaintOrder(List<GraphId> outOrder)
	{
		outOrder.Clear();
		let ids = scope List<GraphId>();
		mSource.GetNodes(ids);
		for (let id in ids)
		{
			if (!Holds(mSelection, id))
				outOrder.Add(id);
		}
		for (let id in ids)
		{
			if (Holds(mSelection, id))
				outOrder.Add(id);
		}
	}

	private void CapturePointer()
	{
		if (let dispatcher = EventDispatcher)
			dispatcher.CapturePointer(this);
	}

	private void ReleasePointer()
	{
		if (let dispatcher = EventDispatcher)
			dispatcher.ReleasePointer(this);
	}

	private void BeginMove()
	{
		let pressed = mSource.GetNode(mPressed);
		mPressedFrom = (pressed != null) ? pressed.Position : Float2(0.0f, 0.0f);
		let pressedFrame = scope GraphFrameInfo();
		if ((pressed == null) && FindFrame(mPressedFrame, pressedFrame))
			mPressedFrom = pressedFrame.Position;
		// What moves: the selected nodes and frames, and what lies wholly inside the selected frames.
		mMoveNodes.Clear();
		mMoveNodes.AddRange(mSelection);
		mMoveFrames.Clear();
		mMoveFrames.AddRange(mSelectedFrames);
		let frames = scope List<GraphFrameInfo>();
		defer { ClearAndDeleteItems!(frames); }
		mSource.GetFrames(frames);
		let nodes = scope List<GraphId>();
		mSource.GetNodes(nodes);
		for (let frame in frames)
		{
			if (!Holds(mSelectedFrames, frame.Id))
				continue;
			let inside = Rect(frame.Position.X, frame.Position.Y, frame.Size.X, frame.Size.Y);
			for (let node in nodes)
			{
				let info = mSource.GetNode(node);
				let size = NodeSize(node);
				if (!Holds(mMoveNodes, node) && inside.Contains(Rect(info.Position.X, info.Position.Y, size.X, size.Y)))
					mMoveNodes.Add(node);
			}
			for (let other in frames)
			{
				if (!Holds(mMoveFrames, other.Id) && inside.Contains(Rect(other.Position.X, other.Position.Y, other.Size.X, other.Size.Y)))
					mMoveFrames.Add(other.Id);
			}
		}
		mSource.BeginMove();
	}

	private void MoveTo(Float2 local)
	{
		var delta = Float2((local.X - mPressAt.X) / mZoom, (local.Y - mPressAt.Y) / mZoom);
		if (mSnap) // the pressed node lands on the grid; the rest keep their places to it
		{
			let x = Round((mPressedFrom.X + delta.X) / mGridSize) * mGridSize;
			let y = Round((mPressedFrom.Y + delta.Y) / mGridSize) * mGridSize;
			delta = .(x - mPressedFrom.X, y - mPressedFrom.Y);
		}
		mSource.PreviewMove(mMoveNodes, mMoveFrames, delta);
	}

	private void EndDrag(bool commit)
	{
		let drag = mDrag;
		mDrag = .None;
		if (drag == .None)
			return;
		ReleasePointer();
		if (drag == .Box)
			Invalidate();
		if (drag == .Resize)
		{
			RequestLayout();
			let info = scope GraphFrameInfo();
			let changed = (mResizeTo.X != mResizeFrom.X) || (mResizeTo.Y != mResizeFrom.Y) || (mResizeTo.Width != mResizeFrom.Width) ||
				(mResizeTo.Height != mResizeFrom.Height);
			if (commit && changed && FindFrame(mResizeFrame, info))
			{
				info.Position = .(mResizeTo.X, mResizeTo.Y);
				info.Size = .(mResizeTo.Width, mResizeTo.Height);
				mSource.EditFrame(info);
			}
			return;
		}
		if ((drag != .Nodes) || (mSource == null))
			return;
		if (commit)
			mSource.CommitMove();
		else
			mSource.CancelMove();
	}

	private void Frame(bool selectionOnly)
	{
		if (mSource == null)
			return;
		let ids = scope List<GraphId>();
		if (selectionOnly)
			ids.AddRange(mSelection);
		else
			mSource.GetNodes(ids);
		bool any = false;
		float left = 0.0f;
		float top = 0.0f;
		float right = 0.0f;
		float bottom = 0.0f;
		for (let id in ids)
		{
			let info = mSource.GetNode(id);
			if (info == null)
				continue;
			let size = NodeSize(id);
			let l = info.Position.X;
			let t = info.Position.Y;
			let r = l + size.X;
			let b = t + size.Y;
			left = any ? Min(left, l) : l;
			top = any ? Min(top, t) : t;
			right = any ? Max(right, r) : r;
			bottom = any ? Max(bottom, b) : b;
			any = true;
		}
		if (!any)
			return;
		let @box = ContentBounds;
		if ((@box.Width <= 0.0f) || (@box.Height <= 0.0f))
			return; // not laid out yet: fitting does it once it is
		let margin = 32.0f;
		let width = right - left + 2.0f * margin;
		let height = bottom - top + 2.0f * margin;
		let zoom = Clamp(Min(1.0f, Min(@box.Width / width, @box.Height / height)), mZoomMin, mZoomMax);
		let middle = Float2((left + right) * 0.5f, (top + bottom) * 0.5f);
		let pan = Float2(middle.X - @box.Width * 0.5f / zoom, middle.Y - @box.Height * 0.5f / zoom);
		if ((Abs(zoom - mZoom) < 1e-5f) && (Abs(pan.X - mPan.X) < 0.01f) && (Abs(pan.Y - mPan.Y) < 0.01f))
			return; // where it is already: nothing to lay out again
		mZoom = zoom;
		mPan = pan;
		RequestLayout();
	}

	// A widget for a node: one from the pool, else a new one; the caller takes the reference.
	private GraphNodeWidget TakeWidget()
	{
		if (!mPool.IsEmpty)
			return mPool.PopBack();
		return new GraphNodeWidget();
	}
}

/// What GraphView.bf keeps out of the public surface.
internal static class GraphViewDetail
{
	/// Lets go of each widget's reference and deletes the table.
	public static void ReleaseAll<T>(Dictionary<GraphId, T> widgets) where T : Node
	{
		if (widgets == null)
			return;
		for (let widget in widgets.Values)
			widget.ReleaseRef();
		delete widgets;
	}
}
