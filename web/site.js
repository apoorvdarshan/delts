(function () {
  "use strict";

  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var root = document.documentElement;

  /* footer year */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = String(new Date().getFullYear());
  });

  /* smooth-scroll buttons (non-anchor triggers) */
  document.querySelectorAll("[data-scroll]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var t = document.querySelector(btn.getAttribute("data-scroll"));
      if (t) t.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "start" });
    });
  });

  /* sticky nav state */
  var nav = document.querySelector("[data-nav]");
  /* scroll progress bar */
  var bar = document.querySelector("[data-progress]");
  function onScroll() {
    var y = window.scrollY || 0;
    if (nav) nav.classList.toggle("stuck", y > 10);
    if (bar) {
      var h = document.documentElement.scrollHeight - window.innerHeight;
      bar.style.setProperty("--p", h > 0 ? Math.min(y / h, 1).toFixed(4) : "0");
    }
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* reveal on scroll */
  var revealEls = document.querySelectorAll(".reveal");
  if (reduce || !("IntersectionObserver" in window)) {
    revealEls.forEach(function (el) { el.classList.add("in"); });
  } else {
    var io = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("in"); obs.unobserve(e.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.12 });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* count-up numbers */
  var counters = document.querySelectorAll("[data-count]");
  function runCount(el) {
    var end = Number(el.getAttribute("data-count")) || 0;
    if (reduce || end === 0) { el.textContent = String(end); return; }
    var dur = 1000, start = null;
    function step(ts) {
      if (start === null) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = String(Math.round(end * eased));
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }
  if (counters.length) {
    if (!("IntersectionObserver" in window)) {
      counters.forEach(runCount);
    } else {
      var co = new IntersectionObserver(function (entries, obs) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { runCount(e.target); obs.unobserve(e.target); }
        });
      }, { threshold: 0.6 });
      counters.forEach(function (el) { co.observe(el); });
    }
  }

  /* hero session clock — counts up like a running timer */
  var clock = document.querySelector("[data-clock]");
  var clock2 = document.querySelector("[data-clock-2]");
  if (clock && !reduce) {
    var sec = 0;
    setInterval(function () {
      sec = (sec + 1) % 6000;
      var m = String(Math.floor(sec / 60)).padStart(2, "0");
      var s = String(sec % 60).padStart(2, "0");
      clock.textContent = m + ":" + s;
      if (clock2) clock2.textContent = Math.floor(sec / 60) + ":" + s;
    }, 1000);
  }

  /* theme swatches — retint the whole page + swap brand icon/favicon */
  var swatches = document.querySelectorAll("[data-swatches] .swatch");
  var brandImg = document.querySelector("[data-brand]");
  var favicon = document.querySelector("[data-favicon]");
  swatches.forEach(function (sw) {
    sw.addEventListener("click", function () {
      var accent = sw.getAttribute("data-accent");
      var icon = sw.getAttribute("data-icon");
      root.style.setProperty("--accent", accent);
      if (brandImg && icon) brandImg.src = icon;
      if (favicon && icon) favicon.href = icon;
      swatches.forEach(function (s) { s.classList.remove("active"); });
      sw.classList.add("active");
    });
  });

  /* lagging cursor ring (fine pointers) */
  var ring = document.querySelector("[data-cursor]");
  if (ring && !reduce && window.matchMedia("(hover: hover) and (pointer: fine)").matches) {
    var rx = window.innerWidth / 2, ry = window.innerHeight / 2, tx = rx, ty = ry, shown = false;
    window.addEventListener("pointermove", function (e) {
      tx = e.clientX; ty = e.clientY;
      if (!shown) { ring.classList.add("on"); shown = true; }
    }, { passive: true });
    document.addEventListener("pointerover", function (e) {
      var t = e.target;
      var hot = t && (t.closest("a") || t.closest("button") || t.closest(".swatch") || t.closest(".spec__row"));
      ring.classList.toggle("grow", !!hot);
    });
    (function loop() {
      rx += (tx - rx) * 0.18; ry += (ty - ry) * 0.18;
      ring.style.transform = "translate(" + rx + "px," + ry + "px)";
      requestAnimationFrame(loop);
    })();
  }
})();
