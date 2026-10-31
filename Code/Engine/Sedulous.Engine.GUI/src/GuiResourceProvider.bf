using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Image;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Texture.Resource;
using Sedulous.VG.Resource;
using Sedulous.VG.SVG;

namespace Sedulous.Engine.GUI;

/// The GUI's resources by asset guid ("{guid}" or the bare guid), as every other reference in the
/// engine, through the application's resource manager: a document's markup and a sheet's CSS
/// from their cooked products, an SVG from a vector image, an image from a texture (a render
/// texture a camera draws into among them). The markup, the sheets and the gamekit need no
/// change: they ask by string, as they do in the sandbox.
///
/// A guid is bound only as what it was cooked as: a handle bound as another product caches its
/// failure, and the manager keeps one handle per guid.
class GuiResourceProvider : IResourceProvider
{
	/// Told when an image key starts or stops standing for a texture (`view` null: it stops):
	/// the renderers that draw the GUI. The key and the view are borrowed.
	public typealias TextureSink = delegate void(ImageData key, ITextureView view);

	/// A document or a sheet read: its binding, and the product it last answered with.
	private class Text
	{
		public Guid Id;
		/// STORED, so retained; forgotten when the entry goes.
		public Proxy<Object> Handle;
		/// Compared only: a replaced product is parked by the manager for frames, so a new one
		/// never takes its address between two polls of a frame.
		public Object Seen;
	}

	/// A vector image's picture, parsed from the product it last saw.
	private class Picture
	{
		public Guid Id;
		/// STORED, so retained; forgotten when the entry goes.
		public Proxy<VectorImage> Image;
		/// Compared only, as Text.Seen is.
		public Object Seen;
		/// OWNED until it is retired; null when the product did not parse, or there is none.
		public SVGDocument Document;
	}

	/// A texture's image key.
	private class TextureImage
	{
		public Guid Id;
		/// STORED, so retained; forgotten when the entry goes.
		public Proxy<Texture> Texture;
		/// OWNED until it is retired; null until the texture has loaded.
		public ImageDataRef Key;
		/// The texture product the key stands for; nought for none (yet).
		public uint64 Uid;
	}

	/// BORROWED; null between projects, which resolves nothing.
	private ResourceManager mResources = null;
	private List<Text> mTexts = new .() ~ delete _;
	private List<Picture> mPictures = new .() ~ delete _;
	private List<TextureImage> mImages = new .() ~ delete _;
	/// A texture an image asked for has arrived (TakeImagesArrived).
	private bool mImagesArrived = false;
	/// Keys no texture backs now, kept for the views that may hold them. OWNED.
	private List<ImageDataRef> mRetired = new .() ~ DeleteContainerAndItems!(_);
	/// Pictures replaced, kept for the widgets that may hold them. OWNED.
	private List<SVGDocument> mRetiredPictures = new .() ~ DeleteContainerAndItems!(_);
	/// OWNED; null tells no one.
	private TextureSink mSink = null ~ delete _;

	public ~this()
	{
		ForgetAll();
	}

	/// The guid `path` names ("{guid}" or bare); false when it names none.
	public static bool ParseGuid(StringView path, out Guid id)
	{
		var text = path;
		if ((text.Length == 38) && (text[0] == '{') && (text[37] == '}'))
			text = text.Substring(1, 36);
		id = default;
		if (!(Guid.Parse(text) case .Ok(out id)))
			return false;
		return !id.IsNil;
	}

	/// Where the guids resolve; null (between projects) resolves nothing. Another manager lets
	/// go of what was bound: an image key stays valid for what holds it and stops showing.
	/// Borrowed.
	public void SetResourceManager(ResourceManager resources)
	{
		if (resources == mResources)
			return;
		mResources = resources;
		for (let entry in mImages)
		{
			if (entry.Key != null)
			{
				Tell(entry.Key, null);
				mRetired.Add(entry.Key);
				entry.Key = null;
			}
		}
		for (let entry in mPictures)
		{
			if (entry.Document != null)
			{
				mRetiredPictures.Add(entry.Document);
				entry.Document = null;
			}
		}
		ForgetAll();
	}

	public ResourceManager GetResourceManager() => mResources;

	/// The renderers' sink, OWNED from here on (null: none); told at once of every key that
	/// stands for a texture now.
	public void SetTextureSink(TextureSink sink)
	{
		delete mSink;
		mSink = sink;
		for (let entry in mImages)
		{
			if ((entry.Key != null) && (entry.Uid != 0))
			{
				let texture = entry.Texture.Get;
				Tell(entry.Key, (texture != null) ? texture.View : null);
			}
		}
	}

	/// A texture's image: one key per texture, its natural size the texture's. Borrowed, kept
	/// for the provider's life.
	public override ImageData LoadImage(StringView path)
	{
		if (!ParseGuid(path, let id))
			return null;
		TextureImage entry = null;
		for (let known in mImages)
		{
			if (known.Id == id)
				entry = known;
		}
		if (entry == null)
		{
			let instance = InstanceOf(id);
			// Not a texture. The texture records are several cooked types, so what is refused is
			// what is known to be something else.
			if ((instance == null) || IsCookedAs(instance, typeof(VectorImageResource))
				|| IsCookedAs(instance, typeof(GuiDocumentSource)) || IsCookedAs(instance, typeof(GuiStyleSheetSource)))
				return null;
			entry = new TextureImage();
			entry.Id = id;
			entry.Texture = mResources.Bind<Texture>(id);
			entry.Texture.Retain();
			mImages.Add(entry);
		}
		Refresh(entry);
		return (entry.Uid != 0) ? entry.Key : null;
	}

	/// A document's markup or a sheet's CSS, appended to `outText`.
	public override bool LoadText(StringView path, String outText)
	{
		if (!ParseGuid(path, let id))
			return false;
		Text entry = null;
		for (let known in mTexts)
		{
			if (known.Id == id)
				entry = known;
		}
		if (entry == null)
		{
			let instance = InstanceOf(id);
			if (instance == null)
				return false;
			uint64 productType;
			if (IsCookedAs(instance, typeof(GuiDocumentSource)))
				productType = ResourceManager.ProductTypeIdOf<GuiDocument>();
			else if (IsCookedAs(instance, typeof(GuiStyleSheetSource)))
				productType = ResourceManager.ProductTypeIdOf<GuiStyleSheet>();
			else
				return false;
			entry = new Text();
			entry.Id = id;
			entry.Handle = .(mResources.BindHandle(productType, id));
			entry.Handle.Retain();
			mTexts.Add(entry);
		}
		let product = entry.Handle.Get;
		entry.Seen = product;
		if (let document = product as GuiDocument)
		{
			outText.Append(document.Markup);
			return true;
		}
		if (let sheet = product as GuiStyleSheet)
		{
			outText.Append(sheet.Css);
			return true;
		}
		return false;
	}

	/// A vector image's picture, parsed once per product. Borrowed, kept for the provider's
	/// life.
	public override SVGDocument LoadSvg(StringView path)
	{
		if (!ParseGuid(path, let id))
			return null;
		Picture entry = null;
		for (let known in mPictures)
		{
			if (known.Id == id)
				entry = known;
		}
		if (entry == null)
		{
			let instance = InstanceOf(id);
			if ((instance == null) || !IsCookedAs(instance, typeof(VectorImageResource)))
				return null;
			entry = new Picture();
			entry.Id = id;
			entry.Image = mResources.Bind<VectorImage>(id);
			entry.Image.Retain();
			mPictures.Add(entry);
		}
		Refresh(entry);
		return entry.Document;
	}

	/// Brings what was read in line with the current products (a re-cook, a failed load): true
	/// when a document or a sheet read before has changed since the last poll.
	public bool Poll()
	{
		for (let entry in mImages)
			mImagesArrived = Refresh(entry) || mImagesArrived;
		for (let entry in mPictures)
			Refresh(entry);
		bool changed = false;
		for (let entry in mTexts)
			changed = changed || (entry.Handle.Get !== entry.Seen);
		return changed;
	}

	/// Whether `instance` was cooked as `cooked`: the cook names an instance's type by its full
	/// name.
	private static bool IsCookedAs(Instance instance, Type cooked)
	{
		return instance.TypeName == cooked.GetFullName(.. scope String());
	}

	private Instance InstanceOf(Guid id)
	{
		return (mResources != null) ? mResources.Database.GetInstance(id) : null;
	}

	private void Tell(ImageData key, ITextureView view)
	{
		if ((mSink != null) && (key != null))
			mSink(key, view);
	}

	/// Every binding let go, every entry gone; what an entry still owns goes with it (a key or
	/// a picture retired first is not its own any more).
	private void ForgetAll()
	{
		for (let entry in mImages)
		{
			entry.Texture.Forget();
			delete entry.Key;
			delete entry;
		}
		mImages.Clear();
		for (let entry in mPictures)
		{
			entry.Image.Forget();
			delete entry.Document;
			delete entry;
		}
		mPictures.Clear();
		for (let entry in mTexts)
		{
			entry.Handle.Forget();
			delete entry;
		}
		mTexts.Clear();
	}

	/// Whether a texture an image asked for has arrived since the last call (an image asked before
	/// it loaded got nothing, and asks again as it is laid out next).
	public bool TakeImagesArrived()
	{
		let arrived = mImagesArrived;
		mImagesArrived = false;
		return arrived;
	}

	/// An image's key in line with its texture's current product: true when the texture has just
	/// arrived (an image that had none has one now).
	private bool Refresh(TextureImage entry)
	{
		let texture = entry.Texture.Get;
		let uid = ((texture != null) && (texture.View != null)) ? texture.Uid : 0;
		if (uid == entry.Uid)
			return false;
		let arrived = (entry.Uid == 0) && (uid != 0);
		if ((uid != 0) && ((entry.Key == null) || (entry.Key.Width != texture.Width) || (entry.Key.Height != texture.Height)))
		{
			// A key's size is the image's natural size: another size takes a new key, the old one
			// kept for the views that hold it.
			if (entry.Key != null)
			{
				Tell(entry.Key, null);
				mRetired.Add(entry.Key);
			}
			entry.Key = new ImageDataRef(texture.Width, texture.Height);
		}
		entry.Uid = uid;
		Tell(entry.Key, (uid != 0) ? texture.View : null);
		return arrived;
	}

	/// A picture parsed again when its vector image's product changed.
	private void Refresh(Picture entry)
	{
		let product = entry.Image.Get;
		if (product === entry.Seen)
			return;
		entry.Seen = product;
		if (entry.Document != null)
		{
			mRetiredPictures.Add(entry.Document);
			entry.Document = null;
		}
		if (product == null)
			return;
		if (SVGLoader.Load(product.Svg) case .Ok(let parsed))
			entry.Document = parsed;
		else
			GlobalLog(.Warning, "GUI: vector image {} does not parse", entry.Id);
	}
}
