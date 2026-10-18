using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;
using Biertan.Levels;

namespace Biertan.Bosses
{
    /// <summary>
    /// Muma Pădurii, the Forest Mother. Bark-skinned hag who steals children to keep the wood young.
    /// Phase 2+: her bark is proof against steel unless salt burns it away; she splits into three
    /// sisters (only one real) and walks between hollow trees. Port of muma.gd.
    /// </summary>
    public class Muma : EnemyBase, IBoss
    {
        public event System.Action<int> PhaseChanged;

        public int phase = 1;
        public string bstate = "intro";
        public float bt, rootT = 4f, hopT = 10f, wispT = 8f, vulnT, alpha = 1f;
        public float brewT = 3f, weaveT = 7f, crowT = 9f;
        public Vector2 hopTo;
        public bool illusion;
        public HollowArena arena;

        public float Hp => hp;
        public float MaxHp => maxHp;

        public override void Setup(string k)
        {
            kind = "muma";
            hp = maxHp = 560f;
            speed = 88f; dmg = 15f; radius = 40f; coin = 80; aggro = 9999f;
            var col = GetComponent<CircleCollider2D>();
            if (col != null) col.radius = radius * 0.8f;
            rb.mass = 40f;
        }

        public string HudName() => "MUMA PĂDURII";
        public string HudHint() => phase >= 2 && !Vulnerable() ? "Her bark turns steel. Catch her in a ring of salt (R)." : "";

        public override bool Undead() => true; // salt finds her (muma.gd)

        public bool Vulnerable() => phase == 1 || vulnT > 0f;

        public override void SaltHit(Transform ring, float dt)
        {
            if (illusion) { Pop(false); return; }
            if (bstate is "intro" or "hide") return;
            var sr = ring.GetComponent<SaltRing>();
            if (sr != null && sr.spent) return;
            if (arena != null) arena.DispelIllusions();
            if (vulnT <= 0f)
            {
                if (sr != null) sr.spent = true;
                vulnT = 4.5f;
                bstate = "stunned"; bt = 0f;
                FxUtil.Ring(Pos, new Color(1, 1, 1, 0.9f), 140f, 0.6f);
                AudioManager.I?.Sfx("cackle", -2f, 0.7f);
                HudEvents.Toast("The salt burns her bark! Strike now!");
            }
        }

        /// <summary>An illusion struck or salted bursts into crows.</summary>
        public void Pop(bool crows = true)
        {
            AudioManager.I?.Sfx("cackle", -4f, 1.4f);
            FxUtil.Ring(Pos, new Color(0.3f, 0.3f, 0.3f, 0.9f), 80f, 0.5f);
            if (crows && arena != null)
            {
                for (int i = 0; i < 2; i++)
                {
                    var e = arena.SpawnEnemy("bat", Pos + new Vector2(Random.Range(-30f, 30f), 40f));
                    if (e != null) e.state = "chase";
                }
                HudEvents.Toast("Only an illusion! It bursts into crows.");
            }
            Destroy(gameObject);
        }

        public override void Hurt(float amount, Vector2 dir)
        {
            if (bstate is "intro" or "hide") return;
            if (illusion) { Pop(); return; }
            if (!Vulnerable())
            {
                flash = 0.05f;
                FxUtil.Text(Pos + new Vector2(0, 60), "bark", new Color32(0xa0, 0x8a, 0x60, 0xff));
                AudioManager.I?.Sfx("hit", -10f, 0.5f);
                return;
            }
            hp -= amount;
            flash = 0.1f;
            knock = dir * 70f;
            FxUtil.Text(Pos + new Vector2(Random.Range(-20f, 20f), 50), Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            AudioManager.I?.Sfx("hit", -2f, 0.7f);
            if (hp <= 0f) { Die(); return; }
            float r = hp / maxHp;
            int np = r > 0.66f ? 1 : (r > 0.33f ? 2 : 3);
            if (np != phase)
            {
                phase = np;
                vulnT = 0f;
                bstate = "walk"; bt = -1f;
                hopT = 2f;
                PhaseChanged?.Invoke(phase);
                FxUtil.Ring(Pos, new Color(0.5f, 0.9f, 0.3f, 0.9f), 220f, 0.8f);
            }
        }

        protected override void Die()
        {
            if (arena != null) arena.DispelIllusions();
            AudioManager.I?.Sfx("boss_roar", 0f, 1.3f);
            AudioManager.I?.Sfx("cackle", 0f, 0.6f);
            for (int i = 0; i < 3; i++)
                FxUtil.Ring(Pos, new Color(0.6f, 1f, 0.5f, 0.9f), 120 + i * 70, 0.7f + i * 0.2f);
            coin = 0;
            base.Die();
        }

        protected override void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; bt += dt;
            flash = Mathf.Max(0f, flash - dt);
            atkCd = Mathf.Max(0f, atkCd - dt);
            vulnT = Mathf.Max(0f, vulnT - dt);
            if (player == null) player = FindAnyObjectByType<Biertan.Player.PlayerController>();
            if (player == null || player.hp <= 0f) { rb.linearVelocity = Vector2.zero; return; }

            Vector2 to = (Vector2)player.transform.position - Pos;
            float d = to.magnitude;
            float sm = 1f + 0.2f * (phase - 1);
            Vector2 vel = knock;

            switch (bstate)
            {
                case "intro":
                    vel = Vector2.zero;
                    face = to.normalized;
                    if (bt > 2.8f) { bstate = "walk"; bt = 0f; }
                    break;
                case "walk":
                    face = to.normalized;
                    vel = face * speed * sm + knock;
                    if (d < 130f && atkCd <= 0f) { bstate = "sweep_tel"; bt = 0f; }
                    break;
                case "sweep_tel":
                    if (bt > 0.55f / sm)
                    {
                        bstate = "sweep"; bt = 0f;
                        if (d < 150f && Vector2.Angle(face, to) < 65f)
                            player.Hurt(dmg * (illusion ? 0.6f : 1.2f), face);
                        AudioManager.I?.Sfx("swing", 0f, 0.5f);
                    }
                    break;
                case "sweep":
                    if (bt > 0.35f) { bstate = "walk"; bt = 0f; atkCd = 1.3f; }
                    break;
                case "cast":
                    if (bt > 0.7f)
                    {
                        bstate = "walk"; bt = 0f;
                        if (arena != null && !illusion) arena.CastRoots(this);
                    }
                    break;
                case "hide":
                    vel = Vector2.zero;
                    alpha = Mathf.Max(0f, alpha - dt * 2f);
                    if (bt > 0.6f && Pos != hopTo)
                    {
                        rb.position = hopTo;
                        transform.position = hopTo;
                        if (!illusion && arena != null) arena.ShuffleSisters(this);
                    }
                    if (bt > 1.2f)
                    {
                        bstate = "walk"; bt = 0f;
                        AudioManager.I?.Sfx("cackle", -4f, Random.Range(0.9f, 1.15f));
                    }
                    break;
                case "stunned":
                    if (bt > 1.6f) { bstate = "walk"; bt = 0f; }
                    break;
            }
            if (bstate != "hide") alpha = Mathf.Min(1f, alpha + dt * 2f);

            if (illusion)
            {
                if (bstate == "walk" && bt > 0f)
                {
                    brewT -= dt;
                    if (brewT <= 0f) { brewT = Random.Range(4f, 6f); ThrowBrew(1); }
                }
            }
            else if (bstate == "walk" && bt > 0f)
            {
                brewT -= dt;
                if (brewT <= 0f) { brewT = 5f - phase * 0.7f; ThrowBrew(1 + phase); }
                weaveT -= dt;
                if (weaveT <= 0f && arena != null) { weaveT = 9f - phase; arena.Weave(this); }
                rootT -= dt;
                if (rootT <= 0f) { rootT = 6.5f - phase * 1.2f; bstate = "cast"; bt = 0f; }
                if (phase >= 2)
                {
                    hopT -= dt;
                    if (hopT <= 0f && arena != null && vulnT <= 0f)
                    {
                        hopT = 11f - phase;
                        hopTo = arena.HopSpot(Pos);
                        bstate = "hide"; bt = 0f;
                    }
                }
                if (phase >= 3)
                {
                    wispT -= dt;
                    if (wispT <= 0f && arena != null) { wispT = 11f; arena.CallWisps(this); }
                    crowT -= dt;
                    if (crowT <= 0f && arena != null) { crowT = 10f; arena.CallCrows(this); }
                }
            }
            knock = Vector2.MoveTowards(knock, Vector2.zero, 700f * dt);
            rb.linearVelocity = vel;
        }

        void ThrowBrew(int n)
        {
            AudioManager.I?.Sfx("hiss", -8f, 1.6f);
            for (int i = 0; i < n; i++)
            {
                float a = Random.value * Mathf.PI * 2f;
                Vector2 at = (Vector2)player.transform.position +
                             (i == 0 ? Vector2.zero : new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Random.Range(50f, 130f));
                var go = PrefabRegistry.Spawn(PrefabRegistry.I?.firePatch, at);
                if (go != null)
                {
                    go.GetComponent<FirePatch>().brew = true;
                    if (arena != null) go.transform.SetParent(arena.transform, true);
                }
            }
        }
    }
}
