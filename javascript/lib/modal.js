// Shitty Modal Plugin.
// By Jono Cooper
$ = require('jQuery');
$.fn.modal = function(control){
	// So it works in setTimeout and deferred
	var self = this;
	if (control === "hide" || control === undefined && this.hasClass("show")) {
		this.removeClass("show");
		setTimeout (function() {
			self.hide(0);
		}, 350);
		this.off("click.modal, touchend.modal");
	} else if (control === "show" || control === undefined && !this.hasClass("show")) {
		this.show(0).addClass("show");
		// Because I'm an asshole - delays for touch devices
		setTimeout(function() {
			self.on("click.modal, touchend.modal", function(e)	 {
				if ($(e.target).hasClass("modal")) {
					// This feels so wrong...
					self.modal("hide");
				}
			});
		}, 500);
	}
};

if (typeof(module) !== "undefined") {
	module.exports = exports;
} else {
	window.modal = exports;
}
