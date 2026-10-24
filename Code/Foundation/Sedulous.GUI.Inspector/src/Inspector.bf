using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Inspector;

// Inspector: the GUI's inspector, built from the GUI's own widgets in a root of its own on the
// inspected GUI's context, which a host shows as a pane beside the root it inspects. The Elements
// tab lists the tree (live: rebuilt when its shape changes) over the selected node's details: what
// it is, its states with toggles that force them, its box, its styles grouped by rule with sheet
// and line (inherited ones under their ancestor), its reflected properties edited live as markup
// sets them, its bindings, commands and listeners, and how it measures. Picking (the host routes
// the pointer over the inspected root here while it is on) outlines what is under the pointer, the
// wheel walking out and in through what holds it (gpui's), and a click selects it. The Frames tab
// draws the frame costs the host records. The host draws DrawOverTarget over the inspected root:
// the box model of the node under the pointer and of the one selected.

/// How the inspector writes: its font (a family the host's font service knows) and size. A class:
/// it owns its text.
class InspectorOptions
{
	public String FontFamily = new .("Roboto") ~ delete _;
	public float FontSize = 13.0f;

	public void Set(InspectorOptions other)
	{
		if (other === this)
			return;
		FontFamily.Set(other.FontFamily);
		FontSize = other.FontSize;
	}
}

/// The last few seconds of frame costs, drawn as stacked bars (style, layout, draw).
class FramesGraph : UIWidget
{
	public const int cFrames = 240;

	private struct Sample
	{
		public float Style;
		public float Layout;
		public float Draw;

		public this(float style, float layout, float draw)
		{
			Style = style;
			Layout = layout;
			Draw = draw;
		}
	}

	private List<Sample> mSamples = new .() ~ delete _;
	private int mNext = 0;

	public this()
	{
		Tag = "framesgraph";
	}

	public void Record(Sedulous.GUI.FrameStats stats)
	{
		let s = Sample((float)stats.StyleMs, (float)stats.LayoutMs, (float)stats.DrawMs);
		if (mSamples.Count < cFrames)
			mSamples.Add(s);
		else
		{
			mSamples[mNext] = s;
			mNext = (mNext + 1) % cFrames;
		}
		Invalidate();
	}

	public int SampleCount => mSamples.Count;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let g = ctx.VG;
		let local = localBounds;
		g.FillRect(local.ToRectangle(), Color(0.08f, 0.09f, 0.11f, 1.0f));
		// A line at 16.7 ms (a 60 Hz frame); the bars scale to the larger of it and the worst.
		float worst = 16.7f;
		for (let s in mSamples)
			worst = Math.Max(worst, s.Style + s.Layout + s.Draw);
		let scale = local.Height / worst;
		let budget = local.Bottom - 16.7f * scale;
		g.FillRect(Rectangle(local.X, budget, local.Width, 1.0f), Color(1.0f, 1.0f, 1.0f, 0.25f));
		let w = local.Width / (float)cFrames;
		Color[3] colors = .(Color(0.95f, 0.65f, 0.25f, 1.0f), Color(0.35f, 0.8f, 0.45f, 1.0f), Color(0.4f, 0.6f, 1.0f, 1.0f));
		for (int i = 0; i < mSamples.Count; i++)
		{
			let s = mSamples[(mSamples.Count < cFrames) ? i : (mNext + i) % cFrames];
			let x = local.X + (float)i * w;
			float y = local.Bottom;
			float[3] ms = .(s.Style, s.Layout, s.Draw);
			for (int k = 0; k < 3; k++)
			{
				let h = ms[k] * scale;
				g.FillRect(Rectangle(x, y - h, Math.Max(w - 0.5f, 0.5f), h), colors[k]);
				y -= h;
			}
		}
	}
}

class Inspector
{
	// One line of the styles section: a declaration, or what code or an ancestor set.
	private class StyleLine
	{
		public String Property = new .() ~ delete _;
		public String Value = new .() ~ delete _;
		public bool Won = true;
		public bool Important = false;
		public bool Editable = false;
		public bool Inline = false;
		public StyleRule Rule = null;
	}

	// The styles section's lines under one header (a rule, the inline style, code, an ancestor).
	private class StyleGroup
	{
		public String Header = new .() ~ delete _;
		public List<StyleLine> Lines = new .() ~ DeleteContainerAndItems!(_);
	}

	// The states the details' toggles force for the style pass.
	private static (String Name, uint32 State)[6] sForceable = .(
		(":hover", Node.StateHover), (":active", Node.StateActive),
		(":focus", Node.StateFocus), (":focus-visible", Node.StateFocusVisible),
		(":checked", Node.StateChecked), (":disabled", Node.StateDisabled));

	private InspectorOptions mOptions = new .() ~ delete _;
	private CachedFont mFont = null;
	private SceneRoot mRoot = null; // one reference held
	private StyleManager mStyles = new .() ~ delete _;
	private SceneRoot mTarget = null; // not owned: the host's
	private StyleManager mTargetStyles = null; // edits its rules (the styles' fields)
	private bool mDetailsStale = false; // an edit wants the details shown again
	private StringListModel mModel = null; // owned; the views go before it, in the destructor
	private Panel mShell = null; // owned by the root, as the rest
	private CheckBox mPick = null;
	private Sedulous.GUI.Label mQueryCount = null;
	private ListView mTree = null;
	private Panel mDetails = null;
	private FramesGraph mFrames = null;
	private List<TreeEntry> mEntries = new .() ~ DeleteContainerAndItems!(_); // the rows: the tree less its folded branches
	private List<Node> mCollapsed = new .() ~ delete _; // the folded branches (by identity; forgotten once gone)
	private uint64 mSignature = 0;
	private uint64 mRefreshes = 0;
	private Node.ElementRef mSelected = .(); // a reference to its table held
	private Node mSelectedRaw = null; // when the node has no element table to hold it weakly
	private Node mDetailsFor = null; // compared, never followed
	private bool mSelecting = false;
	private bool mPicking = false;
	private List<Node> mHoverPath = new .() ~ delete _; // the node under the pointer, then what holds it, outward
	private int mHoverLevel = 0;

	/// An inspector in a root of its own on `context` (it takes a reference of its own: the caller
	/// keeps its), writing in `fontService`'s font (null: none) as `options` say (copied; null: the
	/// defaults).
	public this(GUIContext context, IFontService fontService, InspectorOptions options = null)
	{
		if (options != null)
			mOptions.Set(options);
		mRoot = new SceneRoot(context);
		mFont = (fontService != null) ? fontService.GetFont(mOptions.FontFamily, mOptions.FontSize) : null;
		mRoot.DebugFont = mFont;
		mStyles.FontService = fontService;
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, "theme", theme);
		mStyles.UserAgentSheet = theme;
		let css = Sheet(.. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, "inspector", sheet);
		mStyles.StyleSheet = sheet;
		Build();
	}

	public ~this()
	{
		// The views hold the model: they go before it.
		if (mRoot != null)
		{
			mRoot.RemoveAllChildren();
			mRoot.ReleaseRef();
		}
		delete mModel;
		mSelected.Table?.ReleaseRef();
	}

	/// What it inspects: a root and the style manager that styles it (for the styles' origins).
	public void Inspect(SceneRoot target, StyleManager targetStyles)
	{
		mTarget = target;
		mTargetStyles = targetStyles;
		mSignature = 0;
		Select(null);
	}

	public SceneRoot Target => mTarget;
	public SceneRoot Root => mRoot;
	/// Its root with a reference added, for a host that draws it as a pane of a window: the caller
	/// releases it.
	public SceneRoot GetRootRef()
	{
		mRoot.AddRef();
		return mRoot;
	}
	public StyleManager Styles => mStyles;

	/// Once a frame, before its root's style pass: the tree when its shape changed, the details
	/// now and then (values move).
	public void Refresh()
	{
		if (mTarget == null)
			return;
		mRefreshes++;
		if (mRefreshes % 10 == 1) // the shape's signature walks the tree: a few times a second
		{
			let signature = Signature(mTarget);
			if (signature != mSignature)
			{
				mSignature = signature;
				RebuildTree();
			}
		}
		// The details again when the selection changed, and now and then for values that moved,
		// but not under a field being edited there.
		let selected = Selected;
		if ((selected != mDetailsFor) || mDetailsStale || ((mRefreshes % 60 == 0) && !EditingDetails()))
			RebuildDetails();
	}

	// === The tree's branches ===

	/// Folds `node`'s branch away in the tree (its descendants leave the list) or opens it.
	public void SetCollapsed(Node node, bool collapsed)
	{
		if ((node == null) || (IsCollapsed(node) == collapsed))
			return;
		if (collapsed)
			mCollapsed.Add(node);
		else
		{
			for (int i = 0; i < mCollapsed.Count; i++)
			{
				if (mCollapsed[i] == node)
				{
					mCollapsed.RemoveAt(i);
					break;
				}
			}
		}
		if (mTarget != null)
			RebuildTree();
	}

	public bool IsCollapsed(Node node)
	{
		for (let n in mCollapsed)
		{
			if (n == node)
				return true;
		}
		return false;
	}

	// === Selection ===

	public void Select(Node node)
	{
		// What holds it opens, so its row shows.
		bool opened = false;
		for (var n = (node != null) ? node.Parent : null; n != null; n = n.Parent)
		{
			for (int i = 0; i < mCollapsed.Count; i++)
			{
				if (mCollapsed[i] == n)
				{
					mCollapsed.RemoveAt(i);
					opened = true;
					break;
				}
			}
		}
		if (opened && (mTarget != null))
			RebuildTree();
		let held = (node != null) ? node.TakeElementRef() : Node.ElementRef();
		held.Table?.AddRef();
		mSelected.Table?.ReleaseRef();
		mSelected = held;
		mSelectedRaw = node;
		if ((node != null) && (mTree != null))
		{
			for (int i = 0; i < mEntries.Count; i++)
			{
				if (mEntries[i].Target == node)
				{
					mSelecting = true;
					mTree.SelectedItem = (int32)i;
					mTree.ScrollToItem((int32)i);
					mSelecting = false;
				}
			}
		}
		RebuildDetails();
	}

	/// The node selected while it lives (null once it is gone).
	public Node Selected
	{
		get
		{
			if (mSelected.Table != null)
				return mSelected.Table.Resolve(mSelected.Slot, mSelected.Generation);
			return ((mSelectedRaw != null) && (mTarget != null) && Contains(mTarget, mSelectedRaw)) ? mSelectedRaw : null;
		}
	}

	// === Picking ===

	public bool Picking
	{
		get => mPicking;
		set
		{
			mPicking = value;
			mHoverPath.Clear();
			if (mPick != null)
				mPick.Checked = value;
			if (mTarget != null)
				mTarget.Invalidate();
		}
	}

	/// The pointer at `world` (the inspected root's world) while picking: what is under it.
	public void PickHover(Float2 world)
	{
		if (!mPicking || (mTarget == null))
			return;
		let path = scope List<Node>();
		for (var n = mTarget.OverFind(world); (n != null) && (n != mTarget); n = n.Parent)
			path.Add(n);
		if ((path.Count == mHoverPath.Count) && (path.IsEmpty || (path[0] == mHoverPath[0])))
			return;
		mHoverPath.Clear();
		mHoverPath.AddRange(path);
		mHoverLevel = 0;
		mTarget.Invalidate();
	}

	/// The wheel while picking: out to what holds the node (up) or back in (down).
	public void PickWheel(float delta)
	{
		if (!mPicking || mHoverPath.IsEmpty)
			return;
		let level = (int32)mHoverLevel + ((delta > 0.0f) ? 1 : -1);
		mHoverLevel = (int)Math.Clamp(level, 0, (int32)mHoverPath.Count - 1);
		mTarget.Invalidate();
	}

	/// A click while picking: selects what is outlined and stops picking.
	public void PickClick()
	{
		if (!mPicking)
			return;
		let picked = Hovered;
		Picking = false;
		if (picked != null)
			Select(picked);
	}

	/// Selects the first widget `selector` matches in the inspected root (the query field's
	/// Enter); how many it matched.
	public int SelectQuery(StringView selector)
	{
		if (mTarget == null)
			return 0;
		let found = scope List<Node>();
		Query(mTarget, selector, found);
		mQueryCount.Text = scope String()..AppendF("{} found", found.Count);
		if (!found.IsEmpty)
			Select(found[0]);
		return found.Count;
	}

	/// What picking outlines (null when nothing, or when it is gone since the pointer moved).
	public Node Hovered
	{
		get
		{
			if (!mPicking || (mHoverLevel >= mHoverPath.Count) || (mTarget == null))
				return null;
			let node = mHoverPath[mHoverLevel];
			return Contains(mTarget, node) ? node : null;
		}
	}

	/// The frames tab's next bar (the inspected root's last frame).
	public void RecordFrame(FrameStats stats)
	{
		if (mFrames != null)
			mFrames.Record(stats);
	}

	/// Over the inspected root, drawn in its world with the canvas untransformed: the box model
	/// (margin orange, padding green, content blue) of what picking outlines, else of the node
	/// selected, with its name.
	public void DrawOverTarget(DrawContext ctx)
	{
		var node = Hovered;
		if (node == null)
			node = Selected;
		if ((node == null) || !node.IsTreeVisible)
			return;
		let g = ctx.VG;
		let world = node.WorldTransform;
		let m = node.Margin;
		let border = node.LocalBounds;
		let margin = Rect(-m.Left, -m.Top, border.Width + m.TotalHorizontal, border.Height + m.TotalVertical);
		let content = node.ContentBounds;
		g.FillRect(world.TransformRect(margin).ToRectangle(), Color(1.0f, 0.6f, 0.2f, 0.25f));
		g.FillRect(world.TransformRect(border).ToRectangle(), Color(0.3f, 0.85f, 0.4f, 0.25f));
		g.FillRect(world.TransformRect(content).ToRectangle(), Color(0.35f, 0.55f, 1.0f, 0.3f));
		let @box = world.TransformRect(border);
		g.StrokeRect(@box.ToRectangle(), Color(0.35f, 0.55f, 1.0f, 0.9f), 1.0f);
		if (mFont != null)
		{
			let text = scope String();
			Sedulous.GUI.Inspector.Label(node, text);
			text.AppendF("  {}x{}", (int32)node.Size.X, (int32)node.Size.Y);
			let width = 7.0f * (float)text.Length + 10.0f;
			let y = (@box.Y >= 20.0f) ? @box.Y - 20.0f : @box.Bottom;
			g.FillRect(Rectangle(@box.X, y, width, 20.0f), Color(0.05f, 0.06f, 0.08f, 0.9f));
			g.DrawText(text, mFont, Rectangle(@box.X + 5.0f, y, width - 5.0f, 20.0f), .Left, .Middle, Color(0.85f, 0.9f, 1.0f, 1.0f));
		}
	}

	/// The details' rows (for tests): each label's and field's text, in order, added to
	/// `outLines` (the caller owns what is added).
	public void DetailsText(List<String> outLines)
	{
		if (mDetails != null)
			DetailsTextOf(mDetails, outLines);
	}

	public int TreeRowCount => mEntries.Count;

	private static void DetailsTextOf(Node node, List<String> outLines)
	{
		if (let label = node as Sedulous.GUI.Label)
			outLines.Add(new String(label.Text));
		else if (let field = node as TextField)
			outLines.Add(new String(field.Text));
		for (int i = 0; i < node.ChildCount; i++)
			DetailsTextOf(node.GetChildAt(i), outLines);
	}

	private void Sheet(String outText)
	{
		let size = (int32)mOptions.FontSize;
		outText.AppendF(
			".inspector, .inspector label, .inspector button, .inspector textfield, .inspector checkbox, .inspector tab" +
			" {{ font-family: {}; font-size: {}px; }}\n",
			mOptions.FontFamily, size);
		outText.Append(
			".inspector { width: 100%; height: 100%; flex-direction: column; background-color: #181b21; padding: 6px; gap: 6px; color: #d6dbe3; }\n" +
			".ibar { flex-direction: row; align-items: center; gap: 6px; height: 28px; flex-shrink: 0; }\n" +
			".itabs > tabbar { flex-shrink: 0; }\n" +
			".ibar textfield { flex-grow: 1; height: 26px; }\n" +
			".ibar button { height: 26px; padding-left: 10px; padding-right: 10px; }\n" +
			".itabs { flex-grow: 1; min-height: 0px; }\n" +
			".ielements { flex-direction: column; gap: 6px; flex-grow: 1; min-height: 0px; }\n" +
			".itree { flex-grow: 2; min-height: 160px; }\n" +
			".idetails { flex-grow: 3; min-height: 160px; overflow-x: hidden; }\n" +
			".idetailbody { flex-direction: column; gap: 2px; padding: 4px; }\n" +
			".ihead { color: #ffffff; font-size: 15px; }\n" +
			".isection { color: #7fb2ff; margin-top: 8px; }\n" +
			".irule { color: #e6c07b; margin-top: 4px; }\n" +
			".iline { color: #c8ced8; white-space: normal; }\n" +
			".idim { color: #7d8594; }\n" +
			".iover { color: #6b7280; }\n" +
			".iforce { flex-direction: row; flex-wrap: wrap; gap: 8px; }\n" +
			".iprop { flex-direction: row; align-items: center; gap: 6px; height: 24px; }\n" +
			".iprop label { width: 140px; color: #c8ced8; }\n" +
			".iprop textfield { flex-grow: 1; height: 22px; }\n" +
			"framesgraph { flex-grow: 1; min-height: 120px; }\n");
	}

	// A new `T` (of the class `cls` when given), the last child of `parent`, which holds it.
	private T Add<T>(Node parent, StringView cls = default) where T : Node, new
	{
		let node = new T();
		if (cls.Length != 0)
		{
			if (let w = (Object)node as UIWidget)
				w.AddClass(cls);
		}
		parent.AddChild(node);
		node.ReleaseRef(); // the parent's reference keeps it
		return node;
	}

	private Sedulous.GUI.Label Text(Node parent, StringView cls, StringView text)
	{
		let label = Add<Sedulous.GUI.Label>(parent, cls);
		label.Text = text;
		return label;
	}

	private void Build()
	{
		let shell = Add<Panel>(mRoot, "inspector");
		mShell = shell;
		let bar = Add<Panel>(shell, "ibar");
		let pick = Add<CheckBox>(bar);
		pick.Text = "Pick";
		mPick = pick;
		pick.SetOnToggled(new (on) =>
			{
				if (on != mPicking)
					Picking = on;
			});
		let query = Add<TextField>(bar);
		query.Placeholder = "selector, Enter to select the first match";
		query.SetOnSubmit(new (text) => { SelectQuery(text); });
		mQueryCount = this.Text(bar, "idim", default);

		let tabs = Add<TabView>(shell, "itabs");
		let elements = tabs.AddPage("Elements");
		elements.Closable = false;
		elements.AddClass("ielements");
		mModel = new StringListModel();
		let tree = Add<ListView>(elements, "itree");
		tree.Font = mFont;
		tree.RowHeight = mOptions.FontSize + 7.0f;
		tree.Model = mModel;
		tree.SetOnSelectionChanged(new (index) =>
			{
				if (mSelecting || !index.IsValid || (index.Row >= mEntries.Count))
					return;
				let node = mEntries[index.Row].Target;
				if ((mTarget != null) && Contains(mTarget, node)) // the tree may have changed since
					Select(node);
			});
		// A row activated (a double click, Enter) folds its branch or opens it.
		tree.SetOnActivated(new (index) =>
			{
				if (!index.IsValid || (index.Row >= mEntries.Count))
					return;
				let node = mEntries[index.Row].Target;
				if ((mTarget != null) && Contains(mTarget, node) && (node.ChildCount != 0))
					SetCollapsed(node, !IsCollapsed(node));
			});
		mTree = tree;
		let details = Add<ScrollView>(elements, "idetails");
		mDetails = Add<Panel>(details, "idetailbody");

		let frames = tabs.AddPage("Frames");
		frames.Closable = false;
		frames.AddClass("ielements");
		this.Text(frames, "idim", "Style (orange), layout (green) and draw (blue) of each frame drawn; the line is 16.7 ms.");
		mFrames = Add<FramesGraph>(frames);
	}

	// The focus is in the details (a property being edited).
	private bool EditingDetails()
	{
		for (var n = mRoot.EventDispatcher.FocusNode; n != null; n = n.Parent)
		{
			if (n == mDetails)
				return true;
		}
		return false;
	}

	// Whether `node` is in the tree under `root` (a raw reference checked before it is used).
	private static bool Contains(Node root, Node node)
	{
		if (root == node)
			return true;
		for (int i = 0; i < root.ChildCount; i++)
		{
			if (Contains(root.GetChildAt(i), node))
				return true;
		}
		return false;
	}

	// The tree's shape: each node and its children's arrangement, hashed in order.
	private static uint64 Signature(Node root)
	{
		uint64 hash = FnvOffsetBasis;
		SignatureOf(root, ref hash);
		return hash;
	}

	private static void SignatureOf(Node node, ref uint64 hash)
	{
		void* address = Internal.UnsafeCastToPtr(node);
		uint32 generation = node.ChildrenGeneration;
		hash = HashBytes(&address, sizeof(void*), hash);
		hash = HashBytes(&generation, sizeof(uint32), hash);
		for (int i = 0; i < node.ChildCount; i++)
			SignatureOf(node.GetChildAt(i), ref hash);
	}

	private void RebuildTree()
	{
		// The whole tree, less what folded branches hold; a fold of a node gone is forgotten.
		let all = scope List<TreeEntry>();
		defer { ClearAndDeleteItems!(all); }
		Tree(mTarget, all);
		for (int i = mCollapsed.Count - 1; i >= 0; i--)
		{
			bool present = false;
			for (let e in all)
				present = present || (e.Target == mCollapsed[i]);
			if (!present)
				mCollapsed.RemoveAt(i);
		}
		ClearAndDeleteItems!(mEntries);
		uint32 foldedBelow = uint32.MaxValue; // the depth of the fold being skipped, none when MaxValue
		for (let e in all)
		{
			if ((foldedBelow != uint32.MaxValue) && (e.Depth > foldedBelow))
				continue;
			foldedBelow = IsCollapsed(e.Target) ? e.Depth : uint32.MaxValue;
			let kept = new TreeEntry();
			kept.Set(e);
			mEntries.Add(kept);
		}
		let rows = scope List<String>();
		defer { ClearAndDeleteItems!(rows); }
		let views = scope List<StringView>();
		for (let e in mEntries)
		{
			let row = new String();
			// Indented by no-break spaces: a row's white space collapses, theirs does not.
			for (uint32 d = 0; d < e.Depth; d++)
				row.Append("\u{00A0}\u{00A0}\u{00A0}");
			// A branch says whether it is open (-) or folded (+); a leaf leaves the room.
			row.Append((e.Target.ChildCount == 0) ? "\u{00A0}\u{00A0}" : IsCollapsed(e.Target) ? "+\u{00A0}" : "-\u{00A0}");
			row.Append(e.Label);
			if (!e.Shown)
				row.Append("  (hidden)");
			rows.Add(row);
			views.Add(row);
		}
		mSelecting = true;
		mModel.SetItems(views);
		mSelecting = false;
		if (let selected = Selected)
		{
			for (int i = 0; i < mEntries.Count; i++)
			{
				if (mEntries[i].Target == selected)
				{
					mSelecting = true;
					mTree.SelectedItem = (int32)i;
					mSelecting = false;
				}
			}
		}
	}

	// The group headed `header` in `groups`, added when there is none.
	private static StyleGroup GroupOf(List<StyleGroup> groups, StringView header)
	{
		for (let g in groups)
		{
			if (g.Header == header)
				return g;
		}
		let g = new StyleGroup();
		g.Header.Set(header);
		groups.Add(g);
		return g;
	}

	// A new line of `property` (and `value`), in `group`.
	private static StyleLine LineIn(StyleGroup group, StringView property, StringView value)
	{
		let line = new StyleLine();
		line.Property.Set(property);
		line.Value.Set(value);
		group.Lines.Add(line);
		return line;
	}

	// `items` joined by commas, "(none)" when there are none.
	private static void Joined(List<String> items, String outText)
	{
		let start = outText.Length;
		for (let item in items)
		{
			if (outText.Length != start)
				outText.Append(", ");
			outText.Append(item);
		}
		if (outText.Length == start)
			outText.Append("(none)");
	}

	// A thickness as "top right bottom left", whole pixels.
	private static void Sides(Thickness t, String outText)
	{
		outText.AppendF("{} {} {} {}", (int32)t.Top, (int32)t.Right, (int32)t.Bottom, (int32)t.Left);
	}

	private void RebuildDetails()
	{
		if (mDetails == null)
			return;
		mDetails.RemoveAllChildren();
		mDetailsStale = false;
		let node = Selected;
		mDetailsFor = node;
		if (node == null)
		{
			this.Text(mDetails, "idim", "Nothing selected: pick a node, choose one in the tree, or query a selector.");
			return;
		}
		let d = scope NodeDescription();
		Describe(node, d);
		let body = mDetails;
		this.Text(body, "ihead", Sedulous.GUI.Inspector.Label(node, .. scope String()));
		if (d.Tag.Length != 0)
			this.Text(body, "idim", scope String()..AppendF("<{}>", d.Tag));

		// States, and the toggles that force them for the style pass.
		this.Text(body, "isection", "States");
		let states = scope String();
		for (let s in d.States)
		{
			if (states.Length != 0)
				states.Append(", ");
			states.Append(s);
		}
		this.Text(body, "iline", (states.Length != 0) ? (StringView)states : "(none)");
		let force = Add<Panel>(body, "iforce");
		for (let f in sForceable)
		{
			let @box = Add<CheckBox>(force);
			@box.Text = f.Name;
			@box.Checked = (node.ForcedStyleStates & f.State) != 0;
			let state = f.State;
			@box.SetOnToggled(new (on) =>
				{
					if (let n = Selected)
						n.ForcedStyleStates = on ? (n.ForcedStyleStates | state) : (n.ForcedStyleStates & ~state);
				});
		}

		// The box.
		this.Text(body, "isection", "Box");
		this.Text(body, "iline", scope String()..AppendF("at {}, {}  size {} x {}", (int32)d.Bounds.X, (int32)d.Bounds.Y,
			(int32)node.Size.X, (int32)node.Size.Y));
		{
			let line = scope String();
			line.Append("margin ");
			Sides(d.Margin, line);
			line.Append("   padding ");
			Sides(d.Padding, line);
			this.Text(body, "iline", line);
		}
		{
			let wanted = node.Measure(LayoutConstraints());
			this.Text(body, "idim", scope String()..AppendF("measures {} x {} unbounded", (int32)wanted.X, (int32)wanted.Y));
		}

		// Styles, grouped by rule (the winner of each property first; overridden ones dim). A
		// rule's declaration and the inline style's are fields: Enter edits the rule itself
		// (every node it matches follows), or the node's inline style.
		let widget = node as UIWidget;
		if ((widget != null) && (mTargetStyles != null))
		{
			this.Text(body, "isection", "Styles");
			this.Text(body, "idim", "Grouped by rule; a dim name is overridden. Enter edits the rule (or the inline style).");
			let explained = scope List<StyleExplanation>();
			defer { ClearAndDeleteItems!(explained); }
			mTargetStyles.ExplainStyle(widget, explained);
			let groups = scope List<StyleGroup>();
			defer { ClearAndDeleteItems!(groups); }
			for (let e in explained)
			{
				if ((e.Origin == .Inherited) && (e.InheritedFrom != null))
				{
					let header = scope String("inherited from ");
					Sedulous.GUI.Inspector.Label(e.InheritedFrom, header);
					LineIn(GroupOf(groups, header), e.Property, e.Value);
					continue;
				}
				if (e.Origin == .Code)
					LineIn(GroupOf(groups, "set by code"), e.Property, default);
				for (int i = 0; i < e.Declarations.Count; i++)
				{
					let source = e.Declarations[i];
					let header = scope String();
					if (source.Inline)
						header.Append("inline style");
					else
						header.AppendF("{}   {}:{}", source.Selector, source.Sheet, source.Line);
					let line = LineIn(GroupOf(groups, header), e.Property, source.Value);
					line.Won = (i == 0) && (e.Origin != .Code);
					line.Important = source.Important;
					line.Editable = true;
					line.Inline = source.Inline;
					line.Rule = source.Rule;
				}
			}
			for (let g in groups)
			{
				this.Text(body, "irule", g.Header);
				for (let line in g.Lines)
				{
					if (!line.Editable)
					{
						if (line.Value.Length != 0)
							this.Text(body, "iline", scope String()..AppendF("{}: {}", line.Property, line.Value));
						else
							this.Text(body, "iline", line.Property);
						continue;
					}
					let row = Add<Panel>(body, "iprop");
					this.Text(row, line.Won ? "iline" : "iover", line.Property);
					let field = Add<TextField>(row);
					if (line.Important)
						field.Text = scope String()..AppendF("{} !important", line.Value);
					else
						field.Text = line.Value;
					let property = new String(line.Property);
					let rule = line.Rule; // compared, never followed: a sheet replaced since makes it a miss
					let inlineStyle = line.Inline;
					field.SetOnSubmit(new (text) =>
						{
							let n = Selected;
							if ((n == null) || (mTargetStyles == null))
								return;
							if (inlineStyle)
								SetProperty(n, property, text);
							else if (rule != null)
								mTargetStyles.EditDeclaration(rule, property, text);
							mDetailsStale = true; // shown again next refresh, not under this field's call
						} ~ { delete property; });
				}
			}
			if (groups.IsEmpty)
				this.Text(body, "idim", "(no rule sets anything)");
		}

		// Reflected properties, edited as markup sets them (Enter applies).
		this.Text(body, "isection", "Properties");
		for (let p in d.Properties)
		{
			let row = Add<Panel>(body, "iprop");
			// A translated one names its key ("text @menu.play").
			let shown = (p.CssName.Length != 0) ? p.CssName : p.Name;
			if (p.Key.Length != 0)
				this.Text(row, default, scope String()..AppendF("{} @{}", shown, p.Key));
			else
				this.Text(row, default, shown);
			if (p.ReadOnly)
			{
				this.Text(row, "idim", p.Value);
				continue;
			}
			let field = Add<TextField>(row);
			field.Text = p.Value;
			// By the name markup gives it: its own camelCased ("text" for Text), which an attribute
			// the widget claims answers to as well as a property with a CSS name.
			let name = new String(p.Name);
			if (name.Length != 0)
				name[0] = name[0].ToLower;
			field.SetOnSubmit(new (text) =>
				{
					if (let n = Selected)
						SetProperty(n, name, text);
				} ~ { delete name; });
		}

		// What a screen reader is told of it, and what in the GUI it would trip on.
		{
			this.Text(body, "isection", "Accessibility");
			let a = scope AccessDescription();
			DescribeAccess(node, a);
			if (!a.Own)
			{
				if (a.ReadAs.Length != 0)
					this.Text(body, "idim", scope String()..AppendF("no node of its own: read as part of {}", a.ReadAs));
				else
					this.Text(body, "idim", "not read: hidden, or in no GUI");
			}
			else
			{
				this.Text(body, "iline", scope String()..AppendF("{} \"{}\"", a.Role, a.Name));
				if (a.Value.Length != 0)
					this.Text(body, "iline", scope String()..AppendF("value {}", a.Value));
				if (a.Description.Length != 0)
					this.Text(body, "iline", scope String()..AppendF("description {}", a.Description));
				this.Text(body, "idim", Joined(a.States, .. scope String("states ")));
				this.Text(body, "idim", Joined(a.Actions, .. scope String("actions ")));
			}
			if (let root = node.SceneRoot)
			{
				let issues = scope List<AccessIssue>();
				defer { ClearAndDeleteItems!(issues); }
				AuditAccess(root, issues);
				if (issues.IsEmpty)
					this.Text(body, "idim", "audit: nothing in this GUI a screen reader trips on");
				else
					this.Text(body, "idim", scope String()..AppendF("audit: {} in this GUI", issues.Count));
				for (let issue in issues)
				{
					let line = scope String();
					Sedulous.GUI.Inspector.Label(issue.Target, line);
					line.AppendF(": {}", issue.Message);
					this.Text(body, "iline", line);
				}
			}
		}

		void Section(StringView title, List<String> items)
		{
			if (items.IsEmpty)
				return;
			this.Text(body, "isection", title);
			for (let item in items)
				this.Text(body, "iline", item);
		}
		Section("Commands", d.Commands);
		Section("Listeners", d.Listeners);
		if (d.Bindings != 0)
			this.Text(body, "idim", scope String()..AppendF("{} bindings", d.Bindings));
	}
}
