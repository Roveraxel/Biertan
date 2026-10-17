namespace Biertan.Core
{
    /// <summary>What the HUD needs from a boss: the big health bar, its name, and a hint line.</summary>
    public interface IBoss
    {
        float Hp { get; }
        float MaxHp { get; }
        string HudName();
        string HudHint();
    }
}
