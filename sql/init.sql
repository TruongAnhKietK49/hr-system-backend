/*
  HR Management Security System - Database Initialization

  Purpose:
  - create database if needed
  - reset core tables
  - create encryption artifacts
  - create core helper, auth, department, request, approval and audit procedures

  Run this file first.
*/

SET NOCOUNT ON;
GO

IF DB_ID('HRManagementSecuritySystem') IS NULL
BEGIN
  CREATE DATABASE HRManagementSecuritySystem;
END
GO

USE HRManagementSecuritySystem;
GO

SET NOCOUNT ON;
GO

/* =========================================================
   Cleanup Legacy Programmable Objects
   ========================================================= */
DROP PROCEDURE IF EXISTS sp_Employee_ListByScope;
DROP PROCEDURE IF EXISTS sp_Employee_GetByIdScoped;
DROP PROCEDURE IF EXISTS sp_Employee_UpdateProfile;
DROP PROCEDURE IF EXISTS sp_Department_SyncManagerAssignment;
DROP PROCEDURE IF EXISTS sp_Finance_GetPayroll;
DROP PROCEDURE IF EXISTS sp_Finance_GetPayrollByEmployeeId;
DROP PROCEDURE IF EXISTS sp_Approval_ListPending;
DROP FUNCTION IF EXISTS fn_RequesterContext;
GO

/* =========================================================
   Drop Existing Tables
   ========================================================= */
IF OBJECT_ID('FK_Department_Manager', 'F') IS NOT NULL
BEGIN
  ALTER TABLE Department DROP CONSTRAINT FK_Department_Manager;
END

IF OBJECT_ID('FK_Employee_Department', 'F') IS NOT NULL
BEGIN
  ALTER TABLE Employee DROP CONSTRAINT FK_Employee_Department;
END

IF OBJECT_ID('FK_Employee_Position', 'F') IS NOT NULL
BEGIN
  ALTER TABLE Employee DROP CONSTRAINT FK_Employee_Position;
END

IF OBJECT_ID('Audit_Log', 'U') IS NOT NULL DROP TABLE Audit_Log;
IF OBJECT_ID('Account', 'U') IS NOT NULL DROP TABLE Account;
IF OBJECT_ID('EmployeeSalaryResult', 'U') IS NOT NULL DROP TABLE EmployeeSalaryResult;
IF OBJECT_ID('EmployeeSalaryConfig', 'U') IS NOT NULL DROP TABLE EmployeeSalaryConfig;
IF OBJECT_ID('HR_Request', 'U') IS NOT NULL DROP TABLE HR_Request;
IF OBJECT_ID('Employee', 'U') IS NOT NULL DROP TABLE Employee;
IF OBJECT_ID('Position', 'U') IS NOT NULL DROP TABLE Position;
IF OBJECT_ID('Department', 'U') IS NOT NULL DROP TABLE Department;
GO

/* =========================================================
   Core Tables
   ========================================================= */
CREATE TABLE Department (
  DepartmentID VARCHAR(10) PRIMARY KEY,
  DepartmentName NVARCHAR(100) NOT NULL,
  ManagerID VARCHAR(10) NULL
);
GO

CREATE TABLE Position (
  PositionID INT IDENTITY(1,1) PRIMARY KEY,
  PositionName NVARCHAR(100) NOT NULL,
  PositionCoefficientDefault DECIMAL(10,2) NOT NULL,
  Description NVARCHAR(255) NULL
);
GO

CREATE TABLE Employee (
  EmployeeID VARCHAR(10) PRIMARY KEY,
  FullName NVARCHAR(100) NOT NULL,
  Gender NVARCHAR(20) NULL,
  DateOfBirth DATE NULL,
  PhoneNumber VARCHAR(20) NULL,
  TaxIDEncrypted VARBINARY(MAX) NULL,
  DepartmentID VARCHAR(10) NOT NULL,
  PositionID INT NOT NULL,
  EmploymentStatus NVARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  IsActive BIT NOT NULL DEFAULT 1,
  CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

ALTER TABLE Department
ADD CONSTRAINT FK_Department_Manager FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeID);
GO

ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_Department FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID);
GO

ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_Position FOREIGN KEY (PositionID) REFERENCES Position(PositionID);
GO

CREATE TABLE EmployeeSalaryConfig (
  EmployeeID VARCHAR(10) PRIMARY KEY,
  BaseSalaryEncrypted VARBINARY(MAX) NOT NULL,
  SalaryCoefficientEncrypted VARBINARY(MAX) NOT NULL,
  PositionCoefficientEncrypted VARBINARY(MAX) NOT NULL,
  AllowanceEncrypted VARBINARY(MAX) NOT NULL,
  ApprovedBy VARCHAR(10) NOT NULL,
  UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  FormulaVersion NVARCHAR(50) NOT NULL DEFAULT 'v1',
  CONSTRAINT FK_EmployeeSalaryConfig_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);
GO

CREATE TABLE EmployeeSalaryResult (
  EmployeeID VARCHAR(10) PRIMARY KEY,
  FinalSalaryEncrypted VARBINARY(MAX) NOT NULL,
  CalculatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT FK_EmployeeSalaryResult_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);
GO

CREATE TABLE Account (
  EmployeeID VARCHAR(10) PRIMARY KEY,
  Username VARCHAR(50) NOT NULL UNIQUE,
  PasswordHash NVARCHAR(MAX) NOT NULL,
  PasswordSalt NVARCHAR(MAX) NOT NULL,
  Role NVARCHAR(50) NOT NULL,
  AccountStatus NVARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  IsActive BIT NOT NULL DEFAULT 1,
  CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  CONSTRAINT FK_Account_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);
GO

CREATE TABLE HR_Request (
  RequestID INT IDENTITY(1,1) PRIMARY KEY,
  RequestType VARCHAR(50) NOT NULL,
  Status NVARCHAR(50) NOT NULL,
  RequesterID VARCHAR(10) NOT NULL,
  ApproverID VARCHAR(10) NULL,
  RequestPayload NVARCHAR(MAX) NOT NULL,
  CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
  ApprovedAt DATETIME NULL,
  RejectionReason NVARCHAR(MAX) NULL,
  CONSTRAINT CK_HR_Request_Status CHECK (Status IN ('PENDING', 'APPROVED', 'REJECTED'))
);
GO

CREATE TABLE Audit_Log (
  LogID INT IDENTITY(1,1) PRIMARY KEY,
  ActorID VARCHAR(10) NULL,
  ActorRole NVARCHAR(50) NULL,
  ActionType NVARCHAR(50) NOT NULL,
  TableName NVARCHAR(50) NOT NULL,
  RecordID VARCHAR(50) NULL,
  OldValues NVARCHAR(MAX) NULL,
  NewValues NVARCHAR(MAX) NULL,
  Timestamp DATETIME NOT NULL DEFAULT GETDATE()
);
GO

/* =========================================================
   Encryption Setup
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Strong_Master_Key_Pass_2026!';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'HRSystemCertificate')
BEGIN
  CREATE CERTIFICATE HRSystemCertificate
  WITH SUBJECT = 'HR System Certificate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'HRSystemSymmetricKey')
BEGIN
  CREATE SYMMETRIC KEY HRSystemSymmetricKey
  WITH ALGORITHM = AES_256
  ENCRYPTION BY CERTIFICATE HRSystemCertificate;
END
GO

/* =========================================================
   Base Reference Data
   ========================================================= */
INSERT INTO Department (DepartmentID, DepartmentName)
SELECT 'D001', N'Human Resources'
WHERE NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = 'D001');

INSERT INTO Department (DepartmentID, DepartmentName)
SELECT 'D002', N'Finance'
WHERE NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = 'D002');

INSERT INTO Department (DepartmentID, DepartmentName)
SELECT 'D003', N'Engineering'
WHERE NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = 'D003');
GO

INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
SELECT N'Staff', 1.00, N'General staff'
WHERE NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Staff');

INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
SELECT N'Manager', 1.50, N'Manager role'
WHERE NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Manager');

INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
SELECT N'Director', 2.00, N'Director role'
WHERE NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Director');
GO

/* =========================================================
   Helper Function
   ========================================================= */
CREATE OR ALTER FUNCTION fn_RequesterContext
(
  @RequesterEmployeeID VARCHAR(10)
)
RETURNS TABLE
AS
RETURN
(
  SELECT
    a.EmployeeID,
    a.Role,
    e.DepartmentID
  FROM Account a
  INNER JOIN Employee e ON e.EmployeeID = a.EmployeeID
  WHERE a.EmployeeID = @RequesterEmployeeID
    AND a.IsActive = 1
    AND a.AccountStatus = 'ACTIVE'
    AND e.IsActive = 1
);
GO

/* =========================================================
   Audit Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_AuditLog_Create
  @ActorID VARCHAR(10) = NULL,
  @ActorRole NVARCHAR(50) = NULL,
  @ActionType NVARCHAR(50),
  @TableName NVARCHAR(50),
  @RecordID VARCHAR(50) = NULL,
  @OldValues NVARCHAR(MAX) = NULL,
  @NewValues NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO Audit_Log
  (
    ActorID,
    ActorRole,
    ActionType,
    TableName,
    RecordID,
    OldValues,
    NewValues,
    Timestamp
  )
  VALUES
  (
    @ActorID,
    @ActorRole,
    @ActionType,
    @TableName,
    @RecordID,
    @OldValues,
    @NewValues,
    GETDATE()
  );
END
GO

CREATE OR ALTER PROCEDURE sp_AuditLog_List
  @ActorID VARCHAR(10) = NULL,
  @ActorRole NVARCHAR(50) = NULL,
  @ActionType NVARCHAR(50) = NULL,
  @TableName NVARCHAR(50) = NULL,
  @StartDate DATETIME = NULL,
  @EndDate DATETIME = NULL,
  @Page INT = 1,
  @Limit INT = 20
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    LogID,
    ActorID,
    ActorRole,
    ActionType,
    TableName,
    RecordID,
    OldValues,
    NewValues,
    Timestamp
  FROM Audit_Log
  WHERE (@ActorID IS NULL OR ActorID = @ActorID)
    AND (@ActorRole IS NULL OR ActorRole = @ActorRole)
    AND (@ActionType IS NULL OR ActionType = @ActionType)
    AND (@TableName IS NULL OR TableName = @TableName)
    AND (@StartDate IS NULL OR Timestamp >= @StartDate)
    AND (@EndDate IS NULL OR Timestamp <= @EndDate)
  ORDER BY Timestamp DESC
  OFFSET ((@Page - 1) * @Limit) ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

/* =========================================================
   Auth Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Auth_GetAccountByUsername
  @Username VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    a.EmployeeID,
    a.Username,
    a.PasswordHash,
    a.PasswordSalt,
    a.Role,
    a.AccountStatus,
    a.IsActive,
    e.FullName,
    e.DepartmentID
  FROM Account a
  INNER JOIN Employee e ON e.EmployeeID = a.EmployeeID
  WHERE a.Username = @Username;
END
GO

/* =========================================================
   Department Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Department_List
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    DepartmentID,
    DepartmentName,
    ManagerID
  FROM Department
  ORDER BY DepartmentName ASC;
END
GO

CREATE OR ALTER PROCEDURE sp_Department_SyncManagerAssignment
  @NewManagerID VARCHAR(10) = NULL,
  @OldManagerID VARCHAR(10) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @StaffPositionID INT;
  DECLARE @ManagerPositionID INT;

  SELECT @StaffPositionID = PositionID
  FROM Position
  WHERE PositionName = N'Staff';

  SELECT @ManagerPositionID = PositionID
  FROM Position
  WHERE PositionName = N'Manager';

  IF @StaffPositionID IS NULL OR @ManagerPositionID IS NULL
  BEGIN
    THROW 50005, 'Base positions Staff/Manager are not configured.', 1;
  END

  -- Người mới được bổ nhiệm làm trưởng ít nhất một phòng:
  -- chỉ nâng chức vụ Staff -> Manager, không đụng Director/chức vụ đặc biệt.
  IF @NewManagerID IS NOT NULL
  BEGIN
    UPDATE Employee
    SET PositionID = @ManagerPositionID
    WHERE EmployeeID = @NewManagerID
      AND IsActive = 1
      AND PositionID = @StaffPositionID;

    -- Chỉ nâng quyền account thường. Không ghi đè HR Staff/HR Manager/Finance Staff/Director.
    UPDATE Account
    SET Role = 'Manager'
    WHERE EmployeeID = @NewManagerID
      AND Role = 'Employee'
      AND IsActive = 1
      AND AccountStatus = 'ACTIVE';
  END

  -- Người cũ bị gỡ khỏi phòng hiện tại:
  -- chỉ hạ nếu họ không còn quản lý bất kỳ phòng ban nào khác.
  IF @OldManagerID IS NOT NULL
    AND (@NewManagerID IS NULL OR @OldManagerID <> @NewManagerID)
    AND NOT EXISTS (
      SELECT 1
      FROM Department
      WHERE ManagerID = @OldManagerID
    )
  BEGIN
    UPDATE Employee
    SET PositionID = @StaffPositionID
    WHERE EmployeeID = @OldManagerID
      AND IsActive = 1
      AND PositionID = @ManagerPositionID;

    UPDATE Account
    SET Role = 'Employee'
    WHERE EmployeeID = @OldManagerID
      AND Role = 'Manager'
      AND IsActive = 1
      AND AccountStatus = 'ACTIVE';
  END
END
GO

CREATE OR ALTER PROCEDURE sp_Department_Create
  @DepartmentID VARCHAR(10),
  @DepartmentName NVARCHAR(100),
  @ManagerID VARCHAR(10) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
  BEGIN
    THROW 50001, 'Department already exists.', 1;
  END

  IF @ManagerID IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM Employee
      WHERE EmployeeID = @ManagerID
        AND IsActive = 1
    )
  BEGIN
    THROW 50002, 'Manager candidate not found or inactive.', 1;
  END

  BEGIN TRANSACTION;

  BEGIN TRY
    INSERT INTO Department (DepartmentID, DepartmentName, ManagerID)
    VALUES (@DepartmentID, @DepartmentName, @ManagerID);

    EXEC sp_Department_SyncManagerAssignment
      @NewManagerID = @ManagerID,
      @OldManagerID = NULL;

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
      ROLLBACK TRANSACTION;

    THROW;
  END CATCH

  SELECT
    DepartmentID,
    DepartmentName,
    ManagerID
  FROM Department
  WHERE DepartmentID = @DepartmentID;
END
GO

CREATE OR ALTER PROCEDURE sp_Department_Update
  @DepartmentID VARCHAR(10),
  @DepartmentName NVARCHAR(100) = NULL,
  @ManagerID VARCHAR(10) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @OldManagerID VARCHAR(10);

  IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
  BEGIN
    SELECT TOP 0 DepartmentID, DepartmentName, ManagerID
    FROM Department;
    RETURN;
  END

  SELECT @OldManagerID = ManagerID
  FROM Department
  WHERE DepartmentID = @DepartmentID;

  IF @ManagerID IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM Employee
      WHERE EmployeeID = @ManagerID
        AND IsActive = 1
    )
  BEGIN
    THROW 50003, 'Manager candidate not found or inactive.', 1;
  END

  BEGIN TRANSACTION;

  BEGIN TRY
    UPDATE Department
    SET DepartmentName = COALESCE(@DepartmentName, DepartmentName),
        ManagerID = @ManagerID
    WHERE DepartmentID = @DepartmentID;

    EXEC sp_Department_SyncManagerAssignment
      @NewManagerID = @ManagerID,
      @OldManagerID = @OldManagerID;

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
      ROLLBACK TRANSACTION;

    THROW;
  END CATCH

  SELECT
    DepartmentID,
    DepartmentName,
    ManagerID
  FROM Department
  WHERE DepartmentID = @DepartmentID;
END
GO

CREATE OR ALTER PROCEDURE sp_Department_Delete
  @DepartmentID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @OldManagerID VARCHAR(10);

  IF EXISTS (
    SELECT 1
    FROM Employee
    WHERE DepartmentID = @DepartmentID
      AND IsActive = 1
  )
  BEGIN
    THROW 50004, 'Cannot delete department with active employees.', 1;
  END

  SELECT @OldManagerID = ManagerID
  FROM Department
  WHERE DepartmentID = @DepartmentID;

  BEGIN TRANSACTION;

  BEGIN TRY
    DELETE FROM Department
    WHERE DepartmentID = @DepartmentID;

    EXEC sp_Department_SyncManagerAssignment
      @NewManagerID = NULL,
      @OldManagerID = @OldManagerID;

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
      ROLLBACK TRANSACTION;

    THROW;
  END CATCH
END
GO

/* =========================================================
   Salary Core Helper
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Salary_UpsertCore
  @TargetEmployeeID VARCHAR(10),
  @ActorEmployeeID VARCHAR(10),
  @BaseSalary DECIMAL(18,2),
  @SalaryCoefficient DECIMAL(10,2),
  @PositionCoefficient DECIMAL(10,2),
  @Allowance DECIMAL(18,2),
  @FormulaVersion NVARCHAR(50),
  @FinalSalary DECIMAL(18,2) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @TargetEmployeeID AND IsActive = 1)
  BEGIN
    THROW 50005, 'Target employee not found or inactive.', 1;
  END

  IF @BaseSalary <= 0 OR @SalaryCoefficient <= 0 OR @PositionCoefficient <= 0 OR @Allowance < 0
  BEGIN
    THROW 50006, 'Invalid salary input.', 1;
  END

  SET @FinalSalary = (@BaseSalary * @SalaryCoefficient * @PositionCoefficient) + @Allowance;

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  IF EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = @TargetEmployeeID)
  BEGIN
    UPDATE EmployeeSalaryConfig
    SET BaseSalaryEncrypted = EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @BaseSalary)),
        SalaryCoefficientEncrypted = EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @SalaryCoefficient)),
        PositionCoefficientEncrypted = EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @PositionCoefficient)),
        AllowanceEncrypted = EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @Allowance)),
        ApprovedBy = @ActorEmployeeID,
        UpdatedAt = GETDATE(),
        FormulaVersion = COALESCE(NULLIF(@FormulaVersion, N''), FormulaVersion)
    WHERE EmployeeID = @TargetEmployeeID;
  END
  ELSE
  BEGIN
    INSERT INTO EmployeeSalaryConfig
    (
      EmployeeID,
      BaseSalaryEncrypted,
      SalaryCoefficientEncrypted,
      PositionCoefficientEncrypted,
      AllowanceEncrypted,
      ApprovedBy,
      UpdatedAt,
      FormulaVersion
    )
    VALUES
    (
      @TargetEmployeeID,
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @BaseSalary)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @SalaryCoefficient)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @PositionCoefficient)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @Allowance)),
      @ActorEmployeeID,
      GETDATE(),
      COALESCE(NULLIF(@FormulaVersion, N''), N'v1')
    );
  END

  IF EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = @TargetEmployeeID)
  BEGIN
    UPDATE EmployeeSalaryResult
    SET FinalSalaryEncrypted = EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @FinalSalary)),
        CalculatedAt = GETDATE()
    WHERE EmployeeID = @TargetEmployeeID;
  END
  ELSE
  BEGIN
    INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
    VALUES
    (
      @TargetEmployeeID,
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @FinalSalary)),
      GETDATE()
    );
  END

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
END
GO

CREATE OR ALTER PROCEDURE sp_Department_SearchManagerCandidates
  @Keyword NVARCHAR(100) = NULL,
  @Limit INT = 20
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SafeLimit INT = CASE
    WHEN @Limit IS NULL OR @Limit < 1 THEN 20
    WHEN @Limit > 50 THEN 50
    ELSE @Limit
  END;

  DECLARE @NormalizedKeyword NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@Keyword)), N'');

  SELECT TOP (@SafeLimit)
    e.EmployeeID,
    e.FullName,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    p.PositionName,
    e.IsActive,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM Department managedDepartment
        WHERE managedDepartment.ManagerID = e.EmployeeID
      ) THEN CAST(1 AS BIT)
      ELSE CAST(0 AS BIT)
    END AS IsManagingDepartment
  FROM Employee e
  INNER JOIN Department d ON d.DepartmentID = e.DepartmentID
  INNER JOIN Position p ON p.PositionID = e.PositionID
  WHERE e.IsActive = 1
    AND (
      @NormalizedKeyword IS NULL
      OR e.EmployeeID LIKE '%' + @NormalizedKeyword + '%'
      OR e.FullName LIKE N'%' + @NormalizedKeyword + N'%'
      OR d.DepartmentName LIKE N'%' + @NormalizedKeyword + N'%'
    )
  ORDER BY
    CASE
      WHEN @NormalizedKeyword IS NOT NULL AND e.EmployeeID = @NormalizedKeyword THEN 0
      WHEN @NormalizedKeyword IS NOT NULL AND e.FullName LIKE @NormalizedKeyword + N'%' THEN 1
      ELSE 2
    END,
    e.FullName ASC,
    e.EmployeeID ASC;
END
GO

/* =========================================================
   HR Request Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_HRRequest_Create
  @RequestType VARCHAR(50),
  @RequesterID VARCHAR(10),
  @RequestPayload NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterID);

  IF @RequesterRole NOT IN ('HR Staff', 'HR Manager')
  BEGIN
    THROW 52001, 'Only HR Staff or HR Manager can create HR requests.', 1;
  END

  IF @RequestType NOT IN ('CREATE_EMPLOYEE', 'UPDATE_EMPLOYEE', 'DELETE_EMPLOYEE')
  BEGIN
  THROW 50008, 'Unsupported request type.', 1;
  END

  INSERT INTO HR_Request (RequestType, Status, RequesterID, RequestPayload, CreatedAt)
  VALUES (@RequestType, 'PENDING', @RequesterID, @RequestPayload, GETDATE());

  SELECT
    RequestID,
    RequestType,
    Status,
    RequesterID,
    ApproverID,
    CASE
      WHEN ISJSON(RequestPayload) = 1 THEN JSON_MODIFY(RequestPayload, '$.password', NULL)
      ELSE RequestPayload
    END AS RequestPayload,
    CreatedAt,
    ApprovedAt,
    RejectionReason
  FROM HR_Request
  WHERE RequestID = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE sp_HRRequest_ListByScope
  @RequesterID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterID);

  IF @RequesterRole NOT IN ('HR Staff', 'HR Manager', 'Director')
  BEGIN
    THROW 50009, 'Forbidden.', 1;
  END

  SELECT
    RequestID,
    RequestType,
    Status,
    RequesterID,
    ApproverID,
    CASE
      WHEN ISJSON(RequestPayload) = 1 THEN JSON_MODIFY(RequestPayload, '$.password', NULL)
      ELSE RequestPayload
    END AS RequestPayload,
    CreatedAt,
    ApprovedAt,
    RejectionReason
  FROM HR_Request
  WHERE @RequesterRole IN ('HR Manager', 'Director')
     OR RequesterID = @RequesterID
  ORDER BY CreatedAt DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_HRRequest_GetByIdByScope
  @RequesterID VARCHAR(10),
  @RequestID INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterID);

  IF @RequesterRole NOT IN ('HR Staff', 'HR Manager', 'Director')
  BEGIN
    THROW 50010, 'Forbidden.', 1;
  END

  SELECT
    RequestID,
    RequestType,
    Status,
    RequesterID,
    ApproverID,
    CASE
      WHEN ISJSON(RequestPayload) = 1 THEN JSON_MODIFY(RequestPayload, '$.password', NULL)
      ELSE RequestPayload
    END AS RequestPayload,
    CreatedAt,
    ApprovedAt,
    RejectionReason
  FROM HR_Request
  WHERE RequestID = @RequestID
    AND (
      @RequesterRole IN ('HR Manager', 'Director')
      OR RequesterID = @RequesterID
    );
END
GO

/* =========================================================
   Approval Procedures
   ========================================================= */
CREATE OR ALTER PROCEDURE sp_Approval_ListPending_ForDirector
  @RequesterID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 50011, 'Only Director can access pending approvals.', 1;
  END

  SELECT
    RequestID,
    RequestType,
    Status,
    RequesterID,
    ApproverID,
    CASE
      WHEN ISJSON(RequestPayload) = 1 THEN JSON_MODIFY(RequestPayload, '$.password', NULL)
      ELSE RequestPayload
    END AS RequestPayload,
    CreatedAt,
    ApprovedAt,
    RejectionReason
  FROM HR_Request
  WHERE Status = 'PENDING'
  ORDER BY CreatedAt ASC;
END
GO

CREATE OR ALTER PROCEDURE sp_Approval_GetRequestForDirector
  @RequesterID VARCHAR(10),
  @RequestID INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@RequesterID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 50012, 'Only Director can access approval request payload.', 1;
  END

  SELECT
    RequestID,
    RequestType,
    Status,
    RequesterID,
    ApproverID,
    RequestPayload,
    CreatedAt,
    ApprovedAt,
    RejectionReason
  FROM HR_Request
  WHERE RequestID = @RequestID;
END
GO

CREATE OR ALTER PROCEDURE sp_Approval_RejectRequest
  @RequestID INT,
  @ApproverID VARCHAR(10),
  @RejectionReason NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @RequesterRole NVARCHAR(50);

  SELECT @RequesterRole = Role
  FROM fn_RequesterContext(@ApproverID);

  IF @RequesterRole <> 'Director'
  BEGIN
    THROW 50013, 'Only Director can reject requests.', 1;
  END

  IF NOT EXISTS (SELECT 1 FROM HR_Request WHERE RequestID = @RequestID AND Status = 'PENDING')
  BEGIN
    THROW 50014, 'Request not found or not pending.', 1;
  END

  UPDATE HR_Request
  SET Status = 'REJECTED',
      ApproverID = @ApproverID,
      ApprovedAt = GETDATE(),
      RejectionReason = @RejectionReason
  WHERE RequestID = @RequestID;
END
GO

CREATE OR ALTER PROCEDURE sp_Approval_ApproveCreateEmployee
  @RequestID INT,
  @ApproverID VARCHAR(10),
  @BaseSalary DECIMAL(18,2),
  @SalaryCoefficient DECIMAL(10,2),
  @PositionCoefficient DECIMAL(10,2),
  @Allowance DECIMAL(18,2),
  @FormulaVersion NVARCHAR(50),
  @PasswordHash NVARCHAR(MAX),
  @PasswordSalt NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @ApproverRole NVARCHAR(50);
  DECLARE @RequestPayload NVARCHAR(MAX);
  DECLARE @EmployeeID VARCHAR(10);
  DECLARE @NextID INT;
  DECLARE @FinalSalary DECIMAL(18,2);
  DECLARE @FullName NVARCHAR(100);
  DECLARE @Gender NVARCHAR(20);
  DECLARE @DateOfBirth DATE;
  DECLARE @PhoneNumber VARCHAR(20);
  DECLARE @TaxID NVARCHAR(50);
  DECLARE @DepartmentID VARCHAR(10);
  DECLARE @PositionID INT;
  DECLARE @Username VARCHAR(50);
  DECLARE @Role NVARCHAR(50);

  SELECT @ApproverRole = Role
  FROM fn_RequesterContext(@ApproverID);

  IF @ApproverRole <> 'Director'
  BEGIN
    THROW 50015, 'Only Director can approve requests.', 1;
  END

  IF NOT EXISTS (SELECT 1 FROM HR_Request WHERE RequestID = @RequestID AND Status = 'PENDING')
  BEGIN
    THROW 50016, 'Request not found or not pending.', 1;
  END

  SELECT @RequestPayload = RequestPayload
  FROM HR_Request
  WHERE RequestID = @RequestID;

  SELECT
    @FullName = JSON_VALUE(@RequestPayload, '$.fullName'),
    @Gender = JSON_VALUE(@RequestPayload, '$.gender'),
    @DateOfBirth = TRY_CAST(JSON_VALUE(@RequestPayload, '$.dateOfBirth') AS DATE),
    @PhoneNumber = JSON_VALUE(@RequestPayload, '$.phoneNumber'),
    @TaxID = JSON_VALUE(@RequestPayload, '$.taxId'),
    @DepartmentID = JSON_VALUE(@RequestPayload, '$.departmentId'),
    @PositionID = TRY_CAST(JSON_VALUE(@RequestPayload, '$.positionId') AS INT),
    @Username = JSON_VALUE(@RequestPayload, '$.username'),
    @Role = JSON_VALUE(@RequestPayload, '$.role');

  IF @FullName IS NULL
    OR @PhoneNumber IS NULL
    OR @TaxID IS NULL
    OR @DepartmentID IS NULL
    OR @PositionID IS NULL
    OR @Username IS NULL
    OR @Role IS NULL
  BEGIN
    THROW 50017, 'Request payload is invalid.', 1;
  END

  IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
  BEGIN
    THROW 50018, 'Department not found.', 1;
  END

  IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
  BEGIN
    THROW 50019, 'Position not found.', 1;
  END

  IF EXISTS (SELECT 1 FROM Account WHERE Username = @Username)
  BEGIN
    THROW 50020, 'Username already exists.', 1;
  END

  BEGIN TRANSACTION;

  SELECT @NextID = ISNULL(MAX(CAST(SUBSTRING(EmployeeID, 3, 10) AS INT)), 0) + 1
  FROM Employee
  WHERE EmployeeID LIKE 'EM%';

  SET @EmployeeID = 'EM' + RIGHT('00000' + CAST(@NextID AS VARCHAR(10)), 5);

  OPEN SYMMETRIC KEY HRSystemSymmetricKey
  DECRYPTION BY CERTIFICATE HRSystemCertificate;

  INSERT INTO Employee
  (
    EmployeeID,
    FullName,
    Gender,
    DateOfBirth,
    PhoneNumber,
    TaxIDEncrypted,
    DepartmentID,
    PositionID,
    EmploymentStatus,
    IsActive,
    CreatedAt
  )
  VALUES
  (
    @EmployeeID,
    @FullName,
    @Gender,
    @DateOfBirth,
    @PhoneNumber,
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), @TaxID),
    @DepartmentID,
    @PositionID,
    'ACTIVE',
    1,
    GETDATE()
  );

  CLOSE SYMMETRIC KEY HRSystemSymmetricKey;

  INSERT INTO Account
  (
    EmployeeID,
    Username,
    PasswordHash,
    PasswordSalt,
    Role,
    AccountStatus,
    IsActive,
    CreatedAt
  )
  VALUES
  (
    @EmployeeID,
    @Username,
    @PasswordHash,
    @PasswordSalt,
    @Role,
    'ACTIVE',
    1,
    GETDATE()
  );

  EXEC sp_Salary_UpsertCore
    @TargetEmployeeID = @EmployeeID,
    @ActorEmployeeID = @ApproverID,
    @BaseSalary = @BaseSalary,
    @SalaryCoefficient = @SalaryCoefficient,
    @PositionCoefficient = @PositionCoefficient,
    @Allowance = @Allowance,
    @FormulaVersion = @FormulaVersion,
    @FinalSalary = @FinalSalary OUTPUT;

  UPDATE HR_Request
  SET Status = 'APPROVED',
      ApproverID = @ApproverID,
      ApprovedAt = GETDATE(),
      RejectionReason = NULL
  WHERE RequestID = @RequestID;

  COMMIT TRANSACTION;

  SELECT
    @EmployeeID AS EmployeeID,
    @Username AS Username,
    @Role AS Role,
    @DepartmentID AS DepartmentID,
    @FinalSalary AS FinalSalary;
END
GO

CREATE OR ALTER PROCEDURE sp_Approval_ApproveUpdateEmployee
  @RequestID INT,
  @ApproverID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @ApproverRole NVARCHAR(50);
  DECLARE @RequestPayload NVARCHAR(MAX);
  DECLARE @EmployeeID VARCHAR(10);
  DECLARE @FullName NVARCHAR(100);
  DECLARE @Gender NVARCHAR(20);
  DECLARE @DateOfBirth DATE;
  DECLARE @PhoneNumber VARCHAR(20);
  DECLARE @DepartmentID VARCHAR(10);
  DECLARE @PositionID INT;
  DECLARE @EmploymentStatus NVARCHAR(50);
  DECLARE @IsActive BIT;

  SELECT @ApproverRole = Role
  FROM fn_RequesterContext(@ApproverID);

  IF @ApproverRole <> 'Director'
  BEGIN
    THROW 50021, 'Only Director can approve update employee requests.', 1;
  END

  IF NOT EXISTS (
    SELECT 1
    FROM HR_Request
    WHERE RequestID = @RequestID
      AND Status = 'PENDING'
      AND RequestType = 'UPDATE_EMPLOYEE'
  )
  BEGIN
    THROW 50022, 'Update employee request not found or not pending.', 1;
  END

  SELECT @RequestPayload = RequestPayload
  FROM HR_Request
  WHERE RequestID = @RequestID;

  SELECT
    @EmployeeID = JSON_VALUE(@RequestPayload, '$.employeeId'),
    @FullName = JSON_VALUE(@RequestPayload, '$.fullName'),
    @Gender = JSON_VALUE(@RequestPayload, '$.gender'),
    @DateOfBirth = TRY_CAST(JSON_VALUE(@RequestPayload, '$.dateOfBirth') AS DATE),
    @PhoneNumber = JSON_VALUE(@RequestPayload, '$.phoneNumber'),
    @DepartmentID = JSON_VALUE(@RequestPayload, '$.departmentId'),
    @PositionID = TRY_CAST(JSON_VALUE(@RequestPayload, '$.positionId') AS INT),
    @EmploymentStatus = JSON_VALUE(@RequestPayload, '$.employmentStatus'),
    @IsActive =
      CASE
        WHEN JSON_VALUE(@RequestPayload, '$.isActive') IS NULL THEN NULL
        WHEN JSON_VALUE(@RequestPayload, '$.isActive') IN ('true', '1') THEN 1
        WHEN JSON_VALUE(@RequestPayload, '$.isActive') IN ('false', '0') THEN 0
        ELSE NULL
      END;

  IF @EmployeeID IS NULL
  BEGIN
    THROW 50023, 'EmployeeID is required.', 1;
  END

  IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
  BEGIN
    THROW 50024, 'Employee not found.', 1;
  END

  IF @DepartmentID IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
  BEGIN
    THROW 50025, 'Department not found.', 1;
  END

  IF @PositionID IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
  BEGIN
    THROW 50026, 'Position not found.', 1;
  END

  BEGIN TRANSACTION;

  UPDATE Employee
  SET
    FullName = COALESCE(@FullName, FullName),
    Gender = CASE
      WHEN JSON_VALUE(@RequestPayload, '$.gender') IS NULL THEN Gender
      ELSE @Gender
    END,
    DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
    PhoneNumber = COALESCE(@PhoneNumber, PhoneNumber),
    DepartmentID = COALESCE(@DepartmentID, DepartmentID),
    PositionID = COALESCE(@PositionID, PositionID),
    EmploymentStatus = COALESCE(@EmploymentStatus, EmploymentStatus),
    IsActive = COALESCE(@IsActive, IsActive)
  WHERE EmployeeID = @EmployeeID;

  IF @IsActive = 0
  BEGIN
    UPDATE Account
    SET IsActive = 0,
        AccountStatus = 'INACTIVE'
    WHERE EmployeeID = @EmployeeID;
  END

  UPDATE HR_Request
  SET Status = 'APPROVED',
      ApproverID = @ApproverID,
      ApprovedAt = GETDATE(),
      RejectionReason = NULL
  WHERE RequestID = @RequestID;

  COMMIT TRANSACTION;

  SELECT
    @RequestID AS RequestID,
    'UPDATE_EMPLOYEE' AS RequestType,
    'APPROVED' AS Status,
    @EmployeeID AS EmployeeID;
END
GO

CREATE OR ALTER PROCEDURE sp_Approval_ApproveDeleteEmployee
  @RequestID INT,
  @ApproverID VARCHAR(10)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @ApproverRole NVARCHAR(50);
  DECLARE @RequestPayload NVARCHAR(MAX);
  DECLARE @EmployeeID VARCHAR(10);

  SELECT @ApproverRole = Role
  FROM fn_RequesterContext(@ApproverID);

  IF @ApproverRole <> 'Director'
  BEGIN
    THROW 50027, 'Only Director can approve delete employee requests.', 1;
  END

  IF NOT EXISTS (
    SELECT 1
    FROM HR_Request
    WHERE RequestID = @RequestID
      AND Status = 'PENDING'
      AND RequestType = 'DELETE_EMPLOYEE'
  )
  BEGIN
    THROW 50028, 'Delete employee request not found or not pending.', 1;
  END

  SELECT @RequestPayload = RequestPayload
  FROM HR_Request
  WHERE RequestID = @RequestID;

  SELECT @EmployeeID = JSON_VALUE(@RequestPayload, '$.employeeId');

  IF @EmployeeID IS NULL
  BEGIN
    THROW 50029, 'EmployeeID is required.', 1;
  END

  IF @EmployeeID = @ApproverID
  BEGIN
    THROW 50030, 'Director cannot delete own account.', 1;
  END

  IF NOT EXISTS (
    SELECT 1
    FROM Employee
    WHERE EmployeeID = @EmployeeID
      AND IsActive = 1
  )
  BEGIN
    THROW 50031, 'Employee not found or already inactive.', 1;
  END

  BEGIN TRANSACTION;

  UPDATE Department
  SET ManagerID = NULL
  WHERE ManagerID = @EmployeeID;

  UPDATE Account
  SET IsActive = 0,
      AccountStatus = 'INACTIVE'
  WHERE EmployeeID = @EmployeeID;

  UPDATE Employee
  SET IsActive = 0,
      EmploymentStatus = 'TERMINATED'
  WHERE EmployeeID = @EmployeeID;

  UPDATE HR_Request
  SET Status = 'APPROVED',
      ApproverID = @ApproverID,
      ApprovedAt = GETDATE(),
      RejectionReason = NULL
  WHERE RequestID = @RequestID;

  COMMIT TRANSACTION;

  SELECT
    @RequestID AS RequestID,
    'DELETE_EMPLOYEE' AS RequestType,
    'APPROVED' AS Status,
    @EmployeeID AS EmployeeID;
END
GO