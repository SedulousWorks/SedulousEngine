namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IRayTracingPipeline.
/// Wraps a D3D12 state object created via ID3D12Device5.CreateStateObject.
class DX12RayTracingPipeline : IRayTracingPipeline
{
	private ID3D12StateObject* mStateObject;
	private ID3D12StateObjectProperties* mProperties;
	private DX12PipelineLayout mLayout;
	private List<String> mGroupExportNames = new .() ~ DeleteContainerAndItems!(_);

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(DX12Device device, RayTracingPipelineDesc desc)
	{
		mLayout = desc.Layout as DX12PipelineLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12RayTracingPipeline: pipeline layout is null");
			return .Err;
		}

		// Query ID3D12Device5 for CreateStateObject
		ID3D12Device5* device5 = null;
		HRESULT hr = device.Handle.QueryInterface(ID3D12Device5.IID, (void**)&device5);
		if (!SUCCEEDED(hr) || device5 == null)
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12RayTracingPipeline: QueryInterface for ID3D12Device5 failed (0x{hr:X})");
			return .Err;
		}
		defer device5.Release();

		// Build subobjects:
		// 1. DXIL library (all shaders)
		// 2. Hit groups
		// 3. Shader config (payload/attribute sizes)
		// 4. Pipeline config (max recursion)
		// 5. Global root signature

		// Count subobjects needed
		int numGroups = 0;
		for (let group in desc.Groups)
		{
			if (group.Type == .TrianglesHitGroup || group.Type == .ProceduralHitGroup)
				numGroups++;
		}
		int subobjectCount = 1 + numGroups + 1 + 1 + 1; // library + hit groups + shader config + pipeline config + global root sig

		D3D12_STATE_SUBOBJECT[] subobjects = scope D3D12_STATE_SUBOBJECT[subobjectCount];
		int soIdx = 0;

		// --- DXIL Library ---
		// Each stage's shader module is a separate DXIL library with its entry point exported
		List<D3D12_DXIL_LIBRARY_DESC> libraries = scope .();
		List<D3D12_EXPORT_DESC> exports = scope .();
		List<String> exportNames = scope .();

		for (let stage in desc.Stages)
		{
			let dxModule = stage.Module as DX12ShaderModule;
			if (dxModule == null) continue;

			let exportName = scope:: String(stage.EntryPoint);
			exportNames.Add(exportName);

			D3D12_EXPORT_DESC exportDesc = default;
			exportDesc.Name = exportName.ToScopedNativeWChar!::();
			exportDesc.Flags = .D3D12_EXPORT_FLAG_NONE;

			exports.Add(exportDesc);
		}

		// Each stage gets its own library subobject
		for (int i = 0; i < desc.Stages.Length; i++)
		{
			let stage = desc.Stages[i];
			let dxModule = stage.Module as DX12ShaderModule;
			if (dxModule == null) continue;

			D3D12_DXIL_LIBRARY_DESC lib = default;
			lib.DXILLibrary.pShaderBytecode = dxModule.Bytecode.Ptr;
			lib.DXILLibrary.BytecodeLength = (uint)dxModule.Bytecode.Length;
			lib.NumExports = 1;
			lib.pExports = &exports[i];

			libraries.Add(lib);
		}

		// Add all library subobjects
		for (int i = 0; i < libraries.Count; i++)
		{
			subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY;
			subobjects[soIdx].pDesc = &libraries[i];
			soIdx++;
		}

		// Recount - we may have more subobjects than initially estimated
		// Actually let's just allocate a bigger array upfront
		// We already allocated enough: 1 library subobject is replaced by N library subobjects
		// Need to reallocate
		int actualSubobjectCount = libraries.Count + numGroups + 3; // libraries + hit groups + shader config + pipeline config + root sig
		D3D12_STATE_SUBOBJECT[] actualSubobjects = scope D3D12_STATE_SUBOBJECT[actualSubobjectCount];
		soIdx = 0;

		for (int i = 0; i < libraries.Count; i++)
		{
			actualSubobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY;
			actualSubobjects[soIdx].pDesc = &libraries[i];
			soIdx++;
		}

		// --- Hit Groups ---
		List<D3D12_HIT_GROUP_DESC> hitGroups = scope .();
		List<String> hitGroupNames = scope .();

		for (int i = 0; i < desc.Groups.Length; i++)
		{
			let group = desc.Groups[i];
			if (group.Type != .TrianglesHitGroup && group.Type != .ProceduralHitGroup)
				continue;

			let hgName = scope:: String();
			hgName.AppendF("HitGroup{}", i);
			hitGroupNames.Add(hgName);

			D3D12_HIT_GROUP_DESC hg = default;
			hg.HitGroupExport = hgName.ToScopedNativeWChar!::();
			hg.Type = (group.Type == .TrianglesHitGroup)
				? .D3D12_HIT_GROUP_TYPE_TRIANGLES
				: .D3D12_HIT_GROUP_TYPE_PROCEDURAL_PRIMITIVE;

			if (group.ClosestHitShaderIndex != uint32.MaxValue && (int)group.ClosestHitShaderIndex < exportNames.Count)
				hg.ClosestHitShaderImport = exportNames[(int)group.ClosestHitShaderIndex].ToScopedNativeWChar!::();

			if (group.AnyHitShaderIndex != uint32.MaxValue && (int)group.AnyHitShaderIndex < exportNames.Count)
				hg.AnyHitShaderImport = exportNames[(int)group.AnyHitShaderIndex].ToScopedNativeWChar!::();

			if (group.IntersectionShaderIndex != uint32.MaxValue && (int)group.IntersectionShaderIndex < exportNames.Count)
				hg.IntersectionShaderImport = exportNames[(int)group.IntersectionShaderIndex].ToScopedNativeWChar!::();

			hitGroups.Add(hg);
		}

		for (int i = 0; i < hitGroups.Count; i++)
		{
			actualSubobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_HIT_GROUP;
			actualSubobjects[soIdx].pDesc = &hitGroups[i];
			soIdx++;
		}

		// --- Build group-to-export-name mapping ---
		// For each group in desc.Groups order, store the DX12 export name
		// used to retrieve its shader identifier.
		for (int i = 0; i < desc.Groups.Length; i++)
		{
			let group = desc.Groups[i];
			if (group.Type == .General)
			{
				// General groups (raygen/miss/callable) use the entry point name
				if (group.GeneralShaderIndex != uint32.MaxValue && (int)group.GeneralShaderIndex < desc.Stages.Length)
					mGroupExportNames.Add(new String(desc.Stages[(int)group.GeneralShaderIndex].EntryPoint));
				else
					mGroupExportNames.Add(new String());
			}
			else
			{
				// Hit groups use "HitGroupN" where N is the group index
				let name = new String();
				name.AppendF("HitGroup{}", i);
				mGroupExportNames.Add(name);
			}
		}

		// --- Shader Config ---
		D3D12_RAYTRACING_SHADER_CONFIG shaderConfig = .()
		{
			MaxPayloadSizeInBytes = (desc.MaxPayloadSize > 0) ? desc.MaxPayloadSize : 32,
			MaxAttributeSizeInBytes = (desc.MaxAttributeSize > 0) ? desc.MaxAttributeSize : 8
		};
		actualSubobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_RAYTRACING_SHADER_CONFIG;
		actualSubobjects[soIdx].pDesc = &shaderConfig;
		soIdx++;

		// --- Pipeline Config ---
		D3D12_RAYTRACING_PIPELINE_CONFIG pipelineConfig = .()
		{
			MaxTraceRecursionDepth = desc.MaxRecursionDepth
		};
		actualSubobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_RAYTRACING_PIPELINE_CONFIG;
		actualSubobjects[soIdx].pDesc = &pipelineConfig;
		soIdx++;

		// --- Global Root Signature ---
		D3D12_GLOBAL_ROOT_SIGNATURE globalRootSig = .()
		{
			pGlobalRootSignature = mLayout.Handle
		};
		actualSubobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_ROOT_SIGNATURE;
		actualSubobjects[soIdx].pDesc = &globalRootSig;
		soIdx++;

		// --- Create State Object ---
		D3D12_STATE_OBJECT_DESC stateObjDesc = .()
		{
			Type = .D3D12_STATE_OBJECT_TYPE_RAYTRACING_PIPELINE,
			NumSubobjects = (uint32)soIdx,
			pSubobjects = actualSubobjects.CArray()
		};

		hr = device5.CreateStateObject(&stateObjDesc, ID3D12StateObject.IID, (void**)&mStateObject);
		if (!SUCCEEDED(hr) || mStateObject == null)
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12RayTracingPipeline: CreateStateObject failed (0x{hr:X})");
			return .Err;
		}

		// Query properties for shader identifier lookup
		hr = mStateObject.QueryInterface(ID3D12StateObjectProperties.IID, (void**)&mProperties);
		if (!SUCCEEDED(hr)) mProperties = null;

		return .Ok;
	}

	/// Gets the shader identifier for an export name.
	/// Returns a pointer to 32 bytes (D3D12_SHADER_IDENTIFIER_SIZE_IN_BYTES).
	public void* GetShaderIdentifier(StringView exportName)
	{
		if (mProperties == null) return null;
		let wideName = scope String(exportName).ToScopedNativeWChar!();
		return mProperties.GetShaderIdentifier(wideName);
	}

	public void Cleanup(DX12Device device)
	{
		if (mProperties != null) { mProperties.Release(); mProperties = null; }
		if (mStateObject != null) { mStateObject.Release(); mStateObject = null; }
	}

	// --- Internal ---
	public ID3D12StateObject* Handle => mStateObject;
	public ID3D12StateObjectProperties* Properties => mProperties;
	public List<String> GroupExportNames => mGroupExportNames;
}
