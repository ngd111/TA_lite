use msens_db
var c = db.hourly_sr_keywords.find()
while(c.hasNext()) {
	printjson(c.next())
}
