CREATE TABLE Manufacturer (
    manufacturer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Vehicle (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    manufacturer_id INT,
    make VARCHAR(100),
    model VARCHAR(100),
    year INT,
    fuel_type VARCHAR(50),
    engine_desc VARCHAR(100),
    mpg_city FLOAT,
    mpg_highway FLOAT,
    combined_mpg_ft1 FLOAT,
    co2_emissions FLOAT,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id)
);

CREATE TABLE ListingCondition (
    condition_id INT PRIMARY KEY AUTO_INCREMENT,
    accident_history VARCHAR(255),
    clean_title BOOLEAN
);

CREATE TABLE UsedCarListing (
    listing_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT,
    model_year INT,
    milage INT,
    price FLOAT,
    transmission VARCHAR(50),
    ext_color VARCHAR(50),
    int_color VARCHAR(50),
    condition_id INT,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
    FOREIGN KEY (condition_id) REFERENCES ListingCondition(condition_id)
);
