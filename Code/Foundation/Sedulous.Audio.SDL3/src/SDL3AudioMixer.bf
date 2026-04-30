namespace Sedulous.Audio.SDL3;

using System;
using SDL3;
using Sedulous.Audio;

/// SDL3 audio mixer backend. When threaded, SDL calls our callback from its
/// audio thread to request mixed samples. When not threaded, Mix() is called
/// from the main thread's Update().
class SDL3AudioMixer : AudioMixer
{
	private SDL_AudioStream* mDeviceStream;
	private int16* mOutputBuffer;

	public this(SDL_AudioDeviceID deviceId, int32 sampleRate = 48000, int32 framesPerMix = 1024)
		: base(sampleRate, framesPerMix)
	{
		let sampleCount = framesPerMix * 2;
		mOutputBuffer = new int16[sampleCount]*;

		// Create a single SDL audio stream for device output
		SDL_AudioSpec srcSpec = .();
		srcSpec.format = .SDL_AUDIO_S16;
		srcSpec.channels = 2;
		srcSpec.freq = sampleRate;

		SDL_AudioSpec deviceSpec = .();
		if (SDL3.SDL_GetAudioDeviceFormat(deviceId, &deviceSpec, null))
		{
			mDeviceStream = SDL3.SDL_CreateAudioStream(&srcSpec, &deviceSpec);
			if (mDeviceStream != null)
				SDL3.SDL_BindAudioStream(deviceId, mDeviceStream);
		}
	}

	/// Enables threaded mixing via SDL audio callback.
	/// After this call, SDL's audio thread drives Mix() — the main thread
	/// must not call Mix() directly.
	public void EnableCallbackMixing()
	{
		if (mDeviceStream == null)
			return;

		EnableThreading();

		// SDL calls our callback from its audio thread when the device needs more data.
		// additional_amount = bytes needed, total_amount = bytes already queued.
		SDL3.SDL_SetAudioStreamGetCallback(mDeviceStream, => AudioCallback, Internal.UnsafeCastToPtr(this));
	}

	/// Disables callback mixing. Main thread must call Mix() again.
	public void DisableCallbackMixing()
	{
		if (mDeviceStream != null)
			SDL3.SDL_SetAudioStreamGetCallback(mDeviceStream, null, null);
	}

	/// SDL audio callback — called from SDL's audio thread when the device needs samples.
	private static void AudioCallback(void* userdata, SDL_AudioStream* stream, int32 additionalAmount, int32 totalAmount)
	{
		let mixer = (SDL3AudioMixer)Internal.UnsafeCastToObject(userdata);
		if (mixer == null)
			return;

		// Only mix if the device actually needs more data
		if (additionalAmount <= 0)
			return;

		// Mix one buffer's worth. SDL will call us again if it needs more.
		mixer.Mix();
	}

	protected override void OutputMix(float* buffer, int32 frameCount, int32 sampleRate)
	{
		if (mDeviceStream == null)
			return;

		let sampleCount = frameCount * 2;

		// Convert float32 to int16 with clamping
		for (int i = 0; i < sampleCount; i++)
		{
			let clamped = Math.Clamp(buffer[i], -1.0f, 1.0f);
			mOutputBuffer[i] = (int16)(clamped * 32767.0f);
		}

		SDL3.SDL_PutAudioStreamData(mDeviceStream, mOutputBuffer, (.)sampleCount * 2);
	}

	public override void Dispose()
	{
		// Disable callback before any cleanup
		DisableCallbackMixing();

		if (mDeviceStream != null)
		{
			SDL3.SDL_UnbindAudioStream(mDeviceStream);
			SDL3.SDL_DestroyAudioStream(mDeviceStream);
			mDeviceStream = null;
		}

		if (mOutputBuffer != null)
		{
			delete mOutputBuffer;
			mOutputBuffer = null;
		}

		base.Dispose();
	}
}
