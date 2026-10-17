using UnityEngine;
using UnityEngine.InputSystem;

namespace Biertan.Core
{
    /// <summary>
    /// Thin input wrapper matching main.gd's setup_input() bindings exactly:
    /// move = WASD/arrows, dodge = Space/Shift, interact = E/Enter,
    /// potion = Q, attack = J or left mouse button, salt = R.
    /// </summary>
    public static class GameInput
    {
        public static Vector2 MoveVector()
        {
            var kb = Keyboard.current;
            if (kb == null) return Vector2.zero;
            float x = (kb.dKey.isPressed || kb.rightArrowKey.isPressed ? 1f : 0f)
                    - (kb.aKey.isPressed || kb.leftArrowKey.isPressed ? 1f : 0f);
            float y = (kb.sKey.isPressed || kb.downArrowKey.isPressed ? 1f : 0f)
                    - (kb.wKey.isPressed || kb.upArrowKey.isPressed ? 1f : 0f);
            var v = new Vector2(x, -y); // Godot's +y is down; Unity world +y is up, so flip for screen-space "down"
            return v.sqrMagnitude > 1f ? v.normalized : v;
        }

        public static bool AttackHeld() =>
            (Keyboard.current?.jKey.isPressed ?? false) || (Mouse.current?.leftButton.isPressed ?? false);

        public static bool DodgePressed() =>
            (Keyboard.current?.spaceKey.wasPressedThisFrame ?? false) || (Keyboard.current?.shiftKey.wasPressedThisFrame ?? false);

        public static bool InteractPressed() =>
            (Keyboard.current?.eKey.wasPressedThisFrame ?? false) || (Keyboard.current?.enterKey.wasPressedThisFrame ?? false);

        public static bool PotionPressed() => Keyboard.current?.qKey.wasPressedThisFrame ?? false;

        public static bool SaltPressed() => Keyboard.current?.rKey.wasPressedThisFrame ?? false;

        public static Vector2 MouseWorldPosition(Camera cam)
        {
            if (cam == null || Mouse.current == null) return Vector2.zero;
            Vector3 screen = Mouse.current.position.ReadValue();
            screen.z = -cam.transform.position.z;
            return cam.ScreenToWorldPoint(screen);
        }
    }
}
