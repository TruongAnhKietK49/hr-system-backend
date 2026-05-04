import { ROLES } from '../../constants/roles.js';
import { ACTION_TYPES } from '../../constants/actionTypes.js';
import { AppError } from '../../utils/AppError.js';
import { generateHashAndSalt } from '../../utils/password.js';
import { approvalRepository } from './approval.repository.js';
import { auditRepository } from '../audit/audit.repository.js';

class ApprovalService {
  async getPending(user) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError('Only Director can access pending approvals', 403);
    }
    return approvalRepository.findPendingRequests(user.employeeId);
  }

  async approve(user, requestId, payload) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError('Only Director can approve request', 403);
    }

    const hrRequest = await approvalRepository.findRequestForDirector({
      requesterId: user.employeeId,
      requestId: Number(requestId)
    });
    if (!hrRequest) {
      throw new AppError('HR request not found', 404);
    }

    const requestPayload = JSON.parse(hrRequest.RequestPayload);
    const { hash, salt } = await generateHashAndSalt(requestPayload.password);

    const result = await approvalRepository.approveRequest({
      requestId: Number(requestId),
      approverId: user.employeeId,
      baseSalary: payload.baseSalary,
      salaryCoefficient: payload.salaryCoefficient,
      positionCoefficient: payload.positionCoefficient,
      allowance: payload.allowance,
      formulaVersion: payload.formulaVersion,
      passwordHash: hash,
      passwordSalt: salt
    });

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.APPROVE_HR_REQUEST,
      tableName: 'HR_Request',
      recordId: String(requestId),
      oldValues: JSON.stringify({ status: 'PENDING' }),
      newValues: JSON.stringify({
        status: 'APPROVED',
        employeeId: result?.EmployeeID,
        finalSalary: result?.FinalSalary
      })
    });

    return result;
  }

  async reject(user, requestId, payload) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError('Only Director can reject request', 403);
    }

    await approvalRepository.rejectRequest({
      requestId: Number(requestId),
      approverId: user.employeeId,
      rejectionReason: payload.rejectionReason
    });

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.REJECT_HR_REQUEST,
      tableName: 'HR_Request',
      recordId: String(requestId),
      oldValues: JSON.stringify({ status: 'PENDING' }),
      newValues: JSON.stringify({ status: 'REJECTED', rejectionReason: payload.rejectionReason })
    });

    return { requestId: Number(requestId), status: 'REJECTED' };
  }
}

export const approvalService = new ApprovalService();
