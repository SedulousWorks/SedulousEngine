using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image.IO;
using Sedulous.Settings;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The shell's dialogs as a test drives them: what Show in Folder was asked to show, and the one
/// path a file or folder dialog answers (none: cancelled), at once as the null shell does.
class LauncherDialogs : IDialogService
{
	public List<String> Shown = new .() ~ DeleteContainerAndItems!(_);
	/// What the next file or folder dialog answers; empty cancels.
	public String Answer = new .() ~ delete _;
	public int Asked = 0;

	public void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters, StringView defaultPath, bool allowMultiple,
		uint32 parentWindowId) => Reply(callback);

	public void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters, StringView defaultPath,
		uint32 parentWindowId) => Reply(callback);

	public void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath, bool allowMultiple,
		uint32 parentWindowId) => Reply(callback);

	public void OpenPath(StringView path)
	{
		Shown.Add(new String(path));
	}

	/// CONSUMES the callback, as the services do.
	private void Reply(delegate void(Span<String>) callback)
	{
		Asked++;
		defer delete callback;
		if (Answer.IsEmpty)
		{
			callback(.());
			return;
		}
		var answer = Answer;
		callback(.(&answer, 1));
	}
}

/// A clipboard of a string.
class LauncherClipboard : IClipboard
{
	public String Held = new .() ~ delete _;

	public bool HasText => !Held.IsEmpty;

	public void GetText(String outText)
	{
		outText.Append(Held);
	}

	public void SetText(StringView text)
	{
		Held.Set(text);
	}
}

/// The project manager over its markup (Data/Editor/ProjectManager.xml): the recent projects as a
/// list or a grid (remembered), each by its picture (the thumbnail in its editor folder, an image
/// chosen for it, or its initial), a missing one with no Open, each project's menu and what it
/// runs, and New Project's dialog. Then what Sedulous adds so each behaviour has a test: a newer
/// engine's project named in the warning colour, each menu item's action (Show in Folder, Copy
/// Path, a thumbnail chosen and cleared), the menu a project's "more" button opens, the list taken
/// back from the grid, and New Project's Browse and Cancel.
class ProjectLauncherTests
{
	/// Two projects and one whose folder is gone, most recent first: First, Second, Gone, then any
	/// older ones asked for; the manager in a GUI of its own, 1280 by 800.
	private class Launcher
	{
		public String Root = new .() ~ delete _;
		public String First = new .() ~ delete _;
		public String Second = new .() ~ delete _;
		public String Gone = new .() ~ delete _;
		public Settings Store = new .() ~ delete _;
		public ProjectManagerController Controller ~ delete _;
		public LauncherDialogs Dialogs = new .() ~ delete _;
		public LauncherClipboard Clipboard = new .() ~ delete _;
		public SceneRoot Scene;
		public ProjectManagerView View;
		public int Saves = 0;
		public List<String> Opened = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Created = new .() ~ DeleteContainerAndItems!(_);
		/// The editor's sheet, once StyleAsTheEditor has styled the tree.
		public EditorSheet Sheet;

		/// `more` older projects after the three, there (`real`) or no longer there.
		public this(int more = 0, bool real = false)
		{
			EditorProjectSerializables.RegisterAll();
			PathJoin(GetCurrentDirectory(.. scope .()), "scratch_launcher", Root);
			PathJoin(Root, "First", First);
			PathJoin(Root, "Second", Second);
			PathJoin(Root, "Gone", Gone);
			RemoveDirectoryRecursive(Root);
			Test.Assert(CreateDirectory(Root));
			Test.Assert(EditorProject.Create(First, "First") case .Ok);
			Test.Assert(EditorProject.Create(Second, "Second") case .Ok);
			for (int i < more) // older projects: enough to scroll, after the three
			{
				let name = scope $"More{i}";
				let directory = PathJoin(Root, name, .. scope .());
				if (real)
					Test.Assert(EditorProject.Create(directory, name) case .Ok);
				ProjectRegistry.TouchRecentProject(Store, directory, name, "0.1.0");
			}
			ProjectRegistry.TouchRecentProject(Store, Gone, "Gone", "0.1.0"); // no project there
			ProjectRegistry.TouchRecentProject(Store, Second, "Second", "0.1.0");
			ProjectRegistry.TouchRecentProject(Store, First, "First", "0.1.0");
			Controller = new .(Store);

			let context = new GUIContext();
			Scene = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Scene.Size = .(1280.0f, 800.0f);
			Scene.EventDispatcher.Clipboard = Clipboard;
			let services = new ProjectManagerServices();
			services.Controller = Controller;
			services.Dialogs = Dialogs;
			let launcher = this;
			services.Open = new [=launcher] (path) => { launcher.Opened.Add(new String(path)); };
			services.Create = new [=launcher] (directory, name) => { launcher.Created.Add(new String(directory)); };
			services.StoreChanged = new [=launcher] () => { launcher.Saves++; };
			services.LoadMarkup = new (path) => PagesBed.LoadMarkup(path);
			View = new .(services, PagesBed.LoadMarkup(ProjectManagerView.cMarkupPath));
			Test.Assert(View.Content != null);
			Scene.AddChild(View.Content);
		}

		public ~this()
		{
			DeleteAndNullify!(Sheet); // while what it styled is there
			DeleteAndNullify!(View);
			Scene.EventDispatcher.Clipboard = null;
			Scene.ReleaseRef();
			RemoveDirectoryRecursive(Root);
		}

		/// The GUI's next drain: what a click asked to happen later happens.
		public void Drain() => Scene.MutationQueue.Drain();

		/// A frame of the GUI's, a sixtieth of a second: its clock (tooltips), its drain, its layout.
		public void Frame() => Scene.Context.Update(TimeSpan((int64)(TimeSpan.TicksPerSecond / 60)));

		/// The tree styled by the editor's own sheet (the default density's), as the window makes it,
		/// then laid out: the grid wraps and scrolls as it shows.
		public void StyleAsTheEditor()
		{
			Sheet = new .();
			Sheet.Apply(Scene);
		}

		/// The list the projects show in.
		public Node Projects => View.Content.FindElement("manager-projects");

		/// A small RGBA picture written as `name` under the scratch root.
		public void WritePicture(StringView name, String outPath)
		{
			let picture = scope Sedulous.Image.Image(16, 9, .RGBA8);
			PathJoin(Root, name, outPath);
			Test.Assert(ImageIO.SaveImage(picture, outPath, .PNG) case .Ok);
		}
	}

	/// The first button in `node`'s subtree showing `text`; null when none does.
	public static Sedulous.GUI.Button ButtonText(Node node, StringView text)
	{
		if (let button = node as Sedulous.GUI.Button)
		{
			if (button.Text == text)
				return button;
		}
		for (int i < node.ChildCount)
		{
			if (let found = ButtonText(node.GetChildAt(i), text))
				return found;
		}
		return null;
	}

	/// The first widget in `node`'s subtree with the sheet's class `cls`; null when none has.
	public static UIWidget WithClass(Node node, StringView cls)
	{
		if (let widget = node as UIWidget)
		{
			if (widget.HasClass(cls))
				return widget;
		}
		for (int i < node.ChildCount)
		{
			if (let found = WithClass(node.GetChildAt(i), cls))
				return found;
		}
		return null;
	}

	/// The text of the label with the sheet's class `cls` in `node`'s subtree.
	public static StringView TextOf(Node node, StringView cls)
	{
		let label = WithClass(node, cls) as Sedulous.GUI.Label;
		Test.Assert(label != null);
		return label.Text;
	}

	/// The project manifest in `directory` stamped as saved by engine `version`: by a raw text
	/// edit, since a save stamps this engine.
	public static void Stamp(StringView directory, StringView version)
	{
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(directory, probed) case .Ok);
		Test.Assert(!probed.EngineVersion.IsEmpty);
		let manifest = PathJoin(directory, ProjectLayout.ManifestFile, .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(manifest, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		text.Replace(probed.EngineVersion, version);
		Test.Assert(WriteFile(manifest, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	[Test]
	public static void TheProjectsShowAsAListOrAGridTheChoiceRememberedAMissingOneHasNoOpen()
	{
		let l = scope Launcher();
		Test.Assert(!l.View.IsGridView);
		Test.Assert(l.View.ShownCount == 3);
		Test.Assert(l.View.ThumbnailCount == 0, "no pictures yet: initials");
		let list = l.Projects;
		Test.Assert((list != null) && (list.ChildCount == 3));
		// First, then Second, then Gone (most recent first); Gone missing: dimmed, no Open.
		Test.Assert(ButtonText(list.GetChildAt(0), "Open") != null);
		Test.Assert(ButtonText(list.GetChildAt(2), "Open") == null);
		Test.Assert((list.GetChildAt(2) as UIWidget).HasClass("missing"));
		// Open has a slot on every row, at one place, empty for the missing one: the columns line up.
		for (int i < list.ChildCount)
		{
			let row = list.GetChildAt(i);
			let slot = row.GetChildAt(row.ChildCount - 2) as UIWidget;
			Test.Assert((slot != null) && slot.HasClass("manager-open-slot"));
			Test.Assert(slot.ChildCount == ((i == 2) ? 0 : 1));
		}
		Test.Assert(!(list.GetChildAt(0) as UIWidget).HasClass("missing"));
		Test.Assert(TextOf(list.GetChildAt(2), "manager-name") == "Gone (missing)");
		Test.Assert(TextOf(list.GetChildAt(0), "manager-name") == "First");
		Test.Assert(ButtonText(list.GetChildAt(0), "Open").HandleActivate());
		Test.Assert((l.Opened.Count == 1) && (l.Opened[0] == l.First));

		Test.Assert((l.View.Content.FindElement("manager-grid") as Sedulous.GUI.Button).HandleActivate());
		l.Drain();
		Test.Assert(l.View.IsGridView);
		Test.Assert(l.View.ShownCount == 3);
		Test.Assert((list as UIWidget).HasClass("grid"));
		Test.Assert((list.GetChildAt(0) as UIWidget).HasClass("manager-tile"));
		// A missing project's tile: dimmed, its picture opening nothing.
		Test.Assert((list.GetChildAt(2) as UIWidget).HasClass("missing"));
		Test.Assert(!(WithClass(list.GetChildAt(2), "manager-tile-open") as Sedulous.GUI.Button).Enabled);
		Test.Assert((WithClass(list.GetChildAt(0), "manager-tile-open") as Sedulous.GUI.Button).Enabled);
		Test.Assert(l.Saves == 1);
		Test.Assert(l.Controller.Entries.GridView, "kept with the recent projects");
		l.View.SetGridView(true);
		Test.Assert(l.Saves == 1, "no change, nothing to save");

		// The choice survives the store's file, and a file from before it reads as a list.
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(l.Store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.Find<RecentProjectsSettings>().GridView);
		Test.Assert(loaded.Find<RecentProjectsSettings>().Entries.Count == 3);

		// And back to the list.
		Test.Assert((l.View.Content.FindElement("manager-list") as Sedulous.GUI.Button).HandleActivate());
		l.Drain();
		Test.Assert(!l.View.IsGridView);
		Test.Assert(!(list as UIWidget).HasClass("grid"));
		Test.Assert((list.GetChildAt(0) as UIWidget).HasClass("manager-row"));
		Test.Assert(l.Saves == 2);
	}

	[Test]
	public static void AProjectsPictureIsItsThumbnailAnImageChosenForItOrItsInitial()
	{
		let l = scope Launcher();
		// A captured thumbnail in the project's editor folder shows.
		let captured = l.WritePicture("captured.png", .. scope .());
		let thumbnail = EditorProject.ThumbnailPath(l.First, .. scope .());
		CreateDirectory(PathParent(thumbnail, .. scope .()));
		let picture = scope Sedulous.Image.Image();
		Test.Assert(ImageIO.LoadImage(captured, picture) case .Ok);
		Test.Assert(ImageIO.SaveImage(picture, thumbnail, .PNG) case .Ok);
		l.View.Rebuild();
		Test.Assert(l.View.ThumbnailCount == 1);

		// An image chosen for the second project becomes its thumbnail.
		let chosen = l.WritePicture("chosen.png", .. scope .());
		Test.Assert(l.View.SetThumbnailFromImage(l.Second, chosen));
		l.Drain();
		Test.Assert(FileExists(EditorProject.ThumbnailPath(l.Second, .. scope .())));
		Test.Assert(l.View.ThumbnailCount == 2);
		Test.Assert(!l.View.SetThumbnailFromImage(l.Second, "/nowhere/at/all.png"));
		Test.Assert(l.View.Status == "That image could not be read.");
	}

	[Test]
	public static void EachProjectsMenuHoldsWhatAppliesToItRemoveFromListTakesItOffAndSaves()
	{
		let l = scope Launcher();
		let items = scope List<StringView>();
		ProjectManagerView.MenuItemsFor(l.First, items);
		Test.Assert(items.Count == 5);
		Test.Assert((items[0] == "Open") && (items[1] == "Show in Folder") && (items[2] == "Copy Path"));
		Test.Assert((items[3] == "Choose Thumbnail Image...") && (items[4] == "Remove from List"));

		// With a thumbnail, it can be cleared.
		Test.Assert(l.View.SetThumbnailFromImage(l.First, l.WritePicture("p.png", .. scope .())));
		items.Clear();
		ProjectManagerView.MenuItemsFor(l.First, items);
		Test.Assert(items[4] == "Clear Thumbnail");

		// A missing project: only what still makes sense.
		items.Clear();
		ProjectManagerView.MenuItemsFor(l.Gone, items);
		Test.Assert(items.Count == 3);
		Test.Assert((items[0] == "Show in Folder") && (items[2] == "Remove from List"));

		l.Drain();
		let before = l.Saves;
		l.View.Run(l.Gone, "Remove from List");
		l.Drain();
		Test.Assert(l.Saves == before + 1);
		Test.Assert(l.View.ShownCount == 2);
		Test.Assert(l.Controller.Entries.Entries.Count == 2);
	}

	[Test]
	public static void AProjectsMoreButtonOpensItsMenuAndEachItemDoesWhatItSays()
	{
		let l = scope Launcher();
		l.Scene.UpdateLayout();
		let list = l.Projects;
		// The first row's "more": its five items; the missing one's: three.
		Test.Assert((WithClass(list.GetChildAt(0), "slot-button") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(l.View.OpenMenu != null);
		Test.Assert(l.View.OpenMenu.ItemCount == 5);
		Test.Assert((WithClass(list.GetChildAt(2), "slot-button") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert((l.View.OpenMenu != null) && (l.View.OpenMenu.ItemCount == 3));

		l.View.Run(l.Second, "Open");
		Test.Assert((l.Opened.Count == 1) && (l.Opened[0] == l.Second));
		l.View.Run(l.Second, "Show in Folder");
		Test.Assert((l.Dialogs.Shown.Count == 1) && (l.Dialogs.Shown[0] == l.Second));
		l.View.Run(l.Second, "Copy Path");
		Test.Assert(l.Clipboard.Held == l.Second);
		Test.Assert(l.View.Status == "Copied the project's path.");

		// A thumbnail chosen in the file dialog; cancelled, none.
		l.View.Run(l.First, "Choose Thumbnail Image...");
		Test.Assert(l.Dialogs.Asked == 1);
		Test.Assert(!FileExists(EditorProject.ThumbnailPath(l.First, .. scope .())), "cancelled");
		l.WritePicture("chosen.png", l.Dialogs.Answer);
		l.View.Run(l.Second, "Choose Thumbnail Image...");
		Test.Assert(FileExists(EditorProject.ThumbnailPath(l.Second, .. scope .())));
		l.Drain();
		Test.Assert(l.View.ThumbnailCount == 1);
		l.View.Run(l.Second, "Clear Thumbnail");
		Test.Assert(!FileExists(EditorProject.ThumbnailPath(l.Second, .. scope .())));
		l.Drain();
		Test.Assert(l.View.ThumbnailCount == 0);
		Test.Assert(l.Saves == 0, "none of these changes the list");
	}

	[Test]
	public static void AProjectANewerEngineSavedIsNamedSoInTheWarningColour()
	{
		let l = scope Launcher();
		Stamp(l.First, scope $"{EngineVersion.Major + 1}.0.0");
		l.View.Rebuild();
		let list = l.Projects;
		Test.Assert((list.GetChildAt(0) as UIWidget).HasClass("newer"));
		Test.Assert(TextOf(list.GetChildAt(0), "manager-name") == "First (newer engine)");
		Test.Assert(ButtonText(list.GetChildAt(0), "Open") != null, "it still opens (the application asks first)");
		Test.Assert(!(list.GetChildAt(1) as UIWidget).HasClass("newer"));
		Test.Assert(!(list.GetChildAt(2) as UIWidget).HasClass("newer"), "a missing one is not probed newer");

		l.View.SetGridView(true);
		l.Drain();
		Test.Assert((list.GetChildAt(0) as UIWidget).HasClass("newer"));
		Test.Assert(TextOf(list.GetChildAt(0), "manager-path") == scope $"{EngineVersion.Major + 1}.0.0, newer engine");
		Test.Assert(TextOf(list.GetChildAt(2), "manager-path") == "0.1.0, missing");
	}

	[Test]
	public static void NewProjectWaitsForANameAndAFolderThenMakesItInAFolderOfItsName()
	{
		let l = scope Launcher();
		l.View.ShowCreateDialog();
		l.Scene.UpdateLayout();
		var dialog = l.View.CreateDialog;
		Test.Assert(dialog != null);
		var name = dialog.FindElement("new-project-name") as Sedulous.GUI.TextField;
		var parent = dialog.FindElement("new-project-parent") as Sedulous.GUI.TextField;
		var create = dialog.FindElement("new-project-create") as Sedulous.GUI.Button;
		var target = dialog.FindElement("new-project-where") as Sedulous.GUI.Label;
		Test.Assert((name != null) && (parent != null) && (create != null) && (target != null));
		Test.Assert(!create.Enabled);
		let d = l.Scene.EventDispatcher;
		name.RequestFocus();
		d.InjectText("Harbour");
		Test.Assert(!create.Enabled, "no folder yet");
		Test.Assert(target.Text.IsEmpty);
		parent.RequestFocus();
		d.InjectText(l.Root);
		Test.Assert(create.Enabled);
		let expected = PathJoin(l.Root, "Harbour", .. scope .());
		Test.Assert(target.Text == expected);
		Test.Assert(create.HandleActivate());
		Test.Assert(l.View.CreateDialog == null);
		Test.Assert((l.Created.Count == 1) && (l.Created[0] == expected));

		// Browse fills the folder; Cancel makes nothing.
		l.View.ShowCreateDialog();
		l.Scene.UpdateLayout();
		dialog = l.View.CreateDialog;
		Test.Assert(dialog != null);
		name = dialog.FindElement("new-project-name") as Sedulous.GUI.TextField;
		parent = dialog.FindElement("new-project-parent") as Sedulous.GUI.TextField;
		create = dialog.FindElement("new-project-create") as Sedulous.GUI.Button;
		name.RequestFocus();
		d.InjectText("Quay");
		l.Dialogs.Answer.Set(l.Second);
		Test.Assert((dialog.FindElement("new-project-browse") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(parent.Text == l.Second);
		Test.Assert(create.Enabled);
		Test.Assert((dialog.FindElement("new-project-cancel") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(l.View.CreateDialog == null);
		Test.Assert(l.Created.Count == 1, "Cancel makes nothing");
	}

	/// Over the first card, held still, frames passing between the notches (a tooltip's time): each
	/// notch scrolls the grid on, over whatever card comes under the pointer.
	private static void WheelOverCards(Launcher l)
	{
		l.View.SetGridView(true);
		l.Drain();
		l.StyleAsTheEditor();
		let list = l.Projects;
		Test.Assert(list != null);
		var scroller = list.Parent;
		while ((scroller != null) && !(scroller is ScrollView))
			scroller = scroller.Parent;
		Test.Assert(scroller != null);
		// Every notch has room, so each one checks (the pointer comes over the second row's first
		// card, a missing project's when the older ones are gone, by the fourth).
		Test.Assert(scroller.ScrollRange.Y >= 8 * scroller.ScrollStep);
		let card = list.GetChildAt(0).ScreenBounds;
		let at = Float2(card.X + card.Width * 0.5f, card.Y + card.Height * 0.4f);
		let d = l.Scene.EventDispatcher;
		d.InjectMouseMove(at);
		var last = scroller.ScrollOffset.Y;
		for (int step = 0; (step < 8) && (last < scroller.ScrollRange.Y); step++)
		{
			d.InjectMouseWheel(at, .(0.0f, -1.0f));
			for (int frame < 30)
				l.Frame();
			let now = scroller.ScrollOffset.Y;
			Test.Assert(now > last, scope $"notch {step}");
			last = now;
		}
	}

	[Test]
	public static void TheWheelOverTheGridsCardsScrollsNotchAfterNotchThePointerHeldStillOverAMissingProjectsCardToo()
	{
		let l = scope Launcher(18);
		WheelOverCards(l);
	}

	[Test]
	public static void TheWheelOverTheGridsCardsScrollsNotchAfterNotchOverProjectsThatAreThere()
	{
		let l = scope Launcher(18, true);
		WheelOverCards(l);
	}

	[Test]
	public static void UnderTheEditorsSheetACardsPictureButtonRingsItEvenlyInsideTheCard()
	{
		let l = scope Launcher();
		l.View.SetGridView(true);
		l.Drain();
		l.StyleAsTheEditor();
		let list = l.Projects;
		Test.Assert(list != null);
		let card = list.GetChildAt(0);
		let button = card.GetChildAt(0) as Sedulous.GUI.Button;
		Test.Assert(button != null);
		Test.Assert(button.ChildCount > 0);
		Node picture = null;
		for (int i < button.ChildCount)
		{
			if (let widget = button.GetChildAt(i) as UIWidget)
			{
				if (widget.HasClass("manager-tile-picture"))
				{
					picture = widget;
					break;
				}
			}
		}
		Test.Assert(picture != null);
		let b = button.ScreenBounds;
		let p = picture.ScreenBounds;
		let c = card.ScreenBounds;
		let left = p.X - b.X;
		let right = b.X + b.Width - (p.X + p.Width);
		let top = p.Y - b.Y;
		let bottom = b.Y + b.Height - (p.Y + p.Height);
		Test.Assert(Math.Abs(left - top) < 0.01f);
		Test.Assert(Math.Abs(right - bottom) < 0.01f);
		Test.Assert(Math.Abs(left - right) < 0.01f);
		Test.Assert(b.X >= c.X, "inside the card");
		Test.Assert(b.X + b.Width <= c.X + c.Width + 0.5f);
	}
}
