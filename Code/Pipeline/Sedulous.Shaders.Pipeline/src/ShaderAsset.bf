using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Shaders.Pipeline;

/// A custom shader: its logical name, ONE .hlsl file holding both stages (the file name a plain
/// asset carries, mount relative at cook time), and the entry point each stage's function is
/// called in it.
[Category("Rendering")]
[DisplayName("Shader")]
[Serializable]
class ShaderAsset : Asset
{
	/// How a material refers to this shader.
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;

	[DisplayName("Vertex Entry Point")]
	[Description("The vertex stage's function in the file")]
	public String VertexEntryPoint = new .("VSMain") ~ delete _;

	[DisplayName("Fragment Entry Point")]
	[Description("The fragment stage's function in the file")]
	public String FragmentEntryPoint = new .("PSMain") ~ delete _;
}
