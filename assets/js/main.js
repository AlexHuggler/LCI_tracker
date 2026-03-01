// Mobile menu toggle
document.addEventListener('DOMContentLoaded', function() {
  const menuToggle = document.querySelector('[data-mobile-menu-toggle]');
  const mobileMenu = document.querySelector('[data-mobile-menu]');

  if (menuToggle && mobileMenu) {
    menuToggle.addEventListener('click', function() {
      const isOpen = mobileMenu.classList.contains('hidden');
      mobileMenu.classList.toggle('hidden');
      // Toggle hamburger/close icons
      const openIcon = menuToggle.querySelector('[data-icon="open"]');
      const closeIcon = menuToggle.querySelector('[data-icon="close"]');
      if (openIcon && closeIcon) {
        openIcon.classList.toggle('hidden');
        closeIcon.classList.toggle('hidden');
      }
    });
  }

  // FAQ accordion
  document.querySelectorAll('[data-faq-toggle]').forEach(function(button) {
    button.addEventListener('click', function() {
      const answer = this.nextElementSibling;
      const icon = this.querySelector('[data-faq-icon]');

      if (answer) {
        answer.classList.toggle('open');
      }
      if (icon) {
        icon.classList.toggle('rotate-180');
      }

      // Update aria
      const expanded = this.getAttribute('aria-expanded') === 'true';
      this.setAttribute('aria-expanded', !expanded);
    });
  });

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
    anchor.addEventListener('click', function(e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // Scroll animations (Intersection Observer)
  var animatedElements = document.querySelectorAll('.animate-on-scroll');
  if (animatedElements.length > 0 && 'IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });
    animatedElements.forEach(function(el) { observer.observe(el); });
  }

  // Mobile sticky CTA bar (show after scrolling past hero)
  var stickyBar = document.querySelector('.mobile-sticky-cta');
  var heroSection = document.getElementById('hero');
  if (stickyBar && heroSection) {
    var heroObserver = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          stickyBar.classList.remove('is-visible');
        } else {
          stickyBar.classList.add('is-visible');
        }
      });
    }, { threshold: 0 });
    heroObserver.observe(heroSection);
  }

  // Blog category filter
  var filterButtons = document.querySelectorAll('[data-category]');
  if (filterButtons.length > 0) {
    filterButtons.forEach(function(btn) {
      btn.addEventListener('click', function() {
        var category = this.getAttribute('data-category');
        // Update active button styling
        filterButtons.forEach(function(b) {
          b.classList.remove('bg-pool-blue', 'text-white');
          b.classList.add('bg-gray-100', 'text-gray-700');
        });
        this.classList.remove('bg-gray-100', 'text-gray-700');
        this.classList.add('bg-pool-blue', 'text-white');
        // Filter posts
        var posts = document.querySelectorAll('[data-post-categories]');
        posts.forEach(function(post) {
          if (category === 'all') {
            post.style.display = '';
          } else {
            var cats = post.getAttribute('data-post-categories');
            post.style.display = cats && cats.indexOf(category) !== -1 ? '' : 'none';
          }
        });
      });
    });
  }

  // Waitlist form submission via Formspree (AJAX)
  document.querySelectorAll('.waitlist-form').forEach(function(form) {
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      var formData = new FormData(form);
      var button = form.querySelector('button[type="submit"]');
      var successMsg = form.parentElement.querySelector('.waitlist-success');
      button.disabled = true;
      button.textContent = 'Joining...';

      fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: { 'Accept': 'application/json' }
      }).then(function(response) {
        if (response.ok) {
          form.classList.add('hidden');
          if (successMsg) successMsg.classList.remove('hidden');
        } else {
          button.disabled = false;
          button.textContent = 'Join Waitlist';
          alert('Something went wrong. Please try again.');
        }
      }).catch(function() {
        button.disabled = false;
        button.textContent = 'Join Waitlist';
        alert('Network error. Please try again.');
      });
    });
  });
});
