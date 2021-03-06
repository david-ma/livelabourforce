var path = require("path");
var fs = require("fs");
var mime = require('mime');

function route(handle, pathname, response, request) {
//	console.log(pathname);

	if (typeof handle[pathname] === 'function') {
		handle[pathname](response, request);
	} else {
		normalRoute();
	}
	function normalRoute(){
		var filename = path.join(process.cwd(), pathname);
	
		path.exists(filename, function(exists) {
			if(!exists) {
				console.log("No file found for " + pathname);
				response.writeHead(404, {"Content-Type": "text/plain"});
				response.end("404 Not Found\n");
				return;
			}

			fs.readFile(filename, "binary", function(err,file) {
				if(err) {
					console.log("Error 500, content protected? "+filename);
					response.writeHead(500, {"Content-Type": "text/plain"});
					response.end(err + "\n");
					return;
				}

				fs.stat(filename, function(err, stats){
					if (stats.size > 102400){ //cache files bigger than 100kb?
				//		console.log(stats.size);
				//		console.log(filename +" is a big file! Caching!");
						if (!response.getHeader('Cache-Control') || !response.getHeader('Expires')) {
								response.setHeader("Cache-Control", "public, max-age=345600"); // ex. 4 days in seconds.
								response.setHeader("Expires", new Date(Date.now() + 345600000).toUTCString());  // in ms.
						}
					}
					response.writeHead(200, {'Content-Type': mime.lookup(filename)});
					response.end(file, "binary");
				});
			});
		});
	}
}

function isPhoto(file){
	var result = false;
	var end = file.substring(file.lastIndexOf('.'),file.length).toLowerCase();

	if (end == '.jpg' ||
			end == '.jpeg' ||
			end == '.png' ||
			end == '.gif' ||
			end == '.bmp') {
		result = true;
	}
	
	return result;
}

exports.route = route;