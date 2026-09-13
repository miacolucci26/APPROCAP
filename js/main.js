(function () {
  "use strict";

  /* Año automático en el pie de página */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });

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
