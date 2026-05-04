import { employeeService } from './employee.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, employeeUpdateSchema } from '../../validations/schemas.js';

export const getAll = asyncHandler(async (req, res) => {
  const data = await employeeService.getAll(req.user);
  return success(res, data, 'Employees fetched');
});

export const getById = asyncHandler(async (req, res) => {
  const data = await employeeService.getById(req.user, req.params.id);
  return success(res, data, 'Employee fetched');
});

export const update = asyncHandler(async (req, res) => {
  const payload = validate(employeeUpdateSchema, req.body);
  const data = await employeeService.update(req.user, req.params.id, payload);
  return success(res, data, 'Employee updated');
});
