using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Audio;

/// A Schroeder reverberator: eight damped combs in parallel into four allpasses in series,
/// per channel, with the right channel's buffers offset so the two decorrelate.
///
/// PURE MATHS, with no contact with the audio backend at all, so its state machine is
/// testable without a device. The engine wraps it in a custom node for a bus effect or a
/// scene's own reverb.
class FreeverbState
{
	private const int cCombCount = 8;
	private const int cAllpassCount = 4;

	/// The canonical tunings, in samples at forty four thousand one hundred.
	private static uint32[cCombCount] sCombTunings = .(1116, 1188, 1277, 1356, 1422, 1491, 1557,
		1617);
	private static uint32[cAllpassCount] sAllpassTunings = .(556, 441, 341, 225);
	/// How far the right channel's buffers are offset from the left's.
	private const uint32 cStereoSpread = 23;

	/// The input gain the topology is defined with.
	private const float cFixedGain = 0.015f;

	private class Comb
	{
		public List<float> Buffer = new .() ~ delete _;
		public int Cursor = 0;
		public float FilterStore = 0.0f;
	}

	private class Allpass
	{
		public List<float> Buffer = new .() ~ delete _;
		public int Cursor = 0;
	}

	private Comb[2][cCombCount] mCombs;
	private Allpass[2][cAllpassCount] mAllpasses;

	private float mFeedback = 0.84f;
	private float mDamp = 0.2f;
	private float mWet = 0.4f;
	/// Tracks one minus the wet unless the parameters pin it, which is the send form.
	private float mDry = 0.6f;
	private bool mInitialized = false;

	public this()
	{
		for (int channel < 2)
		{
			for (int i < cCombCount)
				mCombs[channel][i] = new Comb();
			for (int i < cAllpassCount)
				mAllpasses[channel][i] = new Allpass();
		}
	}

	public ~this()
	{
		for (int channel < 2)
		{
			for (int i < cCombCount)
				delete mCombs[channel][i];
			for (int i < cAllpassCount)
				delete mAllpasses[channel][i];
		}
	}

	public bool IsInitialized => mInitialized;
	public float Wet => mWet;
	public float Dry => mDry;

	/// Sizes the buffers for a rate. The lengths scale from the canonical tunings, so the
	/// tail is the same length in SECONDS whatever the rate.
	public void Initialize(uint32 sampleRate)
	{
		let scale = (float)sampleRate / 44100.0f;

		for (int channel < 2)
		{
			let spread = (channel == 1) ? cStereoSpread : 0;

			for (int i < cCombCount)
			{
				let length = Max(4, (int)((float)(sCombTunings[i] + spread) * scale));
				mCombs[channel][i].Buffer.Clear();
				mCombs[channel][i].Buffer.Resize(length);
				for (int s < length)
					mCombs[channel][i].Buffer[s] = 0.0f;
				mCombs[channel][i].Cursor = 0;
				mCombs[channel][i].FilterStore = 0.0f;
			}

			for (int i < cAllpassCount)
			{
				let length = Max(2, (int)((float)(sAllpassTunings[i] + spread) * scale));
				mAllpasses[channel][i].Buffer.Clear();
				mAllpasses[channel][i].Buffer.Resize(length);
				for (int s < length)
					mAllpasses[channel][i].Buffer[s] = 0.0f;
				mAllpasses[channel][i].Cursor = 0;
			}
		}

		mInitialized = true;
	}

	public void SetParams(AudioReverbParams parameters)
	{
		mFeedback = 0.7f + Clamp(parameters.RoomSize, 0.0f, 1.0f) * 0.28f;
		mDamp = Clamp(parameters.Damping, 0.0f, 1.0f) * 0.4f;
		mWet = Clamp(parameters.Wet, 0.0f, 1.0f);
		mDry = (parameters.Dry < 0.0f) ? (1.0f - mWet) : Clamp(parameters.Dry, 0.0f, 1.0f);
	}

	/// Processes interleaved stereo: the output is the input at the dry level plus the tail
	/// at the wet one. A mono caller duplicates its channel.
	public void ProcessStereo(float* input, float* output, uint32 frameCount)
	{
		for (uint32 frame = 0; frame < frameCount; frame++)
		{
			let inLeft = input[frame * 2 + 0];
			let inRight = input[frame * 2 + 1];
			let feed = (inLeft + inRight) * cFixedGain;

			var outLeft = 0.0f;
			var outRight = 0.0f;

			for (int i < cCombCount)
			{
				outLeft += CombProcess(mCombs[0][i], feed);
				outRight += CombProcess(mCombs[1][i], feed);
			}

			for (int i < cAllpassCount)
			{
				outLeft = AllpassProcess(mAllpasses[0][i], outLeft);
				outRight = AllpassProcess(mAllpasses[1][i], outRight);
			}

			output[frame * 2 + 0] = inLeft * mDry + outLeft * mWet * 3.0f;
			output[frame * 2 + 1] = inRight * mDry + outRight * mWet * 3.0f;
		}
	}

	/// Flushes a value that has decayed to nothing.
	///
	/// A tail decays toward zero forever, and once it enters the denormal range the
	/// arithmetic can slow by orders of magnitude on some hardware, which turns a silent
	/// reverb into the most expensive thing in the mix.
	private static float Undenormal(float value) =>
		((value > -1.0e-18f) && (value < 1.0e-18f)) ? 0.0f : value;

	private float CombProcess(Comb comb, float input)
	{
		let output = comb.Buffer[comb.Cursor];
		comb.FilterStore = Undenormal(output * (1.0f - mDamp) + comb.FilterStore * mDamp);
		comb.Buffer[comb.Cursor] = Undenormal(input + comb.FilterStore * mFeedback);

		comb.Cursor++;
		if (comb.Cursor >= comb.Buffer.Count)
			comb.Cursor = 0;

		return output;
	}

	private float AllpassProcess(Allpass allpass, float input)
	{
		let buffered = allpass.Buffer[allpass.Cursor];
		let output = buffered - input;
		allpass.Buffer[allpass.Cursor] = Undenormal(input + buffered * 0.5f);

		allpass.Cursor++;
		if (allpass.Cursor >= allpass.Buffer.Count)
			allpass.Cursor = 0;

		return output;
	}
}
