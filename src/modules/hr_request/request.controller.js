import { requestService } from './request.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, hrRequestCreateSchema } from '../../validations/schemas.js';

export const create = asyncHandler(async (req, res) => {
  const payload = validate(hrRequestCreateSchema, req.body);
  const data = await requestService.create(req.user, payload);
  return success(res, data, 'HR request created', 201);
});

export const getAll = asyncHandler(async (req, res) => {
  const data = await requestService.getAll(req.user);
  return success(res, data, 'HR requests fetched');
});

export const getById = asyncHandler(async (req, res) => {
  const data = await requestService.getById(req.user, req.params.id);
  return success(res, data, 'HR request fetched');
});
