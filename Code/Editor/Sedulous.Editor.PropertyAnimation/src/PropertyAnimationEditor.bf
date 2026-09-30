using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// The plugin registrar: property animation is authored in the scene through the persistent
/// panel, so there is no standalone clip page. This ensures the clip asset types exist; the
/// "Property Animation Clip" creator is the pipeline's (PropertyAnimationCreators).
static class PropertyAnimationEditor
{
	/// The editor executable's entry point. The host is unused, the panel being scene-page
	/// owned, and kept for a uniform registrar signature.
	public static void Register(EditorContext context, IApplicationHost host)
	{
		PropertyAnimationPipeline.RegisterAll();
	}
}
