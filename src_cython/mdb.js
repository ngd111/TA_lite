use msens_db
var c = db.mining_result.find()
while(c.hasNext()) {
	printjson(c.next())
}
