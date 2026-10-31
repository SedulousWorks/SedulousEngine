using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Http;
using Sedulous.Net;
using Sedulous.Net.Tls;

namespace Sedulous.Http.Client;

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
	}

	/// BORROWED: the application's, outliving the client.
	private ITlsBackend mTls;
	private TlsTrust mTrust;
	private String mTrustedPem = new .() ~ delete _;
	private Monitor mLock = new .() ~ delete _;
	/// Set when a job is queued or the client stops.
	private WaitEvent mWake = new .() ~ delete _;
	private List<Job> mQueue = new .() ~ DeleteContainerAndItems!(_);
	private List<Job> mDelivered = new .() ~ DeleteContainerAndItems!(_);
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
			for (int i < mDelivered.Count)
			{
				if (mDelivered[i].Id == id)
				{
					delete mDelivered[i];
					mDelivered.RemoveAt(i);
					mPending--;
					return;
				}
			}
		}
	}

	public void Pump()
	{
		let ready = scope List<Job>();
		using (mLock.Enter())
		{
			ready.AddRange(mDelivered);
			mDelivered.Clear();
			mPending -= ready.Count;
		}
		for (let job in ready)
		{
			if (job.Done != null)
				job.Done(job.Response);
			delete job;
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
			Run(job.Request, job.Response);
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
				mDelivered.Add(job);
			}
		}
	}

	private bool Cancelled()
	{
		using (mLock.Enter())
			return mCancelCurrent || mStopping;
	}

	/// One request to its end: each redirect a connection of its own.
	private void Run(HttpClientRequest request, HttpClientResponse response)
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
			if (!Exchange(at, method, request.Headers, body, request, clock, parser, response.Error))
				return;
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

	/// One connection: the request out, the response read into `parser`. False, `outError`
	/// saying why, when no whole response arrived.
	private bool Exchange(HttpUrl at, StringView method, List<HttpHeader> headers, List<uint8> body,
		HttpClientRequest request, Stopwatch clock, HttpMessageParser parser, String outError)
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
