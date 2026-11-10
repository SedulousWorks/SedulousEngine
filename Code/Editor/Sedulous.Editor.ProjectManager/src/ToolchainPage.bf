using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.ProjectManager;

/// The project manager's Toolchain page, over its parts in the manager's markup
/// (Data/Editor/ProjectManager.xml): for the engine picked (the newest listed at first), what a
/// project's build needs besides it, a line each (BeefBuild with its version beside the engine's
/// pin, the linker, the archiver, Emscripten), each with its state and its fix; Install Toolchain
/// while the toolchain the engine names is not installed, with its bar and Cancel while it installs;
/// and Emscripten's folder, written into the installed toolchain's settings.
class ToolchainPage
{
	/// BORROWED, all: the manager's frame, the engines, the view whose status line it speaks on, and
	/// the shell's dialogs (null: none).
	private Node mContent;
	private EngineManager mEngines;
	private ProjectManagerView mView;
	private IDialogService mDialogs;
	/// The engines the picker lists (their roots), newest first, and the one picked (-1: none).
	private List<String> mRoots = new .() ~ DeleteContainerAndItems!(_);
	private int32 mPicked = -1;
	/// The last check, of the engine picked.
	private ToolchainReport mReport = new .() ~ delete _;
	private int mChangeSeen = 0;

	public this(Node content, EngineManager engines, ProjectManagerView view, IDialogService dialogs)
	{
		mContent = content;
		mEngines = engines;
		mView = view;
		mDialogs = dialogs;
		mChangeSeen = engines.ChangeSerial;
		if (let picker = Find<Sedulous.GUI.ComboBox>("manager-toolchain-engine"))
			picker.SetOnSelectionChanged(new (index) =>
				{
					mPicked = index;
					Check();
				});
		if (let recheck = Find<Sedulous.GUI.Button>("manager-toolchain-recheck"))
			recheck.SetOnClick(new () => { Check(); });
		if (let install = Find<Sedulous.GUI.Button>("manager-toolchain-install"))
			install.SetOnClick(new () => { InstallToolchain(); });
		if (let cancel = Find<Sedulous.GUI.Button>("manager-toolchain-cancel"))
			cancel.SetOnClick(new () => { mEngines.CancelToolchain(); });
		if (let browse = Find<Sedulous.GUI.Button>("manager-toolchain-emsdk-browse"))
			browse.SetOnClick(new () => { BrowseEmscripten(); });
		if (let apply = Find<Sedulous.GUI.Button>("manager-toolchain-emsdk-set"))
			apply.SetOnClick(new () => { SetEmscripten(); });
	}

	/// The lines call back nowhere; they go with the frame.
	public ~this()
	{
		Clear(Find<Node>("manager-toolchain-lines"));
	}

	/// The last check's report (a test's).
	public ToolchainReport Report => mReport;

	/// The page comes into view: the engines listed again in the picker, the one picked kept (else
	/// the newest), and checked.
	public void Shown()
	{
		mEngines.ReadInstalled();
		let kept = scope String();
		if ((mPicked >= 0) && (mPicked < mRoots.Count))
			kept.Set(mRoots[mPicked]);
		ClearAndDeleteItems!(mRoots);
		let engines = scope List<InstalledEngine>();
		for (let engine in mEngines.Installed)
		{
			if (!engine.Missing)
				engines.Add(engine);
		}
		engines.Sort(scope (a, b) => ProjectManagerProgram.NewerSdk(a.Info, b.Info) ? -1 : (ProjectManagerProgram.NewerSdk(b.Info, a.Info) ? 1 : 0));
		mPicked = engines.IsEmpty ? -1 : 0;
		let picker = Find<Sedulous.GUI.ComboBox>("manager-toolchain-engine");
		if (picker != null)
			picker.ItemsText = "";
		for (let engine in engines)
		{
			mRoots.Add(new .(engine.Root));
			if (engine.Root == kept)
				mPicked = (int32)@engine.Index;
			if (picker != null)
				picker.AddItem(scope $"{engine.Info.Display}{engine.Info.IsCheckout ? " (checkout)" : ""} at {engine.Root}");
		}
		if (picker != null)
			picker.SelectedIndex = mPicked;
		mChangeSeen = mEngines.ChangeSerial;
		Check();
	}

	/// Once a frame while the page shows: the toolchain checked again once an install has ended,
	/// else the install's bar.
	public void Tick()
	{
		if (mEngines.ChangeSerial != mChangeSeen)
		{
			mChangeSeen = mEngines.ChangeSerial;
			let queue = (mContent != null) ? mContent.MutationQueue : null;
			if (queue != null)
				queue.Enqueue(new [=this] () => { Check(); });
			else
				Check();
			return;
		}
		ShowProgress();
	}

	/// The engine picked read again and its toolchain checked, the lines laid out from the report.
	public void Check()
	{
		mReport.Clear();
		let sdk = scope SdkInfo();
		let picked = (mPicked >= 0) && (mPicked < mRoots.Count) && (SdkInfo.Read(mRoots[mPicked], sdk) case .Ok);
		if (picked)
			mEngines.CheckToolchain(sdk, mReport);
		let lines = Find<Node>("manager-toolchain-lines");
		Clear(lines);
		if (lines != null)
		{
			for (let line in mReport.Lines)
				Adopt(lines, LineRow(line));
		}
		if (let none = Find<Node>("manager-toolchain-none"))
			none.Displayed = !picked;
		// The toolchain the engine names, while it is not installed: Install, and while it installs,
		// the bar and Cancel.
		let installing = mEngines.InstallingToolchain;
		let offer = picked && !sdk.Beef.IsEmpty && !mEngines.HasToolchain(sdk.Beef);
		if (let install = Find<Sedulous.GUI.Button>("manager-toolchain-install"))
		{
			install.Displayed = offer && !installing;
			install.Text = scope $"Install Toolchain {sdk.Beef}";
		}
		if (let progress = Find<Node>("manager-toolchain-progress"))
			progress.Displayed = installing;
		if (let pin = Find<Sedulous.GUI.Label>("manager-toolchain-pin"))
		{
			if (!picked)
				pin.Text = "";
			else if (sdk.Beef.IsEmpty)
				pin.Text = scope $"Engine {sdk.Display} names no toolchain: it builds with your own Beef (BeefBuild on PATH, or {ProjectBuild.cBeefBuildVariable}).";
			else if (mEngines.HasToolchain(sdk.Beef))
				pin.Text = scope $"Engine {sdk.Display} was built with Beef {sdk.Beef}, which is installed.";
			else
				pin.Text = scope $"Engine {sdk.Display} was built with Beef {sdk.Beef}: install it, or use your own.";
		}
		// Emscripten's folder is written only into the installed toolchain's settings.
		if (let apply = Find<Sedulous.GUI.Button>("manager-toolchain-emsdk-set"))
			apply.Enabled = mReport.Managed;
		if (let field = Find<Sedulous.GUI.TextField>("manager-toolchain-emsdk"))
		{
			let emscripten = mReport.Get(.Emscripten);
			if ((emscripten != null) && (emscripten.State != .Missing) && field.Text.IsEmpty)
				field.Text = emscripten.Found;
		}
		ShowProgress();
	}

	/// Install Toolchain: the toolchain the picked engine names, from its release.
	private void InstallToolchain()
	{
		let sdk = scope SdkInfo();
		if ((mPicked < 0) || (mPicked >= mRoots.Count) || (SdkInfo.Read(mRoots[mPicked], sdk) case .Err))
			return;
		let why = scope String();
		if (!mEngines.InstallToolchain(sdk, why))
			mView.SetStatus(why);
		Check();
	}

	private void BrowseEmscripten()
	{
		let field = Find<Sedulous.GUI.TextField>("manager-toolchain-emsdk");
		if ((mDialogs == null) || (field == null))
			return;
		mDialogs.ShowOpenFolder(new [=field] (paths) =>
			{
				if (paths.Length > 0) // none: cancelled
					field.Text = paths[0];
			}, field.Text, false, 0);
	}

	/// Set: the field's folder written as Emscripten's into the toolchain's settings, then checked
	/// again; else what to do on the status line.
	private void SetEmscripten()
	{
		let field = Find<Sedulous.GUI.TextField>("manager-toolchain-emsdk");
		if (field == null)
			return;
		let why = scope String();
		if (!mEngines.SetEmscripten(mReport, field.Text, why))
			mView.SetStatus(why);
		Check();
	}

	/// The install's bar and words, while it runs.
	private void ShowProgress()
	{
		let download = mEngines.ToolchainDownload;
		if (let bar = Find<Sedulous.GUI.ProgressBar>("manager-toolchain-bar"))
		{
			bar.Min = 0.0;
			bar.Max = 1.0;
			bar.Value = (download != null) ? download.Progress : 0.0f;
		}
		if (let words = Find<Sedulous.GUI.Label>("manager-toolchain-stage"))
		{
			if (download == null)
				words.Text = "Reading the release's index...";
			else
				words.Text = scope $"Downloading {ByteSizeText(download.Received, .. scope .())} of {ByteSizeText(download.Total, .. scope .())}";
		}
	}

	/// One need's row: its state's icon, its name, what was found, and what is wrong with the fix.
	/// A node with one reference, the caller's.
	private static Node LineRow(ToolchainLine line)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-toolchain-line");
		let icon = new Sedulous.GUI.Image();
		icon.AddClass("message-icon");
		switch (line.State)
		{
		case .Ok:
			icon.Source = "Editor/Icons/check.svg";
		case .Warning:
			icon.Source = "Editor/Icons/warning.svg";
			row.AddClass("warning");
		case .Missing:
			icon.Source = "Editor/Icons/error.svg";
			row.AddClass("error");
		}
		Adopt(row, icon);
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		Adopt(text, Text(NeedName(line.Need), "manager-name"));
		if (!line.Found.IsEmpty)
		{
			let found = Text(line.Found, "manager-path");
			found.Tooltip = line.Found;
			Adopt(text, found);
		}
		if (!line.Detail.IsEmpty)
		{
			Adopt(text, Text(line.Detail, "manager-toolchain-detail"));
		}
		Adopt(row, text);
		return row;
	}

	private static StringView NeedName(ToolchainNeed need)
	{
		switch (need)
		{
		case .BeefBuild: return "BeefBuild";
		case .Linker: return "Linker";
		case .Archiver: return "Archiver";
		default: return "Emscripten (web exports only)";
		}
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private static void Clear(Node node)
	{
		if (node != null)
			node.RemoveAllChildren();
	}

	/// Adds `child` to `into`, the tree's reference taking the place of the one it was made with.
	private static void Adopt(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}

	/// A label of `text` with the sheet's `classes`: a node with one reference, the caller's.
	private static Sedulous.GUI.Label Text(StringView text, StringView classes)
	{
		let label = new Sedulous.GUI.Label();
		label.AddClasses(classes);
		label.Text = text;
		return label;
	}
}
