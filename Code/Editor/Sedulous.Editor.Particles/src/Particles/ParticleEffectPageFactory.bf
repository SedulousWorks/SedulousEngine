using System;
using Sedulous.Content;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Particles;

/// Opens a ParticleEffectAsset in the particle page; a page asks for its services when it is made.
class ParticleEffectPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(ParticleEffectAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new ParticleEffectEditorPage(context, mServices.Make(), instance);
}
