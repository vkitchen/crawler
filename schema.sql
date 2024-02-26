CREATE TABLE sites
	( id INTEGER PRIMARY KEY AUTOINCREMENT
	, domain TEXT NOT NULL
	);

CREATE TABLE pages
	( id INTEGER PRIMARY KEY AUTOINCREMENT
	, site_id INTEGER NOT NULL
	, path TEXT NOT NULL
	, status INTEGER NOT NULL
	, inserted_at TEXT NOT NULL
	, updated_at TEXT NOT NULL
	, FOREIGN KEY(site_id) REFERENCES sites(id)
	, UNIQUE(site_id, path)
	);

CREATE TABLE queue
	( id INTEGER PRIMARY KEY AUTOINCREMENT
	, site_id INTEGER NOT NULL
	, path TEXT NOT NULL
	, inserted_at TEXT NOT NULL
	, FOREIGN KEY(site_id) REFERENCES sites(id)
	, UNIQUE(site_id, path)
	);
