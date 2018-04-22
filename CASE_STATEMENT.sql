/*CASE STATEMENT WORK*/

/*
-- Emily Ding
CASE: label customers' address based on the 7 regions where our customers come from:
1) New England Region: Maine, Rhode Island, Vermont, Connecticut, New Hampshire and Massachusetts
2) Mid-Atlantic Region: New York, New Jersey and Pennsylvania
3) Southern Region: Virginia, West Virginia, Kentucky, Delaware, Maryland, North 
				and South Carolina, Tennessee, Arkansas, Louisiana, Florida, Georgia, 
				Alabama and Mississipp
4) Mid-West Region: Michigan, North and South Dakota, Iowa, Minnesota, Kansas, Nebraska, 
				Ohio, Indiana, Illinois, Wisconsin and Missouri
5) South-West Region: Texas, Arizona, New Mexico and Oklahoma
6) Pacific Coastal Region: California, Oregon and Washington
7) Rocky Mountains: else, Montana, Idaho, Colorado, Utah, Wyoming and Nevada
*/

SELECT (CASE
		WHEN [State] IN ('Maine, ME', 'Rhode Island, RI', 'Vermont, VT', 'Connecticut, CT', 
		'New Hampshire, NH', 'Massachusetts, MA') 
		THEN 'New England Region'
		WHEN [State] IN ('New York, NY', 'New Jersey, NJ', 'Pennsylvania, PA') 
		THEN 'Mid-Atlantic Region'
		WHEN [State] IN ('Virginia, VA', 'West Virginia, WV', 'Kentucky, KY', 'Delaware, DE',
		'Maryland, MD', 'North Carolina, NC', 'South Carolina, SC', 'Tennessee, TN', 
		'Arkansas, AR, ', 'Louisiana, LA', 'Florida, FL', 'Georgia, GA', 'Alabama, AL', 
		'Mississipp, MS') 
		THEN 'Southern Region'
		WHEN [State] IN ('Michigan, MI', 'North Dakota, ND', 'South Dakota, SD', 'Iowa, IA', 
		'Minnesota, MN', 'Kansas,KS', 'Nebraska, NE', 'Ohio, OH', 'Indiana, IN', 'Illinois, IL', 
		'Wisconsin, WI', 'Missouri, MO') 
		THEN 'Mid-West Region'
		WHEN [State] IN ('Texas, TX', 'Arizona, AZ', 'New Mexico, NM', 'Oklahoma, OK')
		THEN 'South-West Region'
		WHEN [State] IN ('California, CA', 'Oregon, OR', 'Washington, WA')
		THEN 'Pacific Coastal Region'
		ELSE 'Rocky Mountains'
		END) AS 'Customer_Region', COUNT(*) AS 'TotalNum'
FROM tblCustomer C JOIN tblAddress A ON C.AddressID = A.AddressID
GROUP BY (CASE
		WHEN [State] IN ('Maine, ME', 'Rhode Island, RI', 'Vermont, VT', 'Connecticut, CT', 
		'New Hampshire, NH', 'Massachusetts, MA') 
		THEN 'New England Region'
		WHEN [State] IN ('New York, NY', 'New Jersey, NJ', 'Pennsylvania, PA') 
		THEN 'Mid-Atlantic Region'
		WHEN [State] IN ('Virginia, VA', 'West Virginia, WV', 'Kentucky, KY', 'Delaware, DE',
		'Maryland, MD', 'North Carolina, NC', 'South Carolina, SC', 'Tennessee, TN', 
		'Arkansas, AR, ', 'Louisiana, LA', 'Florida, FL', 'Georgia, GA', 'Alabama, AL', 
		'Mississipp, MS') 
		THEN 'Southern Region'
		WHEN [State] IN ('Michigan, MI', 'North Dakota, ND', 'South Dakota, SD', 'Iowa, IA', 
		'Minnesota, MN', 'Kansas,KS', 'Nebraska, NE', 'Ohio, OH', 'Indiana, IN', 'Illinois, IL', 
		'Wisconsin, WI', 'Missouri, MO') 
		THEN 'Mid-West Region'
		WHEN [State] IN ('Texas, TX', 'Arizona, AZ', 'New Mexico, NM', 'Oklahoma, OK')
		THEN 'South-West Region'
		WHEN [State] IN ('California, CA', 'Oregon, OR', 'Washington, WA')
		THEN 'Pacific Coastal Region'
		ELSE 'Rocky Mountains'
		END)
ORDER BY TotalNum DESC