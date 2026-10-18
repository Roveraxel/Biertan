using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// An interactable world object: NPC, coin sack, torn fleece, signpost, lost ewe, haiduc treasure,
    /// healing spring. Port of prop.gd; what using one does lives in WorldEvents (main.gd prop_used).
    /// </summary>
    public class Prop : Interactable
    {
        public string kind = "npc";
        public string id = "";
        public string display = "";
        public string prompt = "";
        public Color col = new Color32(0xa0, 0x50, 0x30, 0xff);
        public bool used;
        public float regrow;

        float t;
        Light2D glow;
        SpriteRenderer body;
        GameObject visual;
        SpriteRenderer[] flames;
        TextMesh marker;
        SpriteRenderer hole, ember;
        GameObject purse;

        static Material unlit;
        static Material Unlit => unlit != null ? unlit : (unlit = Resources.Load<Material>("LineMat"));

        void Start()
        {
            gameObject.AddComponent<SortingGroup>();
            gameObject.layer = LayerMask.NameToLayer("World");
            if (kind is "npc" or "sign" or "sack" or "ewe" or "cross" or "greenman" or "bones")
            {
                var col2d = gameObject.AddComponent<CircleCollider2D>();
                col2d.radius = 12f;
            }
            if (kind != "spring") Part("Shadow", "circle", new Vector2(0, -2), new Vector2(30, 13), new Color(0, 0, 0, 0.35f), -1);
            visual = new GameObject("Visual");
            visual.transform.SetParent(transform, false);

            switch (kind)
            {
                case "npc":
                    body = Part("Body", "npc_" + id, Vector2.zero, Vector2.one, Color.white, 0, visual.transform);
                    if (body.sprite == null) // no portrait: a simple robed figure
                    {
                        body.sprite = Resources.Load<Sprite>("Sprites/circle");
                        body.transform.localScale = new Vector3(24, 30, 1);
                        body.transform.localPosition = new Vector3(0, 16, 0);
                        body.color = col;
                        Part("Head", "circle", new Vector2(0, 32), new Vector2(14, 14), new Color32(0xd9, 0xb4, 0x8f, 0xff), 1, visual.transform);
                    }
                    Label(display, new Vector2(0, 54), 13, new Color32(0xe8, 0xe0, 0xcc, 0xff), 60);
                    marker = Label("!", new Vector2(0, 72), 22, FxUtil.Amber, 61);
                    break;
                case "sack":
                    Part("Sack", "circle", new Vector2(0, 8), new Vector2(20, 20), new Color32(0x8a, 0x6a, 0x3a, 0xff), 0, visual.transform);
                    Part("Neck", "circle", new Vector2(0, 16), new Vector2(10, 10), new Color32(0x8a, 0x6a, 0x3a, 0xff), 1, visual.transform);
                    Part("Tie", "white", new Vector2(0, 19), new Vector2(8, 3), new Color32(0xc9, 0xa2, 0x4a, 0xff), 2, visual.transform);
                    break;
                case "fleece":
                    Part("Wool", "circle", new Vector2(0, 4), new Vector2(24, 24), new Color32(0xcf, 0xc6, 0xb3, 0xff), 0, visual.transform);
                    Part("Blood", "circle", new Vector2(8, 2), new Vector2(14, 14), new Color(0.6f, 0.12f, 0.12f, 0.6f), 1, visual.transform);
                    Part("Tuft", "circle", new Vector2(-6, 6), new Vector2(12, 12), new Color32(0xe8, 0xe0, 0xcc, 0xff), 1, visual.transform);
                    break;
                case "ewe":
                    var wool = new Color32(0xe8, 0xe2, 0xd2, 0xff);
                    var dark = new Color32(0x2a, 0x24, 0x20, 0xff);
                    Part("LegL", "white", new Vector2(-6.5f, 1), new Vector2(3, 6), dark, 0, visual.transform);
                    Part("LegR", "white", new Vector2(7.5f, 1), new Vector2(3, 6), dark, 0, visual.transform);
                    Part("Body", "circle", new Vector2(0, 12), new Vector2(26, 26), wool, 1, visual.transform);
                    Part("WoolL", "circle", new Vector2(-8, 14), new Vector2(18, 18), new Color32(0xf0, 0xea, 0xdc, 0xff), 2, visual.transform);
                    Part("WoolR", "circle", new Vector2(8, 14), new Vector2(18, 18), new Color32(0xf0, 0xea, 0xdc, 0xff), 2, visual.transform);
                    Part("Head", "circle", new Vector2(14, 20), new Vector2(12, 12), dark, 3, visual.transform);
                    break;
                case "treasure":
                    glow = Lights.Point(transform, 160f, new Color(0.4f, 0.6f, 1f), 0f, new Vector2(0, 20));
                    flames = new SpriteRenderer[6];
                    for (int i = 0; i < 3; i++)
                    {
                        float x = (i - 1) * 9f;
                        flames[i * 2] = Part("Flame", "circle", new Vector2(x, 13), new Vector2(12, 26), new Color(0.35f, 0.55f, 1f, 0.85f), 1, visual.transform);
                        flames[i * 2 + 1] = Part("Core", "circle", new Vector2(x, 8), new Vector2(6, 15), new Color(0.8f, 0.9f, 1f, 0.9f), 2, visual.transform);
                        flames[i * 2].sharedMaterial = flames[i * 2 + 1].sharedMaterial = Unlit;
                    }
                    hole = Part("Hole", "circle", new Vector2(0, 2), new Vector2(24, 11), new Color32(0x1a, 0x14, 0x10, 0xff), -1, visual.transform);
                    break;
                case "cross":
                {
                    var wood = new Color32(0x4a, 0x33, 0x20, 0xff);
                    var gold = new Color32(0xc9, 0xa2, 0x4a, 0xff);
                    Part("Post", "white", new Vector2(0, 32), new Vector2(6, 64), wood, 0, visual.transform);
                    Part("Beam", "white", new Vector2(0, 49), new Vector2(36, 6), wood, 1, visual.transform);
                    Part("Roof", "tri", new Vector2(0, 68), new Vector2(48, 16), new Color32(0x2e, 0x22, 0x17, 0xff), 2, visual.transform);
                    Part("Sun", "circle", new Vector2(0, 40), new Vector2(10, 10), gold, 3, visual.transform);
                    for (int i = 0; i < 8; i++)
                    {
                        float a = i * Mathf.PI / 4f;
                        var ray = Part("Ray", "white", new Vector2(0, 40) + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 8f, new Vector2(4, 1.5f), gold, 3, visual.transform);
                        ray.transform.localRotation = Quaternion.Euler(0, 0, a * Mathf.Rad2Deg);
                    }
                    ember = Part("Ember", "circle", new Vector2(0, 6), new Vector2(6, 6), new Color(1f, 0.7f, 0.3f, 0.8f), 3, visual.transform);
                    ember.sharedMaterial = Unlit;
                    glow = Lights.Point(transform, 150f, new Color(1f, 0.8f, 0.5f), 0.5f, new Vector2(0, 30));
                    break;
                }
                case "bell": // the rope of the great bell
                    Part("Rope", "white", new Vector2(0, 60), new Vector2(6, 100), new Color32(0x8a, 0x7a, 0x5a, 0xff), 0, visual.transform);
                    Part("Knob", "circle", new Vector2(0, 8), new Vector2(14, 14), new Color32(0xb0, 0x8a, 0x3a, 0xff), 1, visual.transform);
                    break;
                case "greenman":
                {
                    Part("Stone", "white", new Vector2(0, 30), new Vector2(44, 52), new Color32(0x8d, 0x87, 0x7a, 0xff), 0, visual.transform);
                    Part("Face", "circle", new Vector2(0, 32), new Vector2(30, 30), new Color32(0x6a, 0x64, 0x58, 0xff), 1, visual.transform);
                    for (int i = 0; i < 7; i++)
                    {
                        float a = Mathf.PI + i * Mathf.PI / 6f; // Godot's upper half-circle of oak leaves
                        Part("Leaf", "circle", new Vector2(0, 32) + new Vector2(Mathf.Cos(a), -Mathf.Sin(a)) * 17f, new Vector2(14, 14), new Color32(0x5a, 0x6a, 0x44, 0xff), 2, visual.transform);
                    }
                    Part("EyeL", "circle", new Vector2(-5, 34), new Vector2(4, 4), new Color32(0x1a, 0x14, 0x10, 0xff), 3, visual.transform);
                    Part("EyeR", "circle", new Vector2(5, 34), new Vector2(4, 4), new Color32(0x1a, 0x14, 0x10, 0xff), 3, visual.transform);
                    Part("Mouth", "white", new Vector2(0, 24), new Vector2(12, 2), new Color32(0x3a, 0x3a, 0x2a, 0xff), 3, visual.transform);
                    break;
                }
                case "bones":
                    purse = new GameObject("Purse");
                    purse.transform.SetParent(visual.transform, false);
                    Part("Sack", "circle", new Vector2(0, 8), new Vector2(20, 20), new Color32(0x8a, 0x6a, 0x3a, 0xff), 0, purse.transform);
                    Part("Tie", "white", new Vector2(0, 19), new Vector2(8, 3), new Color32(0xc9, 0xa2, 0x4a, 0xff), 1, purse.transform);
                    var bone = Part("Bone", "white", new Vector2(-7, 4), new Vector2(22, 3), new Color32(0xd8, 0xd2, 0xc0, 0xff), 2, visual.transform);
                    bone.transform.localRotation = Quaternion.Euler(0, 0, 10);
                    Part("Skull", "circle", new Vector2(12, 6), new Vector2(12, 12), new Color32(0xd8, 0xd2, 0xc0, 0xff), 2, visual.transform);
                    Part("Socket", "circle", new Vector2(10, 7), new Vector2(3, 3), new Color32(0x1a, 0x14, 0x10, 0xff), 3, visual.transform);
                    break;
                case "sign":
                    Part("Post", "white", new Vector2(0, 17), new Vector2(4, 34), new Color32(0x4a, 0x33, 0x20, 0xff), 0, visual.transform);
                    Part("Board", "white", new Vector2(0, 32), new Vector2(32, 16), new Color32(0x6b, 0x4a, 0x2e, 0xff), 1, visual.transform);
                    Part("Carving", "white", new Vector2(0, 34), new Vector2(20, 2), new Color32(0x2a, 0x1c, 0x10, 0xff), 2, visual.transform);
                    break;
            }
        }

        SpriteRenderer Part(string n, string sprite, Vector2 local, Vector2 scale, Color c, int order, Transform parent = null)
        {
            var go = new GameObject(n);
            go.transform.SetParent(parent != null ? parent : transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(scale.x, scale.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + sprite);
            sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        TextMesh Label(string text, Vector2 local, int size, Color c, int order)
        {
            var go = new GameObject("Label");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            var tm = go.AddComponent<TextMesh>();
            tm.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var mr = tm.GetComponent<MeshRenderer>();
            mr.sharedMaterial = tm.font.material;
            mr.sortingOrder = order;
            tm.text = text; tm.fontSize = 48; tm.characterSize = size * 0.21f;
            tm.anchor = TextAnchor.MiddleCenter; tm.alignment = TextAlignment.Center;
            tm.color = c;
            return tm;
        }

        public override bool CanInteract()
        {
            var gm = GameManager.I;
            return kind switch
            {
                "crystal" => regrow <= 0f,
                "treasure" => !used && gm != null && gm.dusk >= 0.99f,
                "spring" => gm != null && !gm.SideHas("spring"),
                "ewe" => !used,
                _ => !(used && kind is "sack" or "cross" or "bones"),
            };
        }

        public override string PromptText() => prompt;
        public override void Interact() => WorldEvents.PropUsed(this);

        void Update()
        {
            if (visual == null) return; // not started yet
            t += Time.deltaTime;
            if (regrow > 0f) regrow = Mathf.Max(0f, regrow - Time.deltaTime);

            if (kind is "sack" or "ewe") visual.SetActive(!used);
            if (kind == "ewe" && !used) visual.transform.localPosition = new Vector3(0, Mathf.Sin(t * 3f), 0);
            if (kind == "npc" && body != null)
            {
                visual.transform.localPosition = new Vector3(0, -Mathf.Sin(t * 2f + transform.position.x), 0);
                marker.gameObject.SetActive(WorldEvents.MarkerFor(id));
                marker.transform.localPosition = new Vector3(0, 72 + Mathf.Sin(t * 4f) * 2f, 0);
            }
            if (kind == "cross")
            {
                ember.enabled = !used;
                ember.color = new Color(1f, 0.7f, 0.3f, 0.6f + 0.3f * Mathf.Sin(t * 5f));
                glow.intensity = used ? 0.25f : 0.5f;
            }
            if (kind == "bones") purse.SetActive(!used);
            if (kind == "treasure")
            {
                bool burning = CanInteract();
                glow.intensity = burning ? 0.9f + 0.2f * Mathf.Sin(t * 7f) : 0f;
                for (int i = 0; i < flames.Length; i++)
                {
                    flames[i].enabled = burning;
                    float h = 26f + 8f * Mathf.Sin(t * 9f + (i / 2) * 2f);
                    if (i % 2 == 0) { flames[i].transform.localScale = new Vector3(12, h, 1); flames[i].transform.localPosition = new Vector3(((i / 2) - 1) * 9f, h / 2f, 0); }
                    else { flames[i].transform.localScale = new Vector3(6, h * 0.6f, 1); flames[i].transform.localPosition = new Vector3(((i / 2) - 1) * 9f, h * 0.3f, 0); }
                }
                hole.enabled = used;
            }
        }
    }
}
