using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The editor-wide actions and the surfaces generated from them. Declared once in
/// RegisterActions, in menu order (the bar lists menus in the order their names first appear),
/// before the domains register theirs; BuildMenus then generates the menu bar and the global
/// shortcuts from the registry, File > New <creator> leading the File menu as the one
/// list-driven set. File holds the document and app essentials; per-user prefs live under Edit;
/// project-scoped concerns get the Project menu; Build stays cook-only. There are no native
/// module actions.
extension EditorApplication
{
	private void RegisterActions()
	{
		let actions = mContext.Actions;
		{
			let d = new EditorActionDeclaration("file.save", "Save", "Save the active page to its source asset", "File/Save", 100);
			d.Enabled = new (page) => (page != null) && page.IsDirty;
			d.Shortcut = .(.S, .Ctrl);
			d.Execute = new (page) => { SavePage(page); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("file.saveAs", "Save As...", "Save the active page as a new source asset", "File/Save As...", 101);
			d.Enabled = new (page) => page != null;
			d.Execute = new (page) => { SavePageAs(page); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("file.saveLayout", "Save Layout", "Save the panel layout as the default for this editor", "File/Save Layout", 200);
			d.Execute = new (page) =>
				{
					SaveLayout();
					mContext.SetStatus("Layout saved.");
				};
			actions.Register(d);
		}
		// Only meaningful when the manager launched us; a CLI-opened editor keeps its
		// single-project lifecycle, Exit being the way out.
		if (mConfig.StartInProjectManager)
		{
			let d = new EditorActionDeclaration("file.closeProject", "Close Project", "Close the project and return to the project manager", "File/Close Project", 300);
			d.Execute = new (page) => { ConfirmCloseProjectThen(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("file.exit", "Exit", "Exit the editor", "File/Exit", 301);
			d.Execute = new (page) =>
				{
					if ((mHost != null) && ConfirmExitAllowed())
						mHost.RequestExit();
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("edit.undo", "Undo", "Undo the active page's last edit", "Edit/Undo", 100);
			d.Enabled = new (page) => (page != null) && page.Commands.CanUndo;
			d.Shortcut = .(.Z, .Ctrl);
			d.Execute = new (page) => { page.Commands.Undo(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("edit.redo", "Redo", "Redo the active page's last undone edit", "Edit/Redo", 101);
			d.Enabled = new (page) => (page != null) && page.Commands.CanRedo;
			d.Shortcut = .(.Z, .Ctrl | .Shift);
			d.AlternateShortcut = .(.Y, .Ctrl);
			d.Execute = new (page) => { page.Commands.Redo(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("page.discardChanges", "Discard Changes", "Revert the page's unsaved edits");
			d.Enabled = new (page) => (page != null) && page.IsDirty;
			d.Execute = new (page) => { page.DiscardChanges(); };
			actions.Register(d);
		}
		{
			// Per-user, not per-document: the conventional Edit home.
			let d = new EditorActionDeclaration("edit.preferences", "Preferences...", "Open the per-user editor preferences", "Edit/Preferences...", 200);
			d.Execute = new (page) =>
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
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("project.settings", "Project Settings...", "Open the project settings", "Project/Project Settings...", 100);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) =>
				{
					if (mProject != null)
					{
						let dialog = new ProjectSettingsDialog(mContext);
						dialog.Show(mUiHost.Context);
					}
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("project.export", "Export...", "Open the export presets panel", "Project/Export...", 300);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) => { OpenExportPresetsPanel(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("project.manageTemplates", "Manage Templates...", "Manage the export templates", "Project/Manage Templates...", 301);
			d.Execute = new (page) => { OpenTemplatesManager(); };
			actions.Register(d);
		}
		{
			// What is resident, from the log: counts by product type, unreferenced being the
			// cache-only purge candidates.
			let d = new EditorActionDeclaration("project.reportResourceMemory", "Report Resource Memory", "Log the resident resources by type (unreferenced = purge candidates)", "Project/Report Resource Memory", 400);
			d.ReadOnly = true;
			d.Execute = new (page) => { ReportResourceMemory(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("build.cookAll", "Cook All", "Cook the dirty assets into the cooked database", "Build/Cook All", 100);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) => { mCookService.RequestCook(false); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("build.rebuildAll", "Rebuild All", "Cook every asset again", "Build/Rebuild All", 101);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) => { mCookService.RequestCook(true); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("game.play", "Play", "Play the project in the Game page", "Game/Play", 100);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) => { OpenGamePage(false); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("game.playNewInstance", "Play New Instance", "Play the project in a fresh Game page", "Game/Play New Instance", 101);
			d.Enabled = new (page) => mProject != null;
			d.Execute = new (page) => { OpenGamePage(true); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("view.resetLayout", "Reset Layout", "Reset the panel layout to the default", "View/Reset Layout", 100);
			d.Execute = new (page) =>
				{
					mShell.ResetLayout();
					mContext.SetStatus("Layout reset to default.");
				};
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("help.about", "About", "The editor's version", "Help/About", 100);
			d.ReadOnly = true;
			d.Execute = new (page) =>
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
				};
			actions.Register(d);
		}
	}

	/// The bar and the global shortcuts, GENERATED from the action registry (RegisterActions and
	/// each domain's RegisterEditor); a menu's items are rebuilt when it opens, so enabled states
	/// are the registry's answer at that moment. Shortcuts dispatch AFTER the focused view, and
	/// text controls mark their key-downs handled: a focused textbox keeps Ctrl+Z for its own
	/// undo.
	private void BuildMenus()
	{
		mActionMenus = new ActionMenuBar(mShell.Menus, mContext.Actions);
		// File > New <creator> from the creator registry; categorised creators nest in a
		// submenu of that name.
		mActionMenus.AddLeadingItems("File", new (file) =>
			{
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
					for (let creator in mContext.Creators)
					{
						if (creator.Category != category)
							continue;
						submenu.AddItem(creator.Label, new [=creator, =this]() => { CreateAndOpen(creator); });
					}
				}
			});
		mActionShortcuts = new ActionShortcuts(mUiHost.Context.GetShortcuts(), mContext.Actions);
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
