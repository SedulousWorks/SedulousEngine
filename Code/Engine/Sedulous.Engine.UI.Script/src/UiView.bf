using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Script;

/// What every UI handle can do: identity, visibility, enabled. A handle to nothing, a
/// finder's miss or a view the tree dropped, is null but valid: it reads false and empty
/// and its setters do nothing, so a script never dereferences a dead view.
///
/// The handles are plain values a script copies freely; UiHandles resolves them.
[Scriptable, ScriptName("View")]
struct UiView
{
	public uint32 Id = 0;

	public this() {}
	public this(View view) { Id = UiHandles.IdOf(view); }

	public View Resolve() => UiHandles.Resolve(Id);

	[Scriptable]
	public bool IsValid => Resolve() != null;
	[Scriptable]
	public StringView Name => Resolve()?.Name ?? "";
	[Scriptable]
	public bool Visible => Resolve()?.Visibility == .Visible;
	[Scriptable]
	public bool Enabled => Resolve()?.IsEnabled ?? false;
	[Scriptable]
	public void SetVisible(bool value)
	{
		if (let v = Resolve())
			v.Visibility = value ? .Visible : .Hidden;
	}
	[Scriptable]
	public void SetEnabled(bool value)
	{
		if (let v = Resolve())
			v.IsEnabled = value;
	}
}

/// A text label: `label.Text` reads, `label.SetText(...)` writes.
[Scriptable, ScriptName("Label")]
struct UiLabel
{
	public uint32 Id = 0;

	public this() {}
	public this(Label label) { Id = UiHandles.IdOf(label); }

	public Label Resolve() => UiHandles.Resolve<Label>(Id);

	[Scriptable]
	public bool IsValid => Resolve() != null;
	[Scriptable]
	public StringView Name => Resolve()?.Name ?? "";
	[Scriptable]
	public bool Visible => Resolve()?.Visibility == .Visible;
	[Scriptable]
	public bool Enabled => Resolve()?.IsEnabled ?? false;
	[Scriptable]
	public void SetVisible(bool value) { if (let v = Resolve()) v.Visibility = value ? .Visible : .Hidden; }
	[Scriptable]
	public void SetEnabled(bool value) { if (let v = Resolve()) v.IsEnabled = value; }
	[Scriptable]
	public StringView Text => Resolve()?.Text.Value ?? "";
	[Scriptable]
	public void SetText(StringView value) { if (let v = Resolve()) v.SetText(value); }
}

/// A button: `button.Text` its caption, `button.OnClick(fn)` a script function as its
/// click handler, alive as long as the button. The handler NEVER runs inline in click
/// dispatch: it goes through the context's mutation queue and runs at the next drain, a
/// quiescent point where any structural mutation, a screen push or an entity despawn, is
/// safe, which is also where the screen stack's own mutations run.
[Scriptable, ScriptName("Button")]
struct UiButton
{
	public uint32 Id = 0;

	public this() {}
	public this(Button button) { Id = UiHandles.IdOf(button); }

	public Button Resolve() => UiHandles.Resolve<Button>(Id);

	[Scriptable]
	public bool IsValid => Resolve() != null;
	[Scriptable]
	public StringView Name => Resolve()?.Name ?? "";
	[Scriptable]
	public bool Visible => Resolve()?.Visibility == .Visible;
	[Scriptable]
	public bool Enabled => Resolve()?.IsEnabled ?? false;
	[Scriptable]
	public void SetVisible(bool value) { if (let v = Resolve()) v.Visibility = value ? .Visible : .Hidden; }
	[Scriptable]
	public void SetEnabled(bool value) { if (let v = Resolve()) v.IsEnabled = value; }
	[Scriptable]
	public StringView Text => Resolve()?.Text.Value ?? "";
	[Scriptable]
	public void SetText(StringView value) { if (let v = Resolve()) v.SetText(value); }

	/// TAKES the delegate: parked with the button, deleted with it. Null is a no-op.
	[Scriptable]
	public void OnClick(ScriptDelegate handler)
	{
		let button = Resolve();
		if ((button == null) || (handler == null))
		{
			delete handler;
			return;
		}
		UiHandles.Own(button, handler);
		button.OnClick.Add(new (clicked) =>
			{
				let context = (clicked != null) ? clicked.Context : null;
				if (context != null)
					context.MutationQueue.QueueAction(new () => { handler.Invoke(); });
				else
					handler.Invoke(); // nothing is dispatching: a headless button
			});
	}
}

/// A progress or fill bar: `bar.Value` in 0..1.
[Scriptable, ScriptName("ProgressBar")]
struct UiProgressBar
{
	public uint32 Id = 0;

	public this() {}
	public this(ProgressBar bar) { Id = UiHandles.IdOf(bar); }

	public ProgressBar Resolve() => UiHandles.Resolve<ProgressBar>(Id);

	[Scriptable]
	public bool IsValid => Resolve() != null;
	[Scriptable]
	public StringView Name => Resolve()?.Name ?? "";
	[Scriptable]
	public bool Visible => Resolve()?.Visibility == .Visible;
	[Scriptable]
	public bool Enabled => Resolve()?.IsEnabled ?? false;
	[Scriptable]
	public void SetVisible(bool value) { if (let v = Resolve()) v.Visibility = value ? .Visible : .Hidden; }
	[Scriptable]
	public void SetEnabled(bool value) { if (let v = Resolve()) v.IsEnabled = value; }
	[Scriptable]
	public float Value => Resolve()?.Value.Value ?? 0.0f;
	[Scriptable]
	public void SetValue(float value) { if (let v = Resolve()) v.Value.Value = value; }
}

/// A text input: `box.Text` reads, `box.SetText(...)` writes the edited text.
[Scriptable, ScriptName("TextBox")]
struct UiTextBox
{
	public uint32 Id = 0;

	public this() {}
	public this(EditText edit) { Id = UiHandles.IdOf(edit); }

	public EditText Resolve() => UiHandles.Resolve<EditText>(Id);

	[Scriptable]
	public bool IsValid => Resolve() != null;
	[Scriptable]
	public StringView Name => Resolve()?.Name ?? "";
	[Scriptable]
	public bool Visible => Resolve()?.Visibility == .Visible;
	[Scriptable]
	public bool Enabled => Resolve()?.IsEnabled ?? false;
	[Scriptable]
	public void SetVisible(bool value) { if (let v = Resolve()) v.Visibility = value ? .Visible : .Hidden; }
	[Scriptable]
	public void SetEnabled(bool value) { if (let v = Resolve()) v.IsEnabled = value; }
	[Scriptable]
	public StringView Text => Resolve()?.Text ?? "";
	[Scriptable]
	public void SetText(StringView value) { if (let v = Resolve()) v.SetText(value); }
}
