var last_time = 0;
var m0_data = {};
var last_checked = {};
var scrapbook = {};
var fs = require("fs");
var gs = require("google-spreadsheet");
var wait_time = 900000; //15 minutes in milliseconds

function init(io){
//load data from hard drive
	fs.readFile(__dirname+'/scrapbook.data', {'encoding':'utf8'}, function(err, d){
		if(!err){
			console.log("scrapbook loaded!");
			scrapbook = JSON.parse(d);
		} else {
			console.log(err);
		}
	});

	io.on('connection', function(socket){
	console.log("socket connected at "+socket.id+" "+socket.handshake.address.address+" "+socket.handshake.headers.referer);

		// generic_load = load any google doc, and pass it back
		socket.on("generic_load", function(d){
			if(d){
				if(d.key){
					if(typeof scrapbook[d.key] == 'undefined'){
						console.log("oh no, first load, stall for time!");
						socket.emit("loading", {"thing":"Stall for time!"});
						generic_load(d.key, socket);
	//					socket.emit("generic_data", scrapbook[d.key])
					} else {
						socket.emit("generic_data", scrapbook[d.key]);
						generic_load(d.key);
					}
				}
			}
		});
	});
}



//helper tally function
function tally(object, thing) {
	if(typeof object[thing] == 'undefined'){
		object[thing] = 1;
	} else {
		object[thing]++;
	}
}

//helper funciton for generic load
function generic_load(key, socket){
	var doc = new gs(key);
	var numberOfSheets = 0;
	var ready = 0;
	var current_time = new Date().getTime();
	console.log("calling generic load on"+key);
	if(typeof last_checked[key] == 'undefined' || last_checked[key] < current_time) {
		last_checked[key] = current_time + wait_time;
		doc.setAuth('','', function(err){
			if(!err){ //we have a document...
				doc.getInfo( function( err, info ){
					if(!err) {
						console.log('Starting to load "'+info.title+'"...' );
						numberOfSheets = info.worksheets.length;
						var document = {
							title: info.title,
							updated: info.updated,
							author: info.author
						};
						a();
						function a(){
							info.worksheets.forEach(function(worksheet, i){
								worksheet.getCells({
									minRow: 1,
									maxRow: worksheet.rowCount,
									minCol: 1,
									maxCol: worksheet.colCount
								},function(err,dat){
									dat.forEach(function(d, i){
										if(!document[worksheet.title]){
											document[worksheet.title] = [];
										}
										if(!document[worksheet.title][d.row]){
											document[worksheet.title][d.row] = [];
										}
										document[worksheet.title][d.row][d.col] = d.value;
										if(i == dat.length-1){
											ready++;
											callback(document);
										}
									});
								});
							});
						}
					} else {
						console.log("There was an error loading the google doc... "+key);
						console.log(err);
						console.trace();
					}
				});
			} else {
				console.log("There was an error authenticating... "+key);
				console.log(err);
				console.trace();
			}
		});
	} else {
		console.log("data is still fresh, not reloading");
	}
	
	return null;

	function callback(document){
		if(ready == numberOfSheets){
			console.log("...finished loading "+key);
			scrapbook[key] = document;
			if(typeof socket!= 'undefined'){
				socket.emit("generic_data", scrapbook[key]);
			}
//			console.log(Object.keys(scrapbook["11w61At2RjK31zbnpNllSwiB9czlh3d_jQV8inN6j4sU"]));
			fs.writeFile(__dirname+'/scrapbook.data', JSON.stringify(scrapbook),function (err) {
				if (err) {
					console.log("error!")
				} else {
					console.log("wrote to scrapbook!");
				}
			});
		}
	}
}

exports.init = init;



























