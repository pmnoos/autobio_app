// Safe toolbar alignment icons for Trix
import "trix"

// Ensure block attributes exist
function ensureAlignmentAttributes() {
  const cfg = Trix.config.blockAttributes
  if (!cfg["text-left"]) cfg["text-left"] = { tagName: "div", className: "text-left" }
  if (!cfg["text-center"]) cfg["text-center"] = { tagName: "div", className: "text-center" }
  if (!cfg["text-right"]) cfg["text-right"] = { tagName: "div", className: "text-right" }
}

document.addEventListener("trix-initialize", (event) => {
  try {
    ensureAlignmentAttributes()

    const editor = event.target
    const toolbar = editor.toolbarElement
    if (!toolbar) return

    // Avoid duplicates
    if (toolbar.querySelector(".trix-button-group--text-align")) return

    const group = document.createElement("span")
    group.className = "trix-button-group trix-button-group--text-align"

    group.innerHTML = `
      <button type="button" class="trix-button trix-button--icon trix-button--icon-align-left" data-trix-attribute="text-left" title="Align Left" aria-label="Align Left"></button>
      <button type="button" class="trix-button trix-button--icon trix-button--icon-align-center" data-trix-attribute="text-center" title="Align Center" aria-label="Align Center"></button>
      <button type="button" class="trix-button trix-button--icon trix-button--icon-align-right" data-trix-attribute="text-right" title="Align Right" aria-label="Align Right"></button>
    `

    const buttonRow = toolbar.querySelector(".trix-button-row")
    if (buttonRow) buttonRow.appendChild(group)
  } catch (e) {
    // No-op: do not interfere with editor flow
  }
})
