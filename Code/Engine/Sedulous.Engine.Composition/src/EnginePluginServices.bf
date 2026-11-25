using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Scene;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Run;

namespace Sedulous.Engine.Composition;

/// What a plugin's Engine part adds to the engine, through the service its host provides
/// (PluginContext.Find<EnginePluginServices>): a domain (its resource modules join the
/// composition), a scene manager (it reaches live scenes and new ones), a run service (its per-run
/// state, in every live run and every run made after) and its own script types (on the process's
/// script surfaces while it is enabled). The service records what each plugin added, so the plugin
/// host's unload takes it all out again, in reverse.
class EnginePluginServices : IRegistrationRecorder
{
	/// This service's token for a domain added, and the composition's for it.
	private List<uint64> mTokens = new .() ~ delete _;
	private List<uint64> mDomains = new .() ~ delete _;
	/// This service's token for a plugin's script types, and the plugin's id.
	private List<uint64> mScriptTokens = new .() ~ delete _;
	private List<String> mScriptPlugins = new .() ~ DeleteContainerAndItems!(_);
	/// This service's token for a run service added, and the run contributions' for it.
	private List<uint64> mRunTokens = new .() ~ delete _;
	private List<uint64> mRunServices = new .() ~ delete _;
	/// The armed part's sink. BORROWED, the loader's; null while none loads.
	private List<uint64> mSink = null;
	private uint64 mNextToken = 1;

	/// Hands this service to `host`'s plugins and records what they add through it, and the
	/// scene managers they contribute. Before the host enables any; this outlives the host.
	public bool Attach(PluginHost host)
	{
		if (!host.Provide(this))
			return false;
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

	/// Adds a service to every live run and every run made after (the plugin's per-run state); taken
	/// out of each run as the plugin unloads. False, with nothing added, for one with no type or no
	/// install.
	public bool AddRunService(RunServiceContribution contribution)
	{
		let service = RunServiceContributions.Global.Add(contribution);
		if (service == 0)
			return false;
		let token = mNextToken++;
		mRunTokens.Add(token);
		mRunServices.Add(service);
		if (mSink != null)
			mSink.Add(token);
		return true;
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

	/// Armed around each part's load, so what it added is recorded against it.
	public override void Arm(List<uint64> sink) => mSink = sink;
	public override void Disarm() => mSink = null;

	public override void Reverse(uint64 id)
	{
		let run = mRunTokens.IndexOf(id);
		if (run >= 0)
		{
			RunServiceContributions.Global.Remove(mRunServices[run]);
			mRunTokens.RemoveAt(run);
			mRunServices.RemoveAt(run);
			return;
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
}
