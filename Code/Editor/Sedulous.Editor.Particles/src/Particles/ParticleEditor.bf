using System;
using Sedulous.Particles;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Particles;

/// The particle editor's composition: the particle effect page, its rows' types with it.
static class ParticleEditor
{
	/// The particle effect page; a page asks `services` (borrowed: the editor's, or a test's, which
	/// outlives the factory) for its own when it is made.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		RegisterRowTypes();
		context.Pages.Register(new ParticleEffectPageFactory(services));
	}

	/// What the page's rows need, for the process (again changes nothing): the modules in the
	/// serializable registry, so a list's add can make each type, and the particle curves as one
	/// curve or gradient value for the toolkit's editors.
	public static void RegisterRowTypes()
	{
		ParticleModules.RegisterModules();
		FieldPropertySource.RegisterCurveType(typeof(ParticleCurveFloat), .("Keys", "KeyCount"));
		FieldPropertySource.RegisterGradientType(typeof(ParticleCurveColor), .("Colors", "ColorCount", "Alphas", "AlphaCount", "Interpolation"));
	}
}
