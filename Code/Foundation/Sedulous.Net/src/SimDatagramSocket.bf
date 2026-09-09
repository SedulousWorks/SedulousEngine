using System;
using System.Collections;

namespace Sedulous.Net;

/// A socket on a simulated network. Send routes through the shared network, which applies the
/// conditions when its clock advances; Receive drains what the network has delivered here.
///
/// OWNED by its network.
class SimDatagramSocket : IDatagramSocket
{
	/// One delivered datagram waiting to be drained.
	private class Received
	{
		public DatagramEndpoint From;
		public List<uint8> Data = new .() ~ delete _;
	}

	private SimDatagramNetwork mNetwork;
	private DatagramEndpoint mEndpoint;
	private List<Received> mReceived = new .() ~ DeleteContainerAndItems!(_);
	/// Where the next drain starts. The list is only compacted once it empties, so draining a
	/// tick's worth is not quadratic in the number of datagrams.
	private int mReceivedHead = 0;

	public this(SimDatagramNetwork network, DatagramEndpoint endpoint)
	{
		mNetwork = network;
		mEndpoint = endpoint;
	}

	public DatagramEndpoint LocalEndpoint => mEndpoint;

	public void Send(DatagramEndpoint to, Span<uint8> data)
	{
		if (mNetwork != null)
			mNetwork.[Friend]Route(mEndpoint, to, data);
	}

	public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData)
	{
		if (mReceivedHead >= mReceived.Count)
		{
			outFrom = .();
			return false;
		}

		let entry = mReceived[mReceivedHead];
		mReceivedHead++;
		outFrom = entry.From;
		outData.Clear();
		outData.AddRange(entry.Data);

		if (mReceivedHead >= mReceived.Count)
		{
			ClearAndDeleteItems!(mReceived);
			mReceivedHead = 0;
		}
		return true;
	}

	/// The network hands a delivered datagram over. The queue entry is built HERE rather than
	/// by the network, so the entry type stays this socket's business.
	private void Deliver(DatagramEndpoint from, Span<uint8> data)
	{
		let entry = new Received();
		entry.From = from;
		entry.Data.AddRange(data);
		mReceived.Add(entry);
	}
}
