using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Bosses
{
    /// <summary>
    /// One head of the Balaur, each carrying a power from the tale of Harap-Alb: frost like Gerilă, fire like
    /// the Red Emperor's red-hot copper house, and an endless thirst like Setilă, who drinks lakes dry.
    /// Cut it down and it falls to a stump that regrows unless seared with fire. Port of balaur_head.gd.
    /// Heads float on their necks: no physics body, moved directly.
    /// </summary>
    public class BalaurHead : EnemyBase
    {
        public Balaur body;
        public Vector2 anchor, rest;     // world space
        public string element = "fire";  // frost, fire, thirst
        public string hstate = "sway";
        public float ht, cd = 2f, regrowT;
        public Vector2 strikeFrom, strikeTo;
        public bool seared;
        int patches;
        public const float RegrowTime = 7f;

        public override void Setup(string k)
        {
            kind = "balaur_head";
            hp = maxHp = 170f;
            radius = 26f; dmg = 18f; coin = 0; aggro = 9999f;
            rb.bodyType = RigidbodyType2D.Kinematic;
            var col = GetComponent<Collider2D>();
            if (col != null) col.enabled = false;
            cd = Random.Range(1.5f, 3.5f);
        }

        public override bool Undead() => false;
        public override void SaltHit(Transform ring, float dt) { }

        public Color Tint() => element switch
        {
            "frost" => new Color(0.75f, 0.95f, 1f),
            "fire" => new Color(1f, 0.82f, 0.68f),
            _ => new Color(0.8f, 1f, 1f),
        };

        public bool CanSear => hstate == "stump" && !seared;

        public void Sear()
        {
            var gm = GameManager.I;
            if (!gm.player.torch) { HudEvents.Toast("You need fire to seal the neck."); return; }
            seared = true;
            hstate = "sealed";
            AudioManager.I?.Sfx("sear", -2f);
            FxUtil.Ring(Pos, new Color(1f, 0.6f, 0.2f, 0.9f), 70f, 0.6f);
            HudEvents.Toast("The stump hisses black. This head will not grow back.");
            body.HeadSealed(this);
        }

        public override void Hurt(float amount, Vector2 dir)
        {
            if (hstate is "stump" or "sealed" || body.intro) return;
            hp -= amount;
            flash = 0.1f;
            AudioManager.I?.Sfx("hit", -3f, 0.8f);
            FxUtil.Text(Pos + new Vector2(0, 30), Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            if (hp <= 0f) { hp = 0f; Sever(); }
        }

        void Sever()
        {
            hstate = "stump"; ht = 0f;
            regrowT = RegrowTime;
            transform.position = anchor + (rest - anchor) * 0.35f;
            AudioManager.I?.Sfx("boss_roar", -4f, 1.4f);
            FxUtil.Ring(Pos, new Color(0.5f, 0.8f, 0.3f, 0.9f), 90f, 0.5f);
            HudEvents.Toast("A head falls! Sear the stump before it grows back.");
        }

        void GrowBack()
        {
            hstate = "sway";
            hp = maxHp * 0.6f;
            cd = 1.5f;
            AudioManager.I?.Sfx("hiss", 0f, 0.8f);
            HudEvents.Toast("The head grows back!");
        }

        protected override void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; ht += dt;
            flash = Mathf.Max(0f, flash - dt);
            if (player == null) player = FindAnyObjectByType<Biertan.Player.PlayerController>();
            if (player == null || body == null) return;
            float rage = body.Rage();
            Vector2 pp = player.transform.position;
            Vector2 pos = transform.position;

            switch (hstate)
            {
                case "sway":
                {
                    Vector2 want = rest + Vector2.ClampMagnitude(pp - rest, 90f) + new Vector2(Mathf.Sin(t * 1.3f + anchor.x) * 26f, -Mathf.Cos(t * 1.1f) * 14f);
                    pos = Vector2.Lerp(pos, want, Mathf.Min(1f, dt * 3f));
                    face = (pp - pos).normalized;
                    if (!body.intro && !body.Gazing) cd -= dt * rage;
                    if (cd <= 0f && player.hp > 0f)
                    {
                        ht = 0f;
                        strikeFrom = pos;
                        if (element == "thirst") { hstate = "drink"; AudioManager.I?.Sfx("hiss", -2f, 0.6f); }
                        else if (element == "fire" && Random.value < 0.45f) { hstate = "skulls"; AudioManager.I?.Sfx("laugh", -6f, 1.6f); }
                        else
                        {
                            hstate = "tel";
                            strikeTo = anchor + Vector2.ClampMagnitude(pp - anchor, 560f);
                            AudioManager.I?.Sfx("hiss", -4f, Random.Range(0.9f, 1.2f));
                        }
                    }
                    break;
                }
                case "tel":
                    face = (strikeTo - pos).normalized;
                    pos = strikeFrom - face * 30f * Mathf.Min(1f, ht / 0.4f);
                    if (ht > 0.75f / rage) { hstate = "breath"; ht = 0f; patches = 0; AudioManager.I?.Sfx("fire", -2f, element == "frost" ? 0.8f : 1f); }
                    break;
                case "breath":
                {
                    int n = (int)(ht / 0.09f);
                    if (n < 7 && n >= patches)
                    {
                        patches = n + 1;
                        var go = PrefabRegistry.Spawn(PrefabRegistry.I?.firePatch, Vector2.Lerp(pos, strikeTo, (n + 1) / 7f));
                        if (go != null)
                        {
                            go.transform.SetParent(transform.parent, true);
                            if (go.TryGetComponent(out FirePatch fp)) fp.frost = element == "frost";
                        }
                        if (n == 6 && element == "frost" && Vector2.Distance(pp, strikeTo) < 60f && player.invT <= 0f)
                        {
                            player.rootT = 1f;
                            FxUtil.Text(pp + new Vector2(0, 50), "frozen", new Color32(0xcf, 0xe8, 0xff, 0xff));
                        }
                    }
                    if (ht > 0.7f) { hstate = "recoil"; ht = 0f; }
                    break;
                }
                case "drink":
                    // dip into the lake and drink; the current drags the hunter in
                    pos = Vector2.Lerp(pos, anchor + new Vector2(0, 20), Mathf.Min(1f, dt * 3f));
                    face = Vector2.up;
                    player.pull += (anchor - pp).normalized * 170f;
                    if (ht > 1.8f)
                    {
                        hstate = "spit"; ht = 0f;
                        pos = rest;
                        WaterWave.Spawn(transform.parent, rest);
                        AudioManager.I?.Sfx("dodge", 2f, 0.5f);
                        AudioManager.I?.Sfx("hiss", 0f, 0.5f);
                    }
                    break;
                case "skulls":
                    face = (pp - pos).normalized;
                    if (ht > 0.6f)
                    {
                        float a0 = Mathf.Atan2(face.y, face.x);
                        for (int i = 0; i < 2 + (int)rage; i++)
                        {
                            float a = Random.value * Mathf.PI * 2f;
                            var s = body.arena.SpawnEnemy("skull", pos + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 30f);
                            if (s != null) { float q = a0 + (i - 1) * 0.6f; s.face = new Vector2(Mathf.Cos(q), Mathf.Sin(q)); }
                        }
                        hstate = "recoil"; ht = 0f;
                    }
                    break;
                case "spit":
                    if (ht > 0.6f) { hstate = "recoil"; ht = 0f; }
                    break;
                case "recoil":
                    pos = Vector2.Lerp(pos, rest, Mathf.Min(1f, dt * 4f));
                    if (ht > 0.7f) { hstate = "sway"; cd = Random.Range(2f, 3.4f); }
                    break;
                case "stump":
                    regrowT -= dt;
                    if (regrowT <= 0f) GrowBack();
                    break;
            }
            transform.position = pos;
        }
    }

    /// <summary>The E-prompt on a severed neck: sear it with Konrad's torch so it never grows back.</summary>
    public class HeadStump : Interactable
    {
        public BalaurHead head;
        public override bool CanInteract() => head != null && head.CanSear;
        public override string PromptText() => GameManager.I.player.torch ? "E   Sear the stump with your torch" : "You have nothing to burn it with";
        public override void Interact() => head.Sear();
    }
}
