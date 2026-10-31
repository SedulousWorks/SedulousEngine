using System;

namespace Sedulous.UI.Toolkit;

/// One notification to show.
///
/// The strings are BORROWED: Show copies them into the card's views before returning, so a
/// caller can build a request over scope text.
struct ToastRequest
{
	public StringView Message = default;
	public ToastSeverity Severity = .Info;
	/// Zero or less is STICKY: it stays until the player closes it or the app dismisses it.
	/// Errors and anything carrying an action should be sticky, because a message that needs a
	/// decision must not time out while the player is reading it.
	public float DurationSeconds = 5.0f;
	/// Empty means no action button.
	public StringView ActionLabel = default;
	/// OWNERSHIP transfers to Show. Fired on an action click, after which the toast closes.
	public delegate void() OnAction = null;

	public this() {}

	public this(StringView message)
	{
		Message = message;
	}

	public this(StringView message, ToastSeverity severity)
	{
		Message = message;
		Severity = severity;
	}
}
