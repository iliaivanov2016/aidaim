DROP TABLE checkdate CASCADE;

CREATE TABLE checkdate (
	id  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE MAXVALUE 2147483647 NOCYCLED),
	datecreated DATETIME
);
INSERT INTO checkdate VALUES (
	7,
	TODATE('2/22/2011 8:52:24:266','M/D/YYYY H24:N:S:Z')
);
INSERT INTO checkdate VALUES (
	8,
	TODATE('2/22/2011 8:52:26:376','M/D/YYYY H24:N:S:Z')
);
INSERT INTO checkdate VALUES (
	9,
	TODATE('2/22/2011 8:52:37:407','M/D/YYYY H24:N:S:Z')
);

DROP TABLE ppc_ads CASCADE;

CREATE TABLE ppc_ads (
	id  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE MAXVALUE 2147483647 NOCYCLED),
	keyword_id INTEGER NOT NULL,
	searchengine_id INTEGER NOT NULL,
	rank SIGNEDINT16 DEFAULT 0 NOT NULL,
	title STRING (75) NOT NULL,
	desc1 STRING (75),
	desc2 STRING (75),
	display_url_id INTEGER,
	url_id INTEGER,
	domain_url_id INTEGER,
	checkdate_id INTEGER NOT NULL,
PRIMARY KEY pk_id (id)
);
CREATE INDEX ix_checkdate_id ON ppc_ads (
	checkdate_id
);
CREATE INDEX ix_searchengine_id ON ppc_ads (
	searchengine_id
);
CREATE INDEX ix_keyword_id ON ppc_ads (
	keyword_id
);
CREATE INDEX ix_display_url_id ON ppc_ads (
	display_url_id
);
CREATE INDEX ix_domain_url_id ON ppc_ads (
	domain_url_id
);
CREATE INDEX ix_url_id ON ppc_ads (
	url_id
);
INSERT INTO ppc_ads VALUES (
	1,
	2,
	36,
	1,
	'Search engine marketing',
	'Attract people searching for your',
	'product. Optimisation strategist',
	10,
	9,
	10,
	8
);
INSERT INTO ppc_ads VALUES (
	2,
	2,
	36,
	2,
	'SEO Specialists NZ',
	'Improve Your Website Rankings',
	'Search Engine Optimisation, NZ',
	13,
	11,
	12,
	8
);
INSERT INTO ppc_ads VALUES (
	3,
	2,
	36,
	3,
	'Free SEO Analysis Report',
	'Complete Analysis of your Website',
	'SEO Experts. Call 09 521 3099',
	15,
	14,
	15,
	8
);
INSERT INTO ppc_ads VALUES (
	4,
	2,
	36,
	4,
	'Free Listing &amp; Text Link',
	'Welcome to R-TT Directory',
	'No fees, No backlink required',
	17,
	16,
	17,
	8
);
INSERT INTO ppc_ads VALUES (
	5,
	2,
	36,
	5,
	'20 Search Engines-Free',
	'Website submission to 20 popular',
	'search engines. Fast, easy &amp; free!',
	19,
	18,
	19,
	8
);
INSERT INTO ppc_ads VALUES (
	6,
	2,
	36,
	6,
	'Free Site Optimization',
	'100% Free. Get your site ranked',
	'better with all the search engines.',
	21,
	20,
	21,
	8
);
INSERT INTO ppc_ads VALUES (
	7,
	2,
	36,
	7,
	'Need better SERP ranking?',
	'Enjoy these great advices on how to',
	'play straight and get best results.',
	24,
	22,
	23,
	8
);
INSERT INTO ppc_ads VALUES (
	8,
	2,
	36,
	8,
	'Free Website Promotion',
	'Smart Promotion Service',
	'Submit to over 40 Search Engines',
	26,
	25,
	26,
	8
);
INSERT INTO ppc_ads VALUES (
	9,
	1,
	36,
	1,
	'Promote Your Site Online',
	'Attract Qualified Visitors &amp; Leads',
	'to Your Site Through Google Ads',
	29,
	27,
	28,
	8
);
INSERT INTO ppc_ads VALUES (
	10,
	1,
	36,
	2,
	'SEO Services NZ',
	'Search Engine Optimisation &amp;',
	'Pay Per Click Advertising Experts',
	30,
	11,
	12,
	8
);
INSERT INTO ppc_ads VALUES (
	11,
	1,
	36,
	3,
	'Easy To Use SEO Tool',
	'Optimize keywords and check search',
	'engine best practices. Try now.',
	33,
	31,
	32,
	8
);
INSERT INTO ppc_ads VALUES (
	12,
	1,
	36,
	4,
	'Online Profile Building',
	'Save Yourself Hours of Tedious Work',
	'Local NZ Manual Backlink Building',
	35,
	34,
	35,
	8
);
INSERT INTO ppc_ads VALUES (
	13,
	1,
	36,
	5,
	'SEO Experts - NZ',
	'Get your webite ranked today.',
	'Increase your sales and leads!',
	37,
	36,
	37,
	8
);
INSERT INTO ppc_ads VALUES (
	14,
	1,
	36,
	6,
	'Free SEO Checklist',
	'Improve Your Search Rankings',
	'Free SEO Checklist Tool',
	39,
	38,
	39,
	8
);
INSERT INTO ppc_ads VALUES (
	15,
	1,
	36,
	7,
	'Search Engine SEO Service',
	'Increase Website Rank &amp; Sales!',
	'Free Analysis Report. SEO Experts',
	15,
	40,
	15,
	8
);
INSERT INTO ppc_ads VALUES (
	16,
	1,
	36,
	8,
	'Still Stuck On Page 2?',
	'Turn Your Site Into a Search Engine',
	'Leader! Get Our Free SEO Guide.',
	43,
	41,
	42,
	8
);
INSERT INTO ppc_ads VALUES (
	17,
	1,
	36,
	1,
	'Google Website Promotion',
	'Get better ROI from your website.',
	'Try Google ad programmes today!',
	29,
	27,
	28,
	9
);
INSERT INTO ppc_ads VALUES (
	18,
	1,
	36,
	2,
	'SEO Specialists',
	'Boost Your Site Search Rankings',
	'Get More Online Traffic, NZ',
	44,
	11,
	12,
	9
);
INSERT INTO ppc_ads VALUES (
	19,
	1,
	36,
	3,
	'Easy To Use SEO Tool',
	'Optimize keywords and check search',
	'engine best practices. Try now.',
	33,
	31,
	32,
	9
);
INSERT INTO ppc_ads VALUES (
	20,
	1,
	36,
	4,
	'SEO Software',
	'Top 10 rankings or money back.',
	'Easy. Reliable. Proven. Safe.',
	47,
	45,
	46,
	9
);
INSERT INTO ppc_ads VALUES (
	21,
	1,
	36,
	5,
	'SEO Experts - NZ',
	'Get your webite ranked today.',
	'Increase your sales and leads!',
	37,
	36,
	37,
	9
);
INSERT INTO ppc_ads VALUES (
	22,
	1,
	36,
	6,
	'Try Our Free SEO Software',
	'Turn Your Site Into a Search Engine',
	'Leader! Get Our Free SEO Guide.',
	43,
	41,
	42,
	9
);
INSERT INTO ppc_ads VALUES (
	23,
	1,
	36,
	7,
	'Free SEO Checklist',
	'Improve Your Search Rankings',
	'Free SEO Checklist Tool',
	39,
	38,
	39,
	9
);
INSERT INTO ppc_ads VALUES (
	24,
	1,
	36,
	8,
	'Search Engine SEO Service',
	'Increase Website Rank &amp; Sales!',
	'Free Analysis Report. SEO Experts',
	15,
	40,
	15,
	9
);
INSERT INTO ppc_ads VALUES (
	25,
	2,
	36,
	1,
	'Seo professional advice',
	'12 step approach to get relevant',
	'traffic. New or existing sites',
	10,
	9,
	10,
	9
);
INSERT INTO ppc_ads VALUES (
	26,
	2,
	36,
	2,
	'SEO Specialists',
	'Boost Your Site Search Rankings',
	'Get More Online Traffic, NZ',
	44,
	11,
	12,
	9
);
INSERT INTO ppc_ads VALUES (
	27,
	2,
	36,
	3,
	'Search Engine SEO Service',
	'Increase Website Rank &amp; Sales!',
	'Free Analysis Report. SEO Experts',
	15,
	40,
	15,
	9
);
INSERT INTO ppc_ads VALUES (
	28,
	2,
	36,
	4,
	'Free Listing &amp; Text Link',
	'Welcome to R-TT Directory',
	'No fees, No backlink required',
	17,
	16,
	17,
	9
);
INSERT INTO ppc_ads VALUES (
	29,
	2,
	36,
	5,
	'20 Search Engines-Free',
	'Website submission to 20 popular',
	'search engines. Fast, easy &amp; free!',
	19,
	18,
	19,
	9
);
INSERT INTO ppc_ads VALUES (
	30,
	2,
	36,
	6,
	'Free Software',
	'Organise, find, edit, print &amp; share',
	'Try Picasa - Free from Google',
	49,
	48,
	49,
	9
);
INSERT INTO ppc_ads VALUES (
	31,
	2,
	36,
	7,
	'Free Site Optimization',
	'100% Free. Get your site ranked',
	'better with all the search engines.',
	21,
	20,
	21,
	9
);
INSERT INTO ppc_ads VALUES (
	32,
	2,
	36,
	8,
	'Need better SERP ranking?',
	'Enjoy these great advices on how to',
	'play straight and get best results.',
	24,
	22,
	23,
	9
);
