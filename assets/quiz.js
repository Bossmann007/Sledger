/* Shared retrieval-practice helper for lessons. */
function checkQuiz(name, expected, okText, badText) {
  const chosen = document.querySelector('input[name="' + name + '"]:checked');
  const fb = document.getElementById('fb-' + name);
  if (!fb) return;
  if (chosen && chosen.value === expected) {
    fb.className = 'feedback show callout-ok';
    fb.textContent = okText;
  } else {
    fb.className = 'feedback show callout-warn';
    fb.textContent = badText;
  }
}
