using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Enemies
{
    /// <summary>
    /// C# port of enemy.gd — every regular creature (wolf, pricolici, scarecrow, shade,
    /// iele, moroi, strigoi, fire skull, blood ward, bat). Bosses derive from this.
    ///
    /// Units: 1 Unity unit = 1 Godot pixel, so every speed/radius/range below is the
    /// original GDScript value. Vertical offsets are sign-flipped (Godot +Y is down).
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D))]
    public class EnemyBase : MonoBehaviour
    {
        public static readonly List<EnemyBase> All = new();
        public event System.Action<EnemyBase> Died;

        [Header("Stats")]
        public string kind = "wolf";
        public float hp = 20f, maxHp = 20f, speed = 140f, dmg = 8f, radius = 14f, aggro = 400f;
        public int coin = 3;

        [Header("Runtime")]
        public string state = "idle";
        public float t, atkCd, flash, salted, orbit;
        public float strikeT;   // > 0 while a bite or strike just landed (drawn as the attack animation)
        public Vector2 face = Vector2.right, knock, lungeDir, home;
        public bool hitDone;

        protected PlayerController player;
        protected Rigidbody2D rb;
        protected Vector2 velocity;
        static float songT; // shared across all Iele, as in the GDScript static var

        protected Vector2 Pos => transform.position;

        // ------------------------------------------------------------ setup

        public virtual void Setup(string k)
        {
            kind = k;
            switch (k)
            {
                case "wolf":      hp = 18; speed = 150; dmg = 7;  radius = 13; coin = 3;  aggro = 430; break;
                case "pricolici": hp = 46; speed = 118; dmg = 14; radius = 17; coin = 9;  aggro = 460; break;
                case "scarecrow": hp = 62; speed = 62;  dmg = 12; radius = 16; coin = 7;  aggro = 170; state = "dormant"; break;
                case "shade":     hp = 14; speed = 128; dmg = 6;  radius = 12; coin = 0;  aggro = 700; break;
                case "iele":      hp = 26; speed = 170; dmg = 9;  radius = 12; coin = 5;  aggro = 330; orbit = Random.value * Mathf.PI * 2f; break;
                case "moroi":     hp = 60; speed = 76;  dmg = 14; radius = 15; coin = 8;  aggro = 190; state = "dormant"; break;
                case "strigoi":   hp = 52; speed = 118; dmg = 12; radius = 14; coin = 9;  aggro = 380; break;
                case "skull":     hp = 8;  speed = 150; dmg = 14; radius = 12; coin = 0;  aggro = 9999; state = "chase"; break;
                case "ward":      hp = 90; speed = 0;   dmg = 0;  radius = 22; coin = 15; aggro = 520; break;
                case "bat":       hp = 6;  speed = 235; dmg = 4;  radius = 8;  coin = 1;  aggro = 380; orbit = Random.value * Mathf.PI * 2f; break;
            }
            maxHp = hp;
            var col = GetComponent<CircleCollider2D>();
            if (col != null) col.radius = radius * 0.8f;
        }

        /// <summary>Applies the chapter difficulty multipliers (level.gd spawn_enemy()).</summary>
        public void ApplyDifficulty(Vector2 mult)
        {
            hp *= mult.x; maxHp = hp; dmg *= mult.y;
        }

        protected virtual void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            rb.gravityScale = 0f;
            rb.freezeRotation = true;
            gameObject.layer = LayerMask.NameToLayer("Enemy"); // Godot layer 4; collides with World + Player
        }

        protected virtual void OnEnable() => All.Add(this);
        protected virtual void OnDisable() => All.Remove(this);

        // ------------------------------------------------------------ frame

        protected virtual void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt;
            flash = Mathf.Max(0f, flash - dt);
            atkCd = Mathf.Max(0f, atkCd - dt);
            strikeT = Mathf.Max(0f, strikeT - dt);
            if (player == null) player = FindAnyObjectByType<PlayerController>();
            if (player == null || player.hp <= 0f) { rb.linearVelocity = Vector2.zero; return; }

            Vector2 to = (Vector2)player.transform.position - Pos;
            float d = to.magnitude;
            float mult = 1f + 0.4f * (GameManager.I != null ? GameManager.I.dusk : 0f);
            salted = Mathf.Max(0f, salted - dt);

            if (Step(dt, to, d, mult)) { rb.linearVelocity = velocity; return; }

            switch (state)
            {
                case "dormant":
                case "idle":
                    velocity = knock;
                    if (d < aggro)
                    {
                        if ((kind == "moroi" || kind == "strigoi") && state == "dormant")
                        {
                            state = "rise"; t = 0f;
                            if (kind == "moroi") AudioManager.I?.Sfx("moroi", -4f, Random.Range(0.85f, 1.1f));
                            else AudioManager.I?.Sfx("shriek", -8f, Random.Range(0.8f, 0.95f));
                        }
                        else state = "chase";
                    }
                    break;
                case "rise":
                    velocity = Vector2.zero;
                    if (t > 0.8f) state = "chase";
                    break;
                case "chase":
                {
                    Vector2 dir = to.normalized;
                    face = dir;
                    if (kind == "pricolici" && d < 200f && atkCd <= 0f) { state = "windup"; t = 0f; }
                    else
                    {
                        velocity = dir * speed * mult + knock + Separation();
                        if (d < radius + 26f && atkCd <= 0f)
                        {
                            player.Hurt(dmg * mult, dir);
                            atkCd = 1f;
                            knock = -dir * 220f; // bounce off so it can't sit inside the hunter
                        }
                    }
                    break;
                }
                case "windup":
                    velocity = knock;
                    face = to.normalized;
                    if (t > 0.5f) { state = "lunge"; t = 0f; lungeDir = to.normalized; hitDone = false; strikeT = 0.5f; }
                    break;
                case "lunge":
                    velocity = lungeDir * 470f;
                    if (!hitDone && d < radius + 24f) { player.Hurt(dmg * mult, lungeDir); hitDone = true; }
                    if (t > 0.3f || touchingWall) { state = "chase"; atkCd = 1.5f; }
                    break;
            }
            knock = Vector2.MoveTowards(knock, Vector2.zero, 900f * dt);
            rb.linearVelocity = velocity;
            touchingWall = false;
        }

        /// <summary>Kind-specific behaviours. Return true if this frame was fully handled.</summary>
        protected virtual bool Step(float dt, Vector2 to, float d, float mult)
        {
            switch (kind)
            {
                case "skull": return SkullStep(dt, to, d);
                case "ward": return WardStep(d);
                case "bat": return BatStep(dt, to, d, mult);
                case "strigoi":
                    if (StrigoiStep(to, d, mult)) { knock = Vector2.MoveTowards(knock, Vector2.zero, 900f * dt); return true; }
                    return false;
                case "iele":
                    if (IeleStep(dt, to, d, mult)) { knock = Vector2.MoveTowards(knock, Vector2.zero, 900f * dt); return true; }
                    return false;
            }
            return false;
        }

        /// <summary>The unclean dead: burned by salt rings (salt_ring.gd checks this).</summary>
        public virtual bool Undead() => kind is "iele" or "moroi" or "shade" or "strigoi" or "skull";

        // A burning skull that homes on the hunter and bursts on contact.
        bool SkullStep(float dt, Vector2 to, float d)
        {
            face = Vector3.Slerp(face, to.normalized, Mathf.Min(1f, dt * 2.2f)).normalized;
            velocity = face * speed + knock;
            knock = Vector2.MoveTowards(knock, Vector2.zero, 900f * dt);
            if (d < 30f || t > 6f)
            {
                if (d < 40f) player.Hurt(dmg, face);
                PrefabRegistry.Spawn(PrefabRegistry.I?.firePatch, Pos);
                AudioManager.I?.Sfx("fire", -8f, 1.5f);
                Destroy(gameObject);
            }
            return true;
        }

        bool WardStep(float d)
        {
            velocity = Vector2.zero;
            if (d < aggro && atkCd <= 0f)
            {
                atkCd = 6f;
                var bat = PrefabRegistry.SpawnEnemy("bat", Pos + new Vector2(Random.Range(-30f, 30f), 40f));
                if (bat != null) bat.state = "chase";
            }
            return true;
        }

        // Bats: erratic swoops, nip and veer away.
        bool BatStep(float dt, Vector2 to, float d, float mult)
        {
            orbit += dt * 7f;
            if (state == "idle")
            {
                float a = orbit * 0.4f;
                velocity = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 40f;
                if (d < aggro) { state = "chase"; AudioManager.I?.Sfx("bat", -10f, Random.Range(0.9f, 1.3f)); }
                return true;
            }
            Vector2 dir = to.normalized;
            face = dir;
            Vector2 side = Vector2.Perpendicular(dir);
            if (state == "retreat")
            {
                velocity = -dir * speed * 0.8f + side * Mathf.Sin(orbit) * 120f;
                if (t > 0.8f) state = "chase";
                return true;
            }
            velocity = dir * speed * mult + side * Mathf.Sin(orbit) * 160f + knock;
            knock = Vector2.MoveTowards(knock, Vector2.zero, 900f * dt);
            if (d < radius + 22f && atkCd <= 0f)
            {
                player.Hurt(dmg * mult, dir);
                atkCd = 0.9f; state = "retreat"; t = 0f;
            }
            return true;
        }

        // Strigoi: stalk, crouch, then leap onto where the hunter stood.
        // Bites drink blood and heal the strigoi, unless the hunter wears garlic.
        bool StrigoiStep(Vector2 to, float d, float mult)
        {
            switch (state)
            {
                case "chase":
                    face = to.normalized;
                    velocity = face * speed * mult + knock + Separation();
                    if (d > 110f && d < 330f && atkCd <= 0f) { state = "crouch"; t = 0f; home = player.transform.position; }
                    else if (d < radius + 26f && atkCd <= 0f) Bite(face, mult);
                    return true;
                case "crouch":
                    velocity = knock;
                    if (t > 0.55f)
                    {
                        state = "leap"; t = 0f; lungeDir = Pos;
                        AudioManager.I?.Sfx("shriek", -6f, Random.Range(0.95f, 1.2f));
                    }
                    return true;
                case "leap":
                {
                    float k = Mathf.Clamp01(t / 0.45f);
                    velocity = Vector2.zero;
                    rb.MovePosition(Vector2.Lerp(lungeDir, home, k));
                    if (k >= 1f)
                    {
                        state = "chase"; atkCd = 2f;
                        FxUtil.Ring(Pos, new Color(0.6f, 0.1f, 0.1f, 0.7f), 60f, 0.35f);
                        if (Vector2.Distance(player.transform.position, Pos) < 62f)
                            Bite(((Vector2)player.transform.position - Pos).normalized, mult);
                    }
                    return true;
                }
            }
            return false;
        }

        void Bite(Vector2 dir, float mult)
        {
            bool garlic = player.garlic;
            float amount = dmg * mult * (garlic ? 0.5f : 1f);
            player.Hurt(amount, dir);
            atkCd = 1.1f;
            strikeT = 0.5f;
            if (!garlic)
            {
                hp = Mathf.Min(maxHp, hp + amount * 0.5f);
                FxUtil.Text(Pos + new Vector2(0, 40), "drinks", new Color32(0xc0, 0x39, 0x2b, 0xff));
            }
        }

        // Iele: dance around their fairy ring, then circle the hunter, sing to
        // slow and draw them in, and dart in for a strike.
        bool IeleStep(float dt, Vector2 to, float d, float mult)
        {
            if (state is "windup" or "lunge") return false;
            if (state == "idle")
            {
                orbit += dt * 1.3f;
                Vector2 target = home + Dir(orbit) * 70f;
                velocity = (target - Pos) * 3f + knock;
                face = Dir(orbit + Mathf.PI / 2f);
                if (d < aggro)
                {
                    state = "chase";
                    if (songT <= 0f)
                    {
                        AudioManager.I?.Sfx("iele_song", -6f, Random.Range(0.95f, 1.05f));
                        songT = 4.5f;
                        HudEvents.Toast("The Iele sing. Your legs grow heavy...");
                    }
                }
                return true;
            }
            songT = Mathf.Max(0f, songT - dt / 3f);
            orbit += dt * 1.5f;
            Vector2 tgt = (Vector2)player.transform.position + Dir(orbit) * 135f;
            face = to.normalized;
            velocity = Vector2.ClampMagnitude(tgt - Pos, speed * mult) + knock + Separation();
            if (salted > 0f) velocity = -to.normalized * speed + knock;
            if (d < 290f && salted <= 0f && !player.wormwood)
            {
                player.slowT = Mathf.Max(player.slowT, 0.15f);
                player.pull += -to.normalized * 55f;
            }
            if (songT <= 0f && d < 300f)
            {
                songT = 4.5f;
                AudioManager.I?.Sfx("iele_song", -9f, Random.Range(0.9f, 1.1f));
            }
            if (d < 210f && atkCd <= 0f && salted <= 0f) { state = "windup"; t = 0.15f; }
            if (d > aggro * 2.2f) state = "idle";
            return true;
        }

        protected static Vector2 Dir(float angle) => new(Mathf.Cos(angle), Mathf.Sin(angle));

        protected Vector2 Separation()
        {
            Vector2 push = Vector2.zero;
            foreach (var o in All)
            {
                if (o == this) continue;
                Vector2 dv = Pos - o.Pos;
                float dl = dv.magnitude;
                if (dl < 32f && dl > 0.1f) push += dv / dl * (32f - dl) * 5f;
            }
            return push;
        }

        // ------------------------------------------------------------ damage

        public virtual void SaltHit(Transform ring, float dt)
        {
            float burn = kind == "moroi" ? 16f : 11f;
            hp -= burn * dt;
            flash = 0.05f;
            knock = (Pos - (Vector2)ring.position).normalized * 260f;
            if (salted <= 0f)
            {
                FxUtil.Text(Pos + new Vector2(0, 30), "salt!", new Color32(0xe8, 0xee, 0xff, 0xff));
                if (state == "dormant") state = "chase";
            }
            salted = 0.6f;
            if (hp <= 0f) Die();
        }

        public virtual void Hurt(float amount, Vector2 dir)
        {
            hp -= amount;
            flash = 0.12f;
            knock = dir * 280f;
            AudioManager.I?.Sfx("hit", -5f);
            if (state is "dormant" or "idle") state = "chase";
            FxUtil.Text(Pos, Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0xe0, 0x8a, 0xff));
            if (hp <= 0f) Die();
        }

        protected virtual void Die()
        {
            Died?.Invoke(this);
            if (coin > 0 && player != null)
            {
                player.coins += coin;
                AudioManager.I?.Sfx("coin", -12f);
                FxUtil.Text(Pos + new Vector2(0, 16), $"+{coin}", FxUtil.Amber);
            }
            FxUtil.Ring(Pos, new Color(0.8f, 0.8f, 0.9f, 0.8f), 40f);
            Destroy(gameObject);
        }

        protected bool touchingWall;
        void OnCollisionStay2D(Collision2D c)
        {
            if (c.gameObject.layer == LayerMask.NameToLayer("World")) touchingWall = true;
        }
    }
}
