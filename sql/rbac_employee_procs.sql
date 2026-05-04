/*
  HR Management Security System - RBAC Procedures

  Purpose:
  - create database roles for application-facing RBAC
  - block direct reads on sensitive tables
  - expose employee list/detail/update procedures per role
  - expose salary list/detail/update procedures per role

  Run this file after:
  1. sql/init.sql
  2. sql/seed.sql
*/

SET NOCOUNT ON;
GO

USE HRManagementSecuritySystem;
GO

SET NOCOUNT ON;
GO

/* =========================================================
   Database Roles
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_employee')
BEGIN
  CREATE ROLE rl_employee;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_manager')
BEGIN
  CREATE ROLE rl_manager;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_hrstaff')
BEGIN
  CREATE ROLE rl_hrstaff;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_hrmanager')
BEGIN
  CREATE ROLE rl_hrmanager;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_finance')
BEGIN
  CREATE ROLE rl_finance;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rl_director')
BEGIN
  CREATE ROLE rl_director;
END
GO

/* =========================================================
   Direct Table Access Restrictions
   ========================================================= */
DENY SELECT ON OBJECT::Employee TO PUBLIC;
DENY SELECT ON OBJECT::Department TO PUBLIC;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::Account TO PUBLIC;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::EmployeeSalaryConfig TO PUBLIC;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::EmployeeSalaryResult TO PUBLIC;
DENY SELECT ON OBJECT::HR_Request TO PUBLIC;
DENY SELECT ON OBJECT::Audit_Log TO PUBLIC;
GO

/* =========================================================
   Employee Read - Employee
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForEmployee
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Employee'
  BEGIN
    THROW 51001, 'Forbidden: role mismatch for Employee employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
    AND e.DepartmentID = @RequesterDepartmentID
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForEmployee
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Employee'
  BEGIN
    THROW 51002, 'Forbidden: role mismatch for Employee employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID
    AND e.DepartmentID = @RequesterDepartmentID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Read - Manager
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForManager
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Manager'
  BEGIN
    THROW 51003, 'Forbidden: role mismatch for Manager employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND d.ManagerID = @RequesterEmployeeID
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForManager
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Manager'
  BEGIN
    THROW 51004, 'Forbidden: role mismatch for Manager employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID
    AND d.ManagerID = @RequesterEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Read - HR Staff
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForHRStaff
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Staff'
  BEGIN
    THROW 51005, 'Forbidden: role mismatch for HR Staff employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
    AND e.DepartmentID <> 'D001'
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForHRStaff
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Staff'
  BEGIN
    THROW 51006, 'Forbidden: role mismatch for HR Staff employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID
    AND e.DepartmentID <> 'D001';

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Read - HR Manager
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForHRManager
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Manager'
  BEGIN
    THROW 51007, 'Forbidden: role mismatch for HR Manager employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForHRManager
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Manager'
  BEGIN
    THROW 51008, 'Forbidden: role mismatch for HR Manager employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Read - Finance
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForFinance
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Finance Staff'
  BEGIN
    THROW 51009, 'Forbidden: role mismatch for Finance employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.FullName ELSE NULL END AS FullName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.Gender ELSE NULL END AS Gender,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DateOfBirth ELSE NULL END AS DateOfBirth,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.PhoneNumber ELSE NULL END AS PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DepartmentID ELSE NULL END AS DepartmentID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN d.DepartmentName ELSE NULL END AS DepartmentName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.PositionID ELSE NULL END AS PositionID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.EmploymentStatus ELSE NULL END AS EmploymentStatus,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.IsActive ELSE NULL END AS IsActive,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.CreatedAt ELSE NULL END AS CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
  ORDER BY
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN 0 ELSE 1 END,
    e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForFinance
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Finance Staff'
  BEGIN
    THROW 51010, 'Forbidden: role mismatch for Finance employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.FullName ELSE NULL END AS FullName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.Gender ELSE NULL END AS Gender,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DateOfBirth ELSE NULL END AS DateOfBirth,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.PhoneNumber ELSE NULL END AS PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DepartmentID ELSE NULL END AS DepartmentID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN d.DepartmentName ELSE NULL END AS DepartmentName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.PositionID ELSE NULL END AS PositionID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.EmploymentStatus ELSE NULL END AS EmploymentStatus,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.IsActive ELSE NULL END AS IsActive,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.CreatedAt ELSE NULL END AS CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Read - Director
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_GetList_ForDirector
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 51011, 'Forbidden: role mismatch for Director employee-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.BaseSalaryEncrypted)) AS BaseSalary,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.SalaryCoefficientEncrypted)) AS SalaryCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.PositionCoefficientEncrypted)) AS PositionCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_GetById_ForDirector
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 51012, 'Forbidden: role mismatch for Director employee-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.Gender,
    e.DateOfBirth,
    e.PhoneNumber,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    e.EmploymentStatus,
    e.IsActive,
    e.CreatedAt,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.BaseSalaryEncrypted)) AS BaseSalary,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.SalaryCoefficientEncrypted)) AS SalaryCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.PositionCoefficientEncrypted)) AS PositionCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Employee Update Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Employee_UpdateProfile_ForEmployee
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10),
  @FullName NVARCHAR(100) = NULL,
  @Gender NVARCHAR(20) = NULL,
  @DateOfBirth DATE = NULL,
  @PhoneNumber VARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Employee'
  BEGIN
    THROW 51013, 'Forbidden: role mismatch for Employee profile-update procedure.', 1;
  END

  IF @RequesterEmployeeID <> @TargetEmployeeID
  BEGIN
    THROW 51014, 'Employee can update only own profile.', 1;
  END

  UPDATE Employee
  SET FullName = COALESCE(@FullName, FullName),
      Gender = COALESCE(@Gender, Gender),
      DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
      PhoneNumber = COALESCE(@PhoneNumber, PhoneNumber)
  WHERE EmployeeID = @TargetEmployeeID
    AND IsActive = 1;

  EXEC sp_Employee_GetById_ForEmployee
    @RequesterEmployeeID = @RequesterEmployeeID,
    @TargetEmployeeID = @TargetEmployeeID;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_UpdateProfile_ForHRStaff
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10),
  @FullName NVARCHAR(100) = NULL,
  @Gender NVARCHAR(20) = NULL,
  @DateOfBirth DATE = NULL,
  @PhoneNumber VARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Staff'
  BEGIN
    THROW 51015, 'Forbidden: role mismatch for HR Staff profile-update procedure.', 1;
  END

  IF NOT EXISTS
  (
    SELECT 1
    FROM Employee
    WHERE EmployeeID = @TargetEmployeeID
      AND IsActive = 1
      AND DepartmentID <> 'D001'
  )
  BEGIN
    THROW 51016, 'Target employee is outside HR Staff update scope.', 1;
  END

  UPDATE Employee
  SET FullName = COALESCE(@FullName, FullName),
      Gender = COALESCE(@Gender, Gender),
      DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
      PhoneNumber = COALESCE(@PhoneNumber, PhoneNumber)
  WHERE EmployeeID = @TargetEmployeeID
    AND IsActive = 1;

  EXEC sp_Employee_GetById_ForHRStaff
    @RequesterEmployeeID = @RequesterEmployeeID,
    @TargetEmployeeID = @TargetEmployeeID;
END
GO

CREATE OR ALTER PROCEDURE sp_Employee_UpdateProfile_ForHRManager
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10),
  @FullName NVARCHAR(100) = NULL,
  @Gender NVARCHAR(20) = NULL,
  @DateOfBirth DATE = NULL,
  @PhoneNumber VARCHAR(20) = NULL,
  @DepartmentID VARCHAR(10) = NULL,
  @PositionID INT = NULL,
  @EmploymentStatus NVARCHAR(50) = NULL,
  @IsActive BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'HR Manager'
  BEGIN
    THROW 51017, 'Forbidden: role mismatch for HR Manager profile-update procedure.', 1;
  END

  IF @DepartmentID IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
  BEGIN
    THROW 51018, 'Department not found.', 1;
  END

  IF @PositionID IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
  BEGIN
    THROW 51019, 'Position not found.', 1;
  END

  UPDATE Employee
  SET FullName = COALESCE(@FullName, FullName),
      Gender = COALESCE(@Gender, Gender),
      DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
      PhoneNumber = COALESCE(@PhoneNumber, PhoneNumber),
      DepartmentID = COALESCE(@DepartmentID, DepartmentID),
      PositionID = COALESCE(@PositionID, PositionID),
      EmploymentStatus = COALESCE(@EmploymentStatus, EmploymentStatus),
      IsActive = COALESCE(@IsActive, IsActive)
  WHERE EmployeeID = @TargetEmployeeID;

  EXEC sp_Employee_GetById_ForHRManager
    @RequesterEmployeeID = @RequesterEmployeeID,
    @TargetEmployeeID = @TargetEmployeeID;
END
GO

/* =========================================================
   Salary Read - Director
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Salary_GetList_ForDirector
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 51020, 'Forbidden: role mismatch for Director salary-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.BaseSalaryEncrypted)) AS BaseSalary,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.SalaryCoefficientEncrypted)) AS SalaryCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.PositionCoefficientEncrypted)) AS PositionCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary,
    cfg.FormulaVersion,
    cfg.ApprovedBy,
    cfg.UpdatedAt AS SalaryUpdatedAt,
    res.CalculatedAt AS SalaryCalculatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
  ORDER BY e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Salary_GetByEmployeeId_ForDirector
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 51021, 'Forbidden: role mismatch for Director salary-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    e.FullName,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.BaseSalaryEncrypted)) AS BaseSalary,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.SalaryCoefficientEncrypted)) AS SalaryCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.PositionCoefficientEncrypted)) AS PositionCoefficient,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary,
    cfg.FormulaVersion,
    cfg.ApprovedBy,
    cfg.UpdatedAt AS SalaryUpdatedAt,
    res.CalculatedAt AS SalaryCalculatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Salary Read - Finance
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Salary_GetList_ForFinance
  @RequesterEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Finance Staff'
  BEGIN
    THROW 51022, 'Forbidden: role mismatch for Finance salary-list procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.FullName ELSE NULL END AS FullName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DepartmentID ELSE NULL END AS DepartmentID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN d.DepartmentName ELSE NULL END AS DepartmentName,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary,
    cfg.FormulaVersion,
    cfg.UpdatedAt AS SalaryUpdatedAt,
    res.CalculatedAt AS SalaryCalculatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
  ORDER BY
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN 0 ELSE 1 END,
    e.EmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Salary_GetByEmployeeId_ForFinance
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @RequesterDepartmentID VARCHAR(10);

  SELECT
    @RequesterRole = Role,
    @RequesterDepartmentID = DepartmentID
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Finance Staff'
  BEGIN
    THROW 51023, 'Forbidden: role mismatch for Finance salary-detail procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT
    e.EmployeeID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.FullName ELSE NULL END AS FullName,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN e.DepartmentID ELSE NULL END AS DepartmentID,
    CASE WHEN e.DepartmentID = @RequesterDepartmentID THEN d.DepartmentName ELSE NULL END AS DepartmentName,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(e.TaxIDEncrypted)) AS TaxID,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
    CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary,
    cfg.FormulaVersion,
    cfg.UpdatedAt AS SalaryUpdatedAt,
    res.CalculatedAt AS SalaryCalculatedAt
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
  LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
  WHERE e.IsActive = 1
    AND e.EmployeeID = @TargetEmployeeID;

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

/* =========================================================
   Salary Update - Director
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Salary_Update_ForDirector
  @RequesterEmployeeID VARCHAR(10),
  @TargetEmployeeID VARCHAR(10),
  @BaseSalary DECIMAL(18,2),
  @SalaryCoefficient DECIMAL(10,2),
  @PositionCoefficient DECIMAL(10,2),
  @Allowance DECIMAL(18,2),
  @FormulaVersion NVARCHAR(50) = N'v1'
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @RequesterRole NVARCHAR(50);
  DECLARE @FinalSalary DECIMAL(18,2);
  DECLARE @OldValues NVARCHAR(MAX);
  DECLARE @NewValues NVARCHAR(MAX);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterEmployeeID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 51024, 'Forbidden: role mismatch for Director salary-update procedure.', 1;
  END

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  SELECT @OldValues =
  (
    SELECT
      e.EmployeeID,
      CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.BaseSalaryEncrypted)) AS BaseSalary,
      CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.SalaryCoefficientEncrypted)) AS SalaryCoefficient,
      CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.PositionCoefficientEncrypted)) AS PositionCoefficient,
      CONVERT(NVARCHAR(50), DECRYPTBYKEY(cfg.AllowanceEncrypted)) AS Allowance,
      CONVERT(NVARCHAR(50), DECRYPTBYKEY(res.FinalSalaryEncrypted)) AS FinalSalary,
      cfg.FormulaVersion
    FROM Employee e
    LEFT JOIN EmployeeSalaryConfig cfg ON cfg.EmployeeID = e.EmployeeID
    LEFT JOIN EmployeeSalaryResult res ON res.EmployeeID = e.EmployeeID
    WHERE e.EmployeeID = @TargetEmployeeID
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
  );

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;

  BEGIN TRANSACTION;

  EXEC sp_Salary_UpsertCore
    @TargetEmployeeID = @TargetEmployeeID,
    @ActorEmployeeID = @RequesterEmployeeID,
    @BaseSalary = @BaseSalary,
    @SalaryCoefficient = @SalaryCoefficient,
    @PositionCoefficient = @PositionCoefficient,
    @Allowance = @Allowance,
    @FormulaVersion = @FormulaVersion,
    @FinalSalary = @FinalSalary OUTPUT;

  SET @NewValues =
  (
    SELECT
      @TargetEmployeeID AS EmployeeID,
      CONVERT(NVARCHAR(50), @BaseSalary) AS BaseSalary,
      CONVERT(NVARCHAR(50), @SalaryCoefficient) AS SalaryCoefficient,
      CONVERT(NVARCHAR(50), @PositionCoefficient) AS PositionCoefficient,
      CONVERT(NVARCHAR(50), @Allowance) AS Allowance,
      CONVERT(NVARCHAR(50), @FinalSalary) AS FinalSalary,
      COALESCE(NULLIF(@FormulaVersion, N''), N'v1') AS FormulaVersion
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
  );

  EXEC sp_AuditLog_Create
    @ActorID = @RequesterEmployeeID,
    @ActorRole = @RequesterRole,
    @ActionType = N'UPDATE_SALARY',
    @TableName = N'EmployeeSalaryConfig',
    @RecordID = @TargetEmployeeID,
    @OldValues = @OldValues,
    @NewValues = @NewValues;

  COMMIT TRANSACTION;

  EXEC sp_Salary_GetByEmployeeId_ForDirector
    @RequesterEmployeeID = @RequesterEmployeeID,
    @TargetEmployeeID = @TargetEmployeeID;
END
GO

/* =========================================================
   Procedure Grants
   ========================================================= */
GRANT EXECUTE ON OBJECT::sp_Auth_GetAccountByUsername TO PUBLIC;
GRANT EXECUTE ON OBJECT::sp_Department_List TO PUBLIC;

GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForEmployee TO rl_employee;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForEmployee TO rl_employee;
GRANT EXECUTE ON OBJECT::sp_Employee_UpdateProfile_ForEmployee TO rl_employee;

GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForManager TO rl_manager;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForManager TO rl_manager;

GRANT EXECUTE ON OBJECT::sp_HRRequest_Create TO rl_hrstaff;
GRANT EXECUTE ON OBJECT::sp_HRRequest_ListByScope TO rl_hrstaff;
GRANT EXECUTE ON OBJECT::sp_HRRequest_GetByIdByScope TO rl_hrstaff;
GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForHRStaff TO rl_hrstaff;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForHRStaff TO rl_hrstaff;
GRANT EXECUTE ON OBJECT::sp_Employee_UpdateProfile_ForHRStaff TO rl_hrstaff;

GRANT EXECUTE ON OBJECT::sp_HRRequest_ListByScope TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_HRRequest_GetByIdByScope TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Department_Create TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Department_Update TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Department_Delete TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_AuditLog_List TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForHRManager TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForHRManager TO rl_hrmanager;
GRANT EXECUTE ON OBJECT::sp_Employee_UpdateProfile_ForHRManager TO rl_hrmanager;

GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForFinance TO rl_finance;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForFinance TO rl_finance;
GRANT EXECUTE ON OBJECT::sp_Salary_GetList_ForFinance TO rl_finance;
GRANT EXECUTE ON OBJECT::sp_Salary_GetByEmployeeId_ForFinance TO rl_finance;

GRANT EXECUTE ON OBJECT::sp_HRRequest_ListByScope TO rl_director;
GRANT EXECUTE ON OBJECT::sp_HRRequest_GetByIdByScope TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Approval_ListPending_ForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Approval_GetRequestForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Approval_ApproveCreateEmployee TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Approval_RejectRequest TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Department_Create TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Department_Update TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Department_Delete TO rl_director;
GRANT EXECUTE ON OBJECT::sp_AuditLog_List TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Employee_GetList_ForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Employee_GetById_ForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Salary_GetList_ForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Salary_GetByEmployeeId_ForDirector TO rl_director;
GRANT EXECUTE ON OBJECT::sp_Salary_Update_ForDirector TO rl_director;
GO

/* =========================================================
   Manual Verification Examples
   ========================================================= */
EXEC sp_Employee_GetList_ForDirector @RequesterEmployeeID = 'EM00001';
EXEC sp_Employee_GetList_ForHRManager @RequesterEmployeeID = 'EM00002';
EXEC sp_Employee_GetList_ForHRStaff @RequesterEmployeeID = 'EM00003';
EXEC sp_Employee_GetList_ForFinance @RequesterEmployeeID = 'EM00004';
EXEC sp_Employee_GetList_ForManager @RequesterEmployeeID = 'EM00005';
EXEC sp_Employee_GetList_ForEmployee @RequesterEmployeeID = 'EM00006';
GO
