using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Input;
using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.UI;

namespace Sedulous.Editor.Input.Tests;

/// The input map editor's registration, its headless edits, and its page: the outline and the
/// two panes, a binding added by source, and a field's edits merged into one undo step.
class InputMapEditTests
{
	[Test]
	public static void RegisteringRoutesInputMapAssetToTheFactory()
	{
		let context = scope EditorContext();
		InputEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(InputMapAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(InputMapAsset)));
	}

	[Test]
	public static void LookupsAreGuardedAndFreshBindingsFollowTheKind()
	{
		let asset = scope InputMapAsset();
		asset.SeedDefaultContent();
		let map = asset.Map;
		Test.Assert(InputMapEdit.SetAt(map, 0) != null);
		Test.Assert(InputMapEdit.SetAt(map, 1) == null);
		Test.Assert(InputMapEdit.ActionAt(map, 0, 3).Name == "Fire");
		Test.Assert(InputMapEdit.ActionAt(map, 0, 4) == null);
		Test.Assert(!InputMapEdit.HasBinding(map, 0, 0, 0));
		let move = InputMapEdit.ActionAt(map, 0, 0);
		move.Bindings.Add(InputMapEdit.FreshBinding(move.Kind));
		Test.Assert(InputMapEdit.HasBinding(map, 0, 0, 0));
		Test.Assert(move.Bindings[0].Source == .GamepadStick);
		Test.Assert(InputMapEdit.FreshBinding(.Button).Source == .Key);
	}

	[Test]
	public static void CyclingTheSourceWalksTheValidListOnAFreshBinding()
	{
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(.Button, valid);
		Test.Assert(valid.Count >= 2);
		var binding = Binding();
		binding.Source = valid[0];
		binding.Scale = 7.0f;
		let next = InputMapEdit.CycleSource(.Button, binding);
		Test.Assert(next.Source == valid[1]);
		Test.Assert(next.Scale == 1.0f); // the source specifics reset
		// The last wraps to the first.
		var last = Binding();
		last.Source = valid[valid.Count - 1];
		Test.Assert(InputMapEdit.CycleSource(.Button, last).Source == valid[0]);
	}

	[Test]
	public static void TheListenFilterFollowsTheActionKind()
	{
		let button = InputMapEdit.FilterFor(.Button, false);
		Test.Assert(button.Keys && button.MouseButtons && button.GamepadButtons && !button.GamepadAxes && !button.GamepadSticks);
		let axis = InputMapEdit.FilterFor(.Axis1D, false);
		Test.Assert(axis.Keys && axis.GamepadAxes && !axis.GamepadSticks);
		let stick = InputMapEdit.FilterFor(.Axis2D, false);
		Test.Assert(!stick.Keys && !stick.MouseButtons && !stick.GamepadButtons && stick.GamepadSticks);
		let direction = InputMapEdit.FilterFor(.Axis2D, true);
		Test.Assert(direction.Keys && !direction.MouseButtons && !direction.GamepadButtons);
	}

	[Test]
	public static void ACaptureLandsInTheBindingOrOneCompositeDirection()
	{
		let asset = scope InputMapAsset();
		asset.SeedDefaultContent();
		let map = asset.Map;
		let jump = InputMapEdit.ActionAt(map, 0, 2);
		jump.Bindings.Add(InputMapEdit.FreshBinding(.Button));
		var captured = Binding();
		captured.Source = .MouseButton;
		captured.Code = 3;
		InputMapEdit.ApplyCapture(map, 0, 2, 0, -1, captured);
		Test.Assert((jump.Bindings[0].Source == .MouseButton) && (jump.Bindings[0].Code == 3));

		let move = InputMapEdit.ActionAt(map, 0, 0);
		var composite = Binding();
		composite.Source = .Composite2D;
		move.Bindings.Add(composite);
		var key = Binding();
		key.Code = 42;
		InputMapEdit.ApplyCapture(map, 0, 0, 0, 3, key);
		Test.Assert((move.Bindings[0].Source == .Composite2D) && (move.Bindings[0].PosY == 42) && (move.Bindings[0].NegX == 0));
		// Out of range slots are ignored.
		InputMapEdit.ApplyCapture(map, 0, 0, 5, -1, key);
		InputMapEdit.ApplyCapture(map, 9, 0, 0, -1, key);
		Test.Assert(move.Bindings.Count == 1);
	}

	private static void CollectViews<T>(View view, List<T> outViews) where T : View
	{
		if (let typed = view as T)
			outViews.Add(typed);
		if (let group = view as ViewGroup)
		{
			for (int i < group.VisualChildCount)
			{
				if (let child = group.GetVisualChild(i))
					CollectViews(child, outViews);
			}
		}
	}

	/// A scratch project holding one input map: Gameplay (Move: four keys and a stick; Jump: a
	/// key) and Menu (Back: a key), open in the page.
	private class PageFixture
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public InputMapEditorPage Page;

		public this()
		{
			InputPipeline.RegisterAll(); // the instance's type, written and read back
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_input_map_page", Dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Controls", typeof(InputMapAsset).GetFullName(.. scope .()));
			Test.Assert(instance != null);
			let asset = scope InputMapAsset();
			let gameplay = new ActionSet();
			gameplay.Name.Set("Gameplay");
			let move = new InputAction();
			move.Name.Set("Move");
			move.Kind = .Axis2D;
			var keys = Binding();
			keys.Source = .Composite2D;
			move.Bindings.Add(keys);
			move.Bindings.Add(InputMapEdit.FreshBinding(ActionKind.Axis2D));
			gameplay.Actions.Add(move);
			let jump = new InputAction();
			jump.Name.Set("Jump");
			jump.Bindings.Add(InputMapEdit.FreshBinding(ActionKind.Button));
			gameplay.Actions.Add(jump);
			asset.Map.Sets.Add(gameplay);
			let menu = new ActionSet();
			menu.Name.Set("Menu");
			let back = new InputAction();
			back.Name.Set("Back");
			back.Bindings.Add(InputMapEdit.FreshBinding(ActionKind.Button));
			menu.Actions.Add(back);
			asset.Map.Sets.Add(menu);
			Test.Assert(instance.WriteObject(asset) case .Ok);
			Page = new InputMapEditorPage(Context, instance);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			DeleteAndNullify!(Project);
			RemoveDirectoryRecursive(Dir);
		}

		public int Count<T>() where T : View
		{
			let found = scope List<T>();
			CollectViews(Page.Body, found);
			return found.Count;
		}
	}

	[Test]
	public static void TheOutlineIsACollapsibleSectionPerSetWithItsActionsCards()
	{
		let f = scope PageFixture();
		Test.Assert(f.Page.CurrentLayout == .Outline);
		Test.Assert(f.Count<Expander>() == 2); // Gameplay, Menu
		// Key caps: Move's four keys and its stick, Jump's key, Back's key.
		let capsOpen = f.Count<Button>();

		// A collapsed set stays collapsed across a rebuild (by name), its body hidden.
		f.Page.SetSetCollapsed(0, true);
		Test.Assert(f.Page.IsSetCollapsed(0));
		f.Page.RebuildNow();
		let sections = scope List<Expander>();
		CollectViews(f.Page.Body, sections);
		Test.Assert(sections.Count == 2);
		Test.Assert(!sections[0].IsExpanded);
		Test.Assert(sections[1].IsExpanded);
		// Its title is the set's name, editable in place.
		let title = sections[0].HeaderTitle as EditableLabel;
		Test.Assert((title != null) && (title.Text == "Gameplay"));
		f.Page.SetSetCollapsed(0, false);
		f.Page.RebuildNow();
		Test.Assert(f.Count<Button>() == capsOpen);
	}

	[Test]
	public static void TwoPanesListTheSetsAndEditTheSelectedOne()
	{
		let f = scope PageFixture();
		f.Page.SetLayout(.TwoPanes);
		f.Page.RebuildNow();
		Test.Assert(f.Count<Expander>() == 0);

		// The selected action's bindings: Move's composite (four caps) and stick (one).
		f.Page.Select(0, 0);
		f.Page.RebuildNow();
		let labels = scope List<Label>();
		CollectViews(f.Page.Body, labels);
		var fourKeys = false;
		var stick = false;
		for (let label in labels)
		{
			fourKeys |= label.Text.Value == "Four keys";
			stick |= label.Text.Value == "Gamepad stick";
		}
		Test.Assert(fourKeys && stick);

		// A set selected: its name and priority.
		f.Page.Select(1, -1);
		f.Page.RebuildNow();
		Test.Assert((f.Page.SelectedSet == 1) && (f.Page.SelectedAction < 0));

		// A selection past the end lands on something that exists.
		f.Page.Select(1, 5);
		f.Page.RebuildNow();
		Test.Assert(f.Page.SelectedAction == 0);
	}

	[Test]
	public static void ABindingIsAddedBySourceAndAFieldsEditsAreOneUndo()
	{
		let f = scope PageFixture();
		f.Page.AddBinding(0, 1, .GamepadButton);
		let jump = f.Page.Map.Sets[0].Actions[1];
		Test.Assert((jump.Bindings.Count == 2) && (jump.Bindings[1].Source == .GamepadButton));
		f.Page.Commands.Undo();
		Test.Assert(f.Page.Map.Sets[0].Actions[1].Bindings.Count == 1);

		// Dragging a dead zone: many edits, one step to undo, and no rebuild under the field.
		f.Page.RebuildNow();
		let numbers = scope List<NumericField>();
		CollectViews(f.Page.Body, numbers);
		NumericField deadZone = null;
		for (let number in numbers)
		{
			if (number.TooltipText.StartsWith("Movement smaller"))
				deadZone = number;
		}
		Test.Assert(deadZone != null); // Move's stick
		let before = f.Page.Map.Sets[0].Actions[0].Bindings[1].DeadZone;
		let undoBefore = f.Page.Commands.UndoIndex;
		deadZone.SetValue(0.2);
		deadZone.SetValue(0.3);
		deadZone.SetValue(0.4);
		Test.Assert(Math.Abs(f.Page.Map.Sets[0].Actions[0].Bindings[1].DeadZone - 0.4f) < 1e-5f);
		Test.Assert(f.Page.Commands.UndoIndex == undoBefore + 1, "one step");
		let still = scope List<NumericField>();
		CollectViews(f.Page.Body, still);
		Test.Assert(still.Contains(deadZone), "the field was not rebuilt away");
		f.Page.Commands.Undo();
		Test.Assert(Math.Abs(f.Page.Map.Sets[0].Actions[0].Bindings[1].DeadZone - before) < 1e-5f);

		// Listening: the same key cap again cancels.
		f.Page.BeginListen(0, 1, 0);
		Test.Assert(f.Page.IsListening);
		f.Page.BeginListen(0, 1, 0);
		Test.Assert(!f.Page.IsListening);
	}
}
