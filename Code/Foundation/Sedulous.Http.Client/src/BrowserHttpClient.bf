using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Http;

namespace Sedulous.Http.Client;

#if BF_PLATFORM_WASM
/// The browser client: the browser's fetch (emscripten's, over XMLHttpRequest), which does TLS,
/// redirects and certificates itself. Without pthreads its callbacks run on this thread between
/// frames; each finished request waits for Pump, as the native client's do. There the response's
/// Url is the URL asked for, MaxRedirects is the browser's, and a cross-origin request needs the
/// server's CORS headers (without them it fails, and the browser does not say why). The browser
/// hands a body over whole, so a streamed request hears its head and one piece together, just
/// before its end.
class BrowserHttpClient : IHttpClient
{
	private class Flight
	{
		public BrowserHttpClient Owner;
		public uint64 Id;
		/// Its body and headers live as long as the fetch.
		public HttpClientRequest Request ~ delete _;
		public delegate void(HttpClientResponse response) Done ~ delete _;
		public HttpClientResponse Response ~ delete _;
		public Stopwatch Clock = new .() ~ delete _;
		public List<String> HeaderText = new .() ~ DeleteContainerAndItems!(_);
		public List<char8*> HeaderPointers = new .() ~ delete _;
		public EmscriptenFetch.Fetch* Fetch = null;
		/// Answered or cancelled: later callbacks are ignored.
		public bool Finished = false;
	}

	/// In flight, OWNED.
	private List<Flight> mFlights = new .() ~ DeleteContainerAndItems!(_);
	/// Answered, waiting for Pump, OWNED.
	private List<Flight> mDelivered = new .() ~ DeleteContainerAndItems!(_);
	private List<uint64> mCancelledInPump = new .() ~ delete _;
	private bool mPumping = false;
	private uint64 mNextId = 0;

	public ~this()
	{
		for (let f in mFlights)
			Abort(f);
	}

	public uint64 Send(HttpClientRequest request, delegate void(HttpClientResponse response) done)
	{
		let f = new Flight();
		f.Owner = this;
		f.Id = ++mNextId;
		f.Request = request;
		f.Done = done;
		f.Clock.Start();
		let id = f.Id;

		let at = scope HttpUrl();
		let error = scope String();
		if (!at.Parse(request.Url, error))
		{
			f.Finished = true;
			Answer(f, error);
			mDelivered.Add(f);
			return id;
		}

		EmscriptenFetch.Attributes attributes = default;
		EmscriptenFetch.emscripten_fetch_attr_init(&attributes);
		let length = Math.Min(request.Method.Length, attributes.RequestMethod.Count - 1);
		for (int i < length)
			attributes.RequestMethod[i] = request.Method[i];
		attributes.RequestMethod[length] = '\0';
		attributes.UserData = Internal.UnsafeCastToPtr(f);
		attributes.Attributes = EmscriptenFetch.LoadToMemory;
		attributes.TimeoutMSecs = (uint32)(request.TimeoutSeconds * 1000.0f);
		attributes.OnSuccess = => OnDone;
		attributes.OnError = => OnDone;
		// The caller's headers, less those a browser sets itself and refuses from a page.
		for (let h in request.Headers)
		{
			if (HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Host") || HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Content-Length")
				|| HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Connection") || HttpHeader.AsciiEqualsIgnoreCase(h.Name, "User-Agent")
				|| HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Accept-Encoding"))
				continue;
			f.HeaderText.Add(new .(h.Name));
			f.HeaderText.Add(new .(h.Value));
		}
		for (let text in f.HeaderText)
			f.HeaderPointers.Add(text.CStr());
		f.HeaderPointers.Add(null);
		attributes.RequestHeaders = f.HeaderPointers.Ptr;
		if (!request.Body.IsEmpty)
		{
			attributes.RequestData = (char8*)request.Body.Ptr;
			attributes.RequestDataSize = (uint)request.Body.Count;
		}
		mFlights.Add(f);
		let fetch = EmscriptenFetch.emscripten_fetch(&attributes, request.Url.CStr());
		// A callback may already have answered it (and moved it on): look it up again.
		for (let live in mFlights)
		{
			if ((live.Id == id) && !live.Finished)
			{
				live.Fetch = fetch;
				if (fetch == null)
				{
					live.Finished = true;
					Answer(live, "the browser refused the request");
					Finish(live);
				}
				break;
			}
		}
		return id;
	}

	public void Cancel(uint64 id)
	{
		if (mPumping)
			mCancelledInPump.Add(id); // its delivery this Pump already took goes unheard
		for (int i < mFlights.Count)
		{
			if (mFlights[i].Id == id)
			{
				let f = mFlights[i];
				Abort(f);
				mFlights.RemoveAt(i);
				delete f;
				return;
			}
		}
		for (int i < mDelivered.Count)
		{
			if (mDelivered[i].Id == id)
			{
				delete mDelivered[i];
				mDelivered.RemoveAt(i);
				return;
			}
		}
	}

	public void Pump()
	{
		let ready = scope List<Flight>();
		ready.AddRange(mDelivered);
		mDelivered.Clear();
		// A request a callback cancels (mCancelledInPump grows as they run) hears nothing more.
		mPumping = true;
		for (let f in ready)
		{
			let request = f.Request;
			let response = f.Response;
			if (request.Streamed && response.Ok)
			{
				if (request.OnHead != null)
					request.OnHead(response.Status, response.Headers, response.Body.Count);
				if (!response.Body.IsEmpty && (request.OnBody != null) && !mCancelledInPump.Contains(f.Id))
					request.OnBody(response.Body);
				response.Body.Clear(); // a streamed response keeps no body
			}
			if ((f.Done != null) && !mCancelledInPump.Contains(f.Id))
				f.Done(response);
			delete f;
		}
		mPumping = false;
		mCancelledInPump.Clear();
	}

	public int Pending => mFlights.Count + mDelivered.Count;

	/// A failed answer saying `why`.
	private static void Answer(Flight f, StringView why)
	{
		f.Response = new HttpClientResponse();
		f.Response.Error.Set(why);
	}

	/// A fetch still running is closed, its error callback (called by the close) ignored.
	private static void Abort(Flight f)
	{
		if (f.Finished)
			return;
		f.Finished = true;
		if (f.Fetch != null)
			EmscriptenFetch.emscripten_fetch_close(f.Fetch);
		f.Fetch = null;
	}

	private static void OnDone(EmscriptenFetch.Fetch* fetch)
	{
		let f = (Flight)Internal.UnsafeCastToObject(fetch.UserData);
		if (f.Finished)
			return; // the close of a cancelled or answered fetch
		f.Finished = true;
		f.Response = new HttpClientResponse();
		Read(f, fetch, f.Response);
		f.Fetch = null;
		EmscriptenFetch.emscripten_fetch_close(fetch); // may call back here: ignored above, f still alive
		f.Owner.Finish(f);
	}

	private static void Read(Flight f, EmscriptenFetch.Fetch* fetch, HttpClientResponse r)
	{
		let request = f.Request;
		// A status of nought is no response: the network, a timeout, or a cross-origin refusal
		// (CORS; the browser keeps the reason from the page).
		if (fetch.Status == 0)
		{
			let elapsed = (float)f.Clock.Elapsed.TotalSeconds;
			if (elapsed >= request.TimeoutSeconds - 0.05f)
				r.Error.AppendF("timed out after {} s", request.TimeoutSeconds);
			else
				r.Error.Append("the request failed (the network, or a cross-origin request the server's CORS headers do not allow)");
			return;
		}
		if (fetch.NumBytes > (uint64)request.MaxResponseBytes)
		{
			r.Error.AppendF("the response is larger than {} bytes", request.MaxResponseBytes);
			return;
		}
		r.Status = fetch.Status;
		r.Url.Set(request.Url);
		r.Body.AddRange(Span<uint8>((uint8*)fetch.Data, (int)fetch.NumBytes));
		let length = EmscriptenFetch.emscripten_fetch_get_response_headers_length(fetch);
		if (length == 0)
			return;
		let text = scope char8[(int)length + 1];
		EmscriptenFetch.emscripten_fetch_get_response_headers(fetch, text.Ptr, length + 1);
		let pairs = EmscriptenFetch.emscripten_fetch_unpack_response_headers(text.Ptr);
		for (var p = pairs; (p != null) && (p[0] != null) && (p[1] != null); p += 2)
		{
			var value = StringView(p[1]);
			value.Trim();
			r.Headers.Add(new .(StringView(p[0]), value));
		}
		EmscriptenFetch.emscripten_fetch_free_unpacked_response_headers(pairs);
	}

	/// The answer queued for Pump, the flight no longer in flight.
	private void Finish(Flight f)
	{
		mFlights.Remove(f);
		mDelivered.Add(f);
	}
}
#endif
