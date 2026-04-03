namespace Sedulous.ShaderReflection.DXIL;

using System;
using System.Diagnostics;
using Sedulous.RHI;
using Dxc_Beef;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D.Fxc;
using Win32.Graphics.Direct3D12;
using Win32.Foundation;

/// DXIL reflection backend.
/// Tries DXC (IDxcUtils.CreateReflection) first, falls back to D3DReflect from d3dcompiler_47.
class DXILReflectionBackend : IReflectionBackend
{
	public ShaderFormat Format => .DXIL;

	public Result<ReflectedShader> Reflect(Span<uint8> bytecode, StringView entryPoint = default)
	{
		if (bytecode.Length == 0)
			return .Err;

		// Try DXC first, fall back to d3dcompiler
		ID3D12ShaderReflection* reflection = null;

		if (TryReflectViaDxc(bytecode, out reflection) || TryReflectViaD3DCompiler(bytecode, out reflection))
		{
			defer reflection.Release();
			return BuildReflection(reflection, entryPoint);
		}

		Debug.WriteLine("DXIL reflection: both DXC and D3DCompiler reflection failed");
		return .Err;
	}

	/// Try to get reflection via DXC's IDxcUtils.CreateReflection.
	private bool TryReflectViaDxc(Span<uint8> bytecode, out ID3D12ShaderReflection* reflection)
	{
		reflection = null;

		IDxcUtils* utils = null;
		if (Dxc.CreateInstance<IDxcUtils>(out utils) != .S_OK || utils == null)
			return false;

		defer utils.Release();

		DxcBuffer buffer = .()
		{
			Ptr = bytecode.Ptr,
			Size = (uint)bytecode.Length,
			Encoding = 0
		};

		void* reflectionPtr = null;
		var iid = ID3D12ShaderReflection.IID;
		if (utils.VT.CreateReflection(utils, &buffer, ref iid, &reflectionPtr) == .S_OK && reflectionPtr != null)
		{
			reflection = (.)reflectionPtr;
			return true;
		}

		return false;
	}

	/// Fall back to D3DReflect from d3dcompiler_47.dll.
	private bool TryReflectViaD3DCompiler(Span<uint8> bytecode, out ID3D12ShaderReflection* reflection)
	{
		reflection = null;

		void* reflectionPtr = null;
		let iid = ID3D12ShaderReflection.IID;
		if (D3DReflect(bytecode.Ptr, (uint)bytecode.Length, iid, &reflectionPtr) == S_OK && reflectionPtr != null)
		{
			reflection = (.)reflectionPtr;
			return true;
		}

		return false;
	}

	private Result<ReflectedShader> BuildReflection(ID3D12ShaderReflection* reflection, StringView entryPoint)
	{
		D3D12_SHADER_DESC shaderDesc = .();
		if (reflection.GetDesc(&shaderDesc) != S_OK)
			return .Err;

		let result = new ReflectedShader();

		// Determine shader stage from version
		result.Stage = DXILTypeMapper.StageFromVersion(shaderDesc.Version);

		// Set entry point
		if (!entryPoint.IsEmpty)
			result.EntryPoint.Set(entryPoint);
		else
			result.EntryPoint.Set("main");

		// Extract resource bindings
		ReflectBindings(reflection, shaderDesc, result);

		// Extract vertex inputs (vertex shaders only)
		if (result.Stage == .Vertex)
			ReflectVertexInputs(reflection, shaderDesc, result);

		// Extract thread group size (compute, mesh, task shaders)
		if (result.Stage == .Compute || result.Stage == .Mesh || result.Stage == .Task)
		{
			uint32 x = 0, y = 0, z = 0;
			reflection.GetThreadGroupSize(&x, &y, &z);
			result.ThreadGroupSize[0] = x;
			result.ThreadGroupSize[1] = y;
			result.ThreadGroupSize[2] = z;
		}

		// Extract mesh shader output properties
		if (result.Stage == .Mesh)
			ReflectMeshOutput(shaderDesc, result);

		return .Ok(result);
	}

	private void ReflectBindings(ID3D12ShaderReflection* reflection, D3D12_SHADER_DESC shaderDesc, ReflectedShader result)
	{
		for (uint32 i = 0; i < shaderDesc.BoundResources; i++)
		{
			D3D12_SHADER_INPUT_BIND_DESC bindDesc = .();
			if (reflection.GetResourceBindingDesc(i, &bindDesc) != S_OK)
				continue;

			let bindingType = DXILTypeMapper.ToBindingType(bindDesc.Type, bindDesc.uFlags);

			// BindCount of 0 means unbounded (bindless)
			let count = bindDesc.BindCount;

			// Convert bindless arrays to bindless binding types
			var finalType = bindingType;
			if (count == 0)
			{
				switch (bindingType)
				{
				case .SampledTexture:           finalType = .BindlessTextures;
				case .Sampler:                  finalType = .BindlessSamplers;
				case .StorageBufferReadOnly,
					 .StorageBufferReadWrite:   finalType = .BindlessStorageBuffers;
				case .StorageTextureReadOnly,
					 .StorageTextureReadWrite:  finalType = .BindlessStorageTextures;
				default:
				}
			}

			// Extract texture dimension and multisampled flag
			let texDimension = DXILTypeMapper.ToTextureDimension(bindDesc.Dimension);
			let texMultisampled = DXILTypeMapper.IsMultisampled(bindDesc.Dimension);

			let name = bindDesc.Name != null ? result.InternString(StringView((char8*)bindDesc.Name)) : StringView();

			result.Bindings.Add(.()
			{
				Set = bindDesc.Space,
				Binding = bindDesc.BindPoint,
				Type = finalType,
				Stages = result.Stage,
				Count = count,
				Name = name,
				TextureDimension = texDimension,
				TextureMultisampled = texMultisampled
			});
		}
	}

	private void ReflectVertexInputs(ID3D12ShaderReflection* reflection, D3D12_SHADER_DESC shaderDesc, ReflectedShader result)
	{
		for (uint32 i = 0; i < shaderDesc.InputParameters; i++)
		{
			D3D12_SIGNATURE_PARAMETER_DESC paramDesc = .();
			if (reflection.GetInputParameterDesc(i, &paramDesc) != S_OK)
				continue;

			// Skip system-value semantics (SV_VertexID, SV_InstanceID, etc.)
			if (paramDesc.SystemValueType != .D3D_NAME_UNDEFINED)
				continue;

			let format = DXILTypeMapper.ToVertexFormat(paramDesc.ComponentType, paramDesc.Mask);
			let name = paramDesc.SemanticName != null ? result.InternString(StringView((char8*)paramDesc.SemanticName)) : StringView();

			result.VertexInputs.Add(.()
			{
				Location = paramDesc.SemanticIndex,
				Format = format,
				Name = name
			});
		}
	}

	private void ReflectMeshOutput(D3D12_SHADER_DESC shaderDesc, ReflectedShader result)
	{
		// D3D12 repurposes GS fields for mesh shaders
		result.MeshOutput.MaxVertices = shaderDesc.GSMaxOutputVertexCount;
		result.MeshOutput.Topology = DXILTypeMapper.ToMeshTopology(shaderDesc.GSOutputTopology);

		// OutputPrimitives count is in the OutputParameters for mesh shaders
		// D3D12 reflection stores this in the CutInstructionCount field for mesh shaders
		// However, this is unreliable; the actual value comes from the shader bytecode.
		// Use OutputParameters as a best-effort approximation.
	}
}
