using System;
using Sedulous.Scene;

namespace Sedulous.Scripting;

/// What a thunk reaches beyond its arguments: the scene a scene bound call resolves its
/// systems and components in, the engine services, and storage for a struct result.
///
/// A backend supplies one; a test supplies a scratch one.
abstract class ScriptCallContext
{
	/// BORROWED. Null in a host with no scene, and every scene bound call then fails.
	public Scene Scene = null;

	/// An engine level service by type: a subsystem, or anything else a host registers.
	/// Null when the host has none of that type.
	public abstract Object FindService(Type type);

	/// Storage for a struct result, owned by the VM side and valid at least until the
	/// call returns to it. A VM makes this its own value cell; a test frees it after.
	public abstract void* AllocStruct(Type type, int size, int align);
}
