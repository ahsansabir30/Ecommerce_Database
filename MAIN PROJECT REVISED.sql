CREATE DATABASE OnlineRetail; 
USE OnlineRetail;

-- Customer Side
CREATE TABLE customers(
    customerID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customerUsername VARCHAR(20) UNIQUE NOT NULL,
    firstName VARCHAR(20) NOT NULL,
    middleName VARCHAR(20), 
    lastName VARCHAR(20) NOT NULL,
    streetName VARCHAR(40) NOT NULL,
    city VARCHAR(20) NOT NULL,
    postcode VARCHAR(20) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    phoneNumber INT UNIQUE NOT NULL,
    dateJoined DATE,
    modified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    loyaltymeter VARCHAR(20),
    INDEX customerdetails (customerID, firstName, lastName, streetName, city, postcode),
    INDEX customercontacts (customerID, firstName, lastName, email, phoneNumber)
);

ALTER TABLE customers 

DELIMITER //
CREATE PROCEDURE customerprocedure(pAction VARCHAR(10), pcustomerID INT, pcustomerUsername VARCHAR(20), pfirstName VARCHAR(20),
                                   pmiddleName VARCHAR(20), plastName VARCHAR(20), pstreetName VARCHAR(40), pcity VARCHAR(20),
                                   ppostcode VARCHAR(20), pemail VARCHAR(50), pphoneNumber TINYINT, pdateJoined DATE
)
BEGIN
    IF pAction = "INSERT" THEN
        INSERT INTO customers(customerID, customerUsername, firstName, middleName, lastName, 
                             streetName, city, postcode, email, phoneNumber, dateJoined)
        VALUES (pcustomerID, pcustomerUsername, pfirstName, pmiddleName, plastName,
				pstreetName, pcity, ppostcode, pemail, pphoneNumber, pdateJoined);
    END IF;
    IF pAction = "UPDATE" THEN
        UPDATE Customers
        SET customerID = pCustomerID,
            customerUsername = pcustomerUsername,
            firstName = pfirstName,
            middleName = pmiddleName, 
            lastName = plastname,
			streetName = pstreetName,
            city = pcity,
            postcode = ppostcode,
            email = pemail,
            phoneNumber = pphonenumber,
            dateJoined= pdateJoined
        WHERE customerID= pCustomerID;
    END IF;
    IF pAction = "DELETE" THEN
        DELETE FROM Customers
        WHERE customersID = pcustomerID;
    END IF;
END // 
DELIMITER ;

DELIMITER //
CREATE PROCEDURE customerdetails(
                IN pcustomerID INT,
                OUT Forname VARCHAR(20),
                OUT Surname VARCHAR(20),
                OUT Address VARCHAR(50))
BEGIN 
         SELECT firstName AS Forname, 
                lastName AS Surname, 
                CONCAT('streetName', ',', 'city', ',' 'postcode') AS Address 
         FROM customers 
         WHERE customerID= pcustomerID;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE createEmailList (
	INOUT emailList varchar(4000)
)
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE EmailAddress VARCHAR(100) DEFAULT "";

	DEClARE cursor_email 
		CURSOR FOR 
			SELECT email FROM customers;

	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN cursor_email;

	getEmail: LOOP
		FETCH cursor_email  
        INTO EmailAddress;
		IF finished = 1 THEN 
			LEAVE getEmail;
		END IF;
	
		SET emailList = CONCAT(EmailAddress,",",emailList);
	END LOOP getEmail;
	CLOSE  cursor_email;
END //
DELIMITER ;
SET @emailList = ""; 
CALL createEmailList(@emailList); 
SELECT @emailList;

CREATE TABLE customerdeletion (
	customerID INT PRIMARY KEY,
    customerUsername VARCHAR(20),
    firstName VARCHAR(20),
    middleName VARCHAR(20), 
    lastName VARCHAR(20),
    streetName VARCHAR(40),
    city VARCHAR(20),
    postcode VARCHAR(20),
    email VARCHAR(50),
    phoneNumber INT,
    dateJoined DATE,
    time_deleted_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    loyaltymeter VARCHAR(20)); 

DELIMITER //
CREATE TRIGGER customerdeletion
BEFORE DELETE ON customers 
FOR EACH ROW
BEGIN 
INSERT INTO customerdeletion VALUES(old.customerID, old.customerUsername, old.firstName, old.middleName, old.lastName, 
								    old.streetName, old.city, old.postcode, old.email, old.phoneNumber, old.dateJoined,
                                    old.loyaltymeter, old.modified_at);
END //
DELIMITER ; 

CREATE TABLE payment(
    paymentID VARCHAR(20) PRIMARY KEY NOT NULL,
    customerID INT UNIQUE NOT NULL,
    paymenttype VARCHAR(10) NOT NULL,
    cardno INT UNIQUE NOT NULL, 
    cardexp DATE NOT NULL,
    cardCVC INT NOT NULL,
    billingAddress VARCHAR(100) NOT NULL,
    billingCity VARCHAR(20) NOT NULL,
    billingPostcode VARCHAR(9) NOT NULL,
    date_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(customerID) REFERENCES customers(customerID) ON DELETE CASCADE,
    CONSTRAINT paymentType CHECK (paymentType IN ('Credit', 'Debit', 'Paypal', 'Other'))
);

DELIMITER //
CREATE PROCEDURE addpayment(
                 ppaymentID VARCHAR(20),
				 pcustomerID INT,
                 ppaymenttype VARCHAR(10),
                 pcardno INT(16),
                 pcardexp DATE,
                 pcardCVC INT(3),
                 pbillingAddress VARCHAR(100),
                 pbillingCity VARCHAR(20),
                 pbillingPostcode VARCHAR(9))
BEGIN 
INSERT INTO Payment VALUES (ppaymentID, pcustomerID, ppaymenttype, pcardno, pcardexp, pcardCVC, pbillingAddress, pbillingCity, pbillingPostcode);
END //
DELIMITER ; 

CREATE TABLE cart(
    cartid VARCHAR(10) PRIMARY KEY UNIQUE NOT NULL,
    customerID VARCHAR(15) NOT NULL UNIQUE,
    productID VARCHAR(10) NOT NULL UNIQUE,
    productSKU VARCHAR(20) NOT NULL UNIQUE, 
    price DECIMAL(4,2),
    quantity INT, 
    cart_active VARCHAR(9),
    created_at DATETIME,
    modified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    CONSTRAINT active CHECK (active IN ('active', 'notactive'))
);
ALTER TABLE cart ADD FOREIGN KEY (productID) REFERENCES product(productID);

CREATE TABLE customerorders(
    orderID VARCHAR(15) NOT NULL UNIQUE,
    customerID INT UNIQUE NOT NULL,
    productID VARCHAR(20) UNIQUE NOT NULL,
    productName VARCHAR(100),
    productSKU VARCHAR(20) UNIQUE NOT NULL,
    productPrice INT,
    order_quantity INT DEFAULT 0,
    weightperitem INT DEFAULT 0,
    totalPrice DECIMAL(5,2) DEFAULT 0,
    totalWeight INT DEFAULT 0,
    costofshippingbykg DECIMAL(5,2) DEFAULT 1, 
    costofshipping DECIMAL(5,2) DEFAULT 0, 
    totalpriceplusshipping DECIMAL(5,2) DEFAULT 0,
    orderDate DATETIME NOT NULL,
	dispatchDate DATETIME,
    requiredbyDate DATE NOT NULL,
    arrivalDate DATE DEFAULT NULL,
    shipperID VARCHAR(10) UNIQUE NOT NULL,
    paymentID VARCHAR(20) UNIQUE NOT NULL,
    paid VARCHAR(3) NOT NULL,
    paymentDate DATETIME NOT NULL,
    date_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(customerID) REFERENCES customers(customerID) ON DELETE NO ACTION,
    FOREIGN KEY(paymentID) REFERENCES Payment(paymentID) ON DELETE SET NULL,
    FOREIGN KEY(productSKU) REFERENCES product(productSKU) ON DELETE NO ACTION,
    FOREIGN KEY(shipperID) REFERENCES shippers(shipperID) ON DELETE NO ACTION,
    PRIMARY KEY(orderID, customerID),
    CONSTRAINT paid_chk CHECK (paid IN ('yes', 'no')),
    INDEX customerorder(orderID, productName, productSKU, productPrice, order_quantity),
    INDEX cost(orderID, totalPrice, costofshipping, totalpriceplusshipping), 
    INDEX customerpayment(orderID, paymentID, paid, paymentDate),
    INDEX orderDate(orderID, orderdate, dispatchDate, requiredDate, fullfilled) 
);
ALTER TABLE customerorders2 ADD FOREIGN KEY(productID) REFERENCES product(productID) ON DELETE NO ACTION;

DELIMITER //
CREATE PROCEDURE insert_order(porderID VARCHAR(15), pcustomerID INT, pproductID VARCHAR(20), pproductName VARCHAR(100), productSKU VARCHAR(20), pproductPrice INT, porder_quantity INT, pweightperitem INT, ptotalPrice DECIMAL(5,2),
    ptotalWeight INT, costofshippingbykg DECIMAL(5,2), pcostofshipping DECIMAL(5,2), ptotalpriceplusshipping DECIMAL(5,2),
    porderDate DATETIME, pdispatchDate DATETIME, prequiredDate DATE, pfullfilled VARCHAR(3), pshipperID VARCHAR(10), ppaymentID VARCHAR(20), ppaid VARCHAR(3), ppaymentDate DATETIME)
BEGIN 
INSERT INTO customerorders( orderID, customerID, productID, productName, productSKU, productPrice, order_quantity, weightperitem, totalPrice, totalWeight, costofshippingbykg, 
    costofshipping, totalpriceplusshipping, orderDate, dispatchDate, requiredDate, fullfilled, shipperID, paymentID, paid, paymentDate) 
VALUES (porderID, pcustomerID, pproductID, pproductName, pproductSKU, pproductPrice, porder_quantity, pweightperitem, ptotalPrice, ptotalWeight, pcostofshippingbykg, 
    pcostofshipping, ptotalpriceplusshipping, porderDate, pdispatchDate, prequiredDate, pfullfilled, pshipperID, ppaymentID, ppaid, ppaymentDate);
END //
DELIMITER ;
		        
CREATE TABLE productReview(
    reviewID VARCHAR(20) PRIMARY KEY UNIQUE,
    productID VARCHAR(10) UNIQUE NOT NULL,
    customerID INT UNIQUE NOT NULL,
    customerUsername VARCHAR(20) NOT NULL UNIQUE,
    reviewtitle VARCHAR(100) NOT NULL,
    content TEXT NOT NULL, 
    reviewRating TINYINT NOT NULL,
    datecreated DATETIME NOT NULL ,
    date_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(productID) REFERENCES product(productID) ON DELETE CASCADE, 
    FOREIGN KEY(customerID) REFERENCES Customer(customerID) ON DELETE NO ACTION,
    CONSTRAINT reviewRating CHECK(reviewRating IN (1,2,3,4,5,6,7,8,9,10))
);

DELIMITER //
CREATE PROCEDURE customerloyalty(
     IN pcustomerid INT,
     OUT pcustomerloyalty VARCHAR(20))
BEGIN 
     DECLARE orders INT DEFAULT 0;
     
     SELECT COUNT(customerID)
     INTO orders 
     FROM customerOrder
     WHERE customerID = pcustomerid;
     
    IF orders >= 100 THEN
	  SET pcustomerloyalty = 'VIP';
    ELSEIF orders >=50 AND orders <100 THEN   
      SET pcustomerloyalty = 'GOLD';
	ELSEIF orders >=10 AND orders <50 THEN   
      SET pcustomerloyalty = 'SILVER';
	ELSEIF orders >=1 AND orders <10 THEN   
      SET pcustomerloyalty = 'BRONZE';
	ELSE 
      SET pcustomerloyalty = 'NEW';
	END IF;
END //
DELIMITER ;

-- Online Retail
CREATE TABLE shippers(
    shipperID VARCHAR(10) PRIMARY KEY NOT NULL,
    shippersName VARCHAR(20) NOT NULL,
    shippersAddress VARCHAR(50) NOT NULL UNIQUE,
    shippersCity VARCHAR(20) NOT NULL,
    shippersPostcode VARCHAR(10) NOT NULL,
    shippersEmail VARCHAR(50) NOT NULL UNIQUE,
    companyNo VARCHAR(15) NOT NULL UNIQUE
);
       
CREATE TABLE supplier(
    supplierID VARCHAR(20) PRIMARY KEY NOT NULL UNIQUE,
    supplierName VARCHAR(20) NOT NULL,
    supplierAddress VARCHAR(100) NOT NULL,
    supplierCity VARCHAR(20) NOT NULL,
    supplierEmail VARCHAR(50) UNIQUE NOT NULL,
    supplierPhone VARCHAR(15) UNIQUE NOT NULL,
    supplierURL VARCHAR(100) UNIQUE,
    supplierpaymethod VARCHAR(100) NOT NULL,
    supplierproduct VARCHAR(100) NOT NULL,
    supplierdesc VARCHAR(100), 
    vendorproductSKU VARCHAR(20) UNIQUE,
    productSKU VARCHAR(20) UNIQUE,
    productID VARCHAR(20) UNIQUE,
    dicount_type DECIMAL(2,2),
    INDEX supplierdetail(supplierName, supplierAddress, supplierCity, supplierEmail, supplierPhone)
);
ALTER TABLE supplier ADD FOREIGN KEY(productID) REFERENCES product(productID);

DELIMITER //
CREATE PROCEDURE supplier_list (INOUT supplier VARCHAR(100))
BEGIN 
	DECLARE done INTEGER DEFAULT 0;
    DECLARE supplier_names VARCHAR(20) DEFAULT "";

	DECLARE supplier_cursor CURSOR FOR 
		SELECT suppliername FROM supplier;

	OPEN supplier_cursor;
		getlist: LOOP
		FETCH supplier_cursor INTO supplier_names;
		IF done = 1 THEN LEAVE getlist;
		END IF;
SET supplier_list = CONCAT(supplier_names, " , ", supplier_list);
END LOOP getlist;
CLOSE supplier_cursor;
END//
DELIMITER ;
SET @supplier_list ="";  
CALL supplier_names(@supplier_list);  
SELECT @supplier_list;  

CREATE TABLE inventoryCategory(
    categoryID VARCHAR(1) UNIQUE NOT NULL,
    categoryName VARCHAR(10),
    PRIMARY KEY (categoryID)
);

CREATE TABLE product(
    productID VARCHAR(10) UNIQUE NOT NULL, 
    categoryID VARCHAR(1),
    productSKU VARCHAR(20) UNIQUE NOT NULL,
    vendorproductSKU VARCHAR(20) UNIQUE,
    product VARCHAR(100) NOT NULL,
    productpic VARCHAR(100),
    productdesc TEXT,
    weight DECIMAL(10,2) NOT NULL,
    msrp VARCHAR(100) NOT NULL,
    dicount_markup INT DEFAULT 1,
    productPrice DECIMAL(5,2) NOT NULL,
    productQuantity INT NOT NULL,
    supplierID VARCHAR(20),
    created_at DATE NOT NULL,
    modified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (productID, productSKU),
    FOREIGN KEY(categoryID) REFERENCES inventoryCategory(categoryID) ON DELETE SET NULL,
    FOREIGN KEY(supplierID) REFERENCES supplier(supplierID) ON DELETE SET NULL,
    FOREIGN KEY(vendorproductSKU) REFERENCES supplier(vendorproductSKU) ON DELETE SET NULL,
    INDEX product_info(productSKU, product, productpic, productdesc(100), msrp, dicount_markup, productPrice, productQuantity)
);
ALTER TABLE product ADD FOREIGN KEY(productSKU) REFERENCES supplier(productSKU) ON DELETE NO ACTION;

DELIMITER //
CREATE TRIGGER productupdate 
AFTER INSERT ON customerorders
FOR EACH ROW
BEGIN
  DECLARE quantityo INT DEFAULT 0;

  SELECT quantity INTO @quantityo FROM customerorders WHERE productID = new.productID;
  
  IF @quantityo> 0
  THEN
     UPDATE product 
     SET product.quantity= product.quantity - @quantityo
     WHERE productID = NEW.productID;
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER productupdate_deleteorder 
BEFORE DELETE ON customerorder
FOR EACH ROW
BEGIN
  DECLARE quantityd INT DEFAULT 0;

  SELECT quantity INTO @quantityd FROM customerorders WHERE productID = OLD.productID;
  
  IF @quantityo> 0
  THEN
     UPDATE product 
     SET product.quantity= product.quantity + @quantityd
     WHERE productID = OLD.productID;
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE newsupply(
	pproductID VARCHAR(10), 
    pcategoryID VARCHAR(1),
    pproductSKU VARCHAR(20),
    pvendorproductSKU VARCHAR(20),
    pproduct VARCHAR(100),
    pproductpic VARCHAR(100),
    pproductdesc TEXT,
    pmsrp DECIMAL(5,2),
    pproductPrice DECIMAL(5,2),
    pproductQuantity INT,
    psupplierID VARCHAR(20),
    pcreated_at DATE)
BEGIN 
	DECLARE EXIT HANDLER FOR 1062 
    BEGIN 
     SELECT CONCAT ('Duplicate Product ID (',pproductID,') Occurred') AS Message;
     END;
	INSERT INTO Product (productID, categoryID, productSKU, vendorproductSKU, product, productpic, productdesc, msrp, productPrice, productQuantity, supplierID, created_at) 
	VALUES (pproductID, pcategoryID, pproductSKU, pvendorproductSKU, pproduct, pproductpic, pproductdesc, pmsrp, pproductPrice, pproductQuantity, psupplierID, pcreated_at);
END //

-- Views
CREATE VIEW customerdetails AS
SELECT customerID, 
       firstName, 
       lastName, 
       streetName, 
       city,
       postcode
FROM customers;

CREATE VIEW customerorder AS 
SELECT customerID
       orderID, 
	   productName, 
       productSKU, 
       productPrice, 
       quantity
FROM customerorders;

CREATE VIEW total_customer_orders AS
SELECT customerID, COUNT(customerID) FROM customerorders;




    