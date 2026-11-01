using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Http;
using Sedulous.Net;
using Sedulous.Net.Tls;

namespace Sedulous.Http.Client;

#if !BF_PLATFORM_WASM
/// The native HTTP client: requests on one worker thread; https through a TLS backend (none:
/// http only, an https request failing to say so), checked against the client's trust.
class NativeHttpClient : IHttpClient
{
	private class Job
	{
		public uint64 Id;
		public HttpClientRequest Request ~ delete _;
		public delegate void(HttpClientResponse response) Done ~ delete _;
		public HttpClientResponse Response ~ delete _;
		/// Its head and body go out as they arrive.
		public bool Streamed;
	}

	private enum DeliveryKind : uint8
	{
		Head,
		Body,
		Done,
	}

	/// What a Pump hands its caller: a streamed response's head or a piece of its body, or the end
	/// of a request.
	private class Delivery
	{
		public DeliveryKind Kind = .Done;
		public uint64 Id;
		/// Done: the request and its response, OWNED.
		public Job Job ~ delete _;
		/// Head: its status, headers and body length (-1 when not given).
		public int32 Status;
		public List<HttpHeader> Headers = new .() ~ DeleteContainerAndItems!(_);
		public int64 Length = -1;
		/// Body.
		public List<uint8> Piece = new .() ~ delete _;
	}

	/// A request's stream callbacks, kept on the caller's thread while it runs.
	private class Stream
	{
		public uint64 Id;
		public delegate void(int32 status, List<HttpHeader> headers, int64 length) OnHead ~ delete _;
		public delegate void(Span<uint8> piece) OnBody ~ delete _;
	}

	/// BORROWED: the application's, outliving the client.
	private ITlsBackend mTls;
	private TlsTrust mTrust;
	private String mTrustedPem = new .() ~ delete _;
	private Monitor mLock = new .() ~ delete _;
	/// Set when a job is queued or the client stops.
	private WaitEvent mWake = new .() ~ delete _;
	private List<Job> mQueue = new .() ~ DeleteContainerAndItems!(_);
	private List<Delivery> mDelivered = new .() ~ DeleteContainerAndItems!(_);
	/// The caller's thread's alone: Send, Cancel and Pump.
	private List<Stream> mStreams = new .() ~ DeleteContainerAndItems!(_);
	private List<uint64> mCancelledInPump = new .() ~ delete _;
	/// Streams removed during a Pump, deleted at its end: one may be the callback running.
	private List<Stream> mRetired = new .() ~ DeleteContainerAndItems!(_);
	private bool mPumping = false;
	private int mPending = 0;
	private uint64 mCurrent = 0;
	private bool mCancelCurrent = false;
	private bool mStopping = false;
	private uint64 mNextId = 0;
	private Thread mWorker;

	/// `tls` BORROWED, and null for http only. `trust` is what an https request checks against;
	/// Roots trusts `trustedPem` alone.
	public this(ITlsBackend tls, TlsTrust trust = .System, StringView trustedPem = default)
	{
		mTls = tls;
		mTrust = trust;
		mTrustedPem.Set(trustedPem);
		mWorker = new Thread(new => Work);
		mWorker.Start(false);
	}

	public ~this()
	{
		using (mLock.Enter())
		{
			mStopping = true;
			ClearAndDeleteItems!(mQueue);
		}
		mWake.Set(true);
		mWorker.Join();
		delete mWorker;
	}

	public uint64 Send(HttpClientRequest request, delegate void(HttpClientResponse response) done)
	{
		let job = new Job();
		job.Id = ++mNextId;
		job.Request = request;
		job.Done = done;
		if (request.Streamed)
		{
			// The callbacks stay on this thread; the worker only knows to stream.
			let stream = new Stream();
			stream.Id = job.Id;
			stream.OnHead = request.OnHead;
			stream.OnBody = request.OnBody;
			request.OnHead = null;
			request.OnBody = null;
			mStreams.Add(stream);
			job.Streamed = true;
		}
		using (mLock.Enter())
		{
			mQueue.Add(job);
			mPending++;
		}
		mWake.Set();
		return job.Id;
	}

	public void Cancel(uint64 id)
	{
		if (mPumping)
			mCancelledInPump.Add(id); // its deliveries this Pump already took go unheard
		RemoveStream(id);
		using (mLock.Enter())
		{
			for (int i < mQueue.Count)
			{
				if (mQueue[i].Id == id)
				{
					delete mQueue[i];
					mQueue.RemoveAt(i);
					mPending--;
					return;
				}
			}
			if (mCurrent == id)
				mCancelCurrent = true; // the worker drops it at its next step
			// Its head and pieces waiting for a Pump go too; its end, if it came, ends it.
			for (int i = mDelivered.Count - 1; i >= 0; i--)
			{
				if (mDelivered[i].Id != id)
					continue;
				if (mDelivered[i].Kind == .Done)
					mPending--;
				delete mDelivered[i];
				mDelivered.RemoveAt(i);
			}
		}
	}

	public void Pump()
	{
		let ready = scope List<Delivery>();
		using (mLock.Enter())
		{
			ready.AddRange(mDelivered);
			mDelivered.Clear();
			for (let d in ready)
			{
				if (d.Kind == .Done)
					mPending--;
			}
		}
		// In order: each stream's head, its pieces, then its end, after which its callbacks are
		// forgotten. A request a callback cancels (mCancelledInPump grows as they run) hears
		// nothing more.
		mPumping = true;
		for (let d in ready)
		{
			if (!mCancelledInPump.Contains(d.Id))
			{
				let stream = FindStream(d.Id);
				switch (d.Kind)
				{
				case .Head:
					if ((stream != null) && (stream.OnHead != null))
						stream.OnHead(d.Status, d.Headers, d.Length);
				case .Body:
					if ((stream != null) && (stream.OnBody != null))
						stream.OnBody(d.Piece);
				case .Done:
					if (d.Job.Done != null)
						d.Job.Done(d.Job.Response);
					RemoveStream(d.Id);
				}
			}
			delete d;
		}
		mPumping = false;
		mCancelledInPump.Clear();
		ClearAndDeleteItems!(mRetired);
	}

	private Stream FindStream(uint64 id)
	{
		for (let s in mStreams)
		{
			if (s.Id == id)
				return s;
		}
		return null;
	}

	private void RemoveStream(uint64 id)
	{
		for (int i < mStreams.Count)
		{
			if (mStreams[i].Id == id)
			{
				if (mPumping)
					mRetired.Add(mStreams[i]);
				else
					delete mStreams[i];
				mStreams.RemoveAt(i);
				return;
			}
		}
	}

	public int Pending
	{
		get
		{
			using (mLock.Enter())
				return mPending;
		}
	}

	private void Work()
	{
		while (true)
		{
			Job job = null;
			while (job == null)
			{
				using (mLock.Enter())
				{
					if (mStopping)
						return;
					if (!mQueue.IsEmpty)
					{
						job = mQueue.PopFront();
						mCurrent = job.Id;
						mCancelCurrent = false;
					}
				}
				if (job == null)
					mWake.WaitFor();
			}
			job.Response = new HttpClientResponse();
			Run(job.Id, job.Streamed, job.Request, job.Response);
			using (mLock.Enter())
			{
				let cancelled = mCancelCurrent;
				mCurrent = 0;
				mCancelCurrent = false;
				if (cancelled || mStopping)
				{
					if (cancelled)
						mPending--;
					delete job;
					continue;
				}
				let end = new Delivery();
				end.Id = job.Id;
				end.Job = job;
				mDelivered.Add(end);
			}
		}
	}

	/// Queues a streamed response's head or a piece of its body for the next Pump. TAKES
	/// OWNERSHIP of `d`.
	private void Post(Delivery d)
	{
		using (mLock.Enter())
		{
			if (!mCancelCurrent)
			{
				mDelivered.Add(d);
				return;
			}
		}
		delete d;
	}

	private bool Cancelled()
	{
		using (mLock.Enter())
			return mCancelCurrent || mStopping;
	}

	/// One request to its end: each redirect a connection of its own. A streamed request's final
	/// response goes out as it arrives (a redirect's own body is never streamed).
	private void Run(uint64 id, bool streamed, HttpClientRequest request, HttpClientResponse response)
	{
		let clock = scope Stopwatch()..Start();
		let url = scope String(request.Url);
		let method = scope String(request.Method);
		let body = scope List<uint8>();
		body.AddRange(request.Body);
		for (int32 hop = 0; ; hop++)
		{
			let at = scope:: HttpUrl();
			if (!at.Parse(url, response.Error))
				return;
			let parser = scope:: HttpMessageParser(.Response, request.MaxResponseBytes);
			if (HttpHeader.AsciiEqualsIgnoreCase(method, "HEAD"))
				parser.SetNoBody();
			bool headSent = false;
			delegate void(HttpMessageParser p) received = scope [&] (p) =>
				{
					if (!streamed || !p.HeadParsed || !Heard(p, request))
						return;
					if (!headSent)
					{
						headSent = true;
						let head = new Delivery();
						head.Kind = .Head;
						head.Id = id;
						head.Status = p.Status;
						for (let header in p.Headers)
							head.Headers.Add(new .(header.Name, header.Value));
						head.Length = p.BodyLength;
						Post(head);
					}
					let piece = new Delivery();
					piece.Kind = .Body;
					piece.Id = id;
					p.TakeBody(piece.Piece);
					if (piece.Piece.IsEmpty)
						delete piece;
					else
						Post(piece);
				};
			if (!Exchange(at, method, request.Headers, body, request, clock, parser, response.Error, received))
				return;
			received(parser); // the last of it
			let status = parser.Status;
			let location = HttpHeader.Find(parser.Headers, "Location");
			let redirect = (status == 301) || (status == 302) || (status == 303) || (status == 307) || (status == 308);
			if (redirect && (request.MaxRedirects > 0) && !location.IsEmpty)
			{
				if (hop >= request.MaxRedirects)
				{
					response.Error.AppendF("too many redirects (more than {})", request.MaxRedirects);
					return;
				}
				let next = at.Resolve(location, .. scope:: String());
				let nextAt = scope:: HttpUrl();
				if (nextAt.Parse(next, scope String()) && at.Secure && !nextAt.Secure)
				{
					response.Error.AppendF("an https request was redirected to http ({}): refused", next);
					return;
				}
				// 303, and 301/302 after a POST (as browsers do): the next request is a GET.
				if ((status == 303) || (((status == 301) || (status == 302)) && HttpHeader.AsciiEqualsIgnoreCase(method, "POST")))
				{
					method.Set("GET");
					body.Clear();
				}
				url.Set(next);
				continue;
			}
			response.Status = status;
			for (let header in parser.Headers)
				response.Headers.Add(new .(header.Name, header.Value));
			response.Body.AddRange(parser.Body);
			response.Url.Set(url);
			return;
		}
	}

	/// Whether this hop's response is the one the caller hears: not a redirect that will be
	/// followed.
	private static bool Heard(HttpMessageParser p, HttpClientRequest request)
	{
		let s = p.Status;
		let redirects = (s == 301) || (s == 302) || (s == 303) || (s == 307) || (s == 308);
		return !(redirects && (request.MaxRedirects > 0) && !HttpHeader.Find(p.Headers, "Location").IsEmpty);
	}

	/// One connection: the request out, the response read into `parser`. False, `outError`
	/// saying why, when no whole response arrived.
	private bool Exchange(HttpUrl at, StringView method, List<HttpHeader> headers, List<uint8> body,
		HttpClientRequest request, Stopwatch clock, HttpMessageParser parser, String outError,
		delegate void(HttpMessageParser p) received)
	{
		if (at.Secure && (mTls == null))
		{
			outError.Append("https needs a TLS backend, and this client has none");
			return false;
		}
		// A name that does not resolve leaves the socket closed; a refused connect is the
		// stream's to say ("the connection could not be made").
		let socket = TcpSocket.Connect(at.Host, at.Port);
		if (!socket.IsOpen)
		{
			delete socket;
			outError.AppendF("'{}' could not be found", at.Host);
			return false;
		}
		INetByteStream stream;
		if (at.Secure)
		{
			let config = scope TlsClientConfig();
			config.ServerName.Set(at.Host);
			config.Trust = mTrust;
			config.Roots.Pem.Set(mTrustedPem);
			config.Alpn.Add(new .("http/1.1"));
			stream = new TlsStream(socket, mTls.CreateClient(config));
		}
		else
			stream = new PlainStream(socket);
		defer delete stream;

		// The request: its line, Host, what this client always says, the caller's own.
		let head = scope String();
		head.AppendF("{} {} HTTP/1.1\r\n", method, at.Target);
		if (at.DefaultPort)
			head.AppendF("Host: {}\r\n", at.Host);
		else
			head.AppendF("Host: {}:{}\r\n", at.Host, at.Port);
		var userAgent = false;
		for (let h in headers)
			userAgent = userAgent || HttpHeader.AsciiEqualsIgnoreCase(h.Name, "User-Agent");
		if (!userAgent)
			head.Append("User-Agent: SedulousEngine\r\n");
		head.Append("Accept-Encoding: identity\r\nConnection: close\r\n");
		if (!body.IsEmpty || HttpHeader.AsciiEqualsIgnoreCase(method, "POST") || HttpHeader.AsciiEqualsIgnoreCase(method, "PUT")
			|| HttpHeader.AsciiEqualsIgnoreCase(method, "PATCH"))
			head.AppendF("Content-Length: {}\r\n", body.Count);
		for (let h in headers)
		{
			// The client's own.
			if (HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Host") || HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Content-Length")
				|| HttpHeader.AsciiEqualsIgnoreCase(h.Name, "Connection"))
				continue;
			head.AppendF("{}: {}\r\n", h.Name, h.Value);
		}
		head.Append("\r\n");
		let outgoing = scope List<uint8>();
		outgoing.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
		outgoing.AddRange(body);
		if (stream.Send(outgoing) < 0)
		{
			outError.Append("the connection closed before the request went");
			return false;
		}

		uint8[16 * 1024] buffer = ?;
		while (true)
		{
			if (Cancelled())
			{
				outError.Append("cancelled");
				return false;
			}
			if (clock.Elapsed.TotalSeconds > request.TimeoutSeconds)
			{
				outError.AppendF("timed out after {} s", request.TimeoutSeconds);
				return false;
			}
			let alive = stream.Pump();
			var moved = false;
			while (true)
			{
				let n = stream.Receive(.(&buffer[0], buffer.Count));
				if (n > 0)
				{
					moved = true;
					parser.Push(.(&buffer[0], (int)n));
					if (parser.State != .NeedMore)
						break;
					received(parser); // a streamed body goes out as it arrives
					continue;
				}
				if (n < 0)
					parser.OnPeerClosed();
				break;
			}
			if (parser.State == .Complete)
				return true;
			if (parser.State == .Failed)
			{
				if (parser.TooLarge)
					outError.AppendF("the response is larger than {} bytes", request.MaxResponseBytes);
				else
					outError.Append("the response could not be read (it ended early, or is not HTTP)");
				return false;
			}
			if (!alive)
			{
				let why = stream.Failure;
				if (why.IsEmpty)
					outError.Append("the connection closed before a response");
				else
					outError.Append(why);
				return false;
			}
			if (!moved)
				Thread.Sleep(1);
		}
	}
}
#endif
