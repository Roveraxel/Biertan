using System;
using UnityEngine;
using Biertan.Enemies;
using Biertan.Levels;

namespace Biertan.Core
{
    /// <summary>
    /// Base class every level script derives from. Port of level.gd: level metadata plus the
    /// builder helpers the GDScript levels used (ground, scattered tufts, trees, walls, sprites).
    ///
    /// Coordinates: the Godot levels were laid out with +Y down from a top-left origin. P() converts
    /// those numbers to Unity world space (+Y up), so layouts can be copied from the .gd files as-is.
    /// </summary>
    public abstract class LevelBase : MonoBehaviour
    {
        [Header("Level")]
        public string title = "";
        public string subtitle = "";
        public Vector2 size = new(2000, 1400);   // Godot pixels
        public Vector2 spawn;                    // Unity world position
        public Color ground = new Color32(0x1c, 0x24, 0x18, 0xff);
        protected System.Random rng = new(1);

        /// <summary>Create the level's contents. Called once by the loader before the player arrives.</summary>
        public virtual void Build() { }

        /// <summary>Called every time the player enters (after Build on first entry).</summary>
        public virtual void OnEnter() { }

        public virtual Color Ambient() => Lights.Dusk(GameManager.I != null ? GameManager.I.dusk : 0.3f);

        public virtual EnemyBase SpawnEnemy(string kind, Vector2 pos)
        {
            var e = PrefabRegistry.SpawnEnemy(kind, pos);
            if (e != null) e.transform.SetParent(transform, true);
            return e;
        }

        // ------------------------------------------------------------ coordinates

        public static Vector2 P(Vector2 godot) => new(godot.x, -godot.y);
        public static Vector2 P(float x, float y) => new(x, -y);

        protected float Rand(float a, float b) => a + (float)rng.NextDouble() * (b - a);

        // ------------------------------------------------------------ builders

        static Sprite LoadSprite(string name) => Resources.Load<Sprite>("Sprites/" + name);

        /// <summary>Adds a sprite. For the utility sprites ("white", "circle") <paramref name="scale"/> is the
        /// size in units; for character art pass Vector2.one.</summary>
        public SpriteRenderer AddSprite(string name, string sprite, Vector2 pos, Vector2 scale, Color color, int order, Transform parent = null)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent != null ? parent : transform, false);
            go.transform.position = pos;
            go.transform.localScale = new Vector3(scale.x, scale.y, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = LoadSprite(sprite);
            sr.color = color;
            sr.sortingOrder = order;
            return sr;
        }

        protected void DrawGround()
        {
            AddSprite("Ground", "white", P(size.x / 2f, size.y / 2f), size, ground, -1000);
        }

        /// <summary>Scatter flattened blots of colour over a Godot-space rect (grass, moss, dirt).</summary>
        protected void Scatter(Rect godotRect, int count, Color[] colors)
        {
            var parent = new GameObject("Scatter").transform;
            parent.SetParent(transform, false);
            for (int i = 0; i < count; i++)
            {
                var c = colors[rng.Next(colors.Length)];
                float s = Rand(6f, 22f);
                var at = P(Rand(godotRect.xMin, godotRect.xMax), Rand(godotRect.yMin, godotRect.yMax));
                AddSprite("Tuft", "circle", at, new Vector2(s, s * 0.55f), c, -990, parent);
            }
        }

        /// <summary>Solid box wall (World layer). Position and size in Unity units.</summary>
        public GameObject AddWall(Vector2 center, Vector2 wallSize, Color? color = null, int order = 0)
        {
            var sr = AddSprite("Wall", "white", center, wallSize, color ?? new Color(0.25f, 0.23f, 0.21f), order);
            sr.gameObject.layer = LayerMask.NameToLayer("World");
            sr.gameObject.AddComponent<BoxCollider2D>();
            sr.gameObject.isStatic = true;
            if (color == null) sr.enabled = false; // invisible boundary unless a colour is given
            return sr.gameObject;
        }

        /// <summary>A circle of invisible wall segments keeping the fight inside an arena.</summary>
        protected void AddRingWall(Vector2 center, float radius, int segments = 48)
        {
            var parent = new GameObject("RingWall").transform;
            parent.SetParent(transform, false);
            float seg = 2f * Mathf.PI * radius / segments * 1.15f;
            for (int i = 0; i < segments; i++)
            {
                float a = i * Mathf.PI * 2f / segments;
                var go = new GameObject("Seg") { layer = LayerMask.NameToLayer("World") };
                go.transform.SetParent(parent, false);
                go.transform.position = center + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * (radius + 20f);
                go.transform.rotation = Quaternion.Euler(0, 0, a * Mathf.Rad2Deg);
                var box = go.AddComponent<BoxCollider2D>();
                box.size = new Vector2(40f, seg);
                go.isStatic = true;
            }
        }

        /// <summary>A pine/oak: trunk collider plus a dark crown. Port of tree2d.gd (simplified).</summary>
        protected void AddTree(Vector2 pos, bool big = false)
        {
            float s = big ? 1.35f : 1f;
            var root = new GameObject("Tree");
            root.transform.SetParent(transform, false);
            root.transform.position = pos;
            root.AddComponent<UnityEngine.Rendering.SortingGroup>();
            AddSprite("Shadow", "circle", pos + new Vector2(0, -2), new Vector2(70, 26) * s, new Color(0, 0, 0, 0.35f), -1, root.transform);
            AddSprite("Trunk", "white", pos + new Vector2(0, 18 * s), new Vector2(12, 36) * s, new Color32(0x3a, 0x2a, 0x1c, 0xff), 0, root.transform);
            var shade = Rand(0f, 0.06f);
            AddSprite("Crown", "circle", pos + new Vector2(0, 70 * s), new Vector2(84, 96) * s, new Color(0.09f + shade, 0.15f + shade, 0.09f), 1, root.transform);
            AddSprite("CrownTop", "circle", pos + new Vector2(-6, 92 * s), new Vector2(52, 58) * s, new Color(0.13f + shade, 0.21f + shade, 0.12f), 2, root.transform);
            root.layer = LayerMask.NameToLayer("World");
            var col = root.AddComponent<CircleCollider2D>();
            col.radius = 10f * s;
            col.offset = new Vector2(0, 4);
            root.isStatic = true;
        }

        // ------------------------------------------------------------ props, triggers, light

        /// <summary>level.gd add_prop(). Position in Godot coordinates.</summary>
        public Prop AddProp(string kind, string id, string display, Vector2 godotPos, string prompt = "", Color? col = null)
        {
            var go = new GameObject("Prop " + kind + " " + id);
            go.transform.SetParent(transform, false);
            go.transform.position = P(godotPos);
            var pr = go.AddComponent<Prop>();
            pr.kind = kind; pr.id = id; pr.display = display; pr.prompt = prompt;
            if (col.HasValue) pr.col = col.Value;
            return pr;
        }

        /// <summary>level.gd add_trigger(): fires every time the hunter walks into the Godot-space rect.</summary>
        public Trigger AddTrigger(Rect godotRect, Action onEnter)
        {
            var go = new GameObject("Trigger");
            go.transform.SetParent(transform, false);
            go.transform.position = P(godotRect.center);
            var box = go.AddComponent<BoxCollider2D>();
            box.isTrigger = true;
            box.size = godotRect.size;
            var t = go.AddComponent<Trigger>();
            t.onEnter = onEnter;
            return t;
        }

        public Brazier AddBrazier(Vector2 godotPos, bool lit = true)
        {
            var go = new GameObject("Brazier");
            go.transform.SetParent(transform, false);
            go.transform.position = P(godotPos);
            var b = go.AddComponent<Brazier>();
            b.lit = lit;
            b.SetLit(lit);
            return b;
        }

        /// <summary>level.gd add_torch(): a flickering point light with no visible source.</summary>
        public void AddTorch(Vector2 godotPos, float radius = 240f, Color? col = null, float energy = 1.1f)
        {
            var go = new GameObject("Torch");
            go.transform.SetParent(transform, false);
            go.transform.position = P(godotPos);
            var f = go.AddComponent<FlickerLight>();
            f.light = Lights.Point(go.transform, radius, col ?? new Color(1f, 0.68f, 0.34f), energy);
            f.baseEnergy = energy;
        }

        /// <summary>A thick dirt road along Godot-space points: rotated strips with round joints, lit like the ground.</summary>
        protected void AddPath(Vector2[] godotPts, float width, Color color, int order)
        {
            var parent = new GameObject("Path").transform;
            parent.SetParent(transform, false);
            for (int i = 0; i < godotPts.Length; i++)
            {
                var a = P(godotPts[i]);
                AddSprite("Joint", "circle", a, new Vector2(width, width), color, order, parent);
                if (i == godotPts.Length - 1) break;
                var b = P(godotPts[i + 1]);
                var seg = AddSprite("Seg", "white", (a + b) / 2f, new Vector2(Vector2.Distance(a, b), width), color, order, parent);
                seg.transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(b.y - a.y, b.x - a.x) * Mathf.Rad2Deg);
            }
        }

        public static float DistToSegment(Vector2 p, Vector2 a, Vector2 b)
        {
            var ab = b - a;
            float k = Mathf.Clamp01(Vector2.Dot(p - a, ab) / Mathf.Max(0.0001f, ab.sqrMagnitude));
            return Vector2.Distance(p, a + ab * k);
        }
    }
}
