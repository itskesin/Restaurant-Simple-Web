const sql = {}

sql.query = {
    
	// Adding new account
	add_user: 'INSERT INTO Users(name, phoneNum, email, uname, password, type) VALUES ($1,$2,$3,$4,$5,$6)',
	add_company: 'INSERT INTO Company uname) VALUES ($1)',
	add_owner: 'INSER INTO Owners(uname) VALUES ($1)',
	add_worker: 'INSERT INTO Workers(uname) VALUES ($1)',
	add_diner: 'INSERT INTO Diners(uname) VALUES ($1)',
	
	//Login
	userpass: 'SELECT * FROM Users WHERE uname=$1',
	adminpass: 'SELECT * FROM Admin WHERE uname=$1',

	//Update user info
	update_info: 'UPDATE Users SET name=$2, email=$3 phoneNum=$3 WHERE uname=$1',
	update_pass: 'UPDATE Users SET password=$2 WHERE uname=$1',

	//Diners
	update_point: 'UPDATE Diners SET points =$2 WHERE uname=$1',
	view_point: 'SELECT points FROM Diners where uname =$1',
	
	//Rewards
	add_reward: 'INSERT INTO Rewards(rewardsCode, pointsReq, s_date, e_date, amountSaved) VALUES ($1,$2,$3,$4,$5)',
	del_reward: 'DELEE FROM Rewards where rewardsCode = $1',
	view_reward: 'SELECT * FROM Rewards',
	view_rewarddate: 'SELECT * FROM Rewards where s_date <= $1 AND e_date >= $1',
	
	//Cuisines
	add_cui: 'INSERT INTO Cuisines(cname) VALUES ($1)',
	view_cui: 'SELECT * FROM Cuisines',
	
	//Locations
	add_loc: 'INSERT INTO Locations(areas) VALUES ($1)',
	view_loc: 'SELECT * FROM Locations',
	
	//Restaurant
	view_allrest: 'SELECT * FROM Restaurant',
	view_restname: 'SELECT * FROM Restaurant where rname LIKE ''$1%'''
	view_rest: 'SELECT rname,address FROM Owner_Rest where owner = $1',
	add_rest: 'INSERT INTO Restaurant(rname, address) VALUES ($1,$2)',
	del_rest: 'DELETE FROM Restaurant WHERE rname = $1 AND address = $2',
	add_ownrest: 'INSERT INTO Owner_Rest(rname, owner, address) VALUES ($1,$2,$3)',
	add_restcui: 'INSERT INTO Rest_Cuisine(rname, address, cname) VALUES ($1,$2,$3)',
	add_restloc: 'INSERT INTO Rest_Location(rname, address, area) VALUES ($1,$2,$3)',
	view_restbyloc: 'SELECT rname, address FROM Rest_Location WHERE area = $1',
	view_restbycui: 'SELECT rname, address FROM Rest_Cuisine WHERE cname = $1',
	view_restloc: 'SELECT area FROM Rest_Location WHERE dname = $1 AND address = $2',
	view_restcui: 'SELECT cname FROM Rest_Cuisine WHERE dname = $1 AND address = $2',
	
	
	//Favourites
	add_fav: 'INSERT INTO Favourites(dname, rname, address) VALUES ($1,$2,$3)',
	del_fav: 'DELETE FROM Favourites where rname = $1 AND address = $2 AND dname = $3',
	view_fav: 'SELECT * FROM Favourites where dname = $1',
	
	//Redemptions
	add_red: 'INSERT INTO Redemptions(dname, rewardsCode, s_date, e_date, time) VALUES ($1,$2,$3,$4,$5)',
	use_red: 'UPDATE Redemptions SET is_valid = FALSE WHERE dname = $1 AND rewardsCode = $2 AND s_date = $3',
	view_red: 'SELECT * FROM Redemptions WHERE dname = $1',
	view_oldred: 'SELECT * FROM Redemptions WHERE dname = $1 AND is_valid = FALSE',
	
	//Fnb
	add_fnb: 'INSERT INTO Fnb(rname,address,fname,price) VALUES ($1,$2,$3,$4)',
	del_fnb: 'DELETE FROM Fnb WHERE rname = $1 AND address = $2 AND fname = $3',
	view_fnb: 'SELECT fname FROM Fnb WHERE rname = $1 AND address = $2', 
	
	//Promotion
	add_prom: 'INSERT INTO Promotion(rname,address,fname,price) VALUES ($1,$2,$3,$4)',
	del_prom: 'DELETE FROM Promotion WHERE rname = $1 AND address = $2 AND fname = $3',
	view_prom: 'SELECT * FROM Promotion where rname = $1 AND address = $2 AND fname = $3',
	view_restprom: 'SELECT fname,price FROM Promotion WHERE dname = $1 AND address = $2',
	
	//Opening Hours
	add_oh: 'INSERT INTO OpeningHours(rname, address, day, s_time, hours) VALUES ($1,$2,$3,$4,$5)',
	view_restoh: 'SELECT day,s_time, hours FROM OpeningHours WHERE dname = $1 AND address = $2',
	
	//Availability
	edit_av: 'UPDATE Availability SET maxPax = $1 WHERE rname = $2 AND address = $3 AND date = $4 AND s_time = $5',
	get_pax: 'SELECT max_pax FROM Availability WHERE rname = $1 AND address = $2 AND date = $3 AND s_time = $4',
	
	//Reservations
	add_reser: 'INSERT INTO Reservations(dname, rname, address, maxPax, time, date) VALUES ($1,$2,$3,$4,$5,$6)',
	accept_reser: 'Update Reservations status = \'\'Confirmed\'\' WHERE dname = $1 AND rname = $2 AND address = $3 AND time = $4 AND date = $5',
	com_reser: 'Update Reservations status = \'\'Completed\'\' WHERE dname = $1 AND rname = $2 AND address = $3 AND time = $4 AND date = $5',
	view_dinereser: 'SELECT * FROM Reservations WHERE dname = $1',
	view_restreser: 'SELECT * FROM Reservations WHERE rname = $1 AND address = $2',
	give_rate: 'UPDATE Reservations rating = $1 WHERE dname = $1 AND rname = $2 AND address = $3 AND time = $4 AND date = $5',
	
	//Aggregate
	view_moneysaved: 'SELECT SUM(amountSaved) FROM Redemptions WHERE dname = $1 AND address = $2 ANDs_date = $3 AND e_date = $4 AND is_valid = FALSE',
	view_restaverate: 'SELECT AVG(rating) FROM Reservations WHERE rname = $1 AND address = $2 AND rating != NULL',
	
	//Complex, need 2 CTE
	
}

module.exports = sql