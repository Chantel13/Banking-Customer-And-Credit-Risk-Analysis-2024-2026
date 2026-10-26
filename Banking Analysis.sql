BANKING ANALYSIS PROJECT
SQL PORTFOLIO

Objective: The objective of this project is to analyse customer banking activity, account balances, lending trends and loan repayment behaviour. The goal is to identify growth opportunities, investigate credit-risk patterns and provide data-driven recommendations to support better business decisions and sustainable lending.

Tools:
SQL Server / SSMS

Author: MS MNYONI, CHANTEL

1. DATA OVERVIEW

-- Check number of Customers
SELECT COUNT(*) AS [Total Customers]
FROM Customers;

-- Check number of Accounts
SELECT COUNT(*) AS [Total Accounts]
FROM Accounts;

-- Check number of Transactions
SELECT COUNT(*) AS [Total Transactions]
FROM Transactions;

-- Check number of Loans
SELECT COUNT(*) AS [Total Loans]
FROM Loans;

-- Check number of Loan Payments
SELECT COUNT (*) AS [Total Loan Payments]
FROM LoanPayments;

2. DATA QUALITY CHECK

-- Check for accounts with no matching customerID
SELECT
    A.AccountID,
    C.CustomerID
FROM Accounts AS A
LEFT JOIN Customers AS C
    ON a.customerid = c.customerid
WHERE C.CustomerID IS NULL;

-- Check for accounts with invaild balances
SELECT
    AccountID,
    AccountBalance
FROM Accounts
WHERE AccountBalance < 0;

-- Check for transactions with no matching customerID
SELECT
    T.TransactionID,
    C.CustomerID
FROM Transactions AS T
LEFT JOIN Customers AS C
    ON c.customerid = customerid
WHERE CustomerID IS NULL;

-- Check for transactions with invaild amounts
SELECT
    TransactionID,
    Amount
FROM Transactions
WHERE Amount <= 0;

-- Check for duplicate transactions
SELECT 
    TransactionID, 
    COUNT(TransactionID) AS NumberOfTransactions
FROM Transactions
GROUP BY TransactionID
HAVING COUNT(TransactionID) > 1;

-- Check for duplicate accounts
SELECT AccountID, COUNT(*) AS NumberOfAccounts
FROM Accounts
GROUP BY AccountID
HAVING COUNT(*) > 1;

-- Check for customers
SELECT CustomerID, COUNT(*) AS NumberOfCustomers
FROM Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- Check for duplicate loans
SELECT LoanID, COUNT(*) AS NumberOfLoans
FROM Loans
GROUP BY LoanID
HAVING COUNT(*) > 1;

-- Check for duplicate loan payments
SELECT PaymentID, COUNT(*) AS NumberOfLoanPayments
FROM LoanPayments
GROUP BY PaymentID
HAVING COUNT(*) > 1;

-- Check for invaild interest rates
SELECT 
    LoanID, 
    InterestRate 
FROM Loans 
WHERE InterestRate <= 0; 

-- Check for loans with no matching customerID
SELECT
    L.LoanID,
    C.CustomerID
FROM Loans AS L
LEFT JOIN Customers AS C
    ON c.customerid = l.customerid
WHERE C.CustomerID IS NULL;

-- Loan payments with no matching loan
SELECT
    LP.PaymentID,
    LP.LoanID
FROM LoanPayments AS LP
LEFT JOIN Loans AS L
    ON LP.LoanID = L.LoanID
WHERE L.LoanID IS NULL;

-- Check for invalid loan amounts
SELECT
    LoanID,
    LoanAmount
FROM Loans
WHERE LoanAmount <= 0;

4. LENDING GROWTH

-- How has the loan application volume and value change in each quarter

SELECT
    YEAR(ApplicationDate) Year,
    DATEPART(QUARTER, ApplicationDate) Quarter,
    COUNT(LoanID) ApplicationVolume,
    SUM(LoanAmount) TotalValue
FROM Loans
GROUP BY
    YEAR(ApplicationDate),
    DATEPART(QUARTER, ApplicationDate)
ORDER BY Year, Quarter;

-- What is the average interest rate by loan type

SELECT
    LoanType,
    AVG(InterestRate) AS AverageInterestRate
FROM Loans
GROUP BY LoanType
ORDER BY AverageInterestRate DESC;

-- What is the average loan amount

SELECT
    YEAR(ApplicationDate) AS Year,
    DATEPART(QUARTER, ApplicationDate) AS Quarter,
    COUNT(LoanID) AS ApplicationVolume,
    SUM(LoanAmount) AS TotalValue,
    AVG(LoanAmount) AS AverageLoanAmount
FROM Loans
GROUP BY
    YEAR(ApplicationDate),
    DATEPART(QUARTER, ApplicationDate)
ORDER BY
    Year, Quarter;

-- Loan application volume by loan type for Quarter 1 to Quarter 2 across all three years

SELECT
    YEAR(ApplicationDate) AS Year,
    LoanType,
    COUNT(LoanID) AS ApplicationVolume,
    SUM(LoanAmount) AS TotalLoanValue
FROM Loans
WHERE ApplicationDate IS NOT NULL
  AND DATEPART(QUARTER, ApplicationDate) <= 2
GROUP BY
    YEAR(ApplicationDate),
    LoanType
ORDER BY
    Year, ApplicationVolume DESC;

-- Average loan amount for Business and Vehicle loans

WITH ApplicationStatus AS
(
    SELECT
        YEAR(ApplicationDate) AS Year,
        LoanType,
        COUNT(LoanID) AS ApplicationVolume,
        SUM(LoanAmount) AS TotalLoanValue
    FROM Loans
    WHERE LoanType IN ('Business', 'Vehicle')
        AND ApplicationDate IS NOT NULL
        AND DATEPART(QUARTER, ApplicationDate) <= 2
    GROUP BY
        YEAR(ApplicationDate),
        LoanType
)
SELECT
    Year,
    LoanType,
    ApplicationVolume,
    TotalLoanValue,
    TotalLoanValue * 1.0 /
        NULLIF(ApplicationVolume, 0) AS AverageLoanAmount
FROM ApplicationStatus
ORDER BY Year, LoanType;

-- What percentage of loan applications are approved by loan type for the first and second quarter of each year

SELECT
    YEAR(ApplicationDate) Year,
    LoanType,
    CAST(
        SUM(CASE WHEN LoanStatus = 'Approved' THEN 1 ELSE 0 END) * 1.0 
        / COUNT(*) * 100
        AS DECIMAL(5,2)
    ) AS ApprovalRate
FROM Loans
WHERE DATEPART(QUARTER, ApplicationDate) <= 2
GROUP BY YEAR(ApplicationDate), LoanType
ORDER BY Year, ApprovalRate DESC;

5. LOAN PAYMENT 

-- What is the total amount received from loan payments by loan type

SELECT
    l.LoanType,
    SUM(lp.PaymentAmount) AS TotalAmountReceived
FROM Loans l
JOIN LoanPayments lp
    ON l.loanid = lp.loanid
GROUP BY l.LoanType;

-- Which loan types appear riskiest based on late and missed payments

WITH LoanRisk AS
(
    SELECT
        L.LoanType,
        COUNT(*) AS TotalPayments,
        SUM( CASE WHEN LP.PaymentStatus IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS RiskPayments
    FROM Loans AS L
        JOIN LoanPayments AS LP
            ON L.LoanID = LP.LoanID
    GROUP BY L.LoanType
)
SELECT
    LoanType,
    TotalPayments,
    RiskPayments,
    CAST( RiskPayments * 100.0 / NULLIF(TotalPayments, 0)
    AS DECIMAL(5,2)
) AS RiskPercentage
FROM LoanRisk
ORDER BY RiskPercentage DESC;

-- Repayment risk across loan approval statues

SELECT
    L.LoanStatus,
    COUNT(LP.PaymentID) AS TotalPayments,
    SUM( CASE WHEN LP.PaymentStatus IN ('Late', 'Missed') THEN 1 ELSE 0 END ) AS RiskPayments,
    CAST( SUM(CASE WHEN LP.PaymentStatus IN ('Late', 'Missed') THEN 1 ELSE 0 END) * 1.0 
        / NULLIF(COUNT(LP.PaymentID), 0) * 100
        AS DECIMAL(5,2)
    ) AS RiskPercentage
FROM Loans AS L
JOIN LoanPayments AS LP
    ON L.LoanID = LP.LoanID
GROUP BY L.LoanStatus
ORDER BY RiskPercentage DESC;

6. CUSTOMER BEHAVIOUR

-- Does home-loan repayment risk vary by city

WITH LoanRisk AS
(
    SELECT
        c.City,
        L.LoanType,
        COUNT(LP.PaymentID) AS TotalPayments,
        SUM( CASE WHEN LP.PaymentStatus IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS RiskPayments
    FROM Customers as c
        JOIN Loans AS L
            ON c.customerid = l.customerid
        JOIN LoanPayments AS LP
            ON L.LoanID = LP.LoanID
    WHERE l.LoanType = 'Home'
    GROUP BY 
    c.City, 
    L.LoanType
)
SELECT
    City,
    LoanType,
    TotalPayments,
    RiskPayments,
    CAST( RiskPayments * 100.0 / NULLIF(TotalPayments, 0)
    AS DECIMAL(5,2)
) AS RiskPercentage
FROM LoanRisk
ORDER BY RiskPercentage DESC;

-- What is the average income made by customers with different employment status, and which group is mostly associate with Johannesburgs higher risk payment rate

WITH LoanRisk AS
(
    SELECT
        c.City,
        c.EmploymentStatus,
        L.LoanType,
        AVG(DISTINCT c.Income) AverageIncome,
        COUNT(LP.PaymentID) AS TotalPayments,
        SUM( CASE WHEN LP.PaymentStatus IN ('Late', 'Missed') THEN 1 ELSE 0 END) AS RiskPayments
    FROM Customers AS c
        JOIN Loans AS L
            ON c.customerid = l.customerid
        JOIN LoanPayments AS LP
            ON L.LoanID = LP.LoanID
    WHERE City = 'Johannesburg'
        AND l.LoanType = 'Home'
    GROUP BY 
    c.City, 
    c.EmploymentStatus,
    L.LoanType
)
SELECT
    EmploymentStatus,
    AverageIncome,
    LoanType,
    TotalPayments,
    RiskPayments,
    CAST( RiskPayments * 100.0 / NULLIF(TotalPayments, 0)
    AS DECIMAL(5,2)
) AS RiskPercentage
FROM LoanRisk
ORDER BY RiskPercentage DESC;