using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>
    /// C# port of g.gd's sound()/music helpers. Looks up clips from Resources/Audio
    /// by name (matching the Godot project's sfx/music naming: "bell", "music_hub", ...).
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager I { get; private set; }

        public AudioSource sfxSource;
        public AudioSource musicSource;

        readonly Dictionary<string, AudioClip> cache = new();

        void Awake()
        {
            if (I != null && I != this) { Destroy(gameObject); return; }
            I = this;
        }

        AudioClip Load(string name)
        {
            if (cache.TryGetValue(name, out var c)) return c;
            // Audio/SFX/<name>.ogg and Audio/Music/<name>.ogg, imported under Resources/Audio/
            var clip = Resources.Load<AudioClip>($"Audio/{name}");
            cache[name] = clip;
            if (clip == null) Debug.LogWarning($"AudioManager: missing clip '{name}'");
            return clip;
        }

        /// <param name="db">Volume offset in decibels (matches Godot's linear_to_db usage).</param>
        /// <param name="pitch">Pitch/playback-speed multiplier.</param>
        public void Sfx(string name, float db = 0f, float pitch = 1f)
        {
            var clip = Load(name);
            if (clip == null || sfxSource == null) return;
            sfxSource.pitch = pitch;
            sfxSource.PlayOneShot(clip, DbToLinear(db));
        }

        public void SetMusic(string name, float db = 0f)
        {
            var clip = Load(name);
            if (clip == null || musicSource == null) return;
            if (musicSource.clip == clip && musicSource.isPlaying) { musicSource.volume = DbToLinear(db); return; }
            musicSource.clip = clip;
            musicSource.loop = true;
            musicSource.volume = DbToLinear(db);
            musicSource.Play();
        }

        static float DbToLinear(float db) => Mathf.Pow(10f, db / 20f);
    }
}
