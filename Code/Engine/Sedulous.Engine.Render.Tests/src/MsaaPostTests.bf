using System;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Engine.Render.Tests;

/// A project's MSAA reached the views through the samples' global post override, so a game with
/// MSAA on lost its scene's post processing (its profile's auto exposure, AO, SSR and TAA) in the
/// player, which sets the project's MSAA, and kept it in the editor, which does not.
class MsaaPostTests
{
	[Test]
	public static void TheHostsMsaaKeepsTheScenesPostSettings()
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return;
		let mount = scope NativeFileSystem(dataRoot);

		let backend = NullRhi.CreateBackend();
		defer { backend.Destroy(); delete backend; }
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		defer device.Destroy();

		let subsystem = scope RenderSubsystem(device, 2, mount);

		let scene = scope Scene("msaa");
		let post = scene.AddSystem<PostProcessSystem>();
		post.Post.AutoExposure = true;
		post.Post.AoMode = .SSAO;
		post.Post.SsrEnabled = true;
		post.Post.AaMode = .TAA;

		subsystem.MsaaSamples = 4;
		let withMsaa = subsystem.ViewPost(scene);
		Test.Assert(withMsaa.MsaaSamples == 4);
		Test.Assert(withMsaa.AutoExposure);
		Test.Assert(withMsaa.AoMode == (uint32)AoMode.SSAO);
		Test.Assert(withMsaa.SsrEnabled);
		Test.Assert(withMsaa.TaaEnabled);

		// A sample's debug panel still overrides the scene's look, and the count stays.
		subsystem.Exposure = 2.0f;
		let overridden = subsystem.ViewPost(scene);
		Test.Assert(Math.Abs(overridden.Exposure - 2.0f) < 1e-5f);
		Test.Assert(!overridden.AutoExposure);
		Test.Assert(overridden.MsaaSamples == 4);
	}
}
