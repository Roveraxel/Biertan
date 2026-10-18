using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Biertan.Core;
using Biertan.Enemies;
using Biertan.Levels;
using Biertan.Player;

namespace Biertan.EditorTools
{
    /// <summary>
    /// Menu: Biertan ▸ Build Test Arena. Creates the shared prefabs (enemy, salt ring, fire patch,
    /// floating text, ring FX) and a playable sandbox scene, so nothing has to be wired by hand.
    /// Safe to run again: it overwrites its own prefabs and scene.
    /// </summary>
    public static class BiertanSceneBuilder
    {
        const string PrefabDir = "Assets/Prefabs";
        const string ScenePath = "Assets/Scenes/TestArena.unity";

        static int World => LayerMask.NameToLayer("World");
        static int PlayerL => LayerMask.NameToLayer("Player");
        static int EnemyL => LayerMask.NameToLayer("Enemy");

        [MenuItem("Biertan/Build Test Arena")]
        public static void Build() => BuildScene(ScenePath, "sandbox");

        [MenuItem("Biertan/Build Boss Test: Varcolac")]
        public static void BuildVarcolac() => BuildScene("Assets/Scenes/Boss_Varcolac.unity", "arena");

        [MenuItem("Biertan/Build Boss Test: Muma Padurii")]
        public static void BuildMuma() => BuildScene("Assets/Scenes/Boss_Muma.unity", "hollow");

        [MenuItem("Biertan/Build Game: New Game in Saschiz")]
        public static void BuildSaschiz() => BuildScene("Assets/Scenes/Game_Saschiz.unity", "hub");

        [MenuItem("Biertan/Build Level Test: Wolf Forest")]
        public static void BuildForest() => BuildScene("Assets/Scenes/Level_Forest.unity", "forest");

        [MenuItem("Biertan/Build Level Test: Richis (chapter 2)")]
        public static void BuildRichis() => BuildScene("Assets/Scenes/Level_Richis.unity", "richis");

        [MenuItem("Biertan/Build Level Test: Hollow Hills")]
        public static void BuildHills() => BuildScene("Assets/Scenes/Level_Hills.unity", "hills");

        [MenuItem("Biertan/Build Level Test: Salt Caves")]
        public static void BuildCaves() => BuildScene("Assets/Scenes/Level_Caves.unity", "caves");

        [MenuItem("Biertan/Build Level Test: Mosna (chapter 3)")]
        public static void BuildMosna() => BuildScene("Assets/Scenes/Level_Mosna.unity", "mosna");

        [MenuItem("Biertan/Build Level Test: Burnt Vineyards")]
        public static void BuildVineyard() => BuildScene("Assets/Scenes/Level_Vineyard.unity", "vineyard");

        [MenuItem("Biertan/Build Boss Test: Balaur")]
        public static void BuildBalaur() => BuildScene("Assets/Scenes/Boss_Balaur.unity", "gorge");

        [MenuItem("Biertan/Build Level Test: Biertan (chapter 4)")]
        public static void BuildBiertan() => BuildScene("Assets/Scenes/Level_Biertan.unity", "biertan");

        [MenuItem("Biertan/Build Level Test: Three Walls")]
        public static void BuildWalls() => BuildScene("Assets/Scenes/Level_Walls.unity", "walls");

        [MenuItem("Biertan/Build Boss Test: Strigoi Vlad")]
        public static void BuildVlad() => BuildScene("Assets/Scenes/Boss_Vlad.unity", "church");

        [MenuItem("Biertan/Setup 2D Lighting")]
        public static void Setup2DLighting()
        {
            const string rdPath = "Assets/Settings/Biertan_Renderer2D.asset";
            const string urpPath = "Assets/Settings/Biertan_URP2D.asset";
            Directory.CreateDirectory("Assets/Settings");
            var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(urpPath);
            if (urp == null)
            {
                var rd = ScriptableObject.CreateInstance<Renderer2DData>();
                AssetDatabase.CreateAsset(rd, rdPath);
                urp = UniversalRenderPipelineAsset.Create(rd);
                AssetDatabase.CreateAsset(urp, urpPath);
                AssetDatabase.SaveAssets();
            }
            GraphicsSettings.defaultRenderPipeline = urp;
            int keep = QualitySettings.GetQualityLevel();
            for (int i = 0; i < QualitySettings.names.Length; i++)
            {
                QualitySettings.SetQualityLevel(i, false);
                QualitySettings.renderPipeline = urp;
            }
            QualitySettings.SetQualityLevel(keep, false);
            AssetDatabase.SaveAssets();
            Debug.Log("Biertan: 2D renderer active (lanterns, fires, dusk).");
        }

        static void BuildScene(string scenePath, string levelId)
        {
            bool sandbox = levelId == "sandbox";
            Setup2DLighting(); // before any SpriteRenderer is created, so they all get the lit sprite material
            if (World < 0 || PlayerL < 0 || EnemyL < 0)
            {
                EditorUtility.DisplayDialog("Biertan", "Layers World / Player / Enemy are missing (Project Settings ▸ Tags and Layers).", "OK");
                return;
            }
            Directory.CreateDirectory(PrefabDir);
            Directory.CreateDirectory("Assets/Art");
            AssetDatabase.Refresh();

            // physics: creatures don't shove each other (they use soft separation), everything hits walls & the hunter
            Physics2D.IgnoreLayerCollision(EnemyL, EnemyL, true);
            Physics2D.IgnoreLayerCollision(PlayerL, EnemyL, false);
            Physics2D.gravity = Vector2.zero;

            var lineMat = LineMaterial();
            var white = Load("white");
            var circle = Load("circle");

            var ring = MakeRingPrefab(lineMat);
            var text = MakeTextPrefab();
            var fire = MakeFirePatchPrefab(circle);
            var salt = MakeSaltRingPrefab(circle, lineMat);
            var enemy = MakeEnemyPrefab(white, circle);

            // ---------------- scene
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
            var cam = camGo.AddComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = 360;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.05f, 0.06f, 0.08f);
            cam.nearClipPlane = -1000; cam.farClipPlane = 1000;
            camGo.transform.position = new Vector3(0, 0, -100);
            var follow = camGo.AddComponent<CameraFollow>();
            camGo.AddComponent<AudioListener>();

            var sys = new GameObject("Systems");
            sys.AddComponent<GameManager>();
            var am = sys.AddComponent<AudioManager>();
            am.sfxSource = sys.AddComponent<AudioSource>();
            am.musicSource = sys.AddComponent<AudioSource>();
            am.sfxSource.playOnAwake = am.musicSource.playOnAwake = false;
            var reg = sys.AddComponent<PrefabRegistry>();
            reg.enemy = enemy; reg.firePatch = fire; reg.saltRing = salt; reg.floatingText = text; reg.ring = ring;

            // fade overlay
            var canvasGo = new GameObject("Overlay", typeof(Canvas), typeof(CanvasScaler));
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 100;
            var fadeGo = new GameObject("Fade", typeof(RectTransform), typeof(Image));
            fadeGo.transform.SetParent(canvasGo.transform, false);
            var rt = fadeGo.GetComponent<RectTransform>();
            rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one; rt.offsetMin = rt.offsetMax = Vector2.zero;
            var img = fadeGo.GetComponent<Image>();
            img.color = new Color(0, 0, 0, 0);
            img.raycastTarget = false;
            var fade = canvasGo.AddComponent<ScreenFade>();
            fade.overlay = img;

            var ambient = new GameObject("Global Light");
            ambient.AddComponent<Light2D>();
            ambient.AddComponent<AmbientLight>();

            if (sandbox) BuildSandboxGround(white, circle);

            // player
            var pc = MakePlayer(cam, follow, salt, white, circle, lineMat);

            if (sandbox)
            {
                var arena = new GameObject("TestArena").AddComponent<TestArena>();
                arena.player = pc;
            }
            else
            {
                var host = new GameObject("LevelHost").AddComponent<LevelHost>();
                host.player = pc;
                host.levelId = levelId;
                host.chapterGear = levelId != "hub";
                host.gameObject.AddComponent<DebugHud>();
            }

            EditorSceneManager.SaveScene(scene, scenePath);
            AddToBuildSettings(scenePath);
            AssetDatabase.SaveAssets();
            Debug.Log("Biertan: scene built at " + scenePath + ". Press Play.");
        }

        static void BuildSandboxGround(Sprite white, Sprite circle)
        {
            // ground + walls (a 2400 x 1600 clearing)
            var ground = MakeSprite("Ground", white, new Color(0.17f, 0.24f, 0.15f), -1000);
            ground.transform.localScale = new Vector3(2400, 1600, 1);
            for (int i = 0; i < 26; i++) // a few dark tufts so movement reads
            {
                var tuft = MakeSprite("Tuft", circle, new Color(0.12f, 0.19f, 0.11f), -999);
                tuft.transform.position = new Vector3(Random.Range(-1100f, 1100f), Random.Range(-740f, 740f), 0);
                float s = Random.Range(40f, 140f);
                tuft.transform.localScale = new Vector3(s, s * 0.55f, 1);
            }
            Wall("Wall N", white, new Vector2(0, 820), new Vector2(2500, 40));
            Wall("Wall S", white, new Vector2(0, -820), new Vector2(2500, 40));
            Wall("Wall W", white, new Vector2(-1220, 0), new Vector2(40, 1680));
            Wall("Wall E", white, new Vector2(1220, 0), new Vector2(40, 1680));
            Wall("Rock", white, new Vector2(-180, 260), new Vector2(120, 70));
            Wall("Rock", white, new Vector2(260, -300), new Vector2(90, 90));
        }

        static PlayerController MakePlayer(Camera cam, CameraFollow follow, GameObject salt, Sprite white, Sprite circle, Material lineMat)
        {
            var pGo = new GameObject("Player");
            pGo.layer = PlayerL;
            var rb = pGo.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            rb.collisionDetectionMode = CollisionDetectionMode2D.Continuous;
            var col = pGo.AddComponent<CircleCollider2D>();
            col.radius = 12;
            var pc = pGo.AddComponent<PlayerController>();
            pc.mainCamera = cam;
            pc.saltRingPrefab = salt;
            var shadow = MakeSprite("Shadow", circle, new Color(0, 0, 0, 0.4f), -1, pGo.transform);
            shadow.transform.localPosition = new Vector3(0, -2, 0);
            shadow.transform.localScale = new Vector3(30, 13.5f, 1);
            var view = pGo.AddComponent<PlayerView>();
            view.player = pc;
            view.body = MakeSprite("Body", Load("wanderer_idle"), Color.white, 0, pGo.transform);
            view.aura = MakeSprite("VampAura", circle, new Color(0.7f, 0, 0.1f, 0.3f), 1, pGo.transform);
            view.aura.transform.localPosition = new Vector3(0, 30, 0);
            view.aura.transform.localScale = new Vector3(52, 52, 1);
            view.aura.enabled = false;
            view.frost = MakeSprite("Frost", white, new Color(0.75f, 0.9f, 1f, 0.45f), 2, pGo.transform);
            view.frost.transform.localPosition = new Vector3(0, 29, 0);
            view.frost.transform.localScale = new Vector3(40, 62, 1);
            view.frost.enabled = false;
            var arcGo = new GameObject("SwordArc");
            arcGo.transform.SetParent(pGo.transform, false);
            var arc = arcGo.AddComponent<LineRenderer>();
            arc.useWorldSpace = false; arc.widthMultiplier = 4; arc.sharedMaterial = lineMat;
            arc.startColor = arc.endColor = new Color(1, 0.95f, 0.8f, 0.85f);
            arc.sortingOrder = 5; arc.enabled = false;
            view.arc = arc;
            follow.target = pGo.transform;
            // the wanderer's lantern (player.gd: radius 300, warm, 0.95)
            Lights.Point(pGo.transform, 300f, new Color(1f, 0.82f, 0.5f), 0.95f, new Vector2(-11, 12));
            return pc;
        }

        // ------------------------------------------------------------------ prefabs

        static EnemyBase MakeEnemyPrefab(Sprite white, Sprite circle)
        {
            var go = new GameObject("Enemy");
            go.layer = EnemyL;
            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            var col = go.AddComponent<CircleCollider2D>();
            col.radius = 11;
            var e = go.AddComponent<EnemyBase>();
            var shadow = MakeSprite("Shadow", circle, new Color(0, 0, 0, 0.35f), -1, go.transform);
            shadow.transform.localPosition = new Vector3(0, -2, 0);
            shadow.transform.localScale = new Vector3(30, 13, 1);
            var v = go.AddComponent<EnemyView>();
            v.enemy = e;
            v.body = MakeSprite("Body", Load("wolf_idle"), Color.white, 0, go.transform);
            v.windupGlow = MakeSprite("Windup", circle, new Color(1, 0.2f, 0.1f, 0.3f), 1, go.transform);
            v.windupGlow.transform.localPosition = new Vector3(0, 14, 0);
            v.windupGlow.transform.localScale = new Vector3(48, 48, 1);
            v.windupGlow.enabled = false;
            v.barBack = MakeSprite("BarBack", white, new Color(0, 0, 0, 0.7f), 10, go.transform);
            v.barFill = MakeSprite("BarFill", white, new Color32(0xc0, 0x39, 0x2b, 0xff), 11, go.transform);
            return Save(go, "Enemy").GetComponent<EnemyBase>();
        }

        static GameObject MakeRingPrefab(Material lineMat)
        {
            var go = new GameObject("RingFx");
            var lr = go.AddComponent<LineRenderer>();
            lr.sharedMaterial = lineMat; lr.sortingOrder = 20;
            go.AddComponent<RingFx>();
            return Save(go, "RingFx");
        }

        static GameObject MakeTextPrefab()
        {
            var go = new GameObject("FloatingText");
            var tm = go.AddComponent<TextMesh>();
            tm.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            tm.GetComponent<MeshRenderer>().sharedMaterial = tm.font.material;
            tm.GetComponent<MeshRenderer>().sortingOrder = 50;
            tm.fontSize = 48; tm.characterSize = 4f;
            tm.anchor = TextAnchor.MiddleCenter;
            tm.alignment = TextAlignment.Center;
            go.AddComponent<FloatingText>();
            return Save(go, "FloatingText");
        }

        static GameObject MakeFirePatchPrefab(Sprite circle)
        {
            var go = new GameObject("FirePatch");
            var fp = go.AddComponent<FirePatch>();
            fp.disc = MakeSprite("Disc", circle, new Color(1, 0.5f, 0.1f, 0.6f), -900, go.transform);
            return Save(go, "FirePatch");
        }

        static GameObject MakeSaltRingPrefab(Sprite circle, Material lineMat)
        {
            var go = new GameObject("SaltRing");
            var sr = go.AddComponent<SaltRing>();
            sr.disc = MakeSprite("Disc", circle, new Color(0.9f, 0.92f, 1, 0.08f), -900, go.transform);
            var lr = go.AddComponent<LineRenderer>();
            lr.sharedMaterial = lineMat; lr.sortingOrder = -899;
            sr.edge = lr;
            return Save(go, "SaltRing");
        }

        // ------------------------------------------------------------------ helpers

        static GameObject Save(GameObject go, string name)
        {
            var path = $"{PrefabDir}/{name}.prefab";
            var prefab = PrefabUtility.SaveAsPrefabAsset(go, path);
            Object.DestroyImmediate(go);
            return prefab;
        }

        static Sprite Load(string name)
        {
            var s = AssetDatabase.LoadAssetAtPath<Sprite>($"Assets/Resources/Sprites/{name}.png");
            if (s == null) Debug.LogWarning("Biertan: missing sprite " + name);
            return s;
        }

        static SpriteRenderer MakeSprite(string name, Sprite s, Color c, int order, Transform parent = null)
        {
            var go = new GameObject(name);
            if (parent != null) go.transform.SetParent(parent, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = s; sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        static void Wall(string name, Sprite white, Vector2 pos, Vector2 size)
        {
            var sr = MakeSprite(name, white, new Color(0.33f, 0.31f, 0.29f), 0);
            sr.gameObject.layer = World;
            sr.transform.position = pos;
            sr.transform.localScale = new Vector3(size.x, size.y, 1);
            sr.gameObject.AddComponent<BoxCollider2D>(); // 1x1 box scaled with the transform
            sr.gameObject.isStatic = true;
        }

        static Material LineMaterial()
        {
            const string path = "Assets/Art/Line.mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (m != null) return m;
            var sh = Shader.Find("Universal Render Pipeline/2D/Sprite-Unlit-Default") ?? Shader.Find("Sprites/Default");
            m = new Material(sh);
            AssetDatabase.CreateAsset(m, path);
            return m;
        }

        static void AddToBuildSettings(string path)
        {
            var scenes = new System.Collections.Generic.List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            if (scenes.Exists(s => s.path == path)) return;
            scenes.Insert(0, new EditorBuildSettingsScene(path, true));
            EditorBuildSettings.scenes = scenes.ToArray();
        }
    }
}
