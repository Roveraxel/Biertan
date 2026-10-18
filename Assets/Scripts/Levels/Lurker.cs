using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>A pair of red eyes that watches the hunter from the dark, follows at a distance, blinks,
    /// and slips away when approached. Port of lurker.gd.</summary>
    public class Lurker : MonoBehaviour
    {
        public static readonly List<Lurker> All = new();

        PlayerController player;
        float life, fade, blinkT, closed;
        bool fleeing;
        Light2D glow;
        SpriteRenderer[] eyes;

        void OnEnable() => All.Add(this);
        void OnDisable() => All.Remove(this);

        void Start()
        {
            player = FindAnyObjectByType<PlayerController>();
            life = Random.Range(5f, 9f);
            blinkT = Random.Range(1.2f, 3f);
            glow = Lights.Point(transform, 80f, new Color(1f, 0.1f, 0.06f), 0f, new Vector2(0, 40));
            eyes = new SpriteRenderer[4];
            for (int i = 0; i < 2; i++)
            {
                float side = i == 0 ? -1f : 1f;
                eyes[i * 2] = Eye(new Vector2(side * 9f, 40f), new Vector2(14f, 14f), 0f, 60);       // halo
                eyes[i * 2 + 1] = Eye(new Vector2(side * 9f, 40f), new Vector2(10f, 5f), -side * 14f, 61); // slanted eye
            }
            AudioManager.I?.Sfx("whisper", -9f);
        }

        SpriteRenderer Eye(Vector2 pos, Vector2 size, float rot, int order)
        {
            var go = new GameObject("Eye");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = pos;
            go.transform.localScale = new Vector3(size.x, size.y, 1);
            go.transform.localRotation = Quaternion.Euler(0, 0, rot);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/circle");
            sr.sharedMaterial = Resources.Load<Material>("LineMat"); // unlit: eyes glow in the dark
            sr.sortingOrder = order;
            return sr;
        }

        void Update()
        {
            float dt = Time.deltaTime;
            if (player == null) { Destroy(gameObject); return; }
            Vector2 to = player.transform.position - transform.position;
            float d = to.magnitude;
            if (!fleeing)
            {
                if (d > 390f) transform.position += (Vector3)(to.normalized * 95f * dt);
                if (d < 150f || life <= 0f) { fleeing = true; AudioManager.I?.Sfx("flee", -10f); }
            }
            life -= dt;
            if (fleeing)
            {
                fade -= dt * 3.5f;
                if (fade <= 0f) { Destroy(gameObject); return; }
            }
            else fade = Mathf.MoveTowards(fade, 1f, dt * 1.4f);
            blinkT -= dt;
            if (blinkT <= 0f) { closed = 0.16f; blinkT = Random.Range(1.5f, 3.5f); }
            closed = Mathf.Max(0f, closed - dt);
            float vis = closed > 0f ? 0f : fade;
            glow.intensity = 1.7f * vis;
            Vector3 look = to.normalized * 1.6f;
            for (int i = 0; i < 4; i++)
            {
                var c = i % 2 == 0 ? new Color(1f, 0.1f, 0.06f, 0.28f * vis) : new Color(1f, 0.16f, 0.1f, vis);
                eyes[i].color = c;
                float side = i < 2 ? -1f : 1f;
                eyes[i].transform.localPosition = new Vector3(side * 9f, 40f, 0) + look;
            }
        }
    }
}
