use msens_db
var c = db.classification_result.find()
while(c.hasNext()) {
	printjson(c.next())
}
