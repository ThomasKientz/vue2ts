var ExtensionClass = function() {};

ExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({
            "title": document.title,
            "hostname": document.location.hostname,
            "favicon": this.fetchFavicon()
        });
    },
    fetchFavicon: function() {
        return Array.from(document.getElementsByTagName("link"))
                .filter(element => element.rel == "icon" || element.rel == "shortcut icon")
                .map(elem => elem.href)[0];
    }
};

var ExtensionPreprocessingJS = new ExtensionClass;
