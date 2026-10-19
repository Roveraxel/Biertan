using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Player
{
    /// <summary>
    /// C# port of player.gd. Movement, melee swing, tincture drinking, salt-ring throw,
    /// and the three boss-specific curses (madness / blood-vampirism / haste).
    ///
    /// Coordinate note: Godot's 2D +Y is down-screen; Unity's is up-screen. All vertical
    /// signs here are already flipped relative to the GDScript source so "facing down"
    /// means the same thing on screen in both engines.
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D))]
    [RequireComponent(typeof(CircleCollider2D))]
    public class PlayerController : MonoBehaviour
    {
        public event Action Died;

        [Header("Stats")]
        public float hp = 100f;
        public float maxHp = 100f;
        public float speed = 205f;
        public float dmg = 12f;

        [Header("Runtime")]
        public Vector2 facing = Vector2.right;
        public float attackT, attackCd, dodgeT, dodgeCd;
        public Vector2 dodgeDir = Vector2.right;
        public float invT, hurtFlash, slowT, walkT;
        public int potions = 1;
        public int coins = 20;
        public bool charmDodge, redThread, frozen, god;
        public int salt;
        public bool saltUnlocked, wormwood, oakHeart, garlic, torch;
        public Vector2 pull;
        public float saltCd, rootT;

        /// Muma Pădurii: grows with every hit, tinctures don't touch it.
        public float madness;
        /// Vlad: hits build the curse.
        public float blood;
        /// Time left as a vampire.
        public float vampT;
        /// Magda's bandage.
        public float hasteT;

        public Light2D light; // assign a 2D URP light in the prefab (see PointLight2D in Godot)

        Rigidbody2D rb;
        public Camera mainCamera;
        public GameObject saltRingPrefab;
        public Action<string> onToast; // wired to HudEvents.Toast by the spawner

        void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            rb.gravityScale = 0f;
            rb.mass = 20f; // creatures (mass 1) can't shove the hunter around; bosses (30-40) still can
            gameObject.layer = LayerMask.NameToLayer("Player"); // collision layer 2 equivalent
        }

        public void ResetStats()
        {
            maxHp = 100f;
            hp = maxHp;
            dmg = 12f;
            potions = 1;
            coins = 20;
            charmDodge = false;
            redThread = false;
            frozen = false;
            salt = 0;
            saltUnlocked = false;
            wormwood = false;
            oakHeart = false;
            garlic = false;
            torch = false;
        }

        void Update()
        {
            float dt = Time.deltaTime;
            attackCd = Mathf.Max(0f, attackCd - dt);
            dodgeCd = Mathf.Max(0f, dodgeCd - dt);
            invT = Mathf.Max(0f, invT - dt);
            attackT = Mathf.Max(0f, attackT - dt);
            hurtFlash = Mathf.Max(0f, hurtFlash - dt);
            slowT = Mathf.Max(0f, slowT - dt);
            saltCd = Mathf.Max(0f, saltCd - dt);
            rootT = Mathf.Max(0f, rootT - dt);

            if (vampT > 0f)
            {
                vampT = Mathf.Max(0f, vampT - dt);
                if (vampT <= 0f)
                    onToast?.Invoke("The vampire blood fades. You are yourself again.");
            }
            blood = Mathf.Max(0f, blood - dt * 0.25f);
            hasteT = Mathf.Max(0f, hasteT - dt);

            if (rootT > 0f && hp > 0f && !frozen)
            {
                rb.linearVelocity = Vector2.zero;
                if (GameInput.AttackHeld() && attackCd <= 0f) Swing();
                return;
            }

            if (frozen || hp <= 0f)
            {
                rb.linearVelocity = Vector2.MoveTowards(rb.linearVelocity, Vector2.zero, 1800f * dt);
                return;
            }

            Vector2 dir = GameInput.MoveVector();

            // facing: mouse-aim (desktop). Touch-mode auto-aim is handled separately by TouchUI when ported.
            Vector2 mouseWorld = GameInput.MouseWorldPosition(mainCamera);
            Vector2 md = mouseWorld - (Vector2)transform.position;
            if (md.magnitude > 8f) facing = md.normalized;
            else if (dir != Vector2.zero) facing = dir;

            if (dodgeT > 0f)
            {
                dodgeT -= dt;
                rb.linearVelocity = dodgeDir * (charmDodge ? 600f : 540f);
            }
            else
            {
                float sp = speed * (slowT > 0f ? 0.55f : 1f) * (hasteT > 0f ? 1.25f : 1f);
                rb.linearVelocity = Vector2.MoveTowards(rb.linearVelocity, dir * sp + pull, 2800f * dt);
                pull = Vector2.zero;

                if (GameInput.DodgePressed() && dodgeCd <= 0f)
                {
                    dodgeDir = dir != Vector2.zero ? dir : facing;
                    dodgeT = 0.22f;
                    invT = 0.32f;
                    dodgeCd = 0.75f * (charmDodge ? 0.9f : 1f);
                    FxUtil.Ring(transform.position, new Color(1, 1, 1, 0.5f), 32f);
                    AudioManager.I?.Sfx("dodge", -6f);
                }
                if (GameInput.AttackHeld() && attackCd <= 0f) Swing();
                if (GameInput.PotionPressed()) Drink();
                if (GameInput.SaltPressed()) ThrowSalt();
                if (GameInput.InteractPressed() && GameManager.I != null && GameManager.I.inputBlock <= 0f) Interactable.Nearest(transform.position)?.Interact();
            }

            if (dir != Vector2.zero) walkT += dt * 9f;
        }

        void Swing()
        {
            AudioManager.I?.Sfx("swing", -9f);
            attackT = 0.18f;
            attackCd = 0.36f;
            const float reach = 82f;
            foreach (var e in EnemyBase.All.ToArray()) // copy: Hurt() may kill/remove
            {
                Vector2 to = (Vector2)e.transform.position - (Vector2)transform.position;
                bool close = to.magnitude < e.radius + 26f;
                if (to.magnitude < reach + e.radius &&
                    (close || Vector2.Angle(facing, to) < 72f))
                {
                    e.Hurt(dmg, to.magnitude > 1f ? to.normalized : facing);
                    if (vampT > 0f) hp = Mathf.Min(maxHp, hp + 3f);
                }
            }
        }

        public void Drink()
        {
            if (potions > 0 && vampT > 0f)
            {
                potions--;
                hp = Mathf.Max(1f, hp - 30f);
                hurtFlash = 0.3f;
                AudioManager.I?.Sfx("sear", -2f);
                FxUtil.Text(transform.position, "-30  garlic burns!", new Color32(0xff, 0x6a, 0x5a, 0xff));
                return;
            }
            if (potions > 0 && hp < maxHp)
            {
                potions--;
                hp = Mathf.Min(maxHp, hp + 45f);
                AudioManager.I?.Sfx("potion", -3f);
                FxUtil.Text(transform.position, "+45", new Color32(0x7b, 0xd3, 0x6a, 0xff));
                FxUtil.Ring(transform.position, new Color32(0x7b, 0xd3, 0x6a, 0xff), 40f);
            }
        }

        public void ThrowSalt()
        {
            if (!saltUnlocked || saltCd > 0f) return;
            if (salt <= 0)
            {
                onToast?.Invoke("Your salt pouch is empty.");
                return;
            }
            salt--;
            saltCd = 1f;
            if (saltRingPrefab != null)
                Instantiate(saltRingPrefab, transform.position, Quaternion.identity);
            AudioManager.I?.Sfx("salt", -3f);
        }

        public void Hurt(float amount, Vector2 dir)
        {
            if (invT > 0f || hp <= 0f || god) return;
            hp -= amount;
            invT = 0.55f;

            var gm = GameManager.I;
            if (gm != null && gm.current == "hollow")
            {
                madness += amount;
                if (madness >= maxHp * 2f)
                {
                    madness = maxHp * 2f;
                    onToast?.Invoke("Your mind is lost in the wood.");
                    hp = 0f;
                }
            }
            if (gm != null && gm.current == "church" && vampT <= 0f)
            {
                blood += garlic ? 0.5f : 1f;
                if (blood >= 5f)
                {
                    blood = 0f;
                    vampT = 18f;
                    AudioManager.I?.Sfx("laugh", 0f, 1.2f);
                    HudEvents.Banner("VAMPIRISM", "His blood is in you. Tinctures burn, but your strikes drink.");
                }
            }
            hurtFlash = 0.25f;
            rb.linearVelocity = dir * 320f;
            AudioManager.I?.Sfx("hurt", -2f);
            FxUtil.Text(transform.position, Mathf.RoundToInt(amount).ToString(), new Color32(0xff, 0x6a, 0x5a, 0xff));
            if (hp <= 0f)
            {
                hp = 0f;
                Died?.Invoke();
            }
        }
    }
}
