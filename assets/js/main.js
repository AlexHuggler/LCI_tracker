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
});
