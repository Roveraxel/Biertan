using System.Collections;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>HUD-facing events (banners/toasts) the HUD script subscribes to. Decouples GameManager from UI.</summary>
    public static class HudEvents
    {
        public delegate void BannerHandler(string text, string sub);
        public delegate void ToastHandler(string text);
        public delegate void ContinueHandler(bool enabled);

        public static event BannerHandler OnBanner;
        public static event ToastHandler OnToast;
        public static event ContinueHandler OnContinueEnabled;

        public static void Banner(string text, string sub = "") => OnBanner?.Invoke(text, sub);
        public static void Toast(string text) => OnToast?.Invoke(text);
        public static void SetContinueEnabled(bool enabled) => OnContinueEnabled?.Invoke(enabled);
    }
}
