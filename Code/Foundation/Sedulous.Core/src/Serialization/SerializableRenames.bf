using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Serializable types that moved or were renamed. A type's stored identity is its qualified
/// name (TypeIdOf), so a move is a format change: without a rename, what was saved before it
/// is refused by the version envelope and unknown to a registry keyed by name. Registered
/// once at startup, before anything loads; read from any thread after that.
static class SerializableRenames
{
	/// Former id to current id. Lazy, since static initialisation order is not guaranteed.
	private static Dictionary<uint64, uint64> sIds = null ~ delete _;
	/// Former qualified name to current, for stores that key by name (a settings file).
	private static Dictionary<String, String> sNames = null ~ { if (_ != null) DeleteDictionaryAndKeysAndValues!(_); };

	/// `formerName` is what `currentName` was called when data was saved under it.
	public static void Register(StringView formerName, StringView currentName)
	{
		if (sIds == null)
			sIds = new .();
		if (sNames == null)
			sNames = new .();
		sIds[TypeIdOf(formerName)] = TypeIdOf(currentName);
		if (sNames.GetAndRemove(scope String(formerName)) case .Ok(let previous))
		{
			delete previous.key;
			delete previous.value;
		}
		sNames[new String(formerName)] = new String(currentName);
	}

	/// Whether a stored `storedId` is a former identity of `currentId`.
	public static bool IsFormerId(uint64 storedId, uint64 currentId)
	{
		uint64 renamed = 0;
		return (sIds != null) && sIds.TryGetValue(storedId, out renamed) && (renamed == currentId);
	}

	/// The current name of a type stored as `name`; false when it was never renamed.
	public static bool TryCurrentName(StringView name, String outCurrent)
	{
		String current = null;
		if ((sNames == null) || !sNames.TryGetValue(scope String(name), out current))
			return false;
		outCurrent.Set(current);
		return true;
	}
}
