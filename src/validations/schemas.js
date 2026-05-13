import Joi from "joi";
import { ROLES } from "../constants/roles.js";
import { AppError } from "../utils/AppError.js";

export const validate = (schema, payload) => {
  const { error, value } = schema.validate(payload, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error) {
    throw new AppError(
      error.details.map((item) => item.message).join(", "),
      400,
    );
  }
  return value;
};

export const loginSchema = Joi.object({
  username: Joi.string().trim().required(),
  password: Joi.string().min(6).required(),
});

export const refreshSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

export const departmentCreateSchema = Joi.object({
  departmentId: Joi.string().required(),
  departmentName: Joi.string().trim().required(),
  managerId: Joi.string().allow(null, ""),
});

export const departmentUpdateSchema = Joi.object({
  departmentName: Joi.string().trim(),
  managerId: Joi.string().allow(null, ""),
}).min(1);

export const hrRequestCreateSchema = Joi.object({
  requestType: Joi.string()
    .valid("CREATE_EMPLOYEE", "UPDATE_EMPLOYEE", "DELETE_EMPLOYEE")
    .required(),

  payload: Joi.when("requestType", {
    switch: [
      {
        is: "CREATE_EMPLOYEE",
        then: Joi.object({
          fullName: Joi.string().trim().required(),
          gender: Joi.string().allow("", null),
          dateOfBirth: Joi.date().required(),
          phoneNumber: Joi.string().required(),
          taxId: Joi.string().required(),
          departmentId: Joi.string().required(),
          positionId: Joi.number().integer().required(),
          username: Joi.string().required(),
          password: Joi.string().min(6).required(),
          role: Joi.string()
            .valid(
              ROLES.EMPLOYEE,
              ROLES.MANAGER,
              ROLES.HR_STAFF,
              ROLES.HR_MANAGER,
              ROLES.FINANCE_STAFF,
            )
            .required(),
        }).required(),
      },
      {
        is: "UPDATE_EMPLOYEE",
        then: Joi.object({
          employeeId: Joi.string().required(),
          fullName: Joi.string().trim(),
          gender: Joi.string().allow("", null),
          dateOfBirth: Joi.date(),
          phoneNumber: Joi.string(),
          departmentId: Joi.string(),
          positionId: Joi.number().integer(),
          employmentStatus: Joi.string(),
          isActive: Joi.boolean(),
        })
          .min(2) // employeeId + at least 1 field
          .required(),
      },
      {
        is: "DELETE_EMPLOYEE",
        then: Joi.object({
          employeeId: Joi.string().required(),
          reason: Joi.string().trim().allow("", null),
        }).required(),
      },
    ],
    otherwise: Joi.forbidden(),
  }),
});

export const approvalApproveSchema = Joi.object({
  baseSalary: Joi.number().positive(),
  salaryCoefficient: Joi.number().positive(),
  positionCoefficient: Joi.number().positive(),
  allowance: Joi.number().min(0),
  formulaVersion: Joi.string().default("v1"),
});

export const approvalRejectSchema = Joi.object({
  rejectionReason: Joi.string().trim().required(),
});

export const employeeUpdateSchema = Joi.object({
  fullName: Joi.string(),
  gender: Joi.string().allow("", null),
  dateOfBirth: Joi.date(),
  phoneNumber: Joi.string(),
  departmentId: Joi.string(),
  positionId: Joi.number().integer(),
  employmentStatus: Joi.string(),
  isActive: Joi.boolean(),
}).min(1);

export const salaryUpdateSchema = Joi.object({
  baseSalary: Joi.number().positive().required(),
  salaryCoefficient: Joi.number().positive().required(),
  positionCoefficient: Joi.number().positive().required(),
  allowance: Joi.number().min(0).required(),
  formulaVersion: Joi.string().allow("", null).default("v1"),
});

export const auditQuerySchema = Joi.object({
  actorId: Joi.string(),
  actorRole: Joi.string(),
  actionType: Joi.string(),
  tableName: Joi.string(),
  startDate: Joi.date(),
  endDate: Joi.date(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});
