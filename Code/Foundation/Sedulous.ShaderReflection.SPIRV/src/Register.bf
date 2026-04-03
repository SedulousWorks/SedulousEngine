namespace Sedulous.ShaderReflection.SPIRV;

/// Self-registration via static constructor.
/// Adding this project as a dependency automatically registers the SPIR-V reflection backend.
static class Register
{
	static SPIRVReflectionBackend sInstance = new .() ~ delete _;

	static this()
	{
		ShaderReflection.RegisterBackend(sInstance);
	}
}
