using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;
using Biertan.Levels;

namespace Biertan.Bosses
{
    /// <summary>
    /// The Vârcolac, after Romanian folklore: a lean, hound-like creature "born of the air". It climbs
    /// threads spun by women working at night without a candle and bites the moon, which bleeds red
    /// during an eclipse. When it gorges it grows heavy, the threads snap and it falls. Fire and noise
    /// drive it off. Port of boss.gd.
    /// </summary>
    public class Varcolac : EnemyBase, IBoss
    {
        public event System.Action<int> PhaseChanged;

        public int phase = 1;
        public string bstate = "intro";
        public float bt, howlT = 7f, swallowT = 6f, howlAnim;
        public Vector2 chargeDir = Vector2.right;
        public int eaten;
        public MoonClearing arena;

        public float Hp => hp;
        public float MaxHp => maxHp;

        public override void Setup(string k)
        {
            kind = "varcolac";
            hp = maxHp = 360f;
            speed = 105f; dmg = 16f; radius = 44f; coin = 60; aggro = 9999f;
            var col = GetComponent<CircleCollider2D>();
            if (col != null) col.radius = radius * 0.8f;
            rb.mass = 30f;
        }

        public string HudName() => "THE VÂRCOLAC, EATER OF THE MOON";

        public string HudHint()
        {
            if (bstate == "fallen") return "Its threads have snapped! Strike while it lies on the ground!";
            if (phase >= 2 && !Vulnerable()) return "It rides its threads in the dark. Strike it only near a lit fire.";
            return "";
        }

        public void Gorge()
        {
            eaten++;
            if (eaten < 3) return;
            eaten = 0;
            bstate = "fallen"; bt = 0f;
            AudioManager.I?.Sfx("boss_roar", 0f, 1.3f);
            FxUtil.Ring(Pos, new Color(0.9f, 0.85f, 0.7f, 0.9f), 160f, 0.6f);
            HudEvents.Toast("Gorged on flame, it grows heavy. Its threads snap and it falls!");
        }

        public bool Vulnerable()
        {
            if (phase == 1 || bstate == "fallen") return true;
            foreach (var b in Brazier.All)
                if (b.lit && Vector2.Distance(b.transform.position, Pos) < 260f) return true;
            return false;
        }

        public override void Hurt(float amount, Vector2 dir)
        {
            if (bstate == "intro") return;
            if (!Vulnerable())
            {
                flash = 0.05f;
                FxUtil.Text(Pos + new Vector2(0, 50), "shadow", new Color32(0x8a, 0x8a, 0xa8, 0xff));
                return;
            }
            hp -= amount;
            flash = 0.1f;
            knock = dir * 90f;
            FxUtil.Text(Pos + new Vector2(Random.Range(-20f, 20f), 40), Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            AudioManager.I?.Sfx("hit", -2f, 0.75f);
            if (hp <= 0f) { Die(); return; }
            float r = hp / maxHp;
            int np = r > 0.66f ? 1 : (r > 0.33f ? 2 : 3);
            if (np != phase)
            {
                phase = np;
                bstate = "recover"; bt = -0.8f;
                PhaseChanged?.Invoke(phase);
                FxUtil.Ring(Pos, new Color(0.9f, 0.3f, 0.3f, 0.9f), 220f, 0.8f);
            }
        }

        public override void SaltHit(Transform ring, float dt) { } // salt means nothing to a creature of the air

        protected override void Die()
        {
            AudioManager.I?.Sfx("boss_roar", 0f, 0.9f);
            for (int i = 0; i < 3; i++)
                FxUtil.Ring(Pos, new Color(1f, 0.8f, 0.5f, 0.9f), 120f + i * 60f, 0.7f + i * 0.2f);
            coin = 0; // the reward comes from GameManager.OnBossDead
            base.Die();
        }

        protected override void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt;
            flash = Mathf.Max(0f, flash - dt);
            atkCd = Mathf.Max(0f, atkCd - dt);
            howlAnim = Mathf.Max(0f, howlAnim - dt);
            if (player == null) player = FindAnyObjectByType<Biertan.Player.PlayerController>();
            if (player == null || player.hp <= 0f) { rb.linearVelocity = Vector2.zero; return; }

            bt += dt;
            Vector2 to = (Vector2)player.transform.position - Pos;
            float d = to.magnitude;
            float sm = 1f + 0.25f * (phase - 1);

            switch (bstate)
            {
                case "intro":
                    velocity = Vector2.zero;
                    face = to.normalized;
                    if (bt > 2.5f) { bstate = "stalk"; bt = 0f; }
                    break;
                case "stalk":
                    face = to.normalized;
                    velocity = face * speed * sm + knock;
                    if (d < radius + 34f && atkCd <= 0f) { player.Hurt(dmg, face); atkCd = 1.1f; }
                    if (bt > 2.4f / sm) { bstate = "telegraph"; bt = 0f; chargeDir = face; }
                    break;
                case "telegraph":
                    velocity = knock;
                    if (bt < 0.45f) chargeDir = to.normalized;
                    face = chargeDir;
                    if (bt > 0.8f / sm) { bstate = "charge"; bt = 0f; hitDone = false; }
                    break;
                case "charge":
                    velocity = chargeDir * 560f * sm;
                    if (!hitDone && d < radius + 16f) { player.Hurt(dmg * 1.4f, chargeDir); hitDone = true; }
                    if (bt > 0.7f || touchingWall)
                    {
                        bstate = "recover"; bt = 0f;
                        FxUtil.Ring(Pos, new Color(0.6f, 0.5f, 0.4f, 0.6f), 110f, 0.5f);
                    }
                    break;
                case "recover":
                    velocity = knock;
                    if (bt > 0.9f / sm) { bstate = "stalk"; bt = 0f; }
                    break;
                case "fallen":
                    velocity = knock;
                    if (bt > 5f) { bstate = "stalk"; bt = 0f; }
                    break;
            }

            if (bstate != "intro")
            {
                howlT -= dt;
                if (howlT <= 0f && bstate is "stalk" or "recover")
                {
                    howlT = 12f - 2f * phase;
                    if (arena != null) arena.BossHowl(this);
                }
                if (phase >= 3)
                {
                    swallowT -= dt;
                    if (swallowT <= 0f)
                    {
                        swallowT = 7f;
                        if (arena != null) arena.SwallowLight(this);
                    }
                }
            }
            knock = Vector2.MoveTowards(knock, Vector2.zero, 700f * dt);
            rb.linearVelocity = velocity;
            touchingWall = false;
        }
    }
}
