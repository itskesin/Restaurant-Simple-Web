const sql_query = require('../db');
const passport = require('passport');
const bcrypt = require('bcrypt');

var express = require('express');
var router = express.Router();

const { Pool } = require('pg')
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

router.get('/', function(req, res, next) {
	var auth, type, fav;
	pool.query(sql_query.query.view_fav, (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			fav = [];
		}
		else {
			fav = data.rows;
		}
		if (!req.isAuthenticated()) {
				type = 'Not Logged in'
				res.render('login', { title: 'Makan Place', auth: false, type: type, data: fav });
		}
		else {
			type = 'Diner'
			res.render('rewards', { title: 'Makan Place', auth: true, type: type, data: fav });
		}
	});
});

module.exports = router;