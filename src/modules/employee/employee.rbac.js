import { StatusCodes } from "http-status-codes";
import { ROLES } from "../../constants/roles.js";
import { AppError } from "../../utils/AppError.js";

const EMPLOYEE_LIST_PROCEDURES_BY_ROLE = {
  [ROLES.EMPLOYEE]: "sp_Employee_GetList_ForEmployee",
  [ROLES.MANAGER]: "sp_Employee_GetList_ForManager",
  [ROLES.HR_STAFF]: "sp_Employee_GetList_ForHRStaff",
  [ROLES.HR_MANAGER]: "sp_Employee_GetList_ForHRManager",
  [ROLES.FINANCE_STAFF]: "sp_Employee_GetList_ForFinance",
  [ROLES.DIRECTOR]: "sp_Employee_GetList_ForDirector",
};

const EMPLOYEE_DETAIL_PROCEDURES_BY_ROLE = {
  [ROLES.EMPLOYEE]: "sp_Employee_GetById_ForEmployee",
  [ROLES.MANAGER]: "sp_Employee_GetById_ForManager",
  [ROLES.HR_STAFF]: "sp_Employee_GetById_ForHRStaff",
  [ROLES.HR_MANAGER]: "sp_Employee_GetById_ForHRManager",
  [ROLES.FINANCE_STAFF]: "sp_Employee_GetById_ForFinance",
  [ROLES.DIRECTOR]: "sp_Employee_GetById_ForDirector",
};

const EMPLOYEE_VISIBLE_FIELDS_BY_ROLE = {
  [ROLES.EMPLOYEE]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
  ],
  [ROLES.MANAGER]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
    "Allowance",
    "FinalSalary",
  ],
  [ROLES.HR_STAFF]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
  ],
  [ROLES.HR_MANAGER]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
  ],
  [ROLES.FINANCE_STAFF]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
    "Allowance",
    "FinalSalary",
  ],
  [ROLES.DIRECTOR]: [
    "EmployeeID",
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "TaxID",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "EmploymentStatus",
    "IsActive",
    "CreatedAt",
    "BaseSalary",
    "SalaryCoefficient",
    "PositionCoefficient",
    "Allowance",
    "FinalSalary",
  ],
};

const EMPLOYEE_UPDATABLE_FIELDS_BY_ROLE = {
  [ROLES.HR_STAFF]: ["fullName", "gender", "dateOfBirth", "phoneNumber"],
  [ROLES.HR_MANAGER]: [
    "fullName",
    "gender",
    "dateOfBirth",
    "phoneNumber",
    "departmentId",
    "positionId",
    "employmentStatus",
    "isActive",
  ],
};

const EMPLOYEE_UPDATE_PROCEDURES_BY_ROLE = {
  [ROLES.HR_STAFF]: "sp_Employee_UpdateProfile_ForHRStaff",
  [ROLES.HR_MANAGER]: "sp_Employee_UpdateProfile_ForHRManager",
};

export const resolveEmployeeListProcedure = (role) => {
  const procedureName = EMPLOYEE_LIST_PROCEDURES_BY_ROLE[role];

  if (!procedureName) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  return procedureName;
};

export const resolveEmployeeDetailProcedure = (role) => {
  const procedureName = EMPLOYEE_DETAIL_PROCEDURES_BY_ROLE[role];

  if (!procedureName) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  return procedureName;
};

export const presentEmployeeRecord = (role, record) => {
  const allowedFields = EMPLOYEE_VISIBLE_FIELDS_BY_ROLE[role];

  if (!allowedFields) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  return allowedFields.reduce((result, field) => {
    if (Object.prototype.hasOwnProperty.call(record, field)) {
      result[field] = record[field];
    }

    return result;
  }, {});
};

export const presentEmployeeList = (role, records = []) => {
  return records.map((record) => presentEmployeeRecord(role, record));
};

export const sanitizeEmployeeUpdatePayload = (role, payload) => {
  const allowedFields = EMPLOYEE_UPDATABLE_FIELDS_BY_ROLE[role];

  if (!allowedFields) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  const sanitizedPayload = allowedFields.reduce((result, field) => {
    if (Object.prototype.hasOwnProperty.call(payload, field)) {
      result[field] = payload[field];
    }

    return result;
  }, {});

  if (Object.keys(sanitizedPayload).length === 0) {
    throw new AppError("No allowed fields to update", StatusCodes.BAD_REQUEST);
  }

  return sanitizedPayload;
};

export const resolveEmployeeUpdateProcedure = (role) => {
  const procedureName = EMPLOYEE_UPDATE_PROCEDURES_BY_ROLE[role];

  if (!procedureName) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  return procedureName;
};

export const sanitizeOwnProfileUpdatePayload = (payload) => {
  const allowedFields = ["fullName", "gender", "dateOfBirth", "phoneNumber"];

  const sanitizedPayload = allowedFields.reduce((result, field) => {
    if (Object.prototype.hasOwnProperty.call(payload, field)) {
      result[field] = payload[field];
    }

    return result;
  }, {});

  if (Object.keys(sanitizedPayload).length === 0) {
    throw new AppError("No allowed fields to update", StatusCodes.BAD_REQUEST);
  }

  return sanitizedPayload;
};
