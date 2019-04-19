// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import "bootstrap";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

window.addEventListener("click", e => {
  if (e.target.getAttribute("phx-click") && e.target.getAttribute("phx-send-click-coords")) {
    let x = Math.floor(e.clientX - e.target.getClientRects()[0].x);
    let y = Math.floor(e.clientY - e.target.getClientRects()[0].y);
    let val = `${x},${y}`;
    e.target.setAttribute("phx-value", val)
  }
}, true)

window.setImportValue = function(event) {
  const val = document.getElementById("import-textarea").value;
  event.target.setAttribute("phx-value", val);
}