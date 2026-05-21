using System;
using Sedulous.Resources;

namespace Sedulous.Fonts.Resources;

/// Static helper for initializing baked-font support.
///
/// Constructs a `FontResourceManager` and registers it with the supplied
/// `ResourceSystem`, so `.font` resources can be loaded uniformly through
/// the resource system. Mirrors `TrueTypeFonts.Initialize()` in spirit -
/// both are "register this font format's plumbing at app startup" entry
/// points - but baked fonts live in the resource system rather than the
/// parser / baker factories (they're a serialized intermediate, not a
/// source format).
public static class BakedFonts
{
	private static FontResourceManager sManager = null;
	private static ResourceSystem sRegisteredWith = null;

	/// Register a `FontResourceManager` with the given resource system.
	/// Idempotent for the same system; calling with a different system
	/// after Initialize has already registered will leave the previous
	/// registration intact (call `Shutdown` first to re-target).
	public static void Initialize(ResourceSystem resourceSystem)
	{
		if (sManager != null || resourceSystem == null) return;

		sManager = new FontResourceManager();
		resourceSystem.AddResourceManager(sManager);
		sRegisteredWith = resourceSystem;
	}

	/// Unregister and dispose the manager. After this returns, `.font`
	/// resources won't load until Initialize is called again.
	public static void Shutdown()
	{
		if (sManager == null) return;

		if (sRegisteredWith != null)
			sRegisteredWith.RemoveResourceManager(sManager);
		delete sManager;
		sManager = null;
		sRegisteredWith = null;
	}

	/// The currently-registered manager (or null when Initialize hasn't run).
	/// Exposed for callers that want to tune options on the manager.
	public static FontResourceManager Manager => sManager;

	/// True once Initialize has registered the manager.
	public static bool IsInitialized => sManager != null;
}
