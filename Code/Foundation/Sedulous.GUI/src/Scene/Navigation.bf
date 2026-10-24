using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Directional focus navigation, automatic by default: a geometric picker takes the best focusable
// widget in the pressed direction, so most screens need no authoring. A candidate must lie beyond
// the focused widget in that direction; those overlapping it on the cross axis come first (a
// row's neighbour before a widget diagonally nearer), then the nearest along the axis, then the
// nearest across it. Hidden, disabled and clipped-away widgets are skipped.
//
// Where the geometry is wrong, a widget says where a direction goes (nav-up and the rest: an id,
// or none to stop), which is followed first.
//
// Focus scopes (Node.NavScope) bound the search: navigation stays inside the focused widget's
// scope, and at its edge passes to the scope around it, wraps to the scope's other side, or stays
// (contain, for a dialog). Entering a scope from outside lands on what was last focused in it, else
// on its default focus, else on the picked widget.

enum NavDirection : uint8
{
	Up,
	Down,
	Left,
	Right,
}

/// What became of one candidate of a directional move.
enum NavVerdict : uint8
{
	/// The best: focus went there (or into the scope holding it).
	Chosen,
	/// Beyond the focused widget that way, with a worse score.
	Beaten,
	/// Not beyond it that way.
	Behind,
	/// Hidden by a clipping ancestor.
	Clipped,
}

/// One candidate a directional move weighed: where it was (in the GUI's world), its name, its
/// score (lower is better; at 1e6 and over, one not overlapping the focused widget across the
/// move) and what became of it. A class: it owns its name.
class NavCandidate
{
	public Rect Bounds = .();
	public String Name = new .() ~ delete _;
	public float Score = -1.0f;
	public NavVerdict Verdict = .Behind;

	public void Set(NavCandidate other)
	{
		if (other === this)
			return;
		Bounds = other.Bounds;
		Name.Set(other.Name);
		Score = other.Score;
		Verdict = other.Verdict;
	}
}

/// What the last directional move weighed (the debug overlay draws it, the inspector lists it):
/// from where, which way, every candidate of the last search, and whether an override decided it
/// or the search wrapped round its scope. A class: it owns its candidates.
class NavTrace
{
	/// Every overlapping candidate's score is below it; every other's is at or above it.
	public const float cNoOverlapTier = 1.0e6f;

	public NavDirection Direction = .Down;
	public Rect From = .();
	public List<NavCandidate> Candidates = new .() ~ DeleteContainerAndItems!(_);
	/// A nav-up (and the rest) said where it went.
	public bool Overridden = false;
	/// It measured again from the scope's other side.
	public bool Wrapped = false;
	/// A move happened since the GUI began.
	public bool Any = false;

	/// Back to a trace of no move.
	public void Reset()
	{
		Direction = .Down;
		From = .();
		ClearAndDeleteItems(Candidates);
		Overridden = false;
		Wrapped = false;
		Any = false;
	}

	public void Set(NavTrace other)
	{
		if (other === this)
			return;
		Direction = other.Direction;
		From = other.From;
		ClearAndDeleteItems(Candidates);
		for (let c in other.Candidates)
		{
			let copy = new NavCandidate();
			copy.Set(c);
			Candidates.Add(copy);
		}
		Overridden = other.Overridden;
		Wrapped = other.Wrapped;
		Any = other.Any;
	}
}

internal static class NavigationDetail
{
	// Whether `node` can take focus from navigation: tab-focusable, enabled, and shown with all its
	// ancestors (visible, and in the layout: not under a page switched away), and not leaving or
	// inert.
	public static bool IsNavigable(Node node)
	{
		return node.TabFocusable && node.IsTreeEnabled && node.IsTreeVisible && !node.IsTreeInert;
	}

	// Whether a clipping ancestor hides `node` (a scroller's clip does not count: it scrolls a
	// focused widget into view).
	public static bool IsClippedAway(Node node, Rect bounds)
	{
		for (var n = node.Parent; n != null; n = n.Parent)
		{
			if (n.ClipsChildren && !n.ScrollsDescendantsIntoView &&
				((n.Parent == null) || !n.Parent.ScrollsDescendantsIntoView))
			{
				let clip = n.ScreenBounds;
				if ((bounds.X + bounds.Width <= clip.X) || (bounds.X >= clip.X + clip.Width) ||
					(bounds.Y + bounds.Height <= clip.Y) || (bounds.Y >= clip.Y + clip.Height))
					return true;
			}
		}
		return false;
	}

	public static void CollectNavigable(Node node, List<Node> outNodes)
	{
		if (!node.Visible || !node.Displayed)
			return;
		if (IsNavigable(node))
			outNodes.Add(node);
		for (int i = 0; i < node.ChildCount; i++)
			CollectNavigable(node.GetChildAt(i), outNodes);
	}

	public static Node FindWidgetById(Node node, StringView id)
	{
		let widget = node as UIWidget;
		if ((widget != null) && (widget.Id == id))
			return node;
		for (int i = 0; i < node.ChildCount; i++)
		{
			let found = FindWidgetById(node.GetChildAt(i), id);
			if (found != null)
				return found;
		}
		return null;
	}

	public static bool IsInside(Node node, Node ancestor)
	{
		for (var n = node; n != null; n = n.Parent)
		{
			if (n == ancestor)
				return true;
		}
		return false;
	}

	// The score of moving from `from` to `to` in `direction`: lower is better; negative when `to`
	// is not beyond `from` that way. Overlap on the cross axis is a tier of its own.
	public static float Score(Rect from, Rect to, NavDirection direction)
	{
		let vertical = (direction == .Up) || (direction == .Down);
		let fromNear = (direction == .Down) ? from.Y + from.Height
			: (direction == .Up) ? from.Y
			: (direction == .Right) ? from.X + from.Width
			: from.X;
		let toNear = (direction == .Down) ? to.Y
			: (direction == .Up) ? to.Y + to.Height
			: (direction == .Right) ? to.X
			: to.X + to.Width;
		let toCenter = vertical ? to.Y + to.Height * 0.5f : to.X + to.Width * 0.5f;
		let fromCenter = vertical ? from.Y + from.Height * 0.5f : from.X + from.Width * 0.5f;
		let forward = (direction == .Down) || (direction == .Right);
		// Beyond: its centre past ours, and its near edge at or past our leading edge, give or take
		// a quarter of the smaller one's size (neighbours that touch or overlap a little). A wide
		// field in the row above is not to the right of a button under it, though its centre is
		// (user report: Back, then right, took the settings' text field).
		if (forward ? (toCenter <= fromCenter) : (toCenter >= fromCenter))
			return -1.0f;
		let slack = 0.25f * Math.Min(vertical ? from.Height : from.Width, vertical ? to.Height : to.Width);
		if (forward ? (toNear < fromNear - slack) : (toNear > fromNear + slack))
			return -1.0f;
		let along = Math.Max(0.0f, forward ? toNear - fromNear : fromNear - toNear);
		let crossFromLo = vertical ? from.X : from.Y;
		let crossFromHi = vertical ? from.X + from.Width : from.Y + from.Height;
		let crossToLo = vertical ? to.X : to.Y;
		let crossToHi = vertical ? to.X + to.Width : to.Y + to.Height;
		let overlap = Math.Min(crossFromHi, crossToHi) - Math.Max(crossFromLo, crossToLo);
		let crossCenterGap = Math.Abs((crossFromLo + crossFromHi) * 0.5f - (crossToLo + crossToHi) * 0.5f);
		if (overlap > 0.0f)
			return along + crossCenterGap * 0.01f;
		let crossGap = -overlap;
		return NavTrace.cNoOverlapTier + along + crossGap * 2.0f; // every overlapping candidate beats every other
	}

	// The innermost scope holding `node` (null when none: the whole GUI is the scope).
	public static Node ScopeOf(Node node)
	{
		for (var n = (node != null) ? node.Parent : null; n != null; n = n.Parent)
		{
			if (n.NavScope != .None)
				return n;
		}
		return null;
	}
}

static
{
	/// The best focusable widget from `from` in `direction` among the navigable widgets under
	/// `within`, or null. Wrapping (true) measures from just outside `within`'s opposite edge, so
	/// the first widget on that side is picked. `trace`, when given, gets every candidate weighed.
	public static Node PickInDirection(Node within, Node from, Rect fromBounds, NavDirection direction, NavTrace trace = null)
	{
		let candidates = scope List<Node>();
		NavigationDetail.CollectNavigable(within, candidates);
		if (trace != null)
			ClearAndDeleteItems(trace.Candidates); // the last search is the one that decided
		Node best = null;
		float bestScore = 0.0f;
		int bestEntry = 0;
		for (let candidate in candidates)
		{
			if ((candidate == from) || ((from != null) && NavigationDetail.IsInside(from, candidate)))
				continue; // not itself, nor what holds it (a focusable scroller around it)
			let bounds = candidate.ScreenBounds;
			let clipped = NavigationDetail.IsClippedAway(candidate, bounds);
			let score = clipped ? -1.0f : NavigationDetail.Score(fromBounds, bounds, direction);
			if (trace != null)
			{
				let entry = new NavCandidate();
				entry.Bounds = bounds;
				candidate.DebugName(entry.Name);
				entry.Score = score;
				entry.Verdict = clipped ? .Clipped : (score < 0.0f) ? .Behind : .Beaten;
				trace.Candidates.Add(entry);
			}
			if (score < 0.0f)
				continue;
			if ((best == null) || (score < bestScore))
			{
				best = candidate;
				bestScore = score;
				bestEntry = (trace != null) ? trace.Candidates.Count - 1 : 0;
			}
		}
		if ((trace != null) && (best != null))
			trace.Candidates[bestEntry].Verdict = .Chosen;
		return best;
	}

	/// Where focus lands entering `scopeNode` (the outermost scope a move crosses into): what was
	/// last focused in it, else its default focus, else `picked`.
	public static Node EntryInto(Node scopeNode, Node picked)
	{
		let remembered = scopeNode.RememberedFocus;
		if ((remembered != null) && NavigationDetail.IsInside(remembered, scopeNode) && NavigationDetail.IsNavigable(remembered))
			return remembered;
		if (scopeNode.DefaultFocusId.Length != 0)
		{
			let fallback = NavigationDetail.FindWidgetById(scopeNode, scopeNode.DefaultFocusId);
			if ((fallback != null) && NavigationDetail.IsNavigable(fallback))
				return fallback;
		}
		// A focus group no one has focused in yet: its current member (a checked radio).
		if (scopeNode.FocusGroup)
		{
			let members = scope List<Node>();
			NavigationDetail.CollectNavigable(scopeNode, members);
			for (let member in members)
			{
				if (member.IsCurrentInGroup)
					return member;
			}
		}
		return picked;
	}

	/// What `focused`'s override `which` says (nav-up and the rest): `stop` set for `none`, the
	/// widget for an id found navigable under `root`, else null (auto, empty, or an id not there).
	public static Node FollowOverride(Node root, Node focused, Node.NavOverride which, out bool stop)
	{
		stop = false;
		let target = focused.GetNavOverride(which);
		if ((target.Length == 0) || (target == "auto"))
			return null;
		if (target == "none")
		{
			stop = true;
			return null;
		}
		let found = NavigationDetail.FindWidgetById(root, target);
		return ((found != null) && NavigationDetail.IsNavigable(found)) ? found : null;
	}

	/// The widget directional navigation moves focus to from `focused` (under `root`, the GUI or a
	/// modal), or null to stay. With nothing focused, the root's entry (its remembered or default
	/// focus, else the first navigable widget).
	public static Node NavigateFrom(Node root, Node focused, NavDirection direction, NavTrace trace = null)
	{
		if (trace != null)
		{
			trace.Reset();
			trace.Direction = direction;
			trace.Any = true;
			if (focused != null)
				trace.From = focused.ScreenBounds;
		}
		// Nothing focused, focus outside `root`, or on something that does not take focus: the entry.
		if ((focused == null) || !NavigationDetail.IsInside(focused, root) || !NavigationDetail.IsNavigable(focused))
		{
			let all = scope List<Node>();
			NavigationDetail.CollectNavigable(root, all);
			return EntryInto(root, all.IsEmpty ? null : all[0]);
		}
		// An override where the geometry is wrong comes first.
		let which = (direction == .Up) ? Node.NavOverride.NavOverrideUp
			: (direction == .Down) ? Node.NavOverride.NavOverrideDown
			: (direction == .Left) ? Node.NavOverride.NavOverrideLeft
			: Node.NavOverride.NavOverrideRight;
		bool stop = false;
		let overridden = FollowOverride(root, focused, which, out stop);
		if (overridden != null)
		{
			if (trace != null)
				trace.Overridden = true;
			return overridden;
		}
		if (stop)
			return null;
		let from = focused.ScreenBounds;
		// Search the focused widget's scope, then outward while a scope passes its edge on.
		var current = NavigationDetail.ScopeOf(focused);
		while (true)
		{
			let within = ((current != null) && NavigationDetail.IsInside(current, root)) ? current : root;
			let picked = PickInDirection(within, focused, from, direction, trace);
			if (picked != null)
			{
				// Crossing into a scope (one holding the pick but not the focused widget): its entry.
				Node entered = null;
				for (var s = NavigationDetail.ScopeOf(picked); (s != null) && (s != within); s = NavigationDetail.ScopeOf(s))
				{
					if (!NavigationDetail.IsInside(focused, s))
						entered = s;
				}
				return (entered != null) ? EntryInto(entered, picked) : picked;
			}
			if (within.NavScope == .Wrap)
			{
				// From just past the scope's opposite edge, along the same line.
				let edge = within.ScreenBounds;
				var outside = from;
				switch (direction)
				{
				case .Down: outside.Y = edge.Y - from.Height - 1.0f;
				case .Up: outside.Y = edge.Y + edge.Height + 1.0f;
				case .Right: outside.X = edge.X - from.Width - 1.0f;
				case .Left: outside.X = edge.X + edge.Width + 1.0f;
				}
				if (trace != null)
					trace.Wrapped = true;
				return PickInDirection(within, null, outside, direction, trace);
			}
			if ((within.NavScope == .Contain) || (within == root))
				return null; // a dialog's edge, or the GUI's
			// Pass: on to the scope around this one.
			current = NavigationDetail.ScopeOf(current);
		}
	}

	/// Where focus goes when `node` is focused by a program: itself when it takes focus, else its
	/// entry (remembered, default, or first focusable widget under it); null when nothing does.
	public static Node FocusTargetOf(Node node)
	{
		if (NavigationDetail.IsNavigable(node))
			return node;
		let all = scope List<Node>();
		NavigationDetail.CollectNavigable(node, all);
		return EntryInto(node, all.IsEmpty ? null : all[0]);
	}

	/// The innermost containing scope holding `node` (a dialog's: Tab stays inside it), or null.
	public static Node ContainingScopeOf(Node node)
	{
		for (var s = NavigationDetail.ScopeOf(node); s != null; s = NavigationDetail.ScopeOf(s))
		{
			if (s.NavScope == .Contain)
				return s;
		}
		return null;
	}

	/// Records `focused` as the remembered focus of every scope holding it.
	public static void RememberInScopes(Node focused)
	{
		for (var s = NavigationDetail.ScopeOf(focused); s != null; s = NavigationDetail.ScopeOf(s))
			s.RememberFocus(focused);
	}
}
