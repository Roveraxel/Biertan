using System.Collections.Concurrent;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>
    /// A small localhost receiver for short-lived download links (Mixamo's signed export links expire in five
    /// minutes). A page posts "url TAB project-path" lines to http://127.0.0.1:PORT/; each file is fetched at
    /// once. Only paths and sizes are logged. Started and stopped by hand from editor commands.
    /// </summary>
    public static class LinkReceiver
    {
        static HttpListener listener;
        static readonly HttpClient Http = new() { Timeout = System.TimeSpan.FromSeconds(900) };
        public static readonly ConcurrentQueue<string> Done = new();
        public static int Pending;

        public static string Start(int port = 17853)
        {
            if (listener != null) return "already running";
            listener = new HttpListener();
            listener.Prefixes.Add($"http://127.0.0.1:{port}/");
            listener.Prefixes.Add($"http://localhost:{port}/");
            listener.Start();
            Task.Run(Loop);
            return "listening on " + port;
        }

        public static string Stop()
        {
            if (listener == null) return "not running";
            listener.Stop(); listener.Close(); listener = null;
            return "stopped";
        }

        public static string Report()
        {
            var sb = new System.Text.StringBuilder($"pending {Pending}\n");
            foreach (var s in Done) sb.AppendLine(s);
            return sb.ToString();
        }

        static async Task Loop()
        {
            while (listener != null && listener.IsListening)
            {
                HttpListenerContext ctx;
                try { ctx = await listener.GetContextAsync(); } catch { return; }
                var res = ctx.Response;
                res.AddHeader("Access-Control-Allow-Origin", "*");
                res.AddHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
                res.AddHeader("Access-Control-Allow-Headers", "*");
                res.AddHeader("Access-Control-Allow-Private-Network", "true");
                res.AddHeader("Access-Control-Allow-Local-Network", "true");
                string body = null;
                if (ctx.Request.HttpMethod == "GET" && ctx.Request.QueryString["u"] != null)
                    body = ctx.Request.QueryString["u"] + "\t" + ctx.Request.QueryString["p"]; // a page that may not fetch localhost navigates here instead
                else if (ctx.Request.HttpMethod == "POST")
                    using (var r = new StreamReader(ctx.Request.InputStream)) body = await r.ReadToEndAsync();
                if (body != null)
                {
                    foreach (var line in body.Split('\n'))
                    {
                        var parts = line.Split('\t');
                        if (parts.Length < 2) continue;
                        string url = parts[0].Trim(), path = parts[1].Trim();
                        if (!(path.StartsWith("Assets/Resources/Models3D/") || path.StartsWith("_packs/")) || path.Contains("..") || !url.StartsWith("https://")) continue;
                        System.Threading.Interlocked.Increment(ref Pending);
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                var bytes = await Http.GetByteArrayAsync(url);
                                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                                File.WriteAllBytes(path, bytes);
                                Done.Enqueue($"{path}: {bytes.Length}");
                            }
                            catch (System.Exception e) { Done.Enqueue($"{path}: FAILED {e.GetType().Name}"); }
                            finally { System.Threading.Interlocked.Decrement(ref Pending); }
                        });
                    }
                }
                res.StatusCode = 200;
                if (ctx.Request.HttpMethod == "GET")
                {
                    var html = System.Text.Encoding.UTF8.GetBytes("<html><body style='font:16px sans-serif;background:#222;color:#ddd'>Biertan: download handed to Unity. You can close this tab.</body></html>");
                    res.ContentType = "text/html"; res.OutputStream.Write(html, 0, html.Length);
                }
                res.Close();
            }
        }
    }
}
