/*
  HR Management Security System - Large Seed Data

  Purpose:
  - seed 50 departments
  - seed 400 employees/accounts distributed evenly across departments
  - seed encrypted salary config/result data
  - seed 30 HR requests and sample audit logs

  Run this file after:
  1. sql/init.sql

  Recommended order:
  1. sql/init.sql
  2. sql/seed.sql
  3. sql/rbac_employee_procs.sql

  Default password for all seeded accounts: 123456

  Important:
  - This seed intentionally inserts fixed business IDs for stable test data.
  - Runtime creation still uses backend-generated IDs through stored procedures.
*/

USE HRManagementSecuritySystem;
GO

SET NOCOUNT ON;
GO

/* =========================================================
   Base Positions
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Staff')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Staff', 1.00, N'General staff');
END;

IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Manager')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Manager', 1.50, N'Manager role');
END;

IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Director')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Director', 2.00, N'Director role');
END;
GO

/* =========================================================
   Department Seed: D001 -> D050
   - ManagerID is assigned after Employee seed because of FK.
   ========================================================= */
DECLARE @Departments TABLE
(
  DepartmentID VARCHAR(10) PRIMARY KEY,
  DepartmentName NVARCHAR(100) NOT NULL
);

INSERT INTO @Departments (DepartmentID, DepartmentName)
VALUES
  ('D001', N'Board Office'),
  ('D002', N'Human Resources'),
  ('D003', N'Finance'),
  ('D004', N'Engineering'),
  ('D005', N'Product'),
  ('D006', N'Sales'),
  ('D007', N'Marketing'),
  ('D008', N'Customer Success'),
  ('D009', N'Operations'),
  ('D010', N'Legal'),
  ('D011', N'Compliance'),
  ('D012', N'Security'),
  ('D013', N'Infrastructure'),
  ('D014', N'Data Platform'),
  ('D015', N'Business Intelligence'),
  ('D016', N'Research and Development'),
  ('D017', N'Quality Assurance'),
  ('D018', N'Training'),
  ('D019', N'Recruitment'),
  ('D020', N'Compensation and Benefits'),
  ('D021', N'Employee Relations'),
  ('D022', N'Internal Communications'),
  ('D023', N'Procurement'),
  ('D024', N'Administration'),
  ('D025', N'Facilities'),
  ('D026', N'IT Support'),
  ('D027', N'DevOps'),
  ('D028', N'Mobile Development'),
  ('D029', N'Web Development'),
  ('D030', N'Backend Services'),
  ('D031', N'Frontend Platform'),
  ('D032', N'Cloud Platform'),
  ('D033', N'Database Administration'),
  ('D034', N'Accounting'),
  ('D035', N'Treasury'),
  ('D036', N'Risk Management'),
  ('D037', N'Corporate Strategy'),
  ('D038', N'Partnerships'),
  ('D039', N'Client Services'),
  ('D040', N'Technical Support'),
  ('D041', N'Implementation'),
  ('D042', N'Solutions Architecture'),
  ('D043', N'Design'),
  ('D044', N'Content'),
  ('D045', N'Public Relations'),
  ('D046', N'Analytics'),
  ('D047', N'Innovation Lab'),
  ('D048', N'Regional Office North'),
  ('D049', N'Regional Office South'),
  ('D050', N'Regional Office Central');

UPDATE d
SET
  d.DepartmentName = src.DepartmentName,
  d.ManagerID = NULL
FROM Department d
INNER JOIN @Departments src ON src.DepartmentID = d.DepartmentID;

INSERT INTO Department (DepartmentID, DepartmentName, ManagerID)
SELECT src.DepartmentID, src.DepartmentName, NULL
FROM @Departments src
WHERE NOT EXISTS (
  SELECT 1
  FROM Department d
  WHERE d.DepartmentID = src.DepartmentID
);
GO

/* =========================================================
   Employee, Account and Salary Seed
   - 400 employees total
   - 50 departments
   - 8 employees per department
   - exactly 1 Director account
   ========================================================= */
DECLARE @StaffPositionID INT = (
  SELECT TOP 1 PositionID
  FROM Position
  WHERE PositionName = N'Staff'
  ORDER BY PositionID
);

DECLARE @ManagerPositionID INT = (
  SELECT TOP 1 PositionID
  FROM Position
  WHERE PositionName = N'Manager'
  ORDER BY PositionID
);

DECLARE @DirectorPositionID INT = (
  SELECT TOP 1 PositionID
  FROM Position
  WHERE PositionName = N'Director'
  ORDER BY PositionID
);

IF @StaffPositionID IS NULL OR @ManagerPositionID IS NULL OR @DirectorPositionID IS NULL
BEGIN
  THROW 51001, 'Base positions Staff/Manager/Director are not configured.', 1;
END;

OPEN SYMMETRIC KEY HRSystemSymmetricKey
DECRYPTION BY CERTIFICATE HRSystemCertificate;

DECLARE @Index INT = 1;

WHILE @Index <= 400
BEGIN
  DECLARE @EmployeeID VARCHAR(10) = 'EM' + RIGHT('00000' + CAST(@Index AS VARCHAR(10)), 5);
  DECLARE @DepartmentNumber INT = ((@Index - 1) / 8) + 1;
  DECLARE @DepartmentID VARCHAR(10) = 'D' + RIGHT('000' + CAST(@DepartmentNumber AS VARCHAR(10)), 3);
  DECLARE @OffsetInDepartment INT = ((@Index - 1) % 8) + 1;

  DECLARE @FullName NVARCHAR(100);
  DECLARE @Gender NVARCHAR(20) = CASE WHEN @Index % 2 = 0 THEN N'Female' ELSE N'Male' END;
  DECLARE @DateOfBirth DATE = DATEADD(DAY, -(@Index % 365), DATEFROMPARTS(1980 + (@Index % 22), ((@Index - 1) % 12) + 1, ((@Index - 1) % 27) + 1));
  DECLARE @PhoneNumber VARCHAR(20) = '09' + RIGHT('00000000' + CAST(1000000 + @Index AS VARCHAR(20)), 8);
  DECLARE @TaxID NVARCHAR(50) = RIGHT('000000000' + CAST(700000000 + @Index AS VARCHAR(20)), 9);
  DECLARE @PositionID INT = @StaffPositionID;
  DECLARE @Role NVARCHAR(50) = 'Employee';
  DECLARE @Username VARCHAR(50) = 'employee' + RIGHT('00000' + CAST(@Index AS VARCHAR(10)), 5);

  IF @Index = 1
  BEGIN
    SET @FullName = N'Director User';
    SET @PositionID = @DirectorPositionID;
    SET @Role = 'Director';
    SET @Username = 'director01';
  END
  ELSE IF @Index = 9
  BEGIN
    SET @FullName = N'HR Manager User';
    SET @PositionID = @ManagerPositionID;
    SET @Role = 'HR Manager';
    SET @Username = 'hrmanager01';
  END
  ELSE IF @Index BETWEEN 10 AND 13
  BEGIN
    SET @FullName = N'HR Staff User ' + RIGHT('00' + CAST(@Index - 9 AS VARCHAR(10)), 2);
    SET @PositionID = @StaffPositionID;
    SET @Role = 'HR Staff';
    SET @Username = 'hrstaff' + RIGHT('00' + CAST(@Index - 9 AS VARCHAR(10)), 2);
  END
  ELSE IF @Index BETWEEN 17 AND 20
  BEGIN
    SET @FullName = N'Finance Staff User ' + RIGHT('00' + CAST(@Index - 16 AS VARCHAR(10)), 2);
    SET @PositionID = CASE WHEN @Index = 17 THEN @ManagerPositionID ELSE @StaffPositionID END;
    SET @Role = 'Finance Staff';
    SET @Username = 'finance' + RIGHT('00' + CAST(@Index - 16 AS VARCHAR(10)), 2);
  END
  ELSE IF @OffsetInDepartment = 1
  BEGIN
    SET @FullName = N'Department Manager ' + RIGHT('000' + CAST(@DepartmentNumber AS VARCHAR(10)), 3);
    SET @PositionID = @ManagerPositionID;
    SET @Role = 'Manager';
    SET @Username = 'manager' + RIGHT('000' + CAST(@DepartmentNumber AS VARCHAR(10)), 3);
  END
  ELSE
  BEGIN
    SET @FullName = N'Employee ' + RIGHT('00000' + CAST(@Index AS VARCHAR(10)), 5);
  END;

  IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
  BEGIN
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
      DATEADD(DAY, -(@Index % 90), GETDATE())
    );
  END;

  IF NOT EXISTS (SELECT 1 FROM Account WHERE EmployeeID = @EmployeeID)
  BEGIN
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
      '$2b$10$D3SURxmd.kaF9n09jfB6lOzi.0B21ISpgOYb2k.W2dMDS2dKvTZTS',
      '$2b$10$D3SURxmd.kaF9n09jfB6lO',
      @Role,
      'ACTIVE',
      1,
      GETDATE()
    );
  END;

  DECLARE @BaseSalary DECIMAL(18,2) =
    CASE
      WHEN @Role = 'Director' THEN 30000000
      WHEN @Role = 'HR Manager' THEN 22000000
      WHEN @Role = 'Manager' THEN 18000000
      WHEN @Role = 'Finance Staff' THEN 14000000
      WHEN @Role = 'HR Staff' THEN 13000000
      ELSE 10000000 + ((@Index % 10) * 500000)
    END;

  DECLARE @SalaryCoefficient DECIMAL(10,2) =
    CASE
      WHEN @Role = 'Director' THEN 1.80
      WHEN @Role IN ('HR Manager', 'Manager') THEN 1.35
      WHEN @Role = 'Finance Staff' THEN 1.20
      WHEN @Role = 'HR Staff' THEN 1.15
      ELSE 1.00 + ((@Index % 5) * 0.05)
    END;

  DECLARE @PositionCoefficient DECIMAL(10,2) =
    CASE
      WHEN @PositionID = @DirectorPositionID THEN 2.00
      WHEN @PositionID = @ManagerPositionID THEN 1.50
      ELSE 1.00
    END;

  DECLARE @Allowance DECIMAL(18,2) =
    CASE
      WHEN @Role = 'Director' THEN 8000000
      WHEN @Role IN ('HR Manager', 'Manager') THEN 3000000
      WHEN @Role IN ('Finance Staff', 'HR Staff') THEN 1200000
      ELSE 500000 + ((@Index % 6) * 100000)
    END;

  DECLARE @FinalSalary DECIMAL(18,2) = (@BaseSalary * @SalaryCoefficient * @PositionCoefficient) + @Allowance;

  IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = @EmployeeID)
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
      @EmployeeID,
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @BaseSalary)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @SalaryCoefficient)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @PositionCoefficient)),
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @Allowance)),
      'EM00001',
      GETDATE(),
      N'v1'
    );
  END;

  IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = @EmployeeID)
  BEGIN
    INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
    VALUES
    (
      @EmployeeID,
      EncryptByKey(Key_GUID('HRSystemSymmetricKey'), CONVERT(NVARCHAR(255), @FinalSalary)),
      GETDATE()
    );
  END;

  SET @Index += 1;
END;

CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
GO

/* =========================================================
   Department Managers
   - one manager per department
   - special roles are preserved:
     D001 -> Director
     D002 -> HR Manager
     D003 -> Finance Staff
   ========================================================= */
DECLARE @DepartmentNumber INT = 1;

WHILE @DepartmentNumber <= 50
BEGIN
  DECLARE @DepartmentID VARCHAR(10) = 'D' + RIGHT('000' + CAST(@DepartmentNumber AS VARCHAR(10)), 3);
  DECLARE @ManagerEmployeeIndex INT = ((@DepartmentNumber - 1) * 8) + 1;
  DECLARE @ManagerID VARCHAR(10) = 'EM' + RIGHT('00000' + CAST(@ManagerEmployeeIndex AS VARCHAR(10)), 5);

  UPDATE Department
  SET ManagerID = @ManagerID
  WHERE DepartmentID = @DepartmentID;

  EXEC sp_Department_SyncManagerAssignment
    @NewManagerID = @ManagerID,
    @OldManagerID = NULL;

  SET @DepartmentNumber += 1;
END;
GO

/* =========================================================
   HR Request Seed: 30 requests
   - Requesters are valid HR users.
   - Payloads intentionally follow app/API request shapes.
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM HR_Request)
BEGIN
  DECLARE @StaffPositionID INT = (
    SELECT TOP 1 PositionID
    FROM Position
    WHERE PositionName = N'Staff'
    ORDER BY PositionID
  );

  IF @StaffPositionID IS NULL
  BEGIN
    THROW 51002, 'Staff position is not configured.', 1;
  END;

  DECLARE @RequestIndex INT = 1;

  WHILE @RequestIndex <= 30
  BEGIN
    DECLARE @RequestType VARCHAR(50);
    DECLARE @Status NVARCHAR(50);
    DECLARE @RequesterID VARCHAR(10) = CASE WHEN @RequestIndex % 2 = 0 THEN 'EM00009' ELSE 'EM00010' END;
    DECLARE @ApproverID VARCHAR(10) = NULL;
    DECLARE @ApprovedAt DATETIME = NULL;
    DECLARE @RejectionReason NVARCHAR(MAX) = NULL;
    DECLARE @Payload NVARCHAR(MAX);

    SET @Status =
      CASE @RequestIndex % 3
        WHEN 1 THEN 'PENDING'
        WHEN 2 THEN 'APPROVED'
        ELSE 'REJECTED'
      END;

    IF @Status IN ('APPROVED', 'REJECTED')
    BEGIN
      SET @ApproverID = 'EM00001';
      SET @ApprovedAt = DATEADD(DAY, -(@RequestIndex % 14), GETDATE());
    END;

    IF @Status = 'REJECTED'
    BEGIN
      SET @RejectionReason = N'Missing or invalid supporting documents';
    END;

    IF @RequestIndex % 3 = 1
    BEGIN
      SET @RequestType = 'CREATE_EMPLOYEE';
      SET @Payload = N'{' +
        N'"fullName":"Seed Request Candidate ' + RIGHT('00' + CAST(@RequestIndex AS NVARCHAR(10)), 2) + N'",' +
        N'"gender":"' + CASE WHEN @RequestIndex % 2 = 0 THEN N'Female' ELSE N'Male' END + N'",' +
        N'"dateOfBirth":"1998-05-' + RIGHT('00' + CAST(((@RequestIndex - 1) % 27) + 1 AS NVARCHAR(10)), 2) + N'",' +
        N'"phoneNumber":"0988' + RIGHT('000000' + CAST(@RequestIndex AS NVARCHAR(10)), 6) + N'",' +
        N'"taxId":"' + RIGHT('000000000' + CAST(800000000 + @RequestIndex AS NVARCHAR(20)), 9) + N'",' +
        N'"departmentId":"D' + RIGHT('000' + CAST(((@RequestIndex + 5) % 50) + 1 AS NVARCHAR(10)), 3) + N'",' +
        N'"positionId":' + CAST(@StaffPositionID AS NVARCHAR(10)) + N',' +
        N'"username":"candidate' + RIGHT('00' + CAST(@RequestIndex AS NVARCHAR(10)), 2) + N'",' +
        N'"password":"123456",' +
        N'"role":"Employee"' +
      N'}';
    END
    ELSE IF @RequestIndex % 3 = 2
    BEGIN
      SET @RequestType = 'UPDATE_EMPLOYEE';

      DECLARE @TargetUpdateEmployeeID VARCHAR(10) =
        'EM' + RIGHT('00000' + CAST(100 + @RequestIndex AS VARCHAR(10)), 5);

      SET @Payload = N'{' +
        N'"employeeId":"' + @TargetUpdateEmployeeID + N'",' +
        N'"fullName":"Updated Employee Sample ' + RIGHT('00' + CAST(@RequestIndex AS NVARCHAR(10)), 2) + N'",' +
        N'"gender":"' + CASE WHEN @RequestIndex % 2 = 0 THEN N'Female' ELSE N'Male' END + N'",' +
        N'"dateOfBirth":"1995-09-' + RIGHT('00' + CAST(((@RequestIndex - 1) % 27) + 1 AS NVARCHAR(10)), 2) + N'",' +
        N'"phoneNumber":"0977' + RIGHT('000000' + CAST(@RequestIndex AS NVARCHAR(10)), 6) + N'",' +
        N'"departmentId":"D' + RIGHT('000' + CAST(((@RequestIndex + 10) % 50) + 1 AS NVARCHAR(10)), 3) + N'",' +
        N'"positionId":' + CAST(@StaffPositionID AS NVARCHAR(10)) + N',' +
        N'"employmentStatus":"ACTIVE",' +
        N'"isActive":true' +
      N'}';
    END
    ELSE
    BEGIN
      SET @RequestType = 'DELETE_EMPLOYEE';

      DECLARE @TargetDeleteEmployeeID VARCHAR(10) =
        'EM' + RIGHT('00000' + CAST(250 + @RequestIndex AS VARCHAR(10)), 5);

      SET @Payload = N'{' +
        N'"employeeId":"' + @TargetDeleteEmployeeID + N'",' +
        N'"reason":"Seed delete request sample ' + RIGHT('00' + CAST(@RequestIndex AS NVARCHAR(10)), 2) + N'"' +
      N'}';
    END;

    INSERT INTO HR_Request
    (
      RequestType,
      Status,
      RequesterID,
      ApproverID,
      RequestPayload,
      CreatedAt,
      ApprovedAt,
      RejectionReason
    )
    VALUES
    (
      @RequestType,
      @Status,
      @RequesterID,
      @ApproverID,
      @Payload,
      DATEADD(HOUR, -@RequestIndex, GETDATE()),
      @ApprovedAt,
      @RejectionReason
    );

    SET @RequestIndex += 1;
  END;
END;
GO

/* =========================================================
   Audit Seed
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM Audit_Log)
BEGIN
  EXEC sp_AuditLog_Create
    @ActorID = 'EM00001',
    @ActorRole = 'Director',
    @ActionType = 'LOGIN_SUCCESS',
    @TableName = 'Account',
    @RecordID = 'EM00001',
    @OldValues = NULL,
    @NewValues = N'{"username":"director01"}';

  EXEC sp_AuditLog_Create
    @ActorID = 'EM00009',
    @ActorRole = 'HR Manager',
    @ActionType = 'VIEW_EMPLOYEE_LIST',
    @TableName = 'Employee',
    @RecordID = NULL,
    @OldValues = NULL,
    @NewValues = N'{"scope":"all"}';

  EXEC sp_AuditLog_Create
    @ActorID = 'EM00010',
    @ActorRole = 'HR Staff',
    @ActionType = 'CREATE_HR_REQUEST',
    @TableName = 'HR_Request',
    @RecordID = '1',
    @OldValues = NULL,
    @NewValues = N'{"status":"PENDING","requestType":"CREATE_EMPLOYEE"}';

  EXEC sp_AuditLog_Create
    @ActorID = 'EM00017',
    @ActorRole = 'Finance Staff',
    @ActionType = 'VIEW_PAYROLL',
    @TableName = 'EmployeeSalaryResult',
    @RecordID = NULL,
    @OldValues = NULL,
    @NewValues = N'{"scope":"finance"}';

  EXEC sp_AuditLog_Create
    @ActorID = 'EM00025',
    @ActorRole = 'Manager',
    @ActionType = 'VIEW_DEPARTMENT_EMPLOYEES',
    @TableName = 'Employee',
    @RecordID = 'D004',
    @OldValues = NULL,
    @NewValues = N'{"departmentId":"D004"}';
END;
GO

/* =========================================================
   Quick Verification Queries
   ========================================================= */
SELECT
  COUNT(*) AS DepartmentCount
FROM Department;

SELECT
  DepartmentID,
  COUNT(*) AS EmployeeCount
FROM Employee
GROUP BY DepartmentID
ORDER BY DepartmentID;

SELECT
  Role,
  COUNT(*) AS AccountCount
FROM Account
GROUP BY Role
ORDER BY Role;

SELECT
  COUNT(*) AS SalaryConfigCount
FROM EmployeeSalaryConfig;

SELECT
  COUNT(*) AS SalaryResultCount
FROM EmployeeSalaryResult;

SELECT
  RequestType,
  Status,
  COUNT(*) AS RequestCount
FROM HR_Request
GROUP BY RequestType, Status
ORDER BY RequestType, Status;

SELECT TOP 20
  Username,
  Role,
  EmployeeID
FROM Account
ORDER BY EmployeeID;
GO
