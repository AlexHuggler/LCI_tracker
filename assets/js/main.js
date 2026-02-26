/**
 * PoolFlow Marketing Site — Main JavaScript
 * Vanilla JS, no dependencies.
 *
 * Features:
 *   1. Mobile menu toggle (hamburger open/close with icon swap)
 *   2. Sticky nav shadow on scroll (frosted glass intensifies)
 *   3. FAQ accordion (single-open, smooth expand/collapse)
 *   4. Smooth scroll for anchor links (offset for sticky nav)
 *   5. Intersection Observer for fade-in animations on scroll
 *   6. Active nav link highlighting based on scroll position
 */

document.addEventListener('DOMContentLoaded', function () {

  // Cache commonly used elements
  var nav = document.querySelector('.nav-blur');
  var navHeight = nav ? nav.offsetHeight : 0;


  /* ========================================================================
     1. Mobile Menu Toggle
     ======================================================================== */
  var menuToggle = document.querySelector('[data-mobile-menu-toggle]');
  var mobileMenu = document.querySelector('[data-mobile-menu]');

  if (menuToggle && mobileMenu) {
    menuToggle.addEventListener('click', function () {
      var isOpen = mobileMenu.classList.contains('open');

      // Toggle menu state
      mobileMenu.classList.toggle('open');
      menuToggle.setAttribute('aria-expanded', isOpen ? 'false' : 'true');

      // Swap hamburger / close icons (expects data-icon="open" and data-icon="close")
      var openIcon = menuToggle.querySelector('[data-icon="open"]');
      var closeIcon = menuToggle.querySelector('[data-icon="close"]');
      if (openIcon && closeIcon) {
        openIcon.classList.toggle('hidden');
        closeIcon.classList.toggle('hidden');
      }

      // Prevent body scroll when menu is open
      document.body.style.overflow = isOpen ? '' : 'hidden';
    });

    // Close mobile menu when a navigation link is tapped
    var mobileLinks = mobileMenu.querySelectorAll('a[href^="#"]');
    mobileLinks.forEach(function (link) {
      link.addEventListener('click', function () {
        mobileMenu.classList.remove('open');
        menuToggle.setAttribute('aria-expanded', 'false');
        document.body.style.overflow = '';

        // Reset icons
        var openIcon = menuToggle.querySelector('[data-icon="open"]');
        var closeIcon = menuToggle.querySelector('[data-icon="close"]');
        if (openIcon && closeIcon) {
          openIcon.classList.remove('hidden');
          closeIcon.classList.add('hidden');
        }
      });
    });

    // Close menu on Escape key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && mobileMenu.classList.contains('open')) {
        mobileMenu.classList.remove('open');
        menuToggle.setAttribute('aria-expanded', 'false');
        document.body.style.overflow = '';

        var openIcon = menuToggle.querySelector('[data-icon="open"]');
        var closeIcon = menuToggle.querySelector('[data-icon="close"]');
        if (openIcon && closeIcon) {
          openIcon.classList.remove('hidden');
          closeIcon.classList.add('hidden');
        }

        // Return focus to the toggle button for accessibility
        menuToggle.focus();
      }
    });
  }


  /* ========================================================================
     2. Sticky Nav Shadow on Scroll
     ======================================================================== */
  if (nav) {
    function updateNavShadow() {
      var scrollY = window.scrollY || window.pageYOffset;

      if (scrollY > 8) {
        nav.classList.add('scrolled');
      } else {
        nav.classList.remove('scrolled');
      }
    }

    // Throttle with requestAnimationFrame for 60fps performance
    var navScrollTicking = false;
    window.addEventListener('scroll', function () {
      if (!navScrollTicking) {
        window.requestAnimationFrame(function () {
          updateNavShadow();
          navScrollTicking = false;
        });
        navScrollTicking = true;
      }
    }, { passive: true });

    // Apply correct state on initial load (e.g., if page is refreshed mid-scroll)
    updateNavShadow();
  }


  /* ========================================================================
     3. FAQ Accordion (only one open at a time)
     ======================================================================== */
  var faqItems = document.querySelectorAll('.faq-item');

  if (faqItems.length > 0) {
    faqItems.forEach(function (item) {
      var question = item.querySelector('.faq-question, [data-faq-toggle]');
      if (!question) return;

      question.addEventListener('click', function () {
        var isActive = item.classList.contains('active');

        // Close all other FAQ items first (single-open behavior)
        faqItems.forEach(function (other) {
          if (other !== item) {
            other.classList.remove('active');
            var otherBtn = other.querySelector('.faq-question, [data-faq-toggle]');
            if (otherBtn) otherBtn.setAttribute('aria-expanded', 'false');
          }
        });

        // Toggle the clicked item
        if (isActive) {
          item.classList.remove('active');
          question.setAttribute('aria-expanded', 'false');
        } else {
          item.classList.add('active');
          question.setAttribute('aria-expanded', 'true');
        }
      });

      // Allow keyboard activation with Enter and Space
      question.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          question.click();
        }
      });
    });
  }


  /* ========================================================================
     4. Smooth Scroll for Anchor Links
     ======================================================================== */
  var anchorLinks = document.querySelectorAll('a[href^="#"]');

  anchorLinks.forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      var href = this.getAttribute('href');

      // Skip empty anchors or "#" alone
      if (!href || href === '#') return;

      var target = document.querySelector(href);
      if (!target) return;

      e.preventDefault();

      // Calculate scroll position with offset for the sticky nav + some padding
      var currentNavHeight = nav ? nav.offsetHeight : 0;
      var targetTop = target.getBoundingClientRect().top + window.scrollY;
      var scrollPosition = targetTop - currentNavHeight - 16;

      window.scrollTo({
        top: scrollPosition,
        behavior: 'smooth'
      });

      // Update the URL hash without causing a jump
      if (history.pushState) {
        history.pushState(null, null, href);
      }
    });
  });


  /* ========================================================================
     5. Intersection Observer — Fade-in Animations on Scroll
     ======================================================================== */
  var animatedElements = document.querySelectorAll('.animate-on-scroll');

  if (animatedElements.length > 0 && 'IntersectionObserver' in window) {
    var animationObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            // Add visible class to trigger CSS transition
            entry.target.classList.add('visible');

            // Stop observing — each element only animates in once
            animationObserver.unobserve(entry.target);
          }
        });
      },
      {
        root: null,
        rootMargin: '0px 0px -60px 0px', // Trigger slightly before element is fully in view
        threshold: 0.1
      }
    );

    animatedElements.forEach(function (el) {
      animationObserver.observe(el);
    });
  } else {
    // Fallback: if IntersectionObserver is not supported, show everything immediately
    animatedElements.forEach(function (el) {
      el.classList.add('visible');
    });
  }


  /* ========================================================================
     6. Active Nav Link Highlighting Based on Scroll Position
     ======================================================================== */
  var navLinks = document.querySelectorAll('.nav-link[href^="#"]');
  var sections = [];

  // Build a mapping of sections referenced by nav links
  navLinks.forEach(function (link) {
    var href = link.getAttribute('href');
    if (href && href !== '#') {
      var section = document.querySelector(href);
      if (section) {
        sections.push({ el: section, link: link });
      }
    }
  });

  if (sections.length > 0) {
    function updateActiveNavLink() {
      var scrollY = window.scrollY || window.pageYOffset;
      var currentNavHeight = nav ? nav.offsetHeight : 0;

      // Activation offset: below the nav + generous buffer for a natural feel
      var activationOffset = currentNavHeight + 100;

      var currentSection = null;

      // Walk through sections top-to-bottom.
      // The last section whose top has scrolled past the activation line wins.
      for (var i = 0; i < sections.length; i++) {
        var sectionTop = sections[i].el.getBoundingClientRect().top + scrollY - activationOffset;
        if (scrollY >= sectionTop) {
          currentSection = sections[i];
        }
      }

      // Remove active class from all nav links
      navLinks.forEach(function (link) {
        link.classList.remove('active');
      });

      // Apply active class to the current section's nav link
      if (currentSection) {
        currentSection.link.classList.add('active');
      }
    }

    // Throttle scroll handler with requestAnimationFrame
    var navLinkTicking = false;
    window.addEventListener('scroll', function () {
      if (!navLinkTicking) {
        window.requestAnimationFrame(function () {
          updateActiveNavLink();
          navLinkTicking = false;
        });
        navLinkTicking = true;
      }
    }, { passive: true });

    // Set correct active state on initial page load
    updateActiveNavLink();
  }

});
