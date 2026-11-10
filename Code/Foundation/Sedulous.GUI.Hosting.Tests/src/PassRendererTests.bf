using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.VG.SVG;

namespace Sedulous.GUI.Hosting.Tests;

/// GuiPassRenderer on the Null RHI backend: a root
/// drawn into a pass its caller opened, at a region of the target; a renderer per kind of pass,
/// rewound once a frame so a frame's roots keep their slices; the bakes recorded once a frame and
/// learned by renderers made later, as the images registered by key are.
class PassRendererTests
{
	/// A Null device, the two VG shaders, a pass renderer on them, a colour target the caller's pass
	/// draws into, and roots showing a red box.
	private class Bed
	{
		public NullRhiBed Rhi = new .();
		public GuiPassRenderer Renderer;
		public ITexture Target;
		public ITextureView View;
		public GUIContext Context = new .();

		public this()
		{
			Renderer = new .(Rhi.Device, 2, null, Rhi.Shaders);
			Target = Rhi.Device.CreateTexture(TextureDesc.RenderTarget(.BGRA8Unorm, 640, 360)).Value;
			View = Rhi.Device.CreateTextureView(Target, .()).Value;
		}

		public ~this()
		{
			delete Renderer;
			Rhi.Device.DestroyTextureView(ref View);
			Rhi.Device.DestroyTexture(ref Target);
			Context.ReleaseRef();
			delete Rhi;
		}

		/// A root the caller releases.
		public SceneRoot MakeRoot()
		{
			let root = new SceneRoot(Context);
			root.ViewportSize = .(320.0f, 180.0f);
			let @box = new Panel();
			@box.Size = .(40.0f, 20.0f);
			let look = scope NodeBox();
			look.BackgroundColor = .(1.0f, 0.0f, 0.0f, 1.0f);
			@box.SetBox(look);
			root.AddChild(@box);
			@box.ReleaseRef(); // the root holds it
			return root;
		}

		/// The caller's pass on its target, as an engine's overlay pass is: already open, loading
		/// what the frame drew before.
		public void InPass(ICommandEncoder encoder, delegate void(IRenderPassEncoder pass) draw)
		{
			var color = ColorAttachment();
			color.View = View;
			color.LoadOp = .Load;
			color.StoreOp = .Store;
			var pass = RenderPassDesc();
			pass.ColorAttachments.Add(color);
			let passEncoder = encoder.BeginRenderPass(pass);
			Test.Assert(passEncoder != null);
			draw(passEncoder);
			passEncoder.End();
		}
	}

	private static GuiPassView ViewOf(uint32 frame, TextureFormat format = .BGRA8Unorm, bool encoded = false)
	{
		var view = GuiPassView();
		view.X = 320; // the right half of the target, a split screen's second view
		view.Y = 0;
		view.Width = 320;
		view.Height = 180;
		view.Format = format;
		view.Encoded = encoded;
		view.FrameIndex = frame;
		return view;
	}

	[Test]
	public static void ARootIsDrawnIntoAPassItsCallerOpenedAtTheViewsRegion()
	{
		let bed = scope Bed();
		Test.Assert(bed.Renderer.IsUsable);
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		bed.Renderer.BeginFrame();
		let encoder = bed.Rhi.Encoder();
		let prepared = bed.Renderer.Prepare(root, ViewOf(0), encoder);
		Test.Assert(prepared.Renderer != null);
		Test.Assert(prepared.Slice.IsValid);
		Test.Assert(prepared.Slice.DrawCommandCount > 0);
		Test.Assert(prepared.View.X == 320);
		bed.InPass(encoder, scope (pass) => { bed.Renderer.Draw(pass, prepared); });
		bed.Rhi.Done(encoder);
		Test.Assert(bed.Renderer.RendererCount == 1);

		// Nothing to draw into: an empty region.
		var empty = ViewOf(0);
		empty.Width = 0;
		Test.Assert(bed.Renderer.Prepare(root, empty).Renderer == null);
	}

	[Test]
	public static void ARendererPerKindOfPassRewoundOnceAFrameSoAFramesRootsKeepTheirSlices()
	{
		let bed = scope Bed();
		let first = bed.MakeRoot();
		defer first.ReleaseRef();
		let second = bed.MakeRoot();
		defer second.ReleaseRef();
		bed.Renderer.BeginFrame();
		let encoder = bed.Rhi.Encoder();
		let a = bed.Renderer.Prepare(first, ViewOf(0));
		let b = bed.Renderer.Prepare(second, ViewOf(0));
		Test.Assert(a.Renderer != null);
		Test.Assert(a.Renderer == b.Renderer); // the same kind of pass: one renderer
		Test.Assert(b.Slice.DrawCommandStart >= a.Slice.DrawCommandStart + a.Slice.DrawCommandCount); // the first's draws kept
		Test.Assert(b.Slice.UniformByteOffset > a.Slice.UniformByteOffset);
		bed.InPass(encoder, scope (pass) =>
			{
				bed.Renderer.Draw(pass, a);
				bed.Renderer.Draw(pass, b);
			});
		bed.Rhi.Done(encoder);

		// Another kind of pass (the screen's, encoded, on an sRGB target's UNORM view): another
		// renderer.
		let c = bed.Renderer.Prepare(first, ViewOf(0, .BGRA8Unorm, true));
		Test.Assert(c.Renderer != null);
		Test.Assert(c.Renderer != a.Renderer);
		Test.Assert(bed.Renderer.RendererCount == 2);

		// The next frame rewinds each renderer once: the first root's draws start over.
		bed.Renderer.BeginFrame();
		let again = bed.Renderer.Prepare(first, ViewOf(1));
		Test.Assert(again.Renderer == a.Renderer);
		Test.Assert(again.Slice.DrawCommandStart == 0);
	}

	[Test]
	public static void TheBakesRecordOnceAFrameAndARendererMadeLaterLearnsThemAndTheRegisteredImages()
	{
		let bed = scope Bed();
		let baker = bed.Renderer.Baker;
		Test.Assert(baker != null);
		let root = bed.MakeRoot();
		defer root.ReleaseRef();

		// The first kind of pass, then a picture asked for and baked on the frame's encoder.
		bed.Renderer.BeginFrame();
		bed.Renderer.Prepare(root, ViewOf(0));
		let document = HostingFixtures.LoadPicture(HostingFixtures.cSquarePicture);
		defer delete document;
		Test.Assert(baker.Baked(document, 16, 16) == null); // queued
		var encoder = bed.Rhi.Encoder();
		Test.Assert(bed.Renderer.RecordBakes(encoder, 0));
		Test.Assert(!bed.Renderer.RecordBakes(encoder, 0)); // once a frame
		bed.Rhi.Done(encoder);
		let key = baker.Baked(document, 16, 16);
		Test.Assert(key != null);
		Test.Assert(bed.Renderer.FindRenderer(ViewOf(0)).IsExternalTextureRegistered(key));

		// An image the caller's provider answers by key, sampled from a texture of its own.
		let picture = scope ImageDataRef(4, 4);
		bed.Renderer.RegisterTexture(picture, bed.View);
		Test.Assert(bed.Renderer.FindRenderer(ViewOf(0)).IsExternalTextureRegistered(picture));

		// A renderer made after both learns both.
		let encoded = ViewOf(0, .RGBA8Unorm, true);
		bed.Renderer.Prepare(root, encoded);
		let later = bed.Renderer.FindRenderer(encoded);
		Test.Assert(later != null);
		Test.Assert(later.IsExternalTextureRegistered(key));
		Test.Assert(later.IsExternalTextureRegistered(picture));

		// Let go: every renderer forgets the image.
		bed.Renderer.UnregisterTexture(picture);
		Test.Assert(!later.IsExternalTextureRegistered(picture));
		Test.Assert(!bed.Renderer.FindRenderer(ViewOf(0)).IsExternalTextureRegistered(picture));

		// The next frame records again.
		bed.Renderer.BeginFrame();
		encoder = bed.Rhi.Encoder();
		bed.Renderer.RecordBakes(encoder, 1);
		Test.Assert(!bed.Renderer.RecordBakes(encoder, 1));
		bed.Rhi.Done(encoder);
	}

	[Test]
	public static void WithoutTheShadersEveryDrawNeedsNothingIsDrawnAndNothingBakes()
	{
		let rhi = scope NullRhiBed();
		let renderer = scope GuiPassRenderer(rhi.Device, 2, null, VgShaderSet());
		Test.Assert(!renderer.IsUsable);
		Test.Assert(renderer.Baker == null);
		let context = new GUIContext();
		defer context.ReleaseRef();
		let root = new SceneRoot(context);
		defer root.ReleaseRef();
		renderer.BeginFrame();
		Test.Assert(renderer.Prepare(root, ViewOf(0)).Renderer == null);
		Test.Assert(renderer.RendererCount == 0);
	}

	/// Added in the port: a pass with a depth-stencil attachment is a kind of its own, its
	/// renderer built for the stencil fills the plain pass's lacks.
	[Test]
	public static void APassWithADepthStencilAttachmentGetsARendererOfItsOwnThatFillsThroughTheStencil()
	{
		let bed = scope Bed();
		let root = bed.MakeRoot();
		defer root.ReleaseRef();
		let stencilFormat = VGRenderer.PickStencilCapableFormat(bed.Rhi.Device, 1);
		Test.Assert(stencilFormat != .Undefined); // the Null backend takes one
		var deep = ViewOf(0);
		deep.DepthStencilFormat = stencilFormat;
		bed.Renderer.BeginFrame();
		let plain = bed.Renderer.Prepare(root, ViewOf(0));
		let stenciled = bed.Renderer.Prepare(root, deep);
		Test.Assert(plain.Renderer != null);
		Test.Assert(stenciled.Renderer != null);
		Test.Assert(stenciled.Renderer != plain.Renderer);
		Test.Assert(stenciled.Renderer.StencilFillsSupported);
		Test.Assert(!plain.Renderer.StencilFillsSupported);
		Test.Assert(bed.Renderer.RendererCount == 2);
		Test.Assert(bed.Renderer.FindRenderer(deep) == stenciled.Renderer);
	}

	/// Two squares in one path: a fill that needs the stencil where there is one.
	private class TwoSquares : Panel
	{
		public override void OnDraw(DrawContext ctx, Rect localBounds)
		{
			base.OnDraw(ctx, localBounds);
			let builder = scope PathBuilder();
			for (int32 i < 2)
			{
				let x = 4.0f + 20.0f * (float)i;
				builder.MoveTo(x, 4.0f);
				builder.LineTo(x + 12.0f, 4.0f);
				builder.LineTo(x + 12.0f, 16.0f);
				builder.LineTo(x, 16.0f);
				builder.Close();
			}
			let path = builder.ToPath();
			defer delete path;
			ctx.VG.FillPath(path, .(1.0f, 1.0f, 1.0f, 1.0f));
		}
	}

	[Test]
	public static void APathFillGoesThroughTheStencilOnlyInAPassWithOne()
	{
		let bed = scope Bed();
		let root = new SceneRoot(bed.Context);
		defer root.ReleaseRef();
		root.ViewportSize = .(320.0f, 180.0f);
		let shape = new TwoSquares();
		shape.Size = .(40.0f, 20.0f);
		root.AddChild(shape);
		shape.ReleaseRef();
		var deep = ViewOf(0);
		deep.DepthStencilFormat = VGRenderer.PickStencilCapableFormat(bed.Rhi.Device, 1);
		bed.Renderer.BeginFrame();
		let plain = bed.Renderer.Prepare(root, ViewOf(0));
		let stenciled = bed.Renderer.Prepare(root, deep);
		Test.Assert(plain.Slice.DrawCommandCount > 0);
		// The stencil pass and its cover each a command of their own.
		Test.Assert(stenciled.Slice.DrawCommandCount > plain.Slice.DrawCommandCount);
	}
}
