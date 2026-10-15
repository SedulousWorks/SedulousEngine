using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// The MCP tools over the editor's dock layout, what only the editor host can serve:
/// layout_get (the tree of splits and tab groups, every panel by its persistence id and title,
/// the floating and hidden ones) and panel_dock (a panel moved beside another, into its tabs,
/// or floating), so an agent can put two Game tabs side by side for a networked playtest as a
/// drag would. A panel is named by its persistence id: a page's asset guid, a Game tab's PIE id
/// (`game-page`, `game-page-1`, ...), or a tool panel's fixed one (`welcome` for Project,
/// `assets`, `console`, `profiler`).
static class EditorLayoutTools
{
	/// How many tools Register registers; a tripwire like EditorPageTools.cPageToolCount.
	public const int cLayoutToolCount = 2;

	private static StringView[6] cPositions = .("left", "right", "top", "bottom", "center", "float");

	/// `dock` is the editor's dock manager, BORROWED: it outlives the server.
	public static void Register(McpServer server, DockManager dock)
	{
		server.RegisterTool("layout_get",
			"The editor's dock layout: `root`, a tree whose nodes are splits ({split: horizontal (first left, second right) or vertical (first above), share: the first side's fraction, first, second}) or tab groups ({tabs: [{panel, title}], active}), and the `floating` and `hidden` (closed tool) panels. A panel is named by its id: a page's asset guid, a Game tab's PIE id (game-page, game-page-1, ...), or a tool panel's (welcome is Project; assets, console, profiler). panel_dock moves them.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				WriteLayout(dock, outResult);
				return true;
			});

		let dockSchema = scope SchemaBuilder();
		dockSchema.Str("panel", "the panel to move, by its id", true);
		dockSchema.Enum("position", cPositions, "where it goes", true);
		dockSchema.Str("relativeTo", "the panel whose tab group it goes beside or into (default: the window)");
		dockSchema.Number("share", "the moved panel's fraction of the split (side positions; default 0.5)");
		server.RegisterTool("panel_dock",
			"Move a panel, as dragging its tab does: to the `left`, `right`, `top` or `bottom` of another panel's tab group (`relativeTo`; default: the whole window), into that group as a tab (`center`), or into a window of its own (`float`). A hidden tool panel docks again the same way. `share` (0.05 to 0.95, default 0.5) is the moved panel's fraction of the split a side position makes. Two Game tabs side by side for a networked playtest: {panel: game-page-1, position: right, relativeTo: game-page}. Returns the layout as layout_get gives it. Ids come from layout_get.",
			dockSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) => Dock(dock, arguments, outResult, outError));
	}

	private static bool Dock(DockManager dock, JsonValue arguments, JsonValue outResult, String outError)
	{
		let id = arguments.Get("panel")?.AsString() ?? StringView();
		let panel = FindLivePanel(dock, id);
		if (panel == null)
		{
			outError.AppendF("no panel '{}' (layout_get lists them)", id);
			return false;
		}
		DockPosition position;
		if (!ParsePosition(arguments.Get("position")?.AsString() ?? StringView(), out position, outError))
			return false;
		let side = (position != .Center) && (position != .Float);
		let shareArg = arguments.Get("share");
		let hasShare = (shareArg != null) && shareArg.IsNumber;
		let share = hasShare ? (float)shareArg.AsNumber() : 0.5f;
		if (hasShare && (!side || (share < 0.05f) || (share > 0.95f)))
		{
			outError.Set("share is a side position's fraction, 0.05 to 0.95");
			return false;
		}
		let relativeId = arguments.Get("relativeTo")?.AsString() ?? StringView();
		DockablePanel relativeTo = null;
		if (!relativeId.IsEmpty)
		{
			relativeTo = FindLivePanel(dock, relativeId);
			if (relativeTo == null)
			{
				outError.AppendF("no panel '{}' (layout_get lists them)", relativeId);
				return false;
			}
			if (relativeTo == panel)
			{
				outError.Set("a panel cannot go beside or into itself");
				return false;
			}
			if (!IsDocked(dock, relativeTo))
			{
				outError.AppendF("panel '{}' is not docked (it floats or is hidden); dock it first", relativeId);
				return false;
			}
		}
		if (relativeTo != null)
			dock.DockPanelRelativeTo(panel, position, relativeTo);
		else
			dock.DockPanel(panel, position);
		if (side)
		{
			// The new split holds the panel's own group on one side.
			let group = panel.Parent;
			if (let split = (group != null) ? group.Parent as DockSplit : null)
				split.SplitRatio = (split.First === group) ? share : 1.0f - share;
		}
		dock.ActivatePanel(panel);
		WriteLayout(dock, outResult);
		return true;
	}

	private static bool ParsePosition(StringView text, out DockPosition outPosition, String outError)
	{
		outPosition = .Center;
		switch (text)
		{
		case "left": outPosition = .Left;
		case "right": outPosition = .Right;
		case "top": outPosition = .Top;
		case "bottom": outPosition = .Bottom;
		case "center": outPosition = .Center;
		case "float": outPosition = .Float;
		default:
			outError.AppendF("unknown position '{}' (left, right, top, bottom, center or float)", text);
			return false;
		}
		return true;
	}

	/// A registered panel by id, or null for none or one on its way out.
	private static DockablePanel FindLivePanel(DockManager dock, StringView id)
	{
		let panel = id.IsEmpty ? null : dock.FindPanelById(id);
		return ((panel != null) && !panel.IsPendingDeletion) ? panel : null;
	}

	/// In the tree: in a tab group, in a split, or the tree's root itself.
	private static bool IsDocked(DockManager dock, DockablePanel panel)
	{
		return (panel.Parent is DockTabGroup) || (panel.Parent is DockSplit)
			|| ((panel.Parent === dock) && (dock.RootNode === panel));
	}

	private static void WriteLayout(DockManager dock, JsonValue outResult)
	{
		let floating = JsonValue.MakeArray();
		let hidden = JsonValue.MakeArray();
		for (int i < dock.PanelCount)
		{
			let panel = dock.GetPanelAt(i);
			if ((panel == null) || panel.IsPendingDeletion || IsDocked(dock, panel))
				continue;
			if (panel.Parent is DockableWindow)
				floating.Add(PanelJson(panel));
			else
				hidden.Add(PanelJson(panel)); // a tool panel closed for now
		}
		outResult.Set("root", NodeJson(dock.RootNode));
		outResult.Set("floating", floating);
		outResult.Set("hidden", hidden);
	}

	private static JsonValue PanelJson(DockablePanel panel)
	{
		let json = JsonValue.MakeObject();
		json.Set("panel", JsonValue.MakeString(panel.PersistenceId));
		json.Set("title", JsonValue.MakeString(panel.Title));
		return json;
	}

	/// A node of the dock tree: a split with its two sides, or a tab group with its panels (a
	/// lone panel at the root reads as a group of one).
	private static JsonValue NodeJson(View node)
	{
		if (let split = node as DockSplit)
		{
			let json = JsonValue.MakeObject();
			json.Set("split", JsonValue.MakeString((split.Orientation == .Horizontal) ? "horizontal" : "vertical"));
			json.Set("share", JsonValue.MakeNumber(split.SplitRatio));
			json.Set("first", NodeJson(split.First));
			json.Set("second", NodeJson(split.Second));
			return json;
		}
		if (let group = node as DockTabGroup)
		{
			let tabs = JsonValue.MakeArray();
			for (int32 i < group.PanelCount)
				tabs.Add(PanelJson(group.GetPanel(i)));
			let json = JsonValue.MakeObject();
			json.Set("tabs", tabs);
			if (let active = group.SelectedPanel)
				json.Set("active", JsonValue.MakeString(active.PersistenceId));
			return json;
		}
		if (let panel = node as DockablePanel)
		{
			let tabs = JsonValue.MakeArray();
			tabs.Add(PanelJson(panel));
			let json = JsonValue.MakeObject();
			json.Set("tabs", tabs);
			json.Set("active", JsonValue.MakeString(panel.PersistenceId));
			return json;
		}
		return JsonValue.MakeNull();
	}
}
