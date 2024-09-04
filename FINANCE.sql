

CREATE DATABASE Finance_LoanDb;

USE Finance_LoanDb;

CREATE TABLE Customer(
      [CustomerID] NVARCHAR(20), 
	  [CustomerName] NVARCHAR(30), 
	  [LoanID] NVARCHAR(50),
	  [LoanAmount] INT, 
	  [InterestRate] NVARCHAR(20),
	  [StateID] NVARCHAR(20)
	  );

INSERT INTO Customer(CustomerID, CustomerName, LoanID, LoanAmount, InterestRate, StateID)
VALUES   
     ('C01','Alice Johnson', 'L01', '50000', '5.50%', '101'),
     ('C02', 'Bob Smith','L02', '75000','6.00%', '102'), 
     ('C03', 'Carol white', 'L03', '60000','4.80%', '103'),
     ('C04', 'Dave Williams', 'L04', '85000','5.20%', '104'),
     ('C05', 'Emma Brown', 'L05', '55000','4.50%', '105'),
     ('C06', 'Frank Miller', 'L06', '40000','6.50%', '106'),
	 ('C07', 'Grace Davis', 'L07', '95000','5.80%', '107'),
     ('C08', 'Henry Willson', 'L08', '30000','6.20%', '108'),
	 ('C09', 'Irene Moore', 'L09', '70000','5.00%', '109'),
	 ('C10', 'Jack Taylor', 'L10','80000','5.70%', '110');



CREATE TABLE Loan
(
     [LoanID] NVARCHAR(20),
	  [LoanType] NVARCHAR(20),
	  [LoanAmount] INT,
	  [CustomerID] NVARCHAR(30)
	  );

INSERT INTO Loan (LoanID, LoanType, LoanAmount, CustomerID)
VALUES  
	('L01', 'Home Loan', '50000','C01'),
	('L02', 'Auto Loan', '75000', 'C02'),
	('L03', 'Personal Loan','60000', 'C03'),
	('L04', 'Education Loan', '85000','C04'),
	('L05', 'Business Loan', '55000','C05'),
	('L06', 'Home Loan', '40000','C06'),
	('L07', 'Auto Loan', '95000','C07'),
	('L08', 'Personal Loan', '30000','C08'),
	('L09', 'Education Loan', '70000','C09'),
	('L10', 'Business Loan', '80000','C10');


CREATE TABLE Statemaster
(
	 [StateID] INT,
	 [StateName] NVARCHAR(20)
	 );

INSERT INTO Statemaster(StateID, StateName)
VALUES  
	('101', 'Lagos'),
	('102', 'Abuja'),
	('103', 'Kano'),
	('104', 'Delta'),
	('105','Ido'),
	('106','Ibadan'),
	('107','Enugu'),
	('108','Kaduna'),
	('109','Ogun'),
	('110','Anambra');




CREATE TABLE  Branchmaster
(
       [BranchmasterID] NVARCHAR(20),
	   [BranchmasterName] NVARCHAR(30),
	   [Location]NVARCHAR(20)
	  );

INSERT INTO  Branchmaster(BranchmasterID, BranchmasterName, Location)
VALUES
    ('B01', 'MainBranch', 'Lagos'),
	('B02','EastBranch', 'Abuja'),
	('B03','WestBranch', 'Kano'),
	('B04', 'NorthBranch', 'Delta'),
	('B05', 'SouthBranch', 'Ido'),
	('B06', 'CentralBranch', 'Ibadan'),
	('B07', 'PacificBranch', 'Enugu'),
	('B08', 'MountainBranch', 'Kaduna'),
	('B09', 'SouthernBranch', 'Ogun'),
	('B10', 'GulfBranch', 'Anambra');
	

--1.Fetch customers with the same loan amount.

SELECT * 
FROM Customer
WHERE LoanAmount IN (
   SELECT (LoanAmount)
   FROM Customer
   GROUP BY LoanAmount
   HAVING COUNT (LoanAmount) > 1
);

--2.	Find the second highest loan amount and the customer and branch associated with it

SELECT C.CustomerID, C.CustomerName,C.LoanAmount,StateName, B.BranchmasterName
FROM Customer C
INNER JOIN Statemaster S
ON C.StateID = S.StateID
INNER JOIN Branchmaster B
ON S.StateName = B.Location
ORDER BY LoanAmount DESC
OFFSET  1 ROW
FETCH NEXT 1 ROW ONLY


--3.	Get the maximum loan amount per branch and the customer name.


SELECT C.CustomerName, C.LoanAmount MAXLoanAmount, StateName, B.BranchmasterName
FROM Customer C
INNER JOIN Statemaster S
ON C.StateID = S.StateID
INNER JOIN Branchmaster B
ON S.StateName = B.Location
JOIN (SELECT C.CustomerName, MAX (LoanAmount) AS MAXLoanAmount
FROM Customer C
GROUP BY StateID,CustomerName ) M ON C.StateID = C.StateID
AND C.LoanAmount = MAXLoanAmount


--4.	Branch-wise count of customers sorted by count in descending order.

SELECT COUNT(DISTINCT C.CustomerName) count_of_bw, B.BranchmasterName
 FROM Customer C, Branchmaster B, Statemaster S
 WHERE C.StateID = S.StateID
 AND S.StateName = B.Location
 GROUP BY C.CustomerName, B.BranchmasterName
 ORDER BY COUNT(*) DESC


--5.	Fetch only the first name from the CustomerName and append the loan amount.

SELECT CONCAT(LEFT(CustomerName,
        CHARINDEX (' ',CustomerName )-1), '_',LoanAmount) FirstName_Age
FROM Customer C


--6.	Fetch loans with odd amounts.

SELECT CustomerName,LoanAmount  FROM Customer C
WHERE LoanAmount % 2 = 1


--7.	Create a view to fetch loan details with an amount greater than $50,000.

CREATE VIEW vw_pt_loanamount_$50000 
AS
 SELECT C.CustomerID, C.CustomerName,C.LoanAmount, C.InterestRate, L.LoanType, S.StateName, B.BranchmasterName
 FROM Customer C
 INNER JOIN Loan L
 ON L.LoanID = C.LoanID
 INNER JOIN Statemaster S
 ON C.StateID = S.StateID
INNER JOIN Branchmaster B 
 ON S.StateName = B.Location
 WHERE C.LoanAmount > $50000

--8.Create a procedure to update the loan interest rate by 2% where the loan type is 'Home Loan' and the branch is not 'MainBranch'.

CREATE PROCEDURE InterestRate
AS
 BEGIN 
	UPDATE C
	SET C.InterestRate = C.InterestRate * 1.02
	FROM Customer C
	INNER JOIN Loan L ON C.LoanID = L.LoanID
	INNER JOIN Branchmaster B ON S.StateName = B.Location
	WHERE L.LoanType = 'HomeLoan' AND B.BranchmasterName NOT IN ('MainBranch')
END;
GO;
EXEC InterestRate;
GO 


--9.Create a stored procedure to fetch loan details along with the customer, branch, and state, including error handling.
CREATE PROCEDURE sp_fetch_loan_details
AS
BEGIN
    BEGIN TRY
        SELECT 
            C.LoanID,
			C.LoanAmount,
			C.CustomerName,
			L.LoanType,
			B.BranchmasterName
        FROM Customer C, Branchmaster B
        JOIN Loan L ON C.CustomerID = L.CustomerID
        JOIN Statemaster S ON S.StateName = B.Location

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(3000)
		SET @ErrorMessage = ERROR_MESSAGE()
        RAISERROR (@ErrorMessage, 20,1);
    END CATCH
END;
GO