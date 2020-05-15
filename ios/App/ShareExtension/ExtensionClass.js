var ExtensionClass = function() {};

ExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({
            "title": document.title,
            "hostname": document.location.hostname,
            "url": document.URL
        });
    }
};

var ExtensionPreprocessingJS = new ExtensionClass;
