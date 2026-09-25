/**
 * main.js — Progressive enhancement for the profile page.
 *
 * Every feature here is additive: with JavaScript disabled the page still
 * renders, reads and navigates correctly.
 */
(function () {
  "use strict";

  var STORAGE_KEY = "krishanth7:theme";

  /* ---------------------------------------------------------------- theme */
  function initTheme() {
    var root = document.documentElement;
    var toggle = document.getElementById("theme-toggle");
    var icon = document.getElementById("theme-icon");
    if (!toggle || !icon) return;

    function read() {
      try {
        return localStorage.getItem(STORAGE_KEY);
      } catch (err) {
        return null;
      }
    }

    function write(value) {
      try {
        localStorage.setItem(STORAGE_KEY, value);
      } catch (err) {
        /* private mode or blocked storage — theme simply is not remembered */
      }
    }

    function apply(theme) {
      root.setAttribute("data-theme", theme);
      icon.textContent = theme === "dark" ? "◐" : "◑";
      toggle.setAttribute("aria-label", "Switch to " + (theme === "dark" ? "light" : "dark") + " theme");
    }

    var prefersLight = window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches;
    apply(read() || (prefersLight ? "light" : "dark"));

    toggle.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      apply(next);
      write(next);
    });
  }

  /* --------------------------------------------------------------- reveal */
  function initReveal() {
    var nodes = document.querySelectorAll(".reveal");
    if (!nodes.length) return;

    if (!("IntersectionObserver" in window)) {
      Array.prototype.forEach.call(nodes, function (node) {
        node.classList.add("is-visible");
      });
      return;
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.12 }
    );

    Array.prototype.forEach.call(nodes, function (node) {
      observer.observe(node);
    });
  }

  /* --------------------------------------------------------------- skills */
  function initSkills() {
    var fills = document.querySelectorAll(".skill__fill");
    if (!fills.length) return;

    function fill(node) {
      node.style.setProperty("--level", node.getAttribute("data-level") || "0%");
    }

    if (!("IntersectionObserver" in window)) {
      Array.prototype.forEach.call(fills, fill);
      return;
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          fill(entry.target);
          observer.unobserve(entry.target);
        });
      },
      { threshold: 0.4 }
    );

    Array.prototype.forEach.call(fills, function (node) {
      observer.observe(node);
    });
  }

  /* ------------------------------------------------------------ nav state */
  function initNavHighlight() {
    var links = document.querySelectorAll(".topbar__link");
    var sections = [];

    Array.prototype.forEach.call(links, function (link) {
      var target = document.querySelector(link.getAttribute("href"));
      if (target) sections.push({ link: link, target: target });
    });

    if (!sections.length || !("IntersectionObserver" in window)) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          var match = sections.filter(function (s) {
            return s.target === entry.target;
          })[0];
          if (!match) return;
          if (entry.isIntersecting) {
            Array.prototype.forEach.call(links, function (l) {
              l.removeAttribute("aria-current");
            });
            match.link.setAttribute("aria-current", "page");
          }
        });
      },
      { rootMargin: "-45% 0px -50% 0px" }
    );

    sections.forEach(function (s) {
      observer.observe(s.target);
    });
  }

  /* ----------------------------------------------------------------- year */
  function initYear() {
    var el = document.getElementById("year");
    if (el) el.textContent = String(new Date().getFullYear());
  }

  function boot() {
    initTheme();
    initReveal();
    initSkills();
    initNavHighlight();
    initYear();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
