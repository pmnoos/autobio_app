import { Controller } from "@hotwired/stimulus"
import "trix"

// Adds safe keyboard shortcuts for alignment without touching toolbar
// Ctrl+Shift+L => left, Ctrl+Shift+C => center, Ctrl+Shift+R => right
export default class extends Controller {
  connect() {
    // Register block attributes once per page load
    const cfg = Trix.config.blockAttributes
    if (!cfg["text-left"]) cfg["text-left"] = { tagName: "div", className: "text-left" }
    if (!cfg["text-center"]) cfg["text-center"] = { tagName: "div", className: "text-center" }
    if (!cfg["text-right"]) cfg["text-right"] = { tagName: "div", className: "text-right" }

    // Prefer Trix's custom keydown event to ensure we catch keystrokes inside the editor
    this.trixKeydownHandler = (event) => {
      const ke = event.originalEvent || event // keyboard event
      if (!(ke.ctrlKey && ke.shiftKey)) return
      const editor = this.element && this.element.editor
      if (!editor) return

      let handled = false
      switch ((ke.key || "").toLowerCase()) {
        case "l":
          this.setAlignment(editor, "text-left"); handled = true; break
        case "c":
          this.setAlignment(editor, "text-center"); handled = true; break
        case "r":
          this.setAlignment(editor, "text-right"); handled = true; break
      }
      if (handled) {
        ke.preventDefault()
        event.preventDefault && event.preventDefault()
      }
    }

    this.element.addEventListener("trix-keydown", this.trixKeydownHandler)
    // Fallback in case trix-keydown is not fired in some environments
    this.keydownHandler = (e) => this.trixKeydownHandler({ originalEvent: e, preventDefault: () => e.preventDefault() })
    this.element.addEventListener("keydown", this.keydownHandler)
  }

  disconnect() {
    if (this.keydownHandler) this.element.removeEventListener("keydown", this.keydownHandler)
    if (this.trixKeydownHandler) this.element.removeEventListener("trix-keydown", this.trixKeydownHandler)
  }

  setAlignment(editor, attr) {
    ["text-left", "text-center", "text-right"].forEach(a => editor.deactivateAttribute(a))
    if (attr) editor.activateAttribute(attr)
  }
}
