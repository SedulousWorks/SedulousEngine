using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// The live editor the action tools see: the registry through the context, and the UI context
/// whose dialogs an unattended call suppresses (null is nothing to suppress, a headless test).
class ActionToolSeams
{
	public EditorContext Context = null;
	public UIContext Ui = null;
}

/// The unattended scope: while alive, every dialog shown through `ui` is suppressed and
/// recorded by title. Installs the context's DialogInterceptor and puts back what was there,
/// so scopes nest.
class UnattendedDialogs
{
	/// BORROWED.
	private UIContext mUi;
	/// OWNED while this scope holds the context's slot; handed back when it ends.
	private delegate bool(Dialog dialog) mPrevious = null;
	public List<String> Suppressed = new .() ~ DeleteContainerAndItems!(_);

	public this(UIContext ui)
	{
		mUi = ui;
		if (mUi == null)
			return;
		mPrevious = mUi.DialogInterceptor;
		mUi.DialogInterceptor = new [=this](dialog) =>
			{
				Suppressed.Add(new String(dialog.Title));
				return false;
			};
	}

	public ~this()
	{
		if (mUi == null)
			return;
		delete mUi.DialogInterceptor;
		mUi.DialogInterceptor = mPrevious;
	}
}

/// The MCP bridge over the editor's ACTIONS, one generic surface for everything a user can do
/// by command: action_list (every declaration with its state over the active page),
/// action_state (one) and action_execute (through the registry, the one funnel). An agent never
/// waits for a human: action_execute runs UNATTENDED, every dialog the action would open kept
/// off the screen and closed as cancelled (the accident-preventing answer), and the result
/// names what was suppressed, with the note that the action then most likely did nothing and a
/// dedicated tool or the user is the way forward.
static class EditorActionTools
{
	/// How many tools Register registers; a tripwire like the page tools'.
	public const int cActionToolCount = 3;

	/// OWNERSHIP of the seams transfers; the first tool holds them for all three.
	public static void Register(McpServer server, ActionToolSeams seams)
	{
		let listSchema = scope SchemaBuilder();
		server.RegisterTool("action_list",
			"Every editor action - what a user can do by menu, chord, toolbar or context menu - with its state over the ACTIVE page: id, label, description, menuPath, kind (command / toggle / window), readOnly, shortcut, enabled, checked. Page-bound actions are disabled when no page of their kind is active: page_open one first.",
			listSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let actions = seams.Context.Actions;
				let list = JsonValue.MakeArray();
				for (let action in actions.Actions)
					list.Add(ActionJson(actions, action));
				outResult.Set("count", JsonValue.MakeNumber(actions.Count));
				outResult.Set("actions", list);
				return true;
			}, seams);

		let stateSchema = scope SchemaBuilder();
		stateSchema.Str("id", "the action's id (from action_list)", true);
		server.RegisterTool("action_state",
			"One action's declaration and its state over the active page, as action_list shows it.",
			stateSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let actions = seams.Context.Actions;
				let action = FindAction(actions, arguments, outError);
				if (action == null)
					return false;
				CopyAction(actions, action, outResult);
				return true;
			});

		let executeSchema = scope SchemaBuilder();
		executeSchema.Str("id", "the action's id (from action_list)", true);
		server.RegisterTool("action_execute",
			"Run an editor action over the active page, exactly as a menu click or its chord would - through the one funnel every surface uses. REFUSED when the action is not enabled over the active page (action_state says why to look). Runs UNATTENDED: any dialog the action would open is kept off the screen and closed as cancelled, and the result lists it under `suppressedDialogs` - the action then most likely did nothing; use a dedicated tool for that step, or ask the user. Returns {id, executed, suppressedDialogs, enabled, checked} (the state after).",
			executeSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let actions = seams.Context.Actions;
				let action = FindAction(actions, arguments, outError);
				if (action == null)
					return false;
				let subject = actions.Subject;
				if (!EditorActionRegistry.IsEnabled(action, subject))
				{
					outError.AppendF("action '{}' is not enabled over the active page ({}) - page_open the page it needs, or select what it acts on",
						action.Id, (subject != null) ? subject.Title : "no page is active");
					return false;
				}
				let dialogs = JsonValue.MakeArray();
				{
					let unattended = scope UnattendedDialogs(seams.Ui);
					if (actions.Execute(action.Id) case .Err(let code))
					{
						delete dialogs;
						outError.AppendF("action '{}' could not run ({})", action.Id, code);
						return false;
					}
					for (let title in unattended.Suppressed)
						dialogs.Add(JsonValue.MakeString(title));
				}
				let suppressedAny = dialogs.Count > 0;
				outResult.Set("id", JsonValue.MakeString(action.Id));
				outResult.Set("executed", JsonValue.MakeBool(true));
				outResult.Set("suppressedDialogs", dialogs);
				if (suppressedAny)
					outResult.Set("note", JsonValue.MakeString("the action opened a dialog that was closed unattended - it most likely did nothing; use a dedicated tool for that step, or ask the user"));
				let after = actions.Subject;
				outResult.Set("enabled", JsonValue.MakeBool(EditorActionRegistry.IsEnabled(action, after)));
				outResult.Set("checked", JsonValue.MakeBool(EditorActionRegistry.IsChecked(action, after)));
				return true;
			});
	}

	private static StringView KindName(EditorActionKind kind)
	{
		switch (kind)
		{
		case .Toggle: return "toggle";
		case .Window: return "window";
		default: return "command";
		}
	}

	/// One action as the agent sees it, its state over the active page.
	private static JsonValue ActionJson(EditorActionRegistry actions, EditorActionDeclaration action)
	{
		let json = JsonValue.MakeObject();
		CopyAction(actions, action, json);
		return json;
	}

	private static void CopyAction(EditorActionRegistry actions, EditorActionDeclaration action, JsonValue outResult)
	{
		outResult.Set("id", JsonValue.MakeString(action.Id));
		outResult.Set("label", JsonValue.MakeString(action.Label));
		outResult.Set("description", JsonValue.MakeString(action.Description));
		outResult.Set("menuPath", JsonValue.MakeString(action.MenuPath));
		outResult.Set("kind", JsonValue.MakeString(KindName(action.Kind)));
		outResult.Set("readOnly", JsonValue.MakeBool(action.ReadOnly));
		outResult.Set("shortcut", JsonValue.MakeString(actions.Shortcut(action.Id).ToString(.. scope .())));
		let subject = actions.Subject;
		outResult.Set("enabled", JsonValue.MakeBool(EditorActionRegistry.IsEnabled(action, subject)));
		outResult.Set("checked", JsonValue.MakeBool(EditorActionRegistry.IsChecked(action, subject)));
	}

	private static EditorActionDeclaration FindAction(EditorActionRegistry actions, JsonValue arguments, String outError)
	{
		let id = McpTools.ArgString(arguments, "id", .. scope .());
		let action = actions.Find(id);
		if (action == null)
			outError.AppendF("no action '{}' (action_list names them all)", id);
		return action;
	}
}
