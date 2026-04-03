namespace Dxc_Beef
{
	public static
	{
		public static mixin DXIL_FOURCC(var ch0, var ch1, var ch2, var ch3)
		{
			(uint32)(uint8)(ch0) | (uint32)(uint8)(ch1) << 8 | (uint32)(uint8)(ch2) << 16 | (uint32)(uint8)(ch3) << 24
		}
	}

	static class Dxil
	{
		public enum DxilFourCC
		{
		  DFCC_Container                = DXIL_FOURCC!('D', 'X', 'B', 'C'), // for back-compat with tools that look for DXBC containers
		  DFCC_ResourceDef              = DXIL_FOURCC!('R', 'D', 'E', 'F'),
		  DFCC_InputSignature           = DXIL_FOURCC!('I', 'S', 'G', '1'),
		  DFCC_OutputSignature          = DXIL_FOURCC!('O', 'S', 'G', '1'),
		  DFCC_PatchConstantSignature   = DXIL_FOURCC!('P', 'S', 'G', '1'),
		  DFCC_ShaderStatistics         = DXIL_FOURCC!('S', 'T', 'A', 'T'),
		  DFCC_ShaderDebugInfoDXIL      = DXIL_FOURCC!('I', 'L', 'D', 'B'),
		  DFCC_ShaderDebugName          = DXIL_FOURCC!('I', 'L', 'D', 'N'),
		  DFCC_FeatureInfo              = DXIL_FOURCC!('S', 'F', 'I', '0'),
		  DFCC_PrivateData              = DXIL_FOURCC!('P', 'R', 'I', 'V'),
		  DFCC_RootSignature            = DXIL_FOURCC!('R', 'T', 'S', '0'),
		  DFCC_DXIL                     = DXIL_FOURCC!('D', 'X', 'I', 'L'),
		  DFCC_PipelineStateValidation  = DXIL_FOURCC!('P', 'S', 'V', '0'),
		  DFCC_RuntimeData              = DXIL_FOURCC!('R', 'D', 'A', 'T'),
		  DFCC_ShaderHash               = DXIL_FOURCC!('H', 'A', 'S', 'H'),
		  DFCC_ShaderSourceInfo         = DXIL_FOURCC!('S', 'R', 'C', 'I'),
		  DFCC_CompilerVersion          = DXIL_FOURCC!('V', 'E', 'R', 'S'),
		}
	}
}