import { ROLES } from '../../constants/roles.js';
import { AppError } from '../../utils/AppError.js';
import { auditRepository } from './audit.repository.js';

class AuditService {
  async getLogs(user, filters) {
    if (![ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }
    return auditRepository.findAll(filters);
  }
}

export const auditService = new AuditService();
