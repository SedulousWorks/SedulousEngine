using System;
using System.Collections;
using Sedulous.Model;

namespace Sedulous.Model.IO;

/// The set of registered loaders, and dispatch by file extension.
///
/// Loaders are NOT owned: a format library owns its own loader and registers it, which is
/// what lets the format be a separate module that Model.IO never names.
static class ModelLoaderRegistry
{
	private static List<IModelLoader> sLoaders = new .() ~ delete _;

	/// Registers a loader, ignoring one that is already registered so a module brought up
	/// twice does not get consulted twice.
	public static void Register(IModelLoader loader)
	{
		if (loader == null)
			return;
		for (let existing in sLoaders)
		{
			if (existing === loader)
				return;
		}
		sLoaders.Add(loader);
	}

	/// Removes a loader.
	///
	/// A loader lives in the library that registered it, so a host closing that library
	/// MUST take it back out first: left behind, the next load would call into unmapped
	/// memory.
	public static bool Unregister(IModelLoader loader)
	{
		for (int i < sLoaders.Count)
		{
			if (sLoaders[i] === loader)
			{
				sLoaders.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public static bool HasLoaders => !sLoaders.IsEmpty;
	public static int LoaderCount => sLoaders.Count;

	/// Forgets every loader. For tests, and for a host tearing everything down.
	public static void Clear() => sLoaders.Clear();

	/// Loads a model, picking the loader by the path's extension.
	///
	/// The FIRST loader that claims the extension wins, so a later registration can be
	/// consulted only when no earlier one handles the format.
	public static ModelLoadResult Load(StringView path, ModelData model)
	{
		// @extension because `extension` is a Beef keyword.
		let @extension = scope String();
		GetExtension(path, @extension);

		for (let loader in sLoaders)
		{
			if (loader.SupportsExtension(@extension))
				return loader.Load(path, model);
		}
		return .UnsupportedFormat;
	}

	/// The extension WITH its dot, or empty when there is none.
	///
	/// The scan stops at a separator, so a dot in a directory name is not mistaken for an
	/// extension on a file that has none.
	public static void GetExtension(StringView path, String outExtension)
	{
		for (int i = path.Length; i > 0; i--)
		{
			let c = path[i - 1];
			if (c == '.')
			{
				outExtension.Append(path.Substring(i - 1));
				return;
			}
			if ((c == '/') || (c == '\\'))
				break;
		}
	}
}
