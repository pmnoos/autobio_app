import { Controller } from "@hotwired/stimulus"

// Robustly restore Trix content from the hidden input after Turbo/Trix initialization
export default class extends Controller {
  connect() {
    this.editorEl = this.element // <trix-editor>

    // Resolve the hidden input that Action Text uses
    this.hiddenInput = this.resolveHiddenInput(this.editorEl)

    // Attempt immediate restore, then after Trix init, and after Turbo load
    this.tryRestore()
    this.trixInitHandler = () => this.tryRestore()
    this.turboLoadHandler = () => this.tryRestore()

    this.editorEl.addEventListener("trix-initialize", this.trixInitHandler)
    document.addEventListener("turbo:load", this.turboLoadHandler)
  }

  disconnect() {
    if (this.trixInitHandler) this.editorEl.removeEventListener("trix-initialize", this.trixInitHandler)
    if (this.turboLoadHandler) document.removeEventListener("turbo:load", this.turboLoadHandler)
  }

  resolveHiddenInput(editorEl) {
    // Preferred: the editor has an 'input' attribute pointing to the hidden input id
    const inputId = editorEl.getAttribute("input")
    if (inputId) {
      const byId = document.getElementById(inputId)
      if (byId) return byId
    }
    // Fallback: look for Action Text hidden input
    const formEl = editorEl.closest("form")
    if (formEl) {
      const byData = formEl.querySelector("input[type='hidden'][data-trix-input]")
      if (byData) return byData
      const byName = formEl.querySelector("input[type='hidden'][name$='[content]']")
      if (byName) return byName
    }
    return null
  }

  tryRestore() {
    const editor = this.editorEl && this.editorEl.editor
    const hidden = this.hiddenInput
    if (!editor || !hidden) return

    // Defer to ensure Trix has finished any internal setup
    setTimeout(() => {
      try {
        const isEmpty = (this.editorEl.value || "").trim() === ""
        if (isEmpty && hidden.value) {
          editor.loadHTML(hidden.value)
        }
      } catch (e) {
        // No-op
      }
    }, 0)
  }
}
