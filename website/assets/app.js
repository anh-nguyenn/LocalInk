(function () {
  "use strict";

  // ---------- Nav ----------
  const nav = document.getElementById("nav");
  const navToggle = document.getElementById("navToggle");
  const navLinks = nav ? nav.querySelector(".nav-links") : null;

  function onScroll() {
    if (nav) nav.classList.toggle("scrolled", window.scrollY > 8);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  if (navToggle && nav && navLinks) {
    navToggle.addEventListener("click", function () {
      const open = nav.classList.toggle("open");
      navLinks.classList.toggle("open", open);
      navToggle.setAttribute("aria-expanded", String(open));
    });
    navLinks.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        nav.classList.remove("open");
        navLinks.classList.remove("open");
        navToggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  // ---------- Reveal on scroll ----------
  const reveals = document.querySelectorAll(".reveal");
  function revealNow(el) { el.classList.add("in"); }

  // Anything already near the viewport should be visible immediately.
  reveals.forEach(function (el) {
    const r = el.getBoundingClientRect();
    if (r.top < window.innerHeight * 0.95 && r.bottom > 0) revealNow(el);
  });

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          revealNow(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.08, rootMargin: "0px 0px -30px 0px" });
    reveals.forEach(function (el) { observer.observe(el); });
  } else {
    reveals.forEach(revealNow);
  }

  // Safety net so content can never stay hidden.
  window.setTimeout(function () { reveals.forEach(revealNow); }, 1800);

  // ---------- Year ----------
  const year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());

  // ---------- Interactive demo ----------
  const canvas = document.getElementById("demoCanvas");
  if (!canvas) return;

  const wrap = document.getElementById("canvasWrap");
  const ctx = canvas.getContext("2d");
  const swatchWrap = document.getElementById("swatches");
  const widthInput = document.getElementById("demoWidth");
  const undoBtn = document.getElementById("demoUndo");
  const clearBtn = document.getElementById("demoClear");
  const hint = document.getElementById("demoHint");
  const toolButtons = Array.from(document.querySelectorAll(".tool[data-tool]"));

  const palette = [
    "#f24436", "#ff9400", "#ffd91a", "#33c759", "#2196f3", "#9c59f2", "#ffffff", "#1a1a1a"
  ];

  let tool = "pen";
  let color = palette[0];
  let lineWidth = 5;
  let marks = [];
  let current = null;
  let drawing = false;
  let dpr = Math.min(window.devicePixelRatio || 1, 2);

  function resize() {
    if (!wrap) return;
    const rect = wrap.getBoundingClientRect();
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.max(1, Math.round(rect.width * dpr));
    canvas.height = Math.max(1, Math.round(rect.height * dpr));
    canvas.style.width = rect.width + "px";
    canvas.style.height = rect.height + "px";
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    redraw();
  }

  function buildSwatches() {
    if (!swatchWrap) return;
    palette.forEach(function (col, i) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "swatch" + (i === 0 ? " active" : "");
      b.style.background = col;
      b.setAttribute("aria-label", "Color " + (i + 1));
      b.addEventListener("click", function () {
        color = col;
        swatchWrap.querySelectorAll(".swatch").forEach(function (s) {
          s.classList.remove("active");
        });
        b.classList.add("active");
      });
      swatchWrap.appendChild(b);
    });
  }

  function drawMark(m) {
    const isHighlighter = m.tool === "highlighter";
    ctx.save();
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.strokeStyle = m.color;
    ctx.fillStyle = m.color;
    ctx.lineWidth = isHighlighter ? m.width * 2.6 : m.width;
    ctx.globalAlpha = isHighlighter ? 0.35 : 1;

    if (m.tool === "pen" || isHighlighter) {
      if (m.points.length < 2) {
        ctx.beginPath();
        ctx.arc(m.points[0].x, m.points[0].y, ctx.lineWidth / 2, 0, Math.PI * 2);
        ctx.fill();
      } else {
        ctx.beginPath();
        ctx.moveTo(m.points[0].x, m.points[0].y);
        for (let i = 1; i < m.points.length; i++) {
          ctx.lineTo(m.points[i].x, m.points[i].y);
        }
        ctx.stroke();
      }
    } else if (m.tool === "arrow") {
      const a = m.start, b = m.end;
      ctx.beginPath();
      ctx.moveTo(a.x, a.y);
      ctx.lineTo(b.x, b.y);
      ctx.stroke();
      const angle = Math.atan2(b.y - a.y, b.x - a.x);
      const size = Math.max(14, m.width * 3.6);
      const wing = Math.PI / 6;
      ctx.beginPath();
      ctx.moveTo(b.x, b.y);
      ctx.lineTo(b.x - size * Math.cos(angle - wing), b.y - size * Math.sin(angle - wing));
      ctx.lineTo(b.x - size * Math.cos(angle + wing), b.y - size * Math.sin(angle + wing));
      ctx.closePath();
      ctx.fill();
    } else if (m.tool === "rect") {
      const x = Math.min(m.start.x, m.end.x);
      const y = Math.min(m.start.y, m.end.y);
      const w = Math.abs(m.end.x - m.start.x);
      const h = Math.abs(m.end.y - m.start.y);
      ctx.strokeRect(x, y, w, h);
    } else if (m.tool === "ellipse") {
      const cx = (m.start.x + m.end.x) / 2;
      const cy = (m.start.y + m.end.y) / 2;
      const rx = Math.abs(m.end.x - m.start.x) / 2;
      const ry = Math.abs(m.end.y - m.start.y) / 2;
      ctx.beginPath();
      ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.restore();
  }

  function redraw() {
    const rect = wrap.getBoundingClientRect();
    ctx.clearRect(0, 0, rect.width, rect.height);
    marks.forEach(drawMark);
    if (current) drawMark(current);
  }

  function position(e) {
    const rect = canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }

  canvas.addEventListener("pointerdown", function (e) {
    e.preventDefault();
    canvas.setPointerCapture(e.pointerId);
    const p = position(e);
    if (hint) hint.classList.add("hide");
    current = {
      tool: tool,
      color: color,
      width: lineWidth,
      points: [p],
      start: p,
      end: p
    };
    drawing = true;
    if (tool === "pen" || tool === "highlighter") redraw();
  });

  canvas.addEventListener("pointermove", function (e) {
    if (!drawing || !current) return;
    const p = position(e);
    current.end = p;
    if (current.tool === "pen" || current.tool === "highlighter") {
      current.points.push(p);
    }
    redraw();
  });

  function finish() {
    if (!current) { drawing = false; return; }
    const m = current;
    const isShape = m.tool === "rect" || m.tool === "ellipse" || m.tool === "arrow";
    const tooSmall = isShape && Math.abs(m.end.x - m.start.x) < 3 && Math.abs(m.end.y - m.start.y) < 3;
    if (!tooSmall) {
      if (m.tool === "pen" || m.tool === "highlighter") {
        if (m.points.length > 1) marks.push(m);
      } else {
        marks.push(m);
      }
    }
    current = null;
    drawing = false;
    redraw();
  }

  canvas.addEventListener("pointerup", finish);
  canvas.addEventListener("pointercancel", finish);
  canvas.addEventListener("pointerleave", function () {
    if (drawing) finish();
  });

  toolButtons.forEach(function (b) {
    b.addEventListener("click", function () {
      tool = b.getAttribute("data-tool");
      toolButtons.forEach(function (x) { x.classList.remove("active"); });
      b.classList.add("active");
    });
  });

  if (widthInput) {
    widthInput.addEventListener("input", function () {
      lineWidth = Number(widthInput.value);
    });
  }
  if (undoBtn) {
    undoBtn.addEventListener("click", function () {
      marks.pop();
      redraw();
    });
  }
  if (clearBtn) {
    clearBtn.addEventListener("click", function () {
      marks = [];
      current = null;
      redraw();
    });
  }

  buildSwatches();
  resize();
  if ("ResizeObserver" in window && wrap) {
    new ResizeObserver(resize).observe(wrap);
  } else {
    window.addEventListener("resize", resize);
  }
})();
