using System;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Render;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Shaders;

namespace Sedulous.Engine.DefaultApp;

/// The batteries: every cooked product type the engine understands, and a factory for each,
/// composed from the engine composition root rather than listed here.
extension DefaultApplication
{
	/// The factories this application owns, destroyed at shutdown while the device they hold
	/// is alive. They are handed to a manager which only BORROWS them, so their lifetime is this
	/// application's rather than any manager's, and a manager attached later gets the same set.
	private ResourceFactorySet mFactories = new .() ~ delete _;

	/// The product TYPES: a factory constructs a cooked product by the type name stored with
	/// it, so a reader that meets an unregistered name cannot build anything at all. Every
	/// resource module of the composition, into the GLOBAL registry, which is what a content
	/// database falls back to when it was given none.
	private void RegisterProductTypes() => EngineComposition.RegisterResourceTypes();

	/// Registers the standard set on a manager: every factory the composition describes that
	/// this host's services allow. The texture factory needs the graphics device and the shader
	/// factory the render subsystem's shader system, so a headless application loads everything
	/// else and the set reports those two as skipped.
	///
	/// IDEMPOTENT per manager, and safe to run again for a manager attached after startup, which
	/// is how an editor hands one over late: a second composition creates only what the first
	/// could not.
	private void RegisterStandardFactories(ResourceManager resources, IApplicationHost host)
	{
		let services = scope ResourceServiceTable();
		let graphics = host.Graphics;
		if (graphics != null)
			services.Add(typeof(IDevice), graphics.Raw);
		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			services.Add(typeof(ShaderSystem), render.Shaders);
		EngineComposition.CreateFactories(mFactories, services);
		mFactories.Register(resources);
	}

	/// The factory set: what this application created, and what it skipped for want of a
	/// service.
	public ResourceFactorySet Factories => mFactories;
}
