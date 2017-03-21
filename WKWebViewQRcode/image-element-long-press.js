$(document).ready(
    function() {
        var imageElements = document.images;
        for(var i = 0; i < imageElements.length; i++) {
            var imageElement = imageElements[i];
//            imageElement.style.webkitTouchCallout = "none";
            var intervalID = 0;
            imageElement.ontouchstart = function(e) {
                e.preventDefault();
                intervalID = window.setInterval(
                    function() {
                        window.clearInterval(intervalID);
                        window.webkit.messageHandlers.webImgLongPressHandler.postMessage(e.target.src);
                    },
                    1000
                );
            };
            imageElement.ontouchend = function(e) {
                window.clearInterval(intervalID);
            };
            imageElement.ontouchcancel = function(e) {
                window.clearInterval(intervalID);
            }
        };
    }
);
