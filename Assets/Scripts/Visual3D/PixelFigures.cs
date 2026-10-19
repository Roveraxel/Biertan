using System.Collections.Generic;
using UnityEngine;
using Biertan.Enemies;
using Biertan.Player;

namespace Biertan.Visual3D
{
    /// <summary>
    /// Frame-animated pixel-art characters (made with PixelLab) standing in the 3D world in place of an
    /// actor's old body sprite. Frames live in Resources/Sprites/Pixel/&lt;character&gt;/ as
    /// &lt;anim&gt;_&lt;dir&gt;_&lt;frame&gt;.png, with dir one of south/east/north/west (and the diagonals when
    /// present). The figure turns toward where it moves or strikes and plays idle, walk, attack, hurt
    /// or death from the actor's state; an animation it lacks falls back to its standing rotation.
    /// </summary>
    public class PixelFigure
    {
        public readonly string name;
        public readonly float height;   // metres the character's body stands tall (the canvas is larger)
        readonly Dictionary<string, Sprite[]> clips = new();
        readonly Dictionary<string, Sprite> stills = new();
        string cur = "idle"; string dir = "south";

        static readonly Dictionary<string, PixelFigure> cache = new();
        static readonly string[] Dirs = { "south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west" };

        PixelFigure(string name, float height)
        {
            this.name = name; this.height = height;
            var all = Resources.LoadAll<Sprite>("Sprites/Pixel/" + name);
            var tmp = new Dictionary<string, SortedList<int, Sprite>>();
            foreach (var s in all)
            {
                // rotation_<dir>  or  <anim>_<dir>_<frame>
                var parts = s.name.Split('_');
                if (parts.Length == 2 && parts[0] == "rotation") { stills[parts[1]] = s; continue; }
                if (parts.Length < 3 || !int.TryParse(parts[^1], out int f)) continue;
                string key = string.Join("_", parts, 0, parts.Length - 1); // anim_dir
                if (!tmp.TryGetValue(key, out var l)) tmp[key] = l = new SortedList<int, Sprite>();
                l[f] = s;
            }
            foreach (var kv in tmp) { var a = new Sprite[kv.Value.Count]; kv.Value.Values.CopyTo(a, 0); clips[kv.Key] = a; }
        }

        public static PixelFigure Get(string name, float height)
        {
            string key = name + height;
            if (!cache.TryGetValue(key, out var f)) { f = new PixelFigure(name, height); cache[key] = f; }
            return f.stills.Count > 0 ? f : null;
        }

        /// <summary>The figure for this actor, or null when it has none.</summary>
        public static PixelFigure For(Transform t)
        {
            if (t.GetComponent<PlayerController>() != null) return Get("hunter", 1.3f)?.Clone();
            if (t.GetComponent<EnemyBase>() is EnemyBase e)
                switch (e.kind)
                {
                    case "strigoi": return Get("strigoi", 1.35f)?.Clone();
                    case "pricolici": return Get("pricolici", 1.5f)?.Clone();
                    case "wolf": return Get("wolf", 1.0f)?.Clone();
                }
            return null;
        }

        PixelFigure Clone()
        {
            var c = (PixelFigure)MemberwiseClone(); // shares the sprite tables, keeps its own playhead
            c.cur = "idle"; c.t0 = Random.value; c.dir = "south";
            return c;
        }

        static string DirFrom(Vector2 v, bool eight)
        {
            float a = Mathf.Atan2(v.x, -v.y) * Mathf.Rad2Deg; // 0 = facing the camera (south), clockwise
            if (a < 0) a += 360f;
            int i = eight ? Mathf.RoundToInt(a / 45f) % 8 : Mathf.RoundToInt(a / 90f) % 4 * 2;
            return Dirs[i]; // south, south-east, east, ... clockwise seen from above

        }

        string State(Transform t, float speed)
        {
            if (t.GetComponent<PlayerController>() is PlayerController p)
            {
                if (p.hp <= 0f) return "death";
                if (p.attackT > 0f) return "attack";
                if (p.hurtFlash > 0.15f) return "hurt";
                return speed > 0.3f ? "walk" : "idle";
            }
            if (t.GetComponent<EnemyBase>() is EnemyBase e)
            {
                if (e.hp <= 0f) return "death";
                if (e.strikeT > 0f || e.state is "windup" or "lunge" or "leap" or "crouch") return "attack";
                if (e.flash > 0.08f) return "hurt";
                return speed > 0.3f ? "walk" : "idle";
            }
            return speed > 0.3f ? "walk" : "idle";
        }

        /// <summary>The standing pose facing the camera: frames of every animation are scaled and seated
        /// from it, since attack frames come on a larger canvas than the walk.</summary>
        public Sprite Still => stills.TryGetValue("south", out var s) ? s : null;

        /// <summary>Advances the figure and returns this frame's sprite.</summary>
        public Sprite Tick(Transform t, Vector2 vel, float dt)
        {
            Vector2 look = vel;
            if (look.sqrMagnitude < 0.09f)
            {
                if (t.GetComponent<PlayerController>() is PlayerController p) look = p.facing;
                else if (t.GetComponent<EnemyBase>() is EnemyBase e) look = e.face;
            }
            bool eight = stills.ContainsKey("south-east");
            if (look.sqrMagnitude > 0.0001f) dir = DirFrom(new Vector2(look.x, look.y), eight);

            string st = State(t, vel.magnitude);
            // a strike plays through once it starts, even if the game's attack window is shorter
            bool locked = cur == "attack" && t0 < ClipLength("attack");
            if (st != cur && !(locked && st != "death" && st != "hurt")) { cur = st; t0 = 0f; }
            t0 += dt;
            float fps = cur switch { "walk" => Mathf.Clamp(vel.magnitude * 3.2f, 6f, 14f), "attack" => 12f, "death" => 10f, _ => 7f };
            Flip = false;
            // a figure drawn without a strike (the wolf) springs at its prey with a quick burst of its run
            string anim = cur == "attack" && !clips.ContainsKey("attack_south") && !clips.ContainsKey("attack_east") ? "walk" : cur;
            if (anim != cur) fps = 18f;
            if (!clips.TryGetValue(anim + "_" + dir, out var frames))
            {
                // a missing side borrows its mirror (west from east and so on), else the camera-facing clip
                string mirror = dir.Replace("west", "@").Replace("east", "west").Replace("@", "east");
                if (mirror != dir && clips.TryGetValue(anim + "_" + mirror, out frames)) Flip = true;
                else clips.TryGetValue(anim + "_south", out frames);
            }
            if (frames != null && frames.Length > 0)
            {
                int i = (int)(t0 * fps);
                i = anim is "death" or "attack" ? Mathf.Min(i, frames.Length - 1) : i % frames.Length;
                return frames[i];
            }
            return stills.TryGetValue(dir, out var s) ? s : (stills.TryGetValue("south", out var s2) ? s2 : null);
        }
        float t0;

        /// <summary>True when this frame is a mirrored copy of the opposite side.</summary>
        public bool Flip { get; private set; }

        float ClipLength(string anim)
        {
            if (clips.TryGetValue(anim + "_" + dir, out var f) || clips.TryGetValue(anim + "_east", out f) || clips.TryGetValue(anim + "_south", out f))
                return f.Length / 12f;
            return 0f;
        }
    }
}
