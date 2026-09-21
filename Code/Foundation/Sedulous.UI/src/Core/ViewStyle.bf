using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// View's computed style: the cascade cache, the keyword and variable resolution, and the
/// transitions overlaid on top.
///
/// Kept beside View rather than inside it because it is a subsystem of its own.
extension View
{
	private const int cPropertyCount = (int)StyleProperty.COUNT;
	/// How far a chain of `var()` references may go before it is treated as circular.
	private const int cMaxVariableDepth = 8;
	/// How far up the ancestor chain local sheets are collected from.
	private const int cMaxSheetChainDepth = 64;

	/// The matching rules in ascending cascade order and, per property, the rule that won it.
	private class StyleCache
	{
		public bool Valid = false;
		public uint32 Generation = 0;
		/// The SUMMED versions of every sheet in this view's chain, so a rule edit in one
		/// sheet invalidates only the views that actually read it.
		public uint32 ChainVersion = 0;
		public uint32 SheetEpoch = 0;
		public ControlState State = .Normal;
		/// BORROWED: the sheets own these.
		public List<StyleRule> Rules = new .() ~ delete _;
		public StyleRule[cPropertyCount] Winners = .();
	}

	private struct StyleTransition
	{
		public StyleProperty Property = .COUNT;
		public StyleValue From = .None;
		public StyleValue To = .None;
		public float Elapsed = 0.0f;
		public float Duration = 0.0f;
		public float Delay = 0.0f;
		public TransitionEasing Easing = .Ease;

		public this() {}
	}

	private class TransitionState
	{
		public List<StyleTransition> Active = new .() ~ delete _;
		public bool StateBlendActive = false;
		public ControlState BlendFrom = .Normal;
		public ControlState BlendTo = .Normal;
		public float BlendElapsed = 0.0f;
		public float BlendDuration = 0.0f;
		public float BlendDelay = 0.0f;
		public TransitionEasing BlendEasing = .Ease;
	}

	private StyleCache mStyleCache = new .() ~ delete _;
	/// Null until this view's first transition.
	private TransitionState mTransitionState ~ delete _;
	private bool mTransitionRegistered = false;

	/// OWNED. The `style="..."` overrides on this view alone.
	private StyleSheet mInlineSheet ~ _?.ReleaseRef();
	/// OWNED. A sheet scoped to this view's subtree.
	private StyleSheet mLocalStyleSheet ~ _?.ReleaseRef();

	// ---- Invalidation --------------------------------------------------------------------------

	/// Something changed which RULES match: a class, an id after attaching, a sheet.
	///
	/// The cache stays VALID BUT STALE. The context's generation bump makes the next lookup
	/// rebuild it, and the rebuild reads the old winners first so a transition can start from
	/// where the view actually IS rather than snapping.
	public void InvalidateStyle()
	{
		if (Context != null)
			Context.InvalidateStyles();
		else
			// Detached, so there is no generation to key on and the cache cannot be trusted.
			mStyleCache.Valid = false;
		Invalidate();
	}

	/// A sheet OBJECT was replaced, so the cached rule pointers may be dead.
	public void InvalidateStyleSheets()
	{
		mStyleCache.Valid = false;
		if (Context != null)
			Context.BumpSheetEpoch();
		Invalidate();
	}

	// ---- Style classes -------------------------------------------------------------------------

	public void AddClass(StringView name)
	{
		if (HasClass(name))
			return;
		StyleClasses.Add(new String(name));
		InvalidateStyle();
	}

	public void RemoveClass(StringView name)
	{
		for (int i < StyleClasses.Count)
		{
			if (StyleClasses[i] == name)
			{
				delete StyleClasses[i];
				StyleClasses.RemoveAt(i);
				InvalidateStyle();
				return;
			}
		}
	}

	public void ToggleClass(StringView name)
	{
		if (HasClass(name))
			RemoveClass(name);
		else
			AddClass(name);
	}

	// ---- Sheets --------------------------------------------------------------------------------

	/// BORROWED, and null when this view has no inline overrides.
	public StyleSheet InlineSheet => mInlineSheet;

	public bool HasAnyInlineStyles => (mInlineSheet != null) && !mInlineSheet.IsEmpty;

	/// The inline sheet, made on first use. BORROWED.
	public StyleSheet GetOrCreateInlineSheet()
	{
		if (mInlineSheet == null)
		{
			mInlineSheet = new StyleSheet();
			InvalidateStyle();
		}
		return mInlineSheet;
	}

	/// BORROWED.
	public StyleSheet GetLocalStyleSheet() => mLocalStyleSheet;

	/// CONSUMES the caller's reference.
	public void SetLocalStyleSheet(StyleSheet sheet)
	{
		if (mLocalStyleSheet == sheet)
		{
			if (sheet != null)
				sheet.ReleaseRef();
			return;
		}
		if (mLocalStyleSheet != null)
			mLocalStyleSheet.ReleaseRef();
		mLocalStyleSheet = sheet;
		InvalidateStyleSheets();
	}

	// ---- Inline style setters ------------------------------------------------------------------

	public void SetStyle(StyleProperty property, Color color)
	{
		GetOrCreateInlineSheet().GetOrCreateInlineElementRule().Set(property, color);
		Invalidate();
	}

	public void SetStyle(StyleProperty property, float value)
	{
		GetOrCreateInlineSheet().GetOrCreateInlineElementRule().Set(property, value);
		Invalidate();
	}

	public void SetStyle(StyleProperty property, Thickness value)
	{
		GetOrCreateInlineSheet().GetOrCreateInlineElementRule().Set(property, value);
		Invalidate();
	}

	public void SetStyle(StyleProperty property, bool value)
	{
		GetOrCreateInlineSheet().GetOrCreateInlineElementRule().Set(property, value);
		Invalidate();
	}

	/// CONSUMES the caller's reference: the inline sheet takes ownership of the drawable.
	/// CONSUMES the caller's reference. A caller that wants to keep one takes it first.
	///
	/// Any drawable this property already held is RELEASED. Inline styles are reassigned at
	/// runtime, which is what they are for, so without this a control that swaps its background
	/// on hover would pile up every drawable it ever set until the view died.
	public void SetStyle(StyleProperty property, Drawable drawable)
	{
		let sheet = GetOrCreateInlineSheet();
		let rule = sheet.GetOrCreateInlineElementRule();
		ReleasePreviousDrawable(sheet, rule, property, drawable);
		sheet.OwnDrawable(drawable);
		rule.Set(property, drawable);
		Invalidate();
	}

	public void SetStyle(StyleProperty property, StringView value)
	{
		GetOrCreateInlineSheet().GetOrCreateInlineElementRule().Set(property, value);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty property, Color color)
	{
		GetOrCreateInlineSheet().GetOrCreateInlinePartRule(part).Set(property, color);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty property, float value)
	{
		GetOrCreateInlineSheet().GetOrCreateInlinePartRule(part).Set(property, value);
		Invalidate();
	}

	/// CONSUMES the caller's reference, and releases whatever this part's property held before.
	public void SetPartStyle(StringView part, StyleProperty property, Drawable drawable)
	{
		let sheet = GetOrCreateInlineSheet();
		let rule = sheet.GetOrCreateInlinePartRule(part);
		ReleasePreviousDrawable(sheet, rule, property, drawable);
		sheet.OwnDrawable(drawable);
		rule.Set(property, drawable);
		Invalidate();
	}

	/// Drops the drawable a rule's property currently holds, if the inline sheet owns it.
	///
	/// Guarded against setting the SAME drawable twice: releasing it there would free something
	/// the rule is about to point at again.
	private static void ReleasePreviousDrawable(StyleSheet sheet, StyleRule rule,
		StyleProperty property, Drawable replacement)
	{
		let existing = rule.GetValue(property);
		if (existing == null)
			return;

		let previous = existing.Value.AsDrawable;
		if ((previous == null) || (previous == replacement))
			return;

		sheet.DisownDrawable(previous);
	}

	/// Removes one inline override.
	public void ClearInlineStyle(StyleProperty property)
	{
		if (mInlineSheet == null)
			return;
		let rule = mInlineSheet.FindInlineElementRule();
		if ((rule != null) && rule.Remove(property))
			Invalidate();
	}

	/// Removes EVERY inline override, element and part alike.
	///
	/// Drops the whole sheet, releasing every rule and every drawable those rules held; the
	/// next SetStyle makes a fresh one.
	public void ClearInlineStyles()
	{
		if ((mInlineSheet == null) || mInlineSheet.IsEmpty)
			return;
		mInlineSheet.ReleaseRef();
		mInlineSheet = null;
		Invalidate();
	}

	/// The inline override for a property, or None.
	public StyleValue GetInlineStyle(StyleProperty property)
	{
		if (mInlineSheet == null)
			return .None;
		let rule = mInlineSheet.FindInlineElementRule();
		if (rule == null)
			return .None;
		let value = rule.GetValue(property);
		return (value != null) ? value.Value : StyleValue.None;
	}

	public bool HasInlineStyle(StyleProperty property) => !GetInlineStyle(property).IsNone;

	// ---- The cascade cache ---------------------------------------------------------------------

	/// Brings the cache up to date and answers it.
	private StyleCache EnsureStyleCache()
	{
		let state = GetControlState();
		let generation = (Context != null) ? Context.StyleGeneration : 0;

		// The chain: the sheets this cache keys on, and the local sheets it collects from.
		let chain = scope List<View>();
		// Explicitly uint32: `0u` is pointer sized uint in Beef.
		uint32 chainVersion = 0;

		if ((Context != null) && (Context.GetStyleSheet() != null))
			chainVersion += Context.GetStyleSheet().Version;

		var ancestor = this;
		while ((ancestor != null) && (chain.Count < cMaxSheetChainDepth))
		{
			if (ancestor.mLocalStyleSheet != null)
			{
				chain.Add(ancestor);
				chainVersion += ancestor.mLocalStyleSheet.Version;
			}
			ancestor = ancestor.Parent;
		}
		if (mInlineSheet != null)
			chainVersion += mInlineSheet.Version;

		let sheetEpoch = (Context != null) ? Context.SheetEpoch : 0;

		// Without a context there is no generation to key on, so a class edit on this view
		// would go unseen and the cache is rebuilt every time.
		if (mStyleCache.Valid && (Context != null) && (mStyleCache.Generation == generation)
			&& (mStyleCache.ChainVersion == chainVersion) && (mStyleCache.State == state)
			&& (mStyleCache.SheetEpoch == sheetEpoch))
			return mStyleCache;

		// The transition trigger remembers the OLD winners, but only when their rule pointers
		// are provably alive: the same sheet epoch and the same summed versions, meaning only
		// the generation or the state moved. A sheet swap or a rule edit rebuilds without
		// animating, because the old pointers may be dangling.
		let canTransition = mStyleCache.Valid && (Context != null)
			&& (mStyleCache.SheetEpoch == sheetEpoch)
			&& (mStyleCache.ChainVersion == chainVersion);
		let oldState = mStyleCache.State;
		StyleRule[cPropertyCount] oldWinners = .();

		if (canTransition)
		{
			for (int p < cPropertyCount)
				oldWinners[p] = mStyleCache.Winners[p];
		}
		else if (mTransitionState != null)
		{
			// The rules moved under a running transition, so its targets are stale. It ends
			// here and the new cascade value applies at once.
			mTransitionState.Active.Clear();
			mTransitionState.StateBlendActive = false;
		}

		mStyleCache.Rules.Clear();

		// Ascending cascade order: the context sheet, then the local sheets from the
		// OUTERMOST ancestor inward so a nearer one wins, then this view's inline sheet,
		// which wins over everything.
		if ((Context != null) && (Context.GetStyleSheet() != null))
			Context.GetStyleSheet().CollectMatching(this, state, default, mStyleCache.Rules);

		for (int i = chain.Count - 1; i >= 0; i--)
			chain[i].mLocalStyleSheet.CollectMatching(this, state, default, mStyleCache.Rules);

		if (mInlineSheet != null)
			mInlineSheet.CollectMatching(this, state, default, mStyleCache.Rules);

		for (int p < cPropertyCount)
			mStyleCache.Winners[p] = null;

		// The LAST declaration wins, so walk from the highest priority rule down and let the
		// first fill of each property stand.
		var filled = 0;
		for (int i = mStyleCache.Rules.Count - 1; (i >= 0) && (filled < cPropertyCount); i--)
		{
			let rule = mStyleCache.Rules[i];
			for (int e < rule.PropertyCount)
			{
				let p = (int)rule.GetProperty(e).Prop;
				if ((p < cPropertyCount) && (mStyleCache.Winners[p] == null))
				{
					mStyleCache.Winners[p] = rule;
					filled++;
				}
			}
		}

		mStyleCache.Valid = true;
		mStyleCache.Generation = generation;
		mStyleCache.ChainVersion = chainVersion;
		mStyleCache.SheetEpoch = sheetEpoch;
		mStyleCache.State = state;

		if (canTransition)
			BeginTransitions(oldWinners, oldState, state);

		return mStyleCache;
	}

	/// The cascade's raw winning value, with no keyword or variable resolution.
	private StyleValue RawStyleValue(StyleProperty property)
	{
		let cache = EnsureStyleCache();
		let p = (int)property;
		if ((p >= cPropertyCount) || (cache.Winners[p] == null))
			return .None;

		let value = cache.Winners[p].GetValue(property);
		return (value != null) ? value.Value : StyleValue.None;
	}

	// ---- Keyword and variable resolution -------------------------------------------------------

	private StyleValue ResolveVariableValue(StyleValue reference, int depth)
	{
		let variable = reference.AsVariable;
		if ((variable == null) || (depth > cMaxVariableDepth))
			return .None;

		var value = CustomProperty(variable.Name);
		if (value.IsNone)
			value = variable.Fallback;

		// A fallback may itself be a reference, which is what makes nested fallbacks work.
		if (value.Kind == .Variable)
			return ResolveVariableValue(value, depth + 1);
		return value;
	}

	/// Turns Inherit, Initial and Variable into a concrete value.
	private StyleValue ResolveKeywords(StyleProperty property, StyleValue raw, int depth)
	{
		switch (raw)
		{
		case .Inherit:
			return (Parent != null) ? Parent.ResolveStyle(property) : StyleValue.None;
		case .Initial:
			return .None;
		case .Variable:
			let value = ResolveVariableValue(raw, depth);
			if (value.NeedsResolution && (depth <= cMaxVariableDepth))
				return ResolveKeywords(property, value, depth + 1);
			return value;
		default:
			return raw;
		}
	}

	/// The cascade's value with keywords and inheritance resolved and NO transition overlay:
	/// what ResolveStyle settles on once every transition on this property has finished.
	public StyleValue ComputeStyle(StyleProperty property)
	{
		let raw = RawStyleValue(property);
		if (!raw.IsNone)
		{
			let value = ResolveKeywords(property, raw, 0);
			if (!value.IsNone || (raw.Kind == .Initial))
				return value;
			// An unset variable with no fallback behaves like "unset", so fall through to
			// inheritance rather than answering None.
		}

		if (InheritableStyle.IsInheritable(property) && (Parent != null))
			return Parent.ResolveStyle(property);
		return .None;
	}

	/// The value a consumer should use RIGHT NOW: the cascade, with any running transition on
	/// this property overlaid.
	public StyleValue ResolveStyle(StyleProperty property)
	{
		let value = ComputeStyle(property);
		if (mTransitionState == null)
			return value;

		for (let transition in mTransitionState.Active)
		{
			if (transition.Property != property)
				continue;
			// A drawable does not interpolate: the DRAW path cross fades it instead.
			if (transition.To.Kind == .Drawable)
				return value;
			return StyleValueOps.Lerp(transition.From, transition.To,
				TransitionProgress(transition.Elapsed, transition.Duration, transition.Delay,
					transition.Easing));
		}
		return value;
	}

	/// A custom property, `--name` with the dashes, inherited through the parent chain.
	///
	/// Also the custom layout extension point: a container reads a per child value the uniform
	/// LayoutStyle has no field for.
	public StyleValue CustomProperty(StringView name)
	{
		let hash = HashText(name);
		var view = this;
		while (view != null)
		{
			let cache = view.EnsureStyleCache();
			for (int i = cache.Rules.Count - 1; i >= 0; i--)
			{
				let value = cache.Rules[i].FindCustom(hash, name);
				if (value == null)
					continue;
				if (value.Value.Kind == .Variable)
					return view.ResolveVariableValue(value.Value, 1);
				return value.Value;
			}
			view = view.Parent;
		}
		return .None;
	}

	// ---- Typed resolution ----------------------------------------------------------------------

	public Color ResolveStyleColor(StyleProperty property, Color defaultValue = Color.White)
	{
		let value = ResolveStyle(property).AsColor;
		return (value != null) ? value.Value : defaultValue;
	}

	public Thickness ResolveStyleThickness(StyleProperty property, Thickness defaultValue = .())
	{
		let value = ResolveStyle(property).AsThickness;
		return (value != null) ? value.Value : defaultValue;
	}

	/// Borrowed, and null when nothing sets it.
	public Drawable ResolveStyleDrawable(StyleProperty property) =>
		ResolveStyle(property).AsDrawable;

	/// A Length valued property resolved against a reference box and this view's font size.
	public float ResolveStyleLength(StyleProperty property, float referenceSize,
		float defaultValue = 0.0f)
	{
		let value = ResolveStyle(property);

		let plain = value.AsFloat;
		if (plain != null)
			return plain.Value;

		let length = value.AsLength;
		if (length == null)
			return defaultValue;

		// em is of this view's COMPUTED font size, which for font-size itself is the PARENT's,
		// as in CSS, so `font-size: 1.5em` compounds down the tree instead of resolving
		// against itself.
		let fontSize = (property == .FontSize)
			? ((Parent != null) ? Parent.ResolveStyleLength(.FontSize, 0.0f, 16.0f) : 16.0f)
			: ResolveStyleLength(.FontSize, 0.0f, 16.0f);

		let root = Root();
		let dpiScale = Max(RootDpiScale(root), 0.01f);
		return length.Value.Resolve(dpiScale, referenceSize, fontSize);
	}

	/// A Float property, which a Length also satisfies by resolving against this view's font
	/// size. That is what lets `font-size: 1.2em` or `corner-radius: 0.5em` in a theme reach
	/// every control that only ever reads floats.
	///
	/// A percentage has no reference box on this path and reads as nought.
	public float ResolveStyleFloat(StyleProperty property, float defaultValue = 0.0f)
	{
		let value = ResolveStyle(property);

		let plain = value.AsFloat;
		if (plain != null)
			return plain.Value;
		if (value.Kind == .Length)
			return ResolveStyleLength(property, 0.0f, defaultValue);
		return defaultValue;
	}

	/// Appends the resolved string value, or the default when nothing sets one.
	public void ResolveStyleString(StyleProperty property, String outValue,
		StringView defaultValue = default)
	{
		let value = ResolveStyle(property).AsString;
		outValue.Append((value != null) ? value.Value : defaultValue);
	}

	/// Appends the effective font family: the FontFamily cascade, falling back to the active
	/// font service's default.
	///
	/// Appended to a caller's String rather than returned, because ResolveStyle hands back a
	/// StyleValue by value and the StringView inside it borrows from that temporary; a view
	/// returned from here would dangle.
	public void ResolveStyleFontFamily(String outFamily)
	{
		// Held in a NAMED local: AsString borrows into the value, which would dangle if the
		// temporary died at the end of the expression.
		let family = ResolveStyle(.FontFamily);
		if (let name = family.AsString)
		{
			outFamily.Append(name);
			return;
		}

		if ((Context != null) && (Context.FontService != null))
			Context.FontService.GetDefaultFontFamily(outFamily);
	}

	/// The same, but a non empty per instance override WINS. A control with its own typed
	/// FontFamily property calls this so the property beats the sheet.
	public void ResolveStyleFontFamily(String outFamily, StringView instanceOverride)
	{
		if (!instanceOverride.IsEmpty)
		{
			outFamily.Append(instanceOverride);
			return;
		}
		ResolveStyleFontFamily(outFamily);
	}

	// ---- Pseudo elements -----------------------------------------------------------------------

	/// A pseudo element's value: the same cascade order as the element, but UNCACHED, because
	/// a part's state varies from draw to draw and caching it would key on the wrong thing.
	public StyleValue ResolvePartStyle(StringView part, StyleProperty property,
		ControlState partState)
	{
		let rules = scope List<StyleRule>();

		if ((Context != null) && (Context.GetStyleSheet() != null))
			Context.GetStyleSheet().CollectMatching(this, partState, part, rules);

		let chain = scope List<View>();
		var ancestor = this;
		while ((ancestor != null) && (chain.Count < cMaxSheetChainDepth))
		{
			if (ancestor.mLocalStyleSheet != null)
				chain.Add(ancestor);
			ancestor = ancestor.Parent;
		}
		for (int i = chain.Count - 1; i >= 0; i--)
			chain[i].mLocalStyleSheet.CollectMatching(this, partState, part, rules);

		if (mInlineSheet != null)
			mInlineSheet.CollectMatching(this, partState, part, rules);

		for (int i = rules.Count - 1; i >= 0; i--)
		{
			let value = rules[i].GetValue(property);
			if (value != null)
				return ResolveKeywords(property, value.Value, 0);
		}
		return .None;
	}

	/// Borrowed, and null when the part declares no drawable.
	public Drawable ResolvePartDrawable(StringView part, StyleProperty property,
		ControlState partState) =>
		ResolvePartStyle(part, property, partState).AsDrawable;

	public Color ResolvePartColor(StringView part, StyleProperty property,
		ControlState partState, Color defaultValue = Color.White)
	{
		let value = ResolvePartStyle(part, property, partState).AsColor;
		return (value != null) ? value.Value : defaultValue;
	}

	public float ResolvePartFloat(StringView part, StyleProperty property,
		ControlState partState, float defaultValue = 0.0f)
	{
		let value = ResolvePartStyle(part, property, partState).AsFloat;
		return (value != null) ? value.Value : defaultValue;
	}

	// ---- Transitions ---------------------------------------------------------------------------

	private static float ApplyTransitionEasing(TransitionEasing easing, float t)
	{
		switch (easing)
		{
		case .Linear:
			return t;
		case .EaseIn:
			return t * t;
		case .EaseOut:
			return 1.0f - (1.0f - t) * (1.0f - t);
		// Ease and EaseInOut are the same quadratic curve here; these are not CSS's cubic
		// beziers.
		case .Ease, .EaseInOut:
			return (t < 0.5f) ? (2.0f * t * t) : (1.0f - 2.0f * (1.0f - t) * (1.0f - t));
		}
	}

	private static float TransitionProgress(float elapsed, float duration, float delay,
		TransitionEasing easing)
	{
		// A zero duration is finished the moment it starts.
		if (duration <= 0.0f)
			return 1.0f;
		return ApplyTransitionEasing(easing, Clamp((elapsed - delay) / duration, 0.0f, 1.0f));
	}

	public int ActiveTransitionCount =>
		(mTransitionState != null) ? mTransitionState.Active.Count : 0;

	public bool IsTransitioning =>
		(mTransitionState != null)
		&& (!mTransitionState.Active.IsEmpty || mTransitionState.StateBlendActive);

	private void RegisterTransitioning()
	{
		if (!mTransitionRegistered && (Context != null))
		{
			Context.RegisterTransitioning(this);
			mTransitionRegistered = true;
		}
	}

	/// Whether the context currently ticks this view. Read by DetachView, which must de-list
	/// it before the context loses sight of it.
	public bool IsTransitionRegistered => mTransitionRegistered;

	public void ClearTransitions()
	{
		DeleteAndNullify!(mTransitionState);
		mTransitionRegistered = false;
	}

	/// Advances every running transition. True while any is still going.
	public bool AdvanceTransitions(float deltaTime)
	{
		if (mTransitionState == null)
		{
			mTransitionRegistered = false;
			return false;
		}

		var layoutDamage = false;
		for (int i = mTransitionState.Active.Count - 1; i >= 0; i--)
		{
			var transition = mTransitionState.Active[i];
			transition.Elapsed += deltaTime;
			mTransitionState.Active[i] = transition;

			// The PROPERTY's kind decides the damage, never the rule's.
			if (!StylePropertyKinds.IsVisualOnly(transition.Property))
				layoutDamage = true;

			// Finished: the cascade value takes over, being the same as To.
			if (transition.Elapsed >= transition.Delay + transition.Duration)
				mTransitionState.Active.RemoveAtFast(i);
		}

		if (mTransitionState.StateBlendActive)
		{
			mTransitionState.BlendElapsed += deltaTime;
			if (mTransitionState.BlendElapsed
				>= mTransitionState.BlendDelay + mTransitionState.BlendDuration)
				mTransitionState.StateBlendActive = false;
		}

		if (layoutDamage)
			Invalidate();
		else
			InvalidateVisual();

		let active = !mTransitionState.Active.IsEmpty || mTransitionState.StateBlendActive;
		if (!active)
			mTransitionRegistered = false;
		return active;
	}

	/// What the draw path should blend for this view right now.
	public DrawBlend CurrentDrawBlend()
	{
		DrawBlend blend = .();
		if (mTransitionState == null)
			return blend;

		if (mTransitionState.StateBlendActive)
		{
			blend.StateActive = true;
			blend.FromState = mTransitionState.BlendFrom;
			blend.ToState = mTransitionState.BlendTo;
			blend.StateT = TransitionProgress(mTransitionState.BlendElapsed,
				mTransitionState.BlendDuration, mTransitionState.BlendDelay,
				mTransitionState.BlendEasing);
		}

		for (let transition in mTransitionState.Active)
		{
			if ((transition.Property == .Background) && (transition.From.Kind == .Drawable))
			{
				blend.FromDrawable = transition.From.AsDrawable;
				blend.ToDrawable = transition.To.AsDrawable;
				blend.DrawableT = TransitionProgress(transition.Elapsed, transition.Duration,
					transition.Delay, transition.Easing);
			}
		}
		return blend;
	}

	/// After a cache rebuild: for every animatable property whose WINNING RULE changed, start
	/// or retarget a transition; and cross fade the control state when it moved.
	///
	/// Comparing winning RULES rather than values is what makes a theme wide
	/// `View { transition }` affordable: the same rule under the same sheets is the same
	/// value, so nothing is resolved unless a winner actually changed.
	private void BeginTransitions(StyleRule[cPropertyCount] oldWinners, ControlState oldState,
		ControlState newState)
	{
		let specs = ComputeStyle(.Transition).AsTransitions;
		if ((specs == null) || specs.Specs.IsEmpty)
			return;

		var started = false;

		for (int p < cPropertyCount)
		{
			let property = (StyleProperty)p;
			if (!StylePropertyKinds.IsAnimatable(property))
				continue;

			let oldRule = oldWinners[p];
			let newRule = mStyleCache.Winners[p];
			if (oldRule == newRule)
				continue;

			let spec = specs.Find(property);
			if ((spec == null) || (spec.Value.Duration <= 0.0f))
				continue;

			// From: a running entry's CURRENT value, so a re-trigger never snaps; else the
			// old rule's value; else what the view inherited before, for an inheritable
			// property that had no rule of its own.
			int entryIndex = -1;
			if (mTransitionState != null)
			{
				for (int i < mTransitionState.Active.Count)
				{
					if (mTransitionState.Active[i].Property == property)
						entryIndex = i;
				}
			}

			StyleValue from = .None;
			if (entryIndex >= 0)
			{
				let entry = mTransitionState.Active[entryIndex];
				from = StyleValueOps.Lerp(entry.From, entry.To,
					TransitionProgress(entry.Elapsed, entry.Duration, entry.Delay, entry.Easing));
			}
			else if (oldRule != null)
			{
				let raw = oldRule.GetValue(property);
				if (raw != null)
					from = ResolveKeywords(property, raw.Value, 0);
			}
			else if (InheritableStyle.IsInheritable(property) && (Parent != null))
			{
				from = Parent.ResolveStyle(property);
			}

			if (from.IsNone)
				continue;

			let to = ComputeStyle(property);
			if (to.IsNone || StyleValueOps.Equivalent(from, to)
				|| !StyleValueOps.Interpolable(from, to))
				continue;

			// A background whose old value was not a drawable has nothing to cross fade from.
			if ((property == .Background) && (from.Kind != .Drawable))
				continue;

			if (mTransitionState == null)
				mTransitionState = new .();

			StyleTransition entry = .();
			entry.Property = property;
			entry.From = from;
			entry.To = to;
			entry.Elapsed = 0.0f;
			entry.Duration = spec.Value.Duration;
			entry.Delay = spec.Value.Delay;
			entry.Easing = spec.Value.Easing;

			if (entryIndex >= 0)
				mTransitionState.Active[entryIndex] = entry;
			else
				mTransitionState.Active.Add(entry);
			started = true;
		}

		if (newState != oldState)
		{
			// A state aware drawable picks its colours INSIDE Draw, invisible to the cascade,
			// so the whole background cross fades between the two states under the
			// `background` entry.
			let spec = specs.Find(.Background);
			if ((spec != null) && (spec.Value.Duration > 0.0f))
			{
				if (mTransitionState == null)
					mTransitionState = new .();

				var from = oldState;
				if (mTransitionState.StateBlendActive)
				{
					// Retargeting mid blend: start from whichever state is currently the more
					// visible of the two.
					let t = TransitionProgress(mTransitionState.BlendElapsed,
						mTransitionState.BlendDuration, mTransitionState.BlendDelay,
						mTransitionState.BlendEasing);
					from = (t < 0.5f) ? mTransitionState.BlendFrom : mTransitionState.BlendTo;
				}

				mTransitionState.StateBlendActive = from != newState;
				mTransitionState.BlendFrom = from;
				mTransitionState.BlendTo = newState;
				mTransitionState.BlendElapsed = 0.0f;
				mTransitionState.BlendDuration = spec.Value.Duration;
				mTransitionState.BlendDelay = spec.Value.Delay;
				mTransitionState.BlendEasing = spec.Value.Easing;
				started = started || mTransitionState.StateBlendActive;
			}
		}

		if (started)
			RegisterTransitioning();
	}
}
