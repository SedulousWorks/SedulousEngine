using System;
using System.Threading;
using Sedulous.Content;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// The intermediate a decode produces and a finalize consumes.
class DecodedIntermediate
{
	public int32 Area;
}

/// A factory that has opted into the two stage path, and records which thread each stage
/// ran on so a test can check the contract rather than assume it.
class AsyncProductFactory : IResourceFactory
{
	public int32 Decodes;
	public int32 Finalizes;
	public int DecodeThreadId;
	public int FinalizeThreadId;
	/// Held closed to keep a decode in flight while a test looks at the pending state.
	public WaitEvent Gate ~ delete _;
	/// The decode itself refuses, so the load fails before there is an intermediate.
	public bool RefuseDecode;
	/// The decode succeeds and the finalize refuses, which fails on the other side of the
	/// thread hop and must still settle rather than hang.
	public bool RefuseFinalize;

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<TestProduct>();

	public bool SupportsAsync => true;

	/// Synchronous fallback, for when async is not available.
	public Object Create(ResourceManager manager, Instance instance)
	{
		let decoded = DecodeStage(instance);
		if (decoded == null)
			return null;
		return FinalizeStage(manager, decoded);
	}

	public Object DecodeStage(Instance instance)
	{
		if (Gate != null)
			Gate.WaitFor(2000);

		DecodeThreadId = Thread.CurrentThread.Id;
		Interlocked.Increment(ref Decodes);

		if (RefuseDecode)
			return null;

		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;

		let decoded = new DecodedIntermediate();
		decoded.Area = ((TestSource)source).Width * ((TestSource)source).Height;
		return decoded;
	}

	public Object FinalizeStage(ResourceManager manager, Object decoded)
	{
		FinalizeThreadId = Thread.CurrentThread.Id;
		Finalizes++;

		let intermediate = (DecodedIntermediate)decoded;
		defer delete intermediate;

		if (RefuseFinalize)
			return null;

		let product = new TestProduct();
		product.Area = intermediate.Area;
		product.BuildCount = Finalizes;
		return product;
	}
}
