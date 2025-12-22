// Adds text alignment buttons to the Trix toolbar and registers block attributes
// Align Left, Center, Right

import "trix";

// Register custom block attributes for alignment
Trix.config.blockAttributes["text-left"] = { tagName: "div", className: "text-left" };
Trix.config.blockAttributes["text-center"] = { tagName: "div", className: "text-center" };
Trix.config.blockAttributes["text-right"] = { tagName: "div", className: "text-right" };

// Insert alignment buttons into the toolbar when an editor initializes
document.addEventListener("trix-initialize", (event) => {
  const editor = event.target;
  const toolbar = editor.toolbarElement;
  if (!toolbar) return;

  // Avoid adding duplicates if multiple initialize events fire
  if (toolbar.querySelector(".trix-button-group--text-align")) return;

  const group = document.createElement("span");
  group.className = "trix-button-group trix-button-group--text-align";

  group.innerHTML = `
    <button type="button" class="trix-button trix-button--icon" data-trix-attribute="text-left" title="Align Left" aria-label="Align Left">L</button>
    <button type="button" class="trix-button trix-button--icon" data-trix-attribute="text-center" title="Align Center" aria-label="Align Center">C</button>
    <button type="button" class="trix-button trix-button--icon" data-trix-attribute="text-right" title="Align Right" aria-label="Align Right">R</button>
  `;

  const buttonRow = toolbar.querySelector(".trix-button-row");
  if (buttonRow) {
    buttonRow.appendChild(group);
  }
});
