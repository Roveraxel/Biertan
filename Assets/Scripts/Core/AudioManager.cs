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

        // music crossfades between two players; an ambient bed (wind, cave drip) loops underneath
        AudioSource musicB, amb;
        float musicTarget = 1f, ambTarget;
        string ambName = "";
        const float Fade = 1.6f;

        // creature cries play through a small pool so each can sit left or right of the hunter
        readonly List<AudioSource> pool = new();
        float vocalT;

        void Awake()
        {
            if (I != null && I != this) { Destroy(gameObject); return; }
            I = this;
            musicB = NewSource(true);
            amb = NewSource(true);
            for (int i = 0; i < 6; i++) pool.Add(NewSource(false));
        }

        AudioSource NewSource(bool loop)
        {
            var a = gameObject.AddComponent<AudioSource>();
            a.playOnAwake = false; a.loop = loop; a.spatialBlend = 0f; a.volume = 0f;
            if (sfxSource != null) a.outputAudioMixerGroup = sfxSource.outputAudioMixerGroup;
            return a;
        }

        AudioClip Load(string name)
        {
            if (cache.TryGetValue(name, out var c)) return c;
            // Audio/SFX/<name>.ogg and Audio/Music/<name>.ogg, imported under Resources/Audio/
            // Romanian folk recordings (Audio/Folk) take the place of the older score where present
            var clip = Resources.Load<AudioClip>($"Audio/Folk/{name}") ?? Resources.Load<AudioClip>($"Audio/{name}");
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

        /// <summary>A sound heard from somewhere in the world: quieter with distance from the hunter and panned
        /// toward the side it comes from. Silent past about 900 units.</summary>
        public void SfxAt(string name, Vector2 at, float db = 0f, float pitch = 1f)
        {
            var p = GameManager.I != null ? GameManager.I.player : null;
            if (p == null) { Sfx(name, db, pitch); return; }
            Vector2 d = at - (Vector2)p.transform.position;
            float dist = d.magnitude;
            if (dist > 900f) return;
            var set = Variants(name);
            if (set.Length == 0) return;
            AudioSource src = null;
            foreach (var a in pool) if (!a.isPlaying) { src = a; break; }
            if (src == null) return; // already crowded: let this cry go
            float fall = Mathf.Clamp01(1f - (dist - 150f) / 750f);
            src.clip = set[Random.Range(0, set.Length)];
            src.pitch = pitch * Random.Range(0.94f, 1.06f);
            src.panStereo = Mathf.Clamp(d.x / 450f, -0.8f, 0.8f);
            src.volume = DbToLinear(db) * fall * fall;
            src.Play();
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
            float k = Time.unscaledDeltaTime / Fade;
            if (musicSource != null) musicSource.volume = Mathf.MoveTowards(musicSource.volume, musicTarget, k * Mathf.Max(musicTarget, 0.3f));
            if (musicB != null) { musicB.volume = Mathf.MoveTowards(musicB.volume, 0f, k * 0.6f); if (musicB.isPlaying && musicB.volume <= 0f) musicB.Stop(); }
            if (amb != null) amb.volume = Mathf.MoveTowards(amb.volume, ambTarget, k * 0.5f);
            UpdateAmbient();
            UpdateVocals();
            UpdateNightCalls();

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
                "hub" or "richis" or "mosna" or "biertan" or "sighisoara" or "caves" or "gorge" or "church" => "step_concrete",
                _ => "step_grass",
            };
            Sfx(surface, -15f);
        }

        public void SetMusic(string name, float db = 0f)
        {
            var clip = Load(name);
            if (clip == null || musicSource == null) return;
            musicTarget = DbToLinear(db);
            if (musicSource.clip == clip && musicSource.isPlaying) return;
            // the old tune hands over to a second player and fades out while the new one fades in
            if (musicSource.isPlaying && musicB != null)
            {
                musicB.clip = musicSource.clip; musicB.timeSamples = musicSource.timeSamples;
                musicB.volume = musicSource.volume; musicB.Play();
            }
            musicSource.clip = clip;
            musicSource.loop = true;
            musicSource.volume = 0f;
            musicSource.Play();
        }

        /// <summary>The bed of sound under the music: dripping stone underground, wind everywhere else.</summary>
        void UpdateAmbient()
        {
            var gm = GameManager.I;
            string want = ""; float db = -60f;
            if (gm != null && gm.state is GameManager.State.Play or GameManager.State.Dialogue)
            {
                switch (gm.current)
                {
                    case "caves": case "gorge": want = "amb_cave"; db = -14f; break;
                    case "church": want = "amb_cave"; db = -20f; break;
                    case "hub": case "richis": case "mosna": case "biertan": case "sighisoara": want = "amb_wind"; db = -24f; break;
                    case "forest": want = "amb_woods"; db = -12f; break;
                    case "": break;
                    default: want = "amb_night"; db = -16f; break;
                }
            }
            if (want != ambName)
            {
                // fade the old bed down before swapping it
                ambTarget = 0f;
                if (amb.volume > 0.01f && amb.isPlaying) return;
                ambName = want;
                amb.Stop();
                if (want == "") return;
                amb.clip = Load(want);
                if (amb.clip == null) return;
                amb.Play();
            }
            ambTarget = want == "" ? 0f : DbToLinear(db);
        }

        /// <summary>Hunting creatures now and then give voice: wolves snarl and howl, the strigoi hisses,
        /// the pricolici growls. Heard from where they are.</summary>
        void UpdateVocals()
        {
            var gm = GameManager.I;
            if (gm == null || gm.state != GameManager.State.Play) return;
            vocalT -= Time.deltaTime;
            if (vocalT > 0f) return;
            vocalT = 0.5f;
            foreach (var e in Biertan.Enemies.EnemyBase.All)
            {
                if (e == null || e.hp <= 0f || e.state is "idle" or "dormant") continue;
                if (Random.value > 0.06f) continue; // about one cry every eight seconds each
                Vocal(e, false);
            }
        }

        /// <summary>Now and then an owl or a crow calls from somewhere out in the dark, wherever the sky is open.</summary>
        float nightT = 8f;
        void UpdateNightCalls()
        {
            var gm = GameManager.I;
            if (gm == null || gm.player == null || gm.state != GameManager.State.Play) return;
            if (gm.current is "" or "caves" or "gorge" or "church") return;
            nightT -= Time.deltaTime;
            if (nightT > 0f) return;
            nightT = Random.Range(12f, 30f);
            Vector2 at = (Vector2)gm.player.transform.position + Random.insideUnitCircle.normalized * Random.Range(350f, 700f);
            float r = Random.value;
            if (r < 0.55f) SfxAt("owl", at, -8f, Random.Range(0.95f, 1.05f));
            else if (r < 0.85f) SfxAt("crow", at, -10f, Random.Range(0.9f, 1.1f));
            else SfxAt("owl_shriek", at, -12f);
        }

        /// <summary>A creature's cry; first=true when it has just caught the hunter's scent.</summary>
        public void Vocal(Biertan.Enemies.EnemyBase e, bool first)
        {
            Vector2 at = e.transform.position;
            switch (e.kind)
            {
                case "wolf":
                    if (first && Random.value < 0.5f) SfxAt("howl", at, -10f, Random.Range(0.95f, 1.15f));
                    else SfxAt("growl", at, -8f, Random.Range(0.9f, 1.1f));
                    break;
                case "pricolici": SfxAt(first ? "roar_wolf" : "growl", at, first ? -6f : -5f, first ? 0.9f : Random.Range(0.7f, 0.8f)); break;
                case "strigoi": SfxAt("hiss", at, -9f, Random.Range(0.8f, 0.95f)); break;
                case "moroi": SfxAt("whisper", at, -10f, Random.Range(0.85f, 1f)); break;
            }
        }

        static float DbToLinear(float db) => Mathf.Pow(10f, db / 20f);
    }
}
