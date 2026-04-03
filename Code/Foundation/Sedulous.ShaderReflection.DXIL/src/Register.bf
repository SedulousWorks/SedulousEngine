namespace Sedulous.ShaderReflection.DXIL;

/// Self-registration via static constructor.
/// Adding this project as a dependency automatically registers the DXIL reflection backend.
static class Register
{
	static DXILReflectionBackend sInstance = new .() ~ delete _;

	static this()
	{
		ShaderReflection.RegisterBackend(sInstance);
	}
}
