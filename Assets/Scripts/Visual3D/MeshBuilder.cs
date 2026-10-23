using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Visual3D
{
    /// <summary>Small procedural mesh helper for the 3D view: flat-shaded quads and triangles with
    /// world-anchored UVs (in metres, so materials tile seamlessly across separate pieces).</summary>
    public class MeshBuilder
    {
        readonly List<Vector3> v = new();
        readonly List<Vector3> n = new();
        readonly List<Vector2> uv = new();
        readonly List<int> tri = new();

        static (Vector3 u, Vector3 w) Axes(Vector3 normal)
        {
            if (Mathf.Abs(normal.y) > 0.95f) return (Vector3.right, Vector3.forward);
            var u = Vector3.Cross(Vector3.up, normal).normalized;
            if (u.sqrMagnitude < 1e-6f) u = Vector3.right;
            return (u, Vector3.Cross(normal, u).normalized);
        }

        /// <summary>A quad a-b-c-d (clockwise seen from the front). offset is added for world UVs.</summary>
        public void Quad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 offset = default)
        {
            var normal = Vector3.Cross(b - a, c - a).normalized;
            var (u, w) = Axes(normal);
            int i = v.Count;
            foreach (var p in new[] { a, b, c, d })
            {
                v.Add(p); n.Add(normal);
                var wp = p + offset;
                uv.Add(new Vector2(Vector3.Dot(wp, u), Vector3.Dot(wp, w)));
            }
            tri.AddRange(new[] { i, i + 1, i + 2, i, i + 2, i + 3 });
        }

        public void Tri(Vector3 a, Vector3 b, Vector3 c)
        {
            var normal = Vector3.Cross(b - a, c - a).normalized;
            var (u, w) = Axes(normal);
            int i = v.Count;
            foreach (var p in new[] { a, b, c })
            {
                v.Add(p); n.Add(normal);
                uv.Add(new Vector2(Vector3.Dot(p, u), Vector3.Dot(p, w)));
            }
            tri.AddRange(new[] { i, i + 1, i + 2 });
        }

        /// <summary>A triangle with its own vertex normals, for soft-shaded rounded shapes.</summary>
        public void TriSmooth(Vector3 a, Vector3 b, Vector3 c, Vector3 na, Vector3 nb, Vector3 nc)
        {
            int i = v.Count;
            v.Add(a); v.Add(b); v.Add(c);
            n.Add(na); n.Add(nb); n.Add(nc);
            uv.Add(new Vector2(a.x, a.z)); uv.Add(new Vector2(b.x, b.z)); uv.Add(new Vector2(c.x, c.z));
            tri.AddRange(new[] { i, i + 1, i + 2 });
        }

        /// <summary>An axis-aligned box from min to max (no bottom).</summary>
        public void Box(Vector3 min, Vector3 max, bool top)
        {
            Vector3 p000 = min, p100 = new(max.x, min.y, min.z), p010 = new(min.x, max.y, min.z), p110 = new(max.x, max.y, min.z);
            Vector3 p001 = new(min.x, min.y, max.z), p101 = new(max.x, min.y, max.z), p011 = new(min.x, max.y, max.z), p111 = max;
            Quad(p000, p010, p110, p100); // front (-z), facing the camera
            Quad(p101, p111, p011, p001); // back
            Quad(p001, p011, p010, p000); // left
            Quad(p100, p110, p111, p101); // right
            if (top) Quad(p010, p011, p111, p110);
        }

        /// <summary>Crenellations along the top of a ring wall.</summary>
        public void Merlons(Vector3 min, Vector3 max)
        {
            float w = max.x - min.x, d = max.z - min.z;
            bool alongX = w >= d;
            float len = alongX ? w : d, step = 0.6f;
            for (float t = 0.1f; t + 0.3f < len; t += step)
            {
                var a = alongX ? new Vector3(min.x + t, max.y, min.z) : new Vector3(min.x, max.y, min.z + t);
                var b = alongX ? new Vector3(min.x + t + 0.3f, max.y + 0.3f, max.z) : new Vector3(max.x, max.y + 0.3f, min.z + t + 0.3f);
                Box(a, b, true);
            }
        }

        /// <summary>A broken wall: segments of uneven height.</summary>
        public void RuinBox(Vector3 min, Vector3 max, int seed)
        {
            var r = new System.Random(seed);
            float w = max.x - min.x;
            int n = Mathf.Max(2, (int)(w / 0.7f));
            for (int i = 0; i < n; i++)
            {
                float x0 = min.x + i * w / n, x1 = min.x + (i + 1) * w / n;
                float h = (max.y - min.y) * (0.35f + 0.65f * (float)r.NextDouble());
                Box(new Vector3(x0, min.y, min.z), new Vector3(x1, min.y + h, max.z), true);
            }
        }

        /// <summary>A pitched roof over the box, ridge along its longer side, with eaves overhang.</summary>
        public void Gable(Vector3 min, Vector3 max, float rise, float over)
        {
            float w = max.x - min.x, d = max.z - min.z, y = max.y;
            if (w >= d)
            {
                float zc = (min.z + max.z) / 2f;
                Vector3 a = new(min.x - over, y - over * 0.5f, min.z - over), b = new(max.x + over, y - over * 0.5f, min.z - over);
                Vector3 c = new(max.x + over, y + rise, zc), e = new(min.x - over, y + rise, zc);
                Vector3 f = new(min.x - over, y - over * 0.5f, max.z + over), g = new(max.x + over, y - over * 0.5f, max.z + over);
                Quad(a, e, c, b);       // front slope
                Quad(g, c, e, f);       // back slope
                Tri(new Vector3(min.x, y, min.z), new Vector3(min.x, y, max.z), new Vector3(min.x, y + rise, zc)); // gable ends
                Tri(new Vector3(max.x, y, max.z), new Vector3(max.x, y, min.z), new Vector3(max.x, y + rise, zc));
            }
            else
            {
                float xc = (min.x + max.x) / 2f;
                Vector3 a = new(min.x - over, y - over * 0.5f, max.z + over), b = new(min.x - over, y - over * 0.5f, min.z - over);
                Vector3 c = new(xc, y + rise, min.z - over), e = new(xc, y + rise, max.z + over);
                Vector3 f = new(max.x + over, y - over * 0.5f, min.z - over), g = new(max.x + over, y - over * 0.5f, max.z + over);
                Quad(a, e, c, b);
                Quad(f, c, e, g);
                Tri(new Vector3(min.x, y, min.z), new Vector3(xc, y + rise, min.z), new Vector3(max.x, y, min.z));
                Tri(new Vector3(max.x, y, max.z), new Vector3(xc, y + rise, max.z), new Vector3(min.x, y, max.z));
            }
        }

        /// <summary>A pyramid roof (towers).</summary>
        public void Pyramid(Vector3 min, Vector3 max, float rise, float over)
        {
            float y = max.y;
            Vector3 a = new(min.x - over, y, min.z - over), b = new(max.x + over, y, min.z - over);
            Vector3 c = new(max.x + over, y, max.z + over), d = new(min.x - over, y, max.z + over);
            Vector3 top = new((min.x + max.x) / 2f, y + rise, (min.z + max.z) / 2f);
            Tri(a, top, b); Tri(b, top, c); Tri(c, top, d); Tri(d, top, a);
        }

        /// <summary>A cone (negative height: an upturned bowl), base centre at c.</summary>
        public void Cone(Vector3 c, float r, float h, int seg)
        {
            var apex = c + Vector3.up * h;
            for (int i = 0; i < seg; i++)
            {
                float a0 = i * Mathf.PI * 2f / seg, a1 = (i + 1) * Mathf.PI * 2f / seg;
                var p0 = c + new Vector3(Mathf.Cos(a0), 0, Mathf.Sin(a0)) * r;
                var p1 = c + new Vector3(Mathf.Cos(a1), 0, Mathf.Sin(a1)) * r;
                if (h > 0) Tri(p0, apex, p1); else Tri(p1, apex, p0);
            }
        }

        /// <summary>A flat rectangle on the ground, rotated by rotDeg around the vertical.</summary>
        public void FlatRect(Vector3 c, float w, float d, float rotDeg)
        {
            var q = Quaternion.Euler(0, rotDeg, 0);
            Vector3 P(float x, float z) => c + q * new Vector3(x, 0, z);
            Quad(P(-w / 2, -d / 2), P(-w / 2, d / 2), P(w / 2, d / 2), P(w / 2, -d / 2));
        }

        /// <summary>A flat ellipse on the ground.</summary>
        public void Disc(Vector3 c, float rx, float rz, float rotDeg, int seg)
        {
            var q = Quaternion.Euler(0, rotDeg, 0);
            for (int i = 0; i < seg; i++)
            {
                float a0 = i * Mathf.PI * 2f / seg, a1 = (i + 1) * Mathf.PI * 2f / seg;
                var p0 = c + q * new Vector3(Mathf.Cos(a0) * rx, 0, Mathf.Sin(a0) * rz);
                var p1 = c + q * new Vector3(Mathf.Cos(a1) * rx, 0, Mathf.Sin(a1) * rz);
                Tri(c, p1, p0);
            }
        }

        /// <summary>A box along the ground segment a-b (local), thickness t, height h (no bottom).</summary>
        public void OrientedBox(Vector3 a, Vector3 b, float t, float h)
        {
            var u = (b - a); u.y = 0; u.Normalize();
            var n = Vector3.Cross(u, Vector3.up) * (t / 2f); // sides chosen so every face winds outward
            Vector3 up = Vector3.up * h;
            Vector3 a0 = a - n, a1 = a + n, b0 = b - n, b1 = b + n;
            Quad(a0, a0 + up, b0 + up, b0);         // right side
            Quad(b1, b1 + up, a1 + up, a1);         // left side
            Quad(a1, a1 + up, a0 + up, a0);         // end at a
            Quad(b0, b0 + up, b1 + up, b1);         // end at b
            Quad(a0 + up, a1 + up, b1 + up, b0 + up); // top
        }

        /// <summary>A pitched roof along the segment a-b sitting on height h, width w, ridge rise.</summary>
        public void OrientedGable(Vector3 a, Vector3 b, float w, float h, float rise)
        {
            var u = (b - a); u.y = 0; u.Normalize();
            var n = Vector3.Cross(u, Vector3.up) * (w / 2f);
            Vector3 up = Vector3.up * h, ridge = Vector3.up * (h + rise);
            Vector3 a0 = a - n + up, a1 = a + n + up, b0 = b - n + up, b1 = b + n + up, ar = a + ridge, br = b + ridge;
            Quad(a0, ar, br, b0);
            Quad(b1, br, ar, a1);
            Tri(a1, ar, a0);
            Tri(b0, br, b1);
        }

        public Mesh Build()
        {
            var m = new Mesh { indexFormat = v.Count > 65000 ? UnityEngine.Rendering.IndexFormat.UInt32 : UnityEngine.Rendering.IndexFormat.UInt16 };
            m.SetVertices(v); m.SetNormals(n); m.SetUVs(0, uv); m.SetTriangles(tri, 0);
            m.RecalculateBounds();
            m.RecalculateTangents();
            return m;
        }
    }
}
