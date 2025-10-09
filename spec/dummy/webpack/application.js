// Webpack entry point for the dummy application
console.log('Webpack is loaded and working!');

// Simple DOM manipulation to verify webpack is working
document.addEventListener('DOMContentLoaded', function() {
  const appDiv = document.getElementById('app');
  if (appDiv) {
    const p = appDiv.querySelector('p');
    if (p) {
      p.textContent = 'Success! JavaScript from webpack has modified this content.';
      p.style.color = 'green';
      p.style.fontWeight = 'bold';
    }
  }
});
