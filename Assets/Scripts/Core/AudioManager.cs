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
        readonly Dictionary<string, AudioClip[]> variants = new();
        float stepT;

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
            var set = Variants(name);
            if (set.Length == 0 || sfxSource == null) return;
            var clip = set[Random.Range(0, set.Length)];
            // recorded sounds with several takes also vary their pitch a touch, so repeats don't sound canned
            sfxSource.pitch = set.Length > 1 ? pitch * Random.Range(0.94f, 1.06f) : pitch;
            sfxSource.PlayOneShot(clip, DbToLinear(db));
        }

        /// <summary>A sound and its other takes: name, name_2, name_3 ... (e.g. hit, hit_2, hit_3).</summary>
        AudioClip[] Variants(string name)
        {
            if (variants.TryGetValue(name, out var v)) return v;
            var list = new List<AudioClip>();
            var first = Load(name);
            if (first != null) list.Add(first);
            for (int i = 2; i <= 8; i++)
            {
                var c = Resources.Load<AudioClip>($"Audio/{name}_{i}");
                if (c == null) break;
                list.Add(c);
            }
            return variants[name] = list.ToArray();
        }

        /// <summary>Footsteps while the hunter walks: cobbles and stone in the villages, caves and the church,
        /// grass and leaves out on the land.</summary>
        void Update()
        {
            var gm = GameManager.I;
            var p = gm != null ? gm.player : null;
            if (p == null || gm.state != GameManager.State.Play) return;
            var rb = p.GetComponent<Rigidbody2D>();
            float speed = rb != null ? rb.linearVelocity.magnitude : 0f;
            if (speed < 60f) { stepT = 0.05f; return; }
            stepT -= Time.deltaTime * Mathf.Clamp(speed / 200f, 0.6f, 1.6f);
            if (stepT > 0f) return;
            stepT = 0.34f;
            string surface = gm.current switch
            {
                "hub" or "richis" or "mosna" or "biertan" or "caves" or "gorge" or "church" => "step_concrete",
                _ => "step_grass",
            };
            Sfx(surface, -15f);
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
