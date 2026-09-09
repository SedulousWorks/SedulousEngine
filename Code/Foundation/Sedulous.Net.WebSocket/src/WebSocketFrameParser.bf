using System;
using System.Collections;

namespace Sedulous.Net.WebSocket;

/// An incremental decoder for the SERVER side of a connection.
///
/// Push bytes as they arrive and drain whole frames with Next. It enforces what this
/// deliberately bounded server accepts: client frames masked, no fragmentation, no reserved
/// bits, and a size cap. Failure LATCHES, because once framing is lost there is no way back
/// into sync; the caller closes the connection.
class WebSocketFrameParser
{
	private List<uint8> mBuffer = new .() ~ delete _;
	/// Where the next undecoded frame starts. The buffer is only compacted once it drains.
	private int mHead = 0;
	private List<WsFrame> mFrames = new .() ~ DeleteContainerAndItems!(_);
	private int mFrameHead = 0;
	private bool mFailed = false;

	public bool Failed => mFailed;

	public void Push(Span<uint8> bytes)
	{
		if (mFailed)
			return;
		mBuffer.AddRange(bytes);
		Parse();
	}

	/// Fills outFrame with the next decoded frame. False when none is ready.
	public bool Next(WsFrame outFrame)
	{
		if (mFrameHead >= mFrames.Count)
			return false;

		let frame = mFrames[mFrameHead];
		mFrameHead++;
		outFrame.Set(frame.Opcode, frame.Payload);

		if (mFrameHead >= mFrames.Count)
		{
			ClearAndDeleteItems!(mFrames);
			mFrameHead = 0;
		}
		return true;
	}

	private void Parse()
	{
		for (;;)
		{
			let available = mBuffer.Count - mHead;
			if (available < 2)
				return;

			let b0 = mBuffer[mHead];
			let b1 = mBuffer[mHead + 1];
			let fin = (b0 & 0x80) != 0;

			// Reserved bits with no extension negotiated, and fragmentation, are both
			// protocol errors here: a game packet never needs either.
			if (((b0 & 0x70) != 0) || !fin)
			{
				mFailed = true;
				return;
			}

			let opcode = (WsOpcode)(b0 & 0x0F);

			// The RFC requires a client to mask. An unmasked client frame is either a broken
			// client or something pretending to be one.
			if ((b1 & 0x80) == 0)
			{
				mFailed = true;
				return;
			}

			uint64 length = b1 & 0x7F;
			var cursor = mHead + 2;
			if (length == 126)
			{
				if (available < 4)
					return;
				length = ((uint64)mBuffer[cursor] << 8) | (uint64)mBuffer[cursor + 1];
				cursor += 2;
			}
			else if (length == 127)
			{
				if (available < 10)
					return;
				length = 0;
				for (int i = 0; i < 8; i++)
					length = (length << 8) | (uint64)mBuffer[cursor + i];
				cursor += 8;
			}

			if (length > (uint64)WebSocketFrame.MaxFrameBytes)
			{
				mFailed = true;
				return;
			}

			// The masking key plus the whole payload have to be here before anything is
			// decoded, because unmasking is not resumable.
			if ((uint64)(mBuffer.Count - cursor) < (4 + length))
				return;

			let key = scope uint8[4](mBuffer[cursor], mBuffer[cursor + 1], mBuffer[cursor + 2],
				mBuffer[cursor + 3]);
			cursor += 4;

			let frame = new WsFrame();
			frame.Opcode = opcode;
			for (int i = 0; i < (int)length; i++)
				frame.Payload.Add(mBuffer[cursor + i] ^ key[i % 4]);
			mFrames.Add(frame);

			mHead = cursor + (int)length;
			if (mHead == mBuffer.Count)
			{
				mBuffer.Clear();
				mHead = 0;
			}
		}
	}
}
