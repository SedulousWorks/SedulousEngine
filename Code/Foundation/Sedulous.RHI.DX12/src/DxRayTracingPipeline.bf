#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One ray tracing state object.
///
/// D3D12 describes these as a list of SUBOBJECTS rather than a struct: one DXIL library per
/// stage, one hit group per triangle or procedural group, then the shader config, the pipeline
/// config and the global root signature. The state object is created from that list in one
/// call, so every array it points into has to be alive and stable until it returns.
///
/// Export names reach D3D12 as UTF-16. They are stored here NARROW and widened only where
/// D3D12 is called, so there is one conversion in one place; see Widen.
class DxRayTracingPipeline : IRayTracingPipeline
{
	private ID3D12StateObject* mStateObject = null; // owned, released in Cleanup
	private ID3D12StateObjectProperties* mProperties = null; // owned, released in Cleanup
	private DxPipelineLayout mLayout = null; // NOT owned

	/// One export name per group, in the description's group order, which is what a caller
	/// asking for shader group handles indexes by.
	private List<String> mGroupExportNames = new .() ~ DeleteContainerAndItems!(_);

	public IPipelineLayout Layout => mLayout;
	public ID3D12StateObject* Handle => mStateObject;
	public ID3D12StateObjectProperties* Properties => mProperties;
	public DxPipelineLayout PipelineLayout => mLayout;
	public Span<String> GroupExportNames => mGroupExportNames;

	/// UTF-8 to UTF-16, null terminated. Shader export names are ASCII, so a widening cast per
	/// character is the whole of it.
	private static void Widen(StringView narrow, List<char16> outWide)
	{
		outWide.Clear();
		for (int i = 0; i < narrow.Length; i++)
			outWide.Add((char16)(uint8)narrow[i]);
		outWide.Add(0);
	}

	public Result<void> Initialize(ID3D12Device* device, RayTracingPipelineDesc desc)
	{
		mLayout = desc.Layout as DxPipelineLayout;
		if (mLayout == null)
		{
			GlobalLog(.Error, "DxRayTracingPipeline: the pipeline layout is null");
			return .Err;
		}

		ID3D12Device5* device5 = null;
		let qiHr = device.QueryInterface(ID3D12Device5.IID, (void**)&device5);
		if (FAILED(qiHr) || (device5 == null))
		{
			GlobalLog(.Error,
				"DxRayTracingPipeline: QueryInterface for ID3D12Device5 failed (0x{0:X8})",
				(uint32)qiHr);
			return .Err;
		}
		defer device5.Release();

		// Every wide name D3D12 is handed has to outlive CreateStateObject, so they are all
		// built here and freed only once it has returned.
		let wideNames = scope List<List<char16>>();
		defer { for (let w in wideNames) delete w; }

		// One entry per stage that has a module, matching the C++ order.
		for (let stage in desc.Stages)
		{
			if ((stage.Module as DxShaderModule) == null)
				continue;
			let w = new List<char16>();
			Widen(stage.EntryPoint, w);
			wideNames.Add(w);
		}

		// Sized before any pointer into it is taken, so growth cannot move it afterwards.
		let exports = scope List<D3D12_EXPORT_DESC>();
		exports.Resize(wideNames.Count);
		for (int i = 0; i < wideNames.Count; i++)
		{
			exports[i] = .();
			exports[i].Name = wideNames[i].Ptr;
			exports[i].Flags = .D3D12_EXPORT_FLAG_NONE;
		}

		let libraries = scope List<D3D12_DXIL_LIBRARY_DESC>();
		int exportIdx = 0;
		for (let stage in desc.Stages)
		{
			let dxMod = stage.Module as DxShaderModule;
			if (dxMod == null)
				continue;

			let bc = dxMod.Bytecode;
			D3D12_DXIL_LIBRARY_DESC lib = .();
			lib.DXILLibrary.pShaderBytecode = bc.Ptr;
			lib.DXILLibrary.BytecodeLength = (uint)bc.Length;
			lib.NumExports = 1;
			lib.pExports = &exports[exportIdx];
			libraries.Add(lib);
			exportIdx++;
		}

		// Hit group names, kept beside the entry point names in the same owning list.
		let hitGroups = scope List<D3D12_HIT_GROUP_DESC>();
		let hitGroupNameStart = wideNames.Count;

		for (int i = 0; i < desc.Groups.Length; i++)
		{
			let group = desc.Groups[i];
			if ((group.Type != .TrianglesHitGroup) && (group.Type != .ProceduralHitGroup))
				continue;

			let hgName = new List<char16>();
			Widen(scope $"HitGroup{i}", hgName);
			wideNames.Add(hgName);

			D3D12_HIT_GROUP_DESC hg = .();
			hg.HitGroupExport = hgName.Ptr;
			hg.Type = (group.Type == .TrianglesHitGroup)
				? .D3D12_HIT_GROUP_TYPE_TRIANGLES
				: .D3D12_HIT_GROUP_TYPE_PROCEDURAL_PRIMITIVE;

			if ((group.ClosestHitShaderIndex != RayTracingShaderGroup.UnusedShader) &&
				((int)group.ClosestHitShaderIndex < hitGroupNameStart))
				hg.ClosestHitShaderImport = wideNames[(int)group.ClosestHitShaderIndex].Ptr;
			if ((group.AnyHitShaderIndex != RayTracingShaderGroup.UnusedShader) &&
				((int)group.AnyHitShaderIndex < hitGroupNameStart))
				hg.AnyHitShaderImport = wideNames[(int)group.AnyHitShaderIndex].Ptr;
			if ((group.IntersectionShaderIndex != RayTracingShaderGroup.UnusedShader) &&
				((int)group.IntersectionShaderIndex < hitGroupNameStart))
				hg.IntersectionShaderImport = wideNames[(int)group.IntersectionShaderIndex].Ptr;

			hitGroups.Add(hg);
		}

		// The export name each group answers to, in the description's order.
		for (int i = 0; i < desc.Groups.Length; i++)
		{
			let group = desc.Groups[i];
			if (group.Type == .General)
			{
				// A standalone shader is exported under its own entry point name.
				if ((group.GeneralShaderIndex != RayTracingShaderGroup.UnusedShader) &&
					((int)group.GeneralShaderIndex < desc.Stages.Length))
				{
					mGroupExportNames.Add(new String(
						desc.Stages[(int)group.GeneralShaderIndex].EntryPoint));
				}
				else
				{
					mGroupExportNames.Add(new String());
				}
			}
			else
			{
				mGroupExportNames.Add(new String(scope $"HitGroup{i}"));
			}
		}

		// libraries and hitGroups are complete, so pointers into them are stable now.
		let subobjects = scope List<D3D12_STATE_SUBOBJECT>();
		subobjects.Resize(libraries.Count + hitGroups.Count + 3);
		int soIdx = 0;

		for (int i = 0; i < libraries.Count; i++)
		{
			subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_DXIL_LIBRARY;
			subobjects[soIdx].pDesc = &libraries[i];
			soIdx++;
		}

		for (int i = 0; i < hitGroups.Count; i++)
		{
			subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_HIT_GROUP;
			subobjects[soIdx].pDesc = &hitGroups[i];
			soIdx++;
		}

		D3D12_RAYTRACING_SHADER_CONFIG shaderConfig = .();
		shaderConfig.MaxPayloadSizeInBytes = (desc.MaxPayloadSize > 0) ? desc.MaxPayloadSize : 32;
		shaderConfig.MaxAttributeSizeInBytes = (desc.MaxAttributeSize > 0) ? desc.MaxAttributeSize : 8;
		subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_RAYTRACING_SHADER_CONFIG;
		subobjects[soIdx].pDesc = &shaderConfig;
		soIdx++;

		D3D12_RAYTRACING_PIPELINE_CONFIG pipelineConfig = .();
		pipelineConfig.MaxTraceRecursionDepth = desc.MaxRecursionDepth;
		subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_RAYTRACING_PIPELINE_CONFIG;
		subobjects[soIdx].pDesc = &pipelineConfig;
		soIdx++;

		D3D12_GLOBAL_ROOT_SIGNATURE globalRootSig = .();
		globalRootSig.pGlobalRootSignature = mLayout.Handle;
		subobjects[soIdx].Type = .D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_ROOT_SIGNATURE;
		subobjects[soIdx].pDesc = &globalRootSig;
		soIdx++;

		D3D12_STATE_OBJECT_DESC stateObjDesc = .();
		stateObjDesc.Type = .D3D12_STATE_OBJECT_TYPE_RAYTRACING_PIPELINE;
		stateObjDesc.NumSubobjects = (uint32)soIdx;
		stateObjDesc.pSubobjects = subobjects.Ptr;

		let hr = device5.CreateStateObject(&stateObjDesc, ID3D12StateObject.IID,
			(void**)&mStateObject);
		if (FAILED(hr) || (mStateObject == null))
		{
			GlobalLog(.Error, "DxRayTracingPipeline: CreateStateObject failed (0x{0:X8})",
				(uint32)hr);
			return .Err;
		}

		// The properties interface is how a shader identifier is looked up. Its absence is
		// not fatal here; GetShaderIdentifier answers null instead.
		if (FAILED(mStateObject.QueryInterface(ID3D12StateObjectProperties.IID,
			(void**)&mProperties)))
			mProperties = null;

		return .Ok;
	}

	/// The 32 byte shader identifier for an export, or null when it cannot be resolved.
	public void* GetShaderIdentifier(StringView exportName)
	{
		if (mProperties == null)
			return null;

		let wide = scope List<char16>();
		Widen(exportName, wide);
		return mProperties.GetShaderIdentifier(wide.Ptr);
	}

	public void Cleanup()
	{
		if (mProperties != null)
		{
			mProperties.Release();
			mProperties = null;
		}

		if (mStateObject != null)
		{
			mStateObject.Release();
			mStateObject = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
