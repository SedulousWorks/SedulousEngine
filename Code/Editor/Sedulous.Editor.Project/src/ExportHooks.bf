using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Runtime;

namespace Sedulous.Editor.Project;

/// What an export hook is handed: the project, the preset and the staged dist's folder. All
/// BORROWED, for the hook's call.
struct ExportHookContext
{
	public EditorProject Project;
	public ExportPreset Preset;
	public StringView OutputDir;
}

/// What a plugin's Tooling part adds to an export, through the service its host provides
/// (PluginContext.Find<ExportPluginServices>): hooks that run once a preset's dist is staged, for
/// what a plugin's data cannot say (a platform's own packaging step, a file written from the
/// project's settings). A hook that fails fails the export, with its reason. The service records
/// what each plugin added, so the plugin host's unload takes it out again.
class ExportPluginServices : IRegistrationRecorder
{
	/// A hook: runs after the dist is staged; false, with why in `outWhy`, fails the export.
	public typealias Hook = delegate bool(ExportHookContext context, String outWhy);

	private class Entry
	{
		/// This service's, what the recording keeps.
		public uint64 Token;
		public String Name = new .() ~ delete _;
		public Hook Run ~ delete _;
	}

	private List<Entry> mHooks = new .() ~ DeleteContainerAndItems!(_);
	/// The armed part's sink. BORROWED, the loader's; null while none loads.
	private List<uint64> mSink = null;
	private uint64 mNextToken = 1;

	/// Hands this service to `host`'s plugins and records what they add through it. Before the
	/// host enables any; this outlives the host.
	public bool Attach(PluginHost host)
	{
		if (!host.Provide(this))
			return false;
		host.Loader.AddRecorder(this);
		return true;
	}

	/// Adds a hook every export runs after staging, in the order they were added; `name` says whose
	/// it is in a failure. TAKES OWNERSHIP of `hook`. False for a null one.
	public bool AddHook(StringView name, Hook hook)
	{
		if (hook == null)
			return false;
		let entry = new Entry();
		entry.Token = mNextToken++;
		entry.Name.Set(name);
		entry.Run = hook;
		mHooks.Add(entry);
		if (mSink != null)
			mSink.Add(entry.Token);
		return true;
	}

	public int Count => mHooks.Count;

	/// Runs every hook over a staged dist: false at the first that fails, "<name>: <why>" in
	/// `outFailure`.
	public bool Run(ExportHookContext context, String outFailure)
	{
		for (let entry in mHooks)
		{
			let why = scope String();
			if (!entry.Run(context, why))
			{
				outFailure.AppendF("{}: {}", entry.Name, why);
				return false;
			}
			GlobalLog(.Information, "Export: export hook '{}' ran", entry.Name);
		}
		return true;
	}

	/// Armed around each part's load, so what it added is recorded against it.
	public override void Arm(List<uint64> sink) => mSink = sink;
	public override void Disarm() => mSink = null;

	public override void Reverse(uint64 id)
	{
		for (int i < mHooks.Count)
		{
			if (mHooks[i].Token == id)
			{
				delete mHooks[i];
				mHooks.RemoveAt(i);
				return;
			}
		}
	}
}
