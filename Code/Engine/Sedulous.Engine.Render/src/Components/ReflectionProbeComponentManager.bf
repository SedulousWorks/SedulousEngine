namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;

/// Manages reflection probe components.
/// Injected into scenes by RenderSubsystem via ISceneAware.
///
/// Future phases will add IRenderDataProvider to extract probe data
/// for the renderer (cubemap capture, IBL generation, shader binding).
class ReflectionProbeComponentManager : ComponentManager<ReflectionProbeComponent>
{
	public override StringView SerializationTypeId => "Sedulous.ReflectionProbeComponent";
}
