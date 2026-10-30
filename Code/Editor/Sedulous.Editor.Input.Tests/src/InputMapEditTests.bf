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
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Input.Tests;

/// The input map page's registration, its edits as pure functions over the map (the capture landing,
/// a fresh binding, the listen filter), what its grid says of a set's rows, and the page over its
/// markup with no host: the tree, an action opened in place, each edit one undo step, the capture,
/// and a map the game could not read.
class InputMapEditTests
{
	[Test]
	public static void RegisteringRoutesInputMapAssetToTheFactory()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		InputEditor.Register(context, none);
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

	[Test]
	public static void AnActionByItsNameAndALineABindingByItsSourceItsSettingsBySource()
	{
		let set = scope ActionSet();
		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		var keys = Binding();
		keys.Source = .Composite2D;
		keys.NegX = (uint32)'A';
		move.Bindings.Add(keys);
		set.Actions.Add(move);

		let action = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0", action);
		Test.Assert(action.DisplayName == "Move");
		Test.Assert(action.Summary.StartsWith(InputMapEdit.KindTitle(.Axis2D)));

		let binding = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Bindings.0", binding);
		Test.Assert(binding.DisplayName == InputMapEdit.SourceTitle(.Composite2D));
		Test.Assert(!binding.Summary.IsEmpty);

		// A four-key binding: its keys shown and captured, its single input and dead zone not.
		let left = scope PropertyInfo();
		let code = scope PropertyInfo();
		let deadZone = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Bindings.0.NegX", left);
		InputMapRows.Describe(set, "Actions.0.Bindings.0.Code", code);
		InputMapRows.Describe(set, "Actions.0.Bindings.0.DeadZone", deadZone);
		Test.Assert(left.Visible);
		Test.Assert(left.DisplayName == "Left");
		Test.Assert(left.Hint == InputMapRows.cInputCodeHint);
		Test.Assert(!code.Visible);
		Test.Assert(!deadZone.Visible);

		// When it fires, in the old page's words: closed, the choice and its time; its seconds only
		// for a hold or a tap, named by which.
		let fires = scope PropertyInfo();
		let firesKind = scope PropertyInfo();
		let seconds = scope PropertyInfo();
		for (int64 v < 4)
			firesKind.AddChoice("raw", v);
		InputMapRows.Describe(set, "Actions.0.Interaction", fires);
		InputMapRows.Describe(set, "Actions.0.Interaction.Kind", firesKind);
		InputMapRows.Describe(set, "Actions.0.Interaction.Seconds", seconds);
		Test.Assert(fires.DisplayName == "Interaction");
		Test.Assert(fires.Summary == "On press");
		Test.Assert(firesKind.Choices[0].Name == "On press");
		Test.Assert(firesKind.Choices[3].Name == "Double tap");
		Test.Assert(!seconds.Visible);
		move.Interaction.Kind = .Hold;
		move.Interaction.Seconds = 0.5f;
		let held = scope PropertyInfo();
		let heldSeconds = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Interaction", held);
		InputMapRows.Describe(set, "Actions.0.Interaction.Seconds", heldSeconds);
		Test.Assert(held.Summary == "Hold for 0.50s");
		Test.Assert(heldSeconds.Visible);
		Test.Assert(heldSeconds.DisplayName == "Hold For");

		// Processing in the old page's words and bounds.
		let curve = scope PropertyInfo();
		let snap = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Processors.ResponseExponent", curve);
		InputMapRows.Describe(set, "Actions.0.Processors.Snap", snap);
		Test.Assert(curve.DisplayName == "Curve");
		Test.Assert(Math.Abs(curve.Min - 0.1) < 1e-9);
		Test.Assert(Math.Abs(curve.Max - 5.0) < 1e-9);
		Test.Assert(snap.DisplayName == "Snap on Reverse");

		// The sources offered: only what the action's kind takes.
		let source = scope PropertyInfo();
		for (int64 v < 16)
			source.AddChoice("raw", v);
		InputMapRows.Describe(set, "Actions.0.Bindings.0.Source", source);
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(.Axis2D, valid);
		Test.Assert(source.Choices.Count == valid.Count);
		for (let choice in source.Choices)
			Test.Assert(choice.Name != "raw");
	}

	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project holding one input map: Gameplay (Move: four keys and a stick; Jump: a key)
	/// and Menu (Back: a key), open in the page.
	private class PageFixture
	{
		public String Dir = new .("scratch_input_map_page") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public InputMapEditorPage Page;

		public this()
		{
			InputPipeline.RegisterAll(); // the instance's type, written and read back
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
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new InputMapEditorPage(Context, services, instance);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public InputMap Map => ((InputMapAsset)Page.AssetObject).Map;

		/// What the set's rows list under `parent`: the row named `name`'s display name and summary,
		/// appended; false when there is none.
		public bool Info(StringView parent, StringView name, String outShown, String outSummary)
		{
			let rows = scope List<PropertyInfo>();
			defer { ClearAndDeleteItems!(rows); }
			Page.SetRows.GetProperties(parent, rows);
			for (let info in rows)
			{
				if (info.Name != name)
					continue;
				outShown.Append(info.ShownName);
				outSummary.Append(info.Summary);
				return true;
			}
			return false;
		}

		public void Edit(StringView path, Sedulous.GUI.Variant value)
		{
			Page.SetRows.BeginEdit(path);
			Page.SetRows.CommitEdit(path, PropertyWrite(value));
		}

		public void Text(StringView path, String outText)
		{
			var value = Page.SetRows.GetValue(path, 0);
			defer value.Dispose();
			outText.Append(value.AsString);
		}
	}

	[Test]
	public static void TheSetsAndTheirActionsATreeTheChosenSetsRowsInTheGrid()
	{
		let f = scope PageFixture();
		Test.Assert(!f.Page.LoadFailed);
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Move\n  Jump\nMenu\n  Back");
		Test.Assert(f.Page.ChosenSet == 0);
		Test.Assert(f.Text("Name", .. scope .()) == "Gameplay");
		let shown = scope String();
		let summary = scope String();
		Test.Assert(f.Info("Actions", "0", shown, summary));
		Test.Assert(shown == "Move");
		Test.Assert(!summary.IsEmpty);
		// An action's rows: its interaction right after its kind.
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		f.Page.SetRows.GetProperties("Actions.0", rows);
		Test.Assert(rows.Count == 5);
		Test.Assert(rows[1].Name == "Kind");
		Test.Assert(rows[2].Name == "Interaction");
		Test.Assert(rows[3].Name == "Bindings");

		// An action chosen in the tree: its set shown, it and its list opened in place.
		f.Page.ChooseAction(1, 0);
		Test.Assert(f.Page.ChosenSet == 1);
		Test.Assert(f.Text("Name", .. scope .()) == "Menu");
		// The grid's own rows, by its paths (the set's section's: "set/..."): open, the action's
		// bindings listed under it.
		let grid = f.Page.Grid;
		Test.Assert(grid != null);
		Test.Assert(grid.IsOpen("set/Actions"));
		Test.Assert(grid.IsOpen("set/Actions.0"));
		Test.Assert(grid.FindRow("set/Actions.0") >= 0);
		Test.Assert(grid.FindRow("set/Actions.0.Bindings") >= 0);

		// The search keeps the actions whose name or input matches, and their sets.
		f.Page.Search("jump");
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Jump");
		f.Page.Search("");
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Move\n  Jump\nMenu\n  Back");
	}

	/// The search filters as it is typed, as every other search does, not on Enter or the focus
	/// leaving.
	[Test]
	public static void TheSearchFiltersAsItIsTyped()
	{
		let f = scope PageFixture();
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(1000.0f, 700.0f);
		root.AddChild(f.Page.Content);
		defer root.RemoveChild(f.Page.Content);
		root.UpdateLayout();
		let search = f.Page.Content.FindElement("input-search") as TextField;
		Test.Assert(search != null);
		root.EventDispatcher.FocusNode = search;
		root.EventDispatcher.InjectText("jump");
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Jump", "filtered at once, nothing committed");
	}

	[Test]
	public static void ARowsEditAnAddedSetAndARemovedActionEachOneUndoStep()
	{
		let f = scope PageFixture();
		f.Edit("Actions.1.Name", Sedulous.GUI.Variant("Leap"));
		Test.Assert(f.Map.Sets[0].Actions[1].Name == "Leap");
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Move\n  Leap\nMenu\n  Back");
		Test.Assert(f.Page.IsDirty);
		f.Page.Commands.Undo();
		Test.Assert(f.Map.Sets[0].Actions[1].Name == "Jump");

		f.Page.AddSet();
		Test.Assert(f.Map.Sets.Count == 3);
		Test.Assert(f.Map.Sets[2].Name == "Set 1");
		Test.Assert(f.Page.ChosenSet == 2);
		f.Page.Commands.Undo();
		Test.Assert(f.Map.Sets.Count == 2);
		Test.Assert(f.Page.ChosenSet == 1, "the set shown gone: the last one");

		f.Page.ChooseAction(0, 0);
		Test.Assert(f.Page.RemoveChosen());
		Test.Assert(f.Map.Sets[0].Actions.Count == 1);
		Test.Assert(f.Page.Tree(.. scope .()) == "Gameplay\n  Jump\nMenu\n  Back");
		f.Page.Commands.Undo();
		Test.Assert(f.Map.Sets[0].Actions.Count == 2);
	}

	[Test]
	public static void ASetFoldedInTheTreeStaysFoldedWhenAnotherIsChosen()
	{
		let f = scope PageFixture();
		let tree = f.Page.Content.FindElement("input-tree") as TreeView;
		Test.Assert(tree != null);
		Test.Assert(tree.IsIdExpanded(0)); // Gameplay
		tree.SetIdExpanded(0, false);
		f.Page.ChooseSet(1);
		Test.Assert(!tree.IsIdExpanded(0));
		f.Edit("Name", Sedulous.GUI.Variant("Menus")); // an edit rebuilds the tree
		Test.Assert(!tree.IsIdExpanded(0));
	}

	[Test]
	public static void ASetAddedAndUndoneAfterARowsEditKeepsThatEdit()
	{
		// The whole edit's before is the map as it is, not as the base page's own last step left it.
		let f = scope PageFixture();
		f.Edit("Actions.1.Name", Sedulous.GUI.Variant("Leap"));
		f.Page.AddSet();
		Test.Assert(f.Map.Sets.Count == 3);
		f.Page.Commands.Undo();
		Test.Assert(f.Map.Sets.Count == 2);
		Test.Assert(f.Map.Sets[0].Actions[1].Name == "Leap");
	}

	[Test]
	public static void ABindingsInputListenedForAndLandedAsOneUndoStepAFourKeyOneByItsKey()
	{
		let f = scope PageFixture();
		let capture = f.Page.CaptureServices;
		// The editor asks by the grid's paths. What the input's button says: Jump's key, and a four-key
		// binding's keys one at a time.
		let jumpKey = BindingNames.DescribeBinding(f.Map.Sets[0].Actions[1].Bindings[0], .. scope .());
		Test.Assert(capture.Describe("set/Actions.1.Bindings.0.Code", .. scope .()) == jumpKey);
		Test.Assert(!jumpKey.IsEmpty);
		f.Map.Sets[0].Actions[0].Bindings[0].PosY = (uint32)'W';
		Test.Assert(capture.Describe("set/Actions.0.Bindings.0.PosY", .. scope .()) == BindingNames.KeyName((uint32)'W', .. scope .()));
		Test.Assert(capture.Describe("set/Actions.0.Bindings.0.NegX", .. scope .()) == "Not set");
		f.Map.Sets[0].Actions[0].Bindings[0].PosY = 0;
		// Jump's key.
		capture.Toggle("set/Actions.1.Bindings.0.Code");
		Test.Assert(f.Page.IsListening);
		Test.Assert(capture.Listening("set/Actions.1.Bindings.0.Code"));
		Test.Assert(!capture.Listening("set/Actions.0.Bindings.0.Code"));
		var captured = Binding();
		captured.Source = .MouseButton;
		captured.Code = 3;
		f.Page.LandCapture(captured);
		Test.Assert(!f.Page.IsListening);
		Test.Assert(f.Map.Sets[0].Actions[1].Bindings[0].Source == .MouseButton);
		Test.Assert(f.Map.Sets[0].Actions[1].Bindings[0].Code == 3);

		// Move's four keys: Up only.
		capture.Toggle("set/Actions.0.Bindings.0.PosY");
		var key = Binding();
		key.Code = 42;
		f.Page.LandCapture(key);
		Test.Assert(f.Map.Sets[0].Actions[0].Bindings[0].PosY == 42);
		Test.Assert(f.Map.Sets[0].Actions[0].Bindings[0].Source == .Composite2D);

		// Toggled twice: stops; a path naming no binding: never listens.
		capture.Toggle("set/Actions.1.Bindings.0.Code");
		capture.Toggle("set/Actions.1.Bindings.0.Code");
		Test.Assert(!f.Page.IsListening);
		capture.Toggle("set/Actions.9.Bindings.0.Code");
		Test.Assert(!f.Page.IsListening);

		f.Page.Commands.Undo();
		f.Page.Commands.Undo();
		Test.Assert(f.Map.Sets[0].Actions[1].Bindings[0].Source == .Key);
		Test.Assert(f.Map.Sets[0].Actions[0].Bindings[0].PosY == 0);
	}

	[Test]
	public static void ABindingsGamepadIsAChoiceAnyOrAPadByItsNumberAsTheOldPageHadIt()
	{
		let set = scope ActionSet();
		let fire = new InputAction();
		fire.Name.Set("Fire");
		var pad = Binding();
		pad.Source = .GamepadButton;
		fire.Bindings.Add(pad);
		set.Actions.Add(fire);
		let device = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Bindings.0.Device", device);
		Test.Assert(device.Visible);
		Test.Assert(device.Kind == .Enum);
		Test.Assert(device.Choices.Count == 5);
		Test.Assert((device.Choices[0].Name == "Any") && (device.Choices[0].Value == -1));
		Test.Assert((device.Choices[1].Name == "1") && (device.Choices[1].Value == 0));

		// Chosen through the grid's rows: the binding's device its index.
		let f = scope PageFixture();
		f.Page.ChooseAction(1, 0); // Menu's Back
		f.Map.Sets[1].Actions[0].Bindings[0].Source = .GamepadButton;
		f.Edit("Actions.0.Bindings.0.Device", Sedulous.GUI.Variant((int64)2));
		Test.Assert(f.Map.Sets[1].Actions[0].Bindings[0].Device == 2);
		f.Edit("Actions.0.Bindings.0.Device", Sedulous.GUI.Variant((int64)-1));
		Test.Assert(f.Map.Sets[1].Actions[0].Bindings[0].Device == -1);
	}

	[Test]
	public static void AMapTheGameCannotReadSaysSoAndSaveRefusesIt()
	{
		let f = scope PageFixture();
		Test.Assert(f.Page.Notice("invalid", .. scope .()).IsEmpty);
		// A stick on a button.
		f.Page.ChooseAction(0, 1);
		f.Edit("Actions.1.Kind", Sedulous.GUI.Variant((int64)ActionKind.Axis2D));
		Test.Assert(!f.Page.Notice("invalid", .. scope .()).IsEmpty);
		Test.Assert(f.Page.Save() case .Err);
		f.Page.Commands.Undo();
		Test.Assert(f.Page.Notice("invalid", .. scope .()).IsEmpty);
	}

	// A touch stick's radius is normalised, as the runtime reads it (the touch's offset from its
	// anchor, a fraction of the screen, over the radius) and as the touch regions are: its row is
	// bounded and said the same way, not in pixels (a typed 100 saturated every touch).
	[Test]
	public static void ATouchSticksRadiusIsAFractionOfTheScreenAsItsAreaIs()
	{
		let set = scope ActionSet();
		let look = new InputAction();
		look.Name.Set("Look");
		look.Kind = .Axis2D;
		var stick = Binding();
		stick.Source = .TouchStick;
		look.Bindings.Add(stick);
		set.Actions.Add(look);

		let radius = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Bindings.0.StickRadius", radius);
		let area = scope PropertyInfo();
		InputMapRows.Describe(set, "Actions.0.Bindings.0.RegionX", area);
		Test.Assert(radius.Visible);
		Test.Assert(radius.HasRange);
		Test.Assert(radius.Min == area.Min);
		Test.Assert(radius.Max == area.Max);
		Test.Assert(radius.Step == area.Step);
		Test.Assert(radius.Description.Contains("fraction of the screen", true));
		Test.Assert(stick.StickRadius <= radius.Max); // the default sits in the range
	}
}
