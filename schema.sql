CREATE TABLE sites
	( id INTEGER PRIMARY KEY AUTOINCREMENT
	, domain TEXT NOT NULL
	, fetched BOOLEAN NOT NULL CHECK (fetched IN (0, 1))
	, robots TEXT
	);

CREATE TABLE pages
	( id INTEGER PRIMARY KEY AUTOINCREMENT
	, site_id INTEGER NOT NULL
	, path TEXT NOT NULL
	, last_fetched TEXT NOT NULL
	, status INTEGER NOT NULL
	, md5 TEXT NOT NULL -- hash of response body
	, FOREIGN KEY(site_id) REFERENCES sites(id)
	, UNIQUE(site_id, path)
	);

CREATE TABLE awaiting_fetch
	( site_id INTEGER NOT NULL
	, path TEXT NOT NULL
	, enqueue_time TEXT NOT NULL
	, FOREIGN KEY(site_id) REFERENCES sites(id)
	, UNIQUE(site_id, path)
	);
