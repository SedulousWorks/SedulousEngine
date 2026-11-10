using System;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Look;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorWindow's look: the sheet a look makes from the editor's files, the density's sheet after
/// the editor's so its sizes win, the user's accent as an input after both, the user's theme
/// overrides last and again as they change; the look from the
/// user's settings and back into them. And with no window or device it opens no interface, and
/// what it is then asked does nothing.
static class EditorWindowTests
{
	/// No shell, no graphics, no windows: a headless run.
	private class HeadlessHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	/// Written through a mount, which makes the folders on the way.
	private static void Write(StringView root, StringView relative, StringView text)
	{
		let fs = scope NativeFileSystem(root);
		Test.Assert(fs.Save(relative, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	[Test]
	public static void ALooksSheetIsTheEditorsThenItsDensitysThenTheUsersAccent()
	{
		let root = Scratch("scratch_editor_window", .. scope .());
		Write(root, "Editor/editor.css", ".frame { color: var(--text); }");
		Write(root, "Editor/density-compact.css", ":root { --row: 22px; }");
		Write(root, "Editor/density-comfortable.css", ":root { --row: 32px; }");
		let resources = scope EditorResources(root);

		let look = scope EditorLook();
		let compact = EditorWindow.SheetFor(resources, look, .. scope .());
		let editor = compact.IndexOf(".frame");
		let density = compact.IndexOf("--row: 22px");
		let accent = compact.IndexOf("--accent-input: #2f6fdf");
		Test.Assert(editor >= 0);
		Test.Assert(editor < density);
		Test.Assert(density < accent);
		Test.Assert(!compact.Contains("--row: 32px"), "one density's sheet, the chosen one");

		look.Density.Set("comfortable");
		look.Accent.Set("#0f8a7e");
		let comfortable = EditorWindow.SheetFor(resources, look, .. scope .());
		Test.Assert(comfortable.Contains("--row: 32px"));
		Test.Assert(comfortable.Contains("--accent-input: #0f8a7e"));
	}

	[Test]
	public static void TheUsersThemeOverridesComeLastSoTheyWinAndApplyAgainAsTheFileComesChangesAndGoes()
	{
		let root = Scratch("scratch_editor_window_theme", .. scope .());
		defer RemoveDirectoryRecursive(root);
		Write(root, "Editor/editor.css", ".frame { color: var(--text); }");
		Write(root, "Editor/density-compact.css", ":root { --row: 22px; }");
		let resources = scope EditorResources(root);
		let folder = PathJoin(root, "user-theme", .. scope .());
		Test.Assert(CreateDirectory(folder));
		let theme = scope EditorResources(folder); // empty, as on a first run

		let look = scope EditorLook();
		let sheet = scope String();
		int applied = 0;
		let reload = new Effect(new [&] () =>
			{
				resources.TrackChanges();
				theme.TrackChanges();
				sheet.Clear();
				EditorWindow.SheetFor(resources, look, theme, sheet);
				applied++;
			});
		defer delete reload;
		Test.Assert(applied == 1);
		Test.Assert(!sheet.Contains("--surface: #000000"), "no file: nothing of the user's");

		Write(folder, EditorWindow.cThemeOverridesPath, ":root { --surface: #000000; --accent-input: #ff0000; }");
		Test.Assert(theme.Poll());
		Test.Assert(applied == 2);
		let accent = sheet.IndexOf("--accent-input: #2f6fdf");
		let theirs = sheet.IndexOf("--accent-input: #ff0000");
		Test.Assert(sheet.Contains("--surface: #000000"));
		Test.Assert((accent >= 0) && (accent < theirs), "after Preferences' inputs, so the user's own accent wins");

		Write(folder, EditorWindow.cThemeOverridesPath, ":root { --surface: #101010; }");
		Test.Assert(theme.Poll());
		Test.Assert(applied == 3);
		Test.Assert(sheet.Contains("--surface: #101010"));
		Test.Assert(!sheet.Contains("--surface: #000000"));

		Test.Assert(System.IO.File.Delete(PathJoin(folder, EditorWindow.cThemeOverridesPath, .. scope .())) case .Ok);
		Test.Assert(theme.Poll());
		Test.Assert(applied == 4);
		Test.Assert(!sheet.Contains("--surface: #101010"), "removed: the editor's own look again");
	}

	[Test]
	public static void ItsWindowsPresentWithAThirdImageSoALateCompositorCostsNoRefresh()
	{
		let desc = EditorWindow.EditorRenderWindowDesc();
		Test.Assert(desc.BufferCount == 3);
		Test.Assert(desc.PresentMode == .Fifo);
		Test.Assert(RenderWindowDesc().BufferCount == 2, "a game keeps the default");
	}

	[Test]
	public static void TheLookFromTheUsersSettingsTheDefaultsForWhatIsUnsetOrNamedWronglyAndBack()
	{
		let none = scope EditorLook();
		none.Dark = false; // read over: none's defaults replace what it had
		none.ReadFrom(null);
		Test.Assert(none.Dark);
		Test.Assert(none.Accent == "#2f6fdf");
		Test.Assert(none.Density == "compact");
		Test.Assert(!none.ReduceMotion);
		Test.Assert(none.UiScale == 1.0f);

		let ui = scope EditorUiSettings();
		ui.Scheme.Set("light");
		ui.Accent.Set("#0f8a7e");
		ui.Density.Set("comfortable");
		ui.ReduceMotion = true;
		ui.UiScale = 9.0f; // past the range
		let look = scope EditorLook();
		look.ReadFrom(ui);
		Test.Assert(!look.Dark);
		Test.Assert(look.Accent == "#0f8a7e");
		Test.Assert(look.Density == "comfortable");
		Test.Assert(look.ReduceMotion);
		Test.Assert(look.UiScale == EditorUiSettings.MaxUiScale);

		ui.Accent.Set("red"); // no colour
		ui.Density.Set("roomy"); // no sheet
		look.ReadFrom(ui);
		Test.Assert(look.Accent == "#2f6fdf");
		Test.Assert(look.Density == "compact");
		ui.Accent.Set("#0f8a7"); // one digit short
		ui.Scheme.Set("sepia"); // not light: dark
		look.ReadFrom(ui);
		Test.Assert(look.Accent == "#2f6fdf");
		Test.Assert(look.Dark);
		ui.Accent.Set("#0F8A7E"); // either case
		look.ReadFrom(ui);
		Test.Assert(look.Accent == "#0F8A7E");

		let stored = scope EditorUiSettings();
		stored.AutoOrthographic = false;
		let chosen = scope EditorLook();
		chosen.Dark = false;
		chosen.Accent.Set("#6d5bd8");
		chosen.Density.Set("default");
		chosen.ReduceMotion = true;
		chosen.UiScale = 1.25f;
		chosen.StoreInto(stored);
		Test.Assert(stored.Scheme == "light");
		Test.Assert(stored.Accent == "#6d5bd8");
		Test.Assert(stored.Density == "default");
		Test.Assert(stored.ReduceMotion);
		Test.Assert(stored.UiScale == 1.25f);
		Test.Assert(!stored.AutoOrthographic, "kept");
		chosen.Dark = true;
		chosen.StoreInto(stored);
		Test.Assert(stored.Scheme == "dark");
	}

	[Test]
	public static void WithNoWindowOrDeviceItOpensNoInterfaceAndItsCallsDoNothing()
	{
		let host = scope HeadlessHost();
		let window = scope EditorWindow();
		let look = scope EditorLook();
		look.Density.Set("comfortable");
		Test.Assert(!window.Open(host, "unused", look));
		Test.Assert(!window.IsOpen);
		Test.Assert(window.Host == null);
		Test.Assert(window.Root == null);
		Test.Assert(window.Resources == null);
		Test.Assert(window.FindById("status-message") == null);
		Test.Assert(window.StatusBar == null);
		Test.Assert(window.LoadMarkup(EditorWindow.cFramePath) == null);
		window.SetStatus("nothing shows it");
		window.ShowToast(.Error, "nothing shows it");
		window.Update(2.0f);
		// No frame to show a screen in place of.
		let screen = new Sedulous.GUI.Panel();
		window.ShowScreen(screen);
		Test.Assert(!window.ShowsScreen);
		screen.ReleaseRef();
		// The look is kept for when it opens.
		window.SetLook(look);
		Test.Assert(window.Look.Density == "comfortable");
		Test.Assert(window.Look !== look, "copied");
		window.Close();
		window.Close(); // again: nothing left to let go of
	}

	[Test]
	public static void ANoticesToastTimesOutOneWithAnActionStaysWithItsButton()
	{
		let plain = scope ToastRequest();
		EditorWindow.MakeToast(.Success, "Cook finished", "", plain);
		Test.Assert(plain.Severity == .Success);
		Test.Assert(plain.Title == "Cook finished");
		Test.Assert(plain.Duration > 0.0f); // it goes
		Test.Assert(plain.Actions.IsEmpty);

		let exported = scope ToastRequest();
		EditorWindow.MakeToast(.Success, "Exported to Dist/Linux64", "Open Folder", exported);
		Test.Assert(exported.Duration == 0.0f); // until closed
		Test.Assert(exported.Actions.Count == 1);
		Test.Assert(exported.Actions[0].Text == "Open Folder");
	}
}
