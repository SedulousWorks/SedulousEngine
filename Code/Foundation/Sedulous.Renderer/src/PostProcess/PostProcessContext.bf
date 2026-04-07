namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RenderGraph;

/// Context passed to each post-process effect during AddPasses.
/// Provides input/output handles and auxiliary texture communication between effects.
class PostProcessContext
{
	/// Current input texture handle (scene HDR or previous effect's output).
	public RGHandle Input;

	/// Where this effect should write its result.
	public RGHandle Output;

	/// Scene depth (read-only, for depth-aware effects like DoF, fog, SSAO).
	public RGHandle SceneDepth;

	/// Auxiliary textures produced by earlier effects (e.g., "BloomTexture").
	private Dictionary<String, RGHandle> mAuxTextures = new .() ~ DeleteDictionaryAndKeys!(_);

	/// Registers an auxiliary texture that downstream effects can read.
	public void SetAux(StringView name, RGHandle handle)
	{
		let key = new String(name);
		if (mAuxTextures.TryAdd(key, handle))
			return;
		// Key already exists — update value, delete the new key
		delete key;
		mAuxTextures[scope String(name)] = handle;
	}

	/// Gets an auxiliary texture by name. Returns invalid handle if not found.
	public RGHandle GetAux(StringView name)
	{
		RGHandle handle;
		if (mAuxTextures.TryGetValue(scope String(name), out handle))
			return handle;
		return .Invalid;
	}

	/// Clears all state for reuse.
	public void Clear()
	{
		Input = .Invalid;
		Output = .Invalid;
		SceneDepth = .Invalid;
		DeleteDictionaryAndKeys!(mAuxTextures);
		mAuxTextures = new .();
	}
}
