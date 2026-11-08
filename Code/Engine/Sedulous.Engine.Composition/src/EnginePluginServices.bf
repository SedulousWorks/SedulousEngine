using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Scene;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Scene;

namespace Sedulous.Engine.Composition;

/// What a plugin's Engine part adds to the engine, through the service its host provides
/// (PluginContext.Find<EnginePluginServices>): a domain (its resource modules join the
/// composition), a scene manager (it reaches live scenes and new ones), its own script types
/// (on the process's script surfaces while it is enabled) and a run listener (it hears every
/// run's lifecycle). The service records what each plugin added, so the plugin host's unload
/// takes it all out again, in reverse. A plugin's per-run state belongs to the runs themselves:
/// its run listener adds it to each run as the run is made.
class EnginePluginServices : IRegistrationRecorder
{
	/// A run listener added, and the run manager it joined.
	private struct ListenerRecord
	{
		public uint64 Token;
		/// OWNED: the listener, deleted as its plugin unloads.
		public IRunListener Listener;
		/// BORROWED: the manager it subscribed to, which outlives this service.
		public IRunManager Runs;
	}

	/// This service's token for a domain added, and the composition's for it.
	private List<uint64> mTokens = new .() ~ delete _;
	private List<uint64> mDomains = new .() ~ delete _;
	/// This service's token for a plugin's script types, and the plugin's id.
	private List<uint64> mScriptTokens = new .() ~ delete _;
	private List<String> mScriptPlugins = new .() ~ DeleteContainerAndItems!(_);
	/// The run listeners added, in the order they were.
	private List<ListenerRecord> mListeners = new .() ~ delete _;
	/// BORROWED: the live runs of the host last attached (its subsystems' run manager); null in
	/// a host without runs (a cook, a tool), where a run listener has nothing to hear.
	private IRunManager mRuns = null;
	/// The armed part's sink. BORROWED, the loader's; null while none loads.
	private List<uint64> mSink = null;
	private uint64 mNextToken = 1;

	/// Hands this service to `host`'s plugins and records what they add through it, and the
	/// scene managers they contribute. Before the host enables any; this outlives the host.
	public bool Attach(PluginHost host)
	{
		if (!host.Provide(this))
			return false;
		mRuns = (host.Subsystems != null) ? host.Subsystems.RunManager : null;
		host.Loader.AddRecorder(this);
		host.Loader.AddRecorder(SceneContributionRecorder.Global);
		return true;
	}

	/// Adds a domain to the composition (EngineComposition.AddPluginDomain). False, with nothing
	/// added, for a domain with scene content: scene managers come through AddSceneManager.
	/// `module` is BORROWED (the plugin's) and outlives its unload.
	public bool AddDomain(DomainModule module)
	{
		let domain = EngineComposition.AddPluginDomain(module);
		if (domain == 0)
			return false;
		let token = mNextToken++;
		mTokens.Add(token);
		mDomains.Add(domain);
		if (mSink != null)
			mSink.Add(token);
		return true;
	}

	/// Adds a scene manager to every live scene and every scene made after. The scene
	/// contribution recorder the host armed records it, and it is reversed with the rest.
	public void AddSceneManager(SceneModuleContribution contribution)
	{
		SceneModuleContributions.Global.Add(contribution);
	}

	/// Puts plugin `pluginId`'s own script types (what `populate` adds: the walk of its namespace)
	/// on every script surface this process binds against (ScriptSurfaces), each tagged with the
	/// plugin, so a script reaches them while the plugin is enabled and the cooks' surface hash
	/// moves with them; the recording takes them off again as the plugin unloads. False, logged,
	/// with nothing added, when a type is on a surface already (a leak: ScriptSurface.AddPluginTypes).
	public bool AddScriptTypes(StringView pluginId, function void(ScriptSurface surface) populate)
	{
		let surfaces = ScriptSurfaces.All;
		for (int i < surfaces.Length)
		{
			let types = scope ScriptSurface();
			populate(types);
			let why = scope String();
			if (!surfaces[i].AddPluginTypes(pluginId, types, why))
			{
				GlobalLog(.Error, "Plugins: {}", why);
				for (int undo < i)
					surfaces[undo].RemovePluginTypes(pluginId);
				return false;
			}
		}
		let token = mNextToken++;
		mScriptTokens.Add(token);
		mScriptPlugins.Add(new .(pluginId));
		if (mSink != null)
			mSink.Add(token);
		return true;
	}

	/// Subscribes `listener` to the live runs, TAKING OWNERSHIP of it, and catches it up: each run
	/// made already is announced to it as created, and as started when a session is under way.
	/// The unload unsubscribes and deletes it, so a listener that put something on the runs takes
	/// it off again as it is deleted. False, the listener deleted, in a host without runs.
	public bool AddRunListener(IRunListener listener)
	{
		if (listener == null)
			return false;
		if (mRuns == null)
		{
			delete (Object)listener;
			return false;
		}
		mRuns.Subscribe(listener);
		mRuns.ForEachRun(scope (run) =>
			{
				listener.OnRunCreated(run);
				if ((run.State == .Running) || (run.State == .Paused))
					listener.OnRunStarted(run);
			});
		ListenerRecord record;
		record.Token = mNextToken++;
		record.Listener = listener;
		record.Runs = mRuns;
		mListeners.Add(record);
		if (mSink != null)
			mSink.Add(record.Token);
		return true;
	}

	/// The first run listener added that is a `T`, or null. BORROWED.
	public T FindRunListener<T>() where T : class
	{
		for (let record in mListeners)
		{
			if (let found = (Object)record.Listener as T)
				return found;
		}
		return null;
	}

	/// What no unload took out goes with the service: the run manager outlives it.
	public ~this()
	{
		for (int i = mListeners.Count - 1; i >= 0; i--)
			RemoveListener(i);
	}

	/// Armed around each part's load, so what it added is recorded against it.
	public override void Arm(List<uint64> sink) => mSink = sink;
	public override void Disarm() => mSink = null;

	public override void Reverse(uint64 id)
	{
		for (int i < mListeners.Count)
		{
			if (mListeners[i].Token == id)
			{
				RemoveListener(i);
				return;
			}
		}
		let script = mScriptTokens.IndexOf(id);
		if (script >= 0)
		{
			for (let surface in ScriptSurfaces.All)
				surface.RemovePluginTypes(mScriptPlugins[script]);
			mScriptTokens.RemoveAt(script);
			delete mScriptPlugins[script];
			mScriptPlugins.RemoveAt(script);
			return;
		}
		let index = mTokens.IndexOf(id);
		if (index < 0)
			return;
		let domain = mDomains[index];
		mTokens.RemoveAt(index);
		mDomains.RemoveAt(index);
		EngineComposition.RemovePluginDomain(domain);
	}

	/// Unsubscribes and deletes listener `index`.
	private void RemoveListener(int index)
	{
		let record = mListeners[index];
		mListeners.RemoveAt(index);
		record.Runs.Unsubscribe(record.Listener);
		delete (Object)record.Listener;
	}
}
