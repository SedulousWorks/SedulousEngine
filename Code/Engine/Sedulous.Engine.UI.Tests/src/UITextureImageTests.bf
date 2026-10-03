using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.UI;
using Sedulous.Image;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Texture.Resource;
using Sedulous.UI;
using Sedulous.VFS;

namespace Sedulous.Engine.UI.Tests;

/// An image in game UI shows a texture asset, a render texture included: an ImageView's source
/// is the asset's id, resolved through the resource manager the application gives the UI.
class UITextureImageTests
{
	[Test]
	public static void AnImageViewsSourceNamesATextureAssetDrawnByEveryUIRenderer()
	{
		// DECLARED FIRST so it is freed LAST: the fixture's teardown releases through it.
		let device = scope NullDevice();
		let encoder = scope NullCommandEncoder();
		// The data root's shaders, so the UI has renderers to register on.
		let fixture = scope UITestFixture(false, true);
		fixture.UI.EnsureRenderReady(device, 2);

		// A cooked render texture in a content database, bound through a resource manager.
		let root = "scratch_ui_texture_images";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		let serializables = scope SerializableRegistry();
		TextureResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = scope ContentDatabase(mount, serializers, "asset", serializables);
		let instance = db.RootGroup.CreateInstance("minimap", "Sedulous.Texture.Resource.RenderTextureResource");
		{
			let record = scope RenderTextureResource();
			record.Width = 128;
			record.Height = 64;
			Test.Assert(instance.WriteObject(record) case .Ok);
		}
		let factory = scope TextureFactory(device);
		let resources = scope ResourceManager(db);
		resources.AddFactory(factory);
		defer fixture.UI.SetResourceManager(null);

		let provider = fixture.UI.UiContext.ResourceProvider;
		Test.Assert(provider != null);
		let id = instance.Id.ToString(.. scope .());
		Test.Assert(provider.LoadImage(id) == null, "no resource manager yet");

		fixture.UI.SetResourceManager(resources);
		let image = provider.LoadImage(id);
		Test.Assert(image != null);
		Test.Assert((image.Width == 128) && (image.Height == 64), "the texture's size: the view's natural size");
		Test.Assert(provider.LoadImage(scope $"{{{id}}}") === image, "one key per texture");
		Test.Assert(provider.LoadImage("not-a-guid") == null);

		// No shader compiler (the ASan run's DXC fails to load): nothing to draw with.
		if (!fixture.UI.CanRender)
			return;

		// An ImageView naming it in a drawn root: the key is registered on the renderer that
		// drew, and on a renderer of another format once that one draws too.
		let document = UITestFixture.MakeDocument("<ImageView id=\"map\"/>");
		defer delete document;
		let preview = fixture.UI.CreatePreview(document);
		Test.Assert(preview != null);
		defer { fixture.UI.DestroyPreview(preview); preview.ReleaseRef(); }
		let view = preview.FindByName("map") as ImageView;
		Test.Assert(view != null);
		view.SetSource(id);
		var targetTexture = device.CreateTexture(TextureDesc.RenderTarget(.RGBA8UnormSrgb, 256, 256)).Value;
		defer device.DestroyTexture(ref targetTexture);
		var target = device.CreateTextureView(targetTexture, .()).Value;
		defer device.DestroyTextureView(ref target);

		fixture.Frame();
		fixture.UI.RenderPreview(preview, encoder, target, .RGBA8UnormSrgb, 256, 256, 0);
		Test.Assert(view.Image === image);
		Test.Assert(fixture.UI.RenderersShowing(image) == 1);
		fixture.Frame();
		fixture.UI.RenderPreview(preview, encoder, target, .RGBA16Float, 256, 256, 1);
		Test.Assert(fixture.UI.RenderersShowing(image) == 2);

		// Another project (or none): the key stays valid for the view that holds it, but
		// nothing backs it, and the renderers drop it as they next draw.
		fixture.UI.SetResourceManager(null);
		Test.Assert(provider.LoadImage(id) == null);
		fixture.Frame();
		fixture.UI.RenderPreview(preview, encoder, target, .RGBA8UnormSrgb, 256, 256, 0);
		Test.Assert(fixture.UI.RenderersShowing(image) == 1, "dropped by the one that drew, not yet the other");
	}
}
