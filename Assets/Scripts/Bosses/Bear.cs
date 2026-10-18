using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Bosses
{
    /// <summary>
    /// The Bear of the Garden (Ursul din Grădina Ursului). In Ion Creangă's tale of Harap-Alb, the Spân sends
    /// the hero to fetch lettuce from the garden of a fearsome bear that no one has ever robbed and lived.
    /// An optional master, as hard as any on the road. Port of bear.gd.
    /// </summary>
    public class Bear : EnemyBase, IBoss
    {
        public event System.Action<int> PhaseChanged;

        public string bstate = "sleep";
        public float bt, roarT = 9f, chargeT = 5f, slamT = 7f;
        public int combo;
        public Vector2 chargeDir = Vector2.right;
        public bool enraged;

        public float Hp => hp;
        public float MaxHp => maxHp;

        public override void Setup(string k)
        {
            kind = "bear";
            hp = maxHp = 750f;
            speed = 150f; dmg = 24f; radius = 38f; coin = 0; aggro = 9999f;
            var col = GetComponent<CircleCollider2D>();
            if (col != null) col.radius = radius * 0.8f;
            rb.mass = 40f;
        }

        public string HudName() => "URSUL · THE BEAR OF THE GARDEN";
        public string HudHint() => bstate == "rear" ? "It rears up! Get out of the circle!" : enraged ? "Enraged. Its swipes come faster." : "";
        public override bool Undead() => false;
        public override void SaltHit(Transform ring, float dt) { }

        public void Wake()
        {
            if (bstate != "sleep") return;
            bstate = "intro"; bt = 0f;
            AudioManager.I?.Sfx("boss_roar", 2f, 0.55f);
        }

        public override void Hurt(float amount, Vector2 dir)
        {
            if (bstate == "sleep") Wake();
            if (bstate == "intro") return;
            hp -= amount;
            flash = 0.1f;
            knock = dir * 40f;
            FxUtil.Text(Pos + new Vector2(Random.Range(-20f, 20f), 70f), Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            AudioManager.I?.Sfx("hit", -2f, 0.6f);
            if (hp <= 0f) { Die(); return; }
            if (!enraged && hp < maxHp * 0.35f)
            {
                enraged = true;
                PhaseChanged?.Invoke(2);
                bstate = "roar"; bt = 0f; hitDone = false;
            }
        }

        protected override void Die()
        {
            AudioManager.I?.Sfx("boss_roar", 0f, 0.45f);
            for (int i = 0; i < 3; i++) FxUtil.Ring(Pos, new Color(0.9f, 0.7f, 0.4f, 0.9f), 120 + i * 70, 0.7f + i * 0.2f);
            base.Die();
        }

        protected override void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; bt += dt;
            flash = Mathf.Max(0f, flash - dt);
            atkCd = Mathf.Max(0f, atkCd - dt);
            if (player == null) player = FindAnyObjectByType<Biertan.Player.PlayerController>();
            if (player == null || player.hp <= 0f) { rb.linearVelocity = Vector2.zero; return; }
            Vector2 to = (Vector2)player.transform.position - Pos;
            float d = to.magnitude;
            float sm = enraged ? 1.3f : 1f;

            switch (bstate)
            {
                case "sleep":
                    velocity = Vector2.zero;
                    if (d < 220f) Wake();
                    break;
                case "intro":
                    velocity = Vector2.zero;
                    face = to.normalized;
                    if (bt > 1.6f) { bstate = "stalk"; bt = 0f; }
                    break;
                case "stalk":
                    face = to.normalized;
                    velocity = face * speed * sm + knock;
                    if (d < 130f && atkCd <= 0f) { bstate = "tel"; bt = 0f; combo = enraged ? 3 : 2; }
                    break;
                case "tel":
                    velocity = knock;
                    if (bt > 0.42f / sm)
                    {
                        bstate = "swipe"; bt = 0f;
                        AudioManager.I?.Sfx("swing", 0f, 0.5f);
                        if (d < 140f && Vector2.Angle(face, to) < 70f) player.Hurt(dmg, face);
                    }
                    break;
                case "swipe":
                    velocity = face * 160f;
                    if (bt > 0.22f)
                    {
                        combo--;
                        face = to.normalized;
                        if (combo > 0) { bstate = "tel"; bt = 0.15f; }
                        else { bstate = "stalk"; bt = 0f; atkCd = 1.2f / sm; }
                    }
                    break;
                case "charge_tel":
                    velocity = knock;
                    if (bt < 0.5f) { chargeDir = to.normalized; face = chargeDir; }
                    if (bt > 0.85f / sm) { bstate = "charge"; bt = 0f; hitDone = false; AudioManager.I?.Sfx("boss_roar", -4f, 0.8f); }
                    break;
                case "charge":
                    velocity = chargeDir * 640f * sm;
                    if (!hitDone && d < radius + 26f) { hitDone = true; player.Hurt(dmg * 1.3f, chargeDir); }
                    if (bt > 0.75f || touchingWall)
                    {
                        bool wall = touchingWall;
                        bstate = wall ? "dazed" : "stalk"; bt = 0f;
                        if (wall) FxUtil.Ring(Pos, new Color(0.7f, 0.6f, 0.4f, 0.8f), 90f, 0.4f);
                    }
                    break;
                case "dazed":
                    velocity = Vector2.zero;
                    if (bt > 1.4f) { bstate = "stalk"; bt = 0f; }
                    break;
                case "rear":
                    velocity = Vector2.zero;
                    if (bt > 0.9f / sm)
                    {
                        bstate = "stalk"; bt = -0.3f;
                        AudioManager.I?.Sfx("root", 2f, 0.6f);
                        if (d < 170f) player.Hurt(dmg * 1.4f, to.normalized);
                        var w = WaterWave.Spawn(transform.parent, Pos);
                        w.earth = true; w.dmg = 16f; w.speed = 380f; w.maxR = 520f;
                    }
                    break;
                case "roar":
                    velocity = Vector2.zero;
                    if (bt > 0.6f && !hitDone)
                    {
                        hitDone = true;
                        AudioManager.I?.Sfx("boss_roar", 4f, 0.5f);
                        FxUtil.Ring(Pos, new Color(1f, 0.9f, 0.7f, 0.7f), 320f, 0.6f);
                        if (d < 320f)
                        {
                            player.slowT = Mathf.Max(player.slowT, 1.6f);
                            HudEvents.Toast("The roar shakes your bones!");
                        }
                    }
                    if (bt > 1.1f) { hitDone = false; bstate = "throw"; bt = 0f; }
                    break;
                case "throw":
                    velocity = Vector2.zero;
                    if (bt > 0.4f) { ThrowHives(enraged ? 3 : 2); bstate = "stalk"; bt = 0f; }
                    break;
            }

            if (bstate == "stalk" && bt > 0f)
            {
                chargeT -= dt; slamT -= dt; roarT -= dt;
                if (chargeT <= 0f && d > 220f) { chargeT = 5f / sm; bstate = "charge_tel"; bt = 0f; }
                else if (slamT <= 0f && d < 200f) { slamT = 7f / sm; bstate = "rear"; bt = 0f; }
                else if (roarT <= 0f) { roarT = 13f / sm; bstate = "roar"; bt = 0f; hitDone = false; }
            }
            knock = Vector2.MoveTowards(knock, Vector2.zero, 600f * dt);
            rb.linearVelocity = velocity;
            touchingWall = false;
        }

        void ThrowHives(int n)
        {
            AudioManager.I?.Sfx("swing", 0f, 0.4f);
            for (int i = 0; i < n; i++)
            {
                float a = Random.value * Mathf.PI * 2f;
                Vector2 at = (Vector2)player.transform.position + (i == 0 ? Vector2.zero : new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Random.Range(70f, 150f));
                var go = PrefabRegistry.Spawn(PrefabRegistry.I?.firePatch, at);
                if (go != null && go.TryGetComponent(out FirePatch fp)) fp.bees = true;
            }
            HudEvents.Toast("It hurls wild beehives!");
        }
    }
}
