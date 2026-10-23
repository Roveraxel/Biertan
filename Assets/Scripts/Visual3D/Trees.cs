using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Visual3D
{
    /// <summary>
    /// Procedural low-poly trees for the 3D view, flat-shaded and a little crooked: autumn beeches and oaks with
    /// a bent trunk, a few limbs and lumpy leaf clumps; Carpathian spruces with ragged, drooping skirts; and in
    /// the deep woods some dead trees, bare and grey. Undergrowth (ferns, grass, stones) gathers at their feet.
    /// Everything is seeded from the tree's position, so the same tree grows the same way every time.
    /// </summary>
    public static class Trees
    {
        public struct Parts { public MeshBuilder bark, leaves, leaves2, ground, stone; }

        // muted, dark autumn: the land at dusk
        static readonly Color[] Autumn =
        {
            new(0.13f, 0.19f, 0.11f), new(0.2f, 0.23f, 0.11f), new(0.34f, 0.25f, 0.1f),
            new(0.33f, 0.16f, 0.08f), new(0.29f, 0.26f, 0.11f), new(0.16f, 0.21f, 0.13f),
        };
        public static Color LeafColor(int seed, int k) => Autumn[(seed + k * 3) % Autumn.Length];

        static void TriOut(MeshBuilder mb, Vector3 a, Vector3 b, Vector3 c, Vector3 inside)
        {
            var nrm = Vector3.Cross(b - a, c - a);
            if (Vector3.Dot(nrm, (a + b + c) / 3f - inside) < 0f) mb.Tri(a, c, b); else mb.Tri(a, b, c);
        }

        /// <summary>A tapering many-sided limb from a to b.</summary>
        public static void Limb(MeshBuilder mb, Vector3 a, Vector3 b, float ra, float rb, int sides = 6)
        {
            var dir = (b - a).normalized;
            var u = Vector3.Cross(dir, Mathf.Abs(dir.y) > 0.9f ? Vector3.right : Vector3.up).normalized;
            var w = Vector3.Cross(dir, u);
            for (int i = 0; i < sides; i++)
            {
                float t0 = i * Mathf.PI * 2f / sides, t1 = (i + 1) * Mathf.PI * 2f / sides;
                var o0 = u * Mathf.Cos(t0) + w * Mathf.Sin(t0);
                var o1 = u * Mathf.Cos(t1) + w * Mathf.Sin(t1);
                var p0 = a + o0 * ra; var p1 = a + o1 * ra; var q0 = b + o0 * rb; var q1 = b + o1 * rb;
                var mid = (a + b) / 2f;
                TriOut(mb, p0, p1, q1, mid); TriOut(mb, p0, q1, q0, mid);
            }
        }

        static readonly List<Vector3> icoV = new();
        static readonly List<int> icoT = new();
        static void Ico()
        {
            if (icoV.Count > 0) return;
            float t = (1f + Mathf.Sqrt(5f)) / 2f;
            var v = new List<Vector3> { new(-1, t, 0), new(1, t, 0), new(-1, -t, 0), new(1, -t, 0), new(0, -1, t), new(0, 1, t), new(0, -1, -t), new(0, 1, -t), new(t, 0, -1), new(t, 0, 1), new(-t, 0, -1), new(-t, 0, 1) };
            int[] f = { 0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11, 1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1 };
            // one subdivision: 80 faces, round enough to read as a leaf clump once it is roughed up
            var mid = new Dictionary<long, int>();
            int Mid(int a, int b)
            {
                long key = a < b ? ((long)a << 32) | (uint)b : ((long)b << 32) | (uint)a;
                if (mid.TryGetValue(key, out int m)) return m;
                v.Add((v[a] + v[b]) / 2f); return mid[key] = v.Count - 1;
            }
            var nf = new List<int>();
            for (int i = 0; i < f.Length; i += 3)
            {
                int a = f[i], b = f[i + 1], c = f[i + 2], ab = Mid(a, b), bc = Mid(b, c), ca = Mid(c, a);
                nf.AddRange(new[] { a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca });
            }
            foreach (var p in v) icoV.Add(p.normalized);
            icoT.AddRange(nf);
        }

        /// <summary>A lumpy, roughed-up ball of leaves (or a stone), flattened underneath.</summary>
        public static void Clump(MeshBuilder mb, Vector3 c, Vector3 size, System.Random rnd, float rough = 0.2f, float flatBottom = 0.55f, bool smooth = false)
        {
            Ico();
            var pts = new Vector3[icoV.Count];
            for (int i = 0; i < icoV.Count; i++)
            {
                var p = icoV[i];
                float k = 1f + ((float)rnd.NextDouble() * 2f - 1f) * rough;
                var q = Vector3.Scale(p * k, size);
                if (q.y < -size.y * flatBottom) q.y = -size.y * flatBottom;
                pts[i] = c + q;
            }
            if (!smooth) { for (int i = 0; i < icoT.Count; i += 3) TriOut(mb, pts[icoT[i]], pts[icoT[i + 1]], pts[icoT[i + 2]], c); return; }
            // soft shading: each corner's normal leans out from the clump's heart and a little toward the sky,
            // so a canopy reads as a mass of leaves rather than a cut gem
            for (int i = 0; i < icoT.Count; i += 3)
            {
                Vector3 a = pts[icoT[i]], b = pts[icoT[i + 1]], d = pts[icoT[i + 2]];
                Vector3 na = (icoV[icoT[i]] + Vector3.up * 0.35f).normalized, nb = (icoV[icoT[i + 1]] + Vector3.up * 0.35f).normalized, nd = (icoV[icoT[i + 2]] + Vector3.up * 0.35f).normalized;
                if (Vector3.Dot(Vector3.Cross(b - a, d - a), (a + b + d) / 3f - c) < 0f) mb.TriSmooth(a, d, b, na, nd, nb);
                else mb.TriSmooth(a, b, d, na, nb, nd);
            }
        }

        static readonly Vector3[] Ico0 = Ico0Verts();
        static readonly int[] Ico0F = { 0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11, 1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1 };
        static Vector3[] Ico0Verts()
        {
            float t = (1f + Mathf.Sqrt(5f)) / 2f;
            var v = new[] { new Vector3(-1, t, 0), new(1, t, 0), new(-1, -t, 0), new(1, -t, 0), new(0, -1, t), new(0, 1, t), new(0, -1, -t), new(0, 1, -t), new(t, 0, -1), new(t, 0, 1), new(-t, 0, -1), new(-t, 0, 1) };
            for (int i = 0; i < v.Length; i++) v[i] = v[i].normalized;
            return v;
        }

        /// <summary>Small leaf tufts poking out of a clump's skin, so its outline breaks up like real foliage.</summary>
        static void Tufts(MeshBuilder mb, Vector3 c, Vector3 size, System.Random rnd, int count)
        {
            for (int k = 0; k < count; k++)
            {
                float ang = (float)rnd.NextDouble() * Mathf.PI * 2f, el = ((float)rnd.NextDouble() - 0.25f) * 1.2f;
                var dir = new Vector3(Mathf.Cos(ang) * Mathf.Cos(el), Mathf.Sin(el), Mathf.Sin(ang) * Mathf.Cos(el));
                var at = c + Vector3.Scale(dir, size) * 0.95f;
                float r = size.x * (0.22f + (float)rnd.NextDouble() * 0.14f);
                for (int i = 0; i < Ico0F.Length; i += 3)
                {
                    Vector3 a = at + Ico0[Ico0F[i]] * r, b = at + Ico0[Ico0F[i + 1]] * r, d = at + Ico0[Ico0F[i + 2]] * r;
                    Vector3 na = (Ico0[Ico0F[i]] + dir + Vector3.up * 0.4f).normalized, nb = (Ico0[Ico0F[i + 1]] + dir + Vector3.up * 0.4f).normalized, nd = (Ico0[Ico0F[i + 2]] + dir + Vector3.up * 0.4f).normalized;
                    if (Vector3.Dot(Vector3.Cross(b - a, d - a), (a + b + d) / 3f - at) < 0f) mb.TriSmooth(a, d, b, na, nd, nb);
                    else mb.TriSmooth(a, b, d, na, nb, nd);
                }
            }
        }

        /// <summary>A broadleaf (beech, oak) in autumn, or a dead one with bare grey limbs.</summary>
        public static void Broadleaf(Parts p, Vector3 at, float sc, System.Random rnd, bool dead, bool low = false)
        {
            float h = (2.1f + (float)rnd.NextDouble() * 0.6f) * sc;
            var lean = new Vector3((float)rnd.NextDouble() - 0.5f, 0f, (float)rnd.NextDouble() - 0.5f) * 0.5f * sc;
            Vector3 a = at, b = at + new Vector3(0, h * 0.45f, 0) + lean * 0.4f, top = at + new Vector3(0, h, 0) + lean;
            float r0 = 0.2f * sc;
            Limb(p.bark, a + Vector3.down * 0.1f, b, r0 * 1.25f, r0 * 0.85f, 7);
            Limb(p.bark, b, top, r0 * 0.85f, r0 * 0.45f, 7);
            // roots flaring into the ground
            for (int i = 0; i < (low ? 0 : 4); i++)
            {
                float ang = i * Mathf.PI / 2f + (float)rnd.NextDouble();
                var d = new Vector3(Mathf.Cos(ang), 0, Mathf.Sin(ang));
                Limb(p.bark, a + Vector3.up * 0.35f * sc, a + d * 0.5f * sc + Vector3.down * 0.05f, r0 * 0.45f, r0 * 0.12f, 5);
            }
            int limbs = dead ? 6 : low ? 3 : 4;
            var ends = new List<Vector3> { top };
            for (int i = 0; i < limbs; i++)
            {
                float ang = i * Mathf.PI * 2f / limbs + (float)rnd.NextDouble() * 0.8f;
                float up = 0.45f + (float)rnd.NextDouble() * 0.5f;
                var start = Vector3.Lerp(b, top, 0.25f + (float)rnd.NextDouble() * 0.6f);
                var dir = new Vector3(Mathf.Cos(ang), up, Mathf.Sin(ang)).normalized;
                float len = (0.75f + (float)rnd.NextDouble() * 0.45f) * sc;
                var end = start + dir * len;
                Limb(p.bark, start, end, r0 * 0.4f, r0 * 0.12f, 5);
                if (dead)
                {
                    // gnarled twigs off each bare limb
                    var tw = end + (dir + new Vector3((float)rnd.NextDouble() - 0.5f, 0.3f, (float)rnd.NextDouble() - 0.5f)).normalized * 0.5f * sc;
                    Limb(p.bark, end, tw, r0 * 0.12f, r0 * 0.04f, 4);
                }
                ends.Add(end);
            }
            if (dead) return;
            // leaf clumps on the limb ends, the crown biggest; two shades so the canopy isn't one flat colour
            for (int i = 0; i < ends.Count; i++)
            {
                float s = (i == 0 ? 0.9f : 0.58f + (float)rnd.NextDouble() * 0.22f) * sc;
                var size = new Vector3(s, s * 0.72f, s);
                var cc = ends[i] + Vector3.up * 0.12f * sc;
                var mbL = i % 3 == 1 ? p.leaves2 : p.leaves;
                Clump(mbL, cc, size, rnd, 0.28f, 0.5f, true);
                if (!low) Tufts(mbL, cc, size, rnd, 7);
            }
        }

        /// <summary>A Carpathian spruce: a straight dark trunk under ragged tiers of drooping boughs.</summary>
        public static void Spruce(Parts p, Vector3 at, float sc, System.Random rnd, bool low = false)
        {
            float h = (4.2f + (float)rnd.NextDouble() * 1.4f) * sc;
            Limb(p.bark, at + Vector3.down * 0.1f, at + Vector3.up * h * 0.85f, 0.16f * sc, 0.05f * sc, 6);
            int tiers = low ? 4 : 6;
            for (int i = 0; i < tiers; i++)
            {
                float k = i / (float)(tiers - 1);
                float y = Mathf.Lerp(0.8f, h * 0.88f, k);
                float r = Mathf.Lerp(1.55f, 0.35f, k) * sc;
                float tierH = Mathf.Lerp(1.15f, 0.8f, k) * sc;
                var c = at + Vector3.up * y;
                var apex = c + Vector3.up * tierH;
                int seg = low ? 8 : 12;
                float twist = (float)rnd.NextDouble() * Mathf.PI;
                var mb = i % 2 == 0 ? p.leaves : p.leaves2;
                var rim = new Vector3[seg];
                for (int j = 0; j < seg; j++)
                {
                    float ang = twist + j * Mathf.PI * 2f / seg;
                    // ragged: boughs alternate long and short, and droop at the tips
                    float rr = r * (j % 2 == 0 ? 1f : 0.72f) * (0.9f + (float)rnd.NextDouble() * 0.2f);
                    float droop = j % 2 == 0 ? -0.28f * sc : 0.02f;
                    rim[j] = c + new Vector3(Mathf.Cos(ang) * rr, droop, Mathf.Sin(ang) * rr);
                }
                var inner = c + Vector3.up * tierH * 0.2f;
                for (int j = 0; j < seg; j++)
                {
                    var q0 = rim[j]; var q1 = rim[(j + 1) % seg];
                    TriOut(mb, q0, q1, apex, c + Vector3.down * 0.5f);
                    if (!low) TriOut(mb, q0, q1, inner, apex + Vector3.up * 2f); // underside, so the tiers aren't hollow from the low camera
                }
            }
        }

        /// <summary>Ferns, grass and the odd stone around a tree's feet.</summary>
        public static void Undergrowth(Parts p, Vector3 at, float sc, System.Random rnd)
        {
            int n = 3 + rnd.Next(4);
            for (int i = 0; i < n; i++)
            {
                float ang = (float)rnd.NextDouble() * Mathf.PI * 2f;
                float dist = (0.7f + (float)rnd.NextDouble() * 1.1f) * sc;
                var c = at + new Vector3(Mathf.Cos(ang) * dist, 0f, Mathf.Sin(ang) * dist);
                int blades = 5 + rnd.Next(4);
                float bh = 0.25f + (float)rnd.NextDouble() * 0.3f;
                for (int j = 0; j < blades; j++)
                {
                    float ba = j * Mathf.PI * 2f / blades + (float)rnd.NextDouble() * 0.4f;
                    var d = new Vector3(Mathf.Cos(ba), 0, Mathf.Sin(ba));
                    var side = Vector3.Cross(d, Vector3.up) * 0.05f;
                    var tip = c + d * bh * 0.9f + Vector3.up * bh;
                    p.ground.Tri(c - side, tip, c + side);
                    p.ground.Tri(c + side, tip, c - side);
                }
            }
            if (rnd.NextDouble() < 0.35)
            {
                float ang = (float)rnd.NextDouble() * Mathf.PI * 2f;
                var c = at + new Vector3(Mathf.Cos(ang), 0f, Mathf.Sin(ang)) * (1f + (float)rnd.NextDouble()) * sc;
                float s = 0.18f + (float)rnd.NextDouble() * 0.22f;
                Clump(p.stone, c, new Vector3(s * 1.3f, s * 0.7f, s), rnd, 0.25f, 0.3f);
            }
        }
    }
}
