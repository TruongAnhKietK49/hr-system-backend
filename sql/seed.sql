/*
  HR Management Security System - Seed Data

  Purpose:
  - seed departments, employees and accounts for all main roles
  - seed salary config/result data for payroll and salary tests
  - seed sample HR requests and audit logs

  Run this file after sql/init.sql.
*/

USE HRManagementSecuritySystem;
GO

SET NOCOUNT ON;
GO

/* =========================================================
   Extra Departments and Base Positions
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = 'D004')
BEGIN
  INSERT INTO Department (DepartmentID, DepartmentName, ManagerID)
  VALUES ('D004', N'Board Office', NULL);
END
GO

IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Staff')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Staff', 1.00, N'General staff');
END

IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Manager')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Manager', 1.50, N'Manager role');
END

IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionName = N'Director')
BEGIN
  INSERT INTO Position (PositionName, PositionCoefficientDefault, Description)
  VALUES (N'Director', 2.00, N'Director role');
END
GO

/* =========================================================
   Employee Seed
   ========================================================= */
DECLARE @StaffPositionID INT = (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Staff' ORDER BY PositionID);
DECLARE @ManagerPositionID INT = (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Manager' ORDER BY PositionID);
DECLARE @DirectorPositionID INT = (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Director' ORDER BY PositionID);
GO

OPEN SYMMETRIC KEY HRSystemSymmetricKey
DECRYPTION BY CERTIFICATE HRSystemCertificate;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00001')
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
    'EM00001',
    N'Director User',
    N'Male',
    '1980-01-10',
    '0901000001',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'111111111'),
    'D004',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Director' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00002')
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
    'EM00002',
    N'HR Manager User',
    N'Female',
    '1988-05-15',
    '0901000002',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'222222222'),
    'D001',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Manager' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00003')
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
    'EM00003',
    N'HR Staff User',
    N'Female',
    '1992-07-20',
    '0901000003',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'333333333'),
    'D001',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Staff' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00004')
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
    'EM00004',
    N'Finance Staff User',
    N'Male',
    '1991-03-12',
    '0901000004',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'444444444'),
    'D002',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Staff' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00005')
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
    'EM00005',
    N'Engineering Manager User',
    N'Male',
    '1989-09-09',
    '0901000005',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'555555555'),
    'D003',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Manager' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = 'EM00006')
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
    'EM00006',
    N'Employee User',
    N'Female',
    '1998-11-25',
    '0901000006',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'666666666'),
    'D003',
    (SELECT TOP 1 PositionID FROM Position WHERE PositionName = N'Staff' ORDER BY PositionID),
    'ACTIVE',
    1,
    GETDATE()
  );
END;

/* Salary seed for all role users */
IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00001')
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
    'EM00001',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'30000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.80'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'2.00'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'8000000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00001')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00001', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'116000000'), GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00002')
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
    'EM00002',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'22000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.35'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.50'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'2500000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00002')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00002', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'47050000'), GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00003')
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
    'EM00003',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'11000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.05'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.00'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'800000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00003')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00003', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'12350000'), GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00004')
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
    'EM00004',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'12000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.20'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.00'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1000000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00004')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00004', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'15400000'), GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00005')
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
    'EM00005',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'18000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.40'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.50'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'3000000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00005')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00005', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'40800000'), GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryConfig WHERE EmployeeID = 'EM00006')
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
    'EM00006',
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'10000000'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.10'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'1.00'),
    EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'500000'),
    'EM00001',
    GETDATE(),
    N'v1'
  );
END;

IF NOT EXISTS (SELECT 1 FROM EmployeeSalaryResult WHERE EmployeeID = 'EM00006')
BEGIN
  INSERT INTO EmployeeSalaryResult (EmployeeID, FinalSalaryEncrypted, CalculatedAt)
  VALUES ('EM00006', EncryptByKey(Key_GUID('HRSystemSymmetricKey'), N'11500000'), GETDATE());
END;

CLOSE SYMMETRIC KEY HRSystemSymmetricKey;
GO

/* =========================================================
   Department Managers
   ========================================================= */
UPDATE Department SET ManagerID = 'EM00002' WHERE DepartmentID = 'D001';
UPDATE Department SET ManagerID = 'EM00004' WHERE DepartmentID = 'D002';
UPDATE Department SET ManagerID = 'EM00005' WHERE DepartmentID = 'D003';
UPDATE Department SET ManagerID = 'EM00001' WHERE DepartmentID = 'D004';
GO

/* =========================================================
   Account Seed
   Password for all accounts: 123456
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'director01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00001',
    'director01',
    '$2b$10$D3SURxmd.kaF9n09jfB6lOzi.0B21ISpgOYb2k.W2dMDS2dKvTZTS',
    '$2b$10$D3SURxmd.kaF9n09jfB6lO',
    'Director',
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'hrmanager01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00002',
    'hrmanager01',
    '$2b$10$BOQYCmaxYdhzi83i3ZIzB.QtZPQOTDsMCUIatoqQIhG8Y3VYU0j6e',
    '$2b$10$BOQYCmaxYdhzi83i3ZIzB.',
    'HR Manager',
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'hrstaff01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00003',
    'hrstaff01',
    '$2b$10$XSuXpRpsmsMzkpGiQtcHROowJ1MW.jfbXmyTTfee8IO7L2SXMq0Si',
    '$2b$10$XSuXpRpsmsMzkpGiQtcHRO',
    'HR Staff',
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'finance01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00004',
    'finance01',
    '$2b$10$HfG9WruN1vLkMftsvgwoZOfZNCGHwL5OCnO8rpwEdEYg9lVvo.VQ2',
    '$2b$10$HfG9WruN1vLkMftsvgwoZO',
    'Finance Staff',
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'manager01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00005',
    'manager01',
    '$2b$10$FAqTldZeP4.EeQh9v3/ThOd.5HzMZqf2q9vkqf.lZc02EIrjSfj0K',
    '$2b$10$FAqTldZeP4.EeQh9v3/ThO',
    'Manager',
    'ACTIVE',
    1,
    GETDATE()
  );
END;

IF NOT EXISTS (SELECT 1 FROM Account WHERE Username = 'employee01')
BEGIN
  INSERT INTO Account (EmployeeID, Username, PasswordHash, PasswordSalt, Role, AccountStatus, IsActive, CreatedAt)
  VALUES
  (
    'EM00006',
    'employee01',
    '$2b$10$VztxOup0OsscDT.zHMvvXusjwn9GGf/xxS0.xtw6FcU4XqRl3GpFu',
    '$2b$10$VztxOup0OsscDT.zHMvvXu',
    'Employee',
    'ACTIVE',
    1,
    GETDATE()
  );
END;
GO

/* =========================================================
   Post-seed Department Manager Consistency
   - keep PositionID/Account.Role aligned with Department.ManagerID
   - special account roles are preserved by sp_Department_SyncManagerAssignment
   ========================================================= */
DECLARE @SeedManagerID VARCHAR(10);

DECLARE seed_manager_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT ManagerID
FROM Department
WHERE ManagerID IS NOT NULL;

OPEN seed_manager_cursor;
FETCH NEXT FROM seed_manager_cursor INTO @SeedManagerID;

WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC sp_Department_SyncManagerAssignment
    @NewManagerID = @SeedManagerID,
    @OldManagerID = NULL;

  FETCH NEXT FROM seed_manager_cursor INTO @SeedManagerID;
END;

CLOSE seed_manager_cursor;
DEALLOCATE seed_manager_cursor;
GO

/* =========================================================
   HR Request Seed
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM HR_Request WHERE RequestID = 1)
BEGIN
  SET IDENTITY_INSERT HR_Request ON;

  INSERT INTO HR_Request
  (
    RequestID,
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
    1,
    'CREATE_EMPLOYEE',
    'PENDING',
    'EM00003',
    NULL,
    N'{
      "fullName":"Pending Employee User",
      "gender":"Male",
      "dateOfBirth":"2000-04-10",
      "phoneNumber":"0901999991",
      "taxId":"777777777",
      "departmentId":"D003",
      "positionId":1,
      "username":"pendingemp01",
      "password":"123456",
      "role":"Employee"
    }',
    GETDATE(),
    NULL,
    NULL
  );

  INSERT INTO HR_Request
  (
    RequestID,
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
    2,
    'CREATE_EMPLOYEE',
    'APPROVED',
    'EM00003',
    'EM00001',
    N'{
      "fullName":"Approved Request Sample",
      "gender":"Female",
      "dateOfBirth":"1999-06-01",
      "phoneNumber":"0901999992",
      "taxId":"888888888",
      "departmentId":"D002",
      "positionId":1,
      "username":"approvedsample01",
      "password":"123456",
      "role":"Employee"
    }',
    DATEADD(DAY, -2, GETDATE()),
    DATEADD(DAY, -2, GETDATE()),
    NULL
  );

  INSERT INTO HR_Request
  (
    RequestID,
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
    3,
    'CREATE_EMPLOYEE',
    'REJECTED',
    'EM00003',
    'EM00001',
    N'{
      "fullName":"Rejected Request Sample",
      "gender":"Female",
      "dateOfBirth":"1997-12-12",
      "phoneNumber":"0901999993",
      "taxId":"999999999",
      "departmentId":"D001",
      "positionId":1,
      "username":"rejectedsample01",
      "password":"123456",
      "role":"Employee"
    }',
    DATEADD(DAY, -1, GETDATE()),
    DATEADD(DAY, -1, GETDATE()),
    N'Missing supporting documents'
  );

  SET IDENTITY_INSERT HR_Request OFF;
END;
GO

/* =========================================================
   Audit Seed
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM Audit_Log WHERE ActionType = 'LOGIN_SUCCESS' AND RecordID = 'EM00001')
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
    @ActorID = 'EM00003',
    @ActorRole = 'HR Staff',
    @ActionType = 'CREATE_HR_REQUEST',
    @TableName = 'HR_Request',
    @RecordID = '1',
    @OldValues = NULL,
    @NewValues = N'{"status":"PENDING","requestType":"CREATE_EMPLOYEE"}';

  EXEC sp_AuditLog_Create
    @ActorID = 'EM00001',
    @ActorRole = 'Director',
    @ActionType = 'APPROVE_HR_REQUEST',
    @TableName = 'HR_Request',
    @RecordID = '2',
    @OldValues = N'{"status":"PENDING"}',
    @NewValues = N'{"status":"APPROVED"}';
END;
GO

/* =========================================================
   Quick Verification Queries
   ========================================================= */
SELECT Username, Role, EmployeeID
FROM Account
ORDER BY Username;

SELECT RequestID, Status, RequesterID, ApproverID
FROM HR_Request
ORDER BY RequestID;

SELECT EmployeeID, FullName, DepartmentID
FROM Employee
ORDER BY EmployeeID;
