// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/zidolink"
import topbar from "../vendor/topbar"

const LocationPicker = {
  mounted() {
    const apiKey = this.el.dataset.apiKey
    this.requestId = 0
    this.loadGoogleMaps(apiKey).then(() => this.setup())
  },
  loadGoogleMaps(apiKey) {
    if (window.google && window.google.maps) return Promise.resolve()
    return new Promise((resolve, reject) => {
      window.__gmapsReady = resolve
      const script = document.createElement("script")
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places&callback=__gmapsReady&loading=async`
      script.async = true
      script.onerror = reject
      document.head.appendChild(script)
    })
  },
  async setup() {
    const { AutocompleteSuggestion, AutocompleteSessionToken } = await google.maps.importLibrary("places")
    this.sessionToken = new AutocompleteSessionToken()

    const input = this.el.querySelector("#location-search-input")
    const resultsList = this.el.querySelector("#location-results")

    input.addEventListener("input", async (e) => {
      const requestId = ++this.requestId
      const value = e.target.value

      if (!value) {
        resultsList.replaceChildren()
        return
      }

      const request = { input: value, sessionToken: this.sessionToken }
      const { suggestions } = await AutocompleteSuggestion.fetchAutocompleteSuggestions(request)

      if (requestId !== this.requestId) return // a newer keystroke has since fired, discard this stale result

      resultsList.replaceChildren()
      suggestions.forEach((suggestion) => {
        const placePrediction = suggestion.placePrediction
        const li = document.createElement("li")
        li.textContent = placePrediction.text.text
        li.className = "px-3 py-2 cursor-pointer hover:bg-base-200"
        li.addEventListener("click", async () => {
          const place = placePrediction.toPlace()
          await place.fetchFields({ fields: ["location", "formattedAddress"] })
          input.value = place.formattedAddress
          resultsList.replaceChildren()
          this.pushEvent("location_selected", {
            lat: place.location.lat(),
            lng: place.location.lng(),
            address: place.formattedAddress
          })
        })
        resultsList.appendChild(li)
      })
    })

    const currentLocationBtn = this.el.querySelector("#use-current-location")
    currentLocationBtn.addEventListener("click", () => {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          this.pushEvent("location_selected", {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            address: null
          })
        },
        () => alert("Could not get your location.")
      )
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, LocationPicker},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}