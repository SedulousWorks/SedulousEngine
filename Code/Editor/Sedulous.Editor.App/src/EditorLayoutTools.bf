using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI; // GUI.Docking's controller and layout

namespace Sedulous.Editor.App;

/// The MCP tools over the editor's dock layout (GUI.Docking's; Raptor's editor-gui spec, 5.1,
/// layer 14), what only the editor host can serve: layout_get (the tree of splits, each with any
/// number of children and their weights (ruling 16), and stacks of tabs, every panel by its id
/// and title, the floating and hidden ones) and panel_dock (a panel moved beside another, into
/// its tabs, along the window's edge, or floating), so an agent can put two Game tabs side by
/// side for a networked playtest as a drag would. A panel is named by its id: a page's asset
/// guid, a Game tab's PIE id (`game-page`, `game-page-1`, ...), or a shared panel's (`welcome`
/// for Project, `assets`, `console`, `profiler`).
static class EditorLayoutTools
{
	/// How many tools Register registers; a tripwire like EditorPageTools.cPageToolCount.
	public const int cLayoutToolCount = 2;

	private static StringView[6] cPositions = .("left", "right", "top", "bottom", "center", "float");

	/// A float's bounds when the tool makes one: where a drag out of the window would put it.
	private static readonly Rectangle cFloatBounds = .(120.0f, 120.0f, 640.0f, 420.0f);

	/// What a position names: beside a stack (or along the window's edge) on a side, into a stack
	/// as a tab, or a window of its own.
	private enum Placement : uint8
	{
		case Side;
		case Center;
		case Float;
	}

	/// `dock` is the editor's dock controller, BORROWED: it outlives the server. Its edits go
	/// through it, so every view of the layout shows them.
	public static void Register(McpServer server, DockController dock)
	{
		server.RegisterTool("layout_get",
			"The editor's dock layout: `root`, a tree whose nodes are splits ({split: horizontal (children left to right) or vertical (top to bottom), children: [nodes], weights: [each child's share, summing to one]}) or stacks of tabs ({tabs: [{panel, title}], active}), and the `floating` and `hidden` (closed) panels. A panel is named by its id: a page's asset guid, a Game tab's PIE id (game-page, game-page-1, ...), or a shared panel's (welcome is Project; assets, console, profiler). panel_dock moves them.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				WriteLayout(dock, outResult);
				return true;
			});

		let dockSchema = scope SchemaBuilder();
		dockSchema.Str("panel", "the panel to move, by its id", true);
		dockSchema.Enum("position", cPositions, "where it goes", true);
		dockSchema.Str("relativeTo", "the panel whose stack it goes beside or into (default: the window)");
		dockSchema.Number("share", "the moved panel's fraction of the room (side positions; default 0.5)");
		server.RegisterTool("panel_dock",
			"Move a panel, as dragging its tab does: to the `left`, `right`, `top` or `bottom` of another panel's stack (`relativeTo`; default: along the whole window's edge), into that stack as a tab (`center`; default: the documents' stack), or into a window of its own (`float`). A hidden panel docks again the same way. `share` (0.05 to 0.95, default 0.5) is the moved panel's fraction of the room a side position splits. Two Game tabs side by side for a networked playtest: {panel: game-page-1, position: right, relativeTo: game-page}. Returns the layout as layout_get gives it. Ids come from layout_get.",
			dockSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) => Dock(dock, arguments, outResult, outError));
	}

	private static bool Dock(DockController dock, JsonValue arguments, JsonValue outResult, String outError)
	{
		let id = arguments.Get("panel")?.AsString() ?? StringView();
		if (!Known(dock, id))
		{
			outError.AppendF("no panel '{}' (layout_get lists them)", id);
			return false;
		}
		Placement placement;
		DockSide side;
		if (!ParsePosition(arguments.Get("position")?.AsString() ?? StringView(), out placement, out side, outError))
			return false;
		let shareArg = arguments.Get("share");
		let hasShare = (shareArg != null) && shareArg.IsNumber;
		let share = hasShare ? (float)shareArg.AsNumber() : 0.5f;
		if (hasShare && ((placement != .Side) || (share < 0.05f) || (share > 0.95f)))
		{
			outError.Set("share is a side position's fraction, 0.05 to 0.95");
			return false;
		}
		let layout = dock.Layout;
		let relativeId = arguments.Get("relativeTo")?.AsString() ?? StringView();
		DockNodeId target = cNoDock;
		if (!relativeId.IsEmpty)
		{
			if (!Known(dock, relativeId))
			{
				outError.AppendF("no panel '{}' (layout_get lists them)", relativeId);
				return false;
			}
			if (relativeId == id)
			{
				outError.Set("a panel cannot go beside or into itself");
				return false;
			}
			target = layout.StackOf(relativeId);
			if (target == cNoDock)
			{
				outError.AppendF("panel '{}' is not docked (it is hidden); dock it first", relativeId);
				return false;
			}
		}
		// A docked panel (floating included) moves; a hidden or never-placed one is inserted.
		let docked = layout.StackOf(id) != cNoDock;
		let done = dock.Edit(scope (edit) =>
			{
				if (placement == .Float)
					return edit.Float(id, cFloatBounds);
				if (placement == .Center)
				{
					let stack = (target != cNoDock) ? target : edit.CentralStack;
					return docked ? edit.MoveToTab(id, stack) : edit.InsertTab(id, stack);
				}
				if (target != cNoDock)
					return docked ? edit.MoveBeside(id, target, side, share) : edit.InsertBeside(id, target, side, share);
				return docked ? edit.MoveToEdge(id, edit.MainSurface, side, share) : edit.InsertAtEdge(id, edit.MainSurface, side, share);
			});
		if (!done.Ok)
		{
			outError.AppendF("'{}' cannot go there: {}", id, done.Refused);
			return false;
		}
		dock.Edit(scope (edit) => edit.Activate(id));
		WriteLayout(dock, outResult);
		return true;
	}

	private static bool ParsePosition(StringView text, out Placement outPlacement, out DockSide outSide, String outError)
	{
		outPlacement = .Side;
		outSide = .End;
		switch (text)
		{
		case "left": outSide = .Start;
		case "right": outSide = .End;
		case "top": outSide = .Top;
		case "bottom": outSide = .Bottom;
		case "center": outPlacement = .Center;
		case "float": outPlacement = .Float;
		default:
			outError.AppendF("unknown position '{}' (left, right, top, bottom, center or float)", text);
			return false;
		}
		return true;
	}

	/// A panel the tools may name: registered, or placed by the layout.
	private static bool Known(DockController dock, StringView id)
	{
		return !id.IsEmpty && ((dock.Describe(id) != null) || (dock.Layout.StackOf(id) != cNoDock));
	}

	private static void WriteLayout(DockController dock, JsonValue outResult)
	{
		let layout = dock.Layout;
		let floating = JsonValue.MakeArray();
		for (let surface in layout.Surfaces)
		{
			if (surface.Kind == .Floating)
				CollectPanels(dock, surface.Root, floating);
		}
		// Hidden: closed with their place kept, and registered panels the layout never placed.
		let hidden = JsonValue.MakeArray();
		for (let closed in layout.Hidden)
			hidden.Add(PanelJson(dock, closed.Panel));
		for (let description in dock.Panels)
		{
			if ((layout.StackOf(description.Id) == cNoDock) && (layout.FindHidden(description.Id) == null))
				hidden.Add(PanelJson(dock, description.Id));
		}
		let main = layout.FindSurface(layout.MainSurface);
		outResult.Set("root", (main != null) ? NodeJson(dock, main.Root) : JsonValue.MakeNull());
		outResult.Set("floating", floating);
		outResult.Set("hidden", hidden);
	}

	/// {panel, title}: the registered title, else the id (a panel the layout places unregistered).
	private static JsonValue PanelJson(DockController dock, StringView panel)
	{
		let description = dock.Describe(panel);
		StringView title = panel;
		if ((description != null) && !description.Title.IsEmpty)
			title = description.Title;
		let json = JsonValue.MakeObject();
		json.Set("panel", JsonValue.MakeString(panel));
		json.Set("title", JsonValue.MakeString(title));
		return json;
	}

	/// A node of the dock tree: a split with its children and their weights, or a stack of tabs.
	private static JsonValue NodeJson(DockController dock, DockNodeId id)
	{
		let node = dock.Layout.FindNode(id);
		if (node == null)
			return JsonValue.MakeNull();
		let json = JsonValue.MakeObject();
		if (node.IsStack)
		{
			let tabs = JsonValue.MakeArray();
			for (let panel in node.Panels)
				tabs.Add(PanelJson(dock, panel));
			json.Set("tabs", tabs);
			if (!node.Panels.IsEmpty)
				json.Set("active", JsonValue.MakeString(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]));
			return json;
		}
		json.Set("split", JsonValue.MakeString((node.Axis == .Horizontal) ? "horizontal" : "vertical"));
		let children = JsonValue.MakeArray();
		let weights = JsonValue.MakeArray();
		for (int i < node.Children.Count)
		{
			children.Add(NodeJson(dock, node.Children[i]));
			weights.Add(JsonValue.MakeNumber((i < node.Weights.Count) ? node.Weights[i] : 0.0f));
		}
		json.Set("children", children);
		json.Set("weights", weights);
		return json;
	}

	/// Every panel under `id`, in the tree's order, into `into`.
	private static void CollectPanels(DockController dock, DockNodeId id, JsonValue into)
	{
		let node = dock.Layout.FindNode(id);
		if (node == null)
			return;
		if (node.IsStack)
		{
			for (let panel in node.Panels)
				into.Add(PanelJson(dock, panel));
			return;
		}
		for (let child in node.Children)
			CollectPanels(dock, child, into);
	}
}
