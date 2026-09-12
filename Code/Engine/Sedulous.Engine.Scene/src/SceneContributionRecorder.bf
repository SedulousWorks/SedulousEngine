using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Scene;

/// Records the scene managers a plugin contributes, so unloading it takes them back out.
///
/// Runtime cannot name Scene, so it takes a recorder instead of reaching for the
/// contribution registry itself. The host arms this around one plugin's OnLoad, every
/// contribution registered in that window lands in the sink, and each id comes back to
/// Reverse on unload. Without it a plugin would leave managers behind in live scenes while
/// the code that built them is being unmapped.
class SceneContributionRecorder : IRegistrationRecorder
{
	/// One per process, because the registry it observes is process wide for the same
	/// reason: a plugin loading has to reach the one list every scene consults.
	private static SceneContributionRecorder sGlobal = new .() ~ delete _;

	/// The registry BORROWS what it is handed, so the delegate is this recorder's to free.
	/// Arm and Disarm bracket one OnLoad and never nest, so one field is enough.
	private delegate void(uint64) mObserver ~ delete _;

	public static SceneContributionRecorder Global => sGlobal;

	public override void Arm(List<uint64> sink)
	{
		delete mObserver;
		mObserver = new (id) => sink.Add(id);
		SceneModuleContributions.Global.SetRegistrationObserver(mObserver);
	}

	public override void Disarm()
	{
		SceneModuleContributions.Global.SetRegistrationObserver(null);
		DeleteAndNullify!(mObserver);
	}

	public override void Reverse(uint64 id)
	{
		SceneModuleContributions.Global.Remove(id);
	}
}
