-- SYNTHETIC test data. These rows are invented to exercise edge cases; they are not from the project's dataset.
-- Edge cases: mileage-bracket boundaries (29999/30000/60000/60001/100000/100001), a zero-mileage listing,
-- a listing with no price, and a vehicle whose make text ("Ford Motor") differs from its manufacturer's name.
INSERT INTO Manufacturer VALUES (1,'Toyota'),(2,'Ford'),(3,'BMW');
INSERT INTO Vehicle VALUES
 (1,1,'Toyota','Prius',2015,'Hybrid','1.8L I4',54,50,52,180),
 (2,2,'Ford','F-150',2010,'Gasoline','5.0L V8',15,21,17,520),
 (3,3,'BMW','M3',2012,'Gasoline','4.0L V8',14,20,16,560),
 (4,2,'Ford Motor','Focus',2014,'Gasoline','2.0L I4',26,36,30,300);
INSERT INTO ListingCondition VALUES
 (1,'None reported',TRUE),(2,'At least 1 accident or damage reported',TRUE),(3,'None reported',FALSE);
INSERT INTO UsedCarListing VALUES
 (1,1,2015,29999,18000,'Automatic','White','Black',1),
 (2,1,2015,30000,17000,'Automatic','Black','Beige',1),
 (3,2,2010,60000,15000,'Manual','Red','Gray',2),
 (4,2,2010,60001,14000,'Automatic','Black','Black',1),
 (5,3,2012,100000,25000,'Manual','Blue','Black',2),
 (6,3,2012,100001,9000,'Automatic','White','Beige',3),
 (7,4,2014,0,12000,'Automatic','Silver','Black',1),
 (8,4,2014,45000,NULL,'Automatic','Silver','Gray',1);
