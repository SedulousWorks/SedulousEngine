using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.Engine.UI.Script;

/// The finders every container handle shares: the subtree searched recursively, first
/// match, a miss or the wrong control type a null but valid handle.
static class UiFinders
{
	public static UiView FindByName(ViewGroup group, StringView name) => .((group != null) ? group.FindByName(name) : null);
	public static UiLabel FindLabel(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<Label>(name) : null);
	public static UiButton FindButton(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<ButtonBase>(name) : null);
	public static UiProgressBar FindProgressBar(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<ProgressBar>(name) : null);
	public static UiSlider FindSlider(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<Slider>(name) : null);
	public static UiTextBox FindTextBox(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<EditText>(name) : null);
	public static UiImage FindImage(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<ImageView>(name) : null);
	public static UiGroup FindGroup(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<ViewGroup>(name) : null);
	public static UiScreen FindScreen(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<UIScreen>(name) : null);
	public static int32 ChildCount(ViewGroup group) => (group != null) ? (int32)group.ChildCount : 0;
	public static UiView ChildAt(ViewGroup group, int32 index)
		=> .(((group != null) && (index >= 0) && (index < group.ChildCount)) ? group.GetChildAt(index) : null);
}

/// A container: the search surface. Every finder searches this group's subtree.
[Scriptable, ScriptName("ViewGroup")]
struct UiGroup
{
	public uint32 Id = 0;

	public this() {}
	public this(ViewGroup group) { Id = UiHandles.IdOf(group); }

	public ViewGroup Resolve() => UiHandles.Resolve<ViewGroup>(Id);

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
	public float Opacity => Resolve()?.Opacity ?? 0.0f;
	[Scriptable]
	public void SetOpacity(float value) { UiHandles.SetOpacity(Resolve(), value); }
	[Scriptable]
	public void FadeTo(float opacity, float seconds, Ease ease = .InOut) { UiHandles.FadeTo(Resolve(), opacity, seconds, ease); }
	/// The offset in pixels from where layout put the view, applied as it draws and hit tests,
	/// so moving it costs no relayout (a marker on a minimap).
	[Scriptable]
	public Float2 Translation => UiHandles.Translation(Resolve());
	[Scriptable]
	public void SetTranslation(float x, float y) { UiHandles.SetTranslation(Resolve(), x, y); }
	/// Degrees, clockwise on screen, about the view's centre.
	[Scriptable]
	public float Rotation => UiHandles.Rotation(Resolve());
	[Scriptable]
	public void SetRotation(float degrees) { UiHandles.SetRotation(Resolve(), degrees); }
	/// Moves the offset to (x, y) over `seconds` (zero sets it); a move of its own, so it runs
	/// beside a fade.
	[Scriptable]
	public void MoveTo(float x, float y, float seconds, Ease ease = .InOut) { UiHandles.MoveTo(Resolve(), x, y, seconds, ease); }
	/// A uniform scale about the view's centre, as drawn (layout is unchanged).
	[Scriptable]
	public float Scale => UiHandles.Scale(Resolve());
	[Scriptable]
	public void SetScale(float value) { UiHandles.SetScale(Resolve(), value); }
	[Scriptable]
	public void ScaleTo(float scale, float seconds, Ease ease = .InOut) { UiHandles.ScaleTo(Resolve(), scale, seconds, ease); }
	[Scriptable]
	public void RotateTo(float degrees, float seconds, Ease ease = .InOut) { UiHandles.RotateTo(Resolve(), degrees, seconds, ease); }
	/// From the normal size out to `peak` times it and back over `seconds`: a counter that
	/// changed.
	[Scriptable]
	public void Pulse(float peak, float seconds) { UiHandles.Pulse(Resolve(), peak, seconds); }
	[Scriptable]
	public int32 ChildCount => UiFinders.ChildCount(Resolve());
	[Scriptable]
	public UiView ChildAt(int32 index) => UiFinders.ChildAt(Resolve(), index);
	[Scriptable]
	public UiView Find(StringView name) => UiFinders.FindByName(Resolve(), name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(Resolve(), name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(Resolve(), name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(Resolve(), name);
	[Scriptable]
	public UiSlider FindSlider(StringView name) => UiFinders.FindSlider(Resolve(), name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(Resolve(), name);
	[Scriptable]
	public UiImage FindImage(StringView name) => UiFinders.FindImage(Resolve(), name);
	[Scriptable]
	public UiGroup FindGroup(StringView name) => UiFinders.FindGroup(Resolve(), name);
	[Scriptable]
	public UiScreen FindScreen(StringView name) => UiFinders.FindScreen(Resolve(), name);
}

/// A screen on the stack: a container with the same finders, scoped to one screen so a
/// lookup can be narrowed, `Ui.Top.FindLabel(...)`.
[Scriptable, ScriptName("Screen")]
struct UiScreen
{
	public uint32 Id = 0;

	public this() {}
	public this(UIScreen screen) { Id = UiHandles.IdOf(screen); }

	public UIScreen Resolve() => UiHandles.Resolve<UIScreen>(Id);

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
	public float Opacity => Resolve()?.Opacity ?? 0.0f;
	[Scriptable]
	public void SetOpacity(float value) { UiHandles.SetOpacity(Resolve(), value); }
	[Scriptable]
	public void FadeTo(float opacity, float seconds, Ease ease = .InOut) { UiHandles.FadeTo(Resolve(), opacity, seconds, ease); }
	/// The offset in pixels from where layout put the view, applied as it draws and hit tests,
	/// so moving it costs no relayout (a marker on a minimap).
	[Scriptable]
	public Float2 Translation => UiHandles.Translation(Resolve());
	[Scriptable]
	public void SetTranslation(float x, float y) { UiHandles.SetTranslation(Resolve(), x, y); }
	/// Degrees, clockwise on screen, about the view's centre.
	[Scriptable]
	public float Rotation => UiHandles.Rotation(Resolve());
	[Scriptable]
	public void SetRotation(float degrees) { UiHandles.SetRotation(Resolve(), degrees); }
	/// Moves the offset to (x, y) over `seconds` (zero sets it); a move of its own, so it runs
	/// beside a fade.
	[Scriptable]
	public void MoveTo(float x, float y, float seconds, Ease ease = .InOut) { UiHandles.MoveTo(Resolve(), x, y, seconds, ease); }
	/// A uniform scale about the view's centre, as drawn (layout is unchanged).
	[Scriptable]
	public float Scale => UiHandles.Scale(Resolve());
	[Scriptable]
	public void SetScale(float value) { UiHandles.SetScale(Resolve(), value); }
	[Scriptable]
	public void ScaleTo(float scale, float seconds, Ease ease = .InOut) { UiHandles.ScaleTo(Resolve(), scale, seconds, ease); }
	[Scriptable]
	public void RotateTo(float degrees, float seconds, Ease ease = .InOut) { UiHandles.RotateTo(Resolve(), degrees, seconds, ease); }
	/// From the normal size out to `peak` times it and back over `seconds`: a counter that
	/// changed.
	[Scriptable]
	public void Pulse(float peak, float seconds) { UiHandles.Pulse(Resolve(), peak, seconds); }
	[Scriptable]
	public int32 ChildCount => UiFinders.ChildCount(Resolve());
	[Scriptable]
	public UiView ChildAt(int32 index) => UiFinders.ChildAt(Resolve(), index);
	[Scriptable]
	public UiView Find(StringView name) => UiFinders.FindByName(Resolve(), name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(Resolve(), name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(Resolve(), name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(Resolve(), name);
	[Scriptable]
	public UiSlider FindSlider(StringView name) => UiFinders.FindSlider(Resolve(), name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(Resolve(), name);
	[Scriptable]
	public UiImage FindImage(StringView name) => UiFinders.FindImage(Resolve(), name);
	[Scriptable]
	public UiGroup FindGroup(StringView name) => UiFinders.FindGroup(Resolve(), name);
}
