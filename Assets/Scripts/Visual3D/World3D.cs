using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Biertan.Bosses;
using Biertan.Core;
using Biertan.Enemies;
using Biertan.Levels;
using Biertan.Player;

namespace Biertan.Visual3D
{
    /// <summary>
    /// A Diablo-style 3D presentation of the 2D game. The simulation (physics, combat, quests) keeps running in
    /// 2D; this builds a lit 3D world from each level's data (ground, roads, blocks, trees, lights) and mirrors
    /// the actors as upright sprites lit by nearby fires. 2D (x, y) maps to 3D (x·S, 0, y·S).
    /// </summary>
    public class World3D : MonoBehaviour
    {
        public static World3D I { get; private set; }
        public static bool Active => I != null && I.isActiveAndEnabled && I.cam != null;

        public const float S = 0.02f;      // metres per 2D unit (50 px = 1 m)
        public const float HK = 2.6f;      // block face heights are drawn taller in 3D
        public RenderPipelineAsset pipeline;
        [Range(20, 80)] public float pitch = 52f;
        public float distance = 26f, fov = 34f;

        RenderPipelineAsset prevPipeline;
        Camera cam, cam2d;
        int cam2dMask;
        Transform root, actors;
        LevelBase built;
        Vector3 camTarget;
        Light moon;
        readonly Dictionary<LineRenderer, LineRenderer> lines = new();
        readonly Dictionary<TextMesh, TextMesh> texts = new();
        readonly Dictionary<UnityEngine.Rendering.Universal.Light2D, Light> lights = new();
        readonly Dictionary<Transform, Actor> mirrored = new();
        readonly Dictionary<string, Material> mats = new();

        class Actor { public EntityId id; public Transform board, shadow; public CharacterBody body; public FolkFigures.Art? folk; public PixelFigure pix; public float lastStrike; public float seed, dir = 1f; public Vector3 last; public Vector2 vel; public bool hasLast; public List<(SpriteRenderer src, SpriteRenderer dst)> parts = new(); public (TextMesh src, TextMesh dst) text; }

        public static Vector3 To3D(Vector2 p, float h = 0f) => new(p.x * S, h, p.y * S);

        // ------------------------------------------------------------ lifecycle

        void OnEnable()
        {
            I = this;
            prevPipeline = QualitySettings.renderPipeline;
            if (pipeline != null) QualitySettings.renderPipeline = pipeline;
        }

        void OnDisable()
        {
            if (I == this) I = null;
            QualitySettings.renderPipeline = prevPipeline;
            if (cam2d != null) cam2d.cullingMask = cam2dMask;
        }

        void Start()
        {
            cam2d = Camera.main;
            if (cam2d != null) { cam2dMask = cam2d.cullingMask; cam2d.cullingMask = 0; cam2d.depth = -10; cam2d.clearFlags = CameraClearFlags.Nothing; }

            var cgo = new GameObject("Camera3D");
            cam = cgo.AddComponent<Camera>();
            cam.fieldOfView = fov; cam.nearClipPlane = 0.3f; cam.farClipPlane = 200f; cam.depth = 0;
            cam.clearFlags = CameraClearFlags.SolidColor; cam.backgroundColor = new Color(0.015f, 0.018f, 0.03f);
            var cdata = cgo.AddComponent<UniversalAdditionalCameraData>();
            cdata.renderPostProcessing = true;
            cdata.antialiasing = AntialiasingMode.SubpixelMorphologicalAntiAliasing;

            // moonlight, ambient, fog
            moon = new GameObject("Moon").AddComponent<Light>();
            moon.type = LightType.Directional;
            moon.transform.rotation = Quaternion.Euler(48f, -35f, 0f);
            moon.color = new Color(0.55f, 0.62f, 0.9f); moon.intensity = 1.1f;
            moon.shadows = LightShadows.Soft; moon.shadowStrength = 0.75f;
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.3f, 0.32f, 0.45f);
            RenderSettings.ambientEquatorColor = new Color(0.2f, 0.2f, 0.26f);
            RenderSettings.ambientGroundColor = new Color(0.1f, 0.09f, 0.08f);
            RenderSettings.fog = true; RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.012f; RenderSettings.fogColor = new Color(0.05f, 0.06f, 0.09f);

            // grading: bloom on fire, vignette, crushed and slightly desaturated like Diablo's night
            var vol = new GameObject("PostFX").AddComponent<Volume>();
            vol.isGlobal = true;
            var prof = ScriptableObject.CreateInstance<VolumeProfile>();
            var bloom = prof.Add<Bloom>(true); bloom.threshold.Override(0.95f); bloom.intensity.Override(0.7f); bloom.scatter.Override(0.65f);
            var vig = prof.Add<Vignette>(true); vig.intensity.Override(0.34f); vig.smoothness.Override(0.5f);
            var ca = prof.Add<ColorAdjustments>(true); ca.contrast.Override(22f); ca.saturation.Override(-18f); ca.postExposure.Override(1.4f);
            var tm = prof.Add<Tonemapping>(true); tm.mode.Override(TonemappingMode.ACES);
            var grain = prof.Add<FilmGrain>(true); grain.intensity.Override(0.18f);
            vol.profile = prof;
        }

        // ------------------------------------------------------------ per frame

        void LateUpdate()
        {
            var gm = GameManager.I;
            if (gm == null || cam == null) return;
            if (gm.level != built) Rebuild(gm.level);
            if (built == null) return;
            SyncLights();
            SyncActors(gm.player);
            SyncLines();
            UpdateCutaway(gm.player);
            FollowCamera(gm.player);
        }

        void FollowCamera(PlayerController p)
        {
            if (p == null) return;
            var target = To3D(p.transform.position);
            camTarget = Vector3.Distance(camTarget, target) > 20f ? target : Vector3.Lerp(camTarget, target, 1f - Mathf.Exp(-Time.deltaTime * 6f));
            var rot = Quaternion.Euler(pitch, 0f, 0f);
            // a jolt on heavy blows that dies away within a quarter second
            shake = Mathf.MoveTowards(shake, 0f, Time.unscaledDeltaTime * 0.6f);
            Vector3 jolt = shake > 0f ? new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), 0f) * shake : Vector3.zero;
            cam.transform.SetPositionAndRotation(camTarget + rot * (new Vector3(0f, 0f, -distance) + jolt), rot);
        }

        float shake;
        /// <summary>Shake the camera by about this many metres (it settles on its own).</summary>
        public static void Shake(float amount) { if (Active) I.shake = Mathf.Max(I.shake, amount); }

        /// <summary>Sparks where the blade lands, at a 2D world point, thrown along dir.</summary>
        public static void Spark(Vector2 at, Vector2 dir)
        {
            if (Active) HitSpark.Spawn(I.root, To3D(at, 0.8f), new Vector3(dir.x, 0f, dir.y));
        }

        /// <summary>Freeze the game for a heartbeat so a killing blow lands with weight.</summary>
        public static void HitStop(float seconds) { if (Active) I.StartCoroutine(I.Freeze(seconds)); }
        System.Collections.IEnumerator Freeze(float seconds)
        {
            if (Time.timeScale < 1f) yield break;
            Time.timeScale = 0.05f;
            yield return new WaitForSecondsRealtime(seconds);
            if (Time.timeScale < 0.1f) Time.timeScale = 1f;
        }

        /// <summary>The 2D world point under the mouse (for aiming), through the ground plane.</summary>
        public Vector2 MouseWorld2D(Vector2 screen)
        {
            var ray = cam.ScreenPointToRay(screen);
            if (Mathf.Abs(ray.direction.y) < 1e-4f) return Vector2.zero;
            float t = -ray.origin.y / ray.direction.y;
            var hit = ray.origin + ray.direction * t;
            return new Vector2(hit.x / S, hit.z / S);
        }

        // ------------------------------------------------------------ materials

        Material Mat(string set, float tileMetres, Color tint, float smooth = 0.12f)
        {
            string key = set + tileMetres + tint;
            if (mats.TryGetValue(key, out var m)) return m;
            m = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            var diff = Resources.Load<Texture2D>("Textures3D/" + set + "_diff_1k");
            var nor = Resources.Load<Texture2D>("Textures3D/" + set + "_nor_gl_1k");
            if (diff != null) m.SetTexture("_BaseMap", diff);
            if (nor != null) { m.SetTexture("_BumpMap", nor); m.EnableKeyword("_NORMALMAP"); m.SetFloat("_BumpScale", 1.2f); }
            m.SetColor("_BaseColor", tint);
            m.SetFloat("_Smoothness", smooth);
            m.SetTextureScale("_BaseMap", Vector2.one / tileMetres);
            mats[key] = m;
            return m;
        }

        Material Plain(Color c, float smooth = 0.1f, Color? emission = null)
        {
            string key = "plain" + c + emission;
            if (mats.TryGetValue(key, out var m)) return m;
            m = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            m.SetColor("_BaseColor", c); m.SetFloat("_Smoothness", smooth);
            if (emission.HasValue) { m.EnableKeyword("_EMISSION"); m.SetColor("_EmissionColor", emission.Value); }
            mats[key] = m;
            return m;
        }

        Material Ground => Mat("grass_path_2", 5f, new Color(0.62f, 0.66f, 0.55f));
        Material Cobble => Mat("cobblestone_floor_08", 2.4f, new Color(0.78f, 0.76f, 0.72f), 0.2f);
        Material Road => Mat("forest_leaves_02", 3f, new Color(0.7f, 0.62f, 0.52f));
        Material Roof => Mat("clay_roof_tiles_02", 1.6f, new Color(0.85f, 0.8f, 0.78f), 0.18f);
        Material Plaster => Mat("clay_plaster", 2.5f, new Color(0.92f, 0.88f, 0.8f));
        Material Stone => Mat("castle_wall_slates", 2.4f, new Color(0.8f, 0.78f, 0.74f));
        Material Wood => Mat("brown_planks_05", 1.6f, new Color(0.75f, 0.68f, 0.6f));

        Material GroundFor(string id, LevelBase level) => id switch
        {
            "hub" or "richis" or "mosna" or "biertan" => Ground,
            "forest" or "hills" or "vineyard" or "walls" => Mat("forest_leaves_02", 3f, new Color(0.6f, 0.58f, 0.52f)),
            "arena" or "hollow" => Mat("forest_leaves_02", 3f, new Color(0.42f, 0.44f, 0.38f)),
            "caves" or "gorge" => Mat("castle_wall_slates", 3f, new Color(0.36f, 0.34f, 0.32f)),
            "church" => Mat("cobblestone_floor_08", 1.6f, new Color(0.55f, 0.53f, 0.5f), 0.3f),
            _ => string.IsNullOrEmpty(level.tile) ? Plain(level.ground * 0.9f) : Ground,
        };

        /// <summary>Scale the moon and the ambient light by the 2D level's own ambient brightness (caves are dark,
        /// villages bright).</summary>
        void ApplyDarkness(LevelBase level)
        {
            var a = level.Ambient();
            float k = Mathf.Clamp((a.r * 0.3f + a.g * 0.59f + a.b * 0.11f) / 0.4f, 1.0f, 1.45f);
            moon.intensity = 1.7f * k;
            RenderSettings.ambientSkyColor = new Color(0.42f, 0.44f, 0.58f) * k;
            RenderSettings.ambientEquatorColor = new Color(0.3f, 0.29f, 0.34f) * k;
            RenderSettings.ambientGroundColor = new Color(0.16f, 0.14f, 0.12f) * k;
            ambientK = k;
        }

        float ambientK = 1f;

        // ------------------------------------------------------------ building the world

        void Rebuild(LevelBase level)
        {
            if (root != null) Destroy(root.gameObject);
            foreach (var l in lights.Values) if (l != null) Destroy(l.gameObject);
            lights.Clear();
            coveredRoofs.Clear();
            foreach (var l in lines.Values) if (l != null) Destroy(l.gameObject);
            lines.Clear();
            foreach (var a in mirrored.Values) if (a.board != null) { Destroy(a.board.gameObject); Destroy(a.shadow.gameObject); }
            EnemyBase.Slain.Clear();
            mirrored.Clear();
            built = level;
            if (level == null) return;
            root = new GameObject("World3D: " + level.name).transform;
            actors = new GameObject("Actors").transform;
            actors.SetParent(root, false);

            // ground
            var size = level.size * S;
            // the ground runs well past the map's edges so the camera never looks into a void
            Quad("Ground", new Vector3(size.x / 2f, 0f, -size.y / 2f), size + new Vector2(70f, 70f), GroundFor(GameManager.I.current, level));
            ApplyDarkness(level);

            foreach (var sr in level.GetComponentsInChildren<SpriteRenderer>())
            {
                // cobbled squares and roads, from the 2D level's own drawing
                if (sr.name.StartsWith("Tiled tile_cobble") && sr.drawMode != SpriteDrawMode.Simple)
                    Quad("Cobbles", To3D(sr.transform.position, 0.01f), sr.size * S, Cobble);
                else if (sr.name.StartsWith("GateRoad"))
                    Quad("GateRoad", To3D(sr.transform.position, 0.008f), (Vector2)sr.transform.lossyScale * S, Cobble);
                else if (sr.transform.parent != null && sr.transform.parent.name == "Path" && sr.name == "Seg")
                {
                    var q = Quad("Road", To3D(sr.transform.position, 0.006f), (Vector2)sr.transform.lossyScale * S, Road);
                    q.transform.rotation = Quaternion.Euler(0f, -sr.transform.eulerAngles.z, 0f);
                }
            }

            BuildDecals(level);
            foreach (var b in level.GetComponentsInChildren<Block>()) BuildBlock(b);
            cutaways.Clear();
            foreach (var cw in level.GetComponentsInChildren<CurtainWall>()) BuildCurtain(cw);
            foreach (var way in level.GetComponentsInChildren<CoveredWay>()) BuildCoveredWay(way);
            foreach (Transform t in level.transform)
                if (t.name is "Tree" or "Pine") BuildTree(t, t.name == "Pine");
            foreach (var br in level.GetComponentsInChildren<Brazier>()) BuildBrazier(br);
        }

        /// <summary>Flat ground features drawn by the 2D level (lakes, chambers, yards, carpets, graves, clearings)
        /// become coloured shapes on the 3D ground, merged into one mesh per colour.</summary>
        void BuildDecals(LevelBase level)
        {
            var groups = new Dictionary<Color, MeshBuilder>();
            foreach (var sr in level.GetComponentsInChildren<SpriteRenderer>())
            {
                if (sr.sortingOrder > -100 || !sr.enabled || sr.sprite == null) continue;
                if (sr.name is "Ground" || sr.name.StartsWith("Tiled") || sr.name.StartsWith("GateRoad")) continue;
                if (sr.transform.parent != null && sr.transform.parent.name == "Path") continue;
                if (sr.GetComponentInParent<Block>() != null) continue;
                Vector2 sz = sr.transform.lossyScale;
                if (Mathf.Abs(sz.x) < 14f && Mathf.Abs(sz.y) < 14f) continue; // ground specks: the texture covers them
                bool disc = sr.sprite.name == "circle";
                if (!disc && sr.sprite.name != "white") continue;
                var c = sr.color;
                if (c.a < 0.5f) continue; // faint 2D shading: the 3D lighting does this job
                c = new Color(Mathf.Round(c.r * 40f) / 40f, Mathf.Round(c.g * 40f) / 40f, Mathf.Round(c.b * 40f) / 40f, Mathf.Round(c.a * 20f) / 20f);
                if (!groups.TryGetValue(c, out var mb)) groups[c] = mb = new MeshBuilder();
                float y = 0.004f + (sr.sortingOrder + 1000) * 0.0004f;
                var centre = To3D(sr.transform.position, y);
                float rot = -sr.transform.eulerAngles.z;
                if (disc) mb.Disc(centre, sz.x * S / 2f, sz.y * S / 2f, rot, 24);
                else mb.FlatRect(centre, sz.x * S, sz.y * S, rot);
            }
            foreach (var kv in groups)
            {
                var go = new GameObject("Decal");
                go.transform.SetParent(root, false);
                bool water = kv.Key.b > kv.Key.r * 1.25f && kv.Key.b > 0.15f;
                var col = kv.Key; col.a = 1f;
                Finish(go, kv.Value, Plain(col, water ? 0.85f : 0.1f), shadows: false);
            }
            // visible straight walls (AddWall with a colour)
            foreach (var sr in level.GetComponentsInChildren<SpriteRenderer>())
                if (sr.name == "Wall" && sr.enabled && sr.GetComponent<BoxCollider2D>() != null)
                {
                    Vector2 sz = sr.transform.lossyScale, p = sr.transform.position;
                    var go = new GameObject("Wall3D");
                    go.transform.SetParent(root, false);
                    var mb = new MeshBuilder();
                    mb.Box(new Vector3((p.x - sz.x / 2f) * S, 0, (p.y - sz.y / 2f) * S), new Vector3((p.x + sz.x / 2f) * S, 1.2f, (p.y + sz.y / 2f) * S), true);
                    Finish(go, mb, Stone);
                }
        }

        Material Fade(Color c)
        {
            string key = "fade" + c;
            if (mats.TryGetValue(key, out var m)) return m;
            m = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            m.SetFloat("_Surface", 1f); m.SetFloat("_Blend", 0f);
            m.SetOverrideTag("RenderType", "Transparent");
            m.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha); m.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
            m.SetInt("_ZWrite", 0);
            m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            m.renderQueue = (int)RenderQueue.Transparent;
            m.SetColor("_BaseColor", c); m.SetFloat("_Smoothness", 0.1f);
            mats[key] = m;
            return m;
        }

        GameObject Quad(string n, Vector3 centre, Vector2 size, Material m)
        {
            var go = new GameObject(n);
            go.transform.SetParent(root, false);
            go.transform.position = centre;
            var mb = new MeshBuilder();
            Vector3 a = new(-size.x / 2f, 0, -size.y / 2f), b = new(size.x / 2f, 0, -size.y / 2f), c = new(size.x / 2f, 0, size.y / 2f), d = new(-size.x / 2f, 0, size.y / 2f);
            mb.Quad(a, d, c, b, centre); // world-anchored UVs keep textures continuous between pieces
            Finish(go, mb, m, shadows: false);
            return go;
        }

        void Finish(GameObject go, MeshBuilder mb, Material m, bool shadows = true)
        {
            go.AddComponent<MeshFilter>().sharedMesh = mb.Build();
            var r = go.AddComponent<MeshRenderer>();
            r.sharedMaterial = m;
            r.shadowCastingMode = shadows ? ShadowCastingMode.On : ShadowCastingMode.Off;
            r.receiveShadows = true;
        }

        void BuildBlock(Block b)
        {
            if (b.style is "hidden" or "vine") return;
            Vector2 p = b.transform.position;
            float w = b.footprint.x * S, d = b.footprint.y * S, h = Mathf.Max(0.25f, b.h * S * HK);
            // keep rock and walls low enough to see over from the camera, as Diablo does
            if (b.style == "rock") h = Mathf.Min(h, 1.3f);
            else if (b.style is "wall" or "stone" or "ruin") h = Mathf.Min(h, 2.2f);
            var go = new GameObject("Block " + b.style);
            go.transform.SetParent(root, false);
            var min = new Vector3(p.x * S - w / 2f, 0f, p.y * S);
            var max = min + new Vector3(w, h, d);
            var walls = new MeshBuilder();
            var roof = new MeshBuilder();
            Material wallMat = Stone, roofMat = Roof;
            switch (b.style)
            {
                case "house":
                    wallMat = Plaster;
                    walls.Box(min, max, top: false);
                    roof.Gable(min, max, Mathf.Min(w, d) * 0.55f, 0.18f);
                    BuildBeams(go.transform, min, max);
                    break;
                case "church":
                    wallMat = Plaster;
                    walls.Box(min, max, top: false);
                    roof.Gable(min, max, Mathf.Min(w, d) * 0.85f, 0.2f);
                    break;
                case "tower":
                    wallMat = Plaster;
                    walls.Box(min, max, top: false);
                    roof.Pyramid(min, max, Mathf.Max(w, d) * 1.25f, 0.12f);
                    break;
                case "wall":
                    walls.Box(min, max, top: true);
                    walls.Merlons(min, max);
                    roof = null;
                    break;
                case "pew":
                    wallMat = Wood;
                    walls.Box(min, new Vector3(max.x, Mathf.Min(max.y, 0.5f), max.z), top: true);
                    roof = null;
                    break;
                case "ruin":
                    walls.RuinBox(min, max, (int)(p.x * 7 + p.y * 3));
                    roof = null;
                    break;
                default: // stone, rock
                    walls.Box(min, max, top: true);
                    roof = null;
                    if (b.style == "rock") wallMat = Mat("castle_wall_slates", 2.4f, new Color(0.42f, 0.4f, 0.38f));
                    break;
            }
            Finish(go, walls, wallMat);
            if (roof != null)
            {
                var rgo = new GameObject("Roof");
                rgo.transform.SetParent(go.transform, false);
                Finish(rgo, roof, roofMat);
            }
            if (b.style is "house" or "church") BuildWindows(go.transform, min, max, b.style == "church");
            if (b.style == "house") BuildDoor(go.transform, min, max);
        }

        // ------------------------------------------------------------ Biertan's curved walls

        readonly List<Transform> cutaways = new();
        readonly List<(GameObject roof, Rect area)> coveredRoofs = new();

        /// <summary>A curved fortification wall, one piece per segment so pieces near the camera can be cut away:
        /// pale stone-and-plaster wall, a tiled roof over its walkway, buttress piers on the inside of the middle
        /// ring, plain timber for the stairway's sides.</summary>
        void BuildCurtain(CurtainWall cw)
        {
            bool gallery = cw.style == "gallery";
            float H = gallery ? 1.1f : cw.h * S * HK * 1.6f;
            float t = cw.thick * S;
            var wallMat = gallery ? Wood : Mat("clay_plaster", 2.5f, new Color(0.8f, 0.78f, 0.72f));
            var centroid = Vector2.zero;
            foreach (var p in cw.pts) centroid += p;
            centroid /= Mathf.Max(1, cw.pts.Count);
            for (int i = 0; i < cw.pts.Count - 1; i++)
            {
                Vector2 a2 = cw.pts[i], b2 = cw.pts[i + 1];
                if (Vector2.Distance(a2, b2) < 1f) continue;
                Vector3 a = To3D(a2), b = To3D(b2), mid = (a + b) / 2f;
                var u = (b - a).normalized;
                a -= u * t * 0.35f; b += u * t * 0.35f; // overlap the joints
                var go = new GameObject("Curtain");
                go.transform.SetParent(root, false);
                go.transform.position = mid;
                var mb = new MeshBuilder();
                mb.OrientedBox(a - mid, b - mid, t, H);
                Finish(go, mb, wallMat);
                if (!gallery)
                {
                    var roofGo = new GameObject("Walkway roof");
                    roofGo.transform.SetParent(go.transform, false);
                    var rm = new MeshBuilder();
                    rm.OrientedGable(a - mid, b - mid, t + 0.35f, H, 0.45f);
                    Finish(roofGo, rm, Roof);
                    if (cw.style == "arches" && i % 2 == 0)
                    {
                        var inward = (To3D(centroid) - mid); inward.y = 0; inward.Normalize();
                        var n = Vector3.Cross(Vector3.up, u);
                        if (Vector3.Dot(n, inward) < 0) n = -n;
                        var pier = new MeshBuilder();
                        pier.OrientedBox(n * (t / 2f + 0.25f) - u * 0.25f, n * (t / 2f + 0.25f) + u * 0.25f, 0.5f, H * 0.82f);
                        var pgo = new GameObject("Pier");
                        pgo.transform.SetParent(go.transform, false);
                        Finish(pgo, pier, Stone);
                    }
                }
                cutaways.Add(go.transform);
            }
        }

        /// <summary>The covered wooden stairway: posts down both sides and a tiled roof over the passage.</summary>
        void BuildCoveredWay(CoveredWay way)
        {
            var r = way.godotRect;
            float x0 = r.xMin * S, x1 = r.xMax * S, z0 = -r.yMax * S, z1 = -r.yMin * S, H = 1.9f;
            var go = new GameObject("CoveredWay");
            go.transform.SetParent(root, false);
            var posts = new MeshBuilder();
            for (float z = z0 + 0.3f; z < z1; z += 1.6f)
                foreach (float x in new[] { x0 + 0.1f, x1 - 0.1f })
                    posts.Box(new Vector3(x - 0.09f, 0, z - 0.09f), new Vector3(x + 0.09f, H, z + 0.09f), true);
            Finish(go, posts, Wood);
            var roofGo = new GameObject("Roof");
            roofGo.transform.SetParent(go.transform, false);
            var rm = new MeshBuilder();
            rm.Gable(new Vector3(x0 - 0.1f, 0, z0), new Vector3(x1 + 0.1f, H, z1), 0.8f, 0.25f);
            Finish(roofGo, rm, Roof);
            coveredRoofs.Add((roofGo, new Rect(r.xMin, -r.yMax, r.width, r.height)));
        }

        /// <summary>Diablo's trick: walls between the camera and the hunter sink so he stays visible, and the
        /// stairway's roof lifts away while he is under it.</summary>
        void UpdateCutaway(PlayerController p)
        {
            if (p == null) return;
            var pp = To3D(p.transform.position);
            foreach (var t in cutaways)
            {
                if (t == null) continue;
                var c = t.position;
                bool front = c.z < pp.z - 0.2f && pp.z - c.z < 7.5f && Mathf.Abs(c.x - pp.x) < 3.2f;
                float target = front ? 0.22f : 1f;
                var s = t.localScale;
                s.y = Mathf.MoveTowards(s.y, target, Time.deltaTime * 4f);
                t.localScale = s;
            }
            Vector2 p2 = p.transform.position;
            foreach (var (roof, area) in coveredRoofs)
                if (roof != null) roof.SetActive(!area.Contains(p2));
        }

        void BuildWindows(Transform parent, Vector3 min, Vector3 max, bool church)
        {
            float w = max.x - min.x, h = max.y - min.y;
            int n = Mathf.Max(1, (int)(w / 1.3f));
            var glow = Plain(new Color(0.2f, 0.12f, 0.05f), 0.6f, new Color(1.4f, 0.75f, 0.25f));
            for (int i = 0; i < n; i++)
            {
                float x = min.x + (i + 0.5f) * w / n;
                if (!church && n > 1 && i == n / 2) continue; // the door goes here
                var win = GameObject.CreatePrimitive(PrimitiveType.Cube);
                Destroy(win.GetComponent<Collider>());
                win.transform.SetParent(parent, false);
                win.transform.position = new Vector3(x, min.y + h * (church ? 0.55f : 0.6f), min.z - 0.01f);
                win.transform.localScale = new Vector3(church ? 0.22f : 0.3f, church ? Mathf.Min(1.1f, h * 0.35f) : 0.38f, 0.04f);
                win.GetComponent<Renderer>().sharedMaterial = glow;
            }
        }

        /// <summary>Saxon half-timbering: dark beams over the plaster of the street front.</summary>
        void BuildBeams(Transform parent, Vector3 min, Vector3 max)
        {
            var beam = Plain(new Color(0.12f, 0.08f, 0.05f), 0.15f);
            float w = max.x - min.x, h = max.y - min.y;
            void Beam(Vector3 c, Vector3 size, float rotZ = 0f)
            {
                var b = GameObject.CreatePrimitive(PrimitiveType.Cube);
                Destroy(b.GetComponent<Collider>());
                b.transform.SetParent(parent, false);
                b.transform.position = c; b.transform.localScale = size;
                b.transform.rotation = Quaternion.Euler(0, 0, rotZ);
                b.GetComponent<Renderer>().sharedMaterial = beam;
            }
            float z = min.z - 0.03f;
            Beam(new Vector3((min.x + max.x) / 2f, max.y - 0.06f, z), new Vector3(w, 0.12f, 0.06f));
            Beam(new Vector3((min.x + max.x) / 2f, min.y + 0.1f, z), new Vector3(w, 0.14f, 0.06f));
            int posts = Mathf.Max(2, (int)(w / 1.1f) + 1);
            for (int i = 0; i < posts; i++)
            {
                float x = min.x + 0.05f + i * (w - 0.1f) / (posts - 1);
                Beam(new Vector3(x, (min.y + max.y) / 2f, z), new Vector3(0.1f, h, 0.06f));
                if (i < posts - 1 && i % 2 == 0) // a diagonal brace in every other bay
                {
                    float bw = (w - 0.1f) / (posts - 1);
                    float len = Mathf.Sqrt(bw * bw + h * h * 0.36f);
                    Beam(new Vector3(x + bw / 2f, min.y + h * 0.45f, z), new Vector3(len, 0.08f, 0.05f), Mathf.Atan2(h * 0.6f, bw) * Mathf.Rad2Deg);
                }
            }
        }

        void BuildDoor(Transform parent, Vector3 min, Vector3 max)
        {
            var door = GameObject.CreatePrimitive(PrimitiveType.Cube);
            Destroy(door.GetComponent<Collider>());
            door.transform.SetParent(parent, false);
            door.transform.position = new Vector3((min.x + max.x) / 2f, min.y + 0.55f, min.z - 0.02f);
            door.transform.localScale = new Vector3(0.6f, 1.1f, 0.05f);
            door.GetComponent<Renderer>().sharedMaterial = Wood;
        }

        void BuildTree(Transform t, bool pine)
        {
            Vector2 p = t.position;
            float sc = t.localScale.x;
            var go = new GameObject(pine ? "Pine3D" : "Tree3D");
            go.transform.SetParent(root, false);
            go.transform.position = To3D(p);
            var bark = Plain(new Color(0.3f, 0.21f, 0.13f));
            var trunk = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Destroy(trunk.GetComponent<Collider>());
            trunk.transform.SetParent(go.transform, false);
            trunk.transform.localScale = new Vector3(0.22f, 0.9f, 0.22f) * sc;
            trunk.transform.localPosition = new Vector3(0, 0.9f * sc, 0);
            trunk.GetComponent<Renderer>().sharedMaterial = bark;
            int seed = (int)(p.x * 13 + p.y * 7);
            var rnd = new System.Random(seed);
            if (pine)
            {
                var needles = Plain(new Color(0.12f, 0.24f, 0.17f), 0.05f);
                for (int i = 0; i < 4; i++)
                {
                    var cone = new GameObject("Tier");
                    cone.transform.SetParent(go.transform, false);
                    float r = (1.5f - i * 0.3f) * sc, y = (1.1f + i * 0.85f) * sc;
                    var mb = new MeshBuilder();
                    mb.Cone(new Vector3(0, y, 0), r, 1.5f * sc, 10);
                    Finish(cone, mb, needles);
                }
            }
            else
            {
                Color[] pal = { new(0.2f, 0.34f, 0.17f), new(0.26f, 0.4f, 0.18f), new(0.5f, 0.34f, 0.12f) };
                var leaf = Plain(pal[rnd.Next(3)], 0.05f);
                for (int i = 0; i < 5; i++)
                {
                    var blob = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                    Destroy(blob.GetComponent<Collider>());
                    blob.transform.SetParent(go.transform, false);
                    float a = i * 1.26f + (float)rnd.NextDouble();
                    var off = i == 0 ? Vector3.zero : new Vector3(Mathf.Cos(a), (float)rnd.NextDouble() * 0.5f - 0.2f, Mathf.Sin(a)) * 0.7f;
                    blob.transform.localPosition = (new Vector3(0, 2.3f, 0) + off) * sc;
                    blob.transform.localScale = Vector3.one * (i == 0 ? 1.9f : 1.3f) * sc;
                    blob.GetComponent<Renderer>().sharedMaterial = leaf;
                }
            }
        }

        void BuildBrazier(Brazier br)
        {
            var go = new GameObject("Brazier3D");
            go.transform.SetParent(root, false);
            go.transform.position = To3D(br.transform.position);
            var iron = Plain(new Color(0.08f, 0.07f, 0.07f), 0.35f);
            var leg = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Destroy(leg.GetComponent<Collider>());
            leg.transform.SetParent(go.transform, false);
            leg.transform.localPosition = new Vector3(0, 0.4f, 0); leg.transform.localScale = new Vector3(0.12f, 0.4f, 0.12f);
            leg.GetComponent<Renderer>().sharedMaterial = iron;
            leg.GetComponent<Renderer>().shadowCastingMode = ShadowCastingMode.Off;
            var bowl = new GameObject("Bowl");
            bowl.transform.SetParent(go.transform, false);
            var mb = new MeshBuilder();
            mb.Cone(new Vector3(0, 1.05f, 0), 0.4f, -0.3f, 12); // inverted cone: a bowl
            Finish(bowl, mb, iron, shadows: false); // the fire sits in it: it must not shadow its own light
            var flame = new GameObject("Flame");
            flame.transform.SetParent(go.transform, false);
            var fm = new MeshBuilder();
            fm.Cone(new Vector3(0, 1.0f, 0), 0.26f, 0.7f, 8);
            Finish(flame, fm, Plain(new Color(1f, 0.5f, 0.15f), 0f, new Color(5f, 2.2f, 0.6f)), shadows: false);
            flame.AddComponent<FlameFlicker>().brazier = br;
        }

        // ------------------------------------------------------------ lights

        void SyncLights()
        {
            int shadowed = 0;
            foreach (var l2 in built.GetComponentsInChildren<UnityEngine.Rendering.Universal.Light2D>(true))
            {
                if (l2.lightType != UnityEngine.Rendering.Universal.Light2D.LightType.Point) continue;
                if (!lights.TryGetValue(l2, out var l3) || l3 == null)
                {
                    l3 = new GameObject("Light3D").AddComponent<Light>();
                    l3.transform.SetParent(root, false);
                    l3.type = LightType.Point;
                    bool fire = l2.GetComponentInParent<Brazier>() != null;
                    l3.shadows = fire && shadowed < 4 ? LightShadows.Soft : LightShadows.None;
                    if (l3.shadows != LightShadows.None) shadowed++;
                    lights[l2] = l3;
                }
                bool fireLight = l2.GetComponentInParent<Brazier>() != null;
                l3.transform.position = To3D(l2.transform.position, fireLight ? 1.35f : 1.8f);
                l3.color = l2.color;
                l3.range = l2.pointLightOuterRadius * S * 1.7f;
                l3.intensity = l2.intensity * (fireLight ? 7f : 4.5f);
                l3.enabled = l2.isActiveAndEnabled && l2.intensity > 0.01f;
            }
        }

        /// <summary>How brightly the fires light a point (sprites aren't lit by 3D lights, so they are tinted).</summary>
        Color LightAt(Vector3 p)
        {
            var c = new Color(0.68f, 0.69f, 0.78f) * ambientK;
            foreach (var l in lights.Values)
            {
                if (l == null || !l.enabled) continue;
                float d = Vector3.Distance(l.transform.position, p + Vector3.up);
                if (d >= l.range) continue;
                float k = 1f - d / l.range;
                c += l.color * (l.intensity * 0.12f * k * k);
            }
            return new Color(Mathf.Min(c.r, 1.25f), Mathf.Min(c.g, 1.25f), Mathf.Min(c.b, 1.25f));
        }

        // ------------------------------------------------------------ actors

        void SyncActors(PlayerController player)
        {
            var live = new List<Transform>();
            if (player != null) live.Add(player.transform);
            foreach (var e in EnemyBase.All) if (e != null) live.Add(e.transform);
            foreach (var pr in built.GetComponentsInChildren<Prop>()) if (pr.kind != "spring") live.Add(pr.transform);
            foreach (var mb in FindObjectsByType<MonoBehaviour>())
                if (mb != null && mb.isActiveAndEnabled && IsActorType(mb)) live.Add(mb.transform);

            var camRot = Quaternion.Euler(pitch * 0.55f, 0f, 0f); // stand up, leaning back toward the camera
            var flatRot = Quaternion.Euler(90f, 0f, 0f);
            var keep = new HashSet<Transform>(live);
            var gone = new List<Transform>();
            foreach (var kv in mirrored) if (!keep.Contains(kv.Key) || kv.Key == null) gone.Add(kv.Key);
            foreach (var t in gone)
            {
                var a = mirrored[t];
                // a slain pixel creature keeps its last pose, topples over in a spreading pool of blood and fades
                if (a.pix != null && a.board != null && a.body == null && a.parts.Count > 0 && t == null && EnemyBase.Slain.Remove(a.id))
                {
                    var bodyR = a.parts.Find(p => p.src == null && p.dst != null && p.dst.enabled).dst;
                    if (bodyR != null)
                    {
                        Corpse.Make(a.board, a.shadow, a.dir >= 0f ? 1f : -1f, a.vel, a.pix.Flip);
                        mirrored.Remove(t);
                        continue;
                    }
                }
                if (a.board != null) Destroy(a.board.gameObject);
                if (a.shadow != null) Destroy(a.shadow.gameObject);
                if (a.body != null && t != null) Destroy(a.body.gameObject); // a destroyed actor's body plays its death
                mirrored.Remove(t);
            }

            foreach (var t in live)
            {
                if (!mirrored.TryGetValue(t, out var a)) mirrored[t] = a = MakeActor(t);
                var pos = To3D(t.position);
                float dtv = Time.deltaTime;
                if (a.hasLast && dtv > 0f)
                {
                    var v = new Vector2(pos.x - a.last.x, pos.z - a.last.z) / dtv;
                    if (v.magnitude > 30f) v = Vector2.zero; // a teleport
                    a.vel = Vector2.Lerp(a.vel, v, 1f - Mathf.Exp(-dtv * 10f));
                }
                a.last = pos; a.hasLast = true;
                bool flat = IsFlat(t);
                a.board.SetPositionAndRotation(pos + (flat ? new Vector3(0, 0.03f, 0) : Vector3.zero), flat ? flatRot : camRot);
                a.shadow.gameObject.SetActive(!flat && a.body == null && t.GetComponent<FloatingText>() == null && t.GetComponent<BloodBolt>() == null);
                a.shadow.position = pos + new Vector3(0, 0.015f, 0);
                var tint = LightAt(pos);
                if (a.text.src != null)
                {
                    a.text.dst.text = a.text.src.text; a.text.dst.color = a.text.src.color;
                    a.text.dst.characterSize = a.text.src.characterSize * S;
                    a.text.dst.transform.localPosition = new Vector3(0, 1.8f, 0);
                    a.text.dst.transform.localScale = t.lossyScale;
                }
                bool brazier = t.GetComponent<Brazier>() != null;
                for (int i = a.parts.Count - 1; i >= 0; i--)
                {
                    var (src, dst) = a.parts[i];
                    if (src == null) { if (dst != null) Destroy(dst.gameObject); a.parts.RemoveAt(i); continue; }
                    dst.enabled = src.enabled && src.gameObject.activeInHierarchy && !(a.body != null && src.name is "Body" or "Head");
                    if (!dst.enabled) continue;
                    if ((a.folk.HasValue || a.pix != null) && src.name is "Head") { dst.enabled = false; continue; }
                    if (a.pix != null && src.name is "Body")
                    {
                        // a monster's strike leaves three red claw rakes in front of it
                        if (t.GetComponent<EnemyBase>() is EnemyBase ce)
                        {
                            if (ce.strikeT > a.lastStrike + 0.05f) ClawSlash.Spawn(root, pos, new Vector3(ce.face.x, 0f, ce.face.y));
                            a.lastStrike = ce.strikeT;
                        }
                        // a frame-animated pixel figure, upright to the camera so it isn't foreshortened
                        var spr = a.pix.Tick(t, a.vel, Time.deltaTime);
                        if (spr == null) { dst.enabled = false; continue; }
                        var still = a.pix.Still ?? spr;
                        float k = a.pix.height / Mathf.Max(0.01f, still.bounds.size.y * 0.82f);
                        dst.sprite = spr; dst.flipX = a.pix.Flip; dst.flipY = false;
                        var pc = src.color;
                        dst.color = new Color(pc.r * tint.r, pc.g * tint.g, pc.b * tint.b, pc.a);
                        // a hit flares the figure blood-red for a moment and squashes it against the blow
                        float hurt = t.GetComponent<EnemyBase>() is EnemyBase he ? Mathf.Clamp01(he.flash / 0.12f)
                                   : t.GetComponent<PlayerController>() is PlayerController hp ? Mathf.Clamp01((hp.hurtFlash - 0.15f) / 0.15f) : 0f;
                        if (hurt > 0f) dst.color = Color.Lerp(dst.color, new Color(1f, 0.25f, 0.2f, pc.a), hurt * 0.75f);
                        a.dir = a.pix.Flip ? -1f : 1f;
                        dst.transform.localPosition = new Vector3(0f, -still.bounds.min.y * k - still.bounds.size.y * 0.06f * k, -0.001f * src.sortingOrder);
                        dst.transform.localRotation = Quaternion.Euler(pitch * 0.45f, 0f, 0f); // board leans part-way; this finishes facing the camera
                        dst.transform.localScale = new Vector3(k * (1f + 0.08f * hurt), k * (1f - 0.06f * hurt), 1f);
                        continue;
                    }
                    if (a.folk.HasValue && src.name is "Body")
                    {
                        // a painted figure: full height, turned the way the actor goes, moved procedurally
                        var art = a.folk.Value;
                        float f = FolkFigures.Facing(t, a.vel);
                        if (f != 0f) a.dir = f;
                        FolkFigures.Motion(t, a.vel.magnitude, Time.time, a.seed, a.dir, out var off, out var lean, out var sc);
                        float k = art.height / Mathf.Max(0.01f, art.sprite.bounds.size.y);
                        dst.sprite = art.sprite; dst.flipX = a.dir != art.facing; dst.flipY = false;
                        var fc = src.color;
                        dst.color = new Color(fc.r * tint.r, fc.g * tint.g, fc.b * tint.b, fc.a);
                        dst.transform.localPosition = new Vector3(off.x, -art.sprite.bounds.min.y * k * sc.y + off.y, -0.001f * src.sortingOrder);
                        dst.transform.localRotation = Quaternion.Euler(0, 0, lean);
                        dst.transform.localScale = new Vector3(k * sc.x, k * sc.y, 1f);
                        continue;
                    }
                    dst.sprite = src.sprite; dst.flipX = src.flipX; dst.flipY = src.flipY;
                    var c = src.color;
                    dst.color = brazier ? c * 1.6f : new Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a);
                    Vector3 local = t.InverseTransformPoint(src.transform.position);
                    dst.transform.localPosition = new Vector3(local.x * S, local.y * S, -0.001f * src.sortingOrder);
                    dst.transform.localRotation = Quaternion.Euler(0, 0, src.transform.eulerAngles.z - t.eulerAngles.z);
                    var ls = src.transform.lossyScale;
                    dst.transform.localScale = new Vector3(ls.x * S, ls.y * S, 1f);
                    if (src.drawMode != SpriteDrawMode.Simple) { dst.drawMode = src.drawMode; dst.size = src.size; }
                }
            }
        }

        static readonly HashSet<string> ActorTypes = new()
        {
            "FloatingText", "SaltRing", "FirePatch", "SaltCrystal", "RootSpike", "Lurker", "Cameo",
            "BloodBolt", "BloodGeyser", "Gate", "Balaur",
        };

        static bool IsActorType(MonoBehaviour mb) => ActorTypes.Contains(mb.GetType().Name);
        static bool IsFlat(Transform t) => t.GetComponent<SaltRing>() != null || t.GetComponent<FirePatch>() != null || t.GetComponent<BloodGeyser>() != null;

        /// <summary>Every line in the 2D scene (telegraphs, threads, rings, necks, beams) drawn flat just above the
        /// 3D ground.</summary>
        void SyncLines()
        {
            var seen = new HashSet<LineRenderer>();
            foreach (var src in FindObjectsByType<LineRenderer>())
            {
                if (src == null || (root != null && src.transform.IsChildOf(root))) continue;
                if (!lines.TryGetValue(src, out var dst) || dst == null)
                {
                    dst = new GameObject("Line3D").AddComponent<LineRenderer>();
                    dst.transform.SetParent(root, false);
                    dst.useWorldSpace = true;
                    dst.alignment = LineAlignment.TransformZ;
                    dst.transform.rotation = Quaternion.Euler(90f, 0f, 0f); // lie flat, facing up
                    dst.shadowCastingMode = ShadowCastingMode.Off;
                    lines[src] = dst;
                }
                seen.Add(src);
                dst.enabled = src.enabled && src.gameObject.activeInHierarchy && src.positionCount > 1;
                // the hunter's slash: a bright swoosh at waist height tracing the sword's real reach
                bool swoosh = dst.enabled && src.GetComponentInParent<Biertan.Player.PlayerController>() != null;
                if (!dst.enabled) continue;
                dst.sharedMaterial = src.sharedMaterial;
                dst.startColor = src.startColor; dst.endColor = src.endColor;
                dst.widthMultiplier = src.widthMultiplier * S; dst.widthCurve = src.widthCurve;
                if (swoosh)
                {
                    dst.widthMultiplier = 0.34f;
                    dst.widthCurve = new AnimationCurve(new Keyframe(0f, 0.05f), new Keyframe(0.75f, 1f), new Keyframe(1f, 0.3f));
                    var g = new Gradient();
                    g.SetKeys(new[] { new GradientColorKey(new Color(1f, 0.95f, 0.85f), 0f), new GradientColorKey(Color.white, 1f) },
                              new[] { new GradientAlphaKey(0f, 0f), new GradientAlphaKey(0.55f, 0.6f), new GradientAlphaKey(0.95f, 1f) });
                    dst.colorGradient = g;
                }
                dst.loop = src.loop;
                int n = src.positionCount;
                if (dst.positionCount != n) dst.positionCount = n;
                for (int i = 0; i < n; i++)
                {
                    var p = src.GetPosition(i);
                    if (!src.useWorldSpace) p = src.transform.TransformPoint(p);
                    dst.SetPosition(i, To3D(p, swoosh ? 0.55f : 0.05f));
                }
            }
            var dead = new List<LineRenderer>();
            foreach (var kv in lines) if (kv.Key == null || !seen.Contains(kv.Key)) dead.Add(kv.Key);
            foreach (var k in dead) { if (lines[k] != null) Destroy(lines[k].gameObject); lines.Remove(k); }
        }

        /// <summary>A pixel figure is drawn wider than the old sprite: grow the actor's collision circle (and an
        /// enemy's reach, which is measured from it) so bodies keep a believable distance instead of overlapping.</summary>
        static void FitBody(Transform t)
        {
            const float body = 18f; // half the drawn shoulder width, in 2D units
            var col = t.GetComponent<CircleCollider2D>();
            if (t.GetComponent<EnemyBase>() is EnemyBase e)
            {
                float b = e.kind == "pricolici" ? 22f : e.kind == "wolf" ? 15f : body; // the wolf-man stands broader
                if (e.radius < b) e.radius = b;
                if (col != null) col.radius = Mathf.Max(col.radius, e.radius * 0.95f);
            }
            else if (col != null) col.radius = Mathf.Max(col.radius, 16f);
        }

        Actor MakeActor(Transform t)
        {
            var a = new Actor();
            a.board = new GameObject("Board " + t.name).transform;
            a.board.SetParent(actors, false);
            foreach (var sr in t.GetComponentsInChildren<SpriteRenderer>(true))
            {
                if (sr.name is "Shadow" or "Label" || sr.GetComponent<TextMesh>() != null) continue;
                var go = new GameObject(sr.name);
                go.transform.SetParent(a.board, false);
                var dst = go.AddComponent<SpriteRenderer>();
                dst.sortingOrder = sr.sortingOrder;
                dst.shadowCastingMode = ShadowCastingMode.Off;
                a.parts.Add((sr, dst));
            }
            var tm = t.GetComponent<TextMesh>();
            if (tm != null)
            {
                var go = new GameObject("Text");
                go.transform.SetParent(a.board, false);
                var dtm = go.AddComponent<TextMesh>();
                dtm.font = tm.font; go.GetComponent<MeshRenderer>().sharedMaterial = tm.GetComponent<MeshRenderer>().sharedMaterial;
                dtm.anchor = tm.anchor; dtm.alignment = tm.alignment; dtm.fontSize = tm.fontSize;
                a.text = (tm, dtm);
            }
            a.body = CharacterBody.Enabled ? CharacterBody.Create(t, actors) : null;
            a.pix = PixelFigure.For(t);
            if (a.pix != null) FitBody(t);
            a.folk = a.pix == null ? FolkFigures.For(t) : null;
            a.seed = Random.value;
            a.id = t.GetEntityId();
            // a soft blob shadow on the ground
            var sh = new GameObject("BlobShadow");
            sh.transform.SetParent(actors, false);
            sh.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
            sh.transform.localScale = new Vector3(0.9f, 0.6f, 1f);
            var ssr = sh.AddComponent<SpriteRenderer>();
            ssr.sprite = Resources.Load<Sprite>("Sprites/circle");
            ssr.color = new Color(0, 0, 0, 0.45f);
            a.shadow = sh.transform;
            return a;
        }
    }
}

namespace Biertan.Visual3D
{
    /// <summary>What is left of a slain pixel creature: its last frame tips over onto the ground beside a pool of
    /// blood that spreads out, then both darken and fade away.</summary>
    public class Corpse : MonoBehaviour
    {
        Transform board, pool;
        SpriteRenderer[] parts; Color[] baseCol; SpriteRenderer poolR;
        Quaternion start; Vector3 startPos; float side, t;
        const float Fall = 0.35f, Stay = 2.2f, Fade = 1.0f;

        public static void Make(Transform board, Transform shadow, float facing, Vector2 vel, bool flipped)
        {
            var c = board.gameObject.AddComponent<Corpse>();
            c.board = board; c.start = board.rotation; c.startPos = board.position;
            // falls away from the blow: backwards from the way it was facing
            c.side = flipped ? -1f : 1f;
            c.parts = board.GetComponentsInChildren<SpriteRenderer>();
            foreach (var r in c.parts) if (r.name != "Body") r.enabled = false;
            c.baseCol = System.Array.ConvertAll(c.parts, r => r.color);
            if (shadow != null)
            {
                c.pool = shadow; c.poolR = shadow.GetComponent<SpriteRenderer>();
                shadow.gameObject.SetActive(true);
                shadow.localScale = new Vector3(0.2f, 0.12f, 1f);
            }
        }

        void Update()
        {
            t += Time.deltaTime;
            float f = Mathf.Clamp01(t / Fall);
            float ease = 1f - (1f - f) * (1f - f);
            // tip over sideways about the feet and settle a touch into the ground
            board.rotation = start * Quaternion.Euler(0f, 0f, side * 82f * ease);
            board.position = startPos + new Vector3(0f, -0.04f * ease, 0f);
            float dark = Mathf.Lerp(1f, 0.55f, Mathf.Clamp01(t / (Fall + Stay)));
            float alpha = 1f - Mathf.Clamp01((t - Fall - Stay) / Fade);
            for (int i = 0; i < parts.Length; i++)
            {
                if (parts[i] == null || !parts[i].enabled) continue;
                var b = baseCol[i];
                parts[i].color = new Color(b.r * dark, b.g * dark * 0.9f, b.b * dark * 0.9f, b.a * alpha);
            }
            if (pool != null)
            {
                float g = Mathf.Clamp01((t - 0.15f) / 1.2f);
                float sz = Mathf.Lerp(0.2f, 1.1f, 1f - (1f - g) * (1f - g));
                pool.position = startPos + new Vector3(-side * 0.35f, 0.012f, 0f);
                pool.localScale = new Vector3(sz, sz * 0.6f, 1f);
                poolR.color = new Color(0.32f, 0.02f, 0.03f, 0.75f * alpha);
            }
            if (t > Fall + Stay + Fade)
            {
                if (pool != null) Destroy(pool.gameObject);
                Destroy(board.gameObject);
            }
        }
    }

    /// <summary>Three red claw rakes swept through the air in front of a striking monster, fading fast.</summary>
    public class ClawSlash : MonoBehaviour
    {
        LineRenderer[] rakes; float t;
        const float Life = 0.32f;

        public static void Spawn(Transform parent, Vector3 at, Vector3 dir)
        {
            if (dir.sqrMagnitude < 0.0001f) dir = Vector3.back;
            dir.Normalize();
            var go = new GameObject("ClawSlash");
            go.transform.SetParent(parent, false);
            go.transform.SetPositionAndRotation(at + Vector3.up * 0.75f, Quaternion.LookRotation(dir, Vector3.up));
            var c = go.AddComponent<ClawSlash>();
            var mat = Resources.Load<Material>("LineMat");
            c.rakes = new LineRenderer[3];
            for (int i = 0; i < 3; i++)
            {
                var lr = new GameObject("Rake").AddComponent<LineRenderer>();
                lr.transform.SetParent(go.transform, false);
                lr.useWorldSpace = false; lr.sharedMaterial = mat; lr.positionCount = 9;
                lr.alignment = LineAlignment.View; lr.numCapVertices = 2;
                lr.shadowCastingMode = ShadowCastingMode.Off;
                lr.widthCurve = new AnimationCurve(new Keyframe(0f, 0f), new Keyframe(0.5f, 1f), new Keyframe(1f, 0f));
                lr.widthMultiplier = 0.09f;
                c.rakes[i] = lr;
            }
            c.Draw(0f);
        }

        void Draw(float k)
        {
            // a diagonal downward rake from upper-left to lower-right, revealed as k goes 0..1
            for (int i = 0; i < 3; i++)
            {
                var lr = rakes[i];
                float off = (i - 1) * 0.16f;
                for (int j = 0; j < lr.positionCount; j++)
                {
                    float u = Mathf.Min(j / (lr.positionCount - 1f), Mathf.Clamp01(k * 1.6f));
                    float x = Mathf.Lerp(-0.45f, 0.45f, u) + off * 0.3f;
                    float y = Mathf.Lerp(0.45f, -0.4f, u) + off;
                    float z = 0.55f + Mathf.Sin(u * Mathf.PI) * 0.18f;
                    lr.SetPosition(j, new Vector3(x, y, z));
                }
                var col = new Color(0.85f, 0.08f, 0.06f, (1f - k) * 0.95f);
                lr.startColor = col; lr.endColor = new Color(1f, 0.55f, 0.45f, col.a);
            }
        }

        void Update()
        {
            t += Time.deltaTime;
            Draw(Mathf.Clamp01(t / Life));
            if (t >= Life) Destroy(gameObject);
        }
    }

    /// <summary>A burst of short pale streaks and red flecks where the hunter's blade bites.</summary>
    public class HitSpark : MonoBehaviour
    {
        LineRenderer[] streaks; Vector3[] dirs; float t;
        const float Life = 0.16f;

        public static void Spawn(Transform parent, Vector3 at, Vector3 dir)
        {
            if (dir.sqrMagnitude < 0.0001f) dir = Vector3.back;
            dir.Normalize();
            var go = new GameObject("HitSpark");
            go.transform.SetParent(parent, false);
            go.transform.position = at;
            var c = go.AddComponent<HitSpark>();
            var mat = Resources.Load<Material>("LineMat");
            int n = 7;
            c.streaks = new LineRenderer[n]; c.dirs = new Vector3[n];
            for (int i = 0; i < n; i++)
            {
                var lr = new GameObject("Streak").AddComponent<LineRenderer>();
                lr.transform.SetParent(go.transform, false);
                lr.useWorldSpace = false; lr.sharedMaterial = mat; lr.positionCount = 2;
                lr.alignment = LineAlignment.View; lr.shadowCastingMode = ShadowCastingMode.Off;
                lr.widthCurve = new AnimationCurve(new Keyframe(0f, 1f), new Keyframe(1f, 0.1f));
                lr.widthMultiplier = i < 4 ? 0.045f : 0.07f;
                // mostly along the blow, fanned out, some flung upward
                var d = Quaternion.Euler(Random.Range(-35f, 35f), Random.Range(-55f, 55f), 0f) * dir;
                d.y += Random.Range(0.1f, 0.7f);
                c.dirs[i] = d.normalized * Random.Range(0.5f, 0.95f);
                c.streaks[i] = lr;
            }
            c.Draw(0f);
        }

        void Draw(float k)
        {
            float e = 1f - (1f - k) * (1f - k);
            for (int i = 0; i < streaks.Length; i++)
            {
                var lr = streaks[i];
                lr.SetPosition(0, dirs[i] * (0.15f + e * 0.55f));
                lr.SetPosition(1, dirs[i] * (0.15f + e * 0.55f + 0.18f * (1f - k)));
                var col = i < 4 ? new Color(1f, 0.93f, 0.75f, 1f - k) : new Color(0.7f, 0.05f, 0.05f, 1f - k);
                lr.startColor = col; lr.endColor = col;
            }
        }

        void Update()
        {
            t += Time.unscaledDeltaTime;
            Draw(Mathf.Clamp01(t / Life));
            if (t >= Life) Destroy(gameObject);
        }
    }

    /// <summary>Wobbles a 3D brazier flame and hides it while the brazier is out.</summary>
    public class FlameFlicker : MonoBehaviour
    {
        public Brazier brazier;
        void Update()
        {
            bool lit = brazier != null && brazier.lit;
            transform.localScale = lit ? new Vector3(1f, 0.85f + 0.25f * Mathf.PerlinNoise(Time.time * 6f, transform.position.x), 1f) : Vector3.zero;
        }
    }
}
