using System;
using wgpu_Beef;

namespace Sedulous.RHI.WebGPU;

/// A pipeline's push constant emulation binding, snapshotted onto the pipeline so a pass
/// encoder can resolve it when the pipeline is set.
///
/// Group is -1 when the pipeline issues NATIVE immediates and there is no emulation at
/// all. Otherwise the block binds as a uniform at that group, binding zero.
struct PushConstantEmulation
{
	public int32 Group = -1;
	public WGPUBindGroupLayout Layout = null;
	public uint32 BlockSize = 0;
}
