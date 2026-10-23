using System.IO;
using System.Net.Http;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>Downloads third-party asset files (e.g. CC0 Poly Haven textures) straight into the project,
    /// using the editor's own network connection.</summary>
    public static class AssetFetch
    {
        static readonly HttpClient Http = MakeClient();

        static HttpClient MakeClient()
        {
            var c = new HttpClient { Timeout = System.TimeSpan.FromSeconds(120) };
            // some open-data services (e.g. OpenStreetMap's Overpass API) refuse requests without one
            c.DefaultRequestHeaders.UserAgent.ParseAdd("BiertanGame/1.0 (Unity editor asset fetch)");
            return c;
        }

        /// <summary>Downloads every "url&lt;TAB&gt;path" line of a list file; returns a short report.</summary>
        public static string DownloadList(string listFile)
        {
            var sb = new System.Text.StringBuilder();
            foreach (var line in File.ReadAllLines(listFile))
            {
                var parts = line.Split('\t');
                if (parts.Length < 2 || line.StartsWith("#")) continue;
                long n = Download(parts[0].Trim(), parts[1].Trim());
                sb.AppendLine($"{parts[1].Trim()}: {n}");
            }
            return sb.ToString();
        }

        /// <summary>Fetches url into path (relative to the project root). Returns the size in bytes, or -1.</summary>
        public static long Download(string url, string path)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                var bytes = Http.GetByteArrayAsync(url).GetAwaiter().GetResult();
                File.WriteAllBytes(path, bytes);
                return bytes.Length;
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"AssetFetch: {url} failed: {e.Message}");
                return -1;
            }
        }
    }
}
