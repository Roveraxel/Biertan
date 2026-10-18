using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;
using Biertan.Levels;

namespace Biertan.Bosses
{
    /// <summary>
    /// Strigoi Vlad, the blood lord of Biertan: a long blood glaive with sweeping three-hit combos and a lunging
    /// thrust, spilled blood that erupts into bloodflame, and the Nihil rite: three cries that wrench blood from
    /// the hunter unless they stand in salt. From phase 2 he is mist; only the toll of the great bell drags him
    /// back into flesh. Port of vlad.gd (Unity coordinates).
    /// </summary>
    public class Vlad : EnemyBase, IBoss
    {
        public event System.Action<int> PhaseChanged;
        public const float Reach = 175f;

        public int phase = 1, combo, nihil;
        public string bstate = "intro";
        public float bt, poolT = 5f, dashT = 7f, boltT = 9f, blinkT = 12f, batT = 10f, rainT = 6f, vulnT, slowed;
        public Vector2 dashDir = Vector2.right;
        public ChurchOfBiertan arena;

        public Biertan.Player.PlayerController Player => player;
        public float Hp => hp;
        public float MaxHp => maxHp;

        public override void Setup(string k)
        {
            kind = "vlad";
            hp = maxHp = 900f;
            speed = 165f; dmg = 22f; radius = 26f; coin = 0; aggro = 9999f;
            var col = GetComponent<CircleCollider2D>();
            if (col != null) col.radius = radius;
            rb.mass = 30f;
        }

        public string HudName() => "STRIGOI VLAD, LORD OF BLOOD";
        public string HudHint()
        {
            if (bstate == "rite") return "NIHIL! Stand inside a ring of salt!";
            if (phase >= 2 && !Vulnerable()) return "He is mist. Ring the great bell (E)!";
            if (phase >= 3 && !(player != null && player.garlic)) return "His presence drinks your blood. Keep away, or wear garlic.";
            return "";
        }

        public override bool Undead() => true;
        public bool Vulnerable() => bstate != "rite" && (phase == 1 || vulnT > 0f);

        public override void SaltHit(Transform ring, float dt)
        {
            slowed = 0.4f;
            if (Vulnerable()) hp -= 6f * dt;
        }

        public void BellToll()
        {
            if (bstate == "rite") return;
            vulnT = 7f;
            bstate = "stunned"; bt = 0f;
            FxUtil.Ring(Pos, new Color(1f, 0.9f, 0.6f, 0.9f), 200f, 0.7f);
        }

        public override void Hurt(float amount, Vector2 dir)
        {
            if (bstate is "intro" or "blink" or "rite") return;
            if (!Vulnerable())
            {
                flash = 0.05f;
                FxUtil.Text(Pos + new Vector2(0, 70), "mist", new Color32(0xc8, 0xa0, 0xa8, 0xff));
                return;
            }
            hp -= amount;
            flash = 0.1f;
            knock = dir * 60f;
            FxUtil.Text(Pos + new Vector2(Random.Range(-20f, 20f), 60), ((int)amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            AudioManager.I?.Sfx("hit", -2f, 0.8f);
            if (hp <= 0f) { Die(); return; }
            float r = hp / maxHp;
            int np = r > 0.66f ? 1 : (r > 0.33f ? 2 : 3);
            if (np == phase) return;
            phase = np;
            vulnT = 0f;
            PhaseChanged?.Invoke(phase);
            FxUtil.Ring(Pos, new Color(0.8f, 0.1f, 0.1f, 0.9f), 240f, 0.9f);
            if (phase == 2) StartRite();
            else { bstate = "stalk"; bt = -0.6f; AudioManager.I?.Sfx("laugh", 0f, 0.9f); }
        }

        void StartRite()
        {
            bstate = "rite"; bt = 0f; nihil = 0;
            AudioManager.I?.Sfx("laugh", 0f, 0.75f);
        }

        protected override void Die()
        {
            AudioManager.I?.Sfx("boss_roar", 0f, 0.6f);
            for (int i = 0; i < 4; i++) FxUtil.Ring(Pos, new Color(1f, 0.3f, 0.25f, 0.9f), 100 + i * 80, 0.6f + i * 0.25f);
            base.Die();
        }

        protected override void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; bt += dt;
            flash = Mathf.Max(0f, flash - dt);
            atkCd = Mathf.Max(0f, atkCd - dt);
            vulnT = Mathf.Max(0f, vulnT - dt);
            slowed = Mathf.Max(0f, slowed - dt);
            if (player == null) player = FindAnyObjectByType<Biertan.Player.PlayerController>();
            if (player == null || player.hp <= 0f) { rb.linearVelocity = Vector2.zero; return; }
            Vector2 pp = player.transform.position;
            Vector2 to = pp - Pos;
            float d = to.magnitude;
            float sm = (1f + 0.15f * (phase - 1)) * (slowed > 0f ? 0.45f : 1f);
            Vector2 vel = Vector2.zero;

            switch (bstate)
            {
                case "intro":
                    face = to.normalized;
                    if (bt > 3f) { bstate = "stalk"; bt = 0f; AudioManager.I?.Sfx("laugh", -2f); }
                    break;
                case "stalk":
                    face = to.normalized;
                    vel = (d < Reach * 0.7f ? -face * speed * 0.3f : face * speed * sm) + knock;
                    if (d < Reach + 20f && atkCd <= 0f) { bstate = "tel"; bt = 0f; combo = 3; }
                    break;
                case "tel":
                    vel = knock;
                    if (combo == 3 || bt < 0.15f) face = to.normalized;
                    if (bt > (combo == 3 ? 0.5f : 0.32f) / sm)
                    {
                        bstate = "sweep"; bt = 0f;
                        AudioManager.I?.Sfx("swing", -1f, 0.6f);
                        if (combo == 1)
                        {
                            if (LevelBase.DistToSegment(pp, Pos, Pos + face * (Reach + 90f)) < 30f) player.Hurt(dmg * 1.3f, face);
                        }
                        else if (d < Reach + 10f && Vector2.Angle(face, to) < 65f) player.Hurt(dmg, face);
                    }
                    break;
                case "sweep":
                    vel = face * (combo == 1 ? 320f : 140f);
                    if (bt > 0.2f)
                    {
                        combo--;
                        bt = 0f;
                        if (combo > 0) bstate = "tel";
                        else { bstate = "stalk"; atkCd = 1.1f - 0.15f * phase; }
                    }
                    break;
                case "dash_tel":
                    vel = knock;
                    if (bt < 0.35f) { dashDir = to.normalized; face = dashDir; }
                    if (bt > 0.6f / sm) { bstate = "dash"; bt = 0f; hitDone = false; AudioManager.I?.Sfx("blink", -2f, 0.6f); }
                    break;
                case "dash":
                    vel = dashDir * 760f;
                    if (!hitDone && d < 70f) { hitDone = true; player.Hurt(dmg * 1.1f, dashDir); }
                    if (bt > 0.4f || (bt > 0.05f && touchingWall)) { bstate = "tel"; bt = 0f; combo = 1; face = to.normalized; }
                    break;
                case "cast":
                    vel = knock;
                    if (bt > 0.5f) { Shoot(pp); bstate = "stalk"; bt = 0f; }
                    break;
                case "pools":
                    vel = knock;
                    if (bt > 0.5f) { Spill(4 + phase, 170f, pp); bstate = "stalk"; bt = 0f; }
                    break;
                case "blink":
                    if (bt > 0.5f)
                    {
                        if (arena != null)
                        {
                            Vector2 np = pp - player.facing * 110f;
                            np = new Vector2(Mathf.Clamp(np.x, 140f, arena.size.x - 140f), Mathf.Clamp(np.y, -(arena.size.y - 140f), -200f));
                            transform.position = np; rb.position = np;
                        }
                        bstate = "tel"; bt = 0f; combo = 1;
                        face = (pp - Pos).normalized;
                        AudioManager.I?.Sfx("blink", -2f, 0.8f);
                    }
                    break;
                case "rite":
                    if (bt > 1.4f)
                    {
                        bt = 0f;
                        nihil++;
                        NihilCry(pp);
                        if (nihil >= 3) { bstate = "stalk"; bt = -0.5f; }
                    }
                    break;
                case "stunned":
                    vel = knock;
                    if (bt > 2f) { bstate = "stalk"; bt = 0f; }
                    break;
            }

            if (bstate == "stalk" && bt > 0f)
            {
                poolT -= dt; dashT -= dt; boltT -= dt; blinkT -= dt;
                if (poolT <= 0f) { poolT = 7f - phase; bstate = "pools"; bt = 0f; AudioManager.I?.Sfx("laugh", -10f, 1.2f); }
                else if (dashT <= 0f && d > 200f) { dashT = 6f - phase; bstate = "dash_tel"; bt = 0f; }
                else if (boltT <= 0f) { boltT = 8f - phase; bstate = "cast"; bt = 0f; }
                else if (blinkT <= 0f && phase >= 2)
                {
                    blinkT = 10f - phase; bstate = "blink"; bt = 0f;
                    AudioManager.I?.Sfx("blink", -2f, 1.2f); AudioManager.I?.Sfx("bat", -6f);
                }
                if (phase >= 3)
                {
                    batT -= dt; rainT -= dt;
                    if (batT <= 0f && arena != null) { batT = 14f; arena.CallBats(this); }
                    if (rainT <= 0f) { rainT = 6f; Spill(6, 320f, pp); }
                }
            }
            // phase 3: his presence drinks the hunter's blood
            if (phase >= 3 && bstate != "intro" && d < 190f && !player.garlic && player.invT <= 0f)
            {
                player.hp = Mathf.Max(1f, player.hp - 6f * dt);
                hp = Mathf.Min(maxHp, hp + 6f * dt);
            }
            knock = Vector2.MoveTowards(knock, Vector2.zero, 700f * dt);
            rb.linearVelocity = vel;
            touchingWall = false;
        }

        void NihilCry(Vector2 pp)
        {
            AudioManager.I?.Sfx("boss_roar", 0f, 0.5f + 0.1f * nihil);
            FxUtil.Ring(Pos, new Color(0.9f, 0.05f, 0.1f, 0.9f), 900f, 0.9f);
            HudEvents.Banner("NIHIL!", "");
            foreach (var r in SaltRing.All)
                if (r != null && r.Contains(pp))
                {
                    FxUtil.Text(pp + new Vector2(0, 40), "warded", new Color32(0xe8, 0xee, 0xff, 0xff));
                    return;
                }
            float amount = player.maxHp * 0.14f;
            player.invT = 0f;
            player.Hurt(amount, Vector2.zero);
            hp = Mathf.Min(maxHp, hp + amount);
        }

        void Spill(int n, float spread, Vector2 pp)
        {
            for (int i = 0; i < n; i++)
            {
                float a = Random.value * Mathf.PI * 2f;
                Vector2 off = i == 0 ? Vector2.zero : new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Random.Range(60f, spread);
                BloodGeyser.Spawn(transform.parent, pp + off, 16f + 3f * phase, 1.2f + i * 0.08f);
            }
        }

        void Shoot(Vector2 pp)
        {
            AudioManager.I?.Sfx("bolt", -2f);
            int n = 5 + phase * 2;
            float b = Mathf.Atan2(pp.y - Pos.y, pp.x - Pos.x);
            for (int i = 0; i < n; i++)
            {
                float a = b + (i - (n - 1) / 2f) * 0.16f;
                var dir = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                BloodBolt.Spawn(transform.parent, Pos + dir * 30f, dir * (360f + 50f * phase), 12f);
            }
        }
    }
}
