using UnityEngine;
using Biertan.Enemies;
using Biertan.Levels;
using Biertan.Player;

namespace Biertan.Visual3D
{
    /// <summary>
    /// Painted folk-horror figures (Resources/Sprites/Folk) standing in the 3D world in place of an actor's
    /// small body sprite. Each painting is a single pose, so the life comes from procedural motion: a
    /// breathing sway at rest, a stepping bob while walking, a lunge on a strike, a flinch when hurt and a
    /// fall on death. Actors without a painting keep their old sprite.
    /// </summary>
    public static class FolkFigures
    {
        public struct Art { public Sprite sprite; public float height; public int facing; } // facing: +1 drawn looking right

        static Art Load(string name, float height, int facing)
        {
            var s = Resources.Load<Sprite>("Sprites/Folk/" + name);
            return new Art { sprite = s, height = height, facing = facing };
        }

        public static Art? For(Transform t)
        {
            Art a;
            if (t.GetComponent<PlayerController>() != null) a = Load("hunter", 1.9f, 1);
            else if (t.GetComponent<EnemyBase>() is EnemyBase e)
            {
                switch (e.kind)
                {
                    case "strigoi": a = Load("strigoi", 1.85f, -1); break;
                    case "pricolici": a = Load("pricolici", 2.05f, -1); break;
                    default: return null;
                }
            }
            else if (t.GetComponent<Prop>() is Prop p && p.kind == "npc" && p.id is "magda" or "veta" or "sofia" or "katharina" or "rozalia")
                a = Load("woman", 1.7f, -1);
            else return null;
            return a.sprite != null ? a : null;
        }

        /// <summary>Which way the actor looks along the screen's x axis (+1 right, -1 left, 0 unknown).</summary>
        public static float Facing(Transform t, Vector2 vel)
        {
            if (Mathf.Abs(vel.x) > 0.3f) return Mathf.Sign(vel.x);
            if (t.GetComponent<PlayerController>() is PlayerController p && Mathf.Abs(p.facing.x) > 0.05f) return Mathf.Sign(p.facing.x);
            if (t.GetComponent<EnemyBase>() is EnemyBase e && Mathf.Abs(e.face.x) > 0.05f) return Mathf.Sign(e.face.x);
            return 0f;
        }

        /// <summary>Procedural motion for a painted figure: returns a local offset (metres), a lean (degrees
        /// about the board's z) and a scale (x, y) for this frame.</summary>
        public static void Motion(Transform t, float speed, float time, float seed, float dir,
                                  out Vector3 offset, out float lean, out Vector2 scale)
        {
            offset = Vector3.zero; lean = 0f; scale = Vector2.one;
            float ph = time + seed * 7.3f;
            if (speed > 0.25f)
            {
                // stepping: a bob on each footfall and a lean into the walk
                float step = time * Mathf.Lerp(7f, 11f, Mathf.Clamp01(speed / 4f)) + seed * 5f;
                offset.y = Mathf.Abs(Mathf.Sin(step)) * 0.06f;
                lean = -dir * Mathf.Clamp(speed * 2.2f, 0f, 8f) + Mathf.Sin(step) * 2f;
                scale = new Vector2(1f + 0.02f * Mathf.Sin(step * 2f), 1f - 0.02f * Mathf.Sin(step * 2f));
            }
            else
            {
                // at rest: breathing and a slow sway
                scale = new Vector2(1f, 1f + 0.012f * Mathf.Sin(ph * 2.1f));
                lean = Mathf.Sin(ph * 0.9f) * 1.2f;
            }

            if (t.GetComponent<PlayerController>() is PlayerController p)
            {
                if (p.attackT > 0f)
                {
                    float k = Mathf.Sin(Mathf.Clamp01(1f - p.attackT / 0.18f) * Mathf.PI); // in and back out
                    offset.x += dir * 0.25f * k; lean += -dir * 14f * k; scale = new Vector2(1f + 0.06f * k, 1f - 0.04f * k);
                }
                if (p.dodgeT > 0f) { lean += -dir * 25f; offset.y -= 0.15f; scale = new Vector2(1.1f, 0.8f); }
                if (p.hurtFlash > 0f) { lean += dir * 10f * Mathf.Clamp01(p.hurtFlash * 4f); }
                if (p.hp <= 0f) { lean = dir * 80f; offset.y = -0.1f; }
            }
            else if (t.GetComponent<EnemyBase>() is EnemyBase e)
            {
                if (e.state is "windup") { lean += dir * 8f; scale = new Vector2(0.96f, 1.04f); }
                if (e.state is "lunge" or "leap") { offset.x += dir * 0.2f; lean += -dir * 16f; scale = new Vector2(1.08f, 0.94f); }
                if (e.flash > 0f) { lean += dir * 12f * Mathf.Clamp01(e.flash * 5f); offset.x -= dir * 0.05f; }
                if (e.state is "dormant") { scale = new Vector2(1f, 0.9f); lean = -6f; }
            }
        }
    }
}
