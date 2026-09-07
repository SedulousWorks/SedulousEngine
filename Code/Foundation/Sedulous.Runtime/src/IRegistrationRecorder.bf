using System;
using System.Collections;

namespace Sedulous.Runtime;

/// A registry that wants a plugin's additions recorded and reversed along with the rest.
///
/// The two things the host reverses on its own are the serializable factories and the
/// plugin's own subsystems. Everything ELSE a plugin can register lives in a layer above
/// Runtime, which Runtime must not name: a scene manager's contributions are the case this
/// exists for, and Runtime cannot depend on Scene.
///
/// So the layer supplies a recorder instead. Armed around OnLoad, it reports what was
/// added into the sink; on unload the host hands each id back to Reverse. That way one
/// unload reverses everything the plugin did, and no layer has to hook the host's teardown.
///
/// Arm and Disarm bracket ONE plugin's OnLoad and never nest, because the host loads
/// plugins one at a time.
abstract class IRegistrationRecorder
{
	/// Starts recording into the sink, which the host owns and keeps for this plugin.
	///
	/// Only REAL additions belong in it: a registration another party already owned is not
	/// this plugin's to reverse, and reversing it would tear out something still in use.
	public abstract void Arm(List<uint64> sink);

	/// Stops recording. Always called, including when OnLoad failed.
	public abstract void Disarm();

	/// Undoes one recorded registration.
	public abstract void Reverse(uint64 id);
}
