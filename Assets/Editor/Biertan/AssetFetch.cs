using System.IO;
using System.Net.Http;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>Downloads third-party asset files (e.g. CC0 Poly Haven textures) straight into the project,
    /// using the editor's own network connection.</summary>
    public static class AssetFetch
    {
        static readonly HttpClient Http = new() { Timeout = System.TimeSpan.FromSeconds(120) };

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
