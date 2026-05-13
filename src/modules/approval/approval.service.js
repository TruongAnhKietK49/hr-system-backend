import { ROLES } from "../../constants/roles.js";
import { ACTION_TYPES } from "../../constants/actionTypes.js";
import { AppError } from "../../utils/AppError.js";
import { generateHashAndSalt } from "../../utils/password.js";
import { approvalRepository } from "./approval.repository.js";
import { auditRepository } from "../audit/audit.repository.js";

const REQUEST_TYPES = {
  CREATE_EMPLOYEE: "CREATE_EMPLOYEE",
  UPDATE_EMPLOYEE: "UPDATE_EMPLOYEE",
  DELETE_EMPLOYEE: "DELETE_EMPLOYEE",
};

class ApprovalService {
  async getPending(user) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError("Only Director can access pending approvals", 403);
    }

    return approvalRepository.findPendingRequests(user.employeeId);
  }

  async approve(user, requestId, payload) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError("Only Director can approve request", 403);
    }

    const numericRequestId = Number(requestId);

    const hrRequest = await approvalRepository.findRequestForDirector({
      requesterId: user.employeeId,
      requestId: numericRequestId,
    });

    if (!hrRequest) {
      throw new AppError("HR request not found", 404);
    }

    if (hrRequest.Status !== "PENDING") {
      throw new AppError("HR request is not pending", 400);
    }

    switch (hrRequest.RequestType) {
      case REQUEST_TYPES.CREATE_EMPLOYEE:
        return this.approveCreateEmployee(
          user,
          numericRequestId,
          hrRequest,
          payload,
        );

      case REQUEST_TYPES.UPDATE_EMPLOYEE:
        return this.approveUpdateEmployee(user, numericRequestId, hrRequest);

      case REQUEST_TYPES.DELETE_EMPLOYEE:
        return this.approveDeleteEmployee(user, numericRequestId, hrRequest);

      default:
        throw new AppError("Unsupported request type", 400);
    }
  }

  async approveCreateEmployee(user, requestId, hrRequest, payload) {
    this.validateCreateEmployeeApprovalPayload(payload);

    const requestPayload = JSON.parse(hrRequest.RequestPayload);
    const { hash, salt } = await generateHashAndSalt(requestPayload.password);

    const result = await approvalRepository.approveCreateEmployee({
      requestId,
      approverId: user.employeeId,
      baseSalary: payload.baseSalary,
      salaryCoefficient: payload.salaryCoefficient,
      positionCoefficient: payload.positionCoefficient,
      allowance: payload.allowance,
      formulaVersion: payload.formulaVersion || "v1",
      passwordHash: hash,
      passwordSalt: salt,
    });

    await this.createApprovalAuditLog({
      user,
      requestId,
      result,
      newValues: {
        status: "APPROVED",
        requestType: REQUEST_TYPES.CREATE_EMPLOYEE,
        employeeId: result?.EmployeeID,
        finalSalary: result?.FinalSalary,
      },
    });

    return result;
  }

  async approveUpdateEmployee(user, requestId, hrRequest) {
    const result = await approvalRepository.approveUpdateEmployee({
      requestId,
      approverId: user.employeeId,
    });

    await this.createApprovalAuditLog({
      user,
      requestId,
      result,
      newValues: {
        status: "APPROVED",
        requestType: REQUEST_TYPES.UPDATE_EMPLOYEE,
        employeeId: result?.EmployeeID,
      },
    });

    return result;
  }

  async approveDeleteEmployee(user, requestId, hrRequest) {
    const result = await approvalRepository.approveDeleteEmployee({
      requestId,
      approverId: user.employeeId,
    });

    await this.createApprovalAuditLog({
      user,
      requestId,
      result,
      newValues: {
        status: "APPROVED",
        requestType: REQUEST_TYPES.DELETE_EMPLOYEE,
        employeeId: result?.EmployeeID,
      },
    });

    return result;
  }

  async reject(user, requestId, payload) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError("Only Director can reject request", 403);
    }

    await approvalRepository.rejectRequest({
      requestId: Number(requestId),
      approverId: user.employeeId,
      rejectionReason: payload.rejectionReason,
    });

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.REJECT_HR_REQUEST,
      tableName: "HR_Request",
      recordId: String(requestId),
      oldValues: JSON.stringify({ status: "PENDING" }),
      newValues: JSON.stringify({
        status: "REJECTED",
        rejectionReason: payload.rejectionReason,
      }),
    });

    return {
      requestId: Number(requestId),
      status: "REJECTED",
    };
  }

  validateCreateEmployeeApprovalPayload(payload) {
    const requiredFields = [
      "baseSalary",
      "salaryCoefficient",
      "positionCoefficient",
      "allowance",
    ];

    const missingFields = requiredFields.filter(
      (field) => payload[field] === undefined || payload[field] === null,
    );

    if (missingFields.length > 0) {
      throw new AppError(
        `Missing salary approval fields: ${missingFields.join(", ")}`,
        400,
      );
    }
  }

  async createApprovalAuditLog({ user, requestId, newValues }) {
    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.APPROVE_HR_REQUEST,
      tableName: "HR_Request",
      recordId: String(requestId),
      oldValues: JSON.stringify({ status: "PENDING" }),
      newValues: JSON.stringify(newValues),
    });
  }
}

export const approvalService = new ApprovalService();
