import { ROLES } from '../../constants/roles.js';
import { ACTION_TYPES } from '../../constants/actionTypes.js';
import { AppError } from '../../utils/AppError.js';
import { requestRepository } from './request.repository.js';
import { auditRepository } from '../audit/audit.repository.js';

class RequestService {
  async create(user, payload) {
    if (user.role !== ROLES.HR_STAFF) {
      throw new AppError('Only HR Staff can create HR request', 403);
    }

    const request = await requestRepository.create({
      requestType: payload.requestType,
      requesterId: user.employeeId,
      payload: payload.payload
    });

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.CREATE_HR_REQUEST,
      tableName: 'HR_Request',
      recordId: request?.RequestID,
      oldValues: null,
      newValues: JSON.stringify(request)
    });

    return request;
  }

  async getAll(user) {
    if (![ROLES.HR_STAFF, ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }

    return requestRepository.findAllByScope(user.employeeId);
  }

  async getById(user, requestId) {
    const request = await requestRepository.findByIdByScope(user.employeeId, requestId);
    if (!request) {
      throw new AppError('HR request not found', 404);
    }
    if (![ROLES.HR_STAFF, ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }
    return request;
  }
}

export const requestService = new RequestService();
