using UnityEditor;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>Long sounds (music and ambient beds) stream from disk instead of sitting decompressed in
    /// memory; short effects decompress on load so they start without delay.</summary>
    public class AudioImportRules : AssetPostprocessor
    {
        void OnPreprocessAudio()
        {
            if (!assetPath.Contains("/Resources/Audio/")) return;
            var imp = (AudioImporter)assetImporter;
            string file = System.IO.Path.GetFileNameWithoutExtension(assetPath);
            bool longClip = file.StartsWith("music_") || file.StartsWith("amb_") || file == "iele_song";
            var s = imp.defaultSampleSettings;
            if (longClip)
            {
                s.loadType = AudioClipLoadType.Streaming;
                s.compressionFormat = AudioCompressionFormat.Vorbis;
                s.quality = 0.6f;
            }
            else
            {
                s.loadType = AudioClipLoadType.DecompressOnLoad;
            }
            imp.defaultSampleSettings = s;
        }
    }
}
