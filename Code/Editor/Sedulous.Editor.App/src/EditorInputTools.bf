using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Mcp;
using Sedulous.Json;
using Sedulous.GUI;
using Sedulous.GUI.Testing;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

// The user's hands over MCP: editor_find, editor_click, editor_hover, editor_scroll, editor_type and
// editor_key drive the editor's own GUI as a user would, so an agent checks what a page does (a row
// chosen, a group opened, a key captured) and then looks with editor_screenshot. The input goes to
// the editor's GUI dispatcher, never the operating system: it reaches only this editor, with its
// window hidden or the user at work beside it. A target is named as the GUI's tests name one
// (GUI.Testing's Finder: a CSS selector, "text=Jump", "text~=Jum"), or by a point in the
// screenshot's pixels; a click aims at the middle of what it names, and is refused when something
// else lies there. Each acting tool answers a frame later, so what it reports (the focus) is what
// the frame after it shows. The main window only: a floating window's GUI is not reached.

/// The live editor the input tools drive: the main window's GUI (null: none now, the tools say so).
class InputToolSeams
{
	/// Owned.
	public delegate SceneRoot() Root ~ delete _;

	/// The root, when it has a dispatcher to drive.
	public SceneRoot Live
	{
		get
		{
			let root = (Root != null) ? Root() : null;
			return ((root != null) && (root.EventDispatcher != null)) ? root : null;
		}
	}
}

static class EditorInputTools
{
	/// How many tools Register registers (editor_find, editor_click, editor_hover, editor_scroll,
	/// editor_type, editor_key); a tripwire like cPageToolCount.
	public const int cInputToolCount = 6;
	/// Nodes editor_find lists; the count says how many there were.
	private const int cFindLimit = 50;
	/// Nodes a refusal names when a target finds several.
	private const int cNamedLimit = 10;
	private static StringView[3] cButtons = .("left", "right", "middle");

	private const String cTargetHelp = "`target` names a node as the GUI's tests do: a CSS selector (\"#input-tree\", \"button.primary\", \"treeitem\"), \"text=Jump\" (shows exactly that) or \"text~=Jum\" (shows it in part); `within` narrows it to under what that finds; `index` picks one when it finds several (in document order, from 0). Or `x` and `y`, a point in editor_screenshot's pixels.";

	// An acting tool's call: done, its answer waits for the frame after it.
	private class FrameWait
	{
		public JsonValue Answer ~ delete _;
	}

	/// An acting tool's act: true with `answer` filled, or false with `error`.
	private typealias Act = delegate bool(SceneRoot root, JsonValue arguments, JsonValue answer, String error);

	private static JsonValue NodeJson(Node node)
	{
		let @box = node.ScreenBounds;
		let json = JsonValue.MakeObject();
		json.Set("node", JsonValue.MakeString(Sedulous.GUI.Inspector.Label(node, .. scope String())));
		let text = TextOf(node, .. scope String());
		if (!text.IsEmpty)
			json.Set("text", JsonValue.MakeString(text));
		json.Set("x", JsonValue.MakeNumber(@box.X));
		json.Set("y", JsonValue.MakeNumber(@box.Y));
		json.Set("width", JsonValue.MakeNumber(@box.Width));
		json.Set("height", JsonValue.MakeNumber(@box.Height));
		return json;
	}

	private static JsonValue PointJson(Float2 at)
	{
		let json = JsonValue.MakeObject();
		json.Set("x", JsonValue.MakeNumber(at.X));
		json.Set("y", JsonValue.MakeNumber(at.Y));
		return json;
	}

	// What `arguments` names: a finder from `target` and `within`, all it finds.
	private static bool FindAll(SceneRoot root, JsonValue arguments, List<Node> outFound, String outError)
	{
		let target = McpTools.ArgString(arguments, "target", .. scope .());
		if (target.IsEmpty)
		{
			outError.Append("name a `target` (a selector, text=..., text~=...)");
			return false;
		}
		var finder = Finder.Parse(target);
		let within = McpTools.ArgString(arguments, "within", .. scope .());
		if (!within.IsEmpty)
			finder = finder.Within(Finder.Parse(within));
		finder.All(root, outFound);
		return true;
	}

	// Where `arguments` aims: the middle of the one node it names (refused when something else lies
	// there), or its point. `outNode` is what the pointer reaches there.
	private static bool Aim(SceneRoot root, JsonValue arguments, out Float2 outAt, out Node outNode, String outError)
	{
		outAt = .(0, 0);
		outNode = null;
		if (!arguments.Has("target"))
		{
			if (!arguments.Has("x") || !arguments.Has("y"))
			{
				outError.Append("name a `target`, or give `x` and `y`");
				return false;
			}
			outAt = .((float)McpTools.ArgNumber(arguments, "x"), (float)McpTools.ArgNumber(arguments, "y"));
			let dispatcher = root.EventDispatcher;
			outNode = (dispatcher != null) ? dispatcher.NodeAt(outAt) : root.OverFind(outAt); // a popup's first, as input
			return true;
		}
		let found = scope List<Node>();
		if (!FindAll(root, arguments, found, outError))
			return false;
		let index = (int)McpTools.ArgNumber(arguments, "index", -1);
		if (found.IsEmpty || ((index < 0) && (found.Count > 1)) || (index >= found.Count))
		{
			outError.AppendF("{} shown node(s) match", found.Count);
			if (found.Count > 1)
				outError.Append("; pass `index` or narrow it with `within`");
			for (int i = 0; (i < found.Count) && (i < cNamedLimit); i++)
				outError.AppendF("\n  [{}] {} \"{}\"", i, Sedulous.GUI.Inspector.Label(found[i], .. scope String()), TextOf(found[i], .. scope String()));
			if (found.IsEmpty)
				outError.Append(" (editor_find lists what a target finds)");
			return false;
		}
		outNode = found[(index < 0) ? 0 : index];
		if (!AimAt(root, outNode, out outAt, let over))
		{
			outError.AppendF("{} is covered at its middle by {} (a popup or a dialog over it?)", Sedulous.GUI.Inspector.Label(outNode, .. scope String()),
				(over != null) ? Sedulous.GUI.Inspector.Label(over, .. scope String()) : "nothing");
			return false;
		}
		return true;
	}

	// "ctrl-shift" as the dispatcher's modifier bits; false for a word it does not know.
	private static bool ParseModifiers(StringView text, out uint32 outModifiers)
	{
		outModifiers = 0;
		for (let part in text.Split('-', '+'))
		{
			if (part.IsEmpty)
				continue;
			if ((StringView.Compare(part, "ctrl", true) == 0) || (StringView.Compare(part, "control", true) == 0))
				outModifiers |= KeyModCtrl;
			else if (StringView.Compare(part, "shift", true) == 0)
				outModifiers |= KeyModShift;
			else if (StringView.Compare(part, "alt", true) == 0)
				outModifiers |= KeyModAlt;
			else if ((StringView.Compare(part, "super", true) == 0) || (StringView.Compare(part, "meta", true) == 0) || (StringView.Compare(part, "cmd", true) == 0))
				outModifiers |= KeyModSuper;
			else
				return false;
		}
		return true;
	}

	// The focus, as the frame after an act shows it.
	private static void AddAfter(SceneRoot root, JsonValue answer)
	{
		let dispatcher = root.EventDispatcher;
		let focus = (dispatcher != null) ? dispatcher.FocusNode : null;
		answer.Set("focus", (focus != null) ? NodeJson(focus) : JsonValue.MakeNull());
	}

	// An acting tool's handler: `act` on its first entry (an answer, or an error), the answer a frame
	// later. OWNERSHIP of `act` transfers.
	private static Tool.CallHandler Acting(InputToolSeams seams, Act act)
	{
		return new [=seams, =act] (call, arguments, outResult, outError) =>
			{
				let root = seams.Live;
				if (root == null)
				{
					outError.Append("the editor has no window GUI now");
					return .Failed;
				}
				if (call.IsReentry)
				{
					if (let wait = call.State as FrameWait)
					{
						for (let key in wait.Answer.Keys)
							outResult.Set(key, wait.Answer.Get(key).Clone());
					}
					AddAfter(root, outResult);
					return .Answered;
				}
				let answer = JsonValue.MakeObject();
				if (!act(root, arguments, answer, outError))
				{
					delete answer;
					return .Failed;
				}
				let wait = new FrameWait();
				wait.Answer = answer;
				call.State = wait;
				return .NotFinished;
			} ~ delete act;
	}

	/// OWNERSHIP of the seams transfers to the tools (the first holds them).
	public static void Register(McpServer server, InputToolSeams seams)
	{
		let findSchema = scope SchemaBuilder();
		findSchema.Str("target", "a selector, text=..., or text~=...", true);
		findSchema.Str("within", "only under what this finds");
		server.RegisterTool("editor_find",
			scope String()..AppendF("The nodes of the editor's GUI a target names, shown ones only: {{node, text, x, y, width, height}} each in document order (x, y, width and height in editor_screenshot's pixels), at most {}; `count` says how many there were. What to aim editor_click at. {}", cFindLimit, cTargetHelp),
			findSchema.Build(), .ReadOnly,
			new [=seams] (arguments, outResult, outError) =>
			{
				let root = seams.Live;
				if (root == null)
				{
					outError.Append("the editor has no window GUI now");
					return false;
				}
				let found = scope List<Node>();
				if (!FindAll(root, arguments, found, outError))
					return false;
				let list = JsonValue.MakeArray();
				for (int i = 0; (i < found.Count) && (i < cFindLimit); i++)
					list.Add(NodeJson(found[i]));
				outResult.Set("count", JsonValue.MakeNumber(found.Count));
				outResult.Set("nodes", list);
				return true;
			}, seams);

		let clickSchema = scope SchemaBuilder();
		AimFields(clickSchema);
		clickSchema.Enum("button", cButtons, "left (default), right or middle");
		clickSchema.Integer("clicks", "1 (default), 2 for a double click");
		clickSchema.Str("modifiers", "held while clicking: ctrl, shift, alt, super, joined by -");
		server.RegisterTool("editor_click",
			scope String()..AppendF("Clicks in the editor's GUI as a user would (the pointer moved there, pressed and released), through the editor's own input: nothing outside this editor is touched. {} Refused when the target finds no node or several, or something else lies over its middle. `button` left (default), right (a context menu) or middle; `clicks` 2 for a double click; `modifiers` held (\"ctrl\", \"shift\", \"ctrl-shift\"). Answers a frame later with {{clicked, at, focus}}; then editor_screenshot to see it.", cTargetHelp),
			clickSchema.Build(), .Creates,
			Acting(seams, new (root, arguments, answer, error) =>
			{
				if (!Aim(root, arguments, let at, let node, error))
					return false;
				if (!ParseModifiers(McpTools.ArgString(arguments, "modifiers", .. scope .()), let modifiers))
				{
					error.Append("`modifiers` takes ctrl, shift, alt and super, joined by -");
					return false;
				}
				let name = McpTools.ArgString(arguments, "button", .. scope .());
				let button = (name == "right") ? MouseButton.Right : ((name == "middle") ? MouseButton.Middle : MouseButton.Left);
				let clicks = Math.Clamp((int)McpTools.ArgNumber(arguments, "clicks", 1), 1, 3);
				let d = root.EventDispatcher;
				d.InjectMouseMove(at, modifiers);
				for (int i < clicks)
				{
					d.InjectMouseDown(at, button, modifiers);
					d.InjectMouseUp(at, button, modifiers);
				}
				answer.Set("clicked", (node != null) ? NodeJson(node) : JsonValue.MakeNull());
				answer.Set("at", PointJson(at));
				return true;
			}));

		let hoverSchema = scope SchemaBuilder();
		AimFields(hoverSchema);
		server.RegisterTool("editor_hover",
			scope String()..AppendF("Moves the editor's pointer over a target or a point, pressing nothing: a hover's look, or a tooltip after its delay (screenshot a moment later). {} Answers a frame later with {{over, at, focus}}.", cTargetHelp),
			hoverSchema.Build(), .Adjusts,
			Acting(seams, new (root, arguments, answer, error) =>
			{
				if (!Aim(root, arguments, let at, let node, error))
					return false;
				root.EventDispatcher.InjectMouseMove(at);
				answer.Set("over", (node != null) ? NodeJson(node) : JsonValue.MakeNull());
				answer.Set("at", PointJson(at));
				return true;
			}));

		let scrollSchema = scope SchemaBuilder();
		AimFields(scrollSchema);
		scrollSchema.Number("dy", "notches: negative down, positive up", true);
		scrollSchema.Number("dx", "notches sideways");
		server.RegisterTool("editor_scroll",
			scope String()..AppendF("Turns the wheel over a target or a point in the editor's GUI. `dy` in notches as the platform reports them: negative scrolls down (the wheel toward the user), positive up; `dx` sideways. {} Answers a frame later with {{over, at, focus}}.", cTargetHelp),
			scrollSchema.Build(), .Adjusts,
			Acting(seams, new (root, arguments, answer, error) =>
			{
				if (!Aim(root, arguments, let at, let node, error))
					return false;
				let delta = Float2((float)McpTools.ArgNumber(arguments, "dx"), (float)McpTools.ArgNumber(arguments, "dy"));
				let d = root.EventDispatcher;
				d.InjectMouseMove(at);
				d.InjectMouseWheel(at, delta);
				answer.Set("over", (node != null) ? NodeJson(node) : JsonValue.MakeNull());
				answer.Set("at", PointJson(at));
				return true;
			}));

		let typeSchema = scope SchemaBuilder();
		typeSchema.Str("text", "the text to type", true);
		server.RegisterTool("editor_type",
			"Types text into what has the focus in the editor's GUI (editor_click a field first), as the keyboard's text would arrive. A key that does something (Enter, Escape, Tab, a shortcut) is editor_key's. Refused when nothing has the focus. Answers a frame later with {focus}.",
			typeSchema.Build(), .Creates,
			Acting(seams, new (root, arguments, answer, error) =>
			{
				let d = root.EventDispatcher;
				if (d.FocusNode == null)
				{
					error.Append("nothing has the focus: editor_click the field first");
					return false;
				}
				d.InjectText(McpTools.ArgString(arguments, "text", .. scope .()));
				return true;
			}));

		let keySchema = scope SchemaBuilder();
		keySchema.Str("chord", "the key or chord, as a keymap binding writes it", true);
		server.RegisterTool("editor_key",
			"Presses and releases a key or a chord in the editor's GUI, as the keyboard would: to what has the focus first, then the editor's shortcuts (\"return\", \"escape\", \"tab\", \"down\", \"ctrl-s\", \"ctrl-shift-z\", \"f2\"; the keymap's names). Answers a frame later with {handled, focus}.",
			keySchema.Build(), .Creates,
			Acting(seams, new (root, arguments, answer, error) =>
			{
				let chord = McpTools.ArgString(arguments, "chord", .. scope .());
				let stroke = ParseKeystroke(chord);
				if ((stroke == null) || stroke.Value.Pad)
				{
					error.AppendF("no such key or chord: \"{}\" (the keymap's names: ctrl-s, return, f2)", chord);
					return false;
				}
				let d = root.EventDispatcher;
				let taken = d.InjectKeyDown(stroke.Value.Code, stroke.Value.Modifiers);
				d.InjectKeyUp(stroke.Value.Code, stroke.Value.Modifiers);
				answer.Set("handled", JsonValue.MakeBool(taken));
				return true;
			}));
	}

	// The fields every aimed tool takes.
	private static void AimFields(SchemaBuilder schema)
	{
		schema.Str("target", "a selector, text=..., or text~=...");
		schema.Str("within", "only under what this finds");
		schema.Integer("index", "which of several matches, from 0");
		schema.Number("x", "a point in the screenshot's pixels, in place of a target");
		schema.Number("y", "a point in the screenshot's pixels, in place of a target");
	}
}
