using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The menu bar and its keyboard equivalents. File holds the document and app essentials;
/// per-user prefs live under Edit; project-scoped concerns (settings, export, templates) get
/// the Project menu; Build stays cook-only. There are no native module items.
extension EditorApplication
{
	private void BuildMenus()
	{
		let bar = mShell.Menus;
		let file = bar.AddMenu("File");
		let editMenu = bar.AddMenu("Edit");
		let project = bar.AddMenu("Project");
		if (project != null)
		{
			// What is resident, from the log: counts by product type, unreferenced being the
			// cache-only purge candidates.
			project.AddItem("Report Resource Memory", new () => { ReportResourceMemory(); });
		}
		if (let build = bar.AddMenu("Build"))
		{
			build.AddItem("Cook All", new () => { mCookService.RequestCook(false); });
			build.AddItem("Rebuild All", new () => { mCookService.RequestCook(true); });
		}

		if (file != null)
		{
			// File > New <creator> from the registry; categorised creators nest in a submenu
			// of that name.
			let categories = scope List<StringView>();
			for (let creator in mContext.Creators)
			{
				if (creator.Category.IsEmpty)
				{
					file.AddItem(scope $"New {creator.Label}", new [=creator, =this]() => { CreateAndOpen(creator); });
					continue;
				}
				if (!categories.Contains(creator.Category))
					categories.Add(creator.Category);
			}
			categories.Sort(scope (a, b) => a <=> b);
			for (let category in categories)
			{
				let submenu = file.AddSubmenu(category).Submenu;
				if (submenu == null)
					continue;
				for (let creator in mContext.Creators)
				{
					if (creator.Category != category)
						continue;
					submenu.AddItem(creator.Label, new [=creator, =this]() => { CreateAndOpen(creator); });
				}
			}
			if (!mContext.Creators.IsEmpty)
				file.AddSeparator();

			file.AddItem("Save", new () => { SaveActivePage(); });
			file.AddItem("Save As...", new () => { SaveActivePageAs(); });
			file.AddSeparator();
			file.AddItem("Save Layout", new () =>
				{
					SaveLayout();
					mContext.SetStatus("Layout saved.");
				});
			file.AddSeparator();
			if (mConfig.StartInProjectManager)
			{
				// Only meaningful when the manager launched us; a CLI-opened editor keeps its
				// single-project lifecycle, Exit being the way out.
				file.AddItem("Close Project", new () => { ConfirmCloseProjectThen(); });
			}
			file.AddItem("Exit", new () =>
				{
					if ((mHost != null) && ConfirmExitAllowed())
						mHost.RequestExit();
				});
		}

		if (editMenu != null)
		{
			editMenu.AddItem("Undo", new () => { mContext.Undo(); });
			editMenu.AddItem("Redo", new () => { mContext.Redo(); });
			editMenu.AddSeparator();
			// Per-user, not per-document: the conventional Edit home.
			editMenu.AddItem("Preferences...", new () =>
				{
					let dialog = new EditorPreferencesDialog(mContext, mEditorSettings);
					// The UI scale applies live: the host scale, which the roots pick up next
					// frame, plus an icon re-bake at the effective scale.
					dialog.OnUiScaleApplied = new (uiScale) =>
						{
							mUiHost.SetUiScale(uiScale);
							let mainRw = (mHost != null) ? mHost.MainRenderWindow : null;
							let content = (mainRw != null) ? mainRw.Window.ContentScale : 1.0f;
							BakeEditorIcons(content * uiScale);
						};
					// The MCP host follows the saved preference at once: started, moved to the
					// new port, or stopped.
					dialog.OnMcpSettingsApplied = new () => { StartMcpHost(); };
					dialog.Show(mUiHost.Context);
				});
		}

		if (project != null)
		{
			project.AddItem("Project Settings...", new () =>
				{
					if (mProject != null)
					{
						let dialog = new ProjectSettingsDialog(mContext);
						dialog.Show(mUiHost.Context);
					}
				});
			// No native module items (Add Native Code, Build, Reload): native game modules are
			// not supported.
			project.AddSeparator();
			project.AddItem("Export...", new () => { OpenExportPresetsPanel(); });
			project.AddItem("Manage Templates...", new () => { OpenTemplatesManager(); });
		}

		// The keyboard equivalents dispatch after the focused view, and text controls mark
		// their key-downs handled, so a focused textbox keeps Ctrl+Z for its own undo and
		// these fire everywhere else.
		let shortcuts = mUiHost.Context.GetShortcuts();
		shortcuts.AddGlobal(.Z, .Ctrl, new () => { mContext.Undo(); });
		shortcuts.AddGlobal(.Z, .Ctrl | .Shift, new () => { mContext.Redo(); });
		shortcuts.AddGlobal(.Y, .Ctrl, new () => { mContext.Redo(); });
		shortcuts.AddGlobal(.S, .Ctrl, new () => { SaveActivePage(); });

		if (let game = bar.AddMenu("Game"))
		{
			game.AddItem("Play", new () => { OpenGamePage(false); });
			game.AddItem("Play New Instance", new () => { OpenGamePage(true); });
		}
		if (let view = bar.AddMenu("View"))
		{
			view.AddItem("Reset Layout", new () =>
				{
					mShell.ResetLayout();
					mContext.SetStatus("Layout reset to default.");
				});
		}
		if (let help = bar.AddMenu("Help"))
		{
			help.AddItem("About", new () =>
				{
					let dialog = new Dialog("About Editor");
					let column = new FlexLayout();
					column.Direction = .Vertical;
					column.Spacing = 8;
					let title = new Label("Editor");
					title.FontSize.Value = 18.0f;
					column.AddView(title);
					let versionLabel = new Label(scope $"Version {BuildStamp(.. scope .())}");
					versionLabel.WordWrap.Value = true;
					column.AddView(versionLabel);
					dialog.SetContent(column);
					dialog.AddButton("OK", .OK);
					dialog.Show(mUiHost.Context);
				});
		}
	}

	/// The build identity: the executable's write time, the same stamp the MCP host reports.
	private static void BuildStamp(String outStamp)
	{
		let exe = Environment.GetExecutableFilePath(.. scope .());
		if (File.GetLastWriteTimeUtc(exe) case .Ok(let time))
			time.ToString(outStamp, "yyyy-MM-ddTHH:mm:ssZ");
		else
			outStamp.Set("unknown");
	}
}
