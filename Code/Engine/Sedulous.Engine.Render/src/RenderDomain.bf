using System;
using Sedulous.Engine.Domain;
using Sedulous.Geometry;
using Sedulous.Image.Resource;
using Sedulous.Materials.Resource;
using Sedulous.Model.Resource;
using Sedulous.Resource;
using Sedulous.Shaders.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// The render domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class RenderDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("render", => RenderScene.AddRenderSceneManagers,
		new .(
			GeometryResources.Module,
			ModelResources.Module,
			MaterialResources.Module,
			TextureResources.Module,
			ImageResources.Module,
			ShaderResources.Module)));
	private static DomainModule sModule ~ delete _;
}
