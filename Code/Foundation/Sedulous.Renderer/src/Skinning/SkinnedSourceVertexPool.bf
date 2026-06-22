namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;

/// Shared source-vertex buffer for every skinned mesh. Each skinned GPUMesh
/// uploads its source vertices into a sub-range of this single buffer
/// instead of creating its own VkBuffer. The skinning compute pass reads
/// from (pool.Buffer, mesh.VertexOffset, vertexCount * stride).
///
/// Source vertices are written once (mesh upload) and never modified, so
/// the pool is GpuOnly and just needs CopyDst for the staging upload plus
/// StorageRead for the compute-shader bind.
///
/// Step A.3 of the mega-dispatch rework. Like A.1 and A.2, by itself this
/// only changes the backing storage - the source-buffer descriptor entry
/// still varies its offset per character. A.4 collapses all four per-instance
/// bind groups into one shared bind group.
class SkinnedSourceVertexPool : IDisposable
{
	public const uint64 Alignment = 256;

	private IDevice mDevice;
	private IBuffer mBuffer;
	private uint64 mBufferSize;
	private uint64 mBumpHead;

	private Dictionary<uint64, List<uint64>> mFreeBySize = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	private bool mWarnedOnOverflow;

	public Result<void> Initialize(IDevice device, uint64 initialSize)
	{
		mDevice = device;
		mBufferSize = AlignUp(initialSize);

		BufferDesc desc = .()
		{
			Label = "Skinned Source Vertex Pool",
			Size = mBufferSize,
			Usage = .StorageRead | .CopyDst,
			Memory = .GpuOnly
		};
		if (device.CreateBuffer(desc) case .Ok(let buf))
		{
			mBuffer = buf;
			return .Ok;
		}
		return .Err;
	}

	public bool Allocate(uint64 size, out uint64 offset, out uint64 alignedSize)
	{
		alignedSize = AlignUp(size);

		if (mFreeBySize.TryGetValue(alignedSize, var list) && list.Count > 0)
		{
			offset = list.PopBack();
			return true;
		}

		if (mBumpHead + alignedSize > mBufferSize)
		{
			if (!mWarnedOnOverflow)
			{
				Console.WriteLine("[SkinnedSourceVertexPool] Pool exhausted at {0} MB. Bump head {1} + request {2} > size {3}. Skipping further skinned-mesh uploads until slots free.",
					mBufferSize / (1024 * 1024), mBumpHead, alignedSize, mBufferSize);
				mWarnedOnOverflow = true;
			}
			offset = 0;
			return false;
		}

		offset = mBumpHead;
		mBumpHead += alignedSize;
		return true;
	}

	public void Free(uint64 offset, uint64 alignedSize)
	{
		if (!mFreeBySize.TryGetValue(alignedSize, var list))
		{
			list = new .();
			mFreeBySize[alignedSize] = list;
		}
		list.Add(offset);
	}

	public IBuffer Buffer => mBuffer;
	public uint64 SizeBytes => mBufferSize;

	private static uint64 AlignUp(uint64 v) => (v + Alignment - 1) & ~(Alignment - 1);

	public void Dispose()
	{
		if (mBuffer != null && mDevice != null)
		{
			mDevice.DestroyBuffer(ref mBuffer);
			mBuffer = null;
		}
	}
}
