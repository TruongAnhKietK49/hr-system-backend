import { auditService } from './audit.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, auditQuerySchema } from '../../validations/schemas.js';

export const getLogs = asyncHandler(async (req, res) => {
  const filters = validate(auditQuerySchema, req.query);
  const data = await auditService.getLogs(req.user, filters);
  return success(res, data, 'Audit logs fetched');
});
