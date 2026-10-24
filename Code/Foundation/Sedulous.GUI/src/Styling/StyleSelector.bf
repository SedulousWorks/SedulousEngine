using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// CSS selector matching (started from eepp's css/StyleSheetSelector). A StyleSelector is a chain
// of compound selectors joined by combinators: descendant (space), child (>), adjacent sibling (+)
// and general sibling (~). A compound constrains the tag, #id, .classes, [attributes] and
// :pseudo-classes of one widget:
//
// - state: :hover, :active, :focus, :focus-visible, :focus-within, :disabled, :enabled, and the
//   widget's own (:checked, :indeterminate, :read-only, :read-write, :placeholder-shown, :selected,
//   :drop-target and :drag-source), which a widget reports through UIWidget.WidgetStates, and
//   :leaving and :entering (Node.Leave, Node.Enter);
// - structure: :first-child, :last-child, :only-child, :first-of-type, :last-of-type, :empty,
//   :nth-child(), :nth-last-child(), :nth-of-type(), :nth-last-of-type() (an+b, odd, even);
// - logic: :not(), :is() and :where() over selector lists;
// - attributes: [name], [name=value], ^=, $=, *=, ~= and |=, read from the widget's id, classes
//   and reflected properties by their CSS names (`checked`, `placeholder`, `text`, ...).
//
// A pseudo-class the GUI does not know makes its rule match nothing (eepp's rule), so a typo
// does not widen a rule. Matching backtracks through the combinators, as CSS's does.
//
// A compound and a selector own their lists (nested selectors among them), so each is a class,
// with a deep Set.

/// How a compound relates to the one on its left.
enum Combinator : uint8
{
	/// `a b`
	Descendant,
	/// `a > b`
	Child,
	/// `a + b`: b right after a
	Adjacent,
	/// `a ~ b`: b after a, among the same parent's children
	Sibling,
}

static
{
	// The pseudo-classes a compound can require, as flags; those that follow a node's state are
	// its Node StyleState bits. Constants, as they are combined and kept as a uint32.
	public const uint32 PseudoNone = 0;
	public const uint32 PseudoHover = Node.StateHover;
	public const uint32 PseudoFocus = Node.StateFocus;
	public const uint32 PseudoActive = Node.StateActive;
	public const uint32 PseudoDisabled = Node.StateDisabled;
	public const uint32 PseudoFocusVisible = Node.StateFocusVisible;
	public const uint32 PseudoEnabled = Node.StateEnabled;
	public const uint32 PseudoFocusWithin = Node.StateFocusWithin;
	public const uint32 PseudoChecked = Node.StateChecked;
	public const uint32 PseudoIndeterminate = Node.StateIndeterminate;
	public const uint32 PseudoReadOnly = Node.StateReadOnly;
	public const uint32 PseudoReadWrite = Node.StateReadWrite;
	public const uint32 PseudoPlaceholderShown = Node.StatePlaceholderShown;
	public const uint32 PseudoEmpty = 1U << 12;
	public const uint32 PseudoFirstChild = 1U << 13;
	public const uint32 PseudoLastChild = 1U << 14;
	public const uint32 PseudoOnlyChild = 1U << 15;
	public const uint32 PseudoFirstOfType = 1U << 16;
	public const uint32 PseudoLastOfType = 1U << 17;
	public const uint32 PseudoSelected = Node.StateSelected;
	/// A drag would drop here.
	public const uint32 PseudoDropTarget = Node.StateDropTarget;
	/// It is being dragged.
	public const uint32 PseudoDragSource = Node.StateDragSource;
	/// A widget at the top of its tree, under no widget (where a theme's tokens go, so every
	/// widget inherits them and a subtree can override them).
	public const uint32 PseudoRoot = 1U << 21;
	/// On its way out: Node.Leave, until its exit ends and it goes.
	public const uint32 PseudoLeaving = Node.StateLeaving;
	/// On its way in: Node.Enter, until its entrance ends.
	public const uint32 PseudoEntering = Node.StateEntering;

	/// The pseudo-classes that follow interaction (what `applyPseudo = false` ignores).
	public const uint32 cDynamicPseudoClasses = PseudoHover | PseudoFocus | PseudoActive | PseudoDisabled | PseudoFocusVisible |
		PseudoEnabled | PseudoFocusWithin | PseudoChecked | PseudoIndeterminate | PseudoReadOnly | PseudoReadWrite |
		PseudoPlaceholderShown | PseudoSelected | PseudoDropTarget | PseudoDragSource | PseudoLeaving | PseudoEntering;
}

/// `:nth-child(an+b)` and its kin: the positions an+b (n = 0, 1, 2, ...), 1-based.
struct NthPattern
{
	public int32 A = 0;
	public int32 B = 1;
	/// Count siblings of the same tag only.
	public bool OfType = false;
	/// Count from the last sibling.
	public bool FromEnd = false;

	public this() { }

	public this(int32 a, int32 b)
	{
		A = a;
		B = b;
	}

	public bool Matches(int32 position)
	{
		if (A == 0)
			return position == B;
		let steps = position - B;
		return (steps % A == 0) && (steps / A >= 0);
	}
}

/// `[name]`, `[name=value]` and the substring forms. A class: it owns its two strings.
class AttributeTest
{
	public enum Op : uint8
	{
		Exists,
		/// =
		Equals,
		/// ^=
		Prefix,
		/// $=
		Suffix,
		/// *=
		Contains,
		/// ~= (one of its space-separated words)
		Word,
		/// |= (equal, or followed by a dash)
		Dash,
	}

	public String Name = new .() ~ delete _;
	public Op Operation = .Exists;
	public String Value = new .() ~ delete _;

	public void Set(AttributeTest other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Operation = other.Operation;
		Value.Set(other.Value);
	}
}

/// One compound selector (e.g. "button#ok.primary:hover") plus the combinator that relates it
/// to the compound on its left.
class StyleSelectorRule
{
	private const uint32 cPositionPseudoClasses = PseudoFirstChild | PseudoLastChild | PseudoOnlyChild | PseudoFirstOfType | PseudoLastOfType;

	private String mTag = new .() ~ delete _;
	private String mId = new .() ~ delete _;
	private String mPseudoElement = new .() ~ delete _;
	private uint32 mPartPseudo = 0; // pseudo-classes after the part: the part's states
	private List<String> mClasses = new .() ~ DeleteContainerAndItems!(_);
	private List<AttributeTest> mAttributes = new .() ~ DeleteContainerAndItems!(_);
	private List<NthPattern> mNths = new .() ~ delete _;
	private List<String> mLangs = new .() ~ DeleteContainerAndItems!(_); // :lang(list): the widget's language is one of them or under one
	private List<StyleSelector> mNot = new .() ~ DeleteContainerAndItems!(_); // :not(list): matches none
	private List<StyleSelector> mIs = new .() ~ DeleteContainerAndItems!(_); // :is(list): matches one
	private List<StyleSelector> mWhere = new .() ~ DeleteContainerAndItems!(_); // :where(list): as :is, adding no specificity
	private uint32 mPseudo = PseudoNone;
	private bool mNever = false;
	private Sedulous.GUI.Combinator mCombinator = .Descendant;
	private int64 mSpecificity = 0;

	public this()
	{
	}

	public this(StringView fragment, Sedulous.GUI.Combinator combinator)
	{
		mCombinator = combinator;
		Parse(fragment);
	}

	/// Makes this a copy of `other`, its nested selectors included.
	public void Set(StyleSelectorRule other)
	{
		if (other === this)
			return;
		mTag.Set(other.mTag);
		mId.Set(other.mId);
		mPseudoElement.Set(other.mPseudoElement);
		mPartPseudo = other.mPartPseudo;
		ClearAndDeleteItems!(mClasses);
		for (let c in other.mClasses)
			mClasses.Add(new String(c));
		ClearAndDeleteItems!(mAttributes);
		for (let a in other.mAttributes)
		{
			let copy = new AttributeTest();
			copy.Set(a);
			mAttributes.Add(copy);
		}
		mNths.Clear();
		mNths.AddRange(other.mNths);
		ClearAndDeleteItems!(mLangs);
		for (let l in other.mLangs)
			mLangs.Add(new String(l));
		CopySelectors(other.mNot, mNot);
		CopySelectors(other.mIs, mIs);
		CopySelectors(other.mWhere, mWhere);
		mPseudo = other.mPseudo;
		mNever = other.mNever;
		mCombinator = other.mCombinator;
		mSpecificity = other.mSpecificity;
	}

	private static void CopySelectors(List<StyleSelector> from, List<StyleSelector> into)
	{
		ClearAndDeleteItems!(into);
		for (let s in from)
		{
			let copy = new StyleSelector();
			copy.Set(s);
			into.Add(copy);
		}
	}

	public Sedulous.GUI.Combinator Combinator => mCombinator;
	public int64 Specificity => mSpecificity;
	public StringView Tag => mTag;
	public StringView Id => mId;
	public Span<String> Classes => mClasses;
	public uint32 PseudoClasses => mPseudo;
	// The `::part` pseudo-element (empty = none): its declarations style a widget part.
	public StringView PseudoElement => mPseudoElement;
	/// The part's own states it asks for (`::scrollbar-thumb:hover`): :hover and :active after
	/// the part, which the widget reports for it (PartStates).
	public uint32 PartPseudoClasses => mPartPseudo;
	/// Whether it names a pseudo-class the GUI does not know (it then matches nothing).
	public bool IsNever => mNever;

	/// Whether it asks where the widget stands among its siblings (:nth-child, :first-child,
	/// :last-of-type and their kin).
	public bool ReadsPosition => !mNths.IsEmpty || ((mPseudo & cPositionPseudoClasses) != 0);

	/// The selectors in its :not(), :is() and :where(), in that order: how many, and each.
	public int NestedCount => mNot.Count + mIs.Count + mWhere.Count;

	public StyleSelector GetNested(int index)
	{
		if (index < mNot.Count)
			return mNot[index];
		if (index < mNot.Count + mIs.Count)
			return mIs[index - mNot.Count];
		return mWhere[index - mNot.Count - mIs.Count];
	}

	/// Calls `f(selector)` for each selector in its :not(), :is() and :where().
	public void ForEachNested(delegate void(StyleSelector selector) f)
	{
		for (int k = 0; k < NestedCount; k++)
			f(GetNested(k));
	}

	/// Whether its tag, id, classes and attributes match `element`: it matches there in some
	/// position and state (its pseudo-classes and nested selectors are not asked).
	public bool MatchesIdentity(UIWidget element)
	{
		if (mNever)
			return false;
		if ((mTag.Length != 0) && (mTag != element.Tag))
			return false;
		if ((mId.Length != 0) && (mId != element.Id))
			return false;
		for (let cls in mClasses)
		{
			if (!element.HasClass(cls))
				return false;
		}
		for (let test in mAttributes)
		{
			if (!StyleSelectorDetail.AttributeMatches(test, element))
				return false;
		}
		return true;
	}

	public bool Matches(UIWidget element, bool applyPseudo = true)
	{
		if (mNever)
			return false;
		if ((mTag.Length != 0) && (mTag != element.Tag))
			return false;
		if ((mId.Length != 0) && (mId != element.Id))
			return false;
		for (let cls in mClasses)
		{
			if (!element.HasClass(cls))
				return false;
		}
		for (let test in mAttributes)
		{
			if (!StyleSelectorDetail.AttributeMatches(test, element))
				return false;
		}
		if (!MatchesPseudo(element, applyPseudo))
			return false;
		if (!mLangs.IsEmpty)
		{
			let language = scope String();
			element.Language(language);
			if (!StyleSelectorDetail.LanguageMatches(language, mLangs))
				return false;
		}
		for (let nth in mNths)
		{
			if (!nth.Matches(StyleSelectorDetail.PositionAmongSiblings(element, nth.OfType, nth.FromEnd)))
				return false;
		}
		for (let s in mNot)
		{
			if (s.Select(element, applyPseudo))
				return false;
		}
		bool Any(List<StyleSelector> list)
		{
			for (let s in list)
			{
				if (s.Select(element, applyPseudo))
					return true;
			}
			return false;
		}
		if (!mIs.IsEmpty && !Any(mIs))
			return false;
		if (!mWhere.IsEmpty && !Any(mWhere))
			return false;
		return true;
	}

	private bool MatchesPseudo(UIWidget element, bool applyPseudo)
	{
		let wanted = applyPseudo ? mPseudo : (mPseudo & ~cDynamicPseudoClasses);
		if (wanted == PseudoNone)
			return true;
		let states = element.WidgetStates;
		bool Has(uint32 flag) => (wanted & flag) != 0;
		// A state the inspector forces reads as set; forced disabled is not enabled.
		let forced = element.ForcedStyleStates;
		bool Forcing(uint32 state) => (forced & state) != 0;
		let enabled = element.Enabled && !Forcing(Node.StateDisabled);
		if (Has(PseudoHover) && !element.Hovered && !Forcing(Node.StateHover))
			return false;
		if (Has(PseudoActive) && !element.Pressed && !Forcing(Node.StateActive))
			return false;
		if (Has(PseudoFocusVisible) && !element.FocusVisible && !Forcing(Node.StateFocusVisible))
			return false;
		if (Has(PseudoFocus) && !element.IsFocused && !Forcing(Node.StateFocus) && !Forcing(Node.StateFocusVisible))
			return false;
		if (Has(PseudoFocusWithin) && !element.IsFocusWithin && !Forcing(Node.StateFocusWithin))
			return false;
		if (Has(PseudoDisabled) && enabled)
			return false;
		if (Has(PseudoEnabled) && !enabled)
			return false;
		if (Has(PseudoChecked) && ((states & WidgetStateChecked) == 0) && !Forcing(Node.StateChecked))
			return false;
		if (Has(PseudoIndeterminate) && ((states & WidgetStateIndeterminate) == 0))
			return false;
		if (Has(PseudoReadOnly) && ((states & WidgetStateEditable) != 0))
			return false;
		if (Has(PseudoReadWrite) && ((states & WidgetStateEditable) == 0))
			return false;
		if (Has(PseudoPlaceholderShown) && ((states & WidgetStatePlaceholderShown) == 0))
			return false;
		if (Has(PseudoSelected) && ((states & WidgetStateSelected) == 0))
			return false;
		if (Has(PseudoDropTarget) && !element.IsDropTarget)
			return false;
		if (Has(PseudoDragSource) && !element.IsDragSource)
			return false;
		if (Has(PseudoLeaving) && !element.IsLeaving)
			return false;
		if (Has(PseudoEntering) && !element.IsEntering)
			return false;
		if (Has(PseudoEmpty) && (element.ChildCount != 0))
			return false;
		if (Has(PseudoRoot) && (element.Parent != null) && (element.Parent is UIWidget))
			return false;
		let first = Has(PseudoFirstChild) || Has(PseudoOnlyChild);
		let last = Has(PseudoLastChild) || Has(PseudoOnlyChild);
		if (first && (StyleSelectorDetail.PositionAmongSiblings(element, false, false) != 1))
			return false;
		if (last && (StyleSelectorDetail.PositionAmongSiblings(element, false, true) != 1))
			return false;
		if (Has(PseudoFirstOfType) && (StyleSelectorDetail.PositionAmongSiblings(element, true, false) != 1))
			return false;
		if (Has(PseudoLastOfType) && (StyleSelectorDetail.PositionAmongSiblings(element, true, true) != 1))
			return false;
		return true;
	}

	private void Parse(StringView fragment)
	{
		int i = 0;
		let n = fragment.Length;
		// The text inside a bracket pair starting at `i` (i left after the closing one).
		StringView Enclosed(char8 opening, char8 closing)
		{
			let start = i + 1;
			int32 depth = 0;
			char8 quote = (char8)0;
			for (; i < n; i++)
			{
				let c = fragment[i];
				if (quote != (char8)0)
				{
					if (c == quote)
						quote = (char8)0;
					continue;
				}
				if ((c == '"') || (c == '\''))
					quote = c;
				else if (c == opening)
					depth++;
				else if ((c == closing) && (--depth == 0))
				{
					i++;
					return fragment.Substring(start, i - 1 - start);
				}
			}
			mNever = true; // unclosed
			return fragment.Substring(start, (n > start) ? n - start : 0);
		}
		while (i < n)
		{
			let c = fragment[i];
			if (c == '#')
			{
				i++;
				mId.Set(ParseUtil.ReadIdent(fragment, ref i));
			}
			else if (c == '.')
			{
				i++;
				mClasses.Add(new String(ParseUtil.ReadIdent(fragment, ref i)));
			}
			else if (c == '[')
			{
				mAttributes.Add(StyleSelectorDetail.ParseAttribute(Enclosed('[', ']')));
			}
			else if (c == ':')
			{
				if ((i + 1 < n) && (fragment[i + 1] == ':'))
				{
					i += 2;
					mPseudoElement.Set(ParseUtil.ReadIdent(fragment, ref i));
				}
				else if (mPseudoElement.Length != 0)
				{
					// After the part, a pseudo-class is the part's own state: :hover and :active,
					// the states a part has (any other matches nothing).
					i++;
					let name = ParseUtil.ReadIdent(fragment, ref i);
					if (name == "hover")
						mPartPseudo |= PseudoHover;
					else if (name == "active")
						mPartPseudo |= PseudoActive;
					else
						mNever = true;
				}
				else
				{
					i++;
					let name = ParseUtil.ReadIdent(fragment, ref i);
					if ((i < n) && (fragment[i] == '('))
						ApplyPseudo(name, Enclosed('(', ')'), true);
					else
						ApplyPseudo(name, default, false);
				}
			}
			else if (c == '*')
			{
				i++; // universal: no tag constraint
			}
			else if (ParseUtil.IsIdentChar(c))
			{
				mTag.Set(ParseUtil.ReadIdent(fragment, ref i));
			}
			else
			{
				mNever = true; // a character no selector has
				i++;
			}
		}
		ComputeSpecificity();
	}

	private void ApplyPseudo(StringView name, StringView argument, bool functional)
	{
		if (functional)
		{
			void Selectors(List<StyleSelector> into)
			{
				let parts = scope List<StringView>();
				StyleSelector.SplitList(argument, parts);
				for (let part in parts)
					into.Add(new StyleSelector(part));
				if (into.IsEmpty)
					mNever = true;
			}
			if (name == "not")
				Selectors(mNot);
			else if ((name == "is") || (name == "matches"))
				Selectors(mIs);
			else if (name == "where")
				Selectors(mWhere);
			else if ((name == "nth-child") || (name == "nth-last-child") || (name == "nth-of-type") || (name == "nth-last-of-type"))
			{
				var nth = StyleSelectorDetail.ParseNth(argument);
				if (!nth.HasValue)
				{
					mNever = true;
					return;
				}
				var pattern = nth.Value;
				pattern.OfType = (name == "nth-of-type") || (name == "nth-last-of-type");
				pattern.FromEnd = (name == "nth-last-child") || (name == "nth-last-of-type");
				mNths.Add(pattern);
			}
			else if (name == "lang")
			{
				// :lang(pt) matches pt and pt-BR (a language and its regions); a list matches any.
				let parts = scope List<StringView>();
				StyleSelector.SplitList(argument, parts);
				for (let part in parts)
				{
					let lang = ParseUtil.Trim(part);
					if (lang.Length != 0)
						mLangs.Add(new String(lang));
				}
				if (mLangs.IsEmpty)
					mNever = true;
			}
			else
				mNever = true; // an unknown function
			return;
		}
		for (let named in StyleSelectorDetail.sPseudoNames)
		{
			if (name == named.name)
			{
				mPseudo |= named.flag;
				return;
			}
		}
		mNever = true; // an unknown pseudo-class matches nothing
	}

	private void ComputeSpecificity()
	{
		int64 s = 0;
		if (mId.Length != 0)
			s += StyleSelectorDetail.cSpecificityId;
		int64 classes = (int64)(mClasses.Count + mAttributes.Count + mNths.Count + (mLangs.IsEmpty ? 0 : 1));
		// Its pseudo-classes and its part's states, each one a class's worth (counted apart: the
		// two sets use the same bits).
		uint32[2] sets = .(mPseudo, mPartPseudo);
		for (int k = 0; k < sets.Count; k++)
		{
			var pseudo = sets[k];
			while (pseudo != 0)
			{
				classes += pseudo & 1U;
				pseudo >>= 1;
			}
		}
		s += classes * StyleSelectorDetail.cSpecificityClass;
		if (mTag.Length != 0)
			s += StyleSelectorDetail.cSpecificityTag;
		if (mPseudoElement.Length != 0)
			s += StyleSelectorDetail.cSpecificityTag; // pseudo-elements count as a type
		// :not() and :is() add their most specific argument's; :where() adds nothing.
		int64 Most(List<StyleSelector> list)
		{
			int64 best = 0;
			for (let sel in list)
				best = Math.Max(best, sel.Specificity);
			return best;
		}
		s += Most(mNot) + Most(mIs);
		mSpecificity = s;
	}
}

class StyleSelector
{
	public const uint8 cAncestorKeys = 4;

	private List<StyleSelectorRule> mRules = new .() ~ DeleteContainerAndItems!(_);
	private int64 mSpecificity = 0;
	private uint64[cAncestorKeys] mAncestorKeys = default;
	private uint8 mAncestorKeyCount = 0;

	public this()
	{
	}

	public this(StringView selector)
	{
		Parse(selector);
	}

	/// Makes this a copy of `other`, every compound included.
	public void Set(StyleSelector other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(mRules);
		for (let rule in other.mRules)
		{
			let copy = new StyleSelectorRule();
			copy.Set(rule);
			mRules.Add(copy);
		}
		mSpecificity = other.mSpecificity;
		mAncestorKeys = other.mAncestorKeys;
		mAncestorKeyCount = other.mAncestorKeyCount;
	}

	public int64 Specificity => mSpecificity;
	public bool IsEmpty => mRules.Count == 0;
	public int RuleCount => mRules.Count;
	public StyleSelectorRule RuleAt(int i) => mRules[i];

	/// It can match nothing: a compound names a pseudo-class or function the GUI does not know,
	/// or does not parse (what a cook warns of).
	public bool IsNever
	{
		get
		{
			for (let rule in mRules)
			{
				if (rule.IsNever)
					return true;
			}
			return false;
		}
	}

	// The pseudo-element of the subject (rightmost) rule; empty for a normal selector.
	public StringView PseudoElement => (mRules.Count != 0) ? mRules[mRules.Count - 1].PseudoElement : default;

	/// The part's own states the subject asks for (none for a normal selector).
	public uint32 PartPseudoClasses => (mRules.Count != 0) ? mRules[mRules.Count - 1].PartPseudoClasses : 0;

	/// Hashes of names its subject's ancestors must carry (at most four), for AncestorFilter.
	public Span<uint64> AncestorKeys => .(&mAncestorKeys[0], mAncestorKeyCount);

	// True if `element` matches this selector: the rightmost compound matches it and each one
	// before matches a widget its combinator relates it to (trying every candidate).
	public bool Select(UIWidget element, bool applyPseudo = true) =>
		(mRules.Count != 0) && MatchAt(mRules.Count - 1, element, applyPseudo);

	/// The states this selector reads through an ancestor (`:hover x`, `:focus-within > x`) and
	/// through an earlier sibling (`:checked + x`): a change of one restyles the node's subtree, or
	/// its later siblings. `outer` is where the whole selector sits (inside a compound that is
	/// itself an ancestor's or a sibling's, every state it reads counts there).
	public void CollectRelationStates(ref uint32 ancestor, ref uint32 sibling, uint32 outer = 0, bool outerIsSibling = false)
	{
		for (int i = 0; i < mRules.Count; i++)
		{
			let rule = mRules[i];
			let subject = i + 1 == mRules.Count;
			let states = rule.PseudoClasses & cDynamicPseudoClasses;
			uint32 nestedAncestor = 0;
			uint32 nestedSibling = 0;
			if (subject)
			{
				if (outer != 0)
				{
					if (outerIsSibling)
						sibling |= states;
					else
						ancestor |= states;
				}
				for (int k = 0; k < rule.NestedCount; k++)
					rule.GetNested(k).CollectRelationStates(ref ancestor, ref sibling, outer, outerIsSibling);
				continue;
			}
			let next = mRules[i + 1].Combinator;
			let viaSibling = (next == .Adjacent) || (next == .Sibling);
			for (int k = 0; k < rule.NestedCount; k++)
				rule.GetNested(k).CollectRelationStates(ref nestedAncestor, ref nestedSibling, 1, viaSibling);
			let read = states | nestedAncestor | nestedSibling | AllDynamic(rule);
			if (viaSibling)
				sibling |= read;
			else
				ancestor |= read;
		}
	}

	/// Whether it reads a widget's siblings anywhere (its position among them, or `+` and `~`),
	/// nested selectors included: then a change to the children's arrangement can change what it
	/// matches.
	public bool ReadsSiblings
	{
		get
		{
			for (int i = 0; i < mRules.Count; i++)
			{
				let rule = mRules[i];
				let c = rule.Combinator;
				if (rule.ReadsPosition || ((i > 0) && ((c == .Adjacent) || (c == .Sibling))))
					return true;
				for (int k = 0; k < rule.NestedCount; k++)
				{
					if (rule.GetNested(k).ReadsSiblings)
						return true;
				}
			}
			return false;
		}
	}

	/// Calls `f(compound)` for each compound that reads siblings with a child or descendant step
	/// below it (`.row:first-child` in `.row:first-child .label`; both of `.a + .b` in
	/// `.a + .b .c`), nested selectors included: a rearrangement of a parent's children can then
	/// change what matches inside a child that compound matches, not only the child. Read at the
	/// subject alone (`li:nth-child(odd)`, `.a + .b`), it changes the children only.
	public void ForEachSiblingReadAbove(delegate void(StyleSelectorRule compound) f)
	{
		let n = mRules.Count;
		bool BySibling(Sedulous.GUI.Combinator c) => (c == .Adjacent) || (c == .Sibling);
		for (int i = 0; i < n; i++)
		{
			let rule = mRules[i];
			bool nested = false;
			for (int k = 0; k < rule.NestedCount; k++)
			{
				let s = rule.GetNested(k);
				nested = nested || s.ReadsSiblings;
				s.ForEachSiblingReadAbove(f);
			}
			let reads = rule.ReadsPosition || nested || ((i > 0) && BySibling(rule.Combinator)) ||
				((i + 1 < n) && BySibling(mRules[i + 1].Combinator));
			if (!reads)
				continue;
			for (int j = i + 1; j < n; j++)
			{
				if (!BySibling(mRules[j].Combinator))
				{
					f(rule);
					break;
				}
			}
		}
	}

	/// A comma-separated list split at its top level (commas inside parentheses, brackets or
	/// quotes stay), its parts trimmed and empty ones dropped, added to `outParts`.
	public static void SplitList(StringView list, List<StringView> outParts)
	{
		int start = 0;
		int32 depth = 0;
		char8 quote = (char8)0;
		for (int i = 0; i <= list.Length; i++)
		{
			let c = (i < list.Length) ? list[i] : ',';
			if (quote != (char8)0)
			{
				if (c == quote)
					quote = (char8)0;
				continue;
			}
			if ((c == '"') || (c == '\''))
				quote = c;
			else if ((c == '(') || (c == '['))
				depth++;
			else if ((c == ')') || (c == ']'))
				depth--;
			else if ((c == ',') && (depth <= 0))
			{
				let part = ParseUtil.Trim(list.Substring(start, i - start));
				if (part.Length != 0)
					outParts.Add(part);
				start = i + 1;
			}
		}
	}

	// The widget a combinator steps to.
	public static UIWidget AsWidget(Node n) => n as UIWidget;

	public static UIWidget PreviousSibling(UIWidget element)
	{
		let parent = element.Parent;
		if (parent == null)
			return null;
		var i = parent.GetChildIndex(element);
		while ((i > 0) && (i != Node.cInvalidIndex))
		{
			i--;
			if (let w = AsWidget(parent.GetChildAt(i)))
				return w;
		}
		return null;
	}

	// Every dynamic state a compound's nested selectors read, all positions.
	private static uint32 AllDynamic(StyleSelectorRule rule)
	{
		uint32 all = 0;
		for (int k = 0; k < rule.NestedCount; k++)
		{
			for (let r in rule.GetNested(k).mRules)
				all |= (r.PseudoClasses & cDynamicPseudoClasses) | AllDynamic(r);
		}
		return all;
	}

	private bool MatchAt(int i, UIWidget element, bool applyPseudo)
	{
		if (!mRules[i].Matches(element, applyPseudo))
			return false;
		if (i == 0)
			return true;
		switch (mRules[i].Combinator)
		{
		case .Child:
			let parent = AsWidget(element.Parent);
			return (parent != null) && MatchAt(i - 1, parent, applyPseudo);
		case .Descendant:
			for (var n = element.Parent; n != null; n = n.Parent)
			{
				let w = AsWidget(n);
				if ((w != null) && MatchAt(i - 1, w, applyPseudo))
					return true;
			}
			return false;
		case .Adjacent:
			let previous = PreviousSibling(element);
			return (previous != null) && MatchAt(i - 1, previous, applyPseudo);
		case .Sibling:
			for (var s = PreviousSibling(element); s != null; s = PreviousSibling(s))
			{
				if (MatchAt(i - 1, s, applyPseudo))
					return true;
			}
			return false;
		}
	}

	private void Parse(StringView selector)
	{
		int i = 0;
		let n = selector.Length;
		Sedulous.GUI.Combinator combinator = .Descendant; // relates the next fragment to the previous
		while (i < n)
		{
			while ((i < n) && ParseUtil.IsWhiteSpace(selector[i]))
				i++;
			if (i >= n)
				break;
			let c = selector[i];
			if ((c == '>') || (c == '+') || (c == '~'))
			{
				combinator = (c == '>') ? Sedulous.GUI.Combinator.Child : (c == '+') ? Sedulous.GUI.Combinator.Adjacent : Sedulous.GUI.Combinator.Sibling;
				i++;
				continue;
			}
			// A compound runs to the next whitespace or combinator outside brackets and quotes.
			let start = i;
			int32 depth = 0;
			char8 quote = (char8)0;
			while (i < n)
			{
				let d = selector[i];
				if (quote != (char8)0)
				{
					if (d == quote)
						quote = (char8)0;
				}
				else if ((d == '"') || (d == '\''))
					quote = d;
				else if ((d == '(') || (d == '['))
					depth++;
				else if ((d == ')') || (d == ']'))
					depth--;
				else if ((depth <= 0) && (ParseUtil.IsWhiteSpace(d) || (d == '>') || (d == '+') || (d == '~')))
					break;
				i++;
			}
			mRules.Add(new StyleSelectorRule(selector.Substring(start, i - start), combinator));
			combinator = .Descendant;
		}

		mSpecificity = 0;
		for (let rule in mRules)
			mSpecificity += rule.Specificity;

		// What its subject's ancestors must have: the id, classes and tag of each compound a child
		// or descendant combinator relates to the one on its right (`a > b + c`: a is c's parent
		// too; `a + b > c`: a is only a sibling of c's parent).
		mAncestorKeyCount = 0;
		void Key(StringView name)
		{
			if ((name.Length != 0) && (mAncestorKeyCount < cAncestorKeys))
				mAncestorKeys[mAncestorKeyCount++] = HashText(name);
		}
		for (int r = mRules.Count - 1; r >= 1; r--)
		{
			let c = mRules[r].Combinator;
			if ((c != .Child) && (c != .Descendant))
				continue;
			let ancestor = mRules[r - 1];
			Key(ancestor.Id);
			for (let cls in ancestor.Classes)
				Key(cls);
			Key(ancestor.Tag);
		}
	}
}

/// The names (ids, classes and tags) of the widgets above the one being styled, kept while a
/// restyle walks the tree, so a rule that needs an ancestor none of them has is turned away
/// without walking up (WebKit's SelectorFilter). A counting Bloom filter: two counters per name,
/// so it can say "maybe" wrongly but never "no" wrongly; a counter that fills stays full.
class AncestorFilter
{
	private const int32 cBits = 12;

	private uint8[1 << cBits] mCounts = default;
	private List<uint64> mKeys = new .() ~ delete _; // what each push added, so a pop takes away exactly that
	private List<uint32> mFrames = new .() ~ delete _; // where each push's keys start

	/// `widget`'s names join (it is now above what is styled next).
	public void Push(UIWidget widget)
	{
		mFrames.Add((uint32)mKeys.Count);
		Add(widget.Id);
		for (let cls in widget.Classes)
			Add(cls);
		Add(widget.Tag);
	}

	/// The last pushed widget's names leave (those it had when pushed).
	public void Pop()
	{
		let from = (int)mFrames[mFrames.Count - 1];
		mFrames.PopBack();
		while (mKeys.Count > from)
		{
			let key = mKeys.PopBack();
			Count(key, -1);
		}
	}

	public void Clear()
	{
		mKeys.Clear();
		mFrames.Clear();
		for (int i = 0; i < mCounts.Count; i++)
			mCounts[i] = 0;
	}

	/// False when some ancestor `selector` needs is certainly missing.
	public bool MayMatch(StyleSelector selector)
	{
		for (let key in selector.AncestorKeys)
		{
			if ((mCounts[Slot(key, 0)] == 0) || (mCounts[Slot(key, 1)] == 0))
				return false;
		}
		return true;
	}

	private static uint32 Slot(uint64 key, uint32 which) =>
		(uint32)(key >> (int)(which * 32)) & ((1U << cBits) - 1U);

	private void Add(StringView name)
	{
		if (name.Length == 0)
			return;
		let key = HashText(name);
		mKeys.Add(key);
		Count(key, 1);
	}

	private void Count(uint64 key, int32 delta)
	{
		for (uint32 which = 0; which < 2; which++)
		{
			let slot = Slot(key, which);
			let c = mCounts[slot];
			if (c != 255) // a full counter stays full: it can no longer tell when to empty
				mCounts[slot] = (uint8)((int32)c + delta);
		}
	}
}

/// What StyleSelector.bf keeps out of the public surface: the specificity buckets, the
/// pseudo-class names, and the parsing and reading of a compound's parts.
internal static class StyleSelectorDetail
{
	// CSS specificity buckets (packed, matching eepp: lexicographic id > class > tag).
	public const int64 cSpecificityId = 1048576;
	public const int64 cSpecificityClass = 1024;
	public const int64 cSpecificityTag = 1;

	public static (String name, uint32 flag)[24] sPseudoNames = .(
		("hover", PseudoHover),
		("focus", PseudoFocus),
		("focus-visible", PseudoFocusVisible),
		("focus-within", PseudoFocusWithin),
		("active", PseudoActive),
		("disabled", PseudoDisabled),
		("enabled", PseudoEnabled),
		("checked", PseudoChecked),
		("indeterminate", PseudoIndeterminate),
		("read-only", PseudoReadOnly),
		("read-write", PseudoReadWrite),
		("placeholder-shown", PseudoPlaceholderShown),
		("selected", PseudoSelected),
		("drop-target", PseudoDropTarget),
		("drag-source", PseudoDragSource),
		("leaving", PseudoLeaving),
		("entering", PseudoEntering),
		("empty", PseudoEmpty),
		("root", PseudoRoot),
		("first-child", PseudoFirstChild),
		("last-child", PseudoLastChild),
		("only-child", PseudoOnlyChild),
		("first-of-type", PseudoFirstOfType),
		("last-of-type", PseudoLastOfType));

	// `an+b`, `odd`, `even`, `n`, `-n+3`, `5`.
	public static NthPattern? ParseNth(StringView text)
	{
		let compact = scope String();
		for (int i = 0; i < text.Length; i++)
		{
			if (!ParseUtil.IsWhiteSpace(text[i]))
				compact.Append(text[i]);
		}
		StringView t = compact;
		if (t == "odd")
			return NthPattern(2, 1);
		if (t == "even")
			return NthPattern(2, 0);
		bool Integer(StringView s, out int32 outValue)
		{
			outValue = 0;
			if (s.Length == 0)
				return false;
			int k = 0;
			bool negative = false;
			if ((s[0] == '+') || (s[0] == '-'))
			{
				negative = s[0] == '-';
				k++;
			}
			if (k == s.Length)
				return false;
			int32 v = 0;
			for (; k < s.Length; k++)
			{
				if ((s[k] < '0') || (s[k] > '9'))
					return false;
				v = v * 10 + ((int32)s[k] - (int32)'0');
			}
			outValue = negative ? -v : v;
			return true;
		}
		int nAt = Node.cInvalidIndex;
		for (int i = 0; i < t.Length; i++)
		{
			if ((t[i] == 'n') || (t[i] == 'N'))
				nAt = i;
		}
		NthPattern result = .();
		if (nAt == Node.cInvalidIndex)
		{
			result.A = 0;
			if (!Integer(t, out result.B))
				return null;
			return result;
		}
		let a = t.Substring(0, nAt);
		let b = t.Substring(nAt + 1, t.Length - nAt - 1);
		if ((a.Length == 0) || (a == "+"))
			result.A = 1;
		else if (a == "-")
			result.A = -1;
		else if (!Integer(a, out result.A))
			return null;
		result.B = 0;
		if ((b.Length != 0) && !Integer(b, out result.B))
			return null;
		return result;
	}

	// The text of a widget's attribute, appended to `outText`: its id, its classes, or a reflected
	// property by its CSS name; false when it has no such attribute.
	public static bool AttributeText(UIWidget element, StringView name, String outText)
	{
		if (name == "id")
		{
			if (element.Id.Length == 0)
				return false;
			outText.Append(element.Id);
			return true;
		}
		if (name == "class")
		{
			let start = outText.Length;
			for (let c in element.Classes)
			{
				if (outText.Length != start)
					outText.Append(' ');
				outText.Append(c);
			}
			return outText.Length != start;
		}
		let property = element.GuiType.FindCss(name);
		if (property == null)
			return false;
		var value = property.Get(element);
		defer value.Dispose();
		var text = ConvertVariant(value, typeof(String));
		defer text.Dispose();
		if (!IsText(text))
			return false;
		outText.Append(TextOf(text));
		return true;
	}

	public static bool AttributeMatches(AttributeTest test, UIWidget element)
	{
		let text = scope String();
		if (!AttributeText(element, test.Name, text))
			return false;
		StringView v = text;
		StringView want = test.Value;
		switch (test.Operation)
		{
		case .Exists: return true;
		case .Equals: return v == want;
		case .Prefix: return (want.Length != 0) && (v.Length >= want.Length) && (v.Substring(0, want.Length) == want);
		case .Suffix:
			return (want.Length != 0) && (v.Length >= want.Length) && (v.Substring(v.Length - want.Length, want.Length) == want);
		case .Contains:
			if (want.Length == 0)
				return false;
			for (int i = 0; i + want.Length <= v.Length; i++)
			{
				if (v.Substring(i, want.Length) == want)
					return true;
			}
			return false;
		case .Word:
			let words = scope List<StringView>();
			SplitTopLevel(v, ' ', words);
			for (let word in words)
			{
				if (word == want)
					return true;
			}
			return false;
		case .Dash:
			return (v == want) || ((v.Length > want.Length) && (v.Substring(0, want.Length) == want) && (v[want.Length] == '-'));
		}
	}

	// `[name op "value"]` (the brackets removed). The caller owns what comes back.
	public static AttributeTest ParseAttribute(StringView inner)
	{
		let test = new AttributeTest();
		int i = 0;
		while ((i < inner.Length) && ParseUtil.IsWhiteSpace(inner[i]))
			i++;
		let nameStart = i;
		while ((i < inner.Length) && ParseUtil.IsIdentChar(inner[i]))
			i++;
		test.Name.Set(inner.Substring(nameStart, i - nameStart));
		while ((i < inner.Length) && ParseUtil.IsWhiteSpace(inner[i]))
			i++;
		if (i >= inner.Length)
			return test;
		let c = inner[i];
		if (c == '=')
		{
			test.Operation = .Equals;
			i++;
		}
		else if ((i + 1 < inner.Length) && (inner[i + 1] == '='))
		{
			test.Operation = (c == '^') ? AttributeTest.Op.Prefix : (c == '$') ? AttributeTest.Op.Suffix : (c == '*') ? AttributeTest.Op.Contains :
				(c == '~') ? AttributeTest.Op.Word : AttributeTest.Op.Dash;
			i += 2;
		}
		var value = ParseUtil.Trim(inner.Substring(i, inner.Length - i));
		if ((value.Length >= 2) && ((value[0] == '"') || (value[0] == '\'')) && (value[value.Length - 1] == value[0]))
			value = value.Substring(1, value.Length - 2);
		test.Value.Set(value);
		return test;
	}

	// Whether `language` is one of `ranges` or a sub-language of one (`pt-BR` under `pt`),
	// ignoring case and `_` against `-`.
	public static bool LanguageMatches(StringView language, List<String> ranges)
	{
		char8 Lower(char8 c) => (c == '_') ? '-' : ((c >= 'A') && (c <= 'Z')) ? (char8)((int32)c - (int32)'A' + (int32)'a') : c;
		for (let range in ranges)
		{
			StringView r = range;
			if (r.Length > language.Length)
				continue;
			bool same = true;
			for (int i = 0; same && (i < r.Length); i++)
				same = Lower(r[i]) == Lower(language[i]);
			if (same && ((r.Length == language.Length) || (language[r.Length] == '-') || (language[r.Length] == '_')))
				return true;
		}
		return false;
	}

	// The 1-based position of `element` among its parent's widgets (of its tag when `ofType`),
	// from the start or the end.
	public static int32 PositionAmongSiblings(UIWidget element, bool ofType, bool fromEnd)
	{
		if (!ofType)
		{
			element.PositionAmongWidgets(let at, let total);
			return fromEnd ? total - at + 1 : at;
		}
		let parent = element.Parent;
		if (parent == null)
			return 1;
		int32 position = 0;
		let count = parent.ChildCount;
		for (int k = 0; k < count; k++)
		{
			let i = fromEnd ? count - 1 - k : k;
			let w = StyleSelector.AsWidget(parent.GetChildAt(i));
			if ((w == null) || (ofType && (w.Tag != element.Tag)))
				continue;
			position++;
			if (w == element)
				return position;
		}
		return position;
	}
}
