using System;
using System.Collections;

namespace Sedulous.GUI;

// One command model: a command has an id, a label, an icon, and enabled and checked states;
// buttons, menu items, shortcuts and gamepad buttons name it by id, so one disabled command greys
// every control bound to it. Its dispatch follows GPUI's (`zed/crates/gpui/src/key_dispatch.rs`):
// running a command walks the focus path, capture handlers from the root down, then bubble
// handlers from the focused widget up, a bubble handler stopping it unless it lets it go on; and
// a command is available (its controls lit) when it is enabled and a handler for it is on the
// focus path, so moving focus greys and lights the right controls with no bookkeeping.
// Availability is observable: a control's binding follows focus, the command's enabled state and
// the handlers.

class Command
{
	private String mId = new .() ~ delete _;
	private StringProperty mLabel = new .() ~ delete _;
	private StringProperty mIcon = new .() ~ delete _;
	private Property<bool> mEnabled = new .(true) ~ delete _;
	private Property<bool> mChecked = new .(false) ~ delete _;
	private StringProperty mDisabledReason = new .() ~ delete _;

	public this(StringView id)
	{
		mId.Set(id);
	}

	public StringView Id => mId;

	/// A read a binding follows, as are the rest.
	public StringView Label
	{
		get => mLabel.Get();
		set => mLabel.Set(value);
	}

	public StringView Icon
	{
		get => mIcon.Get();
		set => mIcon.Set(value);
	}

	public bool Enabled
	{
		get => mEnabled.Get();
		set => mEnabled.Set(value);
	}

	public bool Checked
	{
		get => mChecked.Get();
		set => mChecked.Set(value);
	}

	/// Why it is disabled ("Nothing to save"), which a control bound to it shows while it is (a
	/// tool bar's tooltip).
	public StringView DisabledReason
	{
		get => mDisabledReason.Get();
		set => mDisabledReason.Set(value);
	}
}

/// When a node's handler runs: on the way down from the root, or on the way up from the focused
/// widget (the usual place).
enum CommandPhase : uint8
{
	case Capture;
	case Bubble;
}

/// What a handler is given: the command, and a way to let it go on past this handler.
struct CommandEvent
{
	public StringView Id;
	public CommandPhase Phase = .Bubble;
	/// A bubble handler sets it to let the command go on up.
	public bool Propagate = false;
	/// A capture handler sets it to take the command: none below it, nor any bubble handler, runs.
	public bool Stop = false;
}

typealias CommandHandler = delegate void(ref CommandEvent);

/// What a control bound to a command is told of its state (Node.OnBoundCommandState).
struct BoundCommandState
{
	/// Enabled, with a handler on the focus path.
	public bool Available = false;
	public bool Checked = false;
	/// Why it is not available: the command's disabled reason while it is disabled, else empty (no
	/// handler where the focus is says nothing a user could act on).
	public StringView Reason;
}

/// A GUI's commands, by id.
class CommandSet
{
	private List<Command> mCommands = new .() ~ DeleteContainerAndItems!(_);
	private Observable mChanged = new .() ~ delete _;

	/// The command `id`, defined now if new (enabled, its label the id until one is set).
	public Command Define(StringView id)
	{
		if (let found = Find(id))
			return found;
		let command = new Command(id);
		mCommands.Add(command);
		command.Label = id;
		mChanged.Notify();
		return command;
	}

	public Command Find(StringView id)
	{
		for (let command in mCommands)
		{
			if (command.Id == id)
				return command;
		}
		return null;
	}

	/// Something that decides availability changed (a definition, a handler added or removed).
	public void NotifyChanged() => mChanged.Notify();
	public void TrackChanges() => mChanged.Track();
}
