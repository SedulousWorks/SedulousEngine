using System;

namespace Sedulous.Shaders;

/// The engine's own shaders (Data/Shaders) are a file per stage, `<name>.<vs|ps|cs>.hlsl`, whose
/// function is `main`: the corpus's convention, stated once for the provider that serves them and
/// the cook that packs them. A shader of another shape names its entries itself.
static class ShaderCorpus
{
	public const String EntryPoint = "main";
}
