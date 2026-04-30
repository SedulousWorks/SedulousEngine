namespace Sedulous.Audio.SDL3;

using System;
using SDL3;
using Sedulous.Audio;

/// SDL3 audio mixer backend. Converts float32 stereo to int16 and pushes to SDL device.
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
