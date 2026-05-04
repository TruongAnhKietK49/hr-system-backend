import { approvalService } from './approval.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, approvalApproveSchema, approvalRejectSchema } from '../../validations/schemas.js';

export const getPending = asyncHandler(async (req, res) => {
  const data = await approvalService.getPending(req.user);
  return success(res, data, 'Pending requests fetched');
});

export const approve = asyncHandler(async (req, res) => {
  const payload = validate(approvalApproveSchema, req.body);
  const data = await approvalService.approve(req.user, req.params.requestId, payload);
  return success(res, data, 'HR request approved');
});

export const reject = asyncHandler(async (req, res) => {
  const payload = validate(approvalRejectSchema, req.body);
  const data = await approvalService.reject(req.user, req.params.requestId, payload);
  return success(res, data, 'HR request rejected');
});
