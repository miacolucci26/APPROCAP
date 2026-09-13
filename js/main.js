(function () {
  "use strict";

  /* Año automático en el pie de página */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });

  /* ---------------- Cifras animadas (franja de estadísticas) ---------------- */
  var countEls = document.querySelectorAll("[data-count-to]");
  if (countEls.length) {
    var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    var animateCount = function (el) {
      var target = parseInt(el.getAttribute("data-count-to"), 10) || 0;
      var suffix = el.getAttribute("data-suffix") || "";
      if (reduceMotion) {
        el.textContent = target + suffix;
        return;
      }
      var duration = 1200;
      var start = null;
      var easeOutQuad = function (t) { return 1 - (1 - t) * (1 - t); };
      var step = function (timestamp) {
        if (start === null) start = timestamp;
        var progress = Math.min((timestamp - start) / duration, 1);
        var current = Math.round(target * easeOutQuad(progress));
        el.textContent = current + suffix;
        if (progress < 1) window.requestAnimationFrame(step);
      };
      window.requestAnimationFrame(step);
    };
    var countObserver = new IntersectionObserver(function (entries, observer) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          animateCount(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.4 });
    countEls.forEach(function (el) { countObserver.observe(el); });
  }

  /* ---------------- Header transparente sobre el hero (solo Inicio) ---------------- */
  var transparentHeader = document.querySelector(".site-header[data-transparent-hero]");
  if (transparentHeader) {
    var scrollThreshold = 40;
    var ticking = false;
    var syncHeaderState = function () {
      transparentHeader.classList.toggle("site-header--transparent", window.scrollY <= scrollThreshold);
      ticking = false;
    };
    syncHeaderState();
    window.addEventListener("scroll", function () {
      if (!ticking) {
        window.requestAnimationFrame(syncHeaderState);
        ticking = true;
      }
    }, { passive: true });
  }

  /* ---------------- Menú móvil ---------------- */
  var toggle = document.querySelector(".nav-toggle");
  var nav = document.getElementById("main-nav");

  function closeMenu() {
    if (!toggle || !nav) return;
    toggle.setAttribute("aria-expanded", "false");
    nav.classList.remove("is-open");
    document.body.style.overflow = "";
  }

  function openMenu() {
    if (!toggle || !nav) return;
    toggle.setAttribute("aria-expanded", "true");
    nav.classList.add("is-open");
    document.body.style.overflow = "hidden";
  }

  if (toggle && nav) {
    toggle.addEventListener("click", function () {
      var isOpen = toggle.getAttribute("aria-expanded") === "true";
      if (isOpen) { closeMenu(); } else { openMenu(); }
    });

    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", closeMenu);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && toggle.getAttribute("aria-expanded") === "true") {
        closeMenu();
        toggle.focus();
      }
    });

    var mq = window.matchMedia("(min-width: 861px)");
    mq.addEventListener("change", function (e) {
      if (e.matches) { closeMenu(); }
    });
  }

  /* ---------------- Menú con desplegables (El Origen / Impacto y Clima) ---------------- */
  var dropdownItems = Array.prototype.slice.call(document.querySelectorAll(".nav-item--dropdown"));
  if (dropdownItems.length) {
    var closeDropdown = function (item) {
      item.classList.remove("is-open");
      item.querySelector(".nav-dropdown-trigger").setAttribute("aria-expanded", "false");
    };
    var closeAllDropdowns = function (except) {
      dropdownItems.forEach(function (item) {
        if (item !== except) closeDropdown(item);
      });
    };
    dropdownItems.forEach(function (item) {
      var trigger = item.querySelector(".nav-dropdown-trigger");
      trigger.addEventListener("click", function () {
        var willOpen = !item.classList.contains("is-open");
        closeAllDropdowns();
        if (willOpen) {
          item.classList.add("is-open");
          trigger.setAttribute("aria-expanded", "true");
        }
      });
      item.querySelectorAll(".nav-dropdown-link").forEach(function (link) {
        link.addEventListener("click", function () { closeDropdown(item); });
      });
    });
    document.addEventListener("click", function (e) {
      if (!e.target.closest(".nav-item--dropdown")) closeAllDropdowns();
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        var openItem = dropdownItems.filter(function (item) { return item.classList.contains("is-open"); })[0];
        if (openItem) {
          closeDropdown(openItem);
          openItem.querySelector(".nav-dropdown-trigger").focus();
        }
      }
    });
  }

  /* ---------------- Lightbox (galería y reconocimientos) ---------------- */
  var lightbox = document.getElementById("lightbox");
  if (!lightbox) return;

  var lbImg = lightbox.querySelector("img");
  var lbCaption = lightbox.querySelector("figcaption");
  var closeBtn = lightbox.querySelector(".lightbox-close");
  var prevBtn = lightbox.querySelector(".lightbox-prev");
  var nextBtn = lightbox.querySelector(".lightbox-next");

  var triggers = Array.prototype.slice.call(document.querySelectorAll(".js-lightbox"));
  var currentIndex = -1;
  var lastFocused = null;

  function itemData(el) {
    return {
      src: el.getAttribute("data-full") || el.querySelector("img").src,
      alt: el.querySelector("img").alt || "",
      caption: el.getAttribute("data-caption") || ""
    };
  }

  function show(index) {
    if (index < 0 || index >= triggers.length) return;
    currentIndex = index;
    var data = itemData(triggers[index]);
    lbImg.src = data.src;
    lbImg.alt = data.alt;
    lbCaption.textContent = data.caption;
    var multiple = triggers.length > 1;
    prevBtn.hidden = !multiple;
    nextBtn.hidden = !multiple;
  }

  function openLightbox(index) {
    lastFocused = document.activeElement;
    show(index);
    lightbox.hidden = false;
    document.body.style.overflow = "hidden";
    closeBtn.focus();
    document.addEventListener("keydown", onKeydown);
  }

  function closeLightbox() {
    lightbox.hidden = true;
    document.body.style.overflow = "";
    document.removeEventListener("keydown", onKeydown);
    if (lastFocused) lastFocused.focus();
  }

  function onKeydown(e) {
    if (e.key === "Escape") { closeLightbox(); }
    else if (e.key === "ArrowRight") { show((currentIndex + 1) % triggers.length); }
    else if (e.key === "ArrowLeft") { show((currentIndex - 1 + triggers.length) % triggers.length); }
    else if (e.key === "Tab") {
      var focusables = [closeBtn, prevBtn, nextBtn].filter(function (b) { return !b.hidden; });
      var first = focusables[0], last = focusables[focusables.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }

  triggers.forEach(function (el, index) {
    el.addEventListener("click", function () { openLightbox(index); });
  });

  closeBtn.addEventListener("click", closeLightbox);
  lightbox.addEventListener("click", function (e) {
    if (e.target === lightbox) closeLightbox();
  });
  prevBtn.addEventListener("click", function () { show((currentIndex - 1 + triggers.length) % triggers.length); });
  nextBtn.addEventListener("click", function () { show((currentIndex + 1) % triggers.length); });
})();
