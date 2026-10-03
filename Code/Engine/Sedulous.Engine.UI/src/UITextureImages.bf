using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Resource;
using Sedulous.Texture.Resource;
using Sedulous.UI;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// The game UI's resource provider: an image source is a texture asset id ("{guid}" or the
/// bare guid), a render texture included. A texture gets ONE key for the subsystem's life (an
/// ImageView keeps the image it was given), and the key is registered on every VG renderer:
/// the renderers are per format, and a texture registered on one is invisible to the others.
class UITextureImages : IResourceProvider
{
	private class Entry
	{
		public Guid Id;
		/// STORED, so retained; forgotten when the entry goes.
		public Proxy<Texture> Texture;
		/// OWNED by the provider; null until the texture has loaded.
		public ImageDataRef Key;
		/// The texture product the key stands for; nought for none yet.
		public uint64 Uid;
	}

	/// BORROWED; null between projects, which resolves nothing.
	private ResourceManager mResources = null;
	private List<Entry> mEntries = new .() ~ delete _;
	/// Keys no texture backs now, kept alive for the views that may still hold them. OWNED.
	private List<ImageDataRef> mRetired = new .() ~ DeleteContainerAndItems!(_);
	/// Bumps whenever what a key stands for changes.
	private uint64 mGeneration = 1;
	private uint64 mPolledSerial = 0;
	/// Per renderer: the generation it was last brought in line with. The renderers are
	/// BORROWED keys, compared only.
	private Dictionary<VGRenderer, uint64> mSynced = new .() ~ delete _;

	public ~this()
	{
		for (let entry in mEntries)
		{
			entry.Texture.Forget();
			delete entry.Key;
			delete entry;
		}
	}

	public bool LoadText(StringView path, String outText) => false;

	public ImageData LoadImage(StringView path)
	{
		var text = path;
		if ((text.Length == 38) && (text[0] == '{') && (text[37] == '}'))
			text = text.Substring(1, 36);
		Guid id;
		if (!(Guid.Parse(text) case .Ok(out id)) || id.IsNil)
			return null;
		var entry = Find(id);
		if (entry == null)
		{
			if (mResources == null)
				return null;
			entry = new Entry();
			entry.Id = id;
			entry.Texture = mResources.Bind<Texture>(id);
			entry.Texture.Retain();
			mEntries.Add(entry);
		}
		Refresh(entry);
		return (entry.Uid != 0) ? entry.Key : null;
	}

	/// A new resource manager (another project, or none): what was bound goes, while every
	/// key stays alive (views may still hold them) and stops showing anything.
	public void Reset(ResourceManager resources)
	{
		if (resources == mResources)
			return;
		mResources = resources;
		for (let entry in mEntries)
		{
			entry.Texture.Forget();
			if (entry.Key != null)
				mRetired.Add(entry.Key);
			delete entry;
		}
		mEntries.Clear();
		mGeneration++;
	}

	/// Brings `renderer` in line before it draws: every key registered, the ones whose
	/// texture is gone dropped. Once per change, not per frame, since a registration rebuilds
	/// bind groups.
	public void SyncOn(VGRenderer renderer, uint64 frameSerial)
	{
		if (mPolledSerial != frameSerial)
		{
			mPolledSerial = frameSerial;
			for (let entry in mEntries)
				Refresh(entry); // a reload, a failed load
		}
		if (mSynced.TryGetValue(renderer, let synced) && (synced == mGeneration))
			return;
		for (let key in mRetired)
			renderer.UnregisterExternalTexture(key);
		for (let entry in mEntries)
		{
			if (entry.Key == null)
				continue;
			let texture = entry.Texture.Get;
			if ((entry.Uid != 0) && (texture != null))
				renderer.RegisterExternalTexture(entry.Key, texture.View);
			else
				renderer.UnregisterExternalTexture(entry.Key);
		}
		mSynced[renderer] = mGeneration;
	}

	private Entry Find(Guid id)
	{
		for (let entry in mEntries)
		{
			if (entry.Id == id)
				return entry;
		}
		return null;
	}

	/// Brings a key in line with its texture's current product.
	private void Refresh(Entry entry)
	{
		let texture = entry.Texture.Get;
		let uid = ((texture != null) && (texture.View != null)) ? texture.Uid : 0;
		if (uid == entry.Uid)
			return;
		if ((texture != null) && (uid != 0)
			&& ((entry.Key == null) || (entry.Key.Width != texture.Width) || (entry.Key.Height != texture.Height)))
		{
			// A key's size is the image's natural size; a reload at another size gets a new
			// key (views resolving afresh find it), the old one kept for views that hold it.
			if (entry.Key != null)
				mRetired.Add(entry.Key);
			entry.Key = new ImageDataRef(texture.Width, texture.Height);
		}
		entry.Uid = uid;
		mGeneration++;
	}
}
