using System;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The editing keys, as bindings: every GUI starts with them, in the "textinput" key context a text
// field declares ("textinput multiline" for a text area), so a later binding of the same keys,
// there or deeper, overrides one, and an empty command unbinds it. The keys are the common desktop
// ones (Ctrl with the arrows by word, Home and End by line, Ctrl+Z and Ctrl+Y, Shift+Delete and
// Shift+Insert as well as Ctrl+X, C and V).

static
{
	/// What a single-line field does with Return: it submits.
	public const String cTextSubmitCommand = "text.submit";

	/// Binds the editing keys to the editing commands: in the text contexts (`context` empty), or,
	/// every key a multiline editor takes, in `context` alone (a widget that edits text but is not a
	/// text input to the keymap, so a field inside it is one alone: a code editor's find bar).
	public static void BindTextEditingKeys(Keymap keymap, StringView context = default)
	{
		if (context.Length != 0)
		{
			for (let b in TextEditingKeysDetail.sEverywhere)
				keymap.Bind(b.Keys, TextEditCommandName(b.Command), context);
			for (let b in TextEditingKeysDetail.sMultiline)
				keymap.Bind(b.Keys, TextEditCommandName(b.Command), context);
			return;
		}
		for (let b in TextEditingKeysDetail.sEverywhere)
			keymap.Bind(b.Keys, TextEditCommandName(b.Command), "textinput");
		for (let b in TextEditingKeysDetail.sMultiline)
			keymap.Bind(b.Keys, TextEditCommandName(b.Command), "textinput && multiline");
		keymap.Bind("enter", cTextSubmitCommand, "textinput && !multiline");
		// Where Return breaks a line, Ctrl+Return submits (a comment's or a message's way).
		keymap.Bind("ctrl-enter", cTextSubmitCommand, "textinput && multiline");
	}
}

/// The binding tables TextEditingKeys.bf keeps out of the public surface.
internal static class TextEditingKeysDetail
{
	public struct Binding
	{
		public String Keys;
		public TextEditCommand Command;

		public this(String keys, TextEditCommand command)
		{
			Keys = keys;
			Command = command;
		}
	}

	public static Binding[31] sEverywhere = .(
		.("left", .MoveLeft),
		.("right", .MoveRight),
		.("ctrl-left", .MoveWordLeft),
		.("ctrl-right", .MoveWordRight),
		.("home", .MoveLineStart),
		.("end", .MoveLineEnd),
		.("ctrl-home", .MoveDocumentStart),
		.("ctrl-end", .MoveDocumentEnd),
		.("shift-left", .SelectLeft),
		.("shift-right", .SelectRight),
		.("ctrl-shift-left", .SelectWordLeft),
		.("ctrl-shift-right", .SelectWordRight),
		.("shift-home", .SelectLineStart),
		.("shift-end", .SelectLineEnd),
		.("ctrl-shift-home", .SelectDocumentStart),
		.("ctrl-shift-end", .SelectDocumentEnd),
		.("ctrl-a", .SelectAll),
		.("shift-backspace", .DeleteBackward),
		.("backspace", .DeleteBackward),
		.("delete", .DeleteForward),
		.("ctrl-backspace", .DeleteWordBackward),
		.("ctrl-delete", .DeleteWordForward),
		.("ctrl-z", .Undo),
		.("ctrl-shift-z", .Redo),
		.("ctrl-y", .Redo),
		// The alternates first: the last binding to a command is the one a menu shows.
		.("shift-delete", .Cut),
		.("ctrl-x", .Cut),
		.("ctrl-insert", .Copy),
		.("ctrl-c", .Copy),
		.("shift-insert", .Paste),
		.("ctrl-v", .Paste));

	public static Binding[10] sMultiline = .(
		.("up", .MoveUp),
		.("down", .MoveDown),
		.("pageup", .MovePageUp),
		.("pagedown", .MovePageDown),
		.("shift-up", .SelectUp),
		.("shift-down", .SelectDown),
		.("shift-pageup", .SelectPageUp),
		.("shift-pagedown", .SelectPageDown),
		.("enter", .InsertNewline),
		.("shift-enter", .InsertNewline));
}
