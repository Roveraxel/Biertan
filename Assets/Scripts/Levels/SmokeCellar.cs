using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>
    /// The butchers' guild smoke-cellar under the Butchers' Tower in Sighișoara: the tutorial's fighting half.
    /// Cold store (slip past the spiriduși carrying off the bacon), the first fight, the smokehouse, then the
    /// Spiriduș-căpitan with his ladle, who winds up before each blow. After him, the hunter decides what
    /// becomes of the little thieves.
    /// </summary>
    public class SmokeCellar : LevelBase
    {
        static readonly Rect[] Rooms =
        {
            new(60, 500, 260, 200),     // the stair foot
            new(360, 300, 640, 600),    // cold store
            new(1080, 350, 520, 500),   // the first fight
            new(1680, 250, 570, 700),   // smokehouse
            new(2330, 350, 420, 500),   // the captain's den
        };
        static readonly Rect Corridor = new(280, 530, 2100, 140);   // two wall cells tall

        bool captainDown;

        public override void Build()
        {
            title = "THE SMOKE-CELLAR";
            subtitle = "Under the Butchers' Tower";
            size = new Vector2(2800, 1200);
            spawn = P(150, 600);
            ground = new Color32(0x24, 0x20, 0x1c, 0xff);
            tile = "";
            rng = new System.Random(1521);

            DrawGround();
            foreach (var r in Rooms) AddSprite("Floor", "white", P(r.center), r.size, new Color32(0x30, 0x2a, 0x24, 0xff), -989);
            AddSprite("Floor", "white", P(Corridor.center), Corridor.size, new Color32(0x2c, 0x27, 0x22, 0xff), -989);

            // solid masonry wherever there is no room or passage
            for (float y = 0f; y < size.y; y += 100f)
                for (float x = 0f; x < size.x; x += 100f)
                {
                    var c = new Rect(x, y, 100f, 100f);
                    if (Open(c)) continue;
                    AddBlock(c, "stone", 70f);
                }
            AddBlock(new Rect(-200, -200, 3200, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1200, 3200, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 1600), "hidden", 0);
            AddBlock(new Rect(2800, -200, 200, 1600), "hidden", 0);

            // stores: barrels, sacks, crates along the walls; the smokehouse's fires and cauldrons
            foreach (var (p, s) in new (Vector2, string)[]
            {
                (new(400, 340), "barrels"), (new(520, 330), "sacks"), (new(640, 340), "barrels"), (new(780, 330), "crate"), (new(930, 350), "sacks"),
                (new(400, 860), "crate"), (new(560, 870), "barrel"), (new(700, 860), "sacks"), (new(940, 850), "barrels"),
                (new(1120, 390), "crate"), (new(1560, 400), "barrel"), (new(1130, 820), "sacks"), (new(1560, 810), "crate"),
                (new(1740, 300), "firewood"), (new(1900, 290), "cauldron"), (new(2080, 300), "firewood"), (new(2200, 330), "barrels"),
                (new(1730, 900), "cauldron"), (new(1960, 910), "firewood"), (new(2190, 900), "cauldron"),
                (new(2380, 400), "sacks"), (new(2700, 420), "barrels"), (new(2690, 800), "crate"), (new(2390, 800), "barrel"),
            })
                AddDecor(p, s);

            AddTorch(new Vector2(200, 560), 200f, new Color(1f, 0.6f, 0.3f), 0.8f);
            AddTorch(new Vector2(680, 600), 260f, new Color(0.7f, 0.75f, 1f), 0.35f);   // cold store: a grey draught of daylight
            AddTorch(new Vector2(1340, 600), 240f, new Color(1f, 0.6f, 0.3f), 0.7f);
            foreach (var x in new[] { 1900f, 1730f, 2190f })
                AddTorch(new Vector2(x, x == 1900f ? 320f : 880f), 220f, new Color(1f, 0.45f, 0.18f), 0.9f); // smoking fires
            AddTorch(new Vector2(2540, 600), 260f, new Color(1f, 0.55f, 0.25f), 0.8f);

            // the smokehouse: hams on chains swinging across the way through
            foreach (var (x, y, ph, ax) in new[] { (1800f, 600f, 0f, false), (1940f, 460f, 0.6f, true), (1940f, 760f, 1.3f, true), (2090f, 600f, 0.9f, false) })
            {
                var hk = new GameObject("SwingingHook").AddComponent<SwingingHook>();
                hk.transform.SetParent(transform, false);
                hk.anchor = P(x, y); hk.transform.position = hk.anchor; hk.phase = ph; hk.alongX = ax; hk.reach = ax ? 160f : 140f;
            }

            // the thieves: two in the cold store you can slip past, then the fights
            foreach (var p in new[] { new Vector2(560, 470), new Vector2(820, 760) })
            {
                var e = SpawnEnemy("spiridus", P(p));
                if (e != null) e.aggro = 130f;
            }
            foreach (var p in new[] { new Vector2(1250, 500), new Vector2(1420, 520), new Vector2(1300, 720), new Vector2(1460, 700) })
                SpawnEnemy("spiridus", P(p));
            foreach (var p in new[] { new Vector2(1800, 450), new Vector2(1950, 600), new Vector2(2100, 470), new Vector2(1850, 780), new Vector2(2120, 760) })
                SpawnEnemy("spiridus", P(p));
            var cap = SpawnEnemy("spiridus_cap", P(2560, 600));
            if (cap != null) cap.Died += _ => OnCaptain();
            foreach (var p in new[] { new Vector2(2450, 480), new Vector2(2460, 740) }) SpawnEnemy("spiridus", P(p));

            AddTrigger(new Rect(0, 500, 50, 200), Leave);
            AddTrigger(new Rect(380, 300, 80, 600), HatTheft);
        }

        public override Color Ambient() => new(0.16f, 0.14f, 0.13f);

        bool Open(Rect c)
        {
            foreach (var r in Rooms) if (r.Overlaps(c) && r.Contains(c.center)) return true;
            return Corridor.Contains(c.center);
        }

        void AddDecor(Vector2 godot, string sprite)
        {
            var go = new GameObject("Decor " + sprite);
            go.transform.SetParent(transform, false);
            go.transform.position = P(godot);
            var d = go.AddComponent<Decor>();
            d.sprite = sprite; d.scale = Decor.SizeOf(sprite); d.radius = 22f * d.scale; d.flip = rng.NextDouble() < 0.5;
            d.Build();
        }

        /// <summary>A spiriduș darts out of the hams, snatches the hunter's hat and is gone into the dark.</summary>
        void HatTheft()
        {
            var gm = GameManager.I;
            if (gm.state != GameManager.State.Play || gm.SideHas("sig_hat_lost")) return;
            gm.side.Add("sig_hat_lost");
            AudioManager.I?.Sfx("cackle", -10f, 1.8f);
            gm.StartDialogue("Hey!", new[] { "Something small and quick drops from a smoking-hook, snatches the hat off your head and is gone between the hams, giggling.", "Your hat. Your good hat." },
                () => HudEvents.Toast("Get your hat back."));
        }

        /// <summary>The captain faints with the rest; when the hunter has him, he comes round to apologise.</summary>
        void OnCaptain()
        {
            if (captainDown) return;
            captainDown = true;
            AudioManager.I?.Sfx("bell", -14f, 1.3f);
            HudEvents.Banner("THE CAPTAIN FAINTS", "Stars circle over his little red cap.");
            AddProp("npc", "captain", "Spiriduș-căpitan", new Vector2(2600, 640), "E   Wake the captain", new Color32(0x8a, 0x2a, 0x22, 0xff));
        }

        void Leave()
        {
            var gm = GameManager.I;
            if (gm.state != GameManager.State.Play || gm.transitioning) return;
            LevelLoader.Goto("sighisoara", Sighisoara.CellarDoor + new Vector2(0f, 60f));
        }
    }
}
