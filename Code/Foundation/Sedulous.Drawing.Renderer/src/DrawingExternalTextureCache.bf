namespace Sedulous.Drawing.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Images;
using Sedulous.Core;

/// Shared cache of external GPU textures that can be used in 2D drawing.
/// Created by the application and passed to all DrawingRenderers.
/// DrawingRenderers lazily pick up external textures during rendering.
public class DrawingExternalTextureCache
{
	public struct ExternalEntry
	{
		public ITextureView TextureView;
		public int32 Version;
		public bool IsReady;
	}

	private Dictionary<ObjectKey<IImageData>, ExternalEntry> mEntries = new .() ~ delete _;
	private int32 mNextVersion = 1;

	/// Register an external GPU texture for an IImageData reference.
	/// Starts as not ready — call MarkReady after the texture is rendered to.
	public void Register(IImageData imageRef, ITextureView textureView)
	{
		if (imageRef == null || textureView == null) return;

		let key = ObjectKey<IImageData>(imageRef);
		if (mEntries.TryGetValue(key, var entry))
		{
			entry.TextureView = textureView;
			entry.Version = mNextVersion++;
			entry.IsReady = false;
			mEntries[key] = entry;
		}
		else
		{
			ExternalEntry newEntry;
			newEntry.TextureView = textureView;
			newEntry.Version = mNextVersion++;
			newEntry.IsReady = false;
			mEntries[key] = newEntry;
		}
	}

	/// Mark a texture as ready (rendered to, in ShaderRead state).
	public void MarkReady(IImageData imageRef)
	{
		if (imageRef == null) return;
		let key = ObjectKey<IImageData>(imageRef);
		if (mEntries.TryGetValue(key, var entry))
		{
			entry.IsReady = true;
			mEntries[key] = entry;
		}
	}

	/// Unregister an external texture.
	public void Unregister(IImageData imageRef)
	{
		if (imageRef == null) return;
		let key = ObjectKey<IImageData>(imageRef);
		mEntries.Remove(key);
	}

	/// Try to find an external texture for the given IImageData.
	public bool TryGet(IImageData imageRef, out ExternalEntry entry)
	{
		return mEntries.TryGetValue(.(imageRef), out entry);
	}
}
