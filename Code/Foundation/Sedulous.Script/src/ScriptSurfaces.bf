using System;
using System.Collections;

namespace Sedulous.Script;

/// The script surfaces this process binds and checks scripts against (an application's runtime
/// surface, the pipeline's cook surface): where a plugin's Engine part puts its own types while
/// the plugin is enabled. A surface registers as it is populated and leaves as it goes; a scratch
/// surface (a test's, a describing host's copy) is not one of them.
static class ScriptSurfaces
{
	private static List<ScriptSurface> sSurfaces ~ delete _;

	/// BORROWED; it must Unregister before it goes.
	public static void Register(ScriptSurface surface)
	{
		if (surface == null)
			return;
		if (sSurfaces == null)
			sSurfaces = new .();
		if (!sSurfaces.Contains(surface))
			sSurfaces.Add(surface);
	}

	public static void Unregister(ScriptSurface surface)
	{
		if (sSurfaces != null)
			sSurfaces.Remove(surface);
	}

	public static Span<ScriptSurface> All => (sSurfaces != null) ? (Span<ScriptSurface>)sSurfaces : .();
}
