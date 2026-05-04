import { salaryService } from './salary.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { salaryUpdateSchema, validate } from '../../validations/schemas.js';

export const getAll = asyncHandler(async (req, res) => {
  const data = await salaryService.getList(req.user);
  return success(res, data, 'Salaries fetched');
});

export const getById = asyncHandler(async (req, res) => {
  const data = await salaryService.getByEmployeeId(req.user, req.params.id);
  return success(res, data, 'Salary fetched');
});

export const updateByDirector = asyncHandler(async (req, res) => {
  const payload = validate(salaryUpdateSchema, req.body);
  const data = await salaryService.updateForDirector(req.user, req.params.id, payload);
  return success(res, data, 'Salary updated');
});
