using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image.IO;
using Sedulous.Settings;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Look.TestSupport;

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
/// chosen for it, or its initial); missing ones in a section of their own with Locate... and no
/// Open. Also the pin, the sort and the search, the keys and the focus ring, the first run's
/// welcome, a dropped folder, each project's menu and what it runs, and New Project's dialog. Then
/// what Sedulous adds so each behaviour has a test: a newer engine's project badged in the warning
/// colour, each menu item's action (Show in Folder, Copy Path, a thumbnail chosen and cleared), the
/// menu a project's "more" button opens, the list taken back from the grid, and New Project's
/// Browse and Cancel.
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

		/// `more` older projects after the three, there (`real`) or no longer there; `configure` adds
		/// to the view's services (the Samples tab's client).
		public this(int more = 0, bool real = false, delegate void(ProjectManagerServices services) configure = null)
		{
			EditorProjectsSerializables.RegisterAll();
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
			if (configure != null)
				configure(services);
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
	public static void TheProjectsShowAsAListOrAGridTheChoiceRememberedAMissingOneInItsOwnSectionWithNoOpen()
	{
		let l = scope Launcher();
		Test.Assert(!l.View.IsWelcome);
		Test.Assert(!l.View.IsGridView);
		Test.Assert(l.View.ShownCount == 3);
		Test.Assert(l.View.ThumbnailCount == 0, "no pictures yet: initials");
		let list = l.Projects;
		let missing = l.View.Content.FindElement("manager-missing-list");
		Test.Assert((list != null) && (missing != null));
		// First, then Second (most recent first); Gone is missing, so it is listed apart, with
		// Locate... and no Open.
		Test.Assert(list.ChildCount == 2);
		Test.Assert(missing.ChildCount == 1);
		Test.Assert(l.View.Content.FindElement("manager-missing").Displayed);
		Test.Assert((l.View.Content.FindElement("manager-count") as Sedulous.GUI.Label).Text == "2 projects");
		Test.Assert(ButtonText(list.GetChildAt(0), "Open") != null);
		Test.Assert(ButtonText(missing.GetChildAt(0), "Open") == null);
		Test.Assert(ButtonText(missing.GetChildAt(0), "Locate...") != null);
		// The heading reads right for one as for many.
		Test.Assert((l.View.Content.FindElement("manager-missing-count") as Sedulous.GUI.Label).Text == "1 · not found at the last known location");
		Test.Assert((missing.GetChildAt(0) as UIWidget).HasClass("missing"));
		Test.Assert(!(list.GetChildAt(0) as UIWidget).HasClass("missing"));
		Test.Assert(TextOf(missing.GetChildAt(0), "manager-name") == "Gone");
		Test.Assert(TextOf(list.GetChildAt(0), "manager-name") == "First");
		Test.Assert(ButtonText(list.GetChildAt(0), "Open").HandleActivate());
		Test.Assert((l.Opened.Count == 1) && (l.Opened[0] == l.First));

		Test.Assert((l.View.Content.FindElement("manager-grid") as Sedulous.GUI.Button).HandleActivate());
		l.Drain();
		Test.Assert(l.View.IsGridView);
		Test.Assert(l.View.ShownCount == 3);
		Test.Assert((list as UIWidget).HasClass("grid"));
		Test.Assert(list.ChildCount == 2);
		Test.Assert((list.GetChildAt(0) as UIWidget).HasClass("manager-tile"));
		Test.Assert(missing.ChildCount == 1, "a missing project stays a row in its section");
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
		Test.Assert(l.View.Status == "Gone was taken off the list; its files are untouched.");
	}

	[Test]
	public static void AProjectsMoreButtonOpensItsMenuAndEachItemDoesWhatItSays()
	{
		let l = scope Launcher();
		l.Scene.UpdateLayout();
		let list = l.Projects;
		// The first row's "more": its five items; the second's too. A missing row has Locate... and
		// Remove from list for buttons, and no menu.
		Test.Assert((WithClass(list.GetChildAt(0), "slot-button") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(l.View.OpenMenu != null);
		Test.Assert(l.View.OpenMenu.ItemCount == 5);
		Test.Assert((WithClass(list.GetChildAt(1), "slot-button") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert((l.View.OpenMenu != null) && (l.View.OpenMenu.ItemCount == 5));
		Test.Assert(WithClass(l.View.Content.FindElement("manager-missing-list"), "slot-button") == null);

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
	public static void AProjectANewerEngineSavedIsBadgedSoInTheWarningColourAndAnOlderOnesUpgrade()
	{
		let l = scope Launcher();
		Stamp(l.First, scope $"{EngineVersion.Major + 1}.0.0");
		Stamp(l.Second, "0.0.1");
		l.View.Rebuild();
		let list = l.Projects;
		let first = list.GetChildAt(0);
		Test.Assert((first as UIWidget).HasClass("newer"));
		Test.Assert(TextOf(first, "manager-name") == "First");
		Test.Assert(TextOf(first, "badge") == "Made with a newer engine");
		Test.Assert(WithClass(first, "manager-version").HasClass("newer"));
		Test.Assert(ButtonText(first, "Open") != null, "it still opens (the application asks first)");
		let second = list.GetChildAt(1);
		Test.Assert((second as UIWidget).HasClass("older"));
		Test.Assert(TextOf(second, "badge") == "Upgrades when opened");

		l.View.SetGridView(true);
		l.Drain();
		let tile = list.GetChildAt(0);
		let stamp = WithClass(tile, "manager-tile-version") as Sedulous.GUI.Label;
		Test.Assert((stamp != null) && stamp.HasClass("newer"));
		Test.Assert(stamp.Text == scope $"{EngineVersion.Major + 1}.0.0");
		Test.Assert(stamp.Tooltip == "Made with a newer engine");
		Test.Assert(WithClass(list.GetChildAt(1), "manager-tile-version").HasClass("older"));
	}

	[Test]
	public static void NewProjectStartsWhereTheLastProjectWentChecksAsItIsTypedAndMakesAFolderOfItsName()
	{
		let l = scope Launcher();
		l.Controller.SetLastLocation(l.Root);
		l.View.ShowCreateDialog();
		l.Scene.UpdateLayout();
		var dialog = l.View.CreateDialog;
		Test.Assert(dialog != null);
		var name = dialog.FindElement("new-project-name") as Sedulous.GUI.TextField;
		var parent = dialog.FindElement("new-project-parent") as Sedulous.GUI.TextField;
		let ownFolder = dialog.FindElement("new-project-own-folder") as Sedulous.GUI.CheckBox;
		let line = dialog.FindElement("new-project-check") as UIWidget;
		let target = dialog.FindElement("new-project-where") as Sedulous.GUI.Label;
		var create = dialog.FindElement("new-project-create") as Sedulous.GUI.Button;
		Test.Assert((name != null) && (parent != null) && (ownFolder != null) && (line != null) && (target != null) && (create != null));
		Test.Assert(parent.Text == l.Root, "the last location");
		Test.Assert(ownFolder.Checked, "a folder of its name, unless turned off");
		Test.Assert(!create.Enabled);
		Test.Assert(line.HasClass("error"));
		Test.Assert(target.Text == "Give the project a name.");

		let d = l.Scene.EventDispatcher;
		name.RequestFocus();
		d.InjectText("Harbour");
		Test.Assert(create.Enabled);
		Test.Assert(!line.HasClass("error") && !line.HasClass("warning"));

		// Without a folder of its name, the location itself must be empty: the scratch root is not.
		Test.Assert(ownFolder.HandleActivate());
		Test.Assert(!ownFolder.Checked);
		Test.Assert(!create.Enabled);
		Test.Assert(line.HasClass("error"));
		Test.Assert(ownFolder.HandleActivate());
		Test.Assert(create.Enabled);

		let before = l.Saves;
		let expected = PathJoin(l.Root, "Harbour", .. scope .());
		Test.Assert(create.HandleActivate());
		Test.Assert(l.View.CreateDialog == null);
		Test.Assert((l.Created.Count == 1) && (l.Created[0] == expected));
		Test.Assert(l.Controller.LastLocation == l.Root, "remembered for the next one");
		Test.Assert(l.Saves == before + 1);

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
		let scroller = l.View.Content.FindElement("manager-scroll");
		Test.Assert((scroller != null) && scroller.IsScrollContainer);
		// Every notch has room, so each one checks (the pointer comes over whatever scrolls under it:
		// the missing projects' rows, when the older ones are gone).
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
	public static void TheWheelOverTheGridsCardsScrollsNotchAfterNotchThePointerHeldStillWithMissingProjectsListed()
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
	public static void UnderTheEditorsSheetACardsPictureFillsItEdgeToEdgeInsideItsBorderAt16By9()
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
		// The picture stretches across its button at 16:9, so it fills it evenly on every side.
		let values = scope $"left {left} top {top} right {right} bottom {bottom}; button {b.Width}x{b.Height}, picture {p.Width}x{p.Height}";
		Test.Assert(Math.Abs(left - top) < 0.01f, values);
		Test.Assert(Math.Abs(right - bottom) < 0.01f, values);
		Test.Assert(Math.Abs(left - right) < 0.01f, values);
		// Inside the card's 1px border (var(--border), so the tokens reached the sheet), edge to edge.
		Test.Assert(Math.Abs(b.X - (c.X + 1.0f)) < 0.01f, values);
		Test.Assert(Math.Abs((b.X + b.Width) - (c.X + c.Width - 1.0f)) < 0.01f, values);
		Test.Assert(Math.Abs(p.Width / p.Height - 16.0f / 9.0f) < 0.01f * (16.0f / 9.0f), "16:9, whatever its column's width");
	}

	/// The names of the projects listed, in their order.
	private static void ListedNames(Launcher l, List<String> outNames)
	{
		let list = l.Projects;
		for (int i < list.ChildCount)
			outNames.Add(new String(TextOf(list.GetChildAt(i), "manager-name")));
	}

	/// The first listed name, else empty.
	private static void FirstName(Launcher l, String outName)
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ListedNames(l, names);
		if (!names.IsEmpty)
			outName.Append(names[0]);
	}

	private static int ListedCount(Launcher l) => l.Projects.ChildCount;

	[Test]
	public static void APinnedProjectComesFirstWhateverTheSortAndTheSortAndTheSearchArrangeWhatWasProbed()
	{
		let l = scope Launcher();
		Test.Assert(ListedCount(l) == 2);
		Test.Assert(FirstName(l, .. scope .()) == "First");

		// Pinning Second puts it first, and is saved.
		l.View.SetFavourite(l.Second, true);
		l.Drain();
		Test.Assert(l.Saves == 1);
		Test.Assert(FirstName(l, .. scope .()) == "Second");
		Test.Assert(l.View.FocusedPath == l.Second, "the ring went with it");
		Test.Assert(WithClass(l.Projects.GetChildAt(0), "manager-star").HasClass("on"));
		l.View.SetFavourite(l.Second, false);
		l.Drain();
		Test.Assert(FirstName(l, .. scope .()) == "First");

		// By name: First before Second still, after recency put Second first: it sorts.
		ProjectRegistry.TouchRecentProject(l.Store, l.Second, "Second", "0.1.0");
		l.View.Rebuild();
		Test.Assert(FirstName(l, .. scope .()) == "Second");
		l.View.SetSortByName(true);
		l.Drain();
		Test.Assert(l.Controller.SortByName);
		Test.Assert(FirstName(l, .. scope .()) == "First");

		// The search matches the name or the folder, any case; the count says how many of how many.
		l.View.SetQuery("sec");
		Test.Assert(ListedCount(l) == 1);
		Test.Assert((l.View.Content.FindElement("manager-count") as Sedulous.GUI.Label).Text == "1 of 2");
		Test.Assert(!l.View.Content.FindElement("manager-missing").Displayed, "Gone does not match");
		l.View.SetQuery("nothing like it");
		Test.Assert(ListedCount(l) == 0);
		Test.Assert(l.View.Content.FindElement("manager-no-match").Displayed);
		l.View.SetQuery("");
		Test.Assert(ListedCount(l) == 2);
		Test.Assert(!l.View.Content.FindElement("manager-no-match").Displayed);
	}

	[Test]
	public static void UpAndDownMoveTheRingEnterOpensItsProjectDelTakesItOffTheListCtrlNIsNewProject()
	{
		let l = scope Launcher();
		l.View.Shown();
		let d = l.Scene.EventDispatcher;
		Test.Assert(l.View.FocusedPath == l.First);
		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Down));
		Test.Assert(l.View.FocusedPath == l.Second);
		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Down));
		Test.Assert(l.View.FocusedPath == l.Gone, "the missing come after the rest");
		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Down));
		Test.Assert(l.View.FocusedPath == l.Gone, "the end holds");
		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Up));
		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Return));
		Test.Assert((l.Opened.Count == 1) && (l.Opened[0] == l.Second));

		Test.Assert(d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Delete));
		l.Drain();
		Test.Assert(l.Saves == 1);
		Test.Assert(l.View.ShownCount == 2);
		Test.Assert(l.View.Status == "Second was taken off the list; its files are untouched.");
		Test.Assert(FileExists(PathJoin(l.Second, ProjectLayout.ManifestFile, .. scope .())), "only the list changed");

		// In the search, Del edits the text.
		l.View.HandleKey((uint32)Sedulous.GUI.KeyCode.F, KeyModCtrl);
		let search = l.View.Content.FindElement("manager-search") as Sedulous.GUI.TextField;
		Test.Assert(search != null);
		Test.Assert(d.FocusNode == search);
		Test.Assert(!l.View.HandleKey((uint32)Sedulous.GUI.KeyCode.Delete, 0));

		Test.Assert(l.View.CreateDialog == null);
		Test.Assert(l.View.HandleKey((uint32)Sedulous.GUI.KeyCode.N, KeyModCtrl));
		Test.Assert(l.View.CreateDialog != null);
	}

	[Test]
	public static void LocatePointsAMissingProjectAtItsNewFolderRemoveMissingTakesTheRestOffFilesUntouched()
	{
		let l = scope Launcher();
		// A folder with no project is refused.
		Test.Assert(!l.View.Locate(l.Gone, l.Root));
		Test.Assert(l.View.ShownCount == 3);
		// Gone was moved: its project is at Moved now.
		let moved = PathJoin(l.Root, "Moved", .. scope .());
		Test.Assert(EditorProject.Create(moved, "Gone") case .Ok);
		Test.Assert(l.View.Locate(l.Gone, moved));
		l.Drain();
		Test.Assert(l.Saves == 1);
		Test.Assert(!l.View.Content.FindElement("manager-missing").Displayed);
		Test.Assert(ListedCount(l) == 3);

		// Two missing, then both off the list at once.
		ProjectRegistry.TouchRecentProject(l.Store, PathJoin(l.Root, "Lost1", .. scope .()), "Lost1", "0.1.0");
		ProjectRegistry.TouchRecentProject(l.Store, PathJoin(l.Root, "Lost2", .. scope .()), "Lost2", "0.1.0");
		l.View.Rebuild();
		Test.Assert(l.View.Content.FindElement("manager-missing-list").ChildCount == 2);
		Test.Assert(ButtonText(l.View.Content, "Remove missing from list").HandleActivate());
		l.Drain();
		Test.Assert(l.Saves == 2);
		Test.Assert(l.View.ShownCount == 3);
		Test.Assert(l.View.Status == "2 missing projects were taken off the list; no files were touched.");
	}

	[Test]
	public static void WithNoProjectsAWelcomeWithNewProjectAndOpenFolderStandsInForTheLists()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		let controller = scope ProjectManagerController(store);
		let context = new GUIContext();
		let scene = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer scene.ReleaseRef();
		let services = new ProjectManagerServices();
		services.Controller = controller;
		services.LoadMarkup = new (path) => PagesBed.LoadMarkup(path);
		let view = new ProjectManagerView(services, PagesBed.LoadMarkup(ProjectManagerView.cMarkupPath));
		defer delete view; // before the scene
		scene.AddChild(view.Content);
		Test.Assert(view.IsWelcome);
		Test.Assert(view.Content.FindElement("manager-welcome").Displayed);
		Test.Assert(!view.Content.FindElement("manager-projects-page").Displayed);
		Test.Assert((view.Content.FindElement("manager-welcome-new") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(view.CreateDialog != null);

		// The Samples tab replaces the welcome while it is chosen.
		view.ShowSamples(true);
		Test.Assert(view.IsShowingSamples);
		Test.Assert(!view.Content.FindElement("manager-welcome").Displayed);
		Test.Assert(view.Content.FindElement("manager-samples-page").Displayed);
		Test.Assert((view.Content.FindElement("manager-tab-samples") as Sedulous.GUI.Button).Checked);
	}

	[Test]
	public static void AFolderDroppedOnTheManagerOpensItsProjectOrTheStatusSaysItHoldsNone()
	{
		let l = scope Launcher();
		StringView[1] dropped = .(l.Root);
		Test.Assert(l.View.OpenDropped(.(&dropped[0], 1)));
		Test.Assert(l.Opened.IsEmpty);
		Test.Assert(l.View.Status == "scratch_launcher holds no Project.xml, so it is not a project. New Project makes one.");
		dropped[0] = l.Second;
		Test.Assert(l.View.OpenDropped(.(&dropped[0], 1)));
		Test.Assert((l.Opened.Count == 1) && (l.Opened[0] == l.Second));
	}

	/// New Project is as tall as what it holds, under the editor's sheet: it ends just under its
	/// buttons, with a check line wrapped onto several lines as with one.
	[Test]
	public static void UnderTheEditorsSheetNewProjectEndsJustUnderItsButtons()
	{
		let l = scope Launcher();
		let folder = scope String(l.Root)..Append('/')..Append('a', 320);
		l.Controller.SetLastLocation(folder);
		l.View.ShowCreateDialog();
		let dialog = l.View.CreateDialog;
		Test.Assert(dialog != null);
		// Named, so the line shows the folder, wrapped taller than the height it opens at.
		(dialog.FindElement("new-project-name") as Sedulous.GUI.TextField).RequestFocus();
		l.Scene.EventDispatcher.InjectText("Harbour");
		l.Sheet = new EditorSheet(true); // text measured, as the window draws it
		l.Sheet.Apply(l.Scene);
		l.Scene.UpdateLayout();
		let window = dialog.ScreenBounds;
		let button = dialog.FindElement("new-project-create").ScreenBounds;
		Test.Assert(button.Y + button.Height <= window.Y + window.Height + 0.5f, "inside the window");
		Test.Assert(window.Y + window.Height - (button.Y + button.Height) < 40.0f,
			scope $"no empty area under the buttons ({window.Y + window.Height - (button.Y + button.Height)})");
	}

	/// A folder with no spaces in it breaks anywhere in the check line, inside its box.
	[Test]
	public static void UnderTheEditorsSheetALongFolderWrapsInsideTheCheckLine()
	{
		let l = scope Launcher();
		let folder = scope String(l.Root)..Append('/')..Append('a', 160);
		l.Controller.SetLastLocation(folder);
		l.View.ShowCreateDialog();
		let dialog = l.View.CreateDialog;
		Test.Assert(dialog != null);
		// Named, so the line shows the folder it will make.
		(dialog.FindElement("new-project-name") as Sedulous.GUI.TextField).RequestFocus();
		l.Scene.EventDispatcher.InjectText("Harbour");
		l.Sheet = new EditorSheet(true); // text measured: a wrap needs its widths
		l.Sheet.Apply(l.Scene);
		l.Scene.UpdateLayout();
		let text = dialog.FindElement("new-project-where").ScreenBounds;
		let line = dialog.FindElement("new-project-check").ScreenBounds;
		Test.Assert(text.X + text.Width <= line.X + line.Width + 0.5f, "inside the line's box");
		Test.Assert(text.Height > 30.0f, scope $"wrapped onto more than one line ({text.Height})");
	}

	[Test]
	public static void UnderTheEditorsSheetARowsMenuButtonStandsAsTallAsOpen()
	{
		let l = scope Launcher();
		l.StyleAsTheEditor();
		let row = l.Projects.GetChildAt(0);
		let open = ButtonText(row, "Open").ScreenBounds;
		let more = WithClass(row, "slot-button").ScreenBounds;
		Test.Assert(Math.Abs(open.Height - 30.0f) < 0.01f);
		Test.Assert(Math.Abs(more.Height - open.Height) < 0.01f, "the menu button beside Open, not the slot button's 18px");
		Test.Assert(Math.Abs(more.Width - 30.0f) < 0.01f);
	}

	[Test]
	public static void UnderTheEditorsSheetARowStretchesAcrossTheWindowLessThePagesMargins()
	{
		let l = scope Launcher();
		l.StyleAsTheEditor();
		let row = l.Projects.GetChildAt(0).ScreenBounds;
		Test.Assert(Math.Abs(row.X - 40.0f) < 0.01f);
		Test.Assert(row.Width > 1100.0f, "1280 less 40 each side and a scroll bar at most");
		let missing = l.View.Content.FindElement("manager-missing-list").GetChildAt(0).ScreenBounds;
		Test.Assert(Math.Abs(missing.Width - row.Width) < 0.01f);
	}

	/// The Launcher's view pumped with `server` until `until` holds, about five seconds at most.
	private static void RunUntil(Launcher l, LoopbackFiles server, delegate bool() until)
	{
		for (int i < 5000)
		{
			if (until())
				break;
			server.Pump();
			l.View.Tick();
			l.Drain();
			Thread.Sleep(1);
		}
	}

	/// Whether `node`'s subtree has a label showing `text`.
	private static bool HasLabel(Node node, StringView text)
	{
		if (let label = node as Sedulous.GUI.Label)
		{
			if (label.Text == text)
				return true;
		}
		for (int i < node.ChildCount)
		{
			if (HasLabel(node.GetChildAt(i), text))
				return true;
		}
		return false;
	}

	[Test]
	public static void TheSamplesTabListsTheReleasesSamplesAndOneDownloadedJoinsTheProjects()
	{
		let client = scope NativeHttpClient(null);
		let server = scope LoopbackFiles();
		let l = scope Launcher(0, false, scope [&] (services) =>
			{
				services.Http = client;
				services.ReleaseFile = new [=server] (file, outUrl) => { server.Url(scope $"/{file}", outUrl); };
			});
		// The release: its samples.json, one sample's zip (a project's manifest at its root) and picture.
		let zip = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(FindDataRoot(.. scope .()), "Tests/Zip/sample.zip", .. scope .()), zip) case .Ok);
		let picture = scope List<uint8>();
		Test.Assert(ReadFile(l.WritePicture("picture.png", .. scope .()), picture) case .Ok);
		let catalog = scope String();
		catalog.AppendF("""
			{{"version": "0.1.0", "samples": [{{"folder": "Gallery", "name": "Shader Gallery", "description": "A hall of shaders.",
			 "archive": "sample-Gallery.zip", "size": {}, "sha256": "{}", "picture": "sample-Gallery.png"}}]}}
			""", zip.Count, Sha256.Of(zip).ToHex(.. scope .()));
		server.Serve("/samples.json", catalog);
		server.Serve("/sample-Gallery.zip", zip);
		server.Serve("/sample-Gallery.png", picture);

		l.View.ShowSamples(true);
		RunUntil(l, server, scope () => l.View.SampleCatalogState == .Loaded);
		Test.Assert(l.View.SampleCatalogState == .Loaded);
		Test.Assert(l.View.Samples.Samples.Count == 1);
		let grid = l.View.Content.FindElement("manager-samples");
		Test.Assert(grid != null);
		Test.Assert(grid.ChildCount == 1);
		let download = ButtonText(grid, "Download...");
		Test.Assert(download != null);
		Test.Assert(!l.View.InProjects(l.View.Samples.Samples[0]));

		// Download... asks where; the location starts where the last project went. Only the first
		// stage shows.
		l.Controller.SetLastLocation(l.Root);
		Test.Assert(download.HandleActivate());
		let dialog = l.View.DownloadDialog;
		Test.Assert(dialog != null);
		Test.Assert(dialog.FindElement("download-sample-choose").Displayed);
		Test.Assert(dialog.FindElement("download-sample-go").Displayed);
		Test.Assert(dialog.FindElement("download-sample-cancel").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-progress").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-result").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-close").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-retry").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-open").Displayed);
		Test.Assert((dialog.FindElement("download-sample-where") as Sedulous.GUI.Label).Text.StartsWith("Downloads into"));
		let go = dialog.FindElement("download-sample-go") as Sedulous.GUI.Button;
		Test.Assert(go != null);
		Test.Assert(go.Enabled);
		Test.Assert(go.HandleActivate());
		// The dialog stays, showing the download, then how it ended.
		Test.Assert(l.View.DownloadDialog != null);
		Test.Assert(dialog.FindElement("download-sample-progress").Displayed);
		Test.Assert(!dialog.FindElement("download-sample-choose").Displayed);
		l.Drain();
		RunUntil(l, server, scope () => l.View.DownloadOf("Gallery") == null);
		Test.Assert(l.View.DownloadDialog != null);
		Test.Assert(dialog.FindElement("download-sample-result").Displayed);
		Test.Assert((dialog.FindElement("download-sample-result-text") as Sedulous.GUI.Label).Text.Contains("is in your projects", true));
		let openIt = dialog.FindElement("download-sample-open") as Sedulous.GUI.Button;
		Test.Assert(openIt != null);
		Test.Assert(openIt.Displayed);
		Test.Assert(openIt.HandleActivate()); // opens the new project
		Test.Assert(l.View.DownloadDialog == null);
		Test.Assert(l.Opened.Count == 1);
		Test.Assert(l.Opened[0] == PathJoin(l.Root, "Gallery", .. scope .()));

		// It is one of the projects now, and its card says so.
		let target = PathJoin(l.Root, "Gallery", .. scope .());
		Test.Assert(FileExists(PathJoin(target, "Project.xml", .. scope .())), scope String(l.View.Status));
		bool listed = false;
		for (let e in l.Controller.Entries.Entries)
			listed = listed || (e.Path == target);
		Test.Assert(listed);
		l.Drain();
		Test.Assert(l.View.InProjects(l.View.Samples.Samples[0]));
		Test.Assert(HasLabel(l.View.Content.FindElement("manager-samples").GetChildAt(0), "In your projects"));
		Test.Assert(l.View.Status.Contains("in your projects", true), scope String(l.View.Status));
	}

	[Test]
	public static void TheSamplesTabSaysWhenTheReleaseHasNoSamplesAndWhenGitHubIsNotReached()
	{
		let client = scope NativeHttpClient(null);
		let server = scope LoopbackFiles(); // serves nothing: samples.json is a 404
		let l = scope Launcher(0, false, scope [&] (services) =>
			{
				services.Http = client;
				services.ReleaseFile = new [=server] (file, outUrl) => { server.Url(scope $"/{file}", outUrl); };
			});
		l.View.ShowSamples(true);
		RunUntil(l, server, scope () => l.View.SampleCatalogState != .Fetching);
		Test.Assert(l.View.SampleCatalogState == .NotPublished);
		Test.Assert(l.View.Content.FindElement("manager-samples-state").Displayed);
		Test.Assert((l.View.Content.FindElement("manager-samples-state-title") as Sedulous.GUI.Label).Text == "No samples for this version yet");
		Test.Assert(!l.View.Content.FindElement("manager-samples-retry").Displayed);
		// Nothing to say, the footer says nothing; back on Projects, how to open one.
		let footer = l.View.Content.FindElement("manager-status") as Sedulous.GUI.Label;
		Test.Assert(footer.Text.IsEmpty, scope String(footer.Text));
		l.View.ShowSamples(false);
		Test.Assert(footer.Text == "Double-click a project or press Enter to open it.", scope String(footer.Text));

		// With no client at all, it cannot be reached, and Retry is offered.
		let offline = scope Launcher();
		offline.View.ShowSamples(true);
		Test.Assert(offline.View.SampleCatalogState == .Failed);
		Test.Assert(offline.View.Content.FindElement("manager-samples-retry").Displayed);
	}
}
