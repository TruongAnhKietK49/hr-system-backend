import { StatusCodes } from "http-status-codes";
import { ROLES } from "../../constants/roles.js";
import { AppError } from "../../utils/AppError.js";

const SALARY_LIST_PROCEDURES_BY_ROLE = {
  [ROLES.FINANCE_STAFF]: "sp_Salary_GetList_ForFinance",
  [ROLES.DIRECTOR]: "sp_Salary_GetList_ForDirector",
};

const SALARY_DETAIL_PROCEDURES_BY_ROLE = {
  [ROLES.FINANCE_STAFF]: "sp_Salary_GetByEmployeeId_ForFinance",
  [ROLES.DIRECTOR]: "sp_Salary_GetByEmployeeId_ForDirector",
};

const SALARY_UPDATE_PROCEDURES_BY_ROLE = {
  [ROLES.DIRECTOR]: "sp_Salary_Update_ForDirector",
};

const SALARY_VISIBLE_FIELDS_BY_ROLE = {
  [ROLES.FINANCE_STAFF]: [
    "EmployeeID",

    // Same-department profile fields.
    // These fields are NULL from SQL when the employee is outside Finance Staff's department.
    "FullName",
    "Gender",
    "DateOfBirth",
    "PhoneNumber",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "PositionName",

    // Same-department salary config fields.
    // These fields are NULL from SQL when the employee is outside Finance Staff's department.
    "BaseSalary",
    "SalaryCoefficient",
    "PositionCoefficient",

    // Fields Finance Staff can see for all employees.
    "TaxID",
    "Allowance",
    "FinalSalary",

    "FormulaVersion",
    "SalaryUpdatedAt",
    "SalaryCalculatedAt",
  ],
  [ROLES.DIRECTOR]: [
    "EmployeeID",
    "FullName",
    "DepartmentID",
    "DepartmentName",
    "PositionID",
    "TaxID",
    "BaseSalary",
    "SalaryCoefficient",
    "PositionCoefficient",
    "Allowance",
    "FinalSalary",
    "FormulaVersion",
    "ApprovedBy",
    "SalaryUpdatedAt",
    "SalaryCalculatedAt",
  ],
};

const resolveProcedure = (map, role) => {
  const procedureName = map[role];

  if (!procedureName) {
    throw new AppError("Forbidden", StatusCodes.FORBIDDEN);
  }

  return procedureName;
};

export const resolveSalaryListProcedure = (role) =>
  resolveProcedure(SALARY_LIST_PROCEDURES_BY_ROLE, role);
export const resolveSalaryDetailProcedure = (role) =>
  resolveProcedure(SALARY_DETAIL_PROCEDURES_BY_ROLE, role);
export const resolveSalaryUpdateProcedure = (role) =>
  resolveProcedure(SALARY_UPDATE_PROCEDURES_BY_ROLE, role);

export const presentSalaryRecord = (role, record) => {
  const allowedFields = SALARY_VISIBLE_FIELDS_BY_ROLE[role];

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

export const presentSalaryList = (role, records = []) =>
  records.map((record) => presentSalaryRecord(role, record));
