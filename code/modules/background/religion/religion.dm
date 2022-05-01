/datum/religion
	var/name
	var/description
	var/book_name = "bible"
	var/book_desc = "A holy item, containing the written words of a religion."
	var/book_desc_fluff
	var/book_sprite = "holybook"

/datum/religion/proc/get_records_name()
	return name