using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Pre-built message dialogs for common scenarios.
public static class MessageBox
{
	/// Shows a simple message dialog with an OK button.
	public static void Show(GUIContext context, StringView message, StringView title = "Message")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new TextBlock(message);
		content.TextWrapping = .Wrap;
		dialog.Content = content;

		dialog.AddButton("OK", .OK);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		// Auto-delete on close
		dialog.Closed.Subscribe(new (d, r) => {
			context.QueueDelete(d);
		});
	}

	/// Shows an information dialog with an OK button.
	public static void ShowInfo(GUIContext context, StringView message, StringView title = "Information")
	{
		Show(context, message, title);
	}

	/// Shows a warning dialog with an OK button.
	public static void ShowWarning(GUIContext context, StringView message, StringView title = "Warning")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new StackPanel();
		content.Orientation = .Horizontal;
		content.Spacing = 12;

		// Warning icon (represented as colored text for now)
		let icon = new TextBlock("!");
		let theme = context.Theme;
		icon.FontSize = theme?.MessageBoxIconSize ?? 24;
		icon.Foreground = theme?.Palette.Warning ?? Color(255, 200, 0, 255);
		icon.VerticalAlignment = .Center;
		content.AddChild(icon);

		let text = new TextBlock(message);
		text.TextWrapping = .Wrap;
		text.VerticalAlignment = .Center;
		content.AddChild(text);

		dialog.Content = content;
		dialog.AddButton("OK", .OK);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		dialog.Closed.Subscribe(new (d, r) => {
			context.QueueDelete(d);
		});
	}

	/// Shows an error dialog with an OK button.
	public static void ShowError(GUIContext context, StringView message, StringView title = "Error")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new StackPanel();
		content.Orientation = .Horizontal;
		content.Spacing = 12;

		// Error icon (represented as colored text for now)
		let icon = new TextBlock("X");
		let theme = context.Theme;
		icon.FontSize = theme?.MessageBoxIconSize ?? 24;
		icon.Foreground = theme?.Palette.Error ?? Color(220, 50, 50, 255);
		icon.VerticalAlignment = .Center;
		content.AddChild(icon);

		let text = new TextBlock(message);
		text.TextWrapping = .Wrap;
		text.VerticalAlignment = .Center;
		content.AddChild(text);

		dialog.Content = content;
		dialog.AddButton("OK", .OK);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		dialog.Closed.Subscribe(new (d, r) => {
			context.QueueDelete(d);
		});
	}

	/// Shows a question dialog with Yes/No buttons.
	/// Returns the dialog for result tracking via Closed event.
	public static Dialog ShowQuestion(GUIContext context, StringView message, StringView title = "Question")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new StackPanel();
		content.Orientation = .Horizontal;
		content.Spacing = 12;

		// Question icon
		let icon = new TextBlock("?");
		let theme = context.Theme;
		icon.FontSize = theme?.MessageBoxIconSize ?? 24;
		icon.Foreground = theme?.Palette.Primary ?? Color(100, 150, 255, 255);
		icon.VerticalAlignment = .Center;
		content.AddChild(icon);

		let text = new TextBlock(message);
		text.TextWrapping = .Wrap;
		text.VerticalAlignment = .Center;
		content.AddChild(text);

		dialog.Content = content;
		dialog.AddButton("Yes", .Yes);
		dialog.AddButton("No", .No);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		return dialog;
	}

	/// Shows a confirmation dialog with OK/Cancel buttons.
	/// Returns the dialog for result tracking via Closed event.
	public static Dialog ShowConfirm(GUIContext context, StringView message, StringView title = "Confirm")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new TextBlock(message);
		content.TextWrapping = .Wrap;
		dialog.Content = content;

		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		return dialog;
	}

	/// Shows a retry/abort dialog.
	/// Returns the dialog for result tracking via Closed event.
	public static Dialog ShowRetryAbort(GUIContext context, StringView message, StringView title = "Error")
	{
		let dialog = new Dialog(title);
		dialog.Padding = .(12, 8, 12, 8);

		let content = new TextBlock(message);
		content.TextWrapping = .Wrap;
		dialog.Content = content;

		dialog.AddButton("Retry", .Retry);
		dialog.AddButton("Abort", .Abort);

		dialog.OnAttachedToContext(context);
		dialog.Show();

		return dialog;
	}
}
