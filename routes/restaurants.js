const sql_query = require('../db');
const passport = require('passport');
const bcrypt = require('bcrypt');

var express = require('express');
var router = express.Router();

const { Pool } = require('pg')
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

function encodeHashtag(str) {
  return str.replace("#", "hashtag");
}

function decodeHashtag(str) {
  return str.replace("hashtag", "#");
}

//TODO: send user to individual restaurant page when clicked
router.get('/', function(req, res, next) {
	var rname = "%" + req.query.restaurantname + "%";
	var cuisine = req.query.cuisine;
	var location = req.query.location;
	var date = req.query.date;
	var time = req.query.time;
	var tbl, type, auth;
	//only from search bar 
	if (Object.keys(req.query).length === 0) {
		pool.query(sql_query.query.view_allrest, (err, data) => {
			if (err) {
				data = [];
			}
			else {
				for (let i = 0; i < data.rows.length; i++) {
					data.rows[i]["link"] = "/restaurants/goto:" + encodeURI(encodeHashtag(data.rows[i].rname)) + "&:" + encodeURI(encodeHashtag(data.rows[i].address));
				}
			}
			res.render('restaurants', {title: 'Makan Place', data: data.rows, rname: rname, cuisine: cuisine });
		});
	}
	else if (rname != "%undefined%") {
		pool.query(sql_query.query.search_rest, [rname], (err, data) => {
			if (err || !data.rows) {
				data = [];
			}
			else {
				for (let i = 0; i < data.rows.length; i++) {
					data.rows[i]["link"] = "/restaurants/goto:" + encodeURI(encodeHashtag(data.rows[i].rname)) + "&:" + encodeURI(encodeHashtag(data.rows[i].address));
				}
			}
			res.render('restaurants', {title: 'Makan Place', data: data.rows, rname: rname, cuisine: cuisine });
		});
	}

	//from side form
	else {
		if (cuisine == "Any Cuisine" || cuisine == '') {
			cuisine = '%';
		}
		if (location == "Any Location" || location == '') {
			location = '%';
		}
		//get rname and address where cname = cuisine, area = location, time within opening hours
		//cuisine
		pool.query(sql_query.query.view_cuilocrest, [location, cuisine], (err, data) => {
			if (err || !data.rows) {
				data = [];
			}
			else {
				//location
				// pool.query(sql_query.query.view_restloc, [location], (err, data) => {
				// 	if (!(err || !data.rows || data.rows.length == 0)) {
						for (let i = 0; i < data.rows.length; i++) {
							data.rows[i]["link"] = "/restaurants/goto:" + encodeURI(data.rows[i].rname) + "&:" + encodeURI(data.rows[i].address);
						}
					// }
					// res.render('restaurants', {title: 'Makan Place', data: data.rows, rname: rname });
				// });
			}
			res.render('restaurants', {title: 'Makan Place', data: data.rows, rname: rname, cuisine: cuisine });
		});
	}
});


router.get('/goto:rname&:address', function(req, res, next) {
	var rname = decodeURI(decodeHashtag(req.params.rname)).substr(1);
	var address = decodeURI(decodeHashtag(req.params.address)).substr(1); //idk why not the whole address shown :(
	// var addr = address + '%';
	var user = '', addr = address;
	if (req.isAuthenticated()) {
		user = req.user.username;
	}
	var cuisine, location, time, auth, type, openHour, promo, menu, fav;
	pool.query(sql_query.query.view_cuirest, [rname, addr], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			cuisine = [];
		}
		else {
			cuisine = data.rows;
		}
		pool.query(sql_query.query.view_locrest, [rname, addr], (err, data) => {
			if (err || !data.rows || data.rows.length == 0) {
				location = [];
			}
			else {
				location = data.rows;
			}
			pool.query(sql_query.query.view_ohtime, [rname, addr], (err, data) => {
				if (err || !data.rows || data.rows.length == 0) {
					openHour = [];
				}
				else {
					openHour = data.rows;
					for (var i = 0; i < data.rows.length; i++) {
						if (openHour[i]['day'] == 'Mon') {
							openHour[i]["daynum"] = 0;
						}
						else if (openHour[i]['day'] == 'Tues') {
							openHour[i]["daynum"] = 1;
						}
						else if (openHour[i]['day'] == 'Wed') {
							openHour[i]["daynum"] = 2;
						}
						else if (openHour[i]['day'] == 'Thurs') {
							openHour[i]["daynum"] = 3;
						}
						else if (openHour[i]['day'] == 'Fri') {
							openHour[i]["daynum"] = 4;
						}
						else if (openHour[i]['day'] == 'Sat') {
							openHour[i]["daynum"] = 5;
						}
						else if (openHour[i]['day'] == 'Sun') {
							openHour[i]["daynum"] = 6;
						}
					}
					openHour.sort(sortFunction);
				}
				pool.query(sql_query.query.view_prom, [rname, addr], (err, data) => {
					if (err || !data.rows || data.rows.length == 0) {
						promo = [];
					}
					else {
						promo = data.rows;
					}
					pool.query(sql_query.query.view_fnb, [rname, addr], (err, data) => {
						if (err || !data.rows || data.rows.length == 0) {
							menu = [];
						}
						else {
							menu = data.rows;
						}
						// if (req.isAuthenticated()) {
							pool.query(sql_query.query.check_fav, [user, rname, addr], (err, data) => {
								if (err || !data.rows || data.rows.length == 0) {
									fav ='Favourite';
								}
								else {
									fav = 'Unfavourite';
								}
								res.render('restaurant_info', { title: 'Makan Place', rname: rname, address: address, location: location, fav: fav, cuisine: cuisine, time: time, openHour: openHour, promo: promo, menu: menu });
							});
						// }
						
					});
				});
			});
  		});
	});
});

function sortFunction(a, b) {
    if (a['daynum'] === b['daynum']) {
        return 0;
    }
    else {
        return (a['daynum'] < b['daynum']) ? -1 : 1;
    }
}

//cant get rname & addr -> undefined :( 
router.post('/add_fav', function(req, res, next) {
	if (!req.isAuthenticated()) {
		res.redirect('/login');
	}
	var rname = req.body.rname;
	var address = req.body.address;
	var user = req.user.username; //needs to be logged in 
	var fav = req.body.fav;
	if (fav == 'Favourite') {
		pool.query(sql_query.query.add_fav, [user, rname, address], (err, data) => {
			if (err) {
				throw err;
			}
			res.redirect(`/restaurants/goto:${encodeURI(encodeHashtag(rname))}&:${encodeURI(encodeHashtag(address))}`) ;
		});
	}
	else {
		pool.query(sql_query.query.del_fav, [rname, address, user], (err, data) => {
			if (err) {
				throw err;
			}
			res.redirect(`/restaurants/goto:${encodeURI(encodeHashtag(rname))}&:${encodeURI(encodeHashtag(address))}`) ;
		});
	}
});

//cant get rname & addr -> undefined :( 
//still have to check if date + time is within opening hours and numpax is below maxpax
router.post('/add_reser', function(req, res, next) {
	if (!req.isAuthenticated()) {
		res.redirect('/login');
	}
	var rname = req.body.rname;
	var address = req.body.address + '%';
	var user = req.user.username; //needs to be logged in 
	// var user = 'itsme';
	var date = req.body.date;
	var time = req.body.time; 
	var pax = req.body.pax; 
	var day = date.getDate(); 
	//check if restaurant open on given date and time 


	//check if num pax below max pax
	pool.query(sql_query.query.get_addr, [rname, address], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			throw err;
		}
		else {
			address = data.rows.address;
		}
		pool.query(sql_query.query.add_reser, [user, rname, address, pax, time, date], (err, data) => {
			if (err) {
				throw err;
			}
			res.redirect(`/restaurants/goto:${encodeURI(encodeHashtag(rname))}&:${encodeURI(encodeHashtag(address))}`) ;
		});
	});
});
module.exports = router;
