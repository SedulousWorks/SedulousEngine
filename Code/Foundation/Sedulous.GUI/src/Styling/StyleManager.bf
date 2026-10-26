using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Profiler;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// StyleManager: the glue that makes a StyleSheet live on a widget tree. It resolves each UIWidget
// against the sheet (+ MediaContext), applies the result, and - by caching the last-applied
// ResolvedStyle per widget - animates transitioned changes on the next apply. Re-applying after a
// state change (e.g. :hover) therefore drives CSS transitions live.
//
// The per-widget cache lives here, not on UIWidget. ApplyTree re-resolves only what changed: the
// widgets a state, class, tag, id or parent change marked (Node.MarkStyleDirty), with their
// subtrees or later siblings when a sheet reads that state through them, the children of a widget
// whose children were rearranged when a sheet reads siblings, the children of one whose custom
// properties changed, and everything after a new sheet, media or fonts. Cache entries are keyed by
// the widget's address (never followed) and checked against its place in its GUI's element table,
// so a destroyed widget's entries are never taken for a new one's at the same address, and a sweep
// drops them as the caches grow; Forget() or Clear() drops them at once.

/// Where a node's value of a property came from (for the inspector).
enum StyleOrigin : uint8
{
	/// A rule of a sheet.
	Sheet,
	/// The node's inline style (markup's attributes, a script's style).
	Inline,
	/// An ancestor's (an inherited property no rule here set).
	Inherited,
	/// A setter called from code: the sheet leaves it be.
	Code,
	/// Nothing set it: the node's own value.
	Own,
}

/// One declaration of a property: where it was written and what it said. A class: it owns its
/// text.
class StyleDeclarationSource
{
	/// Its sheet's name ("inline" for the inline style).
	public String Sheet = new .() ~ delete _;
	/// Its rule's line in that sheet (0: unknown).
	public uint32 Line = 0;
	/// Its rule's selector as written.
	public String Selector = new .() ~ delete _;
	/// As written.
	public String Value = new .() ~ delete _;
	public bool Important = false;
	public bool Inline = false;
	/// Its rule (null for the inline style), for EditDeclaration. Borrowed.
	public StyleRule Rule = null;

	public void Set(StyleDeclarationSource other)
	{
		if (other === this)
			return;
		Sheet.Set(other.Sheet);
		Line = other.Line;
		Selector.Set(other.Selector);
		Value.Set(other.Value);
		Important = other.Important;
		Inline = other.Inline;
		Rule = other.Rule;
	}
}

/// A property of a node, its value and where the value came from. A class: it owns its text and
/// its declarations.
class StyleExplanation
{
	public String Property = new .() ~ delete _;
	public StyleOrigin Origin = .Own;
	/// The cascade's (the ancestor's when inherited; empty for code's or its own).
	public String Value = new .() ~ delete _;
	/// This node's declarations of it, the winner first (all overridden when code set it).
	public List<StyleDeclarationSource> Declarations = new .() ~ DeleteContainerAndItems!(_);
	/// The ancestor whose value it is. Borrowed.
	public UIWidget InheritedFrom = null;
	/// A transition or an animation moves it now.
	public bool Animated = false;

	public void Set(StyleExplanation other)
	{
		if (other === this)
			return;
		Property.Set(other.Property);
		Origin = other.Origin;
		Value.Set(other.Value);
		ClearAndDeleteItems!(Declarations);
		for (let d in other.Declarations)
		{
			let copy = new StyleDeclarationSource();
			copy.Set(d);
			Declarations.Add(copy);
		}
		InheritedFrom = other.InheritedFrom;
		Animated = other.Animated;
	}
}

class StyleManager
{
	/// A sheet for a subtree: its root, held weakly through its GUI's element table (the table
	/// held, so a closed GUI's root reads as gone), and the sheet.
	private class SubtreeSheet
	{
		public ElementTable Table ~ _?.ReleaseRef();
		public uint32 Slot = 0;
		public uint32 Generation = 0;
		public Sedulous.GUI.StyleSheet Sheet = new .() ~ delete _;
	}

	// Whose entries an address's are: the widget's place in its GUI's element table when they were
	// made (the table held, so a closed GUI's reads as gone, not freed).
	private class Owner
	{
		public ElementTable Table ~ _?.ReleaseRef();
		public uint32 Slot = 0;
		public uint32 Generation = 0;
	}

	private const int cFirstSweep = 256;

	private Sedulous.GUI.StyleSheet mUserAgent = new .() ~ delete _;
	private Sedulous.GUI.StyleSheet mSheet = new .() ~ delete _;
	private List<SubtreeSheet> mSubtrees = new .() ~ DeleteContainerAndItems!(_);
	private Sedulous.GUI.MediaContext mContext = .();
	private IResourceProvider mResources = null; // non-owning; loads background-image assets
	private IFontService mFontService = null; // non-owning; resolves font-family
	private delegate bool(StringView face, StringView source) mFontFaceLoader ~ delete _; // the host's; loads @font-face
	private bool mFontFacesLoaded = false; // this sheet's faces were asked for
	private bool mImportsExpanded = false; // this sheet's @imports are in it
	private float mRootFontSize = 16.0f; // CSS `rem` base

	// Keyed by the widget's address, never followed (a destroyed widget's entries wait for the
	// sweep).
	private Dictionary<int, Owner> mOwners = new .() ~ DeleteDictionaryAndValues!(_); // whose entries each address's are
	private int mSweepAt = cFirstSweep;
	private Dictionary<int, ResolvedStyle> mCache = new .() ~ DeleteDictionaryAndValues!(_); // last-applied style per widget
	private Dictionary<int, StyleAnimation> mAnimations = new .() ~ { for (let a in _.Values) a.ReleaseRef(); delete _; }; // widget -> its running transitions and animations (a reference each)
	private Dictionary<int, List<String>> mStartedAnimations = new .() ~ { for (let l in _.Values) DeleteContainerAndItems!(l); delete _; }; // widget -> the @keyframes it has started
	private bool mAllDirty = true; // the next ApplyTree restyles everything (a new sheet, media, fonts)
	private bool mRelationsKnown = false;
	private bool mSheetsReadViewport = false; // a declaration in vw or vh: a resize restyles everything
	private List<MediaQuery> mSizeQueries = new .() ~ delete _; // the rules' media queries with features (borrowed), asked again on a resize
	private bool mViewportResized = false; // the viewport's size changed, no sheet reading it
	private uint32 mAncestorStates = 0; // states a rule reads through an ancestor: a change restyles the subtree
	private uint32 mSiblingStates = 0; // states a rule reads through an earlier sibling: a change restyles the later siblings
	private uint32 mLastRestyleCount = 0;
	private bool mReadsSiblings = false; // some rule reads siblings: a rearrangement restyles them
	private List<StyleSelectorRule> mSiblingReadsAbove = new .() ~ DeleteContainerAndItems!(_); // compounds reading siblings with a step below: what such a child holds restyles too
	private AncestorFilter mAncestors = new .() ~ delete _; // the names above the widget ApplyTree's walk is at
	private bool mFiltering = false; // inside that walk (a widget styled any other way has no filter)

	public this()
	{
	}

	/// A manager styling by a copy of `sheet`.
	public this(Sedulous.GUI.StyleSheet sheet)
	{
		mSheet.Set(sheet);
	}

	/// The GUI's sheet (the author origin): over the user agent's, under a subtree's and inline.
	/// Setting it takes a copy (the caller keeps its own); every widget restyles (hot-reload).
	public Sedulous.GUI.StyleSheet StyleSheet
	{
		get => mSheet;
		set
		{
			mSheet.Set(value);
			ClearCache();
			mAllDirty = true; // hot-reload: every widget restyles
			mRelationsKnown = false;
			mFontFacesLoaded = false;
			mImportsExpanded = false;
		}
	}

	/// The user agent's sheet, the lowest origin: the built-in theme, what every rule of the GUI's
	/// own sheets overrides. Setting it takes a copy.
	public Sedulous.GUI.StyleSheet UserAgentSheet
	{
		get => mUserAgent;
		set
		{
			mUserAgent.Set(value);
			ClearCache();
			mAllDirty = true;
			mRelationsKnown = false;
			mFontFacesLoaded = false;
			mImportsExpanded = false; // its sprites, as the author sheet's
		}
	}

	/// A sheet (a copy of `sheet`) for `root` and what is under it alone (a page's own .css): over
	/// the GUI's sheet, under inline; a subtree inside another's outranks it. The root must be in a
	/// GUI (it is held weakly, through its GUI's element table); false when it is in none.
	public bool SetSubtreeSheet(Node root, Sedulous.GUI.StyleSheet sheet)
	{
		let elementRef = root.TakeElementRef();
		if (elementRef.Table == null)
			return false;
		RemoveSubtreeSheet(root);
		let subtree = new SubtreeSheet();
		subtree.Table = elementRef.Table;
		subtree.Table.AddRef();
		subtree.Slot = elementRef.Slot;
		subtree.Generation = elementRef.Generation;
		subtree.Sheet.Set(sheet);
		mSubtrees.Add(subtree);
		root.MarkStyleDirty(true);
		mRelationsKnown = false;
		return true;
	}

	public void RemoveSubtreeSheet(Node root)
	{
		for (int i = 0; i < mSubtrees.Count; i++)
		{
			if (RootOf(mSubtrees[i]) == root)
			{
				delete mSubtrees[i];
				mSubtrees.RemoveAt(i);
				root.MarkStyleDirty(true);
				mRelationsKnown = false;
				return;
			}
		}
	}

	public Sedulous.GUI.MediaContext MediaContext
	{
		get => mContext;
		set
		{
			if (value == mContext)
				return; // unchanged: nothing to restyle (a host may set it every frame)
			let before = mContext;
			mContext = value;
			// The viewport's size alone (a window resized: each frame of the drag) restyles
			// everything only when a sheet reads it, through vw or vh or a size query that now
			// answers differently; else only the widgets whose own inline style reads it. The input
			// kind alone (a mouse bumped while a pad plays) restyles only when a query answers
			// differently.
			var moved = before;
			moved.Width = value.Width;
			moved.Height = value.Height;
			moved.Input = value.Input;
			if ((moved == value) && mImportsExpanded)
			{
				if (!mRelationsKnown)
					LearnRelations();
				let resized = (before.Width != value.Width) || (before.Height != value.Height);
				bool flips = resized && mSheetsReadViewport;
				for (int i = 0; !flips && (i < mSizeQueries.Count); i++)
					flips = mSizeQueries[i].Evaluate(before) != mSizeQueries[i].Evaluate(value);
				if (!flips)
				{
					mViewportResized = mViewportResized || resized;
					return;
				}
			}
			mAllDirty = true;
		}
	}

	/// Root font size for CSS `rem` units (default 16px).
	public float RootFontSize
	{
		get => mRootFontSize;
		set
		{
			mAllDirty = mAllDirty || (value != mRootFontSize);
			mRootFontSize = value;
		}
	}

	/// Loads background-image assets referenced by the sheet (not owned). Null: background-image
	/// skipped.
	public IResourceProvider ResourceProvider
	{
		get => mResources;
		set
		{
			mAllDirty = mAllDirty || (value != mResources);
			mImportsExpanded = mImportsExpanded && (value == mResources);
			mResources = value;
		}
	}

	/// Resolves font-family and font-size in the sheet (the app's font service, VFS-backed or not;
	/// the GUI is agnostic; not owned). Null: font-family skipped.
	public IFontService FontService
	{
		get => mFontService;
		set
		{
			mAllDirty = mAllDirty || (value != mFontService);
			mFontFacesLoaded = mFontFacesLoaded && (value == mFontService); // a new service lacks the faces
			mFontService = value;
		}
	}

	/// Loads a sheet's @font-face: the host puts the file at `source` (a path as the sheet wrote it)
	/// into its font service under `face`, the name the face is chosen by ("Family", "Family Bold",
	/// "Family Light Italic"), and says whether it did. Each face is asked for once per sheet,
	/// before the restyle that may draw in it; one the service already has is not asked for. Null:
	/// @font-face is skipped. OWNERSHIP of `loader` transfers (one set before is deleted).
	public void SetFontFaceLoader(delegate bool(StringView face, StringView source) loader)
	{
		delete mFontFaceLoader;
		mFontFaceLoader = loader;
		mFontFacesLoaded = false;
		mAllDirty = true;
	}

	/// Resolve + apply one widget. A property that changed and has a `transition` moves from the
	/// value showing toward its new one, an `animation` runs its @keyframes, both through the
	/// widget's StyleAnimation on its GUI's clock; otherwise the style applies at once.
	public void ApplyTo(UIWidget widget)
	{
		let filtering = mFiltering; // the walk's filter is not this widget's ancestors
		mFiltering = false;
		ApplyOne(widget);
		mFiltering = filtering;
	}

	/// Restyles what changed in the subtree (only what changed: a widget whose class, id, tag or
	/// state changed, or that joined the tree, with its descendants; the children of one whose
	/// custom properties changed; everything after the sheet, the media, the fonts or the resources
	/// changed). A clean subtree is not visited.
	public void ApplyTree(Node root)
	{
		using (ProfileScope("GUI.Style"))
		{
			let watch = scope Stopwatch(true);
			mLastRestyleCount = 0;
			if (!mRelationsKnown)
				LearnRelations();
			if (!mImportsExpanded)
				ExpandImports();
			if (!mFontFacesLoaded)
				LoadFontFaces();
			let all = mAllDirty;
			mAllDirty = false;
			if (mViewportResized && !all)
				MarkViewportReaders(root);
			mViewportResized = false;
			// The names above what is styled, from the walk's start up: pushed on the way down.
			mAncestors.Clear();
			for (var n = root.Parent; n != null; n = n.Parent)
			{
				let w = n as UIWidget;
				if (w != null)
					mAncestors.Push(w);
			}
			root.RootNode.NoteStylePass(); // a node leaving this tree waits for its exit
			mFiltering = true;
			Visit(root, all, false);
			mFiltering = false;
			if (mOwners.Count > mSweepAt)
				SweepGone();
			let stats = root.FrameStats; // the GUI's frame stats
			if (stats != null)
			{
				stats.StyleMs += watch.Elapsed.TotalMilliseconds;
				stats.Restyled += mLastRestyleCount;
			}
		}
	}

	/// How many widgets the last ApplyTree restyled (none in a frame where nothing changed).
	public uint32 LastRestyleCount => mLastRestyleCount;
	/// How many widgets it keeps a style for (a destroyed one's go at the next sweep).
	public int CachedWidgetCount => mCache.Count;

	/// Every property something sets on `widget`, each with its value and where it came from, added
	/// to `outExplanations` (empty; the caller owns what is added): its cascade's longhands (each
	/// declaration, the winner first), what code pinned, and the inherited properties an
	/// ancestor's rules set. For the inspector, not the frame.
	public void ExplainStyle(UIWidget widget, List<StyleExplanation> outExplanations)
	{
		let subtrees = scope List<Sedulous.GUI.StyleSheet>();
		SubtreeSheetsOver(widget, subtrees);
		let matches = scope List<StyleRuleMatch>();
		Collect(widget, subtrees, default, 0, null, matches);
		let traces = scope List<LonghandTrace>();
		defer { ClearAndDeleteItems!(traces); }
		Sedulous.GUI.StyleSheet.Trace(matches, widget.InlineStyle, traces);
		bool Listed(StringView name)
		{
			for (let e in outExplanations)
			{
				if (e.Property == name)
					return true;
			}
			return false;
		}
		for (let trace in traces)
			outExplanations.Add(Explain(widget, trace.Name, trace, subtrees));
		for (uint32 slot = 0; slot < (uint32)StyleSlot.SlotCount; slot++)
		{
			let name = StyleSlotProperty((StyleSlot)slot);
			if (widget.IsStylePinned((StyleSlot)slot) && !Listed(name))
				outExplanations.Add(Explain(widget, name, null, subtrees));
		}
		for (let spec in AllStyleProperties())
		{
			StringView name = spec.Name;
			if (spec.Inherited && !Listed(name) && (InheritedFrom(widget, name) != null))
				outExplanations.Add(Explain(widget, name, null, subtrees));
		}
	}

	/// Sets `property` to `value` in `rule` (one of its sheets'), as an inspector edits a rule: every
	/// node it matches restyles. A longhand set in a rule written with its shorthand comes after it
	/// there, so it wins for that side alone. False when the rule is none of its sheets' (it is only
	/// compared, so one from a sheet replaced since is safe to pass).
	public bool EditDeclaration(StyleRule rule, StringView property, StringView value)
	{
		var editable = mUserAgent.MutableRule(rule);
		if (editable == null)
			editable = mSheet.MutableRule(rule);
		for (int i = 0; (editable == null) && (i < mSubtrees.Count); i++)
			editable = mSubtrees[i].Sheet.MutableRule(rule);
		if (editable == null)
			return false;
		editable.SetProperty(property, value);
		mAllDirty = true;
		return true;
	}

	/// One property of `widget`, as ExplainStyle gives it (its own value when nothing sets it), into
	/// `outExplanation` (a new one).
	public void ExplainProperty(UIWidget widget, StringView property, StyleExplanation outExplanation)
	{
		let all = scope List<StyleExplanation>();
		defer { ClearAndDeleteItems!(all); }
		ExplainStyle(widget, all);
		for (let e in all)
		{
			if (e.Property == property)
			{
				outExplanation.Set(e);
				return;
			}
		}
		outExplanation.Property.Set(property);
	}

	/// Drop a widget's cached style (a destroyed one's go by themselves, at the next sweep).
	public void Forget(Node widget)
	{
		ForgetKey(KeyOf(widget));
	}

	public void Clear()
	{
		ClearCache();
		for (let a in mAnimations.Values)
			a.ReleaseRef();
		mAnimations.Clear();
		for (let l in mStartedAnimations.Values)
			DeleteContainerAndItems!(l);
		mStartedAnimations.Clear();
		for (let o in mOwners.Values)
			delete o;
		mOwners.Clear();
	}

	// The address a widget's entries are kept under (never followed).
	private static int KeyOf(Node node) => (int)Internal.UnsafeCastToPtr(node);

	private void ClearCache()
	{
		for (let s in mCache.Values)
			delete s;
		mCache.Clear();
	}

	private ResolvedStyle CachedStyle(Node node)
	{
		if (mCache.TryGetValue(KeyOf(node), let style))
			return style;
		return null;
	}

	private StyleAnimation AnimationOf(Node node)
	{
		if (mAnimations.TryGetValue(KeyOf(node), let animation))
			return animation;
		return null;
	}

	private void RemoveAnimation(int key)
	{
		if (mAnimations.TryGetValue(key, let animation))
		{
			mAnimations.Remove(key);
			animation.ReleaseRef();
		}
	}

	private void ForgetKey(int key)
	{
		if (mCache.TryGetValue(key, let style))
		{
			mCache.Remove(key);
			delete style;
		}
		RemoveAnimation(key);
		if (mStartedAnimations.TryGetValue(key, let started))
		{
			mStartedAnimations.Remove(key);
			DeleteContainerAndItems!(started);
		}
		if (mOwners.TryGetValue(key, let owner))
		{
			mOwners.Remove(key);
			delete owner;
		}
	}

	private void Visit(Node node, bool forceSubtree, bool forceSelf)
	{
		// A state a rule reads through this node (as an ancestor's, or an earlier sibling's)
		// restyles what it reaches; any other state change restyles the node alone.
		let states = node.ChangedStyleStates;
		if ((states & mSiblingStates) != 0)
		{
			let parent = node.Parent;
			if (parent != null)
			{
				for (int i = parent.GetChildIndex(node) + 1; i < parent.ChildCount; i++)
					parent.GetChildAt(i).MarkStyleDirty(true);
			}
		}
		let self = forceSubtree || forceSelf || node.IsStyleDirty;
		let subtree = forceSubtree || node.IsStyleSubtreeDirty || ((states & mAncestorStates) != 0);
		// Its children came, went or moved: when a sheet reads siblings, each may match
		// differently, and what each holds only when a rule reads them through an ancestor; else
		// only the new ones restyle (marked so). (Restyling every child's subtree made each popup or
		// tooltip joining the root restyle the whole page: a second in Debug.)
		let rearranged = mReadsSiblings && node.ChildrenArrangementChanged;
		var descend = subtree || rearranged || node.HasStyleDirtyDescendant;
		let moved = node.IsStyleMotionDirty;
		node.ClearStyleDirty();
		bool customsChanged = false;
		let widget = node as UIWidget;
		if (self)
		{
			if (widget != null)
			{
				customsChanged = ApplyOne(widget);
				mLastRestyleCount++;
			}
		}
		else if (moved)
		{
			if (widget != null)
				ApplyMotion(widget);
		}
		// Applying it may have marked what it holds (a direction it now runs in).
		descend = descend || node.HasStyleDirtyDescendant;
		if (!descend && !customsChanged)
			return;
		if (widget != null)
			mAncestors.Push(widget);
		for (int i = 0; i < node.ChildCount; i++)
		{
			let child = node.GetChildAt(i);
			if (child != null)
				Visit(child, subtree || (rearranged && HoldsSiblingReads(child)), customsChanged || rearranged);
		}
		if (widget != null)
			mAncestors.Pop();
	}

	// Whether a rearrangement of `child`'s siblings can change what matches inside it: a rule reads
	// siblings in a compound `child` could match, with a step below it.
	private bool HoldsSiblingReads(Node child)
	{
		let widget = child as UIWidget;
		if (widget == null)
			return !mSiblingReadsAbove.IsEmpty;
		for (let compound in mSiblingReadsAbove)
		{
			if (compound.MatchesIdentity(widget))
				return true;
		}
		return false;
	}

	private static bool SameCustomProperties(ResolvedStyle a, ResolvedStyle b)
	{
		bool Contains(ResolvedStyle within, ResolvedProperty p) => (within.Get(p.Name) == p.Value) && within.Has(p.Name);
		for (let p in a.Properties)
		{
			if (ResolvedStyle.IsCustomProperty(p.Name) && !Contains(b, p))
				return false;
		}
		for (let p in b.Properties)
		{
			if (ResolvedStyle.IsCustomProperty(p.Name) && !Contains(a, p))
				return false;
		}
		return true;
	}

	// What applying `resolved` to `widget` needs: the length-resolution context (the viewport from
	// the media context, the root font size configurable, the element's font size from its
	// resolved font-size, for em), the resources and the fonts.
	private StyleApplyContext ApplyContextFor(UIWidget widget, ResolvedStyle resolved)
	{
		var context = StyleApplyContext();
		context.Resources = mResources;
		context.FontService = mFontService;
		context.Lengths.RootFontSize = mRootFontSize;
		context.Lengths.ViewportWidth = mContext.Width;
		context.Lengths.ViewportHeight = mContext.Height;
		// The element's font size, what its em lengths measure by: its own font-size resolved
		// against its parent's (em and percentages of the parent's, rem of the root's), else the
		// parent's as it inherits.
		let parentNode = widget.Parent as UINode;
		let parentSize = ((parentNode != null) && (parentNode.GetTextStyle().FontSize > 0.0f)) ? parentNode.GetTextStyle().FontSize : mRootFontSize;
		var parentLengths = context.Lengths;
		parentLengths.ElementFontSize = parentSize;
		let fontSize = resolved.Get("font-size", "");
		context.Lengths.ElementFontSize = (fontSize.Length != 0) ? ResolveLength(fontSize, parentLengths, parentSize).GetValueOrDefault(parentSize) : parentSize;
		return context;
	}

	// A tween moved and nothing else changed: the style it has, with the animated layer over it,
	// applied again (through its transitions and animations when they run).
	private void ApplyMotion(UIWidget widget)
	{
		if (!IsOwn(widget))
		{
			ApplyOne(widget); // entries at its address were another's: from scratch
			return;
		}
		let running = AnimationOf(widget);
		if ((running != null) && !running.IsDone)
		{
			running.ApplyNow();
			return;
		}
		let cached = CachedStyle(widget);
		if (cached == null)
		{
			ApplyOne(widget);
			return;
		}
		let effective = scope ResolvedStyle();
		effective.Set(cached);
		let context = ApplyContextFor(widget, effective);
		var lengths = StyleInterpolationContext();
		lengths.Lengths = context.Lengths;
		lengths.BoxSize = widget.Size;
		OverlayMotion(widget, effective, lengths);
		ApplyStyle(widget, effective, context.Resources, context.FontService, context.Lengths);
	}

	// Restyles one widget; whether its custom properties changed (its children then restyle, as
	// they inherit them).
	private bool ApplyOne(UIWidget widget)
	{
		Claim(widget);
		let key = KeyOf(widget);
		// Custom properties inherit: the nearest styled ancestor's resolved style gives those this
		// widget does not set (ApplyTree styles parents first, so theirs are current).
		ResolvedStyle inherited = null;
		for (var ancestor = widget.Parent; (ancestor != null) && (inherited == null); ancestor = ancestor.Parent)
			inherited = CachedStyle(ancestor);
		let subtrees = scope List<Sedulous.GUI.StyleSheet>();
		SubtreeSheetsOver(widget, subtrees);
		let resolved = new ResolvedStyle(); // the cache's, at the end
		ResolveFor(widget, subtrees, default, inherited, 0, resolved);
		resolved.SettleKeywords(inherited);
		let textBefore = scope UINode.TextStyle();
		textBefore.Set(widget.GetTextStyle());

		let context = ApplyContextFor(widget, resolved);

		// The animation this restyle drives, with a reference of its own while it does.
		StyleAnimation animation = null;
		let running = AnimationOf(widget);
		if (running != null)
		{
			if (running.IsDone)
				RemoveAnimation(key);
			else
			{
				animation = running;
				animation.AddRef();
			}
		}
		defer
		{
			if (animation != null)
				animation.ReleaseRef();
		}
		bool created = false;
		bool Ensure()
		{
			if ((animation == null) && (widget.ActionManager != null))
			{
				animation = new StyleAnimation(widget);
				animation.SetTargetStyle(resolved, context);
				created = true;
			}
			return animation != null;
		}

		// A transition for each property that changed between `prior` (the style applied last) and
		// `resolved` and an entry covers (its own name, or `all` for the transitionable ones; the
		// last entry naming a property wins), from the value showing now toward the new one.
		void StartTransitions(List<TransitionSpec> transitions, ResolvedStyle prior)
		{
			TransitionSpec SpecFor(StringView name)
			{
				TransitionSpec spec = null;
				for (let t in transitions)
				{
					if ((t.Property == name) || ((t.Property == "all") && IsTransitionable(name)))
						spec = t;
				}
				return spec;
			}
			let initial = scope StyleValue();
			let from = scope StyleValue();
			for (let p in resolved.Properties)
			{
				StringView name = p.Name;
				if (ResolvedStyle.IsCustomProperty(name) || (p.Typed.Kind == .None))
					continue;
				let spec = SpecFor(name);
				if ((spec == null) || (spec.Duration <= 0.0f))
					continue;
				var beforeValue = prior.Value(name);
				if (beforeValue == null)
				{
					// Set now and by no rule before (a toast's `:leaving { opacity: 0 }` over a rule
					// that never set it): from its initial value, as CSS's computed value was. An
					// inherited one took its parent's: not here.
					let property = FindStyleProperty(name);
					if ((property == null) || property.Inherited)
						continue;
					StringView text = (property.Initial != null) ? (StringView)property.Initial
						: ((property.Grammar == .Transforms) ? "none" : StringView());
					if ((text.Length == 0) || (text == p.Value) || !ParseStyleValue(property.Grammar, text, initial))
						continue; // no initial value, or no change from it
					beforeValue = initial;
				}
				else if (prior.Get(name) == p.Value)
					continue; // no change
				from.Set(beforeValue);
				if (animation != null)
					animation.TrackValue(name, from); // retarget from where a running track is
				if (Ensure())
					animation.StartTransition(name, from, p.Typed, spec);
			}
			// A property no rule sets any more (a class taken off: a toast's `.entering`) goes back to
			// its initial value, transitioned there as CSS does, not snapped: toward the table's
			// initial value (`none` for a transform). Inherited ones take their parent's: not here.
			let to = scope StyleValue();
			for (let p in prior.Properties)
			{
				StringView name = p.Name;
				if (ResolvedStyle.IsCustomProperty(name) || (p.Typed.Kind == .None) || (resolved.Value(name) != null))
					continue;
				let property = FindStyleProperty(name);
				if ((property == null) || property.Inherited)
					continue;
				StringView initialText = (property.Initial != null) ? (StringView)property.Initial
					: ((property.Grammar == .Transforms) ? "none" : StringView());
				if ((initialText.Length == 0) || !ParseStyleValue(property.Grammar, initialText, to))
					continue;
				let spec = SpecFor(name);
				if ((spec == null) || (spec.Duration <= 0.0f))
					continue;
				from.Set(p.Typed);
				if (animation != null)
					animation.TrackValue(name, from);
				if (Ensure())
					animation.StartTransition(name, from, to, spec);
			}
		}

		// Transitions: each property that changed since the last apply and a `transition` entry
		// covers, from what shows now. An entrance's first style moves from nothing: it is where
		// the entrance starts.
		let entranceStart = widget.TakeEntranceStart();
		ResolvedStyle previous = entranceStart ? null : CachedStyle(widget);
		if (previous != null)
		{
			let transitions = scope List<TransitionSpec>();
			defer { ClearAndDeleteItems!(transitions); }
			ComposeTransitions(resolved.Get("transition-property"), resolved.Get("transition-duration"),
				resolved.Get("transition-timing-function"), resolved.Get("transition-delay"), transitions);
			if (!transitions.IsEmpty)
				StartTransitions(transitions, previous);
		}

		// Keyframe animations: start those newly named (once: one that has ended stays ended while
		// it is named), stop those no longer named.
		let animations = scope List<AnimationSpec>();
		defer { ClearAndDeleteItems!(animations); }
		ComposeAnimations(resolved.Get("animation-name"), resolved.Get("animation-duration"),
			resolved.Get("animation-timing-function"), resolved.Get("animation-delay"),
			resolved.Get("animation-iteration-count"), resolved.Get("animation-direction"),
			resolved.Get("animation-fill-mode"), resolved.Get("animation-play-state"), animations);
		List<String> started = null;
		if (!mStartedAnimations.TryGetValue(key, out started))
		{
			started = new List<String>();
			mStartedAnimations[key] = started;
		}
		for (int i = 0; i < started.Count;)
		{
			bool named = false;
			for (let spec in animations)
				named = named || (spec.Name == started[i]);
			if (named)
			{
				i++;
				continue;
			}
			if (animation != null)
				animation.StopKeyframes(started[i]);
			delete started[i];
			started.RemoveAt(i);
		}
		for (let spec in animations)
		{
			bool already = false;
			for (let name in started)
				already = already || (name == spec.Name);
			if (already && (animation != null))
				animation.SetPaused(spec.Name, spec.Paused);
			let keyframes = FindKeyframes(subtrees, spec.Name);
			if (already || (keyframes == null))
				continue;
			if (Ensure())
			{
				animation.SetTargetStyle(resolved, context);
				animation.StartKeyframes(spec, keyframes);
				started.Add(new String(spec.Name));
			}
		}

		if ((animation != null) && (animation.TrackCount > 0))
		{
			animation.SetTargetStyle(resolved, context);
			if (created)
			{
				animation.AddRef(); // the map's
				mAnimations[key] = animation;
				widget.RunAction(animation); // Start applies it now
			}
			else
				animation.ApplyNow();
		}
		else
		{
			if (animation != null)
			{
				// Nothing moves any more: the target, with what the stopped tracks moved returned to
				// it (or to its initial value).
				animation.SetTargetStyle(resolved, context);
				animation.ApplyNow();
				animation.Stop();
				RemoveAnimation(key);
			}
			else if (widget.HasMotion)
			{
				// Tweens over it; the cache keeps the cascade alone.
				let effective = scope ResolvedStyle();
				effective.Set(resolved);
				var lengths = StyleInterpolationContext();
				lengths.Lengths = context.Lengths;
				lengths.BoxSize = widget.Size;
				OverlayMotion(widget, effective, lengths);
				ApplyStyle(widget, effective, context.Resources, context.FontService, context.Lengths);
			}
			else
				ApplyStyle(widget, resolved, context.Resources, context.FontService, context.Lengths);
		}
		// Leaving, with nothing the sheet started that will end: it goes (at the GUI's next drain,
		// not inside this walk); else its animation lets it go when that ends.
		if (widget.WatchesMotion && !((animation != null) && !animation.IsDone && animation.WaitsForEnd))
			widget.MotionSettled(); // a leaving node goes, an arriving one takes its next step
		let cachedBefore = CachedStyle(widget);
		// Its children restyle when what they inherit changed: a custom property, or its text style.
		let customsChanged = (cachedBefore == null) || !SameCustomProperties(cachedBefore, resolved) || !textBefore.Equals(widget.GetTextStyle());
		mCache[key] = resolved;
		if ((cachedBefore != null) && (cachedBefore != resolved))
			delete cachedBefore;

		// Pseudo-element parts (tag::part): resolve + apply each part the widget declares.
		let parts = scope List<StringView>();
		widget.CollectStyleParts(parts);
		if (widget.IsScrollContainer) // any node that scrolls has its bars' parts
		{
			parts.Add("scrollbar");
			parts.Add("scrollbar-thumb");
		}
		// A part inherits from its widget, as CSS's pseudo-elements do: its custom properties (a
		// theme's tokens) and currentColor reach it.
		let partStyle = scope ResolvedStyle();
		for (let part in parts)
		{
			ResolveFor(widget, subtrees, part, resolved, widget.GetPartStates(part), partStyle);
			ApplyPartStyle(widget, part, partStyle, context.Resources, context.Lengths);
		}
		return customsChanged;
	}

	private static Node RootOf(SubtreeSheet s) => (s.Table != null) ? s.Table.Resolve(s.Slot, s.Generation) : null;

	// The subtree sheets whose root is `widget` or holds it, the outermost first, added to
	// `outSheets` (borrowed).
	private void SubtreeSheetsOver(Node widget, List<Sedulous.GUI.StyleSheet> outSheets)
	{
		if (mSubtrees.IsEmpty)
			return;
		let first = outSheets.Count;
		for (var n = widget; n != null; n = n.Parent)
		{
			for (let s in mSubtrees)
			{
				if (RootOf(s) == n)
					outSheets.Add(s.Sheet);
			}
		}
		// Innermost first so far: reversed.
		int a = first;
		int b = outSheets.Count - 1;
		while (a < b)
		{
			let t = outSheets[a];
			outSheets[a] = outSheets[b];
			outSheets[b] = t;
			a++;
			b--;
		}
	}

	// The rules matching `widget` (or its `part`) over every origin: the user agent's sheet, the
	// GUI's, the subtrees' (outermost first).
	private void Collect(UIWidget widget, List<Sedulous.GUI.StyleSheet> subtrees, StringView part, uint32 partStates,
		AncestorFilter ancestors, List<StyleRuleMatch> matches)
	{
		mUserAgent.CollectMatches(widget, mContext, true, part, 0, matches, partStates, ancestors);
		mSheet.CollectMatches(widget, mContext, true, part, 1, matches, partStates, ancestors);
		uint32 origin = 2;
		for (let sheet in subtrees)
			sheet.CollectMatches(widget, mContext, true, part, origin++, matches, partStates, ancestors);
	}

	// The sheet at a match's origin.
	private Sedulous.GUI.StyleSheet SheetAt(uint32 origin, List<Sedulous.GUI.StyleSheet> subtrees) =>
		(origin == 0) ? mUserAgent : ((origin == 1) ? mSheet : subtrees[(int)origin - 2]);

	// The nearest ancestor whose cascade set `property`.
	private UIWidget InheritedFrom(UIWidget widget, StringView property)
	{
		for (var n = widget.Parent; n != null; n = n.Parent)
		{
			let style = CachedStyle(n);
			if ((style != null) && style.Has(property))
				return n as UIWidget;
		}
		return null;
	}

	// The caller owns what comes back.
	private StyleExplanation Explain(UIWidget widget, StringView property, LonghandTrace trace, List<Sedulous.GUI.StyleSheet> subtrees)
	{
		let e = new StyleExplanation();
		e.Property.Set(property);
		if (trace != null)
		{
			for (let d in trace.Declarations)
			{
				let source = new StyleDeclarationSource();
				source.Value.Set(d.Value);
				source.Important = d.Important;
				if (d.Rule == null)
				{
					source.Sheet.Set("inline");
					source.Inline = true;
				}
				else
				{
					source.Rule = d.Rule;
					source.Sheet.Set(SheetAt(d.Origin, subtrees).Name);
					source.Line = d.Rule.Line;
					source.Selector.Set(d.Rule.SelectorText);
				}
				e.Declarations.Add(source);
			}
		}
		bool pinned = false;
		for (uint32 slot = 0; slot < (uint32)StyleSlot.SlotCount; slot++)
		{
			if (StyleSlotProperty((StyleSlot)slot) == property)
				pinned = widget.IsStylePinned((StyleSlot)slot);
		}
		if (pinned)
			e.Origin = .Code;
		else if (!e.Declarations.IsEmpty)
		{
			e.Origin = e.Declarations[0].Inline ? .Inline : .Sheet;
			let style = CachedStyle(widget);
			if ((style != null) && style.Has(property))
				e.Value.Set(style.Get(property));
			else
				e.Value.Set(e.Declarations[0].Value);
		}
		else
		{
			let spec = FindStyleProperty(property);
			if ((spec != null) && spec.Inherited)
			{
				let from = InheritedFrom(widget, property);
				if (from != null)
				{
					e.Origin = .Inherited;
					e.InheritedFrom = from;
					e.Value.Set(CachedStyle(from).Get(property));
				}
			}
		}
		let animation = AnimationOf(widget);
		if (animation != null)
		{
			let now = scope StyleValue();
			e.Animated = animation.TrackValue(property, now);
		}
		return e;
	}

	// The cascade for `widget` (or its `part`) over every origin, into `outStyle`: the user agent's
	// sheet, the GUI's, the subtrees' (outermost first), then the widget's inline style.
	private void ResolveFor(UIWidget widget, List<Sedulous.GUI.StyleSheet> subtrees, StringView part, ResolvedStyle inherited,
		uint32 partStates, ResolvedStyle outStyle)
	{
		let matches = scope List<StyleRuleMatch>();
		Collect(widget, subtrees, part, partStates, mFiltering ? mAncestors : null, matches); // the filter only inside ApplyTree's walk
		let inlineStyle = (part.Length == 0) ? widget.InlineStyle : Span<InlineStyleDeclaration>();
		Sedulous.GUI.StyleSheet.Cascade(matches, inherited, inlineStyle, outStyle);
	}

	// The sheet's @import, through the resource provider: each imported sheet (its own imports
	// first) before what imported it; a chain that comes back to a sheet stops there.
	private void ExpandImports()
	{
		mImportsExpanded = true;
		ExpandSheetImports();
		// Sprites: a url() naming one, in either sheet, as its image and region.
		let sprites = scope List<Spritesheet>();
		defer { ClearAndDeleteItems!(sprites); }
		for (let s in mUserAgent.Spritesheets)
		{
			let copy = new Spritesheet();
			copy.Set(s);
			sprites.Add(copy);
		}
		for (let s in mSheet.Spritesheets)
		{
			let copy = new Spritesheet();
			copy.Set(s);
			sprites.Add(copy);
		}
		if (sprites.IsEmpty)
			return;
		mUserAgent.ResolveSprites(sprites);
		mSheet.ResolveSprites(sprites);
		ClearCache();
		mAllDirty = true;
	}

	private void ExpandSheetImports()
	{
		if ((mResources == null) || mSheet.Imports.IsEmpty)
			return;
		let chain = scope List<String>();
		defer { ClearAndDeleteItems!(chain); }
		chain.Add(new String(mSheet.Name));
		ExpandImportsOf(mSheet, chain);
		ClearCache();
		mAllDirty = true;
		mRelationsKnown = false;
	}

	private void ExpandImportsOf(Sedulous.GUI.StyleSheet sheet, List<String> chain)
	{
		let imports = scope List<String>();
		defer { ClearAndDeleteItems!(imports); }
		for (let path in sheet.Imports)
			imports.Add(new String(path));
		for (int i = imports.Count - 1; i >= 0; i--) // the last first: each goes in front of the rest
		{
			bool cycle = false;
			for (let seen in chain)
				cycle = cycle || (seen == imports[i]);
			let text = scope String();
			if (cycle || !mResources.LoadText(imports[i], text))
				continue;
			let imported = scope Sedulous.GUI.StyleSheet();
			CSSParser.Parse(text, imports[i], imported);
			chain.Add(new String(imports[i]));
			ExpandImportsOf(imported, chain);
			delete chain.PopBack();
			sheet.PrependImported(imported);
		}
	}

	// The sheets' @font-face, through the host's loader: each under the name ChooseFace looks for
	// (the family, its weight's name, " Italic").
	private void LoadFontFaces()
	{
		mFontFacesLoaded = true;
		if (mFontFaceLoader == null)
			return;
		Sedulous.GUI.StyleSheet[2] sheets = .(mUserAgent, mSheet);
		let face = scope String();
		for (let sheet in sheets)
		{
			for (let rule in sheet.FontFaces)
			{
				face.Set(rule.Family);
				face.Append(TextLayoutDetail.WeightSuffix(rule.Weight));
				if (rule.Italic)
					face.Append(" Italic");
				if ((mFontService != null) && mFontService.HasFamily(face))
					continue;
				mFontFaceLoader(face, rule.Source);
			}
		}
	}

	// A @keyframes by name: the innermost subtree's, then the GUI's, then the user agent's.
	private Keyframes FindKeyframes(List<Sedulous.GUI.StyleSheet> subtrees, StringView name)
	{
		for (int i = subtrees.Count; i > 0; i--)
		{
			let k = subtrees[i - 1].FindKeyframes(name);
			if (k != null)
				return k;
		}
		let k = mSheet.FindKeyframes(name);
		if (k != null)
			return k;
		return mUserAgent.FindKeyframes(name);
	}

	// A value that reads the viewport's size: a number in vw or vh (`50vw`, `calc(100vh - 2px)`).
	private static bool ReadsViewport(StringView value)
	{
		for (int i = 1; i + 1 < value.Length; i++)
		{
			if ((value[i] == 'v') && ((value[i + 1] == 'w') || (value[i + 1] == 'h')) &&
				(((value[i - 1] >= '0') && (value[i - 1] <= '9')) || (value[i - 1] == '.')))
				return true;
		}
		return false;
	}

	// The widgets whose inline style reads the viewport restyle after it resized (the sheets
	// reading none of it).
	private void MarkViewportReaders(Node node)
	{
		let ui = node as UINode;
		if (ui != null)
		{
			for (let d in ui.InlineStyle)
			{
				if (ReadsViewport(d.Value))
				{
					node.MarkStyleDirty(false);
					break;
				}
			}
		}
		for (int i = 0; i < node.ChildCount; i++)
			MarkViewportReaders(node.GetChildAt(i));
	}

	// The states the sheets read through an ancestor and through a sibling, whether any reads
	// siblings or the viewport, and the media queries a resize asks again.
	private void LearnRelations()
	{
		mAncestorStates = 0;
		mSiblingStates = 0;
		mReadsSiblings = false;
		ClearAndDeleteItems!(mSiblingReadsAbove);
		mSheetsReadViewport = false;
		mSizeQueries.Clear();
		void Learn(Sedulous.GUI.StyleSheet sheet)
		{
			for (let rule in sheet.Rules)
			{
				if (rule.Media.FeatureCount != 0)
					mSizeQueries.Add(rule.Media); // any feature: the size's among them, perhaps
				for (let p in rule.Properties)
					mSheetsReadViewport = mSheetsReadViewport || ReadsViewport(p.Value);
				rule.Selector.CollectRelationStates(ref mAncestorStates, ref mSiblingStates);
				mReadsSiblings = mReadsSiblings || rule.Selector.ReadsSiblings;
				rule.Selector.ForEachSiblingReadAbove(scope (compound) =>
					{
						let copy = new StyleSelectorRule();
						copy.Set(compound);
						mSiblingReadsAbove.Add(copy);
					});
			}
		}
		Learn(mUserAgent);
		Learn(mSheet);
		for (let s in mSubtrees)
			Learn(s.Sheet);
		mRelationsKnown = true;
	}

	// Whether the entries at `widget`'s address are its own: none yet, or made for it (a widget in
	// no GUI has nothing to check against, and keeps them).
	private bool IsOwn(Node widget)
	{
		if (!mOwners.TryGetValue(KeyOf(widget), let owner))
			return true;
		return (owner.Table == null) || (owner.Table.Resolve(owner.Slot, owner.Generation) == widget);
	}

	// Makes the entries at `widget`'s address its own, dropping a destroyed widget's first.
	private void Claim(Node widget)
	{
		if (!IsOwn(widget))
			Forget(widget);
		let key = KeyOf(widget);
		if (mOwners.ContainsKey(key))
			return;
		let elementRef = widget.TakeElementRef();
		let owner = new Owner();
		owner.Table = elementRef.Table;
		if (owner.Table != null)
			owner.Table.AddRef();
		owner.Slot = elementRef.Slot;
		owner.Generation = elementRef.Generation;
		mOwners[key] = owner;
	}

	// Drops the entries of every widget gone since, once the caches have doubled since the last
	// sweep (so a GUI that keeps its widgets pays nothing).
	private void SweepGone()
	{
		let gone = scope List<int>();
		for (let entry in mOwners)
		{
			let owner = entry.value;
			if ((owner.Table != null) && (KeyOf(owner.Table.Resolve(owner.Slot, owner.Generation)) != entry.key))
				gone.Add(entry.key);
		}
		for (let key in gone)
			ForgetKey(key);
		mSweepAt = Math.Max(cFirstSweep, mOwners.Count * 2);
	}
}
