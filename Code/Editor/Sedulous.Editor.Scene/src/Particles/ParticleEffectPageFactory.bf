using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a ParticleEffectAsset in the particle page.
class ParticleEffectPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(ParticleEffectAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new ParticleEffectEditorPage(context, mHost, mUiHost, instance);
}
