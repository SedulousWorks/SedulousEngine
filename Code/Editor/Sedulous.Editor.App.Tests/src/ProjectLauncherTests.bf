using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App.Tests;

/// The project launcher: the recent projects as a list or a grid (remembered), each by its
/// picture (the thumbnail in its editor folder, an image chosen for it, or a placeholder with
/// its initial), and each project's menu.
class ProjectLauncherTests
{
	/// Two projects and one whose folder is gone, most recent first: First, Second, Gone.
	private class Launcher
	{
		public String Root = new .() ~ delete _;
		public String First = new .() ~ delete _;
		public String Second = new .() ~ delete _;
		public String Gone = new .() ~ delete _;
		public Settings Store = new .() ~ delete _;
		public ProjectManagerController Controller ~ delete _;
		public ProjectManagerView View ~ delete _;
		public int Saves = 0;

		public this()
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
			ProjectRegistry.TouchRecentProject(Store, Gone, "Gone", "0.1.0"); // no project there
			ProjectRegistry.TouchRecentProject(Store, Second, "Second", "0.1.0");
			ProjectRegistry.TouchRecentProject(Store, First, "First", "0.1.0");
			Controller = new .(Store);
			View = new .();
			View.OnStoreChanged = new () => { Saves++; };
			View.Build(Controller, null, null, 1280, 800);
		}

		public ~this()
		{
			DeleteAndNullify!(View);
			RemoveDirectoryRecursive(Root);
		}

		/// A small RGBA picture written as `name` under the scratch root.
		public void WritePicture(StringView name, String outPath)
		{
			let picture = scope Image(16, 9, .RGBA8);
			PathJoin(Root, name, outPath);
			Test.Assert(ImageIO.SaveImage(picture, outPath, .PNG) case .Ok);
		}
	}

	[Test]
	public static void TheProjectsShowAsAListOrAGridAndTheChoiceIsRemembered()
	{
		let l = scope Launcher();
		Test.Assert(!l.View.IsGridView);
		Test.Assert(l.View.CardCount == 3);
		Test.Assert(l.View.ThumbnailCount == 0, "no pictures yet: placeholders");

		l.View.SetGridView(true);
		Test.Assert(l.View.IsGridView);
		Test.Assert(l.View.CardCount == 3);
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
	}

	[Test]
	public static void AProjectsPictureIsItsThumbnailAnImageChosenForItOrNone()
	{
		let l = scope Launcher();
		// A captured thumbnail in the project's editor folder shows.
		let captured = l.WritePicture("captured.png", .. scope .());
		let thumbnail = EditorProject.ThumbnailPath(l.First, .. scope .());
		CreateDirectory(PathParent(thumbnail, .. scope .()));
		let picture = scope Image();
		Test.Assert(ImageIO.LoadImage(captured, picture) case .Ok);
		Test.Assert(ImageIO.SaveImage(picture, thumbnail, .PNG) case .Ok);
		l.View.Rebuild();
		Test.Assert(l.View.ThumbnailCount == 1);

		// An image chosen for the second project becomes its thumbnail.
		let chosen = l.WritePicture("chosen.png", .. scope .());
		Test.Assert(l.View.SetThumbnailFromImage(l.Second, chosen));
		Test.Assert(FileExists(EditorProject.ThumbnailPath(l.Second, .. scope .())));
		Test.Assert(l.View.ThumbnailCount == 2);
		Test.Assert(!l.View.SetThumbnailFromImage(l.Second, "/nowhere/at/all.png"));
	}

	[Test]
	public static void EachProjectsMenuHoldsWhatAppliesToIt()
	{
		let l = scope Launcher();
		let items = scope List<StringView>();
		l.View.MenuItemsFor(l.First, items);
		Test.Assert(items.Count == 5);
		Test.Assert((items[0] == "Open") && (items[1] == "Show in Folder") && (items[2] == "Copy Path"));
		Test.Assert((items[3] == "Choose Thumbnail Image...") && (items[4] == "Remove from List"));

		// With a thumbnail, it can be cleared.
		Test.Assert(l.View.SetThumbnailFromImage(l.First, l.WritePicture("p.png", .. scope .())));
		items.Clear();
		l.View.MenuItemsFor(l.First, items);
		Test.Assert(items[4] == "Clear Thumbnail");

		// A missing project: only what still makes sense.
		items.Clear();
		l.View.MenuItemsFor(l.Gone, items);
		Test.Assert(items.Count == 3);
		Test.Assert((items[0] == "Show in Folder") && (items[2] == "Remove from List"));
	}

	/// The tooltip's texts: its labels (name, detail, path), then its row of buttons.
	private static void CollectTexts(View tip, List<String> outLabels, List<String> outButtons)
	{
		let group = tip as ViewGroup;
		Test.Assert((group != null) && (group.ChildCount == 4));
		for (int i < 3)
			outLabels.Add(new String((group.GetChildAt(i) as Label).Text.Value));
		let row = group.GetChildAt(3) as ViewGroup;
		for (int i < row.ChildCount)
			outButtons.Add(new String((row.GetChildAt(i) as Button).Text.Value));
	}

	[Test]
	public static void ATilesTooltipNamesTheProjectItsEngineAndItsPathWithItsActions()
	{
		let l = scope Launcher();
		l.View.SetGridView(true);
		let labels = scope List<String>();
		let buttons = scope List<String>();
		defer { ClearAndDeleteItems(labels); ClearAndDeleteItems(buttons); }
		var tip = l.View.TileTooltipFor(l.First);
		Test.Assert(tip != null);
		CollectTexts(tip, labels, buttons);
		tip.ReleaseRef();
		Test.Assert(labels.Count == 3);
		Test.Assert(labels[0] == "First");
		Test.Assert(labels[1].StartsWith("Engine "));
		Test.Assert(labels[2] == l.First);
		Test.Assert(buttons.Count == 3);
		Test.Assert((buttons[0] == "Open") && (buttons[1] == "Show in Folder") && (buttons[2] == "Copy Path"));

		// A missing project: no Open, and the tooltip says why.
		ClearAndDeleteItems(labels);
		ClearAndDeleteItems(buttons);
		tip = l.View.TileTooltipFor(l.Gone);
		Test.Assert(tip != null);
		CollectTexts(tip, labels, buttons);
		tip.ReleaseRef();
		Test.Assert(labels[1].StartsWith("Missing"));
		Test.Assert((buttons.Count == 2) && (buttons[0] == "Show in Folder"));

		// Not a project the launcher shows: no tooltip.
		Test.Assert(l.View.TileTooltipFor("/nowhere") == null);
	}
}
