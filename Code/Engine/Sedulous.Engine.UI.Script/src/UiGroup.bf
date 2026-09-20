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
	public static UiButton FindButton(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<Button>(name) : null);
	public static UiProgressBar FindProgressBar(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<ProgressBar>(name) : null);
	public static UiTextBox FindTextBox(ViewGroup group, StringView name) => .((group != null) ? group.FindByName<EditText>(name) : null);
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
	public int32 ChildCount => UiFinders.ChildCount(Resolve());
	[Scriptable]
	public UiView ChildAt(int32 index) => UiFinders.ChildAt(Resolve(), index);
	[Scriptable]
	public UiView FindByName(StringView name) => UiFinders.FindByName(Resolve(), name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(Resolve(), name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(Resolve(), name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(Resolve(), name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(Resolve(), name);
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
	public int32 ChildCount => UiFinders.ChildCount(Resolve());
	[Scriptable]
	public UiView ChildAt(int32 index) => UiFinders.ChildAt(Resolve(), index);
	[Scriptable]
	public UiView FindByName(StringView name) => UiFinders.FindByName(Resolve(), name);
	[Scriptable]
	public UiLabel FindLabel(StringView name) => UiFinders.FindLabel(Resolve(), name);
	[Scriptable]
	public UiButton FindButton(StringView name) => UiFinders.FindButton(Resolve(), name);
	[Scriptable]
	public UiProgressBar FindProgressBar(StringView name) => UiFinders.FindProgressBar(Resolve(), name);
	[Scriptable]
	public UiTextBox FindTextBox(StringView name) => UiFinders.FindTextBox(Resolve(), name);
	[Scriptable]
	public UiGroup FindGroup(StringView name) => UiFinders.FindGroup(Resolve(), name);
}
