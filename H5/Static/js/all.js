function search_run() {

	if(document.all.search_area.style.display=="none") {
		document.all.search_area.style.display="block";
		return false;
	}
	
	if(document.all.search_area.style.display=="block") {
		document.all.search_area.style.display="none";
		return false;
	}
}

function pop_up() {
	document.all.add_pop.style.display="block";
}

function pop_close() {
	document.all.add_pop.style.display="none";
}

function pop_up2() {
	document.all.add_pop2.style.display="block";
}

function pop_close2() {
	document.all.add_pop2.style.display="none";
}