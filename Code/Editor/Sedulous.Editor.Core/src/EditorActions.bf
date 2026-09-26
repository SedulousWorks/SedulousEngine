using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.Core;

/// Editor actions: one declaration per user command, and the registry every surface is built
/// from - the menu bar (from MenuPath), the shortcuts (from the effective chord), the toolbars
/// (by id), the context menus, and the MCP action bridge. A surface never binds a command of
/// its own; it asks the registry whether an action is enabled or checked and tells it to
/// Execute. The declaration carries what every surface needs to show it and the three bindings
/// that ARE the command: Execute, Enabled (pulled, never pushed) and Checked.
///
/// Actions are nullary from every surface's and the agent's point of view; what they run OVER
/// is a SUBJECT PAGE the surface supplies: the active page for the menu bar, a chord and the
/// MCP bridge (the registry asks its ActiveSubject), a page's OWN page for that page's toolbar
/// (a split layout shows two pages and only one is active). A binding reaches what the subject
/// publishes with `page as ISceneEditorPage`. Anything that takes a real parameter is a tool or
/// a list-driven menu, not an action.
///
/// Registration is explicit, in the composition roots (the application for the editor-wide
/// set, each domain's RegisterEditor for its own). An id registered twice is a programming
/// error at boot, refused and logged, so the surfaces never see two actions with one name.

/// A keyboard chord; an unset key means no shortcut.
struct EditorShortcut : IEquatable<EditorShortcut>
{
	public KeyCode Key = .Unknown;
	public KeyModifiers Modifiers = .None;

	public this() {}

	public this(KeyCode key, KeyModifiers modifiers = .None)
	{
		Key = key;
		Modifiers = modifiers;
	}

	public bool IsSet => Key != .Unknown;

	public bool Equals(EditorShortcut other) => (Key == other.Key) && (Modifiers == other.Modifiers);

	public static bool operator==(EditorShortcut a, EditorShortcut b) => a.Equals(b);

	/// The chord as a shortcut column or a tool result shows it: "Ctrl+Shift+Z", "F5",
	/// "Delete"; nothing when unset.
	public override void ToString(String outText)
	{
		if (!IsSet)
			return;
		if (Modifiers.HasAny(.Ctrl))
			outText.Append("Ctrl+");
		if (Modifiers.HasAny(.Alt))
			outText.Append("Alt+");
		if (Modifiers.HasAny(.Shift))
			outText.Append("Shift+");
		outText.Append(Key.DisplayName);
	}
}

enum EditorActionKind
{
	/// Does something.
	Command,
	/// Flips a state the surfaces show as checked.
	Toggle,
	/// Shows or hides a panel; checked while shown.
	Window
}

class EditorActionDeclaration
{
	/// Stable and dotted: "file.save", "edit.undo", "scene.simulate.start". The identity the
	/// shortcut overrides and the MCP bridge use; never shown as a label.
	public String Id = new .() ~ delete _;
	/// "Save" (menus, toolbars).
	public String Label = new .() ~ delete _;
	/// "Save the active page" (tooltips, MCP).
	public String Description = new .() ~ delete _;
	/// The menu bar is generated from these: "File/Save", "Scene/Simulate/Play". Empty keeps
	/// the action out of the bar. Items order by MenuOrder within a menu, with a separator
	/// between order bands (hundreds).
	public String MenuPath = new .() ~ delete _;
	public int32 MenuOrder = 0;
	/// An icon by name, resolved by the surface that draws it; empty is text only.
	public String Icon = new .() ~ delete _;
	/// The default chord; the user's override wins (Rebind).
	public EditorShortcut Shortcut = .();
	/// A second chord the action also answers to, fixed (Ctrl+Y beside Ctrl+Shift+Z for
	/// redo); never rebound, counted as taken.
	public EditorShortcut AlternateShortcut = .();
	public EditorActionKind Kind = .Command;
	/// Changes nothing: the MCP readOnlyHint.
	public bool ReadOnly = false;

	/// The bindings, over the subject page: null when no page is the subject, and an
	/// editor-wide action ignores it. OWNED.
	public delegate void(EditorPage subject) Execute ~ delete _;
	/// Null is always enabled. OWNED.
	public delegate bool(EditorPage subject) Enabled ~ delete _;
	/// A Toggle or Window's state; null is never checked. OWNED.
	public delegate bool(EditorPage subject) Checked ~ delete _;

	public this() {}

	public this(StringView id, StringView label, StringView description = "", StringView menuPath = "", int32 menuOrder = 0)
	{
		Id.Set(id);
		Label.Set(label);
		Description.Set(description);
		MenuPath.Set(menuPath);
		MenuOrder = menuOrder;
	}
}

class EditorActionRegistry
{
	private List<EditorActionDeclaration> mActions = new .() ~ DeleteContainerAndItems!(_);
	/// By id; the keys are the declarations' own Id strings.
	private Dictionary<StringView, EditorActionDeclaration> mIndex = new .() ~ delete _;
	/// The user's chords, by id (owned keys).
	private Dictionary<String, EditorShortcut> mOverrides = new .() ~ DeleteDictionaryAndKeys!(_);

	/// Registrations and rebinds; the surfaces that cache (the menu bar, the shortcut table)
	/// rebuild on it. A subscriber removes its delegate before it goes.
	public Event<delegate void()> OnActionsChanged ~ _.Dispose();

	/// The subject the nullary calls run over: the context wires it to its active page. Null
	/// (a bare registry) means no subject. OWNED.
	public delegate EditorPage() ActiveSubject ~ delete _;

	public EditorPage Subject => (ActiveSubject != null) ? ActiveSubject() : null;

	/// Registers a declaration, TAKING OWNERSHIP. Refused (false, logged, the declaration
	/// deleted) when the id or label is empty, when Execute is unset, or when the id is already
	/// registered: each a mistake in a composition root, never a runtime condition.
	public bool Register(EditorActionDeclaration declaration)
	{
		if (declaration.Id.IsEmpty || declaration.Label.IsEmpty || (declaration.Execute == null))
		{
			GlobalLog(.Error, "Editor: action '{}' refused: an id, a label and Execute are required", declaration.Id);
			delete declaration;
			return false;
		}
		if (mIndex.ContainsKey(declaration.Id))
		{
			GlobalLog(.Error, "Editor: action '{}' registered twice; the first stands", declaration.Id);
			delete declaration;
			return false;
		}
		mActions.Add(declaration);
		mIndex[declaration.Id] = declaration;
		OnActionsChanged();
		return true;
	}

	public EditorActionDeclaration Find(StringView id)
	{
		if (mIndex.TryGetValue(id, let action))
			return action;
		return null;
	}

	/// Every action, in registration order. BORROWED.
	public List<EditorActionDeclaration> Actions => mActions;
	public int Count => mActions.Count;

	/// Unknown ids are disabled and unchecked: a surface asking about a name nobody registered
	/// shows nothing runnable.
	public bool IsEnabled(StringView id) => IsEnabled(id, Subject);

	public bool IsEnabled(StringView id, EditorPage subject)
	{
		let action = Find(id);
		return (action != null) && IsEnabled(action, subject);
	}

	public static bool IsEnabled(EditorActionDeclaration action, EditorPage subject)
		=> (action.Enabled == null) || action.Enabled(subject);

	public bool IsChecked(StringView id) => IsChecked(id, Subject);

	public bool IsChecked(StringView id, EditorPage subject)
	{
		let action = Find(id);
		return (action != null) && IsChecked(action, subject);
	}

	public static bool IsChecked(EditorActionDeclaration action, EditorPage subject)
		=> (action.Checked != null) && action.Checked(subject);

	/// The one funnel: a menu click, a chord, a toolbar click and the MCP bridge all execute
	/// through here, over the active subject or the page a surface names. NotFound for an
	/// unknown id; NotSupported when the action is not enabled over that subject (the surfaces
	/// never offer a disabled action, so this is the bridge's refusal).
	public Result<void, ErrorCode> Execute(StringView id) => Execute(id, Subject);

	public Result<void, ErrorCode> Execute(StringView id, EditorPage subject)
	{
		let action = Find(id);
		if (action == null)
			return .Err(.NotFound);
		if (!IsEnabled(action, subject))
			return .Err(.NotSupported);
		action.Execute(subject);
		return .Ok;
	}

	/// The effective chord: the user's override when one is set (an unset override is "no
	/// shortcut" on purpose), else the declaration's default.
	public EditorShortcut Shortcut(StringView id)
	{
		let action = Find(id);
		if (action == null)
			return .();
		if (mOverrides.TryGetValueAlt(id, let chord))
			return chord;
		return action.Shortcut;
	}

	/// The declaration's alternate chord (never overridden); unset for most actions.
	public EditorShortcut AlternateShortcut(StringView id)
	{
		let action = Find(id);
		return (action != null) ? action.AlternateShortcut : .();
	}

	/// The action holding a chord, effective bindings and alternates considered; null when
	/// free.
	public EditorActionDeclaration HolderOf(EditorShortcut chord)
	{
		if (!chord.IsSet)
			return null;
		for (let action in mActions)
		{
			if ((Shortcut(action.Id) == chord) || (action.AlternateShortcut == chord))
				return action;
		}
		return null;
	}

	/// Binds the user's chord to an action (an unset chord is no shortcut). NotFound for an
	/// unknown id; AlreadyExists when another action holds the chord, named in `outHolder` so
	/// the settings page can say so.
	public Result<void, ErrorCode> Rebind(StringView id, EditorShortcut chord, out EditorActionDeclaration outHolder)
	{
		outHolder = null;
		let action = Find(id);
		if (action == null)
			return .Err(.NotFound);
		let taken = HolderOf(chord);
		if ((taken != null) && (taken != action))
		{
			outHolder = taken;
			return .Err(.AlreadyExists);
		}
		if (mOverrides.TryGetAlt(id, let key, ?))
			mOverrides[key] = chord;
		else
			mOverrides[new String(id)] = chord;
		OnActionsChanged();
		return .Ok;
	}

	public Result<void, ErrorCode> Rebind(StringView id, EditorShortcut chord) => Rebind(id, chord, ?);

	/// Forgets the user's override: the declaration's default chord applies again.
	public void ResetShortcut(StringView id)
	{
		if (mOverrides.GetAndRemoveAlt(id) case .Ok(let removed))
		{
			delete removed.key;
			OnActionsChanged();
		}
	}

	public bool HasOverride(StringView id) => mOverrides.ContainsKeyAlt(id);

	/// Items for the actions `ids`, in that order, appended to a context menu over `subject`:
	/// each labelled from its declaration, enabled as the registry answers now, executing
	/// through the registry over the subject. An id nobody registered adds nothing. Returns how
	/// many were added.
	public int AppendActionItems(ContextMenu menu, EditorPage subject, params StringView[] ids)
	{
		int added = 0;
		for (let id in ids)
		{
			let action = Find(id);
			if (action == null)
				continue;
			menu.AddItem(action.Label, new [=this, =action, =subject]() => { Execute(action.Id, subject).IgnoreError(); }, IsEnabled(action, subject));
			added++;
		}
		return added;
	}
}
